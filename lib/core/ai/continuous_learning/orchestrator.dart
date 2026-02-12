import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai/core/ai/advanced_communication.dart';
import 'package:avrai/core/ai/continuous_learning/data_collector.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/engines/personality_learning_engine.dart';
import 'package:avrai/core/ai/continuous_learning/engines/behavior_learning_engine.dart';
import 'package:avrai/core/ai/continuous_learning/engines/preference_learning_engine.dart';
import 'package:avrai/core/ai/continuous_learning/engines/interaction_learning_engine.dart';
import 'package:avrai/core/ai/continuous_learning/engines/location_intelligence_engine.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Orchestrates the continuous learning system
///
/// Coordinates data collection, dimension engines, and learning cycles.
/// Manages learning state and shares insights with the AI network.
class ContinuousLearningOrchestrator {
  static const String _logName = 'ContinuousLearningOrchestrator';

  // Perf triage: configurable cycle interval + non-overlapping cycles.
  final Duration _cycleInterval;

  // Learning dimensions that the AI continuously improves
  static const List<String> _learningDimensions = [
    'user_preference_understanding',
    'location_intelligence',
    'temporal_patterns',
    'social_dynamics',
    'authenticity_detection',
    'community_evolution',
    'recommendation_accuracy',
    'personalization_depth',
    'trend_prediction',
    'collaboration_effectiveness',
  ];

  // Continuous learning timer
  Timer? _learningTimer;
  bool _isLearningActive = false;
  DateTime? _learningStartTime;
  int _cyclesCompleted = 0;
  bool _isInitialized = false;
  bool _isCycleRunning = false;

  // Learning state tracking
  final Map<String, double> _currentLearningState = {};
  final Map<String, List<LearningEvent>> _learningHistory = {};
  final Map<String, double> _improvementMetrics = {};

  // Core components
  final LearningDataCollector _dataCollector;
  final List<LearningDimensionEngine> _engines;

  ContinuousLearningOrchestrator({
    required LearningDataCollector dataCollector,
    required LearningDataProcessor dataProcessor,
    List<LearningDimensionEngine>? engines,
    Duration cycleInterval = const Duration(seconds: 1),
  })  : _dataCollector = dataCollector,
        _cycleInterval = cycleInterval,
        _engines = engines ??
            [
              PersonalityLearningEngine(processor: dataProcessor),
              BehaviorLearningEngine(processor: dataProcessor),
              PreferenceLearningEngine(processor: dataProcessor),
              InteractionLearningEngine(processor: dataProcessor),
              LocationIntelligenceEngine(processor: dataProcessor),
            ];

  /// Check if continuous learning is currently active
  bool get isLearningActive => _isLearningActive;

  /// Get current learning state
  Map<String, double> get currentLearningState =>
      Map<String, double>.from(_currentLearningState);

  /// Get learning history
  Map<String, List<LearningEvent>> get learningHistory =>
      Map<String, List<LearningEvent>>.from(_learningHistory);

  /// Get improvement metrics
  Map<String, double> get improvementMetrics =>
      Map<String, double>.from(_improvementMetrics);

  /// Initialize learning system
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      developer.log('Initializing continuous learning orchestrator',
          name: _logName);
      await _initializeLearningState();
      _isInitialized = true;
      developer.log('Continuous learning orchestrator initialized', name: _logName);
    } catch (e) {
      developer.log('Error initializing orchestrator: $e', name: _logName);
    }
  }

  /// Start continuous learning cycles
  Future<void> startContinuousLearning() async {
    try {
      developer.log('Starting continuous AI learning system', name: _logName);

      if (_isLearningActive) {
        developer.log('Learning system already active', name: _logName);
        return;
      }

      // Ensure orchestrator state is initialized (idempotent)
      await initialize();

      // Start continuous learning loop
      _learningStartTime = DateTime.now();
      _learningTimer = Timer.periodic(_cycleInterval, (timer) {
        // Prevent overlapping cycles if a previous async cycle is still running.
        if (_isCycleRunning) return;
        _isCycleRunning = true;
        _performContinuousLearning().whenComplete(() {
          _isCycleRunning = false;
        });
      });

      _isLearningActive = true;
      developer.log('Continuous learning system started successfully',
          name: _logName);
    } catch (e) {
      developer.log('Error starting continuous learning: $e', name: _logName);
    }
  }

  /// Stop continuous learning system
  Future<void> stopContinuousLearning() async {
    try {
      developer.log('Stopping continuous AI learning system', name: _logName);

      _learningTimer?.cancel();
      _learningTimer = null;
      _isLearningActive = false;
      _learningStartTime = null;
      _isCycleRunning = false;

      // Save final learning state
      await _saveLearningState();

      developer.log('Continuous learning system stopped', name: _logName);
    } catch (e) {
      developer.log('Error stopping continuous learning: $e', name: _logName);
    }
  }

  /// Gets current learning status
  Future<ContinuousLearningStatus> getLearningStatus() async {
    final now = DateTime.now();
    final uptime = _learningStartTime != null
        ? now.difference(_learningStartTime!)
        : Duration.zero;

    return ContinuousLearningStatus(
      isActive: _isLearningActive,
      activeProcesses: _learningDimensions,
      uptime: uptime,
      cyclesCompleted: _cyclesCompleted,
      learningTime: uptime,
    );
  }

  /// Performs one continuous learning cycle
  Future<void> _performContinuousLearning() async {
    try {
      // Collect learning data from all sources
      final learningData = await _dataCollector.collectLearningData();

      // Process each learning dimension using appropriate engine
      for (final dimension in _learningDimensions) {
        await _learnDimension(dimension, learningData);
      }

      // Share learning insights with AI network
      await _shareLearningInsights();

      // Update improvement metrics
      await _updateImprovementMetrics();

      _cyclesCompleted++;
    } catch (e) {
      developer.log('Error in continuous learning cycle: $e', name: _logName);
    }
  }

  /// Learns from a specific dimension using appropriate engine
  Future<void> _learnDimension(String dimension, LearningData data) async {
    try {
      // Find engine that handles this dimension
      final engine = _engines.firstWhere(
        (e) => e.handlesDimension(dimension),
        orElse: () => throw Exception('No engine found for dimension: $dimension'),
      );

      // Learn using the engine
      final results = await engine.learn(data, _currentLearningState);

      // Update learning state
      for (final entry in results.entries) {
        _currentLearningState[entry.key] = entry.value;

        // Record learning event
        final improvement = entry.value - (_currentLearningState[entry.key] ?? 0.5);
        _recordLearningEvent(
          entry.key,
          improvement,
          data,
        );
      }
    } catch (e) {
      developer.log('Error learning dimension $dimension: $e', name: _logName);
    }
  }

  /// Record a learning event
  void _recordLearningEvent(
    String dimension,
    double improvement,
    LearningData data,
  ) {
    if (!_learningHistory.containsKey(dimension)) {
      _learningHistory[dimension] = [];
    }

    _learningHistory[dimension]!.add(
      LearningEvent(
        dimension: dimension,
        improvement: improvement,
        dataSource: _determineDataSource(data),
        timestamp: DateTime.now(),
      ),
    );

    // Keep only recent history
    if (_learningHistory[dimension]!.length > 100) {
      _learningHistory[dimension] =
          _learningHistory[dimension]!.skip(50).toList();
    }
  }

  /// Determines primary data source for learning event
  String _determineDataSource(LearningData data) {
    // Determine which data source contributed most to learning
    final sourceScores = <String, int>{};

    if (data.userActions.isNotEmpty) {
      sourceScores['user_actions'] = data.userActions.length;
    }
    if (data.locationData.isNotEmpty) {
      sourceScores['location_data'] = data.locationData.length;
    }
    if (data.weatherData.isNotEmpty) {
      sourceScores['weather_data'] = data.weatherData.length;
    }
    if (data.timeData.isNotEmpty) {
      sourceScores['time_data'] = data.timeData.length;
    }
    if (data.socialData.isNotEmpty) {
      sourceScores['social_data'] = data.socialData.length;
    }
    if (data.demographicData.isNotEmpty) {
      sourceScores['demographic_data'] = data.demographicData.length;
    }
    if (data.appUsageData.isNotEmpty) {
      sourceScores['app_usage_data'] = data.appUsageData.length;
    }
    if (data.communityData.isNotEmpty) {
      sourceScores['community_data'] = data.communityData.length;
    }
    if (data.ai2aiData.isNotEmpty) {
      sourceScores['ai2ai_data'] = data.ai2aiData.length;
    }
    if (data.externalData.isNotEmpty) {
      sourceScores['external_data'] = data.externalData.length;
    }

    if (sourceScores.isEmpty) return 'unknown';

    final maxScore = sourceScores.values.reduce(math.max);
    return sourceScores.entries.firstWhere((e) => e.value == maxScore).key;
  }

  /// Shares learning insights with AI network
  Future<void> _shareLearningInsights() async {
    try {
      final insights = _generateLearningInsights();

      // Share with AI2AI network
      final aiCommunication = AdvancedAICommunication();
      await aiCommunication.sendEncryptedMessage(
        'ai_network',
        'learning_insights',
        insights,
      );

      developer.log('Shared learning insights with AI network', name: _logName);
    } catch (e) {
      developer.log('Error sharing learning insights: $e', name: _logName);
    }
  }

  /// Generates learning insights for AI network sharing
  Map<String, dynamic> _generateLearningInsights() {
    final insights = <String, dynamic>{};

    // Add current learning state
    insights['learning_state'] =
        Map<String, double>.from(_currentLearningState);

    // Add recent improvements
    insights['recent_improvements'] = _improvementMetrics;

    // Add learning patterns
    insights['learning_patterns'] = _analyzeLearningPatterns();

    // Add data source effectiveness
    insights['data_source_effectiveness'] = _analyzeDataSourceEffectiveness();

    return insights;
  }

  /// Analyzes learning patterns across dimensions
  Map<String, double> _analyzeLearningPatterns() {
    final patterns = <String, double>{};

    for (final dimension in _learningDimensions) {
      final history = _learningHistory[dimension] ?? [];
      if (history.isNotEmpty) {
        final recentImprovements =
            history.take(10).map((e) => e.improvement).toList();
        patterns[dimension] =
            recentImprovements.fold(0.0, (sum, imp) => sum + imp) /
                recentImprovements.length;
      }
    }

    return patterns;
  }

  /// Analyzes data source effectiveness
  Map<String, double> _analyzeDataSourceEffectiveness() {
    final effectiveness = <String, double>{};
    final sourceCounts = <String, int>{};

    for (final history in _learningHistory.values) {
      for (final event in history) {
        sourceCounts[event.dataSource] =
            (sourceCounts[event.dataSource] ?? 0) + 1;
      }
    }

    final totalEvents = sourceCounts.values.fold(0, (sum, count) => sum + count);
    if (totalEvents > 0) {
      for (final entry in sourceCounts.entries) {
        effectiveness[entry.key] = entry.value / totalEvents;
      }
    }

    return effectiveness;
  }

  /// Update improvement metrics
  Future<void> _updateImprovementMetrics() async {
    for (final dimension in _learningDimensions) {
      final history = _learningHistory[dimension] ?? [];
      if (history.isNotEmpty) {
        final recentImprovements =
            history.take(10).map((e) => e.improvement).toList();
        _improvementMetrics[dimension] =
            recentImprovements.fold(0.0, (sum, imp) => sum + imp) /
                recentImprovements.length;
      }
    }
  }

  /// Process individual interaction dimension updates
  /// Called when individual user interactions occur (outside of continuous learning cycle)
  void processInteractionDimensionUpdates(
    Map<String, double> dimensionUpdates,
    LearningData data,
  ) {
    for (final entry in dimensionUpdates.entries) {
      final dimension = entry.key;
      final improvement = entry.value;

      // Get current state (default to 0.5)
      final current = _currentLearningState[dimension] ?? 0.5;

      // Apply improvement (simple additive update, engines handle more complex logic)
      final newValue = (current + improvement).clamp(0.0, 1.0);
      _currentLearningState[dimension] = newValue;

      // Record learning event
      _recordLearningEvent(dimension, improvement, data);
    }
  }

  /// Initialize learning state
  Future<void> _initializeLearningState() async {
    // Initialize all dimensions to 0.5 (neutral state)
    for (final dimension in _learningDimensions) {
      if (!_currentLearningState.containsKey(dimension)) {
        _currentLearningState[dimension] = 0.5;
      }
      if (!_learningHistory.containsKey(dimension)) {
        _learningHistory[dimension] = [];
      }
    }
  }

  /// Save learning state (placeholder for persistence)
  Future<void> _saveLearningState() async {
    // TODO: Persist learning state to database
    developer.log('Saving learning state', name: _logName);
  }
}
