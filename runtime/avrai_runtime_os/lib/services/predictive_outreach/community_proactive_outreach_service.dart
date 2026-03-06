// ignore: dangling_library_doc_comments
/// Community Proactive Outreach Service
///
/// Service for communities to proactively reach out to users.
/// Part of Predictive Proactive Outreach System - Phase 2.1
///
/// Uses knot fabric analysis, worldsheet predictions, and quantum compatibility
/// to find users who would improve community fabric stability.

import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/fabric_stability_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Service for communities to proactively reach out to users
class CommunityProactiveOutreachService {
  static const String _logName = 'CommunityProactiveOutreachService';

  final CommunityService _communityService;
  final KnotFabricService _fabricService;
  final KnotWorldsheetService _worldsheetService;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final FabricStabilityPredictionService _fabricStabilityService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;

  CommunityProactiveOutreachService({
    required CommunityService communityService,
    required KnotFabricService fabricService,
    required KnotWorldsheetService worldsheetService,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required FabricStabilityPredictionService fabricStabilityService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _communityService = communityService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _fabricStabilityService = fabricStabilityService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;

  /// Find users for community and send proactive outreach
  ///
  /// **Flow:**
  /// 1. Get community and analyze current fabric
  /// 2. Get worldsheet for evolution analysis
  /// 3. Predict future fabric stability
  /// 4. Find users who would improve fabric
  /// 5. Calculate comprehensive compatibility for each candidate
  /// 6. Send AI2AI outreach for high-compatibility matches
  ///
  /// **Parameters:**
  /// - `communityId`: Community ID
  Future<void> processCommunityOutreach({
    required String communityId,
  }) async {
    try {
      developer.log(
        'Processing community outreach for: $communityId',
        name: _logName,
      );

      // 1. Get community
      final community = await _communityService.getCommunityById(communityId);
      if (community == null) {
        developer.log(
          '⚠️ Community not found: $communityId',
          name: _logName,
        );
        return;
      }

      // 2. Analyze current fabric
      final fabric = await _getOrCreateFabricForCommunity(
          communityId, community.memberIds);

      // 3. Get worldsheet for evolution analysis
      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: communityId,
        userIds: community.memberIds,
      );

      // 4. Predict future fabric stability
      final futureStability =
          await _fabricStabilityService.predictFutureFabricStability(
        groupId: communityId,
        targetTime: DateTime.now().add(const Duration(days: 30)),
      );

      // Use worldsheet and futureStability for enhanced predictions
      if (worldsheet != null && futureStability.stabilityChange > 0) {
        developer.log(
          'Fabric stability improving: ${futureStability.stabilityChange.toStringAsFixed(2)}',
          name: _logName,
        );
      }

      // 5. Find users who would improve fabric stability
      final candidates = await _findUsersForFabricImprovement(
        community: community,
        currentFabric: fabric,
        minStabilityImprovement: 0.1,
      );

      developer.log(
        'Found ${candidates.length} candidate users for community outreach',
        name: _logName,
      );

      // 6. For each candidate, calculate comprehensive compatibility
      for (final candidate in candidates) {
        try {
          // A. String-based future compatibility
          final stringPrediction =
              await _futureCompatService.predictFutureCompatibility(
            userAId: candidate.agentId,
            userBId: community.founderId,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );

          // B. Quantum compatibility trajectory
          final quantumTrajectory =
              await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: candidate.userId ?? candidate.agentId,
            userBId: community.founderId,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );

          // C. Fabric stability prediction
          final stabilityPred =
              await _fabricStabilityService.predictStabilityWithUser(
            groupId: communityId,
            candidateUserId: candidate.agentId,
            currentFabric: fabric,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );

          // D. Current weave fit
          final currentWeaveFit =
              await _communityService.calculateUserCommunityWeaveFit(
                    communityId: communityId,
                    userId: candidate.userId ?? candidate.agentId,
                  ) ??
                  0.0;

          // 7. Combine all signals
          final outreachScore = _combineOutreachSignals(
            stringPrediction: stringPrediction.predictedCompatibility,
            quantumTrajectory: quantumTrajectory.peakCompatibility,
            stabilityPrediction: stabilityPred.stabilityImprovement,
            currentWeaveFit: currentWeaveFit,
          );

          // 8. If score is high enough, gate on churn risk then send outreach
          if (outreachScore >= 0.75) {
            if (await _isHighChurnRisk(candidate.agentId)) {
              developer.log(
                'Skipping standard outreach for high-churn-risk candidate: ${candidate.agentId}',
                name: _logName,
              );
            } else {
              await _sendAI2AIOutreach(
                communityId: communityId,
                userId: candidate.userId ?? candidate.agentId,
                agentId: candidate.agentId,
                outreachScore: outreachScore,
                reasoning: _generateOutreachReasoning(
                  stringPrediction,
                  quantumTrajectory,
                  stabilityPred,
                  currentWeaveFit,
                ),
              );
            }
          }
        } catch (e) {
          developer.log(
            'Error processing candidate ${candidate.agentId}: $e',
            name: _logName,
          );
          continue;
        }
      }

      developer.log(
        '✅ Community outreach processing complete: $communityId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process community outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Returns true when the Markov predictor flags a candidate as high churn risk
  /// (> 0.6 within 7 days). Falls back to false when no predictor is registered,
  /// so this gate is entirely additive — it can never block outreach without
  /// the prediction service present.
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

  /// Process all communities
  Future<void> processAllCommunities() async {
    try {
      final communities = await _getAllCommunities();

      for (final community in communities) {
        await processCommunityOutreach(communityId: community.id);
      }
    } catch (e) {
      developer.log(
        'Error processing all communities: $e',
        name: _logName,
      );
    }
  }

  /// Combine all predictive signals into single score
  double _combineOutreachSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double stabilityPrediction,
    required double currentWeaveFit,
  }) {
    // Weighted combination:
    // - String prediction: 25% (knot evolution)
    // - Quantum trajectory: 30% (temporal quantum)
    // - Stability prediction: 25% (fabric improvement)
    // - Current weave fit: 20% (baseline compatibility)

    return (0.25 * stringPrediction +
            0.30 * quantumTrajectory +
            0.25 * stabilityPrediction +
            0.20 * currentWeaveFit)
        .clamp(0.0, 1.0);
  }

  /// Send outreach through AI2AI network
  Future<void> _sendAI2AIOutreach({
    required String communityId,
    required String userId,
    required String agentId,
    required double outreachScore,
    required String reasoning,
  }) async {
    try {
      // 1. Get user's AI personality
      final userAI = await _personalityLearning.getCurrentPersonality(userId);

      if (userAI == null) {
        developer.log(
          '⚠️ Could not get user AI personality for outreach',
          name: _logName,
        );
        return;
      }

      // 2. Get community's agent ID (use founder's agent ID as community AI)
      final communityAgentId = await _getCommunityAgentId(communityId);
      if (communityAgentId == null) {
        developer.log(
          '⚠️ Could not get community agent ID for outreach',
          name: _logName,
        );
        return;
      }

      // 3. Send AI2AI message through AI2AIOutreachCommunicationService (Signal Protocol)
      final result = await _ai2aiCommunication.sendOutreachMessage(
        fromAgentId: communityAgentId,
        toAgentId: agentId,
        messageType: OutreachMessageType.communityInvitation,
        payload: {
          'community_id': communityId,
          'compatibility_score': outreachScore,
          'reasoning': reasoning,
          'predicted_benefit': 'Would improve fabric stability',
        },
      );

      if (result.success) {
        developer.log(
          '✅ AI2AI outreach sent via Signal Protocol: community $communityId -> user $userId '
          '(score: ${outreachScore.toStringAsFixed(2)}, encryption: ${result.encryptionType.name})',
          name: _logName,
        );
      } else {
        developer.log(
          '❌ Failed to send AI2AI outreach: ${result.error}',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error sending AI2AI outreach: $e',
        name: _logName,
      );
    }
  }

  /// Generate outreach reasoning
  String _generateOutreachReasoning(
    CompatibilityTrajectory stringPrediction,
    TemporalQuantumCompatibility quantumTrajectory,
    FabricStabilityPrediction stabilityPred,
    double currentWeaveFit,
  ) {
    final reasons = <String>[];

    if (stringPrediction.isImproving) {
      reasons.add('Compatibility improving over time');
    }

    if (quantumTrajectory.isImproving) {
      reasons.add('Quantum compatibility trajectory is positive');
    }

    if (stabilityPred.wouldImprove) {
      reasons.add(
          'Would improve fabric stability by ${(stabilityPred.stabilityImprovement * 100).toStringAsFixed(0)}%');
    }

    if (currentWeaveFit >= 0.7) {
      reasons.add('Strong current compatibility');
    }

    return reasons.isEmpty
        ? 'High compatibility match'
        : '${reasons.join('. ')}.';
  }

  /// Get or create fabric for community
  Future<KnotFabric> _getOrCreateFabricForCommunity(
    String communityId,
    List<String> memberIds,
  ) async {
    // Try to load existing fabric
    // If not found, generate new fabric from member knots
    // This is a simplified version - would use fabric storage service in production

    // For now, generate fabric from member knots
    final memberKnots = <PersonalityKnot>[];
    // TODO: Load knots from storage for each memberId
    // for (final memberId in memberIds) {
    //   final knot = await _knotStorage.loadKnot(memberId);
    //   if (knot != null) memberKnots.add(knot);
    // }

    return await _fabricService.generateMultiStrandBraidFabric(
      userKnots: memberKnots,
    );
  }

  /// Find users who would improve fabric stability
  Future<List<CandidateUser>> _findUsersForFabricImprovement({
    required dynamic community, // Community model
    required KnotFabric currentFabric,
    double minStabilityImprovement = 0.1,
  }) async {
    // Placeholder - would query database for candidate users
    // Filter by location, activity, etc.
    return [];
  }

  /// Get all communities
  Future<List<dynamic>> _getAllCommunities() async {
    // Placeholder - would query database
    return [];
  }

  /// Get community's agent ID for AI2AI communication
  Future<String?> _getCommunityAgentId(String communityId) async {
    // Use community's founder agent ID as the community AI
    final community = await _communityService.getCommunityById(communityId);
    return community?.founderId;
  }
}

/// Candidate user for outreach
class CandidateUser {
  final String agentId;
  final String? userId;

  CandidateUser({
    required this.agentId,
    this.userId,
  });
}
