// Group Matching Controller
//
// Orchestrates complete group matching workflow
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.3: Group Matching Controller
// Patent #29: Multi-Entity Quantum Entanglement Matching System
// Patent #31: Topological Knot Theory for Personality Representation
//
// **Workflow:**
// 1. Form group (proximity or manual) - via GroupFormationService
// 2. Get agentIds for all group members (privacy protection)
// 3. Load all members' PersonalityProfile objects (via agentId)
// 4. Get synchronized atomic timestamp
// 5. Create quantum entangled group state
// 6. Load/create group fabric (on-the-fly if needed)
// 7. Calculate knot compatibility (via CrossEntityCompatibilityService)
// 8. Predict string evolution (via KnotEvolutionStringService)
// 9. Measure fabric stability (via KnotFabricService)
// 10. Create worldsheet for evolution tracking (via KnotWorldsheetService)
// 11. Find matching spots using GroupMatchingService (hybrid approach)
// 12. Calculate quantum compatibility scores (with all enhancements)
// 13. Rank and filter results
// 14. Learn from successful matches (if compatibility >= 0.5)
// 15. Return unified GroupMatchingResult

import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/controllers/base/workflow_controller.dart';
import 'package:avrai_runtime_os/controllers/base/controller_result.dart';
import 'package:avrai_core/models/quantum/group_matching_input.dart';
import 'package:avrai_core/models/quantum/group_matching_result.dart';
import 'package:avrai_core/models/quantum/group_session.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_runtime_os/services/matching/group_matching_service.dart';
import 'package:avrai_runtime_os/services/matching/group_formation_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';

/// Result class for group matching controller
class GroupMatchingControllerResult extends ControllerResult {
  /// Group matching result (null if error)
  final GroupMatchingResult? matchingResult;

  const GroupMatchingControllerResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.matchingResult,
  });

  /// Create successful result
  factory GroupMatchingControllerResult.success({
    required GroupMatchingResult matchingResult,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMatchingControllerResult(
      success: true,
      matchingResult: matchingResult,
      metadata: metadata,
    );
  }

  /// Create failure result
  factory GroupMatchingControllerResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMatchingControllerResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props =>
      [success, error, errorCode, metadata, matchingResult];
}

/// Group Matching Controller
///
/// Orchestrates the complete group matching workflow:
/// 1. Validate group session
/// 2. Match group against candidate spots
/// 3. Learn from successful matches (AI2AI integration)
/// 4. Handle offline matching scenarios
/// 5. Return unified matching results
///
/// **Architecture Pattern:**
/// ```
/// UI → BLoC → GroupMatchingController → GroupMatchingService → Repository
/// ```
class GroupMatchingController
    implements
        WorkflowController<GroupMatchingInput, GroupMatchingControllerResult> {
  static const String _logName = 'GroupMatchingController';

  final GroupMatchingService _groupMatchingService;
  // ignore: unused_field
  final GroupFormationService _groupFormationService;
  // ignore: unused_field
  final AtomicClockService _atomicClock;
  // ignore: unused_field
  final AgentIdService _agentIdService;
  // ignore: unused_field
  final PersonalityLearning _personalityLearning;
  final QuantumMatchingAILearningService? _aiLearningService;
  final EnhancedConnectivityService? _connectivityService;

  GroupMatchingController({
    required GroupMatchingService groupMatchingService,
    required GroupFormationService groupFormationService,
    required AtomicClockService atomicClock,
    required AgentIdService agentIdService,
    required PersonalityLearning personalityLearning,
    QuantumMatchingAILearningService? aiLearningService,
    EnhancedConnectivityService? connectivityService,
  })  : _groupMatchingService = groupMatchingService,
        _groupFormationService = groupFormationService,
        _atomicClock = atomicClock,
        _agentIdService = agentIdService,
        _personalityLearning = personalityLearning,
        _aiLearningService = aiLearningService,
        _connectivityService = connectivityService;

  @override
  Future<GroupMatchingControllerResult> execute(
      GroupMatchingInput input) async {
    try {
      developer.log(
        '🎯 Starting group matching for group ${input.session.groupId} (${input.session.memberCount} members)',
        name: _logName,
      );

      // Validate input
      final validation = validate(input);
      if (!validation.isValid) {
        return GroupMatchingControllerResult.failure(
          error: validation.firstError ?? 'Invalid input',
          errorCode: 'VALIDATION_ERROR',
          metadata: {'validationErrors': validation.allErrors},
        );
      }

      // Check connectivity and use offline matching if offline
      final isOffline = _connectivityService != null &&
          !(await _connectivityService.hasInternetAccess());

      if (isOffline && _aiLearningService != null) {
        developer.log(
          '📴 Device is offline, attempting offline group matching',
          name: _logName,
        );

        // Try offline matching using cached quantum states
        final offlineResult = await _performOfflineGroupMatching(input);

        if (offlineResult != null) {
          developer.log(
            '✅ Offline group matching complete: ${offlineResult.matchedSpots.length} spots matched',
            name: _logName,
          );

          return GroupMatchingControllerResult.success(
            matchingResult: offlineResult,
            metadata: {'offline': true},
          );
        } else {
          developer.log(
            '⚠️ Offline matching failed, returning error',
            name: _logName,
          );
          return GroupMatchingControllerResult.failure(
            error:
                'Offline matching unavailable. Please connect to the internet.',
            errorCode: 'OFFLINE_MATCHING_UNAVAILABLE',
            metadata: {'offline': true},
          );
        }
      }

      // STEP 1: Match group against spots using GroupMatchingService
      final matchingResult = await _groupMatchingService.matchGroupAgainstSpots(
        session: input.session,
        candidateSpots: input.candidateSpots,
        matchingStrategy: input.matchingStrategy,
      );

      if (matchingResult.matchedSpots.isEmpty) {
        developer.log(
          '⚠️ No spots matched for group ${input.session.groupId}',
          name: _logName,
        );
        return GroupMatchingControllerResult.success(
          matchingResult: matchingResult,
          metadata: {'noMatches': true},
        );
      }

      // STEP 2: Learn from successful matches (AI2AI integration)
      // Learn from matches with compatibility >= 0.5
      if (_aiLearningService != null) {
        for (final matchedSpot in matchingResult.matchedSpots) {
          if (matchedSpot.groupCompatibility >= 0.5) {
            // Fire-and-forget learning
            unawaited(_learnFromSuccessfulGroupMatch(
              currentUserId: input.currentUser.id,
              session: input.session,
              matchedSpot: matchedSpot,
            ));
          }
        }
      }

      developer.log(
        '✅ Group matching complete: ${matchingResult.matchedSpots.length} spots matched',
        name: _logName,
      );

      return GroupMatchingControllerResult.success(
        matchingResult: matchingResult,
        metadata: {
          'matchedCount': matchingResult.matchedSpots.length,
          'groupSize': matchingResult.groupSize,
          'strategy': matchingResult.matchingStrategy,
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error in group matching: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return GroupMatchingControllerResult.failure(
        error: 'Group matching failed: ${e.toString()}',
        errorCode: 'GROUP_MATCHING_ERROR',
        metadata: {'exception': e.toString()},
      );
    }
  }

  @override
  ValidationResult validate(GroupMatchingInput input) {
    final errors = <String>[];

    // Validate session
    if (input.session.isExpired) {
      errors.add('Group session has expired');
    }

    if (input.session.memberCount < 2) {
      errors.add('Group must have at least 2 members');
    }

    // Validate candidate spots
    if (input.candidateSpots.isEmpty) {
      errors.add('No candidate spots provided for matching');
    }

    // Validate current user
    if (input.currentUser.id.isEmpty) {
      errors.add('Current user ID is required');
    }

    // Note: Current user validation in session would require async call
    // We'll validate this in execute() if needed

    if (errors.isEmpty) {
      return ValidationResult.valid();
    } else {
      return ValidationResult.invalid(
        generalErrors: errors,
      );
    }
  }

  /// Perform offline group matching
  ///
  /// **Flow:**
  /// 1. Get cached quantum states for group members
  /// 2. Use QuantumMatchingAILearningService for offline matching
  /// 3. Return matching result if available
  Future<GroupMatchingResult?> _performOfflineGroupMatching(
    GroupMatchingInput input,
  ) async {
    if (_aiLearningService == null) return null;

    try {
      // For offline matching, we'd need to:
      // 1. Get cached quantum states for all group members
      // 2. Get cached spot quantum states
      // 3. Perform matching using cached data
      //
      // This is a placeholder - full implementation would require
      // caching quantum states in GroupMatchingService
      developer.log(
        '⚠️ Offline group matching not fully implemented yet',
        name: _logName,
      );

      return null;
    } catch (e) {
      developer.log(
        'Error in offline group matching: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Learn from successful group match
  ///
  /// **Flow:**
  /// 1. Create matching result from group match
  /// 2. Call QuantumMatchingAILearningService.learnFromSuccessfulMatch()
  /// 3. Fire-and-forget (use unawaited)
  Future<void> _learnFromSuccessfulGroupMatch({
    required String currentUserId,
    required GroupSession session,
    required GroupMatchedSpot matchedSpot,
  }) async {
    if (_aiLearningService == null) return;

    try {
      // Create a MatchingResult from the group match for learning
      // Note: This is a simplified conversion - full implementation
      // would create a proper MatchingResult with all quantum states
      final matchingResult = MatchingResult.success(
        compatibility: matchedSpot.groupCompatibility,
        quantumCompatibility: matchedSpot.quantumCompatibility,
        knotCompatibility: matchedSpot.knotCompatibility,
        locationCompatibility: matchedSpot.locationCompatibility,
        timingCompatibility: matchedSpot.timingCompatibility,
        meaningfulConnectionScore: matchedSpot.fabricStability,
        timestamp: matchedSpot.timestamp,
        entities: [], // Would contain quantum states in full implementation
      );

      // Learn from successful match
      await _aiLearningService.learnFromSuccessfulMatch(
        userId: currentUserId,
        matchingResult: matchingResult,
        event: null, // Group matching doesn't have events
        isOffline: false,
      );

      developer.log(
        '✅ Learned from successful group match (compatibility: ${matchedSpot.groupCompatibility.toStringAsFixed(3)})',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error learning from group match: $e (non-fatal)',
        name: _logName,
      );
    }
  }

  @override
  Future<void> rollback(GroupMatchingControllerResult result) async {
    // Group matching is read-only (no state changes to rollback)
    // No rollback needed
  }
}
