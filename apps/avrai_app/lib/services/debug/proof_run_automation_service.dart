// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_network/network/device_discovery.dart'
    show DiscoveredDevice, DeviceType;
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/privacy_protection.dart'
    show AnonymizedVibeData, AnonymizedVibeMetrics;
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/background/headless_background_runtime_coordinator.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SimulatedHeadlessSmokeRequest {
  const SimulatedHeadlessSmokeRequest({
    required this.platformMode,
    this.userId,
    this.scenarioName = 'simulated_headless_smoke_v1',
    this.wakeReasons = defaultWakeReasons,
  });

  static const List<BackgroundWakeReason> defaultWakeReasons =
      <BackgroundWakeReason>[
        BackgroundWakeReason.bleEncounter,
        BackgroundWakeReason.trustedAnnounceRefresh,
        BackgroundWakeReason.significantLocation,
        BackgroundWakeReason.backgroundTaskWindow,
      ];

  final String platformMode;
  final String? userId;
  final String scenarioName;
  final List<BackgroundWakeReason> wakeReasons;
}

enum EventPlanningBetaSmokeMilestone {
  eventTruthEntered,
  airGapCrossed,
  suggestionShown,
  publishCompleted,
  safetyChecklistOpened,
  debriefCompleted,
}

class SimulatedHeadlessSmokeResult {
  const SimulatedHeadlessSmokeResult({
    required this.success,
    required this.platformMode,
    required this.runId,
    required this.exportDirectoryPath,
    required this.simulatedNodeIds,
    required this.executedWakeReasons,
    required this.backgroundWakeRunCount,
    required this.fieldValidationProofCount,
    required this.fieldValidationScenarios,
    required this.ambientCandidateCount,
    required this.ambientConfirmedCount,
    required this.ambientDuplicateMergeCount,
    required this.ambientRejectedPromotionCount,
    this.failureSummary,
  });

  final bool success;
  final String platformMode;
  final String runId;
  final String exportDirectoryPath;
  final List<String> simulatedNodeIds;
  final List<String> executedWakeReasons;
  final int backgroundWakeRunCount;
  final int fieldValidationProofCount;
  final List<String> fieldValidationScenarios;
  final int ambientCandidateCount;
  final int ambientConfirmedCount;
  final int ambientDuplicateMergeCount;
  final int ambientRejectedPromotionCount;
  final String? failureSummary;

  Map<String, Object?> toJson() => <String, Object?>{
    'success': success,
    'platform_mode': platformMode,
    'run_id': runId,
    'export_directory_path': exportDirectoryPath,
    'simulated_node_ids': simulatedNodeIds,
    'executed_wake_reasons': executedWakeReasons,
    'background_wake_run_count': backgroundWakeRunCount,
    'field_validation_proof_count': fieldValidationProofCount,
    'field_validation_scenarios': fieldValidationScenarios,
    'ambient_candidate_count': ambientCandidateCount,
    'ambient_confirmed_count': ambientConfirmedCount,
    'ambient_duplicate_merge_count': ambientDuplicateMergeCount,
    'ambient_rejected_promotion_count': ambientRejectedPromotionCount,
    if (failureSummary != null) 'failure_summary': failureSummary,
  };
}

class _AmbientSmokeDeltaCounts {
  const _AmbientSmokeDeltaCounts({
    required this.candidateCount,
    required this.confirmedCount,
    required this.duplicateMergeCount,
    required this.rejectedPromotionCount,
  });

  factory _AmbientSmokeDeltaCounts.fromSnapshots({
    required AmbientSocialLearningDiagnosticsSnapshot? before,
    required AmbientSocialLearningDiagnosticsSnapshot? after,
  }) {
    int delta(int afterValue, int beforeValue) {
      final difference = afterValue - beforeValue;
      return difference < 0 ? 0 : difference;
    }

    return _AmbientSmokeDeltaCounts(
      candidateCount: delta(
        after?.candidateCoPresenceObservationCount ?? 0,
        before?.candidateCoPresenceObservationCount ?? 0,
      ),
      confirmedCount: delta(
        after?.confirmedInteractionPromotionCount ?? 0,
        before?.confirmedInteractionPromotionCount ?? 0,
      ),
      duplicateMergeCount: delta(
        after?.duplicateMergeCount ?? 0,
        before?.duplicateMergeCount ?? 0,
      ),
      rejectedPromotionCount: delta(
        after?.rejectedInteractionPromotionCount ?? 0,
        before?.rejectedInteractionPromotionCount ?? 0,
      ),
    );
  }

  final int candidateCount;
  final int confirmedCount;
  final int duplicateMergeCount;
  final int rejectedPromotionCount;
}

class ProofRunAutomationService {
  static const String eventPlanningBetaSmokeScenarioName =
      'event_planning_beta_smoke_v1';

  ProofRunAutomationService({
    required ProofRunServiceV0 proofRunService,
    AdminRuntimeGovernanceService? adminRuntimeGovernanceService,
    HeadlessBackgroundRuntimeCoordinator? backgroundCoordinator,
    required SharedPreferencesCompat prefs,
    required StorageService storageService,
    required SupabaseService supabaseService,
    PersonalityLearning? personalityLearning,
    VibeConnectionOrchestrator? orchestrator,
    AmbientSocialRealityLearningService? ambientSocialLearningService,
    BackgroundWakeExecutionRunRecordStore? backgroundWakeRunRecordStore,
    Future<List<String>> Function({
      required String runId,
      required String userId,
      required String scenarioName,
    })?
    simulateEncounterOverride,
    Future<void> Function()? startHeadlessRuntimeEnvelopeOverride,
    Future<HeadlessBackgroundRuntimeExecutionResult> Function({
      required BackgroundWakeReason reason,
      bool? isWifiAvailable,
      bool? isIdle,
      String? platformSource,
    })?
    handleWakeOverride,
    Future<List<DomainExecutionFieldScenarioProof>> Function()?
    runFieldAcceptanceValidationOverride,
    DateTime Function()? nowUtc,
  }) : _proofRunService = proofRunService,
       _adminRuntimeGovernanceService = adminRuntimeGovernanceService,
       _backgroundCoordinator = backgroundCoordinator,
       _prefs = prefs,
       _storageService = storageService,
       _personalityLearning = personalityLearning,
       _orchestrator = orchestrator,
       _supabaseService = supabaseService,
       _ambientSocialLearningService = ambientSocialLearningService,
       _backgroundWakeRunRecordStore = backgroundWakeRunRecordStore,
       _simulateEncounterOverride = simulateEncounterOverride,
       _startHeadlessRuntimeEnvelopeOverride =
           startHeadlessRuntimeEnvelopeOverride,
       _handleWakeOverride = handleWakeOverride,
       _runFieldAcceptanceValidationOverride =
           runFieldAcceptanceValidationOverride,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const String _logName = 'ProofRunAutomationService';
  static const String _debugFallbackUserId = 'debug_simulated_smoke_user';

  final ProofRunServiceV0 _proofRunService;
  final AdminRuntimeGovernanceService? _adminRuntimeGovernanceService;
  final HeadlessBackgroundRuntimeCoordinator? _backgroundCoordinator;
  final SharedPreferencesCompat _prefs;
  final StorageService _storageService;
  final PersonalityLearning? _personalityLearning;
  final VibeConnectionOrchestrator? _orchestrator;
  final SupabaseService _supabaseService;
  final AmbientSocialRealityLearningService? _ambientSocialLearningService;
  final BackgroundWakeExecutionRunRecordStore? _backgroundWakeRunRecordStore;
  final Future<List<String>> Function({
    required String runId,
    required String userId,
    required String scenarioName,
  })?
  _simulateEncounterOverride;
  final Future<void> Function()? _startHeadlessRuntimeEnvelopeOverride;
  final Future<HeadlessBackgroundRuntimeExecutionResult> Function({
    required BackgroundWakeReason reason,
    bool? isWifiAvailable,
    bool? isIdle,
    String? platformSource,
  })?
  _handleWakeOverride;
  final Future<List<DomainExecutionFieldScenarioProof>> Function()?
  _runFieldAcceptanceValidationOverride;
  final DateTime Function() _nowUtc;

  Future<List<String>> simulateAi2AiEncounter({
    required String runId,
    String? userId,
    String scenarioName = 'manual_debug_encounter',
  }) async {
    _assertDebugOnly();
    final resolvedUserId = _resolveUserId(userId);
    final override = _simulateEncounterOverride;
    if (override != null) {
      final nodeIds = await override(
        runId: runId,
        userId: resolvedUserId,
        scenarioName: scenarioName,
      );
      await _recordEncounterMilestone(
        runId: runId,
        nodeIds: nodeIds,
        scenarioName: scenarioName,
      );
      return nodeIds;
    }

    final personalityLearning = _personalityLearning;
    final orchestrator = _orchestrator;
    if (personalityLearning == null || orchestrator == null) {
      throw StateError('Simulated encounter runtime dependencies unavailable');
    }

    await _storageService.setBool('discovery_enabled', true);
    final profile =
        await personalityLearning.getCurrentPersonality(resolvedUserId) ??
        await personalityLearning.initializePersonality(resolvedUserId);
    final now = _nowUtc();
    final dimensions = <String, double>{
      for (final dimension in VibeConstants.coreDimensions) dimension: 0.62,
    };
    dimensions['community_orientation'] = 0.9;
    dimensions['exploration_eagerness'] = 0.85;

    final peerVibe = AnonymizedVibeData(
      noisyDimensions: dimensions,
      anonymizedMetrics: AnonymizedVibeMetrics(
        energy: 0.8,
        social: 0.85,
        exploration: 0.9,
      ),
      temporalContextHash: scenarioName,
      vibeSignature: 'simulated_peer_sig',
      privacyLevel: 'debug',
      anonymizationQuality: 0.95,
      salt: scenarioName,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    final devices = <DiscoveredDevice>[
      DiscoveredDevice(
        deviceId: 'sim_peer_1',
        deviceName: 'SimulatedPeer1',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        personalityData: peerVibe,
        signalStrength: -55,
        discoveredAt: now,
        metadata: <String, dynamic>{
          'proof_run': true,
          'scenario_name': scenarioName,
          'simulated': true,
        },
      ),
    ];

    await orchestrator.debugSimulateWalkByHotPath(
      userId: resolvedUserId,
      personality: profile,
      devices: devices,
    );
    final nodeIds = orchestrator
        .debugDiscoveredNodesSnapshot()
        .map((entry) => entry.nodeId)
        .toList(growable: false);
    await _recordEncounterMilestone(
      runId: runId,
      nodeIds: nodeIds,
      scenarioName: scenarioName,
    );
    return nodeIds;
  }

  Future<SimulatedHeadlessSmokeResult> runSimulatedHeadlessSmoke(
    SimulatedHeadlessSmokeRequest request,
  ) async {
    _assertDebugOnly();
    await _finishStaleRunIfPresent();
    await _ensureDebugAdminAuthorization();

    final startedAtUtc = _nowUtc();
    final runId = await _proofRunService.startRun(
      payload: <String, Object?>{
        'platform_mode': request.platformMode,
        'scenario_name': request.scenarioName,
        'simulated': true,
        'notes': 'Automated simulated headless smoke run',
      },
    );

    Directory? exportDirectory;
    var failureSummary = '';
    var nodeIds = const <String>[];
    var proofs = const <DomainExecutionFieldScenarioProof>[];
    final ambientBefore =
        _ambientSocialLearningService?.snapshot(capturedAtUtc: startedAtUtc);

    try {
      nodeIds = await simulateAi2AiEncounter(
        runId: runId,
        userId: request.userId,
        scenarioName: request.scenarioName,
      );

      final startHeadlessRuntimeEnvelope =
          _startHeadlessRuntimeEnvelopeOverride ??
          _backgroundCoordinator?.startHeadlessRuntimeEnvelope;
      if (startHeadlessRuntimeEnvelope == null) {
        throw StateError('Background coordinator unavailable');
      }
      await startHeadlessRuntimeEnvelope();
      for (final reason in request.wakeReasons) {
        final handleWake =
            _handleWakeOverride ?? _backgroundCoordinator?.handleWake;
        if (handleWake == null) {
          throw StateError('Background wake executor unavailable');
        }
        final result = await handleWake(
          reason: reason,
          isWifiAvailable: reason == BackgroundWakeReason.backgroundTaskWindow
              ? true
              : null,
          isIdle: reason == BackgroundWakeReason.backgroundTaskWindow
              ? true
              : null,
          platformSource:
              'simulated_smoke:${request.platformMode}:${reason.wireName}',
        );
        await _proofRunService.recordMilestone(
          runId: runId,
          eventType: 'proof_simulated_headless_wake_executed',
          payload: <String, Object?>{
            'platform_mode': request.platformMode,
            'reason': reason.wireName,
            'simulated': true,
            'mesh_due_replay_count': result.meshResult.dueReplayCount,
            'mesh_recovered_replay_count':
                result.meshResult.recoveredReachabilityReplayCount,
            'ai2ai_released_count': result.ai2aiResult.releasedCount,
            'ai2ai_blocked_count': result.ai2aiResult.blockedCount,
            'passive_ingested_dwell_event_count':
                result.passiveResult.ingestedDwellEventCount,
            'segment_refresh_count': result.segmentRefreshCount,
          },
        );
      }

      final runFieldAcceptanceValidation =
          _runFieldAcceptanceValidationOverride ??
          _adminRuntimeGovernanceService
              ?.runControlledPrivateMeshFieldAcceptanceValidation;
      if (runFieldAcceptanceValidation == null) {
        throw StateError('Admin runtime governance service unavailable');
      }
      proofs = await runFieldAcceptanceValidation();
      await _proofRunService.recordMilestone(
        runId: runId,
        eventType: 'proof_simulated_field_validation_completed',
        payload: <String, Object?>{
          'platform_mode': request.platformMode,
          'scenario_name': request.scenarioName,
          'simulated': true,
          'proof_count': proofs.length,
          'validation_scenarios': proofs
              .map((entry) => entry.scenario.name)
              .toList(growable: false),
        },
      );

      await _proofRunService.finishActiveRun(
        payload: <String, Object?>{
          'platform_mode': request.platformMode,
          'scenario_name': request.scenarioName,
          'simulated': true,
          'notes': 'Finished via ProofRunAutomationService',
        },
      );
      exportDirectory = await _proofRunService.exportRunReceipts(runId: runId);

      final ambientSnapshot = _ambientSocialLearningService?.snapshot(
        capturedAtUtc: _nowUtc(),
      );
      final ambientDelta = _AmbientSmokeDeltaCounts.fromSnapshots(
        before: ambientBefore,
        after: ambientSnapshot,
      );
      final wakeRunCount = _recentSimulatedWakeRuns(
        platformMode: request.platformMode,
        startedAtUtc: startedAtUtc,
      ).length;
      return SimulatedHeadlessSmokeResult(
        success: true,
        platformMode: request.platformMode,
        runId: runId,
        exportDirectoryPath: exportDirectory.path,
        simulatedNodeIds: nodeIds,
        executedWakeReasons: request.wakeReasons
            .map((entry) => entry.wireName)
            .toList(),
        backgroundWakeRunCount: wakeRunCount,
        fieldValidationProofCount: proofs.length,
        fieldValidationScenarios:
            proofs.map((entry) => entry.scenario.name).toList(growable: false),
        ambientCandidateCount: ambientDelta.candidateCount,
        ambientConfirmedCount: ambientDelta.confirmedCount,
        ambientDuplicateMergeCount: ambientDelta.duplicateMergeCount,
        ambientRejectedPromotionCount: ambientDelta.rejectedPromotionCount,
      );
    } catch (error, stackTrace) {
      failureSummary = error.toString();
      developer.log(
        'Simulated headless smoke run failed',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await _proofRunService.recordMilestone(
          runId: runId,
          eventType: 'proof_simulated_smoke_failed',
          payload: <String, Object?>{
            'platform_mode': request.platformMode,
            'scenario_name': request.scenarioName,
            'simulated': true,
            'failure_summary': failureSummary,
          },
        );
      } catch (_) {
        // Keep the original failure authoritative.
      }
      if (_proofRunService.getActiveRunId() == runId) {
        try {
          await _proofRunService.finishActiveRun(
            payload: <String, Object?>{
              'platform_mode': request.platformMode,
              'scenario_name': request.scenarioName,
              'simulated': true,
              'failed': true,
              'failure_summary': failureSummary,
            },
          );
        } catch (_) {
          // Preserve the original error.
        }
      }
      final ambientSnapshot = _ambientSocialLearningService?.snapshot(
        capturedAtUtc: _nowUtc(),
      );
      final ambientDelta = _AmbientSmokeDeltaCounts.fromSnapshots(
        before: ambientBefore,
        after: ambientSnapshot,
      );
      return SimulatedHeadlessSmokeResult(
        success: false,
        platformMode: request.platformMode,
        runId: runId,
        exportDirectoryPath: exportDirectory?.path ?? '',
        simulatedNodeIds: nodeIds,
        executedWakeReasons: request.wakeReasons
            .map((entry) => entry.wireName)
            .toList(),
        backgroundWakeRunCount: _recentSimulatedWakeRuns(
          platformMode: request.platformMode,
          startedAtUtc: startedAtUtc,
        ).length,
        fieldValidationProofCount: proofs.length,
        fieldValidationScenarios:
            proofs.map((entry) => entry.scenario.name).toList(growable: false),
        ambientCandidateCount: ambientDelta.candidateCount,
        ambientConfirmedCount: ambientDelta.confirmedCount,
        ambientDuplicateMergeCount: ambientDelta.duplicateMergeCount,
        ambientRejectedPromotionCount: ambientDelta.rejectedPromotionCount,
        failureSummary: failureSummary,
      );
    }
  }

  Future<String> startEventPlanningBetaSmoke({
    String platformMode = 'ios',
    String? userId,
  }) async {
    _assertDebugOnly();
    await _finishStaleRunIfPresent();
    final String runId = await _proofRunService.startRun(
      payload: <String, Object?>{
        'platform_mode': platformMode,
        'scenario_name': eventPlanningBetaSmokeScenarioName,
        'manual': true,
        'user_id': _resolveUserId(userId),
        'notes': 'Manual event planning beta smoke run',
      },
    );
    await _proofRunService.recordMilestone(
      runId: runId,
      eventType: 'proof_event_planning_smoke_started',
      payload: <String, Object?>{
        'platform_mode': platformMode,
        'scenario_name': eventPlanningBetaSmokeScenarioName,
        'manual': true,
      },
    );
    return runId;
  }

  Future<void> recordEventPlanningBetaSmokeMilestone({
    required String runId,
    required EventPlanningBetaSmokeMilestone milestone,
    String platformMode = 'ios',
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _proofRunService.recordMilestone(
      runId: runId,
      eventType: _eventPlanningSmokeEventType(milestone),
      payload: <String, Object?>{
        'platform_mode': platformMode,
        'scenario_name': eventPlanningBetaSmokeScenarioName,
        'manual': true,
        'milestone': milestone.name,
        ...payload,
      },
    );
  }

  Future<String> finishAndExportEventPlanningBetaSmoke({
    required String runId,
    String platformMode = 'ios',
  }) async {
    final Directory exportDirectory = await _proofRunService.exportRunReceipts(
      runId: runId,
    );
    if (_proofRunService.getActiveRunId() == runId) {
      await _proofRunService.finishActiveRun(
        payload: <String, Object?>{
          'platform_mode': platformMode,
          'scenario_name': eventPlanningBetaSmokeScenarioName,
          'manual': true,
          'notes': 'Finished manual event planning beta smoke run',
        },
      );
    }
    return exportDirectory.path;
  }

  void _assertDebugOnly() {
    if (!kDebugMode) {
      throw StateError('ProofRunAutomationService is debug-only.');
    }
  }

  Future<void> _finishStaleRunIfPresent() async {
    final activeRunId = _proofRunService.getActiveRunId();
    if (activeRunId == null || activeRunId.isEmpty) {
      return;
    }
    await _proofRunService.finishActiveRun(
      payload: <String, Object?>{
        'notes': 'Superseded by automated simulated smoke run',
        'simulated': true,
        'superseded': true,
      },
    );
  }

  Future<void> _ensureDebugAdminAuthorization() async {
    final adminRuntimeGovernanceService = _adminRuntimeGovernanceService;
    if (adminRuntimeGovernanceService != null &&
        adminRuntimeGovernanceService.isAuthorized) {
      return;
    }
    final session = AdminSession(
      username: 'debug-smoke-admin',
      loginTime: _nowUtc(),
      expiresAt: _nowUtc().add(const Duration(hours: 8)),
      accessLevel: AdminAccessLevel.godMode,
      permissions: AdminPermissions.all(),
    );
    await _prefs.setString('admin_session', jsonEncode(session.toJson()));
  }

  String _resolveUserId(String? requestedUserId) {
    final trimmedRequested = requestedUserId?.trim();
    if (trimmedRequested != null && trimmedRequested.isNotEmpty) {
      return trimmedRequested;
    }

    final supabaseUserId = _supabaseService.currentUser?.id;
    if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
      return supabaseUserId;
    }

    final storedUserId = _storageService.getString('currentUser');
    if (storedUserId != null && storedUserId.isNotEmpty) {
      return storedUserId;
    }

    return _debugFallbackUserId;
  }

  Future<void> _recordEncounterMilestone({
    required String runId,
    required List<String> nodeIds,
    required String scenarioName,
  }) {
    return _proofRunService.recordMilestone(
      runId: runId,
      eventType: 'proof_ai2ai_encounter_simulated',
      payload: <String, Object?>{
        'simulated': true,
        'scenario_name': scenarioName,
        'transport': 'simulated_debug_runtime',
        'node_ids': nodeIds,
        'node_count': nodeIds.length,
      },
    );
  }

  List<BackgroundWakeExecutionRunRecord> _recentSimulatedWakeRuns({
    required String platformMode,
    required DateTime startedAtUtc,
  }) {
    final store = _backgroundWakeRunRecordStore;
    if (store == null) {
      return const <BackgroundWakeExecutionRunRecord>[];
    }
    final prefix = 'simulated_smoke:$platformMode:';
    return store
        .recentRecords(limit: 32)
        .where(
          (entry) =>
              entry.platformSource.startsWith(prefix) &&
              !entry.startedAtUtc.isBefore(startedAtUtc),
        )
        .toList(growable: false);
  }

  String _eventPlanningSmokeEventType(
    EventPlanningBetaSmokeMilestone milestone,
  ) {
    return switch (milestone) {
      EventPlanningBetaSmokeMilestone.eventTruthEntered =>
        'proof_event_planning_event_truth_entered',
      EventPlanningBetaSmokeMilestone.airGapCrossed =>
        'proof_event_planning_air_gap_crossed',
      EventPlanningBetaSmokeMilestone.suggestionShown =>
        'proof_event_planning_suggestion_shown',
      EventPlanningBetaSmokeMilestone.publishCompleted =>
        'proof_event_planning_publish_completed',
      EventPlanningBetaSmokeMilestone.safetyChecklistOpened =>
        'proof_event_planning_safety_checklist_opened',
      EventPlanningBetaSmokeMilestone.debriefCompleted =>
        'proof_event_planning_debrief_completed',
    };
  }
}
