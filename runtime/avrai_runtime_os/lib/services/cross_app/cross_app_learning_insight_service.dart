import 'dart:convert';
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';

/// Service for managing cross-app learning insights
///
/// Stores, retrieves, and manages insights learned from cross-app data sources.
/// All data is stored locally using SharedPreferences for privacy.
///
/// Responsibilities:
/// - Record new insights from learning pipeline
/// - Retrieve insights for UI display
/// - Track per-source statistics
/// - Clear insights (all or by source)
/// - Update permission and data status
class CrossAppLearningInsightService {
  static const String _logName = 'CrossAppLearningInsightService';

  // SharedPreferences keys
  static const String _keyInsights = 'cross_app_learning_insights';
  static const String _keySourceStats = 'cross_app_source_stats';
  static const String _keyLastLearning = 'cross_app_last_learning';

  // Limits - configurable max insights per source to balance memory and history
  // 50 insights per source = ~200 total, enough for ~2 weeks of learning
  static const int _maxInsightsPerSource = 50;

  // Confidence thresholds for insight generation
  static const double kBaseConfidence = 0.6;
  static const double kHighConfidence = 0.8;
  static const double kMediumConfidence = 0.7;

  // Deduplication window - don't record same insight within this period
  static const Duration _deduplicationWindow = Duration(hours: 24);

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final _uuid = const Uuid();

  // In-memory cache
  final Map<CrossAppDataSource, List<CrossAppLearningInsight>> _insights = {};
  final Map<CrossAppDataSource, SourceLearningStats> _sourceStats = {};
  DateTime? _lastLearningAt;

  CrossAppLearningInsightService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadFromStorage();
      _isInitialized = true;

      developer.log(
        'CrossAppLearningInsightService initialized with ${_getTotalInsightCount()} insights',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error initializing CrossAppLearningInsightService',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Record a new insight from the learning pipeline
  ///
  /// Returns true if the insight was recorded, false if skipped (duplicate or paused).
  Future<bool> recordInsight(CrossAppLearningInsight insight) async {
    if (!_isInitialized) await initialize();

    try {
      // Check if learning is paused (single source of truth: CrossAppConsentService)
      if (await isLearningPaused()) {
        developer.log(
          'Learning paused, skipping insight: ${insight.description}',
          name: _logName,
        );
        return false;
      }

      // Check for duplicate insight (deduplication)
      if (_isDuplicateInsight(insight)) {
        developer.log(
          'Duplicate insight skipped: ${insight.description}',
          name: _logName,
        );
        return false;
      }

      // Add to in-memory cache
      _insights[insight.source] ??= [];
      _insights[insight.source]!.insert(0, insight);

      // Trim if over limit
      if (_insights[insight.source]!.length > _maxInsightsPerSource) {
        _insights[insight.source] =
            _insights[insight.source]!.take(_maxInsightsPerSource).toList();
      }

      // Update last learning time
      _lastLearningAt = DateTime.now();

      // Update source stats
      _updateSourceStats(
          insight.source,
          (stats) => stats.copyWith(
                insightCount: (_insights[insight.source]?.length ?? 0),
                lastCollected: DateTime.now(),
                dataStatus: DataAvailabilityStatus.available,
              ));

      // Persist
      await _saveToStorage();

      developer.log(
        'Recorded insight: ${insight.description} from ${insight.source.name}',
        name: _logName,
      );
      return true;
    } catch (e, st) {
      developer.log(
        'Error recording insight',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return false;
    }
  }

  /// Check if an insight is a duplicate of a recent insight
  bool _isDuplicateInsight(CrossAppLearningInsight insight) {
    final existingInsights = _insights[insight.source] ?? [];
    final now = DateTime.now();

    return existingInsights.any((existing) =>
        existing.description == insight.description &&
        now.difference(existing.learnedAt) < _deduplicationWindow);
  }

  /// Record multiple insights at once
  ///
  /// Returns the number of insights successfully recorded.
  Future<int> recordInsights(List<CrossAppLearningInsight> insights) async {
    int successCount = 0;
    for (final insight in insights) {
      final success = await recordInsight(insight);
      if (success) successCount++;
    }
    return successCount;
  }

  /// Generate a unique insight ID
  String generateInsightId() {
    return _uuid.v4();
  }

  /// Get all insights for a specific source
  List<CrossAppLearningInsight> getInsightsBySource(CrossAppDataSource source) {
    return List.unmodifiable(_insights[source] ?? []);
  }

  /// Get all insights across all sources
  List<CrossAppLearningInsight> getAllInsights() {
    final all = _insights.values.expand((list) => list).toList();
    all.sort((a, b) => b.learnedAt.compareTo(a.learnedAt));
    return List.unmodifiable(all);
  }

  /// Get the most recent insights
  List<CrossAppLearningInsight> getRecentInsights(int count) {
    return getAllInsights().take(count).toList();
  }

  /// Get the complete learning history
  ///
  /// Note: isPaused is determined synchronously from cached source stats.
  /// For real-time pause state, use [isLearningPaused()].
  CrossAppLearningHistory getLearningHistory() {
    // Check if any source has paused status to determine isPaused
    final isPaused = _sourceStats.values.any(
      (stats) => stats.dataStatus == DataAvailabilityStatus.paused,
    );

    return CrossAppLearningHistory(
      insightsBySource: Map.unmodifiable(_insights),
      totalInsights: _getTotalInsightCount(),
      lastLearningAt: _lastLearningAt,
      sourceStats: Map.unmodifiable(_sourceStats),
      isPaused: isPaused,
    );
  }

  /// Get statistics for a specific source
  SourceLearningStats getSourceStats(CrossAppDataSource source) {
    return _sourceStats[source] ?? SourceLearningStats.initial();
  }

  /// Get statistics for all sources
  Map<CrossAppDataSource, SourceLearningStats> getAllSourceStats() {
    return Map.unmodifiable(_sourceStats);
  }

  /// Clear insights for a specific source
  Future<void> clearInsightsForSource(CrossAppDataSource source) async {
    if (!_isInitialized) await initialize();

    try {
      _insights[source] = [];
      _updateSourceStats(
          source,
          (stats) => stats.copyWith(
                insightCount: 0,
              ));
      await _saveToStorage();

      developer.log(
        'Cleared insights for ${source.name}',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error clearing insights for ${source.name}',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Clear all insights
  Future<void> clearAllInsights() async {
    if (!_isInitialized) await initialize();

    try {
      for (final source in CrossAppDataSource.values) {
        _insights[source] = [];
        _updateSourceStats(
            source,
            (stats) => stats.copyWith(
                  insightCount: 0,
                ));
      }
      await _saveToStorage();

      developer.log(
        'Cleared all insights',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error clearing all insights',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Clear insights learned before a specific date
  ///
  /// Keeps insights learned on or after [cutoffDate], removes older ones.
  /// Returns the number of insights that were cleared.
  Future<int> clearInsightsBeforeDate(DateTime cutoffDate) async {
    if (!_isInitialized) await initialize();

    int totalCleared = 0;

    try {
      for (final source in CrossAppDataSource.values) {
        final sourceInsights = _insights[source] ?? [];
        final originalCount = sourceInsights.length;

        // Keep only insights on or after the cutoff date
        _insights[source] = sourceInsights
            .where((insight) => !insight.learnedAt.isBefore(cutoffDate))
            .toList();

        final clearedCount = originalCount - (_insights[source]?.length ?? 0);
        totalCleared += clearedCount;

        // Update stats
        _updateSourceStats(
            source,
            (stats) => stats.copyWith(
                  insightCount: _insights[source]?.length ?? 0,
                ));
      }

      await _saveToStorage();

      developer.log(
        'Cleared $totalCleared insights before ${cutoffDate.toIso8601String()}',
        name: _logName,
      );

      return totalCleared;
    } catch (e, st) {
      developer.log(
        'Error clearing insights before date',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return 0;
    }
  }

  /// Clear insights learned within a date range
  ///
  /// Removes insights learned between [startDate] and [endDate] (inclusive).
  /// Returns the number of insights that were cleared.
  Future<int> clearInsightsInDateRange(
      DateTime startDate, DateTime endDate) async {
    if (!_isInitialized) await initialize();

    int totalCleared = 0;

    try {
      for (final source in CrossAppDataSource.values) {
        final sourceInsights = _insights[source] ?? [];
        final originalCount = sourceInsights.length;

        // Keep insights outside the date range
        _insights[source] = sourceInsights.where((insight) {
          final learnedAt = insight.learnedAt;
          return learnedAt.isBefore(startDate) || learnedAt.isAfter(endDate);
        }).toList();

        final clearedCount = originalCount - (_insights[source]?.length ?? 0);
        totalCleared += clearedCount;

        // Update stats
        _updateSourceStats(
            source,
            (stats) => stats.copyWith(
                  insightCount: _insights[source]?.length ?? 0,
                ));
      }

      await _saveToStorage();

      developer.log(
        'Cleared $totalCleared insights between ${startDate.toIso8601String()} and ${endDate.toIso8601String()}',
        name: _logName,
      );

      return totalCleared;
    } catch (e, st) {
      developer.log(
        'Error clearing insights in date range',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return 0;
    }
  }

  /// Get count of insights before a specific date
  ///
  /// Useful for previewing how many insights would be cleared.
  int getInsightCountBeforeDate(DateTime cutoffDate) {
    int count = 0;
    for (final sourceInsights in _insights.values) {
      count += sourceInsights
          .where((insight) => insight.learnedAt.isBefore(cutoffDate))
          .length;
    }
    return count;
  }

  /// Update permission status for a source
  Future<void> updatePermissionStatus(
    CrossAppDataSource source,
    PermissionStatus status,
  ) async {
    if (!_isInitialized) await initialize();

    _updateSourceStats(
        source,
        (stats) => stats.copyWith(
              permissionStatus: status,
            ));
    await _saveToStorage();

    developer.log(
      'Updated permission status for ${source.name}: ${status.name}',
      name: _logName,
    );
  }

  /// Update data availability status for a source
  Future<void> updateDataStatus(
    CrossAppDataSource source,
    DataAvailabilityStatus status, {
    String? error,
  }) async {
    if (!_isInitialized) await initialize();

    _updateSourceStats(
        source,
        (stats) => stats.copyWith(
              dataStatus: status,
              lastError: error,
            ));
    await _saveToStorage();

    developer.log(
      'Updated data status for ${source.name}: ${status.name}',
      name: _logName,
    );
  }

  /// Record successful data collection for a source
  Future<void> recordDataCollection(
    CrossAppDataSource source, {
    int dataPoints = 1,
  }) async {
    if (!_isInitialized) await initialize();

    _updateSourceStats(
        source,
        (stats) => stats.copyWith(
              lastCollected: DateTime.now(),
              dataStatus: DataAvailabilityStatus.available,
              dataPointsCollected: stats.dataPointsCollected + dataPoints,
            ));
    await _saveToStorage();
  }

  /// Pause learning (stops collection without deleting)
  ///
  /// Delegates to CrossAppConsentService as the single source of truth.
  /// Also updates local source stats to reflect paused state.
  Future<void> pauseLearning() async {
    if (!_isInitialized) await initialize();

    // Update source stats to reflect paused state
    for (final source in CrossAppDataSource.values) {
      _updateSourceStats(
          source,
          (stats) => stats.copyWith(
                dataStatus: DataAvailabilityStatus.paused,
              ));
    }
    await _saveToStorage();

    // Delegate to consent service (single source of truth)
    final consentService = _getConsentService();
    if (consentService != null) {
      await consentService.pauseLearning();
    }

    developer.log('Learning paused', name: _logName);
  }

  /// Resume learning
  ///
  /// Delegates to CrossAppConsentService as the single source of truth.
  Future<void> resumeLearning() async {
    if (!_isInitialized) await initialize();

    // Update source stats to reflect resumed state
    for (final source in CrossAppDataSource.values) {
      _updateSourceStats(
          source,
          (stats) => stats.copyWith(
                dataStatus: DataAvailabilityStatus.notInitialized,
              ));
    }
    await _saveToStorage();

    // Delegate to consent service (single source of truth)
    final consentService = _getConsentService();
    if (consentService != null) {
      await consentService.resumeLearning();
    }

    developer.log('Learning resumed', name: _logName);
  }

  /// Check if learning is paused
  ///
  /// Queries CrossAppConsentService as the single source of truth.
  Future<bool> isLearningPaused() async {
    final consentService = _getConsentService();
    if (consentService != null) {
      return await consentService.isLearningPaused();
    }
    return false;
  }

  /// Get the consent service (single source of truth for pause state)
  CrossAppConsentService? _getConsentService() {
    if (GetIt.instance.isRegistered<CrossAppConsentService>()) {
      return GetIt.instance<CrossAppConsentService>();
    }
    return null;
  }

  /// Get total insight count
  int _getTotalInsightCount() {
    return _insights.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Update source stats with a modifier function
  void _updateSourceStats(
    CrossAppDataSource source,
    SourceLearningStats Function(SourceLearningStats) modifier,
  ) {
    final current = _sourceStats[source] ?? SourceLearningStats.initial();
    _sourceStats[source] = modifier(current);
  }

  /// Load data from SharedPreferences
  Future<void> _loadFromStorage() async {
    if (_prefs == null) return;

    try {
      // Load insights
      final insightsJson = _prefs!.getString(_keyInsights);
      if (insightsJson != null) {
        final Map<String, dynamic> insightsMap = jsonDecode(insightsJson);
        for (final source in CrossAppDataSource.values) {
          final sourceInsights = insightsMap[source.name] as List? ?? [];
          _insights[source] = sourceInsights
              .map((i) =>
                  CrossAppLearningInsight.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      } else {
        // Initialize empty
        for (final source in CrossAppDataSource.values) {
          _insights[source] = [];
        }
      }

      // Load source stats
      final statsJson = _prefs!.getString(_keySourceStats);
      if (statsJson != null) {
        final Map<String, dynamic> statsMap = jsonDecode(statsJson);
        for (final source in CrossAppDataSource.values) {
          final stats = statsMap[source.name] as Map<String, dynamic>?;
          _sourceStats[source] = stats != null
              ? SourceLearningStats.fromJson(stats)
              : SourceLearningStats.initial();
        }
      } else {
        // Initialize default stats
        for (final source in CrossAppDataSource.values) {
          _sourceStats[source] = SourceLearningStats.initial();
        }
      }

      // Load last learning time
      final lastLearningStr = _prefs!.getString(_keyLastLearning);
      if (lastLearningStr != null) {
        _lastLearningAt = DateTime.parse(lastLearningStr);
      }

      // Note: Paused state is now managed by CrossAppConsentService (single source of truth)
    } catch (e, st) {
      developer.log(
        'Error loading from storage, using defaults',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      _initializeDefaults();
    }
  }

  /// Save data to SharedPreferences
  Future<void> _saveToStorage() async {
    if (_prefs == null) return;

    try {
      // Save insights
      final insightsMap = <String, dynamic>{};
      for (final entry in _insights.entries) {
        insightsMap[entry.key.name] =
            entry.value.map((i) => i.toJson()).toList();
      }
      await _prefs!.setString(_keyInsights, jsonEncode(insightsMap));

      // Save source stats
      final statsMap = <String, dynamic>{};
      for (final entry in _sourceStats.entries) {
        statsMap[entry.key.name] = entry.value.toJson();
      }
      await _prefs!.setString(_keySourceStats, jsonEncode(statsMap));

      // Save last learning time
      if (_lastLearningAt != null) {
        await _prefs!
            .setString(_keyLastLearning, _lastLearningAt!.toIso8601String());
      }

      // Note: Paused state is now managed by CrossAppConsentService (single source of truth)
    } catch (e, st) {
      developer.log(
        'Error saving to storage',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Initialize with default empty values
  void _initializeDefaults() {
    for (final source in CrossAppDataSource.values) {
      _insights[source] = [];
      _sourceStats[source] = SourceLearningStats.initial();
    }
  }
}
