import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Interaction Learning Engine
///
/// Handles learning dimensions related to social and community interactions:
/// - `social_dynamics`
/// - `community_evolution`
/// - `collaboration_effectiveness`
class InteractionLearningEngine implements LearningDimensionEngine {
  static const String _logName = 'InteractionLearningEngine';
  final LearningDataProcessor _processor;

  @override
  final List<String> dimensions = [
    'social_dynamics',
    'community_evolution',
    'collaboration_effectiveness',
  ];

  @override
  final Map<String, double> learningRates = {
    'social_dynamics': 0.13,
    'community_evolution': 0.11,
    'collaboration_effectiveness': 0.17,
  };

  InteractionLearningEngine({
    required LearningDataProcessor processor,
  }) : _processor = processor;

  @override
  Future<Map<String, double>> learn(
    LearningData data,
    Map<String, double> currentState,
  ) async {
    final results = <String, double>{};

    for (final dimension in dimensions) {
      try {
        final current = currentState[dimension] ?? 0.5;
        final learningRate = getLearningRate(dimension);
        final improvement = await calculateImprovement(dimension, data);

        // Apply learning with bounds
        final newState = math.max(
          0.0,
          math.min(1.0, current + (improvement * learningRate)),
        );

        results[dimension] = newState;
      } catch (e) {
        developer.log(
          'Error learning dimension $dimension: $e',
          name: _logName,
        );
        // Keep current state on error
        results[dimension] = currentState[dimension] ?? 0.5;
      }
    }

    return results;
  }

  @override
  Future<double> calculateImprovement(
    String dimension,
    LearningData data,
  ) async {
    switch (dimension) {
      case 'social_dynamics':
        return await _calculateSocialDynamicsImprovement(data);
      case 'community_evolution':
        return await _calculateCommunityEvolutionImprovement(data);
      case 'collaboration_effectiveness':
        return await _calculateCollaborationEffectivenessImprovement(data);
      default:
        return 0.01; // Default small improvement
    }
  }

  @override
  double getLearningRate(String dimension) {
    return learningRates[dimension] ?? 0.1;
  }

  @override
  bool handlesDimension(String dimension) {
    return dimensions.contains(dimension);
  }

  /// Calculates improvement in social dynamics understanding
  Future<double> _calculateSocialDynamicsImprovement(LearningData data) async {
    var improvement = 0.0;

    // Learn from social data
    if (data.socialData.isNotEmpty) {
      final socialPatterns = _processor.analyzeSocialPatterns(data.socialData);
      final socialNetworkDynamics =
          _processor.analyzeSocialNetworkDynamics(data.socialData);
      improvement += (socialPatterns + socialNetworkDynamics) * 0.4;
    }

    // Learn from community interactions
    if (data.communityData.isNotEmpty) {
      final communityDynamics = _processor.analyzeCommunityDynamics(data.communityData);
      improvement += communityDynamics * 0.3;
    }

    // Learn from demographic-social correlations
    if (data.demographicData.isNotEmpty && data.socialData.isNotEmpty) {
      final demographicSocialCorrelation = _processor.analyzeDemographicSocialCorrelation(
          data.demographicData, data.socialData);
      improvement += demographicSocialCorrelation * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }

  /// Calculates improvement in community evolution understanding
  Future<double> _calculateCommunityEvolutionImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from community evolution
    if (data.communityData.isNotEmpty) {
      final communityEvolution =
          _processor.analyzeCommunityEvolution(data.communityData);
      final communityGrowth = _processor.analyzeCommunityGrowth(data.communityData);
      improvement += (communityEvolution + communityGrowth) * 0.4;
    }

    // Learn from social network evolution
    if (data.socialData.isNotEmpty) {
      final socialNetworkEvolution =
          _processor.analyzeSocialNetworkEvolution(data.socialData);
      improvement += socialNetworkEvolution * 0.3;
    }

    // Learn from demographic evolution
    if (data.demographicData.isNotEmpty) {
      final demographicEvolution =
          _processor.analyzeDemographicEvolution(data.demographicData);
      improvement += demographicEvolution * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }

  /// Calculates improvement in collaboration effectiveness
  Future<double> _calculateCollaborationEffectivenessImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from AI collaboration
    if (data.ai2aiData.isNotEmpty) {
      final aiCollaboration = _processor.analyzeAICollaboration(data.ai2aiData);
      improvement += aiCollaboration * 0.4;
    }

    // Learn from community collaboration
    if (data.communityData.isNotEmpty) {
      final communityCollaboration =
          _processor.analyzeCommunityCollaboration(data.communityData);
      improvement += communityCollaboration * 0.3;
    }

    // Learn from social collaboration
    if (data.socialData.isNotEmpty) {
      final socialCollaboration =
          _processor.analyzeSocialCollaboration(data.socialData);
      improvement += socialCollaboration * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }
}
