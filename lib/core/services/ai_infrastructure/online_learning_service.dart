// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Online Learning Service for Phase 12: Neural Network Implementation
// Section 3.2.1: Continuous Learning
// Manages periodic retraining and incremental model updates

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/services/calling_score/calling_score_data_collector.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/ai_infrastructure/model_version_manager.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/ai_infrastructure/model_retraining_service.dart';
import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/ml/model_version_info.dart';

/// Online Learning Service
///
/// Manages continuous learning for neural network models:
/// - Collects new training data from outcomes
/// - Triggers periodic retraining (weekly/monthly)
/// - Auto-registers new model versions
/// - Tracks model performance over time
///
/// Phase 12 Section 3.2.1: Continuous Learning
class OnlineLearningService {
  static const String _logName = 'OnlineLearningService';

  final SupabaseClient _supabase;
  final ModelVersionManager _versionManager;
  final ModelRetrainingService _retrainingService;
  final UrkRuntimeActivationReceiptDispatcher? _urkActivationDispatcher;

  // Retraining configuration
  static const int minSamplesForRetraining = 1000; // Minimum new samples needed
  static const Duration retrainingInterval =
      Duration(days: 7); // Weekly retraining
  static const Duration performanceTrackingInterval =
      Duration(hours: 24); // Daily tracking

  // State tracking
  DateTime? _lastRetrainingDate;
  Timer? _retrainingTimer;
  Timer? _performanceTrackingTimer;
  bool _isRetraining = false;

  // Performance metrics cache
  final Map<String, ModelPerformanceMetrics> _performanceMetrics = {};

  OnlineLearningService({
    required SupabaseClient supabase,
    required CallingScoreDataCollector dataCollector,
    required ModelVersionManager versionManager,
    required ModelRetrainingService retrainingService,
    UrkRuntimeActivationReceiptDispatcher? urkActivationDispatcher,
    AgentIdService? agentIdService,
  })  : _supabase = supabase,
        _versionManager = versionManager,
        _retrainingService = retrainingService,
        _urkActivationDispatcher = urkActivationDispatcher ??
            resolveDefaultUrkRuntimeActivationDispatcher();

  /// Initialize online learning service
  ///
  /// Starts scheduled retraining and performance tracking
  Future<void> initialize() async {
    developer.log('Initializing online learning service...', name: _logName);

    // Load last retraining date from storage
    await _loadState();

    // Start scheduled retraining
    _startScheduledRetraining();

    // Start performance tracking
    _startPerformanceTracking();

    developer.log('✅ Online learning service initialized', name: _logName);
  }

  /// Start scheduled periodic retraining
  void _startScheduledRetraining() {
    // Cancel existing timer if any
    _retrainingTimer?.cancel();

    // Schedule next retraining check
    _retrainingTimer = Timer.periodic(
      const Duration(hours: 24), // Check daily
      (_) => _checkAndTriggerRetraining(),
    );

    developer.log(
      'Scheduled retraining: checking every 24 hours, retraining every ${retrainingInterval.inDays} days',
      name: _logName,
    );
  }

  /// Start performance tracking
  void _startPerformanceTracking() {
    // Cancel existing timer if any
    _performanceTrackingTimer?.cancel();

    // Track performance daily
    _performanceTrackingTimer = Timer.periodic(
      performanceTrackingInterval,
      (_) => _trackPerformanceForAllVersions(),
    );

    developer.log(
      'Performance tracking: every ${performanceTrackingInterval.inHours} hours',
      name: _logName,
    );
  }

  /// Check if retraining should be triggered and trigger if needed
  Future<void> _checkAndTriggerRetraining() async {
    if (_isRetraining) {
      developer.log('Retraining already in progress, skipping check',
          name: _logName);
      return;
    }

    // Check if enough time has passed since last retraining
    final shouldRetrainByTime = _lastRetrainingDate == null ||
        DateTime.now().difference(_lastRetrainingDate!) >= retrainingInterval;

    // Check if enough new data is available
    final newDataCount = await _countNewTrainingData();
    final shouldRetrainByData = newDataCount >= minSamplesForRetraining;

    if (shouldRetrainByTime || shouldRetrainByData) {
      developer.log(
        'Retraining trigger: time=$shouldRetrainByTime, data=$shouldRetrainByData ($newDataCount new samples)',
        name: _logName,
      );

      await triggerRetraining(
        reason: shouldRetrainByTime ? 'scheduled' : 'data_threshold',
        newDataCount: newDataCount,
      );
    }
  }

  /// Count new training data since last retraining
  Future<int> _countNewTrainingData() async {
    try {
      final lastDate = _lastRetrainingDate ??
          DateTime.now().subtract(const Duration(days: 30));

      final response = await _supabase
          .from('calling_score_training_data')
          .select('id')
          .gte('timestamp', lastDate.toIso8601String())
          .not('outcome_type', 'is', null); // Only count records with outcomes

      return (response as List).length;
    } catch (e, stackTrace) {
      developer.log(
        'Error counting new training data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Trigger model retraining
  ///
  /// **Parameters:**
  /// - `modelType`: 'calling_score' or 'outcome'
  /// - `reason`: Why retraining was triggered ('scheduled', 'data_threshold', 'manual')
  /// - `newDataCount`: Number of new training samples available
  ///
  /// **Returns:**
  /// True if retraining was successfully triggered
  Future<bool> triggerRetraining({
    String modelType = 'calling_score',
    String reason = 'manual',
    int? newDataCount,
  }) async {
    if (_isRetraining) {
      developer.log('Retraining already in progress', name: _logName);
      return false;
    }

    _isRetraining = true;

    try {
      developer.log(
        'Triggering retraining for $modelType (reason: $reason, new data: ${newDataCount ?? "unknown"})',
        name: _logName,
      );

      // Count new data if not provided
      final dataCount = newDataCount ?? await _countNewTrainingData();

      if (dataCount < minSamplesForRetraining) {
        developer.log(
          'Insufficient new data for retraining: $dataCount < $minSamplesForRetraining',
          name: _logName,
        );
        _isRetraining = false;
        return false;
      }

      // Export new training data
      final exportResult = await _exportTrainingDataForRetraining();
      if (exportResult == null) {
        developer.log('Failed to export training data for retraining',
            name: _logName);
        _isRetraining = false;
        return false;
      }

      // Trigger complete retraining workflow (retrain + validate + deploy)
      final deployedVersion =
          await _retrainingService.completeRetrainingWorkflow(
        modelType: modelType,
        dataPath: exportResult,
      );

      if (deployedVersion == null) {
        developer.log('Retraining workflow failed', name: _logName);
        _isRetraining = false;
        return false;
      }

      developer.log(
        '✅ Retraining complete and model deployed: $deployedVersion',
        name: _logName,
      );

      // Update last retraining date
      _lastRetrainingDate = DateTime.now();
      await _saveState();

      await _urkActivationDispatcher?.dispatch(
        requestId:
            'retrain_${modelType}_${DateTime.now().millisecondsSinceEpoch}',
        trigger: 'learning_patch_candidate',
        privacyMode: UrkPrivacyMode.multiMode,
        actor: _logName,
        reason: 'retraining_success:$reason',
      );

      _isRetraining = false;
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error triggering retraining: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      _isRetraining = false;
      return false;
    }
  }

  /// Export training data for retraining
  ///
  /// Exports new training data since last retraining to JSON format
  /// for Python training scripts
  ///
  /// **Returns:**
  /// Path to exported data file, or null if export failed
  Future<String?> _exportTrainingDataForRetraining() async {
    try {
      final lastDate = _lastRetrainingDate ??
          DateTime.now().subtract(const Duration(days: 30));

      // Fetch new training data with outcomes
      final response = await _supabase
          .from('calling_score_training_data')
          .select()
          .gte('timestamp', lastDate.toIso8601String())
          .not('outcome_type', 'is', null)
          .order('timestamp', ascending: true);

      if (response.isEmpty) {
        developer.log('No new training data to export', name: _logName);
        return null;
      }

      // Convert to training data format
      final trainingData = (response as List).map((record) {
        return {
          'user_vibe_dimensions': record['user_vibe_dimensions'],
          'spot_vibe_dimensions': record['spot_vibe_dimensions'],
          'context_features': record['context_features'],
          'timing_features': record['timing_features'],
          'formula_calling_score': record['formula_calling_score'],
          'is_called': record['formula_is_called'],
          'outcome_type': record['outcome_type'],
          'outcome_score': record['outcome_score'],
        };
      }).toList();

      // Save to file
      final timestamp =
          DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');
      final exportPath =
          'data/calling_score_training_data_retrain_$timestamp.json';
      final exportFile = File(exportPath);

      // Create data directory if needed
      await exportFile.parent.create(recursive: true);

      // Write JSON file
      final jsonData = {
        'metadata': {
          'num_samples': trainingData.length,
          'source': 'real_data_retraining',
          'export_date': DateTime.now().toIso8601String(),
          'last_retraining_date': _lastRetrainingDate?.toIso8601String(),
        },
        'training_data': trainingData,
      };

      await exportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );

      developer.log(
        '✅ Exported ${trainingData.length} training records to: $exportPath',
        name: _logName,
      );

      return exportPath;
    } catch (e, stackTrace) {
      developer.log(
        'Error exporting training data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Register a newly trained model version
  ///
  /// Called after retraining completes to register the new version
  ///
  /// **Parameters:**
  /// - `version`: Version identifier (e.g., 'v1.2-hybrid')
  /// - `modelPath`: Path to ONNX model file
  /// - `modelType`: 'calling_score' or 'outcome'
  /// - `trainingMetrics`: Training performance metrics
  Future<void> registerNewModelVersion({
    required String version,
    required String modelPath,
    required String modelType,
    required Map<String, dynamic> trainingMetrics,
  }) async {
    try {
      final versionInfo = ModelVersionInfo(
        version: version,
        modelPath: modelPath,
        defaultWeight: 0.1, // Start with low weight
        dataSource: 'real_data', // New versions use real data
        trainedDate: DateTime.now(),
        status: ModelStatus.staging,
        description: 'Auto-retrained model (online learning)',
        trainingMetrics: trainingMetrics,
      );

      await _versionManager.registerVersion(
        versionInfo,
        modelType: modelType,
      );

      developer.log(
        '✅ Registered new model version: $version ($modelType)',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error registering new model version: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Track performance for all active model versions
  Future<void> _trackPerformanceForAllVersions() async {
    try {
      // Track calling score model performance
      final callingScoreVersion =
          ModelVersionRegistry.activeCallingScoreVersion;
      await trackModelPerformance(callingScoreVersion,
          modelType: 'calling_score');

      // Track outcome prediction model performance
      final outcomeVersion = ModelVersionRegistry.activeOutcomeVersion;
      await trackModelPerformance(outcomeVersion, modelType: 'outcome');
    } catch (e, stackTrace) {
      developer.log(
        'Error tracking performance: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Track performance metrics for a specific model version
  ///
  /// **Parameters:**
  /// - `version`: Model version to track
  /// - `modelType`: 'calling_score' or 'outcome'
  Future<void> trackModelPerformance(
    String version, {
    String modelType = 'calling_score',
  }) async {
    try {
      final versionInfo = modelType == 'calling_score'
          ? ModelVersionRegistry.getCallingScoreVersion(version)
          : ModelVersionRegistry.getOutcomeVersion(version);

      if (versionInfo == null) {
        developer.log('Version $version not found for performance tracking',
            name: _logName);
        return;
      }

      // Calculate performance metrics from recent A/B test outcomes
      final metrics = await _calculatePerformanceMetrics(version, modelType);

      // Update version info with performance metrics
      final updatedMetrics = {
        ...versionInfo.performanceMetrics,
        ...metrics,
        'last_tracked': DateTime.now().toIso8601String(),
      };

      // Update version info (would need a method to update in registry)
      // For now, log the metrics
      _performanceMetrics[version] =
          ModelPerformanceMetrics.fromMap(updatedMetrics);

      developer.log(
        'Performance tracked for $version: ${metrics.toString()}',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error tracking model performance: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calculate performance metrics for a model version
  Future<Map<String, dynamic>> _calculatePerformanceMetrics(
    String version,
    String modelType,
  ) async {
    try {
      // Get A/B test outcomes for this version
      // This is a simplified version - in production, you'd query actual A/B test results
      final response = await _supabase
          .from('calling_score_ab_test_outcomes')
          .select()
          .eq('test_group', modelType == 'calling_score' ? 'hybrid' : 'formula')
          .gte(
              'timestamp',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String());

      if (response.isEmpty) {
        return {
          'sample_count': 0,
          'note': 'Insufficient data for metrics',
        };
      }

      final outcomes = response as List;
      final positiveOutcomes =
          outcomes.where((o) => o['outcome_type'] == 'positive').length;
      final totalOutcomes = outcomes.length;

      return {
        'sample_count': totalOutcomes,
        'positive_outcome_rate':
            totalOutcomes > 0 ? positiveOutcomes / totalOutcomes : 0.0,
        'average_calling_score': _calculateAverage(outcomes, 'calling_score'),
        'average_outcome_score': _calculateAverage(outcomes, 'outcome_score'),
        'tracking_period_days': 7,
      };
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating performance metrics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Calculate average value from list of records
  double _calculateAverage(List records, String field) {
    if (records.isEmpty) return 0.0;

    final values = records
        .map((r) => (r[field] as num?)?.toDouble() ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return 0.0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Load service state (last retraining date, etc.)
  Future<void> _loadState() async {
    try {
      // TODO: Load from local storage or Supabase
      // For now, use defaults
      _lastRetrainingDate = null;
    } catch (e) {
      developer.log('Error loading state: $e', name: _logName);
    }
  }

  /// Save service state
  Future<void> _saveState() async {
    try {
      // TODO: Save to local storage or Supabase
      // For now, just log
      developer.log(
        'State saved: last_retraining=${_lastRetrainingDate?.toIso8601String() ?? "never"}',
        name: _logName,
      );
    } catch (e) {
      developer.log('Error saving state: $e', name: _logName);
    }
  }

  /// Get performance metrics for a version
  ModelPerformanceMetrics? getPerformanceMetrics(String version) {
    return _performanceMetrics[version];
  }

  /// Check if retraining is in progress
  bool get isRetraining => _isRetraining;

  /// Get last retraining date
  DateTime? get lastRetrainingDate => _lastRetrainingDate;

  /// Dispose resources
  void dispose() {
    _retrainingTimer?.cancel();
    _performanceTrackingTimer?.cancel();
    _retrainingTimer = null;
    _performanceTrackingTimer = null;
  }
}

/// Model Performance Metrics
class ModelPerformanceMetrics {
  final int sampleCount;
  final double positiveOutcomeRate;
  final double averageCallingScore;
  final double averageOutcomeScore;
  final int trackingPeriodDays;
  final DateTime? lastTracked;

  ModelPerformanceMetrics({
    required this.sampleCount,
    required this.positiveOutcomeRate,
    required this.averageCallingScore,
    required this.averageOutcomeScore,
    required this.trackingPeriodDays,
    this.lastTracked,
  });

  factory ModelPerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return ModelPerformanceMetrics(
      sampleCount: map['sample_count'] as int? ?? 0,
      positiveOutcomeRate:
          (map['positive_outcome_rate'] as num?)?.toDouble() ?? 0.0,
      averageCallingScore:
          (map['average_calling_score'] as num?)?.toDouble() ?? 0.0,
      averageOutcomeScore:
          (map['average_outcome_score'] as num?)?.toDouble() ?? 0.0,
      trackingPeriodDays: map['tracking_period_days'] as int? ?? 7,
      lastTracked: map['last_tracked'] != null
          ? DateTime.parse(map['last_tracked'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sample_count': sampleCount,
      'positive_outcome_rate': positiveOutcomeRate,
      'average_calling_score': averageCallingScore,
      'average_outcome_score': averageOutcomeScore,
      'tracking_period_days': trackingPeriodDays,
      'last_tracked': lastTracked?.toIso8601String(),
    };
  }
}
