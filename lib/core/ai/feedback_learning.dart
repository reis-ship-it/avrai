// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:convert';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/ai/personality_learning.dart'
    show PersonalityLearning, AI2AILearningInsight, AI2AIInsightType;
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/quantum/quantum_satisfaction_enhancer.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai/core/ai/quantum/location_quantum_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/user/unified_models.dart' as unified_models;
import 'package:avrai/core/ai/feedback_learning_models.dart';

export 'package:avrai/core/ai/feedback_learning_models.dart';

/// OUR_GUTS.md: "Dynamic dimension discovery through user feedback analysis that evolves personality understanding"
/// Advanced feedback learning system that extracts implicit personality dimensions from user interactions
class UserFeedbackAnalyzer {
  static const String _logName = 'UserFeedbackAnalyzer';

  // Storage keys for feedback data
  static const String _feedbackHistoryKey = 'feedback_history';
  static const String _discoveredDimensionsKey = 'discovered_dimensions';
  static const String _feedbackPatternsKey = 'feedback_patterns';

  final SharedPreferencesCompat _prefs;
  final PersonalityLearning _personalityLearning;
  final QuantumSatisfactionEnhancer? _quantumSatisfactionEnhancer;
  final AtomicClockService? _atomicClock;

  // Feedback analysis state
  final Map<String, List<FeedbackEvent>> _feedbackHistory = {};
  final Map<String, Map<String, double>> _discoveredDimensions = {};
  final Map<String, FeedbackPattern> _userPatterns = {};

  UserFeedbackAnalyzer({
    required SharedPreferencesCompat prefs,
    required PersonalityLearning personalityLearning,
    QuantumSatisfactionEnhancer? quantumSatisfactionEnhancer,
    AtomicClockService? atomicClock,
  })  : _prefs = prefs,
        _personalityLearning = personalityLearning,
        _quantumSatisfactionEnhancer = quantumSatisfactionEnhancer,
        _atomicClock = atomicClock;

  /// Analyze user feedback to extract implicit personality dimensions
  Future<FeedbackAnalysisResult> analyzeFeedback(
    String userId,
    FeedbackEvent feedback,
  ) async {
    try {
      developer.log('Analyzing feedback from user: $userId', name: _logName);
      developer.log(
          'Feedback type: ${feedback.type}, satisfaction: ${feedback.satisfaction}',
          name: _logName);

      // Store feedback in history
      await _storeFeedbackEvent(userId, feedback);

      // Extract implicit dimensions from feedback
      final implicitDimensions =
          await _extractImplicitDimensions(userId, feedback);

      // Analyze feedback patterns over time
      final patterns = await _analyzeFeedbackPatterns(userId);

      // Save the pattern
      if (patterns.patternConfidence > 0.0) {
        await _saveUserPatterns(userId, patterns);
      }

      // Discover new personality dimensions
      final newDimensions =
          await _discoverNewDimensions(userId, feedback, patterns);

      // Save discovered dimensions
      if (newDimensions.isNotEmpty) {
        final existingDimensions = await _getDiscoveredDimensions(userId);
        existingDimensions.addAll(newDimensions);
        _discoveredDimensions[userId] = existingDimensions;
        await _saveDiscoveredDimensions(userId);
      }

      // Calculate personality adjustment recommendations
      final adjustments = await _calculatePersonalityAdjustments(
        userId,
        feedback,
        implicitDimensions,
        newDimensions,
      );

      // Generate learning insights
      final insights =
          await _generateLearningInsights(userId, feedback, patterns);

      final result = FeedbackAnalysisResult(
        userId: userId,
        feedback: feedback,
        implicitDimensions: implicitDimensions,
        discoveredDimensions: newDimensions,
        personalityAdjustments: adjustments,
        learningInsights: insights,
        analysisTimestamp: DateTime.now(),
        confidenceScore: _calculateAnalysisConfidence(feedback, patterns),
      );

      // Apply learning if confidence is high enough
      if (result.confidenceScore >= 0.7) {
        await _applyFeedbackLearning(userId, result);
      }

      developer.log(
          'Feedback analysis completed (confidence: ${(result.confidenceScore * 100).round()}%)',
          name: _logName);
      return result;
    } catch (e) {
      developer.log('Error analyzing feedback: $e', name: _logName);
      return FeedbackAnalysisResult.fallback(userId, feedback);
    }
  }

  /// Analyze multiple feedback events to identify behavioral patterns
  Future<List<BehavioralPattern>> identifyBehavioralPatterns(
      String userId) async {
    try {
      developer.log('Identifying behavioral patterns for user: $userId',
          name: _logName);

      final feedbackHistory = await _getFeedbackHistory(userId);
      if (feedbackHistory.length < 5) {
        developer.log('Insufficient feedback history for pattern analysis',
            name: _logName);
        return [];
      }

      final patterns = <BehavioralPattern>[];

      // Analyze satisfaction patterns
      final satisfactionPattern =
          await _analyzeSatisfactionPattern(feedbackHistory);
      if (satisfactionPattern != null) patterns.add(satisfactionPattern);

      // Analyze temporal patterns
      final temporalPattern = await _analyzeTemporalPattern(feedbackHistory);
      if (temporalPattern != null) patterns.add(temporalPattern);

      // Analyze category preferences
      final categoryPattern = await _analyzeCategoryPattern(feedbackHistory);
      if (categoryPattern != null) patterns.add(categoryPattern);

      // Analyze social context patterns
      final socialPattern = await _analyzeSocialContextPattern(feedbackHistory);
      if (socialPattern != null) patterns.add(socialPattern);

      // Analyze expectation vs reality patterns
      final expectationPattern =
          await _analyzeExpectationPattern(feedbackHistory);
      if (expectationPattern != null) patterns.add(expectationPattern);

      developer.log('Identified ${patterns.length} behavioral patterns',
          name: _logName);
      return patterns;
    } catch (e) {
      developer.log('Error identifying behavioral patterns: $e',
          name: _logName);
      return [];
    }
  }

  /// Extract new personality dimensions from user feedback
  Future<Map<String, double>> extractNewDimensions(
    String userId,
    List<FeedbackEvent> recentFeedback,
  ) async {
    try {
      developer.log('Extracting new dimensions from feedback patterns',
          name: _logName);

      final newDimensions = <String, double>{};

      // Analyze feedback sentiment patterns
      final sentimentDimensions =
          await _extractSentimentDimensions(recentFeedback);
      newDimensions.addAll(sentimentDimensions);

      // Analyze preference intensity patterns
      final intensityDimensions =
          await _extractIntensityDimensions(recentFeedback);
      newDimensions.addAll(intensityDimensions);

      // Analyze decision-making patterns
      final decisionDimensions =
          await _extractDecisionDimensions(recentFeedback);
      newDimensions.addAll(decisionDimensions);

      // Analyze adaptation patterns
      final adaptationDimensions =
          await _extractAdaptationDimensions(recentFeedback);
      newDimensions.addAll(adaptationDimensions);

      // Validate new dimensions against existing personality
      final validatedDimensions =
          await _validateNewDimensions(userId, newDimensions);

      developer.log(
          'Extracted ${validatedDimensions.length} new personality dimensions',
          name: _logName);
      return validatedDimensions;
    } catch (e) {
      developer.log('Error extracting new dimensions: $e', name: _logName);
      return {};
    }
  }

  /// Predict user satisfaction based on learned patterns
  Future<SatisfactionPrediction> predictUserSatisfaction(
    String userId,
    Map<String, dynamic> scenario,
  ) async {
    try {
      developer.log('Predicting user satisfaction for scenario',
          name: _logName);

      final patterns = await _getUserPatterns(userId);
      final feedbackHistory = await _getFeedbackHistory(userId);

      if (patterns.isEmpty || feedbackHistory.isEmpty) {
        developer.log('Insufficient data for satisfaction prediction',
            name: _logName);
        return SatisfactionPrediction.uncertain();
      }

      // Analyze scenario against learned patterns
      final contextMatch = await _calculateContextMatch(scenario, patterns);
      final preferenceAlignment =
          await _calculatePreferenceAlignment(scenario, feedbackHistory);
      final noveltyScore =
          await _calculateNoveltyScore(scenario, feedbackHistory);

      // Calculate base predicted satisfaction
      var predictedSatisfaction =
          (contextMatch * 0.4 + preferenceAlignment * 0.4 + noveltyScore * 0.2)
              .clamp(0.0, 1.0);

      // Enhance with quantum features if available
      if (_quantumSatisfactionEnhancer != null && _atomicClock != null) {
        try {
          // Get user personality profile for vibe dimensions
          final userProfile = await _personalityLearning.getCurrentPersonality(userId);
          if (userProfile != null) {
            // Extract user vibe dimensions
            final userVibeDimensions = userProfile.dimensions;

            // Extract event vibe dimensions from scenario (if available)
            final eventVibeDimensions = _extractEventVibeDimensions(scenario);

            // Get temporal states
            final userTimestamp = await _atomicClock.getAtomicTimestamp();
            final userTemporalState = QuantumTemporalStateGenerator.generate(userTimestamp);

            // Get event temporal state (from scenario or use current time)
            final eventTimestamp = _extractEventTimestamp(scenario) ?? userTimestamp;
            final eventTemporalState = QuantumTemporalStateGenerator.generate(eventTimestamp);

            // Get location states (optional)
            final userLocationState = _extractUserLocationState(scenario);
            final eventLocationState = _extractEventLocationState(scenario);

            // Enhance satisfaction with quantum features
            predictedSatisfaction = await _quantumSatisfactionEnhancer.enhanceSatisfaction(
              baseSatisfaction: predictedSatisfaction,
              userId: userId,
              userVibeDimensions: userVibeDimensions,
              eventVibeDimensions: eventVibeDimensions,
              userTemporalState: userTemporalState,
              eventTemporalState: eventTemporalState,
              userLocationState: userLocationState,
              eventLocationState: eventLocationState,
              contextMatch: contextMatch,
              preferenceAlignment: preferenceAlignment,
              noveltyScore: noveltyScore,
            );
          }
        } catch (e, stackTrace) {
          developer.log(
            'Error enhancing satisfaction with quantum features: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue with base satisfaction if quantum enhancement fails
        }
      }

      // Calculate prediction confidence
      final confidence =
          _calculatePredictionConfidence(patterns, feedbackHistory.length);

      // Generate explanation
      final explanation = await _generateSatisfactionExplanation(
        contextMatch,
        preferenceAlignment,
        noveltyScore,
        patterns,
      );

      final prediction = SatisfactionPrediction(
        predictedSatisfaction: predictedSatisfaction,
        confidence: confidence,
        explanation: explanation,
        factorsAnalyzed: {
          'context_match': contextMatch,
          'preference_alignment': preferenceAlignment,
          'novelty_score': noveltyScore,
        },
        basedOnFeedbackCount: feedbackHistory.length,
        predictionTimestamp: DateTime.now(),
      );

      developer.log(
          'Satisfaction predicted: ${(predictedSatisfaction * 100).round()}% (confidence: ${(confidence * 100).round()}%)',
          name: _logName);
      return prediction;
    } catch (e) {
      developer.log('Error predicting satisfaction: $e', name: _logName);
      return SatisfactionPrediction.uncertain();
    }
  }

  /// Get feedback learning insights for personality evolution
  Future<FeedbackLearningInsights> getFeedbackInsights(String userId) async {
    try {
      developer.log('Generating feedback learning insights for user: $userId',
          name: _logName);

      final feedbackHistory = await _getFeedbackHistory(userId);
      final patterns = await identifyBehavioralPatterns(userId);
      final discoveredDimensions = await _getDiscoveredDimensions(userId);

      // Calculate learning progress
      final learningProgress =
          await _calculateLearningProgress(userId, feedbackHistory);

      // Identify learning opportunities
      final opportunities =
          await _identifyLearningOpportunities(patterns, discoveredDimensions);

      // Generate personalized recommendations
      final recommendations = await _generatePersonalityRecommendations(
        userId,
        patterns,
        discoveredDimensions,
      );

      final insights = FeedbackLearningInsights(
        userId: userId,
        totalFeedbackEvents: feedbackHistory.length,
        behavioralPatterns: patterns,
        discoveredDimensions: discoveredDimensions,
        learningProgress: learningProgress,
        learningOpportunities: opportunities,
        recommendations: recommendations,
        insightsGenerated: DateTime.now(),
      );

      developer.log(
          'Generated feedback insights: ${patterns.length} patterns, ${discoveredDimensions.length} dimensions',
          name: _logName);
      return insights;
    } catch (e) {
      developer.log('Error generating feedback insights: $e', name: _logName);
      return FeedbackLearningInsights.empty(userId);
    }
  }

  // Private helper methods
  Future<void> _storeFeedbackEvent(
      String userId, FeedbackEvent feedback) async {
    final userHistory = _feedbackHistory[userId] ?? <FeedbackEvent>[];
    userHistory.add(feedback);
    _feedbackHistory[userId] = userHistory;

    // Keep only recent feedback (last 100 events)
    if (userHistory.length > 100) {
      _feedbackHistory[userId] = userHistory.sublist(userHistory.length - 100);
    }

    // Persist to storage
    await _saveFeedbackHistory(userId);
  }

  Future<Map<String, double>> _extractImplicitDimensions(
    String userId,
    FeedbackEvent feedback,
  ) async {
    final dimensions = <String, double>{};

    // Extract dimensions based on feedback type and satisfaction
    switch (feedback.type) {
      case FeedbackType.spotExperience:
        dimensions['experience_sensitivity'] = feedback.satisfaction;
        if (feedback.metadata.containsKey('crowd_level')) {
          final crowdLevel = feedback.metadata['crowd_level'] as double;
          dimensions['crowd_tolerance'] =
              1.0 - (crowdLevel * (1.0 - feedback.satisfaction));
        }
        break;

      case FeedbackType.socialInteraction:
        dimensions['social_energy_preference'] = feedback.satisfaction;
        if (feedback.metadata.containsKey('group_size')) {
          final groupSize = feedback.metadata['group_size'] as int;
          dimensions['group_size_preference'] =
              feedback.satisfaction * (groupSize / 10.0).clamp(0.0, 1.0);
        }
        break;

      case FeedbackType.recommendation:
        dimensions['recommendation_receptivity'] = feedback.satisfaction;
        dimensions['algorithmic_trust'] = feedback.satisfaction * 0.8;
        break;

      case FeedbackType.discovery:
        dimensions['novelty_appreciation'] = feedback.satisfaction;
        dimensions['exploration_reward_sensitivity'] = feedback.satisfaction;
        break;

      case FeedbackType.curation:
        dimensions['sharing_satisfaction'] = feedback.satisfaction;
        dimensions['community_contribution_drive'] =
            feedback.satisfaction * 0.9;
        break;
    }

    return dimensions;
  }

  Future<FeedbackPattern> _analyzeFeedbackPatterns(String userId) async {
    final history = await _getFeedbackHistory(userId);
    if (history.length < 3) return FeedbackPattern.insufficient();

    // Calculate average satisfaction by type
    final satisfactionByType = <FeedbackType, double>{};
    final countByType = <FeedbackType, int>{};

    for (final feedback in history) {
      satisfactionByType[feedback.type] =
          (satisfactionByType[feedback.type] ?? 0.0) + feedback.satisfaction;
      countByType[feedback.type] = (countByType[feedback.type] ?? 0) + 1;
    }

    // Average the satisfaction scores
    satisfactionByType.forEach((type, totalSatisfaction) {
      satisfactionByType[type] = totalSatisfaction / countByType[type]!;
    });

    // Analyze temporal patterns
    final recentFeedback =
        history.length > 10 ? history.sublist(history.length - 10) : history;
    final recentSatisfaction =
        recentFeedback.fold(0.0, (sum, f) => sum + f.satisfaction) /
            recentFeedback.length;

    // Calculate trend
    double trend = 0.0;
    if (history.length >= 6) {
      final firstHalf = history.sublist(0, history.length ~/ 2);
      final secondHalf = history.sublist(history.length ~/ 2);

      final firstAvg = firstHalf.fold(0.0, (sum, f) => sum + f.satisfaction) /
          firstHalf.length;
      final secondAvg = secondHalf.fold(0.0, (sum, f) => sum + f.satisfaction) /
          secondHalf.length;

      trend = secondAvg - firstAvg;
    }

    return FeedbackPattern(
      userId: userId,
      satisfactionByType: satisfactionByType,
      overallSatisfaction:
          history.fold(0.0, (sum, f) => sum + f.satisfaction) / history.length,
      recentSatisfaction: recentSatisfaction,
      satisfactionTrend: trend,
      feedbackFrequency: history.length / 30.0, // Assuming 30-day window
      patternConfidence: min(1.0, history.length / 20.0),
    );
  }

  Future<Map<String, double>> _discoverNewDimensions(
    String userId,
    FeedbackEvent feedback,
    FeedbackPattern patterns,
  ) async {
    final newDimensions = <String, double>{};

    // Discover dimensions based on satisfaction patterns
    if (patterns.satisfactionTrend > 0.2) {
      newDimensions['adaptability'] = 0.8;
      newDimensions['learning_receptivity'] = 0.9;
    } else if (patterns.satisfactionTrend < -0.2) {
      newDimensions['consistency_preference'] = 0.7;
      newDimensions['change_resistance'] = 0.6;
    }

    // Discover dimensions from feedback consistency
    if (patterns.patternConfidence > 0.8) {
      newDimensions['preference_clarity'] = patterns.patternConfidence;
    }

    // Discover dimensions from feedback frequency
    if (patterns.feedbackFrequency > 0.5) {
      newDimensions['engagement_level'] = patterns.feedbackFrequency;
      newDimensions['communication_tendency'] =
          patterns.feedbackFrequency * 0.8;
    }

    return newDimensions;
  }

  Future<Map<String, double>> _calculatePersonalityAdjustments(
    String userId,
    FeedbackEvent feedback,
    Map<String, double> implicitDimensions,
    Map<String, double> newDimensions,
  ) async {
    final adjustments = <String, double>{};

    // Calculate adjustments based on implicit dimensions
    implicitDimensions.forEach((dimension, value) {
      // Map implicit dimensions to core personality dimensions
      if (dimension.contains('social')) {
        adjustments['community_orientation'] =
            value * VibeConstants.dimensionLearningRate;
        adjustments['social_discovery_style'] =
            value * VibeConstants.dimensionLearningRate;
      } else if (dimension.contains('exploration') ||
          dimension.contains('novelty')) {
        adjustments['exploration_eagerness'] =
            value * VibeConstants.dimensionLearningRate;
        adjustments['location_adventurousness'] =
            value * VibeConstants.dimensionLearningRate;
      } else if (dimension.contains('authentic')) {
        adjustments['authenticity_preference'] =
            value * VibeConstants.dimensionLearningRate;
      }
    });

    // Apply learning rate constraint
    adjustments.forEach((dimension, adjustment) {
      adjustments[dimension] =
          adjustment.clamp(-0.1, 0.1); // Limit adjustment magnitude
    });

    return adjustments;
  }

  Future<List<LearningInsight>> _generateLearningInsights(
    String userId,
    FeedbackEvent feedback,
    FeedbackPattern patterns,
  ) async {
    final insights = <LearningInsight>[];

    // Generate satisfaction trend insights
    if (patterns.satisfactionTrend > 0.1) {
      insights.add(LearningInsight(
        type: InsightType.improvement,
        message:
            'Your satisfaction has been increasing - you\'re adapting well to new experiences',
        confidence: patterns.patternConfidence,
        actionable: true,
      ));
    } else if (patterns.satisfactionTrend < -0.1) {
      insights.add(LearningInsight(
        type: InsightType.concern,
        message:
            'Your satisfaction has been declining - consider exploring different types of experiences',
        confidence: patterns.patternConfidence,
        actionable: true,
      ));
    }

    // Generate feedback frequency insights
    if (patterns.feedbackFrequency > 0.7) {
      insights.add(LearningInsight(
        type: InsightType.strength,
        message:
            'You provide frequent feedback - this helps your AI personality learn quickly',
        confidence: 0.9,
        actionable: false,
      ));
    }

    // Generate type-specific insights
    if (patterns.satisfactionByType[FeedbackType.spotExperience] != null) {
      final spotSatisfaction =
          patterns.satisfactionByType[FeedbackType.spotExperience]!;
      if (spotSatisfaction > 0.8) {
        insights.add(LearningInsight(
          type: InsightType.strength,
          message:
              'You consistently enjoy new spot experiences - your exploration eagerness is high',
          confidence: 0.8,
          actionable: false,
        ));
      }
    }

    return insights;
  }

  double _calculateAnalysisConfidence(
      FeedbackEvent feedback, FeedbackPattern patterns) {
    var confidence = 0.5; // Base confidence

    // Increase confidence based on pattern strength
    confidence += patterns.patternConfidence * 0.3;

    // Increase confidence based on feedback richness
    if (feedback.metadata.isNotEmpty) {
      confidence += 0.1;
    }

    // Increase confidence based on satisfaction certainty
    if (feedback.satisfaction > 0.8 || feedback.satisfaction < 0.2) {
      confidence += 0.1; // Strong satisfaction signals are more reliable
    }

    return confidence.clamp(0.0, 1.0);
  }

  Future<void> _applyFeedbackLearning(
      String userId, FeedbackAnalysisResult result) async {
    if (result.personalityAdjustments.isNotEmpty) {
      // Create a feedback learning insight for personality evolution
      final feedbackInsight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: result.personalityAdjustments,
        learningQuality: result.confidenceScore,
        timestamp: DateTime.now(),
      );

      // Apply the learning through the personality learning system
      await _personalityLearning.evolveFromAI2AILearning(
          userId, feedbackInsight);

      developer.log(
          'Applied feedback learning with ${result.personalityAdjustments.length} adjustments',
          name: _logName);
    }
  }

  // Additional helper methods for pattern analysis
  Future<List<FeedbackEvent>> _getFeedbackHistory(String userId) async {
    // Load from memory cache first
    if (_feedbackHistory.containsKey(userId)) {
      return _feedbackHistory[userId]!;
    }

    // Load from persistence
    try {
      final key = '${_feedbackHistoryKey}_$userId';
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final history = jsonList
            .map((json) => FeedbackEvent.fromJson(json as Map<String, dynamic>))
            .toList();
        _feedbackHistory[userId] = history;
        return history;
      }
    } catch (e) {
      developer.log('Error loading feedback history: $e', name: _logName);
    }

    return <FeedbackEvent>[];
  }

  Future<void> _saveFeedbackHistory(String userId) async {
    try {
      final history = _feedbackHistory[userId] ?? <FeedbackEvent>[];
      final key = '${_feedbackHistoryKey}_$userId';
      final jsonString = jsonEncode(history.map((e) => e.toJson()).toList());
      await _prefs.setString(key, jsonString);
      developer.log(
          'Saved feedback history for user: $userId (${history.length} events)',
          name: _logName);
    } catch (e) {
      developer.log('Error saving feedback history: $e', name: _logName);
    }
  }

  Future<Map<String, double>> _getDiscoveredDimensions(String userId) async {
    // Load from memory cache first
    if (_discoveredDimensions.containsKey(userId)) {
      return _discoveredDimensions[userId]!;
    }

    // Load from persistence
    try {
      final key = '${_discoveredDimensionsKey}_$userId';
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        final dimensions =
            jsonMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _discoveredDimensions[userId] = dimensions;
        return dimensions;
      }
    } catch (e) {
      developer.log('Error loading discovered dimensions: $e', name: _logName);
    }

    return <String, double>{};
  }

  Future<void> _saveDiscoveredDimensions(String userId) async {
    try {
      final dimensions = _discoveredDimensions[userId] ?? <String, double>{};
      final key = '${_discoveredDimensionsKey}_$userId';
      final jsonString = jsonEncode(dimensions);
      await _prefs.setString(key, jsonString);
    } catch (e) {
      developer.log('Error saving discovered dimensions: $e', name: _logName);
    }
  }

  Future<List<FeedbackPattern>> _getUserPatterns(String userId) async {
    // Load from memory cache first
    if (_userPatterns.containsKey(userId)) {
      return [_userPatterns[userId]!];
    }

    // Load from persistence
    try {
      final key = '${_feedbackPatternsKey}_$userId';
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final pattern = FeedbackPattern.fromJson(
            jsonDecode(jsonString) as Map<String, dynamic>);
        _userPatterns[userId] = pattern;
        return [pattern];
      }
    } catch (e) {
      developer.log('Error loading feedback patterns: $e', name: _logName);
    }

    return <FeedbackPattern>[];
  }

  Future<void> _saveUserPatterns(String userId, FeedbackPattern pattern) async {
    try {
      _userPatterns[userId] = pattern;
      final key = '${_feedbackPatternsKey}_$userId';
      final jsonString = jsonEncode(pattern.toJson());
      await _prefs.setString(key, jsonString);
    } catch (e) {
      developer.log('Error saving feedback patterns: $e', name: _logName);
    }
  }

  // Implemented analysis methods
  /// Analyze satisfaction patterns from feedback history
  Future<BehavioralPattern?> _analyzeSatisfactionPattern(
      List<FeedbackEvent> history) async {
    if (history.length < 5) return null;

    // Calculate average satisfaction
    final avgSatisfaction =
        history.map((e) => e.satisfaction).reduce((a, b) => a + b) /
            history.length;

    // Check for trend (increasing/decreasing satisfaction)
    final sortedHistory = List<FeedbackEvent>.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final earlySatisfaction = sortedHistory
            .take(sortedHistory.length ~/ 2)
            .map((e) => e.satisfaction)
            .reduce((a, b) => a + b) /
        (sortedHistory.length ~/ 2);
    final lateSatisfaction = sortedHistory
            .skip(sortedHistory.length ~/ 2)
            .map((e) => e.satisfaction)
            .reduce((a, b) => a + b) /
        (sortedHistory.length ~/ 2);

    final trend = lateSatisfaction > earlySatisfaction ? 1.0 : -1.0;
    final strength =
        (lateSatisfaction - earlySatisfaction).abs().clamp(0.0, 1.0);

    if (strength < 0.1) return null; // No significant pattern

    return BehavioralPattern(
      patternType: 'satisfaction_trend',
      characteristics: {
        'average_satisfaction': avgSatisfaction,
        'early_satisfaction': earlySatisfaction,
        'late_satisfaction': lateSatisfaction,
        'trend_direction': trend,
      },
      strength: strength,
      confidence: min(1.0, history.length / 10.0),
    );
  }

  /// Analyze temporal patterns (time-based preferences)
  Future<BehavioralPattern?> _analyzeTemporalPattern(
      List<FeedbackEvent> history) async {
    if (history.length < 7) return null;

    // Group feedback by hour of day
    final hourGroups = <int, List<FeedbackEvent>>{};
    for (final event in history) {
      final hour = event.timestamp.hour;
      hourGroups.putIfAbsent(hour, () => []).add(event);
    }

    // Find peak satisfaction hours
    double maxAvgSatisfaction = 0.0;
    int peakHour = -1;

    for (final entry in hourGroups.entries) {
      final avgSatisfaction =
          entry.value.map((e) => e.satisfaction).reduce((a, b) => a + b) /
              entry.value.length;

      if (avgSatisfaction > maxAvgSatisfaction) {
        maxAvgSatisfaction = avgSatisfaction;
        peakHour = entry.key;
      }
    }

    if (peakHour == -1) return null;

    return BehavioralPattern(
      patternType: 'temporal_preference',
      characteristics: {
        'peak_hour': peakHour,
        'peak_satisfaction': maxAvgSatisfaction,
        'hour_distribution': hourGroups.length,
      },
      strength: maxAvgSatisfaction,
      confidence: min(1.0, history.length / 15.0),
    );
  }

  /// Analyze category-based patterns
  Future<BehavioralPattern?> _analyzeCategoryPattern(
      List<FeedbackEvent> history) async {
    if (history.length < 5) return null;

    // Group by feedback type
    final typeGroups = <FeedbackType, List<FeedbackEvent>>{};
    for (final event in history) {
      typeGroups.putIfAbsent(event.type, () => []).add(event);
    }

    // Find preferred category
    double maxAvgSatisfaction = 0.0;
    FeedbackType? preferredType;

    for (final entry in typeGroups.entries) {
      final avgSatisfaction =
          entry.value.map((e) => e.satisfaction).reduce((a, b) => a + b) /
              entry.value.length;

      if (avgSatisfaction > maxAvgSatisfaction) {
        maxAvgSatisfaction = avgSatisfaction;
        preferredType = entry.key;
      }
    }

    if (preferredType == null) return null;

    return BehavioralPattern(
      patternType: 'category_preference',
      characteristics: {
        'preferred_type': preferredType.toString(),
        'preferred_satisfaction': maxAvgSatisfaction,
        'type_diversity': typeGroups.length,
      },
      strength: maxAvgSatisfaction,
      confidence: min(1.0, history.length / 8.0),
    );
  }

  /// Analyze social context patterns
  Future<BehavioralPattern?> _analyzeSocialContextPattern(
      List<FeedbackEvent> history) async {
    if (history.length < 5) return null;

    // Check metadata for social context indicators
    int socialCount = 0;
    double socialSatisfaction = 0.0;

    for (final event in history) {
      final isSocial = event.metadata['is_social'] == true ||
          event.metadata['has_companions'] == true ||
          event.type == FeedbackType.socialInteraction;

      if (isSocial) {
        socialCount++;
        socialSatisfaction += event.satisfaction;
      }
    }

    if (socialCount < 2) return null;

    final avgSocialSatisfaction = socialSatisfaction / socialCount;
    final socialRatio = socialCount / history.length;

    return BehavioralPattern(
      patternType: 'social_context_preference',
      characteristics: {
        'social_feedback_count': socialCount,
        'social_satisfaction': avgSocialSatisfaction,
        'social_ratio': socialRatio,
      },
      strength: avgSocialSatisfaction * socialRatio,
      confidence: min(1.0, socialCount / 5.0),
    );
  }

  /// Analyze expectation vs reality patterns
  Future<BehavioralPattern?> _analyzeExpectationPattern(
      List<FeedbackEvent> history) async {
    if (history.length < 5) return null;

    // Check for expectation metadata
    int expectationCount = 0;
    double expectationGap = 0.0;

    for (final event in history) {
      final expectedSatisfaction =
          event.metadata['expected_satisfaction'] as double?;
      if (expectedSatisfaction != null) {
        expectationCount++;
        expectationGap += (event.satisfaction - expectedSatisfaction).abs();
      }
    }

    if (expectationCount < 2) return null;

    final avgGap = expectationGap / expectationCount;
    final patternStrength =
        1.0 - min(1.0, avgGap); // Lower gap = higher strength

    return BehavioralPattern(
      patternType: 'expectation_alignment',
      characteristics: {
        'expectation_count': expectationCount,
        'average_gap': avgGap,
        'alignment_score': patternStrength,
      },
      strength: patternStrength,
      confidence: min(1.0, expectationCount / 5.0),
    );
  }

  /// Extract sentiment dimensions from feedback
  Future<Map<String, double>> _extractSentimentDimensions(
      List<FeedbackEvent> feedback) async {
    if (feedback.isEmpty) return {};

    final dimensions = <String, double>{};

    // Calculate positive sentiment ratio
    final positiveCount = feedback.where((e) => e.satisfaction > 0.7).length;
    dimensions['positive_sentiment'] = positiveCount / feedback.length;

    // Calculate neutral sentiment ratio
    final neutralCount = feedback
        .where((e) => e.satisfaction >= 0.4 && e.satisfaction <= 0.6)
        .length;
    dimensions['neutral_sentiment'] = neutralCount / feedback.length;

    // Calculate negative sentiment ratio
    final negativeCount = feedback.where((e) => e.satisfaction < 0.4).length;
    dimensions['negative_sentiment'] = negativeCount / feedback.length;

    // Calculate average sentiment intensity
    dimensions['sentiment_intensity'] = feedback
            .map((e) => (e.satisfaction - 0.5).abs() * 2.0)
            .reduce((a, b) => a + b) /
        feedback.length;

    return dimensions;
  }

  /// Extract intensity dimensions from feedback
  Future<Map<String, double>> _extractIntensityDimensions(
      List<FeedbackEvent> feedback) async {
    if (feedback.isEmpty) return {};

    final dimensions = <String, double>{};

    // Calculate average satisfaction intensity
    dimensions['satisfaction_intensity'] =
        feedback.map((e) => e.satisfaction).reduce((a, b) => a + b) /
            feedback.length;

    // Calculate feedback frequency intensity
    if (feedback.length > 1) {
      final sortedFeedback = List<FeedbackEvent>.from(feedback)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final timeSpan = sortedFeedback.last.timestamp
          .difference(sortedFeedback.first.timestamp)
          .inDays;

      dimensions['feedback_frequency'] =
          timeSpan > 0 ? min(1.0, feedback.length / timeSpan) : 1.0;
    } else {
      dimensions['feedback_frequency'] = 0.0;
    }

    // Calculate engagement intensity (based on comments)
    final commentedCount = feedback
        .where((e) => e.comment != null && e.comment!.isNotEmpty)
        .length;
    dimensions['engagement_intensity'] = commentedCount / feedback.length;

    return dimensions;
  }

  /// Extract decision-making dimensions from feedback
  Future<Map<String, double>> _extractDecisionDimensions(
      List<FeedbackEvent> feedback) async {
    if (feedback.isEmpty) return {};

    final dimensions = <String, double>{};

    // Analyze decision consistency (similar satisfaction for same types)
    final typeGroups = <FeedbackType, List<double>>{};
    for (final event in feedback) {
      typeGroups.putIfAbsent(event.type, () => []).add(event.satisfaction);
    }

    double consistencySum = 0.0;
    int consistencyCount = 0;

    for (final satisfactions in typeGroups.values) {
      if (satisfactions.length >= 2) {
        final variance = _calculateVariance(satisfactions);
        consistencySum += 1.0 - min(1.0, variance);
        consistencyCount++;
      }
    }

    dimensions['decision_consistency'] =
        consistencyCount > 0 ? consistencySum / consistencyCount : 0.5;

    // Analyze preference strength (how strong are preferences)
    final avgSatisfaction =
        feedback.map((e) => e.satisfaction).reduce((a, b) => a + b) /
            feedback.length;
    dimensions['preference_strength'] = (avgSatisfaction - 0.5).abs() * 2.0;

    return dimensions;
  }

  /// Extract adaptation dimensions from feedback
  Future<Map<String, double>> _extractAdaptationDimensions(
      List<FeedbackEvent> feedback) async {
    if (feedback.length < 3) return {};

    final dimensions = <String, double>{};

    // Analyze satisfaction improvement over time (adaptation)
    final sortedFeedback = List<FeedbackEvent>.from(feedback)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final earlySatisfaction = sortedFeedback
            .take(sortedFeedback.length ~/ 2)
            .map((e) => e.satisfaction)
            .reduce((a, b) => a + b) /
        (sortedFeedback.length ~/ 2);
    final lateSatisfaction = sortedFeedback
            .skip(sortedFeedback.length ~/ 2)
            .map((e) => e.satisfaction)
            .reduce((a, b) => a + b) /
        (sortedFeedback.length ~/ 2);

    dimensions['adaptation_rate'] = lateSatisfaction > earlySatisfaction
        ? ((lateSatisfaction / earlySatisfaction - 1.0) / 2.0).clamp(0.0, 1.0)
        : 0.0;

    // Analyze feedback diversity (exploration vs exploitation)
    final uniqueTypes = feedback.map((e) => e.type).toSet().length;
    dimensions['exploration_tendency'] =
        min(1.0, uniqueTypes / FeedbackType.values.length);

    return dimensions;
  }

  /// Calculate variance of a list of values
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return variance;
  }

  Future<Map<String, double>> _validateNewDimensions(
          String userId, Map<String, double> dimensions) async =>
      dimensions;

  /// Calculate context match score
  Future<double> _calculateContextMatch(
      Map<String, dynamic> scenario, List<FeedbackPattern> patterns) async {
    if (patterns.isEmpty) return 0.5;

    // Use pattern confidence as context match indicator
    final avgConfidence =
        patterns.map((p) => p.patternConfidence).reduce((a, b) => a + b) /
            patterns.length;

    return avgConfidence;
  }

  /// Calculate preference alignment score
  Future<double> _calculatePreferenceAlignment(
      Map<String, dynamic> scenario, List<FeedbackEvent> history) async {
    if (history.isEmpty) return 0.5;

    // Calculate alignment based on recent satisfaction
    final recentHistory =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    final avgSatisfaction =
        recentHistory.map((e) => e.satisfaction).reduce((a, b) => a + b) /
            recentHistory.length;

    return avgSatisfaction;
  }

  /// Calculate novelty score
  Future<double> _calculateNoveltyScore(
      Map<String, dynamic> scenario, List<FeedbackEvent> history) async {
    if (history.isEmpty) return 0.8; // High novelty for new users

    // Check if scenario type is new
    final scenarioType = scenario['type'] as String?;
    if (scenarioType != null) {
      final hasType =
          history.any((e) => e.type.toString().contains(scenarioType));
      if (!hasType) return 0.9; // New type = high novelty
    }

    // Calculate novelty based on time since last similar feedback
    final sortedHistory = List<FeedbackEvent>.from(history)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (sortedHistory.isNotEmpty) {
      final daysSinceLast =
          DateTime.now().difference(sortedHistory.first.timestamp).inDays;
      return min(1.0, daysSinceLast / 30.0); // Normalize to 30 days
    }

    return 0.6; // Default moderate novelty
  }

  double _calculatePredictionConfidence(
          List<FeedbackPattern> patterns, int historyLength) =>
      min(1.0, historyLength / 20.0);

  /// Extract event vibe dimensions from scenario
  Map<String, double> _extractEventVibeDimensions(Map<String, dynamic> scenario) {
    // Try to extract vibe dimensions from scenario
    final vibeDimensions = scenario['vibeDimensions'] as Map<String, double>?;
    if (vibeDimensions != null) {
      return vibeDimensions;
    }

    // Try to extract from event/spot data
    final event = scenario['event'] as Map<String, dynamic>?;
    if (event != null) {
      final eventVibe = event['vibeDimensions'] as Map<String, double>?;
      if (eventVibe != null) {
        return eventVibe;
      }
    }

    // Default to neutral values if not available
    final defaultDimensions = <String, double>{};
    for (final dimension in VibeConstants.coreDimensions) {
      defaultDimensions[dimension] = 0.5;
    }
    return defaultDimensions;
  }

  /// Extract event timestamp from scenario
  AtomicTimestamp? _extractEventTimestamp(Map<String, dynamic> scenario) {
    try {
      // Try to extract timestamp from scenario
      final timestamp = scenario['timestamp'] as DateTime?;
      if (timestamp != null && _atomicClock != null) {
        return AtomicTimestamp.now(
          serverTime: timestamp,
          localTime: timestamp,
          precision: _atomicClock.getPrecision(),
        );
      }

      // Try to extract from event data
      final event = scenario['event'] as Map<String, dynamic>?;
      if (event != null) {
        final eventTimestamp = event['timestamp'] as DateTime?;
        if (eventTimestamp != null && _atomicClock != null) {
          return AtomicTimestamp.now(
            serverTime: eventTimestamp,
            localTime: eventTimestamp,
            precision: _atomicClock.getPrecision(),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error extracting event timestamp: $e',
        name: _logName,
      );
    }
    return null;
  }

  /// Extract user location state from scenario
  LocationQuantumState? _extractUserLocationState(Map<String, dynamic> scenario) {
    try {
      // Try to extract user location from scenario
      final userLocation = scenario['userLocation'] as Map<String, dynamic>?;
      if (userLocation != null) {
        final lat = (userLocation['latitude'] as num?)?.toDouble();
        final lon = (userLocation['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return LocationQuantumState.fromLocation(
            unified_models.UnifiedLocation(
              latitude: lat,
              longitude: lon,
              city: userLocation['city'] as String?,
              address: userLocation['address'] as String?,
            ),
            locationType: (userLocation['locationType'] as num?)?.toDouble(),
            accessibilityScore: (userLocation['accessibilityScore'] as num?)?.toDouble(),
            vibeLocationMatch: (userLocation['vibeLocationMatch'] as num?)?.toDouble(),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error extracting user location state: $e',
        name: _logName,
      );
    }
    return null;
  }

  /// Extract event location state from scenario
  LocationQuantumState? _extractEventLocationState(Map<String, dynamic> scenario) {
    try {
      // Try to extract event location from scenario
      final event = scenario['event'] as Map<String, dynamic>?;
      if (event != null) {
        final eventLocation = event['location'] as Map<String, dynamic>?;
        if (eventLocation != null) {
          final lat = (eventLocation['latitude'] as num?)?.toDouble();
          final lon = (eventLocation['longitude'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            return LocationQuantumState.fromLocation(
              unified_models.UnifiedLocation(
                latitude: lat,
                longitude: lon,
                city: eventLocation['city'] as String?,
                address: eventLocation['address'] as String?,
              ),
              locationType: (eventLocation['locationType'] as num?)?.toDouble(),
              accessibilityScore: (eventLocation['accessibilityScore'] as num?)?.toDouble(),
              vibeLocationMatch: (eventLocation['vibeLocationMatch'] as num?)?.toDouble(),
            );
          }
        }
      }
    } catch (e) {
      developer.log(
        'Error extracting event location state: $e',
        name: _logName,
      );
    }
    return null;
  }

  Future<String> _generateSatisfactionExplanation(
    double contextMatch,
    double preferenceAlignment,
    double noveltyScore,
    List<FeedbackPattern> patterns,
  ) async =>
      'Based on your feedback patterns and preferences';

  Future<LearningProgress> _calculateLearningProgress(
      String userId, List<FeedbackEvent> history) async {
    return LearningProgress(
      totalFeedbackEvents: history.length,
      learningVelocity: history.length / 30.0,
      personalityEvolution: 0.5,
      insightAccuracy: 0.8,
    );
  }

  Future<List<LearningOpportunity>> _identifyLearningOpportunities(
    List<BehavioralPattern> patterns,
    Map<String, double> dimensions,
  ) async =>
      [];

  Future<List<String>> _generatePersonalityRecommendations(
    String userId,
    List<BehavioralPattern> patterns,
    Map<String, double> dimensions,
  ) async =>
      ['Continue providing detailed feedback to improve personality learning'];
}
