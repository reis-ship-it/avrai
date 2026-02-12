// ignore: dangling_library_doc_comments
/// Expert Proactive Outreach Service
/// 
/// Service for experts to proactively reach out to users and businesses.
/// Part of Predictive Proactive Outreach System - Phase 2.6
/// 
/// Handles two types of expert outreach:
/// 1. Expert → Users (learning opportunities)
/// 2. Expert → Businesses (partnership opportunities)

import 'dart:developer' as developer;
import 'package:avrai/core/services/business/business_expert_outreach_service.dart';
import 'package:avrai/core/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai/core/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai/core/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai/core/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';

/// Service for experts to proactively reach out
class ExpertProactiveOutreachService {
  static const String _logName = 'ExpertProactiveOutreachService';
  
  // TODO: Use business expert outreach for reverse lookup
  // ignore: unused_field
  final BusinessExpertOutreachService _businessExpertOutreach;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final EvolutionPatternAnalysisService _evolutionPatternService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;
  
  ExpertProactiveOutreachService({
    required BusinessExpertOutreachService businessExpertOutreach,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required EvolutionPatternAnalysisService evolutionPatternService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _businessExpertOutreach = businessExpertOutreach,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _evolutionPatternService = evolutionPatternService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;
  
  /// Process expert learning opportunity outreach (Expert → Users)
  Future<void> processExpertLearningOutreach({
    required String expertId,
  }) async {
    try {
      developer.log(
        'Processing expert learning outreach: expert $expertId',
        name: _logName,
      );
      
      final expertProfile = await _personalityLearning.getCurrentPersonality(expertId);
      if (expertProfile == null) return;
      
      // Find users who would benefit from learning from this expert
      final candidates = await _findLearningCandidates(expertId);
      
      for (final candidate in candidates) {
        try {
          final stringPred = await _futureCompatService.predictFutureCompatibility(
            userAId: expertProfile.agentId,
            userBId: candidate.agentId,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );
          
          final quantumTraj = await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: expertId,
            userBId: candidate.userId,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );
          
          final timingRec = await _evolutionPatternService.calculateOptimalTiming(
            userId: expertProfile.agentId,
            targetId: candidate.agentId,
          );
          
          final outreachScore = _combineExpertOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            currentCompatibility: candidate.compatibilityScore,
          );
          
          if (outreachScore >= 0.75) {
            await _ai2aiCommunication.sendOutreachMessage(
              fromAgentId: expertProfile.agentId,
              toAgentId: candidate.agentId,
              messageType: OutreachMessageType.expertLearningOpportunity,
              payload: {
                'expert_id': expertId,
                'compatibility_score': outreachScore,
                'reasoning': 'High compatibility for learning opportunity',
                'optimal_timing': timingRec.optimalTime.toIso8601String(),
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
        '❌ Failed to process expert learning outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }
  
  /// Process expert-business partnership outreach (Expert → Businesses)
  Future<void> processExpertBusinessOutreach({
    required String expertId,
  }) async {
    try {
      developer.log(
        'Processing expert-business outreach: expert $expertId',
        name: _logName,
      );
      
      final expertProfile = await _personalityLearning.getCurrentPersonality(expertId);
      if (expertProfile == null) return;
      
      // Find businesses using existing service (reverse direction)
      // Note: Would need to add method to find businesses for expert
      final businesses = await _findBusinessesForExpert(expertId);
      
      for (final business in businesses) {
        try {
          final businessProfile = await _personalityLearning.getCurrentPersonality(business.businessId);
          if (businessProfile == null) continue;
          
          final stringPred = await _futureCompatService.predictFutureCompatibility(
            userAId: expertProfile.agentId,
            userBId: businessProfile.agentId,
            targetTime: DateTime.now().add(const Duration(days: 7)),
          );
          
          final quantumTraj = await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: expertId,
            userBId: business.businessId,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 30)),
          );
          
          final outreachScore = _combineExpertOutreachSignals(
            stringPrediction: stringPred.predictedCompatibility,
            quantumTrajectory: quantumTraj.peakCompatibility,
            currentCompatibility: business.compatibilityScore,
          );
          
          if (outreachScore >= 0.75) {
            await _ai2aiCommunication.sendOutreachMessage(
              fromAgentId: expertProfile.agentId,
              toAgentId: businessProfile.agentId,
              messageType: OutreachMessageType.expertBusinessPartnership,
              payload: {
                'expert_id': expertId,
                'business_id': business.businessId,
                'compatibility_score': outreachScore,
                'reasoning': 'High compatibility for expert-business partnership',
              },
            );
          }
        } catch (e) {
          developer.log('Error processing business: $e', name: _logName);
          continue;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process expert-business outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }
  
  double _combineExpertOutreachSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double currentCompatibility,
  }) {
    return (
      0.30 * stringPrediction +
      0.35 * quantumTrajectory +
      0.35 * currentCompatibility
    ).clamp(0.0, 1.0);
  }
  
  Future<List<LearningCandidate>> _findLearningCandidates(String expertId) async {
    return [];
  }
  
  Future<List<BusinessMatch>> _findBusinessesForExpert(String expertId) async {
    return [];
  }
}

/// Learning candidate
class LearningCandidate {
  final String userId;
  final String agentId;
  final double compatibilityScore;
  
  LearningCandidate({
    required this.userId,
    required this.agentId,
    this.compatibilityScore = 0.0,
  });
}

/// Business match (reused from business_expert_outreach_service)
class BusinessMatch {
  final String businessId;
  final double compatibilityScore;
  
  BusinessMatch({
    required this.businessId,
    this.compatibilityScore = 0.0,
  });
}
