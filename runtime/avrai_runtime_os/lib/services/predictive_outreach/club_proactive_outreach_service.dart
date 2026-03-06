// ignore: dangling_library_doc_comments
/// Club Proactive Outreach Service
///
/// Service for clubs to proactively reach out to users.
/// Part of Predictive Proactive Outreach System - Phase 2.5
///
/// Handles two types of club outreach:
/// 1. Club → Users (membership invitations)
/// 2. Club → Users (event invitations)

import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/fabric_stability_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';

/// Service for clubs to proactively reach out to users
class ClubProactiveOutreachService {
  static const String _logName = 'ClubProactiveOutreachService';

  final ClubService _clubService;
  // TODO: Use community service for enhanced club outreach
  // ignore: unused_field
  final CommunityService _communityService;
  final ExpertiseEventService _eventService;
  final KnotFabricService _fabricService;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final FabricStabilityPredictionService _fabricStabilityService;
  // TODO: Use evolution pattern service for optimal timing
  // ignore: unused_field
  final EvolutionPatternAnalysisService _evolutionPatternService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;

  ClubProactiveOutreachService({
    required ClubService clubService,
    required CommunityService communityService,
    required ExpertiseEventService eventService,
    required KnotFabricService fabricService,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required FabricStabilityPredictionService fabricStabilityService,
    required EvolutionPatternAnalysisService evolutionPatternService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _clubService = clubService,
        _communityService = communityService,
        _eventService = eventService,
        _fabricService = fabricService,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _fabricStabilityService = fabricStabilityService,
        _evolutionPatternService = evolutionPatternService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;

  /// Process club membership outreach (Club → Users)
  Future<void> processClubMembershipOutreach({
    required String clubId,
  }) async {
    try {
      developer.log(
        'Processing club membership outreach: club $clubId',
        name: _logName,
      );

      final club = await _clubService.getClubById(clubId);
      if (club == null) return;

      // Get club fabric
      final fabric = await _getOrCreateFabricForClub(clubId, club.memberIds);

      // Find candidates
      final candidates = await _findMembershipCandidates(club, fabric);

      for (final candidate in candidates) {
        try {
          // Calculate compatibility
          final stringPred =
              await _futureCompatService.predictFutureCompatibility(
            userAId: candidate.agentId,
            userBId: club.founderId,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );

          final quantumTraj =
              await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: candidate.userId,
            userBId: club.founderId,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );

          final stabilityPred =
              await _fabricStabilityService.predictStabilityWithUser(
            groupId: clubId,
            candidateUserId: candidate.agentId,
            currentFabric: fabric,
          );

          final outreachScore = _combineClubOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            stabilityPrediction: stabilityPred.stabilityImprovement,
          );

          if (outreachScore >= 0.75) {
            if (await _isHighChurnRisk(candidate.agentId)) {
              developer.log(
                'Skipping membership outreach for high-churn-risk candidate: ${candidate.agentId}',
                name: _logName,
              );
            } else {
              final clubProfile = await _personalityLearning
                  .getCurrentPersonality(club.founderId);
              if (clubProfile != null) {
                await _ai2aiCommunication.sendOutreachMessage(
                  fromAgentId: clubProfile.agentId,
                  toAgentId: candidate.agentId,
                  messageType: OutreachMessageType.clubMembershipInvitation,
                  payload: {
                    'club_id': clubId,
                    'compatibility_score': outreachScore,
                    'stability_improvement': stabilityPred.stabilityImprovement,
                    'reasoning': 'Would improve club fabric stability',
                  },
                );
              }
            }
          }
        } catch (e) {
          developer.log('Error processing candidate: $e', name: _logName);
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process club membership outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Returns true when the Markov predictor flags a candidate as high churn risk.
  /// Silently returns false if no predictor is registered.
  Future<bool> _isHighChurnRisk(String agentId) async {
    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<EngagementPhasePredictor>()) return false;
      final risk = await sl<EngagementPhasePredictor>()
          .predictChurnRisk(agentId, withinDays: 7);
      return risk > 0.6;
    } catch (e) {
      developer.log(
        'Churn risk check failed for $agentId, defaulting to false: $e',
        name: _logName,
      );
      return false;
    }
  }

  /// Process club event outreach (Club → Users)
  Future<void> processClubEventOutreach({
    required String clubId,
    required String eventId,
  }) async {
    try {
      developer.log(
        'Processing club event outreach: club $clubId, event $eventId',
        name: _logName,
      );

      final club = await _clubService.getClubById(clubId);
      final event = await _eventService.getEventById(eventId);

      if (club == null || event == null) return;

      final clubProfile =
          await _personalityLearning.getCurrentPersonality(club.founderId);
      if (clubProfile == null) return;

      // Find candidates
      final candidates = await _findEventCandidates(club, event);

      for (final candidate in candidates) {
        try {
          final stringPred =
              await _futureCompatService.predictFutureCompatibility(
            userAId: candidate.agentId,
            userBId: clubProfile.agentId,
            targetTime: event.startTime,
          );

          final quantumTraj =
              await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: candidate.userId,
            userBId: club.founderId,
            startTime: DateTime.now(),
            endTime: event.startTime,
          );

          final outreachScore = _combineClubOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            stabilityPrediction: 0.0, // Not applicable for events
          );

          if (outreachScore >= 0.75) {
            await _ai2aiCommunication.sendOutreachMessage(
              fromAgentId: clubProfile.agentId,
              toAgentId: candidate.agentId,
              messageType: OutreachMessageType.clubEventInvitation,
              payload: {
                'club_id': clubId,
                'event_id': eventId,
                'compatibility_score': outreachScore,
                'reasoning': 'High compatibility for club event',
              },
            );
          }
        } catch (e) {
          developer.log('Error processing candidate: $e', name: _logName);
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process club event outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  double _combineClubOutreachSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double stabilityPrediction,
  }) {
    return (0.30 * stringPrediction +
            0.35 * quantumTrajectory +
            0.35 * stabilityPrediction)
        .clamp(0.0, 1.0);
  }

  Future<KnotFabric> _getOrCreateFabricForClub(
      String clubId, List<String> memberIds) async {
    // Placeholder - would load/create fabric
    return await _fabricService.generateMultiStrandBraidFabric(
      userKnots: [],
    );
  }

  Future<List<ClubCandidate>> _findMembershipCandidates(
      dynamic club, KnotFabric fabric) async {
    return [];
  }

  Future<List<ClubCandidate>> _findEventCandidates(
      dynamic club, dynamic event) async {
    return [];
  }
}

/// Club candidate
class ClubCandidate {
  final String userId;
  final String agentId;

  ClubCandidate({
    required this.userId,
    required this.agentId,
  });
}
