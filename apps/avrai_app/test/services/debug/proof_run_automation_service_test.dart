import 'dart:convert';
import 'dart:io';

import 'package:avrai/services/debug/proof_run_automation_service.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/background/ai2ai_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/background/headless_background_runtime_coordinator.dart';
import 'package:avrai_runtime_os/services/background/mesh_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/passive_kernel_signal_intake_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsRoot;
  late Directory storageRoot;

  setUpAll(() async {
    docsRoot = await Directory.systemTemp.createTemp(
      'proof_run_automation_docs_',
    );
    storageRoot = await Directory.systemTemp.createTemp(
      'proof_run_automation_storage_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return docsRoot.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    try {
      if (docsRoot.existsSync()) {
        await docsRoot.delete(recursive: true);
      }
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore cleanup failures in temporary storage.
    }
  });

  test('runs deterministic simulated smoke and exports the existing bundle',
      () async {
    MockGetStorage.reset();

    final defaultStorage = MockGetStorage.getInstance(boxName: 'spots_default');
    final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
    final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
    final analyticsStorage =
        MockGetStorage.getInstance(boxName: 'spots_analytics');

    await defaultStorage.erase();
    await userStorage.erase();
    await aiStorage.erase();
    await analyticsStorage.erase();

    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );

    final prefs = await SharedPreferencesCompat.getInstance(
      storage: defaultStorage,
    );
    final now = DateTime.utc(2026, 3, 14, 9, 0);
    final runRecordStore = BackgroundWakeExecutionRunRecordStore(
      storageService: StorageService.instance,
      nowUtc: () => now,
    );
    final proofStore = DomainExecutionFieldScenarioProofStore(
      storageService: StorageService.instance,
      nowUtc: () => now,
    );
    final ambientService = AmbientSocialRealityLearningService(
      nowUtc: () => now,
    );
    final proofRunService = ProofRunServiceV0(
      ledger: LedgerRecorderServiceV0(
        supabaseService: SupabaseService(),
        agentIdService: AgentIdService(
          supabaseService: SupabaseService(),
        ),
        storage: StorageService.instance,
      ),
      supabase: SupabaseService(),
      prefs: prefs,
      backgroundWakeRunRecordStore: runRecordStore,
      fieldScenarioProofStore: proofStore,
      ambientSocialLearningService: ambientService,
    );

    final sequence = <String>[];
    final automationService = ProofRunAutomationService(
      proofRunService: proofRunService,
      prefs: prefs,
      storageService: StorageService.instance,
      supabaseService: SupabaseService(),
      backgroundWakeRunRecordStore: runRecordStore,
      ambientSocialLearningService: ambientService,
      simulateEncounterOverride: ({
        required String runId,
        required String userId,
        required String scenarioName,
      }) async {
        sequence.add('encounter:$scenarioName:$userId');
        return const <String>['node-sim-1'];
      },
      startHeadlessRuntimeEnvelopeOverride: () async {
        sequence.add('start_headless');
      },
      handleWakeOverride: ({
        required BackgroundWakeReason reason,
        bool? isWifiAvailable,
        bool? isIdle,
        String? platformSource,
      }) async {
        sequence.add('wake:${reason.wireName}');
        if (reason == BackgroundWakeReason.bleEncounter) {
          await ambientService.applyObservation(
            observation: _ambientObservation(
              source: AmbientSocialLearningObservationSource.passiveDwell,
              discoveredPeerIds: const <String>['peer-a', 'peer-b'],
              confirmedInteractivePeerIds: const <String>[],
              socialContext: 'small_group',
              placeVibeLabel: 'intimate_social',
              lineageRef: 'wake:ble_encounter',
            ),
            personalAgentId: 'agent-local',
          );
        }
        if (reason == BackgroundWakeReason.trustedAnnounceRefresh) {
          await ambientService.applyObservation(
            observation: _ambientObservation(
              source: AmbientSocialLearningObservationSource
                  .ai2aiCompletedInteraction,
              discoveredPeerIds: const <String>['peer-a', 'peer-b'],
              confirmedInteractivePeerIds: const <String>['peer-a'],
              socialContext: 'small_group',
              placeVibeLabel: 'intimate_social',
              lineageRef: 'wake:trusted_announce_refresh',
            ),
            personalAgentId: 'agent-local',
          );
        }
        await runRecordStore.record(
          BackgroundWakeExecutionRunRecord(
            reason: reason,
            platformSource:
                platformSource ?? 'simulated_smoke:test:${reason.wireName}',
            wakeTimestampUtc: now,
            startedAtUtc: now,
            completedAtUtc: now.add(const Duration(seconds: 1)),
            bootstrapSuccess: true,
            meshDueReplayCount: 1,
            meshRecoveredReplayCount:
                reason == BackgroundWakeReason.trustedAnnounceRefresh ? 1 : 0,
            meshDiscoveredPeerCount: 2,
            ai2aiReleasedCount:
                reason == BackgroundWakeReason.backgroundTaskWindow ? 1 : 0,
            ai2aiBlockedCount: 0,
            ai2aiTrustedRouteUnavailableBlockCount: 0,
            passiveIngestedDwellEventCount:
                reason == BackgroundWakeReason.bleEncounter ? 1 : 0,
            ambientCandidateObservationDeltaCount:
                reason == BackgroundWakeReason.bleEncounter ? 1 : 0,
            ambientConfirmedPromotionDeltaCount:
                reason == BackgroundWakeReason.trustedAnnounceRefresh ? 1 : 0,
            segmentRefreshCount:
                reason == BackgroundWakeReason.backgroundTaskWindow ? 1 : 0,
          ),
        );
        return HeadlessBackgroundRuntimeExecutionResult(
          capabilitySnapshot: BackgroundCapabilitySnapshot(
            observedAtUtc: now,
            wakeReason: reason,
            privacyMode: MeshTransportPrivacyMode.privateMesh,
            isWifiAvailable: isWifiAvailable ?? false,
            isIdle: isIdle ?? false,
            reticulumTransportControlPlaneEnabled: true,
            trustedMeshAnnounceEnforcementEnabled: true,
          ),
          meshResult: MeshBackgroundExecutionResult(
            dueReplayCount: 1,
            recoveredReachabilityReplayCount:
                reason == BackgroundWakeReason.trustedAnnounceRefresh ? 1 : 0,
            discoveredPeerCount: 2,
          ),
          ai2aiResult: Ai2AiBackgroundExecutionResult(
            releasedCount:
                reason == BackgroundWakeReason.backgroundTaskWindow ? 1 : 0,
            blockedCount: 0,
            trustedRouteUnavailableBlockCount: 0,
          ),
          passiveResult: PassiveKernelSignalIntakeResult(
            ingestedDwellEventCount:
                reason == BackgroundWakeReason.bleEncounter ? 1 : 0,
          ),
          segmentRefreshCount:
              reason == BackgroundWakeReason.backgroundTaskWindow ? 1 : 0,
          bootstrapReady: true,
        );
      },
      runFieldAcceptanceValidationOverride: () async {
        sequence.add('validation');
        final proofs = _requiredScenarios
            .map(
              (scenario) => _proof(
                scenario: scenario,
                summary: 'proof-${scenario.name}',
              ),
            )
            .toList(growable: false);
        for (final proof in proofs) {
          await proofStore.record(proof);
        }
        return proofs;
      },
      nowUtc: () => now,
    );

    await ambientService.applyObservation(
      observation: _ambientObservation(
        source: AmbientSocialLearningObservationSource.passiveDwell,
        discoveredPeerIds: const <String>['seed-peer'],
        confirmedInteractivePeerIds: const <String>[],
        socialContext: 'dyad',
        placeVibeLabel: 'intimate_social',
        lineageRef: 'seed:baseline',
      ),
      personalAgentId: 'agent-local',
    );
    final baselineAmbient = ambientService.snapshot(capturedAtUtc: now);

    final result = await automationService.runSimulatedHeadlessSmoke(
      const SimulatedHeadlessSmokeRequest(platformMode: 'ios'),
    );

    expect(result.success, isTrue);
    expect(
      sequence,
      <String>[
        'encounter:simulated_headless_smoke_v1:debug_simulated_smoke_user',
        'start_headless',
        'wake:ble_encounter',
        'wake:trusted_announce_refresh',
        'wake:significant_location',
        'wake:background_task_window',
        'validation',
      ],
    );
    expect(result.simulatedNodeIds, const <String>['node-sim-1']);
    expect(
      result.executedWakeReasons,
      SimulatedHeadlessSmokeRequest.defaultWakeReasons
          .map((entry) => entry.wireName)
          .toList(growable: false),
    );
    expect(result.backgroundWakeRunCount, 4);
    expect(result.fieldValidationProofCount, _requiredScenarios.length);
    expect(result.ambientCandidateCount, greaterThanOrEqualTo(1));
    expect(result.ambientConfirmedCount, greaterThanOrEqualTo(1));
    final ambientAfter = ambientService.snapshot(capturedAtUtc: now);
    expect(
      result.ambientCandidateCount,
      ambientAfter.candidateCoPresenceObservationCount -
          baselineAmbient.candidateCoPresenceObservationCount,
    );
    expect(
      result.ambientConfirmedCount,
      ambientAfter.confirmedInteractionPromotionCount -
          baselineAmbient.confirmedInteractionPromotionCount,
    );
    expect(
      result.ambientDuplicateMergeCount,
      ambientAfter.duplicateMergeCount - baselineAmbient.duplicateMergeCount,
    );
    expect(
      result.ambientRejectedPromotionCount,
      ambientAfter.rejectedInteractionPromotionCount -
          baselineAmbient.rejectedInteractionPromotionCount,
    );

    final exportDir = Directory(result.exportDirectoryPath);
    expect(exportDir.existsSync(), isTrue);
    expect(File('${exportDir.path}/ledger_rows.csv').existsSync(), isTrue);
    expect(File('${exportDir.path}/ledger_rows.jsonl').existsSync(), isTrue);
    expect(
      File('${exportDir.path}/background_wake_runs.json').existsSync(),
      isTrue,
    );
    expect(
      File('${exportDir.path}/field_validation_proofs.json').existsSync(),
      isTrue,
    );
    expect(
      File('${exportDir.path}/ambient_social_diagnostics.json').existsSync(),
      isTrue,
    );

    final backgroundRuns = jsonDecode(
      File('${exportDir.path}/background_wake_runs.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final wakeReasons = (backgroundRuns['runs'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((entry) => entry['reason'] as String)
        .toSet();
    expect(
      wakeReasons,
      containsAll(
        SimulatedHeadlessSmokeRequest.defaultWakeReasons
            .map((entry) => entry.wireName),
      ),
    );

    final fieldProofs = jsonDecode(
      File('${exportDir.path}/field_validation_proofs.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scenarioNames = (fieldProofs['proofs'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((entry) => entry['scenario'] as String)
        .toSet();
    expect(
      scenarioNames,
      containsAll(_requiredScenarios.map((entry) => entry.name)),
    );

    final ambientDiagnostics = jsonDecode(
      File('${exportDir.path}/ambient_social_diagnostics.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(
      ambientDiagnostics['candidate_copresence_observation_count'],
      greaterThanOrEqualTo(1),
    );
    expect(
      ambientDiagnostics['confirmed_interaction_promotion_count'],
      greaterThanOrEqualTo(1),
    );
    expect(ambientDiagnostics['last_promotion_trace'], isNotNull);
  });

  test('records and exports manual event-planning beta smoke milestones',
      () async {
    MockGetStorage.reset();

    final defaultStorage = MockGetStorage.getInstance(boxName: 'spots_default');
    final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
    final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
    final analyticsStorage =
        MockGetStorage.getInstance(boxName: 'spots_analytics');

    await defaultStorage.erase();
    await userStorage.erase();
    await aiStorage.erase();
    await analyticsStorage.erase();

    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );

    final prefs = await SharedPreferencesCompat.getInstance(
      storage: defaultStorage,
    );
    final now = DateTime.utc(2026, 3, 14, 9, 30);
    final proofRunService = ProofRunServiceV0(
      ledger: LedgerRecorderServiceV0(
        supabaseService: SupabaseService(),
        agentIdService: AgentIdService(
          supabaseService: SupabaseService(),
        ),
        storage: StorageService.instance,
      ),
      supabase: SupabaseService(),
      prefs: prefs,
    );
    final automationService = ProofRunAutomationService(
      proofRunService: proofRunService,
      prefs: prefs,
      storageService: StorageService.instance,
      supabaseService: SupabaseService(),
      nowUtc: () => now,
    );

    final runId = await automationService.startEventPlanningBetaSmoke(
      platformMode: 'ios',
      userId: 'host-event-planner',
    );
    expect(runId, isNotEmpty);
    expect(proofRunService.getActiveRunId(), runId);

    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.eventTruthEntered,
      payload: const <String, Object?>{'step': 'truth'},
    );
    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.airGapCrossed,
    );
    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.suggestionShown,
    );
    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.publishCompleted,
    );
    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.safetyChecklistOpened,
    );
    await automationService.recordEventPlanningBetaSmokeMilestone(
      runId: runId,
      milestone: EventPlanningBetaSmokeMilestone.debriefCompleted,
    );

    final exportPath =
        await automationService.finishAndExportEventPlanningBetaSmoke(
      runId: runId,
      platformMode: 'ios',
    );
    expect(proofRunService.getActiveRunId(), isNull);

    final exportDir = Directory(exportPath);
    expect(exportDir.existsSync(), isTrue);

    final jsonlFile = File('${exportDir.path}/ledger_rows.jsonl');
    expect(jsonlFile.existsSync(), isTrue);
    final jsonl = jsonlFile.readAsStringSync();
    expect(jsonl,
        contains(ProofRunAutomationService.eventPlanningBetaSmokeScenarioName));
    expect(jsonl, contains('proof_event_planning_smoke_started'));
    expect(jsonl, contains('proof_event_planning_event_truth_entered'));
    expect(jsonl, contains('proof_event_planning_air_gap_crossed'));
    expect(jsonl, contains('proof_event_planning_suggestion_shown'));
    expect(jsonl, contains('proof_event_planning_publish_completed'));
    expect(jsonl, contains('proof_event_planning_safety_checklist_opened'));
    expect(jsonl, contains('proof_event_planning_debrief_completed'));
  });
}

const List<DomainExecutionFieldScenario> _requiredScenarios =
    <DomainExecutionFieldScenario>[
  DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
  DomainExecutionFieldScenario.untrustedAnnounceRejected,
  DomainExecutionFieldScenario
      .deferredRendezvousBlockedByTrustedRouteUnavailable,
  DomainExecutionFieldScenario.trustedHeardForwardRoutable,
  DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
  DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
  DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
  DomainExecutionFieldScenario
      .ambientTrustedInteractionPromotesConfirmedPresence,
  DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
  DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
];

AmbientSocialLearningObservation _ambientObservation({
  required AmbientSocialLearningObservationSource source,
  required List<String> discoveredPeerIds,
  required List<String> confirmedInteractivePeerIds,
  required String socialContext,
  required String placeVibeLabel,
  required String lineageRef,
}) {
  return AmbientSocialLearningObservation(
    source: source,
    observedAtUtc: DateTime.utc(2026, 3, 14, 9),
    localityBinding: GeographicVibeBinding(
      localityRef: VibeSubjectRef.locality('bham-downtown'),
      stableKey: 'bham-downtown',
      scope: 'locality',
      metadata: <String, dynamic>{
        'social_context': socialContext,
        'place_vibe_label': placeVibeLabel,
      },
    ),
    discoveredPeerIds: discoveredPeerIds,
    confirmedInteractivePeerIds: confirmedInteractivePeerIds,
    confidence: 0.82,
    interactionQuality: confirmedInteractivePeerIds.isEmpty ? null : 0.88,
    structuredSignals: <String, dynamic>{
      'socialContext': socialContext,
      'placeVibeLabel': placeVibeLabel,
    },
    lineageRef: lineageRef,
  );
}

DomainExecutionFieldScenarioProof _proof({
  required DomainExecutionFieldScenario scenario,
  required String summary,
}) {
  final capturedAtUtc = DateTime.utc(2026, 3, 14, 9);
  return DomainExecutionFieldScenarioProof(
    scenario: scenario,
    passed: true,
    summary: summary,
    privacyMode: MeshTransportPrivacyMode.privateMesh,
    routeReceipts: <TransportRouteReceipt>[
      TransportRouteReceiptCompatibilityTranslator.buildFieldValidation(
        receiptId: 'receipt-${scenario.name}',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        status: 'queued',
        recordedAtUtc: capturedAtUtc,
        routeId: 'route-${scenario.name}',
        peerId: 'peer-1',
        peerNodeId: 'node-1',
        hopCount: 1,
      ),
    ],
    meshHealth: const MeshKernelHealthSnapshot(
      kernelId: 'mesh-kernel',
      status: MeshHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      summary: 'healthy',
    ),
    ai2aiHealth: const Ai2AiKernelHealthSnapshot(
      kernelId: 'ai2ai-kernel',
      status: Ai2AiHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      summary: 'healthy',
    ),
    conformanceReport: DomainExecutionConformanceReport(
      checkedAtUtc: capturedAtUtc,
      runtimeReady: true,
      fieldPilotReady: true,
      rolloutFlagEnabled: true,
      signalRequiredSatisfied: true,
      encryptionType: EncryptionType.signalProtocol,
      reports: const <DomainExecutionKernelHealthReport>[],
    ),
    meshRuntimeStateFrame: MeshRuntimeStateFrame(
      capturedAtUtc: capturedAtUtc,
      routeDestinationCount: 1,
      routeEntryCount: 1,
      interfaceEnabledCounts: const <String, int>{'ble': 1},
      interfaceTotalCounts: const <String, int>{'ble': 1},
      activeAnnounceCount: 1,
      trustedActiveAnnounceCount: 1,
      expiredAnnounceCount: 0,
      rejectedAnnounceCount: 0,
      pendingCustodyCount: 0,
      dueCustodyCount: 0,
      encryptedAtRest: true,
      announceTriggeredReplayCount: 0,
      announceRefreshReplayCount: 0,
      interfaceRecoveredReplayCount: 0,
      trustedReplayTriggerCount: 1,
      trustedReplayTriggerSourceCounts: const <String, int>{'ble_encounter': 1},
      rejectionReasonCounts: const <String, int>{},
      queuedPayloadKindCounts: const <String, int>{},
      activeAnnounceSourceCounts: const <String, int>{'direct_discovery': 1},
      rejectedAnnounceSourceCounts: const <String, int>{},
      activeCredentialCount: 1,
      expiringSoonCredentialCount: 0,
      revokedCredentialCount: 0,
      destinations: const <MeshRuntimeDestinationState>[],
    ),
    ai2aiRuntimeStateFrame: Ai2AiRuntimeStateFrame(
      capturedAtUtc: capturedAtUtc,
      recentEventCount: 0,
      activeConnectionCount: 0,
      distinctConnectionCount: 0,
      distinctRemoteNodeCount: 0,
      routingAttemptCount: 0,
      custodyAcceptedCount: 0,
      deliverySuccessCount: 0,
      deliveryFailureCount: 0,
      readConfirmedCount: 0,
      learningAppliedCount: 0,
      learningBufferedCount: 0,
      peerReceivedCount: 0,
      peerValidatedCount: 0,
      peerConsumedCount: 0,
      peerAppliedCount: 0,
      encryptionFailureCount: 0,
      anomalyCount: 0,
      eventTypeCounts: const <String, int>{},
      peers: const <Ai2AiRuntimePeerState>[],
    ),
  );
}
