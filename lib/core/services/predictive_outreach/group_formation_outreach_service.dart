// ignore: dangling_library_doc_comments
/// Group Formation Outreach Service
/// 
/// Service for proactively forming groups by reaching out to compatible users.
/// Part of Predictive Proactive Outreach System - Phase 2.2
/// 
/// Uses knot fabric analysis, evolution predictions, and quantum compatibility
/// to find users who would form stable, cohesive groups.

import 'dart:developer' as developer;
import 'package:avrai_knot/services/knot/knot_community_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai/core/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai/core/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai/core/services/predictive_outreach/fabric_stability_prediction_service.dart';
import 'package:avrai/core/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai/core/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Group formation candidate
class GroupFormationCandidate {
  /// User ID
  final String userId;
  
  /// Agent ID
  final String agentId;
  
  /// Compatibility score with group
  final double compatibilityScore;
  
  /// Predicted fabric stability improvement
  final double stabilityImprovement;
  
  /// Optimal timing for outreach
  final DateTime? optimalTiming;
  
  /// Reasoning for inclusion
  final String reasoning;
  
  GroupFormationCandidate({
    required this.userId,
    required this.agentId,
    required this.compatibilityScore,
    required this.stabilityImprovement,
    this.optimalTiming,
    required this.reasoning,
  });
}

/// Service for proactively forming groups
class GroupFormationOutreachService {
  static const String _logName = 'GroupFormationOutreachService';
  
  final KnotCommunityService _knotCommunityService;
  final KnotFabricService _fabricService;
  // TODO: Use worldsheet for enhanced group formation predictions
  // ignore: unused_field
  final KnotWorldsheetService _worldsheetService;
  final KnotOrchestratorService _knotOrchestrator;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final FabricStabilityPredictionService _fabricStabilityService;
  final EvolutionPatternAnalysisService _evolutionPatternService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;
  
  GroupFormationOutreachService({
    required KnotCommunityService knotCommunityService,
    required KnotFabricService fabricService,
    required KnotWorldsheetService worldsheetService,
    required KnotOrchestratorService knotOrchestrator,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required FabricStabilityPredictionService fabricStabilityService,
    required EvolutionPatternAnalysisService evolutionPatternService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _knotCommunityService = knotCommunityService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _knotOrchestrator = knotOrchestrator,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _fabricStabilityService = fabricStabilityService,
        _evolutionPatternService = evolutionPatternService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;
  
  /// Form a new group by finding compatible users and sending outreach
  /// 
  /// **Flow:**
  /// 1. Get seed user(s) for group
  /// 2. Predict optimal group composition using knot fabric analysis
  /// 3. Find candidates who would improve fabric stability
  /// 4. Calculate comprehensive compatibility for each candidate
  /// 5. Determine optimal timing for group formation
  /// 6. Send AI2AI outreach to selected candidates
  /// 
  /// **Parameters:**
  /// - `seedUserIds`: Initial user(s) to form group around
  /// - `targetGroupSize`: Desired group size (default: 5)
  /// - `groupPurpose`: Optional purpose/context for group
  Future<void> formGroupWithOutreach({
    required List<String> seedUserIds,
    int targetGroupSize = 5,
    String? groupPurpose,
  }) async {
    try {
      developer.log(
        'Forming group with ${seedUserIds.length} seed user(s), target size: $targetGroupSize',
        name: _logName,
      );
      
      // 1. Get seed user profiles and knots
      final seedProfiles = <PersonalityProfile>[];
      final seedKnots = <PersonalityKnot>[];
      
      for (final userId in seedUserIds) {
        final profile = await _personalityLearning.getCurrentPersonality(userId);
        if (profile == null) continue;
        
        seedProfiles.add(profile);
        
        // Get or generate knot
        final knot = await _knotOrchestrator.getOrGenerateKnot(profile);
        seedKnots.add(knot);
      }
      
      if (seedKnots.isEmpty) {
        developer.log(
          '⚠️ No knots found for seed users',
          name: _logName,
        );
        return;
      }
      
      // 2. Create initial fabric from seed users
      final initialFabric = await _fabricService.generateMultiStrandBraidFabric(
        userKnots: seedKnots,
      );
      
      // 3. Find candidates who would improve fabric stability
      final candidates = await _findGroupFormationCandidates(
        seedKnots: seedKnots,
        currentFabric: initialFabric,
        targetSize: targetGroupSize,
        currentSize: seedKnots.length,
      );
      
      developer.log(
        'Found ${candidates.length} candidates for group formation',
        name: _logName,
      );
      
      // 4. For each candidate, calculate comprehensive compatibility
      final selectedCandidates = <GroupFormationCandidate>[];
      
      for (final candidate in candidates) {
        try {
          // A. String-based future compatibility (with seed users)
          double avgStringPrediction = 0.0;
          for (final seedProfile in seedProfiles) {
            final prediction = await _futureCompatService.predictFutureCompatibility(
              userAId: seedProfile.agentId,
              userBId: candidate.agentId,
              targetTime: DateTime.now().add(const Duration(days: 7)),
            );
            avgStringPrediction += prediction.predictedCompatibility;
          }
          avgStringPrediction /= seedProfiles.length;
          
          // B. Quantum compatibility trajectory
          double avgQuantumTrajectory = 0.0;
          for (final seedProfile in seedProfiles) {
            final trajectory = await _temporalQuantumService.calculateTemporalCompatibility(
              userAId: seedProfile.agentId,
              userBId: candidate.userId,
              startTime: DateTime.now(),
              endTime: DateTime.now().add(const Duration(days: 30)),
            );
            avgQuantumTrajectory += trajectory.peakCompatibility;
          }
          avgQuantumTrajectory /= seedProfiles.length;
          
          // C. Fabric stability prediction
          final stabilityPred = await _fabricStabilityService.predictStabilityWithUser(
            groupId: 'temp_group_${DateTime.now().millisecondsSinceEpoch}',
            candidateUserId: candidate.agentId,
            currentFabric: initialFabric,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );
          
          // D. Evolution pattern analysis (optimal timing)
          DateTime? optimalTiming;
          if (seedProfiles.isNotEmpty) {
            final timingRec = await _evolutionPatternService.calculateOptimalTiming(
              userId: seedProfiles.first.agentId,
              targetId: candidate.agentId,
            );
            optimalTiming = timingRec.optimalTime;
          }
          
          // 5. Combine all signals
          final outreachScore = _combineGroupFormationSignals(
            stringPrediction: avgStringPrediction,
            quantumTrajectory: avgQuantumTrajectory,
            stabilityPrediction: stabilityPred.stabilityImprovement,
            currentCompatibility: candidate.compatibilityScore,
          );
          
          // 6. If score is high enough, add to selected candidates
          if (outreachScore >= 0.75) {
            selectedCandidates.add(GroupFormationCandidate(
              userId: candidate.userId,
              agentId: candidate.agentId,
              compatibilityScore: outreachScore,
              stabilityImprovement: stabilityPred.stabilityImprovement,
              optimalTiming: optimalTiming,
              reasoning: _generateGroupFormationReasoning(
                avgStringPrediction,
                avgQuantumTrajectory,
                stabilityPred,
                candidate.compatibilityScore,
              ),
            ));
          }
        } catch (e) {
          developer.log(
            'Error processing candidate ${candidate.agentId}: $e',
            name: _logName,
          );
          continue;
        }
      }
      
      // 7. Sort by compatibility and select top candidates
      selectedCandidates.sort((a, b) => 
        b.compatibilityScore.compareTo(a.compatibilityScore)
      );
      
      final finalCandidates = selectedCandidates.take(
        targetGroupSize - seedKnots.length
      ).toList();
      
      developer.log(
        'Selected ${finalCandidates.length} candidates for group formation',
        name: _logName,
      );
      
      // 8. Send AI2AI outreach to selected candidates
      for (final candidate in finalCandidates) {
        await _sendGroupFormationOutreach(
          seedUserIds: seedUserIds,
          candidate: candidate,
          groupPurpose: groupPurpose,
        );
      }
      
      developer.log(
        '✅ Group formation outreach complete: ${finalCandidates.length} invitations sent',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to form group with outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }
  
  /// Find candidates for onboarding group formation
  /// 
  /// Uses knot compatibility to find users who would form a good onboarding group.
  Future<void> formOnboardingGroupWithOutreach({
    required PersonalityProfile newUserProfile,
    int targetGroupSize = 5,
  }) async {
    try {
      developer.log(
        'Forming onboarding group for new user: ${newUserProfile.agentId.substring(0, 10)}...',
        name: _logName,
      );
      
      // Use KnotCommunityService to find compatible onboarding users
      final compatibleProfiles = await _knotCommunityService.createOnboardingKnotGroup(
        newUserProfile: newUserProfile,
        compatibilityThreshold: 0.7,
        maxGroupSize: targetGroupSize,
      );
      
      if (compatibleProfiles.isEmpty) {
        developer.log(
          'No compatible users found for onboarding group',
          name: _logName,
        );
        return;
      }
      
      // Send outreach to compatible users
      for (final profile in compatibleProfiles) {
        await _sendOnboardingGroupOutreach(
          newUserProfile: newUserProfile,
          candidateProfile: profile,
        );
      }
      
      developer.log(
        '✅ Onboarding group outreach complete: ${compatibleProfiles.length} invitations sent',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to form onboarding group: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }
  
  /// Combine all group formation signals into single score
  double _combineGroupFormationSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double stabilityPrediction,
    required double currentCompatibility,
  }) {
    // Weighted combination:
    // - String prediction: 25% (knot evolution)
    // - Quantum trajectory: 30% (temporal quantum)
    // - Stability prediction: 30% (fabric improvement)
    // - Current compatibility: 15% (baseline)
    
    return (
      0.25 * stringPrediction +
      0.30 * quantumTrajectory +
      0.30 * stabilityPrediction +
      0.15 * currentCompatibility
    ).clamp(0.0, 1.0);
  }
  
  /// Generate reasoning for group formation
  String _generateGroupFormationReasoning(
    double stringPrediction,
    double quantumTrajectory,
    FabricStabilityPrediction stabilityPred,
    double currentCompatibility,
  ) {
    final reasons = <String>[];
    
    if (stringPrediction >= 0.8) {
      reasons.add('Strong knot evolution compatibility');
    }
    
    if (quantumTrajectory >= 0.8) {
      reasons.add('High quantum compatibility trajectory');
    }
    
    if (stabilityPred.wouldImprove) {
      reasons.add('Would improve fabric stability by ${(stabilityPred.stabilityImprovement * 100).toStringAsFixed(0)}%');
    }
    
    if (currentCompatibility >= 0.7) {
      reasons.add('Strong current compatibility');
    }
    
    return reasons.isEmpty
        ? 'High compatibility match for group formation'
        : '${reasons.join('. ')}.';
  }
  
  /// Send group formation outreach via AI2AI
  Future<void> _sendGroupFormationOutreach({
    required List<String> seedUserIds,
    required GroupFormationCandidate candidate,
    String? groupPurpose,
  }) async {
    try {
      // Use first seed user's agent ID as sender
      final seedProfile = await _personalityLearning.getCurrentPersonality(seedUserIds.first);
      if (seedProfile == null) {
        developer.log(
          '⚠️ Could not get seed user profile for outreach',
          name: _logName,
        );
        return;
      }
      
      final result = await _ai2aiCommunication.sendOutreachMessage(
        fromAgentId: seedProfile.agentId,
        toAgentId: candidate.agentId,
        messageType: OutreachMessageType.groupFormation,
        payload: {
          'seed_user_count': seedUserIds.length,
          'compatibility_score': candidate.compatibilityScore,
          'stability_improvement': candidate.stabilityImprovement,
          'reasoning': candidate.reasoning,
          'group_purpose': groupPurpose,
          'optimal_timing': candidate.optimalTiming?.toIso8601String(),
        },
      );
      
      if (result.success) {
        developer.log(
          '✅ Group formation outreach sent via Signal Protocol: ${candidate.userId} '
          '(score: ${candidate.compatibilityScore.toStringAsFixed(2)})',
          name: _logName,
        );
      } else {
        developer.log(
          '❌ Failed to send group formation outreach: ${result.error}',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error sending group formation outreach: $e',
        name: _logName,
      );
    }
  }
  
  /// Send onboarding group outreach
  Future<void> _sendOnboardingGroupOutreach({
    required PersonalityProfile newUserProfile,
    required PersonalityProfile candidateProfile,
  }) async {
    try {
      final result = await _ai2aiCommunication.sendOutreachMessage(
        fromAgentId: newUserProfile.agentId,
        toAgentId: candidateProfile.agentId,
        messageType: OutreachMessageType.groupFormation,
        payload: {
          'onboarding_group': true,
          'new_user_agent_id': newUserProfile.agentId,
          'reasoning': 'Compatible knot topology for onboarding group',
        },
      );
      
      if (result.success) {
        developer.log(
          '✅ Onboarding group outreach sent via Signal Protocol: ${candidateProfile.agentId.substring(0, 10)}...',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error sending onboarding group outreach: $e',
        name: _logName,
      );
    }
  }
  
  /// Find candidates for group formation
  Future<List<CandidateUser>> _findGroupFormationCandidates({
    required List<PersonalityKnot> seedKnots,
    required KnotFabric currentFabric,
    required int targetSize,
    required int currentSize,
  }) async {
    // Placeholder - would query database for candidate users
    // Filter by:
    // - Location (if proximity-based)
    // - Activity level
    // - Not already in a similar group
    // - Has knot data available
    
    final candidates = <CandidateUser>[];
    
    // TODO: Implement actual database query
    // For now, return empty list
    // In production, would:
    // 1. Query active users with knots
    // 2. Filter by location/activity
    // 3. Calculate initial compatibility with seed users
    // 4. Return top candidates
    
    return candidates;
  }
}

/// Candidate user for group formation
class CandidateUser {
  final String agentId;
  final String userId;
  final double compatibilityScore;
  
  CandidateUser({
    required this.agentId,
    required this.userId,
    this.compatibilityScore = 0.0,
  });
}
