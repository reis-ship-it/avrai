// ignore: dangling_library_doc_comments
/// Event Proactive Outreach Service
/// 
/// Service for events to proactively reach out to users.
/// Part of Predictive Proactive Outreach System - Phase 2.3
/// 
/// Uses quantum compatibility, knot predictions, and evolution patterns
/// to find users who would benefit from attending events.

import 'dart:developer' as developer;
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/events/event_matching_service.dart';
import 'package:avrai/core/services/events/event_recommendation_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai/core/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai/core/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai/core/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';

/// Event outreach candidate
class EventOutreachCandidate {
  final String userId;
  final String agentId;
  final double compatibilityScore;
  final double quantumCompatibility;
  final double knotCompatibility;
  final DateTime? optimalTiming;
  final String reasoning;
  
  EventOutreachCandidate({
    required this.userId,
    required this.agentId,
    required this.compatibilityScore,
    required this.quantumCompatibility,
    required this.knotCompatibility,
    this.optimalTiming,
    required this.reasoning,
  });
}

/// Service for events to proactively reach out to users
class EventProactiveOutreachService {
  static const String _logName = 'EventProactiveOutreachService';
  
  final ExpertiseEventService _eventService;
  // TODO: Use matching service for enhanced event matching
  // ignore: unused_field
  final EventMatchingService _matchingService;
  // TODO: Use recommendation service for enhanced event outreach
  // ignore: unused_field
  final EventRecommendationService _recommendationService;
  final FutureCompatibilityPredictionService _futureCompatService;
  final TemporalQuantumCompatibilityService _temporalQuantumService;
  final EvolutionPatternAnalysisService _evolutionPatternService;
  final AI2AIOutreachCommunicationService _ai2aiCommunication;
  final PersonalityLearning _personalityLearning;
  
  EventProactiveOutreachService({
    required ExpertiseEventService eventService,
    required EventMatchingService matchingService,
    required EventRecommendationService recommendationService,
    required FutureCompatibilityPredictionService futureCompatService,
    required TemporalQuantumCompatibilityService temporalQuantumService,
    required EvolutionPatternAnalysisService evolutionPatternService,
    required AI2AIOutreachCommunicationService ai2aiCommunication,
    required PersonalityLearning personalityLearning,
  })  : _eventService = eventService,
        _matchingService = matchingService,
        _recommendationService = recommendationService,
        _futureCompatService = futureCompatService,
        _temporalQuantumService = temporalQuantumService,
        _evolutionPatternService = evolutionPatternService,
        _ai2aiCommunication = ai2aiCommunication,
        _personalityLearning = personalityLearning;
  
  /// Process proactive outreach for an event
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Find users with high compatibility
  /// 3. Calculate predictive compatibility (string, quantum, evolution)
  /// 4. Determine optimal timing
  /// 5. Send AI2AI outreach to high-compatibility users
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  Future<void> processEventOutreach({
    required String eventId,
  }) async {
    try {
      developer.log(
        'Processing event outreach for: $eventId',
        name: _logName,
      );
      
      // 1. Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        developer.log(
          '⚠️ Event not found: $eventId',
          name: _logName,
        );
        return;
      }
      
      // 2. Get event host's agent ID (for AI2AI communication)
      final hostProfile = await _personalityLearning.getCurrentPersonality(event.host.id);
      if (hostProfile == null) {
        developer.log(
          '⚠️ Could not get host profile for event',
          name: _logName,
        );
        return;
      }
      
      // 3. Find users with high compatibility
      final candidates = await _findEventOutreachCandidates(
        event: event,
        minCompatibility: 0.7,
        maxResults: 50,
      );
      
      developer.log(
        'Found ${candidates.length} candidates for event outreach',
        name: _logName,
      );
      
      // 4. For each candidate, calculate comprehensive compatibility
      for (final candidate in candidates) {
        try {
          // A. String-based future compatibility
          final stringPrediction = await _futureCompatService.predictFutureCompatibility(
            userAId: candidate.agentId,
            userBId: hostProfile.agentId,
            targetTime: event.startTime,
          );
          
          // B. Quantum compatibility trajectory
          final quantumTrajectory = await _temporalQuantumService.calculateTemporalCompatibility(
            userAId: candidate.userId,
            userBId: event.host.id,
            startTime: DateTime.now(),
            endTime: event.startTime,
          );
          
          // C. Evolution pattern analysis (optimal timing)
          final timingRec = await _evolutionPatternService.calculateOptimalTiming(
            userId: candidate.agentId,
            targetId: hostProfile.agentId,
          );
          
          // D. Current event matching score
          // Note: EventMatchingService requires expert and user, not eventId
          // For now, use compatibility score as proxy
          final matchingScore = candidate.compatibilityScore;
          
          // 5. Combine all signals
          final outreachScore = _combineEventOutreachSignals(
            stringPrediction: stringPrediction.predictedCompatibility,
            quantumTrajectory: quantumTrajectory.peakCompatibility,
            matchingScore: matchingScore,
            currentCompatibility: candidate.compatibilityScore,
          );
          
          // 6. If score is high enough, send AI2AI outreach
          if (outreachScore >= 0.75) {
            await _sendEventOutreach(
              event: event,
              hostAgentId: hostProfile.agentId,
              candidate: candidate,
              outreachScore: outreachScore,
              optimalTiming: timingRec.optimalTime,
              reasoning: _generateEventOutreachReasoning(
                stringPrediction,
                quantumTrajectory,
                matchingScore,
                candidate,
              ),
            );
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
        '✅ Event outreach processing complete: $eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to process event outreach: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }
  
  /// Process all upcoming events
  Future<void> processAllUpcomingEvents({
    Duration lookahead = const Duration(days: 30),
  }) async {
    try {
      // Get upcoming events
      final events = await _eventService.searchEvents(
        maxResults: 100,
      );
      
      for (final event in events) {
        await processEventOutreach(eventId: event.id);
      }
    } catch (e) {
      developer.log(
        'Error processing all upcoming events: $e',
        name: _logName,
      );
    }
  }
  
  /// Combine all event outreach signals into single score
  double _combineEventOutreachSignals({
    required double stringPrediction,
    required double quantumTrajectory,
    required double matchingScore,
    required double currentCompatibility,
  }) {
    // Weighted combination:
    // - String prediction: 25% (knot evolution)
    // - Quantum trajectory: 30% (temporal quantum)
    // - Matching score: 30% (current event matching)
    // - Current compatibility: 15% (baseline)
    
    return (
      0.25 * stringPrediction +
      0.30 * quantumTrajectory +
      0.30 * matchingScore +
      0.15 * currentCompatibility
    ).clamp(0.0, 1.0);
  }
  
  /// Generate reasoning for event outreach
  String _generateEventOutreachReasoning(
    CompatibilityTrajectory stringPrediction,
    TemporalQuantumCompatibility quantumTrajectory,
    double matchingScore,
    EventOutreachCandidate candidate,
  ) {
    final reasons = <String>[];
    
    if (stringPrediction.isImproving) {
      reasons.add('Compatibility improving over time');
    }
    
    if (quantumTrajectory.isImproving) {
      reasons.add('High quantum compatibility trajectory');
    }
    
    if (matchingScore >= 0.8) {
      reasons.add('Strong event matching score');
    }
    
    if (candidate.knotCompatibility >= 0.7) {
      reasons.add('Strong knot compatibility');
    }
    
    return reasons.isEmpty
        ? 'High compatibility match for event'
        : '${reasons.join('. ')}.';
  }
  
  /// Send event outreach via AI2AI
  Future<void> _sendEventOutreach({
    required ExpertiseEvent event,
    required String hostAgentId,
    required EventOutreachCandidate candidate,
    required double outreachScore,
    DateTime? optimalTiming,
    required String reasoning,
  }) async {
    try {
      final result = await _ai2aiCommunication.sendOutreachMessage(
        fromAgentId: hostAgentId,
        toAgentId: candidate.agentId,
        messageType: OutreachMessageType.eventCall,
        payload: {
          'event_id': event.id,
          'event_title': event.title,
          'event_start_time': event.startTime.toIso8601String(),
          'compatibility_score': outreachScore,
          'quantum_compatibility': candidate.quantumCompatibility,
          'knot_compatibility': candidate.knotCompatibility,
          'reasoning': reasoning,
          'optimal_timing': optimalTiming?.toIso8601String(),
        },
      );
      
      if (result.success) {
        developer.log(
          '✅ Event outreach sent via Signal Protocol: event $event.id -> user ${candidate.userId} '
          '(score: ${outreachScore.toStringAsFixed(2)})',
          name: _logName,
        );
      } else {
        developer.log(
          '❌ Failed to send event outreach: ${result.error}',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error sending event outreach: $e',
        name: _logName,
      );
    }
  }
  
  /// Find candidates for event outreach
  Future<List<EventOutreachCandidate>> _findEventOutreachCandidates({
    required ExpertiseEvent event,
    double minCompatibility = 0.7,
    int maxResults = 50,
  }) async {
    // Placeholder - would query database for candidate users
    // Filter by:
    // - Location (near event location)
    // - Activity level
    // - Not already registered
    // - Has knot data available
    // - Event matching score above threshold
    
    final candidates = <EventOutreachCandidate>[];
    
    // TODO: Implement actual database query
    // For now, return empty list
    // In production, would:
    // 1. Query active users near event location
    // 2. Calculate initial compatibility with event
    // 3. Filter by minCompatibility
    // 4. Return top candidates
    
    return candidates;
  }
}
