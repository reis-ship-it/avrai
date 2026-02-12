import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/services/behavior/behavior_assessment_service.dart';
import 'package:avrai/core/services/calling_score/calling_score_data_collector.dart';
import 'package:avrai/core/services/calling_score/calling_score_ab_testing_service.dart';
import 'package:avrai/core/ml/calling_score_neural_model.dart';
import 'package:avrai/core/services/recommendations/outcome_prediction_service.dart';
import 'package:geolocator/geolocator.dart';

/// Calling Score Calculator
///
/// CORE PHILOSOPHY: "Calling to Action"
/// Users are called to action in the real world by being given spots, lists, places, events, etc.
/// that would make their life better based on meaningful connections and positive influence.
///
/// This service implements the unified "Calling Score" formula that combines:
/// - Vibe Compatibility (40%)
/// - Life Betterment Factor (30%)
/// - Meaningful Connection Probability (15%)
/// - Context Factor (10%)
/// - Timing Factor (5%)
/// - Trend Boost (optional multiplier)
class CallingScoreCalculator {
  static const String _logName = 'CallingScoreCalculator';

  final BehaviorAssessmentService _behaviorAssessment;
  final CallingScoreDataCollector? _dataCollector;
  final CallingScoreNeuralModel?
      _neuralModel; // Phase 12 Section 2.2: Hybrid calculation
  final CallingScoreABTestingService?
      _abTestingService; // Phase 12 Section 2.3: A/B testing
  final OutcomePredictionService?
      _outcomePredictionService; // Phase 12 Section 3.1: Outcome prediction

  CallingScoreCalculator({
    required BehaviorAssessmentService behaviorAssessment,
    CallingScoreDataCollector? dataCollector,
    CallingScoreNeuralModel?
        neuralModel, // Phase 12 Section 2.2: Optional neural model
    CallingScoreABTestingService?
        abTestingService, // Phase 12 Section 2.3: Optional A/B testing
    OutcomePredictionService?
        outcomePredictionService, // Phase 12 Section 3.1: Optional outcome prediction
  })  : _behaviorAssessment = behaviorAssessment,
        _dataCollector = dataCollector,
        _neuralModel = neuralModel,
        _abTestingService = abTestingService,
        _outcomePredictionService = outcomePredictionService;

  /// Calculate unified calling score for a spot/event/opportunity
  ///
  /// Returns score (0.0 to 1.0) where:
  /// - ≥ 0.70 = User is "called" to action
  /// - < 0.70 = Not called, but may still be recommended
  ///
  /// **Phase 12:** Optionally logs calculation data for neural network training
  Future<CallingScoreResult> calculateCallingScore({
    required UserVibe userVibe,
    required SpotVibe opportunityVibe,
    required CallingContext context,
    required TimingFactors timing,
    PersonalityProfile? userPersonality,
    List<RecentAction>? userHistory,
    TrendData? trends,
    String? userId, // Optional: For data collection (Phase 12)
  }) async {
    try {
      developer.log(
          'Calculating calling score for opportunity: ${opportunityVibe.spotId}',
          name: _logName);

      // 1. Vibe Compatibility (40% weight)
      final vibeCompatibility =
          opportunityVibe.calculateVibeCompatibility(userVibe);

      // 2. Life Betterment Factor (30% weight)
      final lifeBetterment = await _calculateLifeBettermentFactor(
        userVibe: userVibe,
        opportunityVibe: opportunityVibe,
        userPersonality: userPersonality,
        userHistory: userHistory,
      );

      // 3. Meaningful Connection Probability (15% weight)
      final meaningfulConnectionProb =
          await _calculateMeaningfulConnectionProbability(
        userVibe: userVibe,
        opportunityVibe: opportunityVibe,
        context: context,
      );

      // 4. Context Factor (10% weight)
      final contextFactor = _calculateContextFactor(context);

      // 5. Timing Factor (5% weight)
      final timingFactor = _calculateTimingFactor(timing);

      // Weighted combination (formula-based score)
      final formulaCallingScore = (vibeCompatibility * 0.40 +
              lifeBetterment * 0.30 +
              meaningfulConnectionProb * 0.15 +
              contextFactor * 0.10 +
              timingFactor * 0.05)
          .clamp(0.0, 1.0);

      // Phase 12 Section 2.3: A/B Testing - Determine user group
      ABTestGroup? userGroup;
      bool useHybrid = false;

      if (_abTestingService != null && userId != null) {
        userGroup = await _abTestingService.getUserGroup(userId: userId);
        useHybrid = userGroup == ABTestGroup.hybrid;
      }

      // Phase 12 Section 2.2: Hybrid calling score calculation
      // Combine formula-based score with neural network adjustment
      double finalCallingScore;
      double neuralNetworkScore = 0.0;
      double neuralNetworkWeight =
          0.0; // Start at 0.0, gradually increase to 0.3

      // Only use hybrid if user is in hybrid group AND model is available
      if (useHybrid && _neuralModel != null && _neuralModel.isLoaded) {
        try {
          // Prepare features for neural network
          final features = _prepareNeuralNetworkFeatures(
            userVibe: userVibe,
            opportunityVibe: opportunityVibe,
            context: context,
            timing: timing,
          );

          // Get neural network prediction
          neuralNetworkScore = await _neuralModel.predict(features);

          // Calculate neural network weight based on confidence
          // Start with 0.0 weight, gradually increase to 0.3 as model confidence grows
          // For now, use fixed 0.3 weight (can be made dynamic based on model performance)
          neuralNetworkWeight =
              0.3; // TODO: Make dynamic based on model confidence/performance

          // Hybrid calculation: Formula × (1 - weight) + Neural × weight
          final formulaWeight = 1.0 - neuralNetworkWeight;
          finalCallingScore = (formulaCallingScore * formulaWeight +
                  neuralNetworkScore * neuralNetworkWeight)
              .clamp(0.0, 1.0);

          developer.log(
            'Hybrid calling score: formula=${(formulaCallingScore * 100).toStringAsFixed(1)}%, '
            'neural=${(neuralNetworkScore * 100).toStringAsFixed(1)}%, '
            'weight=${(neuralNetworkWeight * 100).toStringAsFixed(1)}%, '
            'final=${(finalCallingScore * 100).toStringAsFixed(1)}%',
            name: _logName,
          );
        } catch (e, stackTrace) {
          developer.log(
            'Neural network prediction failed, using formula-based score: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Fallback to formula-based score
          finalCallingScore = formulaCallingScore;
        }
      } else {
        // No neural model available, use formula-based score only
        finalCallingScore = formulaCallingScore;
      }

      // Phase 12 Section 3.1: Outcome Prediction Integration
      // Filter recommendations and adjust calling score based on outcome probability
      if (_outcomePredictionService != null) {
        try {
          // Check if we should call based on outcome probability
          final shouldCall = await _outcomePredictionService.shouldCall(
            userVibe: userVibe,
            spotVibe: opportunityVibe,
            context: context,
            timingFactors: timing,
            userId: userId,
          );

          if (!shouldCall) {
            // Outcome probability too low, don't call
            developer.log(
              'Outcome probability below threshold, not calling user',
              name: _logName,
            );
            finalCallingScore = 0.0; // Set to 0 to prevent calling
          } else {
            // Adjust calling score based on outcome probability
            finalCallingScore =
                await _outcomePredictionService.adjustCallingScore(
              callingScore: finalCallingScore,
              userVibe: userVibe,
              spotVibe: opportunityVibe,
              context: context,
              timingFactors: timing,
              userId: userId,
            );
          }
        } catch (e, stackTrace) {
          developer.log(
            'Outcome prediction failed, using original calling score: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // On error, continue with original score (don't block recommendations)
        }
      }

      // Apply trend boost if available
      final trendBoost = trends != null ? _calculateTrendBoost(trends) : 0.0;

      finalCallingScore =
          (finalCallingScore * (1.0 + trendBoost)).clamp(0.0, 1.0);

      final isCalled = finalCallingScore >= 0.70;

      developer.log(
        'Calling score: ${(finalCallingScore * 100).toStringAsFixed(1)}% '
        '(called: $isCalled)',
        name: _logName,
      );

      final result = CallingScoreResult(
        callingScore: finalCallingScore,
        isCalled: isCalled,
        breakdown: CallingScoreBreakdown(
          vibeCompatibility: vibeCompatibility,
          lifeBetterment: lifeBetterment,
          meaningfulConnectionProb: meaningfulConnectionProb,
          contextFactor: contextFactor,
          timingFactor: timingFactor,
          trendBoost: trendBoost,
        ),
      );

      // Phase 12: Log calculation data for neural network training (non-blocking)
      if (_dataCollector != null && userId != null) {
        // Use unawaited to avoid blocking the calling score calculation
        unawaited(
          _dataCollector
              .logCallingScoreCalculation(
            userId: userId,
            opportunityId: opportunityVibe.spotId,
            userVibe: userVibe,
            spotVibe: opportunityVibe,
            context: context,
            timing: timing,
            result: result,
          )
              .catchError((e, stackTrace) {
            developer.log(
              'Error logging calling score calculation (non-fatal): $e',
              name: _logName,
              error: e,
              stackTrace: stackTrace,
            );
            return null; // Return null to satisfy catchError signature
          }),
        );
      }

      // Phase 12 Section 2.3: Log A/B test outcome (non-blocking)
      if (_abTestingService != null && userId != null && userGroup != null) {
        unawaited(
          _abTestingService
              .logABTestOutcome(
            userId: userId,
            opportunityId: opportunityVibe.spotId,
            group: userGroup,
            callingScore: finalCallingScore,
            isCalled: isCalled,
            // Outcome will be linked later when user action is recorded
          )
              .catchError((e, stackTrace) {
            developer.log(
              'Error logging A/B test outcome (non-fatal): $e',
              name: _logName,
              error: e,
              stackTrace: stackTrace,
            );
          }),
        );
      }

      return result;
    } catch (e) {
      developer.log('Error calculating calling score: $e', name: _logName);
      return CallingScoreResult(
        callingScore: 0.0,
        isCalled: false,
        breakdown: CallingScoreBreakdown.empty(),
      );
    }
  }

  /// Calculate Life Betterment Factor
  ///
  /// Measures potential for life improvement based on:
  /// - Individual trajectory potential
  /// - Meaningful connection probability
  /// - Positive influence score
  /// - Fulfillment potential
  Future<double> _calculateLifeBettermentFactor({
    required UserVibe userVibe,
    required SpotVibe opportunityVibe,
    PersonalityProfile? userPersonality,
    List<RecentAction>? userHistory,
  }) async {
    // Individual trajectory potential (40% weight)
    final trajectoryPotential = userPersonality != null
        ? await _calculateIndividualTrajectoryPotential(
            userPersonality,
            opportunityVibe,
            userHistory ?? [],
          )
        : 0.5; // Neutral if no personality data

    // Meaningful connection probability (30% weight)
    final meaningfulConnectionProb =
        await _calculateMeaningfulConnectionProbability(
      userVibe: userVibe,
      opportunityVibe: opportunityVibe,
      context: CallingContext.empty(),
    );

    // Positive influence score (20% weight)
    final positiveInfluence = await _calculatePositiveInfluenceScore(
      userVibe,
      opportunityVibe,
    );

    // Fulfillment potential (10% weight)
    final fulfillmentPotential = _calculateFulfillmentPotential(
      userVibe,
      opportunityVibe,
    );

    // Weighted combination
    return (trajectoryPotential * 0.40 +
            meaningfulConnectionProb * 0.30 +
            positiveInfluence * 0.20 +
            fulfillmentPotential * 0.10)
        .clamp(0.0, 1.0);
  }

  /// Calculate individual trajectory potential
  ///
  /// What leads to positive growth for THIS unique individual
  Future<double> _calculateIndividualTrajectoryPotential(
    PersonalityProfile userPersonality,
    SpotVibe opportunityVibe,
    List<RecentAction> userHistory,
  ) async {
    // Use behavior assessment service to determine trajectory potential
    // This considers the user's unique personality, preferences, and history
    final behaviorContext = {
      'spot_vibe': opportunityVibe.vibeDescription,
      'user_personality': userPersonality.dimensions,
    };

    // Assess how this opportunity aligns with user's trajectory
    // Higher score = better alignment with individual growth path
    final assessment = _behaviorAssessment.assessBehavior(
      'spot_visit',
      behaviorContext,
      null, // Not age-specific, just trajectory
    );

    // Combine developmental, educational, social, and cultural value
    final trajectoryScore = (assessment.developmentalAppropriateness * 0.30 +
            assessment.educationalValue * 0.25 +
            assessment.socialValue * 0.25 +
            assessment.culturalValue * 0.20)
        .clamp(0.0, 1.0);

    return trajectoryScore;
  }

  /// Calculate meaningful connection probability
  ///
  /// Probability that this opportunity will lead to meaningful connections
  Future<double> _calculateMeaningfulConnectionProbability({
    required UserVibe userVibe,
    required SpotVibe opportunityVibe,
    required CallingContext context,
  }) async {
    // Base compatibility
    final baseCompatibility =
        opportunityVibe.calculateVibeCompatibility(userVibe);

    // Network effects (if available)
    final networkEffects = context.networkEffects ?? 0.5;

    // Community patterns (if available)
    final communityPatterns = context.communityPatterns ?? 0.5;

    // Connection potential from spot vibe description
    // Higher energy and social preference = higher connection potential
    final connectionPotential = (opportunityVibe.overallEnergy * 0.5 +
        opportunityVibe.socialPreference * 0.5);

    // Weighted combination
    return (baseCompatibility * 0.40 +
            networkEffects * 0.25 +
            communityPatterns * 0.20 +
            connectionPotential * 0.15)
        .clamp(0.0, 1.0);
  }

  /// Calculate positive influence score
  ///
  /// Measures potential for positive influence on user
  Future<double> _calculatePositiveInfluenceScore(
    UserVibe userVibe,
    SpotVibe opportunityVibe,
  ) async {
    // Assess behavior category and positive influence potential
    final behaviorContext = {
      'spot_vibe': opportunityVibe.vibeDescription,
      'user_vibe': userVibe.getVibeArchetype(),
    };

    final assessment = _behaviorAssessment.assessBehavior(
      'spot_visit',
      behaviorContext,
      null,
    );

    // Positive influence = high developmental, educational, social value
    // Low risk, high cultural value
    return (assessment.developmentalAppropriateness * 0.30 +
            assessment.educationalValue * 0.25 +
            assessment.socialValue * 0.25 +
            (1.0 - assessment.riskLevel) * 0.10 +
            assessment.culturalValue * 0.10)
        .clamp(0.0, 1.0);
  }

  /// Calculate fulfillment potential
  ///
  /// Measures potential for meaning, fulfillment, and happiness
  double _calculateFulfillmentPotential(
    UserVibe userVibe,
    SpotVibe opportunityVibe,
  ) {
    // Alignment with user's energy and exploration
    final energyAlignment =
        1.0 - (opportunityVibe.overallEnergy - userVibe.overallEnergy).abs();
    final explorationAlignment = 1.0 -
        (opportunityVibe.explorationTendency - userVibe.explorationTendency)
            .abs();
    final socialAlignment = 1.0 -
        (opportunityVibe.socialPreference - userVibe.socialPreference).abs();

    // Weighted average
    return (energyAlignment * 0.40 +
            explorationAlignment * 0.35 +
            socialAlignment * 0.25)
        .clamp(0.0, 1.0);
  }

  /// Calculate context factor
  ///
  /// How well the opportunity fits current context
  double _calculateContextFactor(CallingContext context) {
    double factor = 1.0;

    // Location proximity (closer = better, up to a point)
    if (context.locationProximity != null) {
      final proximity = context.locationProximity!;
      if (proximity < 0.5) {
        factor *= 0.9; // Slightly reduce if far
      } else if (proximity > 0.8) {
        factor *= 1.1; // Boost if very close
      }
    }

    // Journey alignment
    if (context.journeyAlignment != null) {
      factor *= (0.8 + context.journeyAlignment! * 0.2); // 0.8 to 1.0
    }

    // User receptivity
    if (context.userReceptivity != null) {
      factor *= (0.7 + context.userReceptivity! * 0.3); // 0.7 to 1.0
    }

    // Opportunity availability
    if (context.opportunityAvailability != null) {
      factor *= context.opportunityAvailability!;
    }

    return factor.clamp(0.0, 1.0);
  }

  /// Calculate timing factor
  ///
  /// How well the opportunity fits current timing
  double _calculateTimingFactor(TimingFactors timing) {
    double factor = 1.0;

    // Optimal time of day
    if (timing.optimalTimeOfDay != null) {
      final timeAlignment = timing.optimalTimeOfDay!;
      factor *= (0.8 + timeAlignment * 0.2); // 0.8 to 1.0
    }

    // Optimal day of week
    if (timing.optimalDayOfWeek != null) {
      final dayAlignment = timing.optimalDayOfWeek!;
      factor *= (0.8 + dayAlignment * 0.2); // 0.8 to 1.0
    }

    // User patterns
    if (timing.userPatterns != null) {
      factor *= (0.7 + timing.userPatterns! * 0.3); // 0.7 to 1.0
    }

    // Opportunity timing
    if (timing.opportunityTiming != null) {
      factor *= timing.opportunityTiming!;
    }

    return factor.clamp(0.0, 1.0);
  }

  /// Calculate trend boost
  ///
  /// Boost or reduce calling score based on real-time trends
  double _calculateTrendBoost(TrendData trends) {
    // Emerging spot score
    final emergingSpotScore = trends.emergingSpotScore ?? 0.0;

    // Community trend score
    final communityTrendScore = trends.communityTrendScore ?? 0.0;

    // Cultural shift score
    final culturalShiftScore = trends.culturalShiftScore ?? 0.0;

    // Life pattern change score
    final lifePatternChangeScore = trends.lifePatternChangeScore ?? 0.0;

    // Weighted combination
    final trendBoost = (emergingSpotScore * 0.30 +
        communityTrendScore * 0.30 +
        culturalShiftScore * 0.20 +
        lifePatternChangeScore * 0.20);

    // Clamp to [-0.1, +0.2] range
    return trendBoost.clamp(-0.1, 0.2);
  }

  /// Prepare features for neural network prediction
  ///
  /// Converts calling score inputs into a 39D feature vector for the neural network
  List<double> _prepareNeuralNetworkFeatures({
    required UserVibe userVibe,
    required SpotVibe opportunityVibe,
    required CallingContext context,
    required TimingFactors timing,
  }) {
    double matchDim(double? a, double? b) {
      if (a == null || b == null) return 0.5;
      return (1.0 - (a - b).abs()).clamp(0.0, 1.0);
    }

    double avgOrNeutral(List<double?> values) {
      final present = values.whereType<double>().toList();
      if (present.isEmpty) return 0.5;
      final sum = present.fold<double>(0.0, (s, v) => s + v);
      return (sum / present.length).clamp(0.0, 1.0);
    }

    final features = <double>[];

    // User vibe dimensions (12D)
    final userDimensions = userVibe.anonymizedDimensions;
    for (final dimension in [
      'exploration_eagerness',
      'community_orientation',
      'location_adventurousness',
      'authenticity_preference',
      'trust_network_reliance',
      'temporal_flexibility',
      'energy_preference',
      'novelty_seeking',
      'value_orientation',
      'crowd_tolerance',
      'social_preference',
      'overall_energy',
    ]) {
      features.add(userDimensions[dimension] ?? 0.5);
    }

    // Spot vibe dimensions (12D)
    final spotDimensions = opportunityVibe.vibeDimensions;
    for (final dimension in [
      'exploration_eagerness',
      'community_orientation',
      'location_adventurousness',
      'authenticity_preference',
      'trust_network_reliance',
      'temporal_flexibility',
      'energy_preference',
      'novelty_seeking',
      'value_orientation',
      'crowd_tolerance',
      'social_preference',
      'overall_energy',
    ]) {
      features.add(spotDimensions[dimension] ?? 0.5);
    }

    // Context features (10 features)
    features.add(context.locationProximity?.clamp(0.0, 1.0) ?? 0.5);
    features.add(context.journeyAlignment?.clamp(0.0, 1.0) ?? 0.5);
    features.add(context.userReceptivity?.clamp(0.0, 1.0) ?? 0.5);
    features.add(context.opportunityAvailability?.clamp(0.0, 1.0) ?? 0.5);
    features.add(context.networkEffects?.clamp(0.0, 1.0) ?? 0.5);
    features.add(context.communityPatterns?.clamp(0.0, 1.0) ?? 0.5);

    // Additional context features (formerly placeholders):
    // These are computed from the same observable inputs and are also logged
    // via CallingScoreDataCollector so the model can be retrained with them.
    final vibeCompatibility = opportunityVibe.calculateVibeCompatibility(userVibe);
    final energyMatch = matchDim(
      userDimensions['overall_energy'],
      opportunityVibe.vibeDimensions['overall_energy'],
    );
    final communityMatch = matchDim(
      userDimensions['community_orientation'],
      opportunityVibe.vibeDimensions['community_orientation'],
    );
    final noveltyMatch = matchDim(
      userDimensions['novelty_seeking'],
      opportunityVibe.vibeDimensions['novelty_seeking'],
    );

    features.add(vibeCompatibility.clamp(0.0, 1.0));
    features.add(energyMatch);
    features.add(communityMatch);
    features.add(noveltyMatch);

    // Timing features (5 features)
    features.add(timing.optimalTimeOfDay?.clamp(0.0, 1.0) ?? 0.5);
    features.add(timing.optimalDayOfWeek?.clamp(0.0, 1.0) ?? 0.5);
    features.add(timing.userPatterns?.clamp(0.0, 1.0) ?? 0.5);
    features.add(timing.opportunityTiming?.clamp(0.0, 1.0) ?? 0.5);

    // Timing alignment (formerly placeholder): average of the known timing signals.
    features.add(avgOrNeutral([
      timing.optimalTimeOfDay,
      timing.optimalDayOfWeek,
      timing.userPatterns,
      timing.opportunityTiming,
    ]));

    // Ensure we have exactly 39 features
    while (features.length < 39) {
      features.add(0.5);
    }
    features.removeRange(39, features.length);

    return features;
  }
}

/// Calling Context
///
/// Current context for calling score calculation
class CallingContext {
  final double? locationProximity; // 0.0 (far) to 1.0 (close)
  final double? journeyAlignment; // 0.0 (not aligned) to 1.0 (aligned)
  final double? userReceptivity; // 0.0 (not receptive) to 1.0 (receptive)
  final double? opportunityAvailability; // 0.0 (unavailable) to 1.0 (available)
  final double? networkEffects; // 0.0 to 1.0
  final double? communityPatterns; // 0.0 to 1.0

  CallingContext({
    this.locationProximity,
    this.journeyAlignment,
    this.userReceptivity,
    this.opportunityAvailability,
    this.networkEffects,
    this.communityPatterns,
  });

  factory CallingContext.empty() => CallingContext();

  factory CallingContext.fromLocation(
      Position location, Position opportunityLocation) {
    final distance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      opportunityLocation.latitude,
      opportunityLocation.longitude,
    );

    // Convert distance to proximity (0-5km = 1.0, 20km+ = 0.0)
    final proximity =
        (1.0 - (distance / 20000.0).clamp(0.0, 1.0)).clamp(0.0, 1.0);

    return CallingContext(
      locationProximity: proximity,
    );
  }
}

/// Timing Factors
///
/// Timing-related factors for calling score calculation
class TimingFactors {
  final double? optimalTimeOfDay; // 0.0 to 1.0
  final double? optimalDayOfWeek; // 0.0 to 1.0
  final double? userPatterns; // 0.0 to 1.0
  final double? opportunityTiming; // 0.0 to 1.0

  TimingFactors({
    this.optimalTimeOfDay,
    this.optimalDayOfWeek,
    this.userPatterns,
    this.opportunityTiming,
  });

  factory TimingFactors.empty() => TimingFactors();

  factory TimingFactors.fromDateTime(DateTime now) {
    final hour = now.hour;
    final dayOfWeek = now.weekday;

    // Calculate optimal time of day (simplified)
    double timeOfDay = 0.5;
    if (hour >= 9 && hour <= 11) {
      timeOfDay = 0.8; // Morning
    } else if (hour >= 17 && hour <= 20) {
      timeOfDay = 0.9; // Evening
    } else if (hour >= 12 && hour <= 14) {
      timeOfDay = 0.7; // Lunch
    }

    // Calculate optimal day of week (weekends = better)
    final dayOfWeekScore = [6, 7].contains(dayOfWeek) ? 0.8 : 0.6;

    return TimingFactors(
      optimalTimeOfDay: timeOfDay,
      optimalDayOfWeek: dayOfWeekScore,
    );
  }
}

/// Trend Data
///
/// Real-time trend data for calling score calculation
class TrendData {
  final double? emergingSpotScore; // 0.0 to 1.0
  final double? communityTrendScore; // 0.0 to 1.0
  final double? culturalShiftScore; // 0.0 to 1.0
  final double? lifePatternChangeScore; // 0.0 to 1.0

  TrendData({
    this.emergingSpotScore,
    this.communityTrendScore,
    this.culturalShiftScore,
    this.lifePatternChangeScore,
  });

  factory TrendData.empty() => TrendData();
}

/// Calling Score Result
class CallingScoreResult {
  final double callingScore; // 0.0 to 1.0
  final bool isCalled; // true if score ≥ 0.70
  final CallingScoreBreakdown breakdown;

  CallingScoreResult({
    required this.callingScore,
    required this.isCalled,
    required this.breakdown,
  });
}

/// Calling Score Breakdown
///
/// Detailed breakdown of calling score components
class CallingScoreBreakdown {
  final double vibeCompatibility;
  final double lifeBetterment;
  final double meaningfulConnectionProb;
  final double contextFactor;
  final double timingFactor;
  final double trendBoost;

  CallingScoreBreakdown({
    required this.vibeCompatibility,
    required this.lifeBetterment,
    required this.meaningfulConnectionProb,
    required this.contextFactor,
    required this.timingFactor,
    required this.trendBoost,
  });

  factory CallingScoreBreakdown.empty() => CallingScoreBreakdown(
        vibeCompatibility: 0.0,
        lifeBetterment: 0.0,
        meaningfulConnectionProb: 0.0,
        contextFactor: 0.0,
        timingFactor: 0.0,
        trendBoost: 0.0,
      );
}

/// Recent Action
///
/// Represents a recent user action for trajectory calculation
class RecentAction {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RecentAction({
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });
}
