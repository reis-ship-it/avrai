// ignore: dangling_library_doc_comments
/// List Suggestion Outreach Service
///
/// Service for proactively suggesting lists to users.
/// Part of Predictive Proactive Outreach System - Phase 2.7
///
/// Handles two types of list outreach:
/// 1. General list suggestions (based on preferences, location, personality)
/// 2. Expert-curated list suggestions (from experts users follow or are compatible with)

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expert_recommendations_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/user/unified_user.dart';

/// Service for proactively suggesting lists to users
class ListSuggestionOutreachService {
  static const String _logName = 'ListSuggestionOutreachService';

  // TODO: Use onboarding recommendation service for list suggestions
  // ignore: unused_field
  final OnboardingRecommendationService _onboardingRecommendationService;
  final ExpertRecommendationsService _expertRecommendationsService;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final EvolutionPatternAnalysisService _evolutionPatternService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;

  ListSuggestionOutreachService({
    required OnboardingRecommendationService onboardingRecommendationService,
    required ExpertRecommendationsService expertRecommendationsService,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required EvolutionPatternAnalysisService evolutionPatternService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _onboardingRecommendationService = onboardingRecommendationService,
        _expertRecommendationsService = expertRecommendationsService,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _evolutionPatternService = evolutionPatternService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;

  /// Process general list suggestions for a user
  ///
  /// Finds lists that match user preferences, location, and personality.
  Future<void> processGeneralListSuggestions({
    required String userId,
  }) async {
    try {
      developer.log(
        'Processing general list suggestions for user: $userId',
        name: _logName,
      );

      final userProfile =
          await _personalityLearning.getCurrentPersonality(userId);
      if (userProfile == null) return;

      // Get user for recommendations
      final user = await _getUserById(userId);
      if (user == null) return;

      // Get recommended lists using existing service
      // Note: Would need onboarding data - for now, use personality-based recommendations
      final recommendations = await _getListRecommendations(user);

      for (final recommendation in recommendations) {
        try {
          // Calculate predictive compatibility with list
          final stringPred =
              await _futureCompatService.predictFutureCompatibility(
            userAId: userProfile.agentId,
            userBId: recommendation.listId, // Use list ID as proxy
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );

          final quantumTraj =
              await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: userId,
            userBId: recommendation.listId,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );

          final outreachScore = _combineListOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            currentCompatibility: recommendation.compatibilityScore,
          );

          if (outreachScore >= 0.7) {
            await _ai2aiCommunication.sendOutreachMessage(
              fromAgentId: 'system', // System-initiated
              toAgentId: userProfile.agentId,
              messageType: OutreachMessageType.listSuggestion,
              payload: {
                'list_id': recommendation.listId,
                'list_name': recommendation.listName,
                'compatibility_score': outreachScore,
                'reasoning': recommendation.reasoning ??
                    'High compatibility list suggestion',
              },
            );
          }
        } catch (e) {
          developer.log('Error processing list recommendation: $e',
              name: _logName);
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process general list suggestions: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Process expert-curated list suggestions
  ///
  /// Finds expert-curated lists that match user interests and compatibility.
  Future<void> processExpertCuratedListSuggestions({
    required String userId,
  }) async {
    try {
      developer.log(
        'Processing expert-curated list suggestions for user: $userId',
        name: _logName,
      );

      final userProfile =
          await _personalityLearning.getCurrentPersonality(userId);
      if (userProfile == null) return;

      final user = await _getUserById(userId);
      if (user == null) return;

      // Get expert-curated lists
      final expertLists =
          await _expertRecommendationsService.getExpertCuratedLists(
        user,
        maxResults: 20,
      );

      for (final expertList in expertLists) {
        try {
          final curatorProfile = await _personalityLearning
              .getCurrentPersonality(expertList.curator.id);
          if (curatorProfile == null) continue;

          // Calculate predictive compatibility with curator
          final stringPred =
              await _futureCompatService.predictFutureCompatibility(
            userAId: userProfile.agentId,
            userBId: curatorProfile.agentId,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );

          final quantumTraj =
              await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: userId,
            userBId: expertList.curator.id,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );

          final timingRec =
              await _evolutionPatternService.calculateOptimalTiming(
            userId: userProfile.agentId,
            targetId: curatorProfile.agentId,
          );

          final outreachScore = _combineListOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            currentCompatibility:
                expertList.respectCount / 100.0, // Normalize respect count
          );

          if (outreachScore >= 0.7) {
            await _ai2aiCommunication.sendOutreachMessage(
              fromAgentId: curatorProfile.agentId,
              toAgentId: userProfile.agentId,
              messageType: OutreachMessageType.expertCuratedList,
              payload: {
                'list_id': expertList.list.id,
                'list_name': expertList.list.name,
                'curator_id': expertList.curator.id,
                'curator_name':
                    expertList.curator.displayName ?? expertList.curator.id,
                'compatibility_score': outreachScore,
                'respect_count': expertList.respectCount,
                'reasoning': 'Expert-curated list with high compatibility',
                'optimal_timing': timingRec.optimalTime.toIso8601String(),
              },
            );
          }
        } catch (e) {
          developer.log('Error processing expert list: $e', name: _logName);
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process expert-curated list suggestions: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  double _combineListOutreachSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double currentCompatibility,
  }) {
    return (0.30 * stringPrediction +
            0.35 * quantumTrajectory +
            0.35 * currentCompatibility)
        .clamp(0.0, 1.0);
  }

  Future<UnifiedUser?> _getUserById(String userId) async {
    // Placeholder - would query user service
    return null;
  }

  Future<List<ListRecommendation>> _getListRecommendations(
      UnifiedUser user) async {
    // Placeholder - would use onboarding recommendation service
    // Would need onboarding data which may not be available
    return [];
  }
}

/// List recommendation
class ListRecommendation {
  final String listId;
  final String listName;
  final double compatibilityScore;
  final String? reasoning;

  ListRecommendation({
    required this.listId,
    required this.listName,
    this.compatibilityScore = 0.0,
    this.reasoning,
  });
}
