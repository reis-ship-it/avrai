// Calling Score Data Collector for Phase 12: Neural Network Implementation
// Section 1: Foundation & Data Collection
// Collects calling score calculations and outcomes for neural network training

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/models/spots/spot_vibe.dart';
import 'package:avrai/core/services/calling_score/calling_score_calculator.dart';
import 'package:avrai/core/models/quantum/outcome_result.dart';
import 'package:get_it/get_it.dart';

/// Calling Score Data Collector
/// 
/// Collects calling score calculations and outcomes for neural network training.
/// 
/// Phase 12 Section 1: Foundation & Data Collection
/// - Logs all calling score calculations (inputs + outputs)
/// - Tracks outcomes and links them to calling scores
/// - Provides training data pipeline for neural network models
class CallingScoreDataCollector {
  static const String _logName = 'CallingScoreDataCollector';
  
  final SupabaseClient _supabase;
  final AgentIdService _agentIdService;
  final bool _enabled;
  
  CallingScoreDataCollector({
    required SupabaseClient supabase,
    AgentIdService? agentIdService,
    bool enabled = true, // Enable data collection by default
  }) : _supabase = supabase,
       _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
       _enabled = enabled;
  
  /// Log a calling score calculation
  /// 
  /// **Parameters:**
  /// - `userId`: Authenticated user ID
  /// - `opportunityId`: Spot, event, list, etc. ID
  /// - `userVibe`: User vibe (12D dimensions)
  /// - `spotVibe`: Spot vibe (12D dimensions)
  /// - `context`: Calling context (location, time, etc.)
  /// - `timing`: Timing factors
  /// - `result`: Calling score result (score, breakdown, isCalled)
  /// 
  /// Returns the training data record ID
  Future<String?> logCallingScoreCalculation({
    required String userId,
    required String opportunityId,
    required UserVibe userVibe,
    required SpotVibe spotVibe,
    required CallingContext context,
    required TimingFactors timing,
    required CallingScoreResult result,
  }) async {
    if (!_enabled) {
      developer.log('Calling score data collection is disabled', name: _logName);
      return null;
    }
    
    try {
      developer.log(
        'Logging calling score calculation for user: $userId, opportunity: $opportunityId',
        name: _logName,
      );
      
      // Convert userId → agentId for privacy
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      // Extract user vibe dimensions (12D)
      final userVibeDimensions = <String, double>{};
      for (final dimension in userVibe.anonymizedDimensions.keys) {
        userVibeDimensions[dimension] = userVibe.anonymizedDimensions[dimension] ?? 0.0;
      }
      
      // Extract spot vibe dimensions (12D)
      final spotVibeDimensions = <String, double>{};
      for (final dimension in spotVibe.vibeDimensions.keys) {
        spotVibeDimensions[dimension] = spotVibe.vibeDimensions[dimension] ?? 0.0;
      }
      
      // Extract context features
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

      final contextFeatures = <String, dynamic>{
        'location_proximity': context.locationProximity,
        'journey_alignment': context.journeyAlignment,
        'user_receptivity': context.userReceptivity,
        'opportunity_availability': context.opportunityAvailability,
        'network_effects': context.networkEffects,
        'community_patterns': context.communityPatterns,
        // Former placeholders (now logged so the model can be retrained truthfully)
        'vibe_compatibility': result.breakdown.vibeCompatibility,
        'energy_match': matchDim(
          userVibe.anonymizedDimensions['overall_energy'],
          spotVibe.vibeDimensions['overall_energy'],
        ),
        'community_match': matchDim(
          userVibe.anonymizedDimensions['community_orientation'],
          spotVibe.vibeDimensions['community_orientation'],
        ),
        'novelty_match': matchDim(
          userVibe.anonymizedDimensions['novelty_seeking'],
          spotVibe.vibeDimensions['novelty_seeking'],
        ),
      };
      
      // Extract timing features
      final timingFeatures = <String, dynamic>{
        'optimal_time_of_day': timing.optimalTimeOfDay,
        'optimal_day_of_week': timing.optimalDayOfWeek,
        'user_patterns': timing.userPatterns,
        'opportunity_timing': timing.opportunityTiming,
        // Former placeholder (now logged)
        'timing_alignment': avgOrNeutral([
          timing.optimalTimeOfDay,
          timing.optimalDayOfWeek,
          timing.userPatterns,
          timing.opportunityTiming,
        ]),
      };
      
      // Extract formula breakdown
      final formulaBreakdown = <String, double>{
        'vibe_compatibility': result.breakdown.vibeCompatibility,
        'life_betterment': result.breakdown.lifeBetterment,
        'meaningful_connection_prob': result.breakdown.meaningfulConnectionProb,
        'context_factor': result.breakdown.contextFactor,
        'timing_factor': result.breakdown.timingFactor,
        'trend_boost': result.breakdown.trendBoost,
      };
      
      // Insert training data record
      final response = await _supabase
          .from('calling_score_training_data')
          .insert({
            'agent_id': agentId,
            'opportunity_id': opportunityId,
            'user_vibe_dimensions': userVibeDimensions,
            'spot_vibe_dimensions': spotVibeDimensions,
            'context_features': contextFeatures,
            'timing_features': timingFeatures,
            'formula_calling_score': result.callingScore,
            'formula_is_called': result.isCalled,
            'formula_breakdown': formulaBreakdown,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      
      final recordId = response['id'] as String;
      
      developer.log(
        '✅ Logged calling score calculation: $recordId (score: ${(result.callingScore * 100).toStringAsFixed(1)}%, called: ${result.isCalled})',
        name: _logName,
      );
      
      return recordId;
    } catch (e, stackTrace) {
      developer.log(
        'Error logging calling score calculation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - data collection failure shouldn't break the app
      return null;
    }
  }
  
  /// Link an outcome to a calling score calculation
  /// 
  /// **Parameters:**
  /// - `userId`: Authenticated user ID
  /// - `opportunityId`: Spot, event, list, etc. ID
  /// - `outcome`: Outcome result (positive, negative, neutral)
  /// 
  /// Updates the most recent calling score calculation for this user/opportunity
  Future<void> linkOutcomeToCallingScore({
    required String userId,
    required String opportunityId,
    required OutcomeResult outcome,
  }) async {
    if (!_enabled) {
      return;
    }
    
    try {
      developer.log(
        'Linking outcome to calling score for user: $userId, opportunity: $opportunityId',
        name: _logName,
      );
      
      // Convert userId → agentId for privacy
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      // Find the most recent calling score calculation for this user/opportunity
      final response = await _supabase
          .from('calling_score_training_data')
          .select('id')
          .eq('agent_id', agentId)
          .eq('opportunity_id', opportunityId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) {
        developer.log(
          'No calling score calculation found for user: $userId, opportunity: $opportunityId',
          name: _logName,
        );
        return;
      }
      
      final recordId = response['id'] as String;
      
      // Update the record with outcome data
      await _supabase
          .from('calling_score_training_data')
          .update({
            'outcome_type': outcome.outcomeType.toString().split('.').last, // 'positive', 'negative', 'neutral'
            'outcome_score': outcome.outcomeScore,
            'outcome_timestamp': outcome.timestamp.toIso8601String(),
          })
          .eq('id', recordId);
      
      developer.log(
        '✅ Linked outcome to calling score: $recordId (outcome: ${outcome.outcomeType}, score: ${outcome.outcomeScore})',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error linking outcome to calling score: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - data collection failure shouldn't break the app
    }
  }
  
  /// Get training data for neural network model
  /// 
  /// **Parameters:**
  /// - `limit`: Maximum number of records to return (default: 1000)
  /// - `minOutcomeScore`: Minimum outcome score threshold (optional)
  /// - `includeOutcomesOnly`: Only return records with outcomes (default: false)
  /// 
  /// Returns list of training data records
  Future<List<Map<String, dynamic>>> getTrainingData({
    int limit = 1000,
    double? minOutcomeScore,
    bool includeOutcomesOnly = false,
  }) async {
    try {
      developer.log('Fetching training data (limit: $limit)', name: _logName);
      
      // Build query
      var response = await _supabase
          .from('calling_score_training_data')
          .select('*')
          .order('timestamp', ascending: false)
          .limit(limit);
      
      final records = List<Map<String, dynamic>>.from(response);
      
      // Apply filters after fetching (simpler approach)
      var filteredRecords = records;
      
      if (includeOutcomesOnly) {
        filteredRecords = filteredRecords
            .where((r) => r['outcome_type'] != null)
            .toList();
      }
      
      if (minOutcomeScore != null) {
        filteredRecords = filteredRecords
            .where((r) => r['outcome_score'] != null && 
                         (r['outcome_score'] as num).toDouble() >= minOutcomeScore)
            .toList();
      }
      
      developer.log(
        '✅ Fetched ${filteredRecords.length} training data records',
        name: _logName,
      );
      
      return filteredRecords;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching training data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Get training data statistics
  /// 
  /// Returns statistics about collected training data:
  /// - Total records
  /// - Records with outcomes
  /// - Average calling score
  /// - Outcome distribution
  Future<Map<String, dynamic>> getTrainingDataStats() async {
    try {
      developer.log('Fetching training data statistics', name: _logName);
      
      // Get all records for statistics
      final allRecords = await _supabase
          .from('calling_score_training_data')
          .select('id, formula_calling_score, outcome_type, outcome_score');
      
      final records = List<Map<String, dynamic>>.from(allRecords);
      
      final totalCount = records.length;
      
      // Count records with outcomes
      final recordsWithOutcomes = records
          .where((r) => r['outcome_type'] != null)
          .toList();
      final outcomesCount = recordsWithOutcomes.length;
      
      // Calculate average calling score
      double avgScore = 0.0;
      if (records.isNotEmpty) {
        final scores = records
            .map((r) => (r['formula_calling_score'] as num).toDouble())
            .toList();
        avgScore = scores.reduce((a, b) => a + b) / scores.length;
      }
      
      // Get outcome distribution
      final outcomeDistribution = <String, int>{
        'positive': 0,
        'negative': 0,
        'neutral': 0,
      };
      
      for (final record in recordsWithOutcomes) {
        final outcomeType = record['outcome_type'] as String?;
        if (outcomeType != null && outcomeDistribution.containsKey(outcomeType)) {
          outcomeDistribution[outcomeType] = (outcomeDistribution[outcomeType] ?? 0) + 1;
        }
      }
      
      final stats = {
        'total_records': totalCount,
        'records_with_outcomes': outcomesCount,
        'average_calling_score': avgScore,
        'outcome_distribution': outcomeDistribution,
        'coverage_rate': totalCount > 0 ? outcomesCount / totalCount : 0.0,
      };
      
      developer.log(
        '✅ Training data stats: $totalCount total, $outcomesCount with outcomes, avg score: ${avgScore.toStringAsFixed(3)}',
        name: _logName,
      );
      
      return stats;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching training data statistics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'total_records': 0,
        'records_with_outcomes': 0,
        'average_calling_score': 0.0,
        'outcome_distribution': <String, int>{},
        'coverage_rate': 0.0,
      };
    }
  }
  
  /// Get training data stats (public method for baseline metrics)
  /// 
  /// Returns statistics about collected training data
  Future<Map<String, dynamic>> getStats() async {
    return getTrainingDataStats();
  }
}
