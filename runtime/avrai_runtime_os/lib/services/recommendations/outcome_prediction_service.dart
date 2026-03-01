// Outcome Prediction Service for Phase 12: Neural Network Implementation
// Section 3.1: Outcome Prediction Model
// Service to predict outcome probability and filter recommendations

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/ml/outcome_prediction_model.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_calculator.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_data_collector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome Prediction Service
///
/// Predicts the probability of a positive outcome before calling a user.
/// Filters recommendations to only call users when outcome probability is high.
///
/// Phase 12 Section 3.1: Outcome Prediction Model
class OutcomePredictionService {
  static const String _logName = 'OutcomePredictionService';

  final OutcomePredictionModel _model;
  final SupabaseClient? _supabase;
  final CallingScoreDataCollector? _dataCollector;

  OutcomePredictionService({
    required OutcomePredictionModel model,
    SupabaseClient? supabase,
    CallingScoreDataCollector? dataCollector,
  })  : _model = model,
        _supabase = supabase,
        _dataCollector = dataCollector;

  /// Predict outcome probability for a recommendation
  ///
  /// **Parameters:**
  /// - `userVibe`: User's vibe dimensions
  /// - `spotVibe`: Spot's vibe dimensions
  /// - `context`: Calling context
  /// - `timingFactors`: Timing factors
  /// - `userId`: User ID for history lookup (optional)
  ///
  /// **Returns:**
  /// Probability of positive outcome (0.0-1.0)
  Future<double> predictOutcome({
    required UserVibe userVibe,
    required SpotVibe spotVibe,
    required CallingContext context,
    required TimingFactors timingFactors,
    String? userId,
  }) async {
    try {
      // Prepare base features (39D) - same as calling score model
      final baseFeatures = _prepareBaseFeatures(
        userVibe: userVibe,
        spotVibe: spotVibe,
        context: context,
        timingFactors: timingFactors,
      );

      // Prepare history features (~6D)
      final historyFeatures = await _prepareHistoryFeatures(userId: userId);

      // Predict outcome probability
      final probability = await _model.predict(
        baseFeatures: baseFeatures,
        historyFeatures: historyFeatures,
      );

      developer.log(
        'Outcome probability: ${(probability * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      return probability;
    } catch (e, stackTrace) {
      developer.log(
        'Error predicting outcome: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return neutral probability on error
      return 0.5;
    }
  }

  /// Check if user should be called based on outcome probability
  ///
  /// Only calls if outcome probability > threshold (default: 0.7)
  Future<bool> shouldCall({
    required UserVibe userVibe,
    required SpotVibe spotVibe,
    required CallingContext context,
    required TimingFactors timingFactors,
    String? userId,
  }) async {
    try {
      final probability = await predictOutcome(
        userVibe: userVibe,
        spotVibe: spotVibe,
        context: context,
        timingFactors: timingFactors,
        userId: userId,
      );

      final shouldCall = probability > _model.threshold;

      developer.log(
        'Should call: $shouldCall (probability: ${(probability * 100).toStringAsFixed(1)}%, threshold: ${(_model.threshold * 100).toStringAsFixed(1)}%)',
        name: _logName,
      );

      return shouldCall;
    } catch (e) {
      developer.log(
        'Error checking if should call: $e',
        name: _logName,
        error: e,
      );
      // On error, allow calling (don't block recommendations)
      return true;
    }
  }

  /// Adjust calling score based on outcome probability
  ///
  /// Formula: `Adjusted Score = Calling Score × Outcome Probability`
  Future<double> adjustCallingScore({
    required double callingScore,
    required UserVibe userVibe,
    required SpotVibe spotVibe,
    required CallingContext context,
    required TimingFactors timingFactors,
    String? userId,
  }) async {
    try {
      final outcomeProbability = await predictOutcome(
        userVibe: userVibe,
        spotVibe: spotVibe,
        context: context,
        timingFactors: timingFactors,
        userId: userId,
      );

      // Adjust calling score: multiply by outcome probability
      final adjustedScore = (callingScore * outcomeProbability).clamp(0.0, 1.0);

      developer.log(
        'Adjusted calling score: $callingScore × $outcomeProbability = $adjustedScore',
        name: _logName,
      );

      return adjustedScore;
    } catch (e) {
      developer.log(
        'Error adjusting calling score: $e',
        name: _logName,
        error: e,
      );
      // On error, return original score
      return callingScore;
    }
  }

  /// Prepare base features (39D) - same as calling score model
  List<double> _prepareBaseFeatures({
    required UserVibe userVibe,
    required SpotVibe spotVibe,
    required CallingContext context,
    required TimingFactors timingFactors,
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
    final userDims = userVibe.anonymizedDimensions;
    const dimensionNames = [
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
    ];
    for (final dim in dimensionNames) {
      features.add(userDims[dim] ?? 0.5);
    }

    // Spot vibe dimensions (12D)
    final spotDims = spotVibe.vibeDimensions;
    for (final dim in dimensionNames) {
      features.add(spotDims[dim] ?? 0.5);
    }

    // Context features (10 features)
    features.add(context.locationProximity ?? 0.5);
    features.add(context.journeyAlignment ?? 0.5);
    features.add(context.userReceptivity ?? 0.5);
    features.add(context.opportunityAvailability ?? 0.5);
    features.add(context.networkEffects ?? 0.5);
    features.add(context.communityPatterns ?? 0.5);
    // Additional context features (formerly placeholders)
    final vibeCompatibility = spotVibe.calculateVibeCompatibility(userVibe);
    final energyMatch = matchDim(
      userDims['overall_energy'],
      spotVibe.vibeDimensions['overall_energy'],
    );
    final communityMatch = matchDim(
      userDims['community_orientation'],
      spotVibe.vibeDimensions['community_orientation'],
    );
    final noveltyMatch = matchDim(
      userDims['novelty_seeking'],
      spotVibe.vibeDimensions['novelty_seeking'],
    );
    features.add(vibeCompatibility.clamp(0.0, 1.0));
    features.add(energyMatch);
    features.add(communityMatch);
    features.add(noveltyMatch);

    // Timing features (5 features)
    features.add(timingFactors.optimalTimeOfDay ?? 0.5);
    features.add(timingFactors.optimalDayOfWeek ?? 0.5);
    features.add(timingFactors.userPatterns ?? 0.5);
    features.add(timingFactors.opportunityTiming ?? 0.5);
    features.add(avgOrNeutral([
      timingFactors.optimalTimeOfDay,
      timingFactors.optimalDayOfWeek,
      timingFactors.userPatterns,
      timingFactors.opportunityTiming,
    ]));

    return features;
  }

  /// Prepare history features (~6D) from user's past outcomes
  Future<List<double>> _prepareHistoryFeatures({String? userId}) async {
    if (userId == null || _supabase == null || _dataCollector == null) {
      // Return default values if no user ID or data collector
      return [0.5, 0.5, 0.5, 0.0, 0.5, 0.5];
    }

    try {
      // Get user's historical outcome data
      // Note: getTrainingDataStats() doesn't filter by user, so we use overall stats
      // In a production system, you'd want to filter by agent_id
      final stats = await _dataCollector.getTrainingDataStats();

      final totalRecords = stats['total_records'] as int? ?? 0;
      final positiveOutcomes = stats['positive_outcomes'] as int? ?? 0;
      final negativeOutcomes = stats['negative_outcomes'] as int? ?? 0;
      final neutralOutcomes = stats['neutral_outcomes'] as int? ?? 0;

      // Calculate rates
      final totalOutcomes =
          positiveOutcomes + negativeOutcomes + neutralOutcomes;
      final pastPositiveRate =
          totalOutcomes > 0 ? positiveOutcomes / totalOutcomes : 0.5;
      final pastNegativeRate =
          totalOutcomes > 0 ? negativeOutcomes / totalOutcomes : 0.5;

      // Average engagement score (placeholder - would need actual engagement data)
      const averageEngagement = 0.5;

      // Number of previous interactions (normalized)
      final interactionCount = totalRecords.toDouble();
      final normalizedInteractionCount =
          (interactionCount / 100.0).clamp(0.0, 1.0);

      // Time since last positive outcome (normalized, placeholder)
      const timeSinceLastPositive = 0.5;

      // User activity level (placeholder - would need actual activity data)
      const activityLevel = 0.5;

      return [
        pastPositiveRate,
        pastNegativeRate,
        averageEngagement,
        normalizedInteractionCount,
        timeSinceLastPositive,
        activityLevel,
      ];
    } catch (e) {
      developer.log(
        'Error preparing history features: $e',
        name: _logName,
        error: e,
      );
      // Return default values on error
      return [0.5, 0.5, 0.5, 0.0, 0.5, 0.5];
    }
  }
}
