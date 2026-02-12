import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avrai/core/services/cross_app/cross_app_learning_insight_service.dart';

/// Service for managing user consent for cross-app tracking features
///
/// Tracks which data sources the user has opted into/out of:
/// - Calendar: Schedule and event learning
/// - Health: Fitness and wellness learning
/// - Media: Music/vibe learning
/// - App Usage: Digital behavior learning (Android only)
///
/// Implements opt-out model: all sources enabled by default during onboarding,
/// user can disable from settings at any time.
///
/// Per avrai philosophy: user has full control over their data.
class CrossAppConsentService {
  static const String _logName = 'CrossAppConsentService';

  // Preference keys
  static const String _keyCalendarEnabled = 'cross_app_consent_calendar';
  static const String _keyHealthEnabled = 'cross_app_consent_health';
  static const String _keyMediaEnabled = 'cross_app_consent_media';
  static const String _keyAppUsageEnabled = 'cross_app_consent_app_usage';
  static const String _keyOnboardingCompleted = 'cross_app_consent_onboarding_completed';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  CrossAppConsentService();

  /// Initialize the consent service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      developer.log(
        'CrossAppConsentService initialized',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error initializing CrossAppConsentService',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Check if a specific data source is enabled
  Future<bool> isEnabled(CrossAppDataSource source) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return true; // Default to enabled if can't read

    switch (source) {
      case CrossAppDataSource.calendar:
        return _prefs!.getBool(_keyCalendarEnabled) ?? true;
      case CrossAppDataSource.health:
        return _prefs!.getBool(_keyHealthEnabled) ?? true;
      case CrossAppDataSource.media:
        return _prefs!.getBool(_keyMediaEnabled) ?? true;
      case CrossAppDataSource.appUsage:
        return _prefs!.getBool(_keyAppUsageEnabled) ?? true;
    }
  }

  /// Enable or disable a specific data source
  Future<void> setEnabled(CrossAppDataSource source, bool enabled) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return;

    switch (source) {
      case CrossAppDataSource.calendar:
        await _prefs!.setBool(_keyCalendarEnabled, enabled);
        break;
      case CrossAppDataSource.health:
        await _prefs!.setBool(_keyHealthEnabled, enabled);
        break;
      case CrossAppDataSource.media:
        await _prefs!.setBool(_keyMediaEnabled, enabled);
        break;
      case CrossAppDataSource.appUsage:
        await _prefs!.setBool(_keyAppUsageEnabled, enabled);
        break;
    }

    developer.log(
      'Cross-app consent updated: ${source.name} = $enabled',
      name: _logName,
    );
  }

  /// Get all consent statuses
  Future<Map<CrossAppDataSource, bool>> getAllConsents() async {
    if (!_isInitialized) {
      await initialize();
    }

    return {
      CrossAppDataSource.calendar: await isEnabled(CrossAppDataSource.calendar),
      CrossAppDataSource.health: await isEnabled(CrossAppDataSource.health),
      CrossAppDataSource.media: await isEnabled(CrossAppDataSource.media),
      CrossAppDataSource.appUsage: await isEnabled(CrossAppDataSource.appUsage),
    };
  }

  /// Set all consents at once (typically during onboarding)
  Future<void> setAllConsents(Map<CrossAppDataSource, bool> consents) async {
    for (final entry in consents.entries) {
      await setEnabled(entry.key, entry.value);
    }
  }

  /// Enable all data sources (opt-in all)
  Future<void> enableAll() async {
    await setEnabled(CrossAppDataSource.calendar, true);
    await setEnabled(CrossAppDataSource.health, true);
    await setEnabled(CrossAppDataSource.media, true);
    await setEnabled(CrossAppDataSource.appUsage, true);
  }

  /// Disable all data sources (opt-out all)
  Future<void> disableAll() async {
    await setEnabled(CrossAppDataSource.calendar, false);
    await setEnabled(CrossAppDataSource.health, false);
    await setEnabled(CrossAppDataSource.media, false);
    await setEnabled(CrossAppDataSource.appUsage, false);
  }

  /// Check if onboarding consent flow has been completed
  Future<bool> isOnboardingCompleted() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return false;

    return _prefs!.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Mark onboarding consent flow as completed
  Future<void> completeOnboarding() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return;

    await _prefs!.setBool(_keyOnboardingCompleted, true);

    developer.log(
      'Cross-app consent onboarding completed',
      name: _logName,
    );
  }

  /// Get consent summary for display
  Future<CrossAppConsentSummary> getConsentSummary() async {
    final consents = await getAllConsents();
    final enabledCount = consents.values.where((v) => v).length;

    return CrossAppConsentSummary(
      consents: consents,
      enabledCount: enabledCount,
      totalCount: CrossAppDataSource.values.length,
      allEnabled: enabledCount == CrossAppDataSource.values.length,
      allDisabled: enabledCount == 0,
    );
  }

  // ========================================
  // Learning Control Methods
  // ========================================

  static const String _keyLearningPaused = 'cross_app_learning_paused';

  /// Check if learning is currently paused
  Future<bool> isLearningPaused() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return false;

    return _prefs!.getBool(_keyLearningPaused) ?? false;
  }

  /// Pause learning without deleting data
  ///
  /// Temporarily stops data collection from all sources.
  /// Use [resumeLearning] to resume.
  Future<void> pauseLearning() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return;

    await _prefs!.setBool(_keyLearningPaused, true);

    developer.log(
      'Cross-app learning paused',
      name: _logName,
    );
  }

  /// Resume learning after pause
  Future<void> resumeLearning() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_prefs == null) return;

    await _prefs!.setBool(_keyLearningPaused, false);

    developer.log(
      'Cross-app learning resumed',
      name: _logName,
    );
  }

  /// Clear all learned data from cross-app sources
  ///
  /// This clears both the insights and any personality changes
  /// that came from cross-app tracking.
  ///
  /// Returns the number of insights cleared.
  Future<int> clearAllLearnedData() async {
    developer.log(
      'Clearing all cross-app learned data',
      name: _logName,
    );

    int clearedCount = 0;

    // Clear insights via CrossAppLearningInsightService
    try {
      final insightService = _getInsightService();
      if (insightService != null) {
        await insightService.clearAllInsights();
        clearedCount = insightService.getLearningHistory().totalInsights;
      }
    } catch (e) {
      developer.log(
        'Error clearing insights: $e',
        name: _logName,
      );
    }

    // Note: PersonalityLearning.clearExternalContextLearning requires userId
    // and should be called separately from the UI with the current user's ID

    return clearedCount;
  }

  /// Clear learned data for a specific source
  ///
  /// Returns the number of insights cleared for that source.
  Future<int> clearLearnedDataForSource(CrossAppDataSource source) async {
    developer.log(
      'Clearing learned data for ${source.name}',
      name: _logName,
    );

    int clearedCount = 0;

    try {
      final insightService = _getInsightService();
      if (insightService != null) {
        final previousCount = insightService.getInsightsBySource(source).length;
        await insightService.clearInsightsForSource(source);
        clearedCount = previousCount;
      }
    } catch (e) {
      developer.log(
        'Error clearing insights for ${source.name}: $e',
        name: _logName,
      );
    }

    return clearedCount;
  }

  /// Get the insight service via DI
  CrossAppLearningInsightService? _getInsightService() {
    try {
      if (GetIt.instance.isRegistered<CrossAppLearningInsightService>()) {
        return GetIt.instance<CrossAppLearningInsightService>();
      }
    } catch (e) {
      developer.log(
        'Error getting CrossAppLearningInsightService: $e',
        name: _logName,
      );
    }
    return null;
  }
}

/// Data sources that can be tracked for AI learning
enum CrossAppDataSource {
  /// Calendar events (schedule, social events)
  calendar,

  /// Health/Fitness data (activity, sleep, stress)
  health,

  /// Music/Media now playing (mood, vibe)
  media,

  /// App usage statistics (digital behavior, Android only)
  appUsage,
}

/// Extension to get display names and descriptions
extension CrossAppDataSourceExtension on CrossAppDataSource {
  String get displayName {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'Calendar';
      case CrossAppDataSource.health:
        return 'Health & Fitness';
      case CrossAppDataSource.media:
        return 'Music & Media';
      case CrossAppDataSource.appUsage:
        return 'App Usage';
    }
  }

  String get description {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'Learn from your schedule and events to suggest relevant spots';
      case CrossAppDataSource.health:
        return 'Understand your energy and activity to match your current state';
      case CrossAppDataSource.media:
        return 'Match spot vibes to your current music mood';
      case CrossAppDataSource.appUsage:
        return 'Learn your interests from the apps you use (Android only)';
    }
  }

  String get icon {
    switch (this) {
      case CrossAppDataSource.calendar:
        return '📅';
      case CrossAppDataSource.health:
        return '❤️';
      case CrossAppDataSource.media:
        return '🎵';
      case CrossAppDataSource.appUsage:
        return '📱';
    }
  }
}

/// Summary of consent status
class CrossAppConsentSummary {
  final Map<CrossAppDataSource, bool> consents;
  final int enabledCount;
  final int totalCount;
  final bool allEnabled;
  final bool allDisabled;

  const CrossAppConsentSummary({
    required this.consents,
    required this.enabledCount,
    required this.totalCount,
    required this.allEnabled,
    required this.allDisabled,
  });

  bool isEnabled(CrossAppDataSource source) => consents[source] ?? false;
}
