import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_producer_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_network/avra_network.dart';

enum DomainExecutionFieldScenario {
  directNearbyDeliveryWithReadReceipt,
  custodyQueuedPeerReturns,
  hybridCloudFallback,
  privateMeshRejectsCloudRescue,
  threeDeviceRelaySelection,
  learningAppliedAfterGovernedIntake,
  trustedDirectAnnounceRecovery,
  trustedCloudAnnounceAccepted,
  untrustedAnnounceRejected,
  deferredRendezvousBlockedByTrustedRouteUnavailable,
  trustedHeardForwardRoutable,
  trustedRelayRefreshRoutable,
  deferredExchangePeerTruthAfterRelease,
  ambientPassiveNearbyCandidateOnly,
  ambientTrustedInteractionPromotesConfirmedPresence,
  ambientDuplicateEvidenceMerged,
  ambientUntrustedInteractionNotPromoted,
}

class DomainExecutionFieldScenarioProof {
  const DomainExecutionFieldScenarioProof({
    required this.scenario,
    required this.passed,
    required this.summary,
    required this.privacyMode,
    required this.routeReceipts,
    required this.meshHealth,
    required this.ai2aiHealth,
    required this.conformanceReport,
    required this.meshRuntimeStateFrame,
    required this.ai2aiRuntimeStateFrame,
    this.diagnostics = const <String, dynamic>{},
  });

  final DomainExecutionFieldScenario scenario;
  final bool passed;
  final String summary;
  final String privacyMode;
  final List<TransportRouteReceipt> routeReceipts;
  final MeshKernelHealthSnapshot meshHealth;
  final Ai2AiKernelHealthSnapshot ai2aiHealth;
  final DomainExecutionConformanceReport conformanceReport;
  final MeshRuntimeStateFrame meshRuntimeStateFrame;
  final Ai2AiRuntimeStateFrame ai2aiRuntimeStateFrame;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scenario': scenario.name,
        'passed': passed,
        'summary': summary,
        'privacy_mode': privacyMode,
        'route_receipts': routeReceipts.map((entry) => entry.toJson()).toList(),
        'mesh_health': <String, dynamic>{
          'kernel_id': meshHealth.kernelId,
          'status': meshHealth.status.name,
          'native_backed': meshHealth.nativeBacked,
          'headless_ready': meshHealth.headlessReady,
          'summary': meshHealth.summary,
          'diagnostics': meshHealth.diagnostics,
        },
        'ai2ai_health': <String, dynamic>{
          'kernel_id': ai2aiHealth.kernelId,
          'status': ai2aiHealth.status.name,
          'native_backed': ai2aiHealth.nativeBacked,
          'headless_ready': ai2aiHealth.headlessReady,
          'summary': ai2aiHealth.summary,
          'diagnostics': ai2aiHealth.diagnostics,
        },
        'conformance_report': conformanceReport.toJson(),
        'mesh_runtime_state_frame': meshRuntimeStateFrame.toJson(),
        'ai2ai_runtime_state_frame': ai2aiRuntimeStateFrame.toJson(),
        'diagnostics': diagnostics,
      };

  factory DomainExecutionFieldScenarioProof.fromJson(
    Map<String, dynamic> json,
  ) {
    return DomainExecutionFieldScenarioProof(
      scenario: DomainExecutionFieldScenario.values.byName(
        json['scenario'] as String? ??
            DomainExecutionFieldScenario
                .directNearbyDeliveryWithReadReceipt.name,
      ),
      passed: json['passed'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      privacyMode: json['privacy_mode'] as String? ??
          MeshTransportPrivacyMode.privateMesh,
      routeReceipts: (json['route_receipts'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (entry) => TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(growable: false),
      meshHealth: MeshKernelHealthSnapshot.fromJson(
        Map<String, dynamic>.from(
          json['mesh_health'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      ai2aiHealth: Ai2AiKernelHealthSnapshot.fromJson(
        Map<String, dynamic>.from(
          json['ai2ai_health'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      conformanceReport: DomainExecutionConformanceReport.fromJson(
        Map<String, dynamic>.from(
          json['conformance_report'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      meshRuntimeStateFrame: MeshRuntimeStateFrame.fromJson(
        Map<String, dynamic>.from(
          json['mesh_runtime_state_frame'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      ai2aiRuntimeStateFrame: Ai2AiRuntimeStateFrame.fromJson(
        Map<String, dynamic>.from(
          json['ai2ai_runtime_state_frame'] as Map? ??
              const <String, dynamic>{},
        ),
      ),
      diagnostics: Map<String, dynamic>.from(
        json['diagnostics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class DomainExecutionFieldScenarioRunner {
  DomainExecutionFieldScenarioRunner({
    required MeshKernelContract meshKernel,
    required Ai2AiKernelContract ai2aiKernel,
    required DomainExecutionConformanceService conformanceService,
    required MeshRouteLedger routeLedger,
    required MeshCustodyOutbox custodyOutbox,
    required MeshAnnounceLedger announceLedger,
    required MeshInterfaceRegistry interfaceRegistry,
    required MeshRuntimeStateFrameService meshRuntimeStateFrameService,
    required Ai2AiRuntimeStateFrameService ai2aiRuntimeStateFrameService,
    required NetworkActivityMonitor networkActivityMonitor,
    DeviceDiscoveryService? discovery,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    MeshSegmentCredentialRefreshService? meshCredentialRefreshService,
    MeshSegmentRevocationStore? meshRevocationStore,
    AmbientSocialRealityLearningService? ambientSocialRealityLearningService,
    Ai2AiExchangeSubmissionLane? ai2aiExchangeSubmissionLane,
    Ai2AiRendezvousScheduler? ai2aiRendezvousScheduler,
    DomainExecutionFieldScenarioProofStore? proofStore,
    bool trustedAnnounceEnforcementEnabled = false,
    DateTime Function()? nowUtc,
  })  : _meshKernel = meshKernel,
        _ai2aiKernel = ai2aiKernel,
        _conformanceService = conformanceService,
        _routeLedger = routeLedger,
        _custodyOutbox = custodyOutbox,
        _announceLedger = announceLedger,
        _interfaceRegistry = interfaceRegistry,
        _meshRuntimeStateFrameService = meshRuntimeStateFrameService,
        _ai2aiRuntimeStateFrameService = ai2aiRuntimeStateFrameService,
        _networkActivityMonitor = networkActivityMonitor,
        _discovery = discovery,
        _segmentProfileResolver = segmentProfileResolver,
        _segmentCredentialFactory = segmentCredentialFactory,
        _announceAttestationFactory = announceAttestationFactory,
        _meshCredentialRefreshService = meshCredentialRefreshService,
        _meshRevocationStore = meshRevocationStore,
        _ambientSocialRealityLearningService =
            ambientSocialRealityLearningService,
        _ai2aiExchangeSubmissionLane = ai2aiExchangeSubmissionLane,
        _ai2aiRendezvousScheduler = ai2aiRendezvousScheduler,
        _proofStore = proofStore,
        _trustedAnnounceEnforcementEnabled = trustedAnnounceEnforcementEnabled,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final MeshKernelContract _meshKernel;
  final Ai2AiKernelContract _ai2aiKernel;
  final DomainExecutionConformanceService _conformanceService;
  final MeshRouteLedger _routeLedger;
  final MeshCustodyOutbox _custodyOutbox;
  final MeshAnnounceLedger _announceLedger;
  final MeshInterfaceRegistry _interfaceRegistry;
  final MeshRuntimeStateFrameService _meshRuntimeStateFrameService;
  final Ai2AiRuntimeStateFrameService _ai2aiRuntimeStateFrameService;
  final NetworkActivityMonitor _networkActivityMonitor;
  final DeviceDiscoveryService? _discovery;
  final MeshSegmentProfileResolver? _segmentProfileResolver;
  final MeshSegmentCredentialFactory? _segmentCredentialFactory;
  final MeshAnnounceAttestationFactory? _announceAttestationFactory;
  final MeshSegmentCredentialRefreshService? _meshCredentialRefreshService;
  final MeshSegmentRevocationStore? _meshRevocationStore;
  final AmbientSocialRealityLearningService?
      _ambientSocialRealityLearningService;
  final Ai2AiExchangeSubmissionLane? _ai2aiExchangeSubmissionLane;
  final Ai2AiRendezvousScheduler? _ai2aiRendezvousScheduler;
  final DomainExecutionFieldScenarioProofStore? _proofStore;
  final bool _trustedAnnounceEnforcementEnabled;
  final DateTime Function() _nowUtc;

  Future<DomainExecutionFieldScenarioProof> run(
    DomainExecutionFieldScenario scenario,
  ) async {
    late final DomainExecutionFieldScenarioProof proof;
    switch (scenario) {
      case DomainExecutionFieldScenario.directNearbyDeliveryWithReadReceipt:
        proof = await _runDirectNearbyDeliveryWithReadReceipt();
        break;
      case DomainExecutionFieldScenario.custodyQueuedPeerReturns:
        proof = await _runCustodyQueuedPeerReturns();
        break;
      case DomainExecutionFieldScenario.hybridCloudFallback:
        proof = await _runHybridCloudFallback();
        break;
      case DomainExecutionFieldScenario.privateMeshRejectsCloudRescue:
        proof = await _runPrivateMeshRejectsCloudRescue();
        break;
      case DomainExecutionFieldScenario.threeDeviceRelaySelection:
        proof = await _runThreeDeviceRelaySelection();
        break;
      case DomainExecutionFieldScenario.learningAppliedAfterGovernedIntake:
        proof = await _runLearningAppliedAfterGovernedIntake();
        break;
      case DomainExecutionFieldScenario.trustedDirectAnnounceRecovery:
        proof = await _runTrustedDirectAnnounceRecovery();
        break;
      case DomainExecutionFieldScenario.trustedCloudAnnounceAccepted:
        proof = await _runTrustedCloudAnnounceAccepted();
        break;
      case DomainExecutionFieldScenario.untrustedAnnounceRejected:
        proof = await _runUntrustedAnnounceRejected();
        break;
      case DomainExecutionFieldScenario
            .deferredRendezvousBlockedByTrustedRouteUnavailable:
        proof = await _runDeferredRendezvousBlockedByTrustedRouteUnavailable();
        break;
      case DomainExecutionFieldScenario.trustedHeardForwardRoutable:
        proof = await _runTrustedHeardForwardRoutable();
        break;
      case DomainExecutionFieldScenario.trustedRelayRefreshRoutable:
        proof = await _runTrustedRelayRefreshRoutable();
        break;
      case DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease:
        proof = await _runDeferredExchangePeerTruthAfterRelease();
        break;
      case DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly:
        proof = await _runAmbientPassiveNearbyCandidateOnly();
        break;
      case DomainExecutionFieldScenario
            .ambientTrustedInteractionPromotesConfirmedPresence:
        proof = await _runAmbientTrustedInteractionPromotesConfirmedPresence();
        break;
      case DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged:
        proof = await _runAmbientDuplicateEvidenceMerged();
        break;
      case DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted:
        proof = await _runAmbientUntrustedInteractionNotPromoted();
        break;
    }
    await _proofStore?.record(proof);
    return proof;
  }

  Future<DomainExecutionFieldScenarioProof>
      _runDirectNearbyDeliveryWithReadReceipt() async {
    final now = _nowUtc();
    final receipt = _routeReceipt(
      receiptId: 'field-direct-read',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:peer-b',
      peerId: 'peer-b',
      peerNodeId: 'node-b',
      hopCount: 1,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      readAtUtc: now.add(const Duration(seconds: 2)),
      readBy: 'peer-b',
    );
    await _routeLedger.recordForwardOutcome(
      destinationId: 'peer-b',
      channel: 'mesh_ble_forward',
      payloadKind: 'user_chat',
      attemptedRoutes: receipt.plannedRoutes,
      winningRoute: _winningRouteForReceipt(receipt),
      occurredAtUtc: now,
      geographicScope: 'local',
    );
    await _meshKernel.planTransport(
      _meshPlanningRequest(
        planningId: 'field-direct-read-plan',
        destinationId: 'peer-b',
        routeReceipt: receipt,
      ),
    );
    await _meshKernel.commitTransport(
      MeshTransportCommit(
        attemptId: 'field-direct-read-commit',
        plan: MeshTransportPlan(
          planningId: 'field-direct-read-plan',
          destinationId: 'peer-b',
          plannedAtUtc: now,
          lifecycleState: MeshTransportLifecycleState.transportDelivered,
          allowed: true,
          routeReceipt: receipt,
        ),
        envelope: _envelope(
          eventId: 'field-direct-read-commit',
          entityId: 'field-direct-read',
          routeReceipt: receipt,
        ),
      ),
    );
    await _meshKernel.observeTransport(
      MeshObservation(
        observationId: 'field-direct-read-observation',
        subjectId: 'field-direct-read',
        lifecycleState: MeshLifecycleState.delivered,
        observedAtUtc: now.add(const Duration(seconds: 1)),
        envelope: _envelope(
          eventId: 'field-direct-read-observation',
          entityId: 'field-direct-read',
          routeReceipt: receipt,
        ),
        governanceBundle: _governanceBundle(
          conversationId: 'conversation-peer-b',
          destinationId: 'peer-b',
        ),
        routeReceipt: receipt,
      ),
    );
    await _runAi2AiLifecycle(
      messageId: 'field-direct-read-message',
      conversationId: 'conversation-peer-b',
      peerId: 'peer-b',
      routeReceipt: receipt,
      finalState: Ai2AiExchangeLifecycleState.peerConsumed,
      observationAtUtc: now.add(const Duration(seconds: 2)),
    );
    return _proof(
      scenario:
          DomainExecutionFieldScenario.directNearbyDeliveryWithReadReceipt,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: receipt.readAtUtc != null,
      summary: 'Direct nearby delivery reached read receipt state.',
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runCustodyQueuedPeerReturns() async {
    final now = _nowUtc();
    final queuedReceipt = _routeReceipt(
      receiptId: 'field-custody-replay',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:peer-c',
      peerId: 'peer-c',
      peerNodeId: 'node-c',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
    );
    await _custodyOutbox.enqueue(
      receiptId: queuedReceipt.receiptId,
      destinationId: 'peer-c',
      payloadKind: 'learning_update',
      channel: 'mesh_ble_forward',
      payload: const <String, dynamic>{'kind': 'learning_update'},
      payloadContext: const <String, dynamic>{'scenario': 'custody_replay'},
      sourceRouteReceipt: queuedReceipt,
      geographicScope: 'local',
      nowUtc: now,
    );
    await _meshKernel.planTransport(
      _meshPlanningRequest(
        planningId: 'field-custody-plan',
        destinationId: 'peer-c',
        routeReceipt: queuedReceipt,
      ),
    );
    await _meshKernel.observeTransport(
      MeshObservation(
        observationId: 'field-custody-queued-observation',
        subjectId: 'field-custody',
        lifecycleState: MeshLifecycleState.queued,
        observedAtUtc: now,
        envelope: _envelope(
          eventId: 'field-custody-queued',
          entityId: 'field-custody',
          routeReceipt: queuedReceipt,
        ),
        governanceBundle: _governanceBundle(
          conversationId: 'conversation-peer-c',
          destinationId: 'peer-c',
        ),
        routeReceipt: queuedReceipt,
      ),
    );
    final updates = _discovery == null
        ? <MeshAnnounceUpdateResult>[
            await _announceLedger.observe(
              observation: const MeshAnnounceObservation(
                destinationId: 'peer-c',
                nextHopPeerId: 'peer-c',
                nextHopNodeId: 'node-c',
                interfaceId: 'ble',
                hopCount: 1,
                geographicScope: 'local',
                confidence: 0.91,
                supportsCustody: true,
                sourceType: MeshAnnounceSourceType.directDiscovery,
              ),
              interfaceProfile: _interfaceRegistry.resolveByInterfaceId(
                'ble',
                privacyMode: MeshTransportPrivacyMode.privateMesh,
              ),
              nowUtc: now.add(const Duration(seconds: 5)),
            ),
          ]
        : await _syncReachablePeers(
            reachablePeerIds: const <String>{'peer-c'},
            privacyMode: MeshTransportPrivacyMode.privateMesh,
            observedAtUtc: now.add(const Duration(seconds: 5)),
            attachTrustMaterial: _trustedAnnounceEnforcementEnabled,
          );
    final replayTrigger = updates
        .map((update) => update.triggerReason)
        .whereType<String>()
        .firstWhere(
          (reason) => reason.isNotEmpty,
          orElse: () => 'announce_arrival',
        );
    await _announceLedger.recordReplayTrigger(
      replayTrigger,
      trusted: _trustedAnnounceEnforcementEnabled,
      sourceKey: _trustedAnnounceEnforcementEnabled ? 'direct_discovery' : null,
    );
    await _custodyOutbox
        .markReleased('mesh-custody-${now.microsecondsSinceEpoch}');
    final releasedReceipt = queuedReceipt.copyWith(
      status: 'forwarded',
      releasedAtUtc: now.add(const Duration(seconds: 5)),
      custodyAcceptedAtUtc: now.add(const Duration(seconds: 5)),
      custodyAcceptedBy: 'node-c',
      metadata: <String, dynamic>{
        ...queuedReceipt.metadata,
        'mesh_replay_trigger': replayTrigger,
      },
    );
    await _routeLedger.recordForwardOutcome(
      destinationId: 'peer-c',
      channel: 'mesh_ble_forward',
      payloadKind: 'learning_update',
      attemptedRoutes: releasedReceipt.plannedRoutes,
      winningRoute: _winningRouteForReceipt(releasedReceipt),
      occurredAtUtc: now.add(const Duration(seconds: 5)),
      geographicScope: 'local',
    );
    await _meshKernel.observeTransport(
      MeshObservation(
        observationId: 'field-custody-release-observation',
        subjectId: 'field-custody',
        lifecycleState: MeshLifecycleState.custodyAccepted,
        observedAtUtc: now.add(const Duration(seconds: 5)),
        envelope: _envelope(
          eventId: 'field-custody-release',
          entityId: 'field-custody',
          routeReceipt: releasedReceipt,
        ),
        governanceBundle: _governanceBundle(
          conversationId: 'conversation-peer-c',
          destinationId: 'peer-c',
        ),
        routeReceipt: releasedReceipt,
      ),
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.custodyQueuedPeerReturns,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[queuedReceipt, releasedReceipt],
      passed: _meshRuntimeStateFrameService
              .buildFrame(
                routeLedger: _routeLedger,
                custodyOutbox: _custodyOutbox,
                announceLedger: _announceLedger,
                interfaceRegistry: _interfaceRegistry,
                privacyMode: MeshTransportPrivacyMode.privateMesh,
              )
              .announceTriggeredReplayCount >
          0,
      summary:
          'Deferred custody was released after destination reachability returned.',
      diagnostics: <String, dynamic>{
        'replay_trigger': replayTrigger,
        'trusted_enforcement_enabled': _trustedAnnounceEnforcementEnabled,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof> _runHybridCloudFallback() async {
    final now = _nowUtc();
    await MeshAnnounceProducerLane.seedCloudAvailability(
      announceLedger: _announceLedger,
      destinationIds: const <String>['peer-d'],
      interfaceRegistry: _interfaceRegistry,
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
    );
    final receipt = _routeReceipt(
      receiptId: 'field-cloud-fallback',
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
      status: 'queued',
      routeId: 'cloud:peer-d',
      peerId: 'federated_cloud',
      peerNodeId: 'federated_cloud',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'cloud_custody',
      },
    );
    await _custodyOutbox.enqueue(
      receiptId: receipt.receiptId,
      destinationId: 'peer-d',
      payloadKind: 'user_chat',
      channel: 'mesh_cloud_custody',
      payload: const <String, dynamic>{'kind': 'user_chat'},
      payloadContext: const <String, dynamic>{'scenario': 'cloud_fallback'},
      sourceRouteReceipt: receipt,
      geographicScope: 'global',
      nowUtc: now,
    );
    await _meshKernel.planTransport(
      _meshPlanningRequest(
        planningId: 'field-cloud-plan',
        destinationId: 'peer-d',
        routeReceipt: receipt,
      ),
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.hybridCloudFallback,
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: receipt.metadata['mesh_route_resolution_mode'] == 'cloud_custody',
      summary:
          'Hybrid mode selected governed cloud custody when no local mesh path existed.',
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runPrivateMeshRejectsCloudRescue() async {
    final now = _nowUtc();
    final updates = await MeshAnnounceProducerLane.seedCloudAvailability(
      announceLedger: _announceLedger,
      destinationIds: const <String>['peer-e'],
      interfaceRegistry: _interfaceRegistry,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
    );
    final receipt = _routeReceipt(
      receiptId: 'field-private-mesh-block',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:none',
      peerId: 'peer-e',
      peerNodeId: 'peer-e',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'historical_fallback_none',
      },
    );
    await _meshKernel.planTransport(
      _meshPlanningRequest(
        planningId: 'field-private-block-plan',
        destinationId: 'peer-e',
        routeReceipt: receipt,
      ),
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.privateMeshRejectsCloudRescue,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: updates.isEmpty,
      summary:
          'Private mesh mode refused cloud rescue and kept the payload queued.',
      diagnostics: <String, dynamic>{
        'cloud_updates_count': updates.length,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runThreeDeviceRelaySelection() async {
    final now = _nowUtc();
    await _announceLedger.observe(
      observation: const MeshAnnounceObservation(
        destinationId: 'peer-f',
        nextHopPeerId: 'relay-b',
        nextHopNodeId: 'relay-b-node',
        interfaceId: 'ble',
        hopCount: 2,
        geographicScope: 'local',
        confidence: 0.87,
        supportsCustody: true,
        sourceType: MeshAnnounceSourceType.heardForward,
      ),
      interfaceProfile: _interfaceRegistry.resolveByInterfaceId(
        'ble',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      ),
      nowUtc: now,
    );
    final receipt = _routeReceipt(
      receiptId: 'field-relay-selection',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:relay-b',
      peerId: 'relay-b',
      peerNodeId: 'relay-b-node',
      hopCount: 2,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'announce',
      },
    );
    await _routeLedger.recordForwardOutcome(
      destinationId: 'peer-f',
      channel: 'mesh_ble_forward',
      payloadKind: 'user_chat',
      attemptedRoutes: receipt.plannedRoutes,
      winningRoute: _winningRouteForReceipt(receipt),
      occurredAtUtc: now,
      geographicScope: 'local',
    );
    await _meshKernel.observeTransport(
      MeshObservation(
        observationId: 'field-relay-selection-observation',
        subjectId: 'field-relay-selection',
        lifecycleState: MeshLifecycleState.delivered,
        observedAtUtc: now.add(const Duration(seconds: 1)),
        envelope: _envelope(
          eventId: 'field-relay-selection-observation',
          entityId: 'field-relay-selection',
          routeReceipt: receipt,
        ),
        governanceBundle: _governanceBundle(
          conversationId: 'conversation-peer-f',
          destinationId: 'peer-f',
        ),
        routeReceipt: receipt,
      ),
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.threeDeviceRelaySelection,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: receipt.hopCount == 2 &&
          receipt.metadata['mesh_route_resolution_mode'] == 'announce',
      summary:
          'Relay path proof recorded a two-hop announce-selected delivery.',
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runLearningAppliedAfterGovernedIntake() async {
    final now = _nowUtc();
    final receipt = _routeReceipt(
      receiptId: 'field-learning-applied',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:peer-g',
      peerId: 'peer-g',
      peerNodeId: 'node-g',
      hopCount: 1,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      learningAppliedAtUtc: now.add(const Duration(seconds: 2)),
      learningAppliedBy: 'local-user',
    );
    await _runAi2AiLifecycle(
      messageId: 'field-learning-message',
      conversationId: 'conversation-peer-g',
      peerId: 'peer-g',
      routeReceipt: receipt,
      finalState: Ai2AiExchangeLifecycleState.peerApplied,
      observationAtUtc: now.add(const Duration(seconds: 2)),
    );
    final frame = _ai2aiRuntimeStateFrameService.buildFrameFromMonitor(
      _networkActivityMonitor,
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.learningAppliedAfterGovernedIntake,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: frame.learningAppliedCount > 0 && frame.deliverySuccessCount > 0,
      summary:
          'Learning proof was only emitted after the governed AI2AI lifecycle reached learning_applied.',
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runTrustedDirectAnnounceRecovery() async {
    _requireDiscovery();
    final now = _nowUtc();
    final queuedReceipt = _routeReceipt(
      receiptId: 'field-trusted-direct-recovery',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:peer-trusted',
      peerId: 'peer-trusted',
      peerNodeId: 'peer-trusted-node',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
    );
    final queuedEntry = await _custodyOutbox.enqueue(
      receiptId: queuedReceipt.receiptId,
      destinationId: 'peer-trusted',
      payloadKind: 'learning_update',
      channel: 'mesh_ble_forward',
      payload: const <String, dynamic>{'kind': 'learning_update'},
      payloadContext: const <String, dynamic>{
        'scenario': 'trusted_direct_announce_recovery',
      },
      sourceRouteReceipt: queuedReceipt,
      geographicScope: 'local',
      nowUtc: now,
    );
    final updates = await _syncReachablePeers(
      reachablePeerIds: const <String>{'peer-trusted'},
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      observedAtUtc: now.add(const Duration(seconds: 5)),
      attachTrustMaterial: true,
    );
    final acceptedUpdate = _firstAcceptedUpdateOrNull(updates);
    if (acceptedUpdate == null) {
      return _proof(
        scenario: DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        routeReceipts: <TransportRouteReceipt>[queuedReceipt],
        passed: false,
        summary:
            'Trusted direct announce recovery did not produce an accepted announce update.',
        diagnostics: <String, dynamic>{
          'updates_count': updates.length,
          'trusted_enforcement_enabled': true,
        },
      );
    }
    final replayTrigger = acceptedUpdate.triggerReason ?? 'announce_arrival';
    await _announceLedger.recordReplayTrigger(
      replayTrigger,
      trusted: true,
      sourceKey: 'direct_discovery',
    );
    await _custodyOutbox.markReleased(queuedEntry.entryId);
    final releasedReceipt = queuedReceipt.copyWith(
      status: 'forwarded',
      releasedAtUtc: now.add(const Duration(seconds: 5)),
      custodyAcceptedAtUtc: now.add(const Duration(seconds: 5)),
      custodyAcceptedBy: acceptedUpdate.record.nextHopNodeId,
      metadata: <String, dynamic>{
        ...queuedReceipt.metadata,
        'mesh_replay_trigger': replayTrigger,
        'mesh_attestation_id': acceptedUpdate.record.attestationId,
      },
    );
    await _routeLedger.recordForwardOutcome(
      destinationId: 'peer-trusted',
      channel: 'mesh_ble_forward',
      payloadKind: 'learning_update',
      attemptedRoutes: releasedReceipt.plannedRoutes,
      winningRoute: _winningRouteForReceipt(releasedReceipt),
      occurredAtUtc: now.add(const Duration(seconds: 5)),
      geographicScope: 'local',
    );
    await _meshKernel.observeTransport(
      MeshObservation(
        observationId: 'field-trusted-direct-recovery',
        subjectId: 'field-trusted-direct-recovery',
        lifecycleState: MeshLifecycleState.custodyAccepted,
        observedAtUtc: now.add(const Duration(seconds: 5)),
        envelope: _envelope(
          eventId: 'field-trusted-direct-recovery',
          entityId: 'field-trusted-direct-recovery',
          routeReceipt: releasedReceipt,
        ),
        governanceBundle: _governanceBundle(
          conversationId: 'conversation-peer-trusted',
          destinationId: 'peer-trusted',
        ),
        routeReceipt: releasedReceipt,
      ),
    );
    final frame = _meshRuntimeStateFrameService.buildFrame(
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      announceLedger: _announceLedger,
      interfaceRegistry: _interfaceRegistry,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[queuedReceipt, releasedReceipt],
      passed: acceptedUpdate.record.attestationId != null &&
          frame.trustedActiveAnnounceCount > 0 &&
          frame.trustedReplayTriggerCount > 0,
      summary:
          'Trusted direct discovery announce recovered the route and released deferred custody.',
      diagnostics: <String, dynamic>{
        'accepted': acceptedUpdate.accepted,
        'replay_trigger': replayTrigger,
        'attestation_id': acceptedUpdate.record.attestationId,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runTrustedCloudAnnounceAccepted() async {
    final now = _nowUtc();
    final updates = await _seedCloudAvailability(
      destinationIds: const <String>{'peer-trusted-cloud'},
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
      observedAtUtc: now,
      attachTrustMaterial: true,
    );
    final acceptedUpdate = _firstAcceptedUpdateOrNull(updates);
    if (acceptedUpdate == null) {
      return _proof(
        scenario: DomainExecutionFieldScenario.trustedCloudAnnounceAccepted,
        privacyMode: MeshTransportPrivacyMode.federatedCloud,
        routeReceipts: const <TransportRouteReceipt>[],
        passed: false,
        summary:
            'Trusted cloud announce did not produce an accepted update during simulated validation.',
        diagnostics: <String, dynamic>{
          'updates_count': updates.length,
        },
      );
    }
    final receipt = _routeReceipt(
      receiptId: 'field-trusted-cloud-accept',
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
      status: 'queued',
      routeId: 'cloud:peer-trusted-cloud',
      peerId: 'federated_cloud',
      peerNodeId: 'federated_cloud',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'cloud_custody',
      },
    );
    final frame = _meshRuntimeStateFrameService.buildFrame(
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      announceLedger: _announceLedger,
      interfaceRegistry: _interfaceRegistry,
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.trustedCloudAnnounceAccepted,
      privacyMode: MeshTransportPrivacyMode.federatedCloud,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: acceptedUpdate.record.attestationId != null &&
          acceptedUpdate.record.attestationAccepted &&
          frame.trustedActiveAnnounceCount > 0,
      summary:
          'Trusted cloud availability announce became an eligible federated-cloud route.',
      diagnostics: <String, dynamic>{
        'accepted': acceptedUpdate.accepted,
        'attestation_id': acceptedUpdate.record.attestationId,
        'next_hop_peer_id': acceptedUpdate.record.nextHopPeerId,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runUntrustedAnnounceRejected() async {
    _requireDiscovery();
    final now = _nowUtc();
    final updates = await _syncReachablePeers(
      reachablePeerIds: const <String>{'peer-untrusted'},
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      observedAtUtc: now,
      attachTrustMaterial: false,
    );
    final rejectedUpdate = _firstRejectedUpdateOrNull(updates);
    if (rejectedUpdate == null) {
      return _proof(
        scenario: DomainExecutionFieldScenario.untrustedAnnounceRejected,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        routeReceipts: const <TransportRouteReceipt>[],
        passed: false,
        summary:
            'Untrusted announce scenario did not produce a rejected update during simulated validation.',
        diagnostics: <String, dynamic>{
          'updates_count': updates.length,
        },
      );
    }
    final receipt = _routeReceipt(
      receiptId: 'field-untrusted-announce-rejected',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:none',
      peerId: 'peer-untrusted',
      peerNodeId: 'peer-untrusted-node',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'historical_fallback_none',
      },
    );
    final frame = _meshRuntimeStateFrameService.buildFrame(
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      announceLedger: _announceLedger,
      interfaceRegistry: _interfaceRegistry,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.untrustedAnnounceRejected,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: !rejectedUpdate.accepted &&
          _announceLedger
              .activeRecords(destinationId: 'peer-untrusted')
              .isEmpty &&
          frame.rejectedAnnounceCount > 0,
      summary:
          'Unsigned direct discovery announce was rejected and kept out of the active route set.',
      diagnostics: <String, dynamic>{
        'rejection_reason': rejectedUpdate.rejectionReason,
        'rejection_reason_counts': frame.rejectionReasonCounts,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runDeferredRendezvousBlockedByTrustedRouteUnavailable() async {
    final submissionLane = _requireExchangeSubmissionLane();
    final rendezvousScheduler = _requireRendezvousScheduler();
    final now = _nowUtc();
    final routeReceipt = _routeReceipt(
      receiptId: 'field-trusted-route-blocked',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:none',
      peerId: 'peer-rendezvous-blocked',
      peerNodeId: 'peer-rendezvous-blocked-node',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
    );
    final submission = await submissionLane.submit(
      Ai2AiExchangeSubmissionRequest(
        exchangeId: 'exchange-trusted-route-blocked',
        conversationId: 'conversation-peer-rendezvous-blocked',
        peerId: 'peer-rendezvous-blocked',
        artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
        payload: const <String, dynamic>{'delta': 1},
        decision: Ai2AiExchangeDecision.exchangeWhenWifi,
        rendezvousPolicy: Ai2AiRendezvousPolicy(
          requiredConditions: const <Ai2AiRendezvousCondition>{
            Ai2AiRendezvousCondition.wifi,
          },
          expiresAtUtc: now.add(const Duration(days: 30)),
        ),
        routeReceipt: routeReceipt,
        requiresApplyReceipt: true,
        context: const <String, dynamic>{
          'field_validation': true,
        },
      ),
    );
    await rendezvousScheduler.updateRuntimeState(isWifiAvailable: true);
    return _proof(
      scenario: DomainExecutionFieldScenario
          .deferredRendezvousBlockedByTrustedRouteUnavailable,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[routeReceipt],
      passed: submission.deferred &&
          rendezvousScheduler.trustedRouteUnavailableBlockCount > 0 &&
          rendezvousScheduler.lastBlockedReason == 'trusted_route_unavailable',
      summary:
          'Deferred AI2AI exchange remained blocked until a trusted route became available.',
      diagnostics: <String, dynamic>{
        'submission_deferred': submission.deferred,
        'active_rendezvous_count': rendezvousScheduler.activeRendezvousCount,
        'trusted_route_block_count':
            rendezvousScheduler.trustedRouteUnavailableBlockCount,
        'last_blocked_reason': rendezvousScheduler.lastBlockedReason,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runTrustedHeardForwardRoutable() async {
    _requireDiscovery();
    final now = _nowUtc();
    final interfaceProfile = _interfaceRegistry.resolveByInterfaceId(
      'ble',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
    );
    final update = await MeshAnnounceProducerLane.observeHeardForward(
      announceLedger: _announceLedger,
      interfaceProfile: interfaceProfile,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      destinationId: 'peer-heard-target',
      nextHopPeerId: 'relay-heard',
      nextHopNodeId: 'relay-heard-node',
      geographicScope: 'mesh',
      confidence: 0.84,
      supportsCustody: true,
      hopCount: 2,
      segmentProfileResolver: _segmentProfileResolver,
      segmentCredentialFactory: _segmentCredentialFactory,
      announceAttestationFactory: _announceAttestationFactory,
      credentialRefreshService: _meshCredentialRefreshService,
      observedAtUtc: now,
    );
    await _announceLedger.recordReplayTrigger(
      update.triggerReason ?? 'announce_arrival',
      trusted: true,
      sourceKey: 'heard_forward',
    );
    final selection = await MeshForwardingTargetSelector.selectWithContext(
      context: MeshForwardingContext(
        discovery: _requireDiscovery(),
        routeLedger: _routeLedger,
        custodyOutbox: _custodyOutbox,
        interfaceRegistry: _interfaceRegistry,
        announceLedger: _announceLedger,
        segmentProfileResolver: _segmentProfileResolver,
        segmentCredentialFactory: _segmentCredentialFactory,
        announceAttestationFactory: _announceAttestationFactory,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        reticulumTransportControlPlaneEnabled: true,
        trustedAnnounceEnforcementEnabled: true,
      ),
      discoveredNodeIds: const <String>{'relay-heard'},
      destinationId: 'peer-heard-target',
    );
    final receipt = _routeReceipt(
      receiptId: 'field-trusted-heard-forward',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:relay-heard',
      peerId: 'relay-heard',
      peerNodeId: 'relay-heard-node',
      hopCount: 2,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'announce',
      },
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.trustedHeardForwardRoutable,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: update.accepted &&
          selection.routeResolutionMode == 'announce' &&
          selection.peerIds.contains('relay-heard'),
      summary:
          'Trusted heard-forward announce became active and routable under private-mesh enforcement.',
      diagnostics: <String, dynamic>{
        'selection_peer_ids': selection.peerIds,
        'selection_mode': selection.routeResolutionMode,
        'announce_source': update.record.sourceType.name,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runTrustedRelayRefreshRoutable() async {
    _requireDiscovery();
    final now = _nowUtc();
    final interfaceProfile = _interfaceRegistry.resolveByInterfaceId(
      'ble',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
    );
    final update = await MeshAnnounceProducerLane.observeRelayRefresh(
      announceLedger: _announceLedger,
      interfaceProfile: interfaceProfile,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      destinationId: 'peer-relay-target',
      nextHopPeerId: 'relay-refresh',
      nextHopNodeId: 'relay-refresh-node',
      geographicScope: 'mesh',
      confidence: 0.86,
      supportsCustody: true,
      hopCount: 2,
      segmentProfileResolver: _segmentProfileResolver,
      segmentCredentialFactory: _segmentCredentialFactory,
      announceAttestationFactory: _announceAttestationFactory,
      credentialRefreshService: _meshCredentialRefreshService,
      observedAtUtc: now,
    );
    await _announceLedger.recordReplayTrigger(
      update.triggerReason ?? 'announce_refresh',
      trusted: true,
      sourceKey: 'forward_success',
    );
    final selection = await MeshForwardingTargetSelector.selectWithContext(
      context: MeshForwardingContext(
        discovery: _requireDiscovery(),
        routeLedger: _routeLedger,
        custodyOutbox: _custodyOutbox,
        interfaceRegistry: _interfaceRegistry,
        announceLedger: _announceLedger,
        segmentProfileResolver: _segmentProfileResolver,
        segmentCredentialFactory: _segmentCredentialFactory,
        announceAttestationFactory: _announceAttestationFactory,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        reticulumTransportControlPlaneEnabled: true,
        trustedAnnounceEnforcementEnabled: true,
      ),
      discoveredNodeIds: const <String>{'relay-refresh'},
      destinationId: 'peer-relay-target',
    );
    final receipt = _routeReceipt(
      receiptId: 'field-trusted-relay-refresh',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:relay-refresh',
      peerId: 'relay-refresh',
      peerNodeId: 'relay-refresh-node',
      hopCount: 2,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      metadata: const <String, dynamic>{
        'mesh_route_resolution_mode': 'announce',
      },
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: update.accepted &&
          selection.routeResolutionMode == 'announce' &&
          selection.peerIds.contains('relay-refresh'),
      summary:
          'Trusted relay-refresh announce became active and routable after successful forward evidence.',
      diagnostics: <String, dynamic>{
        'selection_peer_ids': selection.peerIds,
        'selection_mode': selection.routeResolutionMode,
        'announce_source': update.record.sourceType.name,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runDeferredExchangePeerTruthAfterRelease() async {
    final submissionLane = _requireExchangeSubmissionLane();
    final rendezvousScheduler = _requireRendezvousScheduler();
    final now = _nowUtc();
    await _syncReachablePeers(
      reachablePeerIds: const <String>{'peer-rendezvous-release'},
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      observedAtUtc: now,
      attachTrustMaterial: true,
    );
    final routeReceipt = _routeReceipt(
      receiptId: 'field-deferred-peer-truth',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:peer-rendezvous-release',
      peerId: 'peer-rendezvous-release',
      peerNodeId: 'peer-rendezvous-release-node',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
    );
    final submission = await submissionLane.submit(
      Ai2AiExchangeSubmissionRequest(
        exchangeId: 'exchange-peer-truth-after-release',
        conversationId: 'conversation-peer-rendezvous-release',
        peerId: 'peer-rendezvous-release',
        artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
        payload: const <String, dynamic>{'delta': 1},
        decision: Ai2AiExchangeDecision.exchangeWhenWifi,
        rendezvousPolicy: Ai2AiRendezvousPolicy(
          requiredConditions: const <Ai2AiRendezvousCondition>{
            Ai2AiRendezvousCondition.wifi,
          },
          expiresAtUtc: now.add(const Duration(days: 30)),
        ),
        routeReceipt: routeReceipt,
        requiresApplyReceipt: true,
        context: const <String, dynamic>{
          'field_validation': true,
        },
      ),
    );
    final preReleaseFrame =
        _ai2aiRuntimeStateFrameService.buildFrameFromMonitor(
      _networkActivityMonitor,
    );
    await rendezvousScheduler.updateRuntimeState(isWifiAvailable: true);
    final afterReleaseFrame =
        _ai2aiRuntimeStateFrameService.buildFrameFromMonitor(
      _networkActivityMonitor,
    );
    final peerReceipt = routeReceipt.copyWith(
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      readAtUtc: now.add(const Duration(seconds: 2)),
      learningAppliedAtUtc: now.add(const Duration(seconds: 3)),
      readBy: 'peer-rendezvous-release',
      learningAppliedBy: 'peer-rendezvous-release',
    );
    for (final stage in const <Ai2AiExchangeLifecycleState>[
      Ai2AiExchangeLifecycleState.peerReceived,
      Ai2AiExchangeLifecycleState.peerValidated,
      Ai2AiExchangeLifecycleState.peerConsumed,
      Ai2AiExchangeLifecycleState.peerApplied,
    ]) {
      await _ai2aiKernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId:
              'field-peer-truth-${stage.name}-exchange-peer-truth-after-release',
          exchangeId: 'exchange-peer-truth-after-release',
          conversationId: 'conversation-peer-rendezvous-release',
          lifecycleState: stage,
          observedAtUtc: now.add(Duration(seconds: stage.index + 1)),
          envelope: _envelope(
            eventId:
                'field-peer-truth-envelope-${stage.name}-exchange-peer-truth-after-release',
            entityId: 'exchange-peer-truth-after-release',
            routeReceipt: peerReceipt,
          ),
          governanceBundle: _governanceBundle(
            conversationId: 'conversation-peer-rendezvous-release',
            destinationId: 'peer-rendezvous-release',
          ),
          routeReceipt: peerReceipt,
          outcomeContext: <String, dynamic>{
            'exchange_receipt_stage': stage.name,
            'field_validation': true,
          },
        ),
      );
    }
    final finalFrame = _ai2aiRuntimeStateFrameService.buildFrameFromMonitor(
      _networkActivityMonitor,
    );
    return _proof(
      scenario:
          DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[routeReceipt, peerReceipt],
      passed: submission.deferred &&
          rendezvousScheduler.releasedTicketCount > 0 &&
          preReleaseFrame.peerReceivedCount == 0 &&
          afterReleaseFrame.peerReceivedCount == 0 &&
          finalFrame.peerReceivedCount > 0 &&
          finalFrame.peerValidatedCount > 0 &&
          finalFrame.peerConsumedCount > 0 &&
          finalFrame.peerAppliedCount > 0,
      summary:
          'Deferred exchange remained transport-only on release and advanced only after downstream peer observations arrived.',
      diagnostics: <String, dynamic>{
        'released_ticket_count': rendezvousScheduler.releasedTicketCount,
        'pre_release_peer_received_count': preReleaseFrame.peerReceivedCount,
        'after_release_peer_received_count':
            afterReleaseFrame.peerReceivedCount,
        'final_peer_received_count': finalFrame.peerReceivedCount,
        'final_peer_validated_count': finalFrame.peerValidatedCount,
        'final_peer_consumed_count': finalFrame.peerConsumedCount,
        'final_peer_applied_count': finalFrame.peerAppliedCount,
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runAmbientPassiveNearbyCandidateOnly() async {
    final ambientService = _requireAmbientSocialRealityLearningService();
    final now = _nowUtc();
    final dwellEvent = DwellEvent(
      startTime: now.subtract(const Duration(minutes: 42)),
      endTime: now.subtract(const Duration(minutes: 5)),
      latitude: 33.5207,
      longitude: -86.8025,
      encounteredAgentIds: const <String>[
        'peer-candidate-a',
        'peer-candidate-b'
      ],
    );
    final projection = PassiveDwellLearningProjection.fromEvent(dwellEvent);
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation.fromPassiveDwell(
        event: dwellEvent,
        projection: projection,
      ),
      personalAgentId: 'local-agent',
    );
    final snapshot = ambientService.snapshot(capturedAtUtc: now);
    final receipt = _routeReceipt(
      receiptId: 'field-ambient-passive-candidate',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'observed',
      routeId: 'ble:ambient-passive',
      peerId: 'ambient-passive',
      peerNodeId: 'ambient-passive-node',
      hopCount: 1,
      recordedAtUtc: now,
      metadata: const <String, dynamic>{
        'ambient_validation': true,
        'validation_kind': 'candidate_only',
      },
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: snapshot.candidateCoPresenceObservationCount > 0 &&
          snapshot.confirmedInteractionPromotionCount == 0 &&
          snapshot.whatIngestionCount > 0,
      summary:
          'Passive nearby discovery created candidate co-presence evidence without promoting confirmed interaction.',
      diagnostics: <String, dynamic>{
        'ambient_scenario': 'candidate_only',
        ..._ambientDiagnostics(snapshot),
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runAmbientTrustedInteractionPromotesConfirmedPresence() async {
    final ambientService = _requireAmbientSocialRealityLearningService();
    final now = _nowUtc();
    final dwellEvent = DwellEvent(
      startTime: now.subtract(const Duration(minutes: 30)),
      endTime: now.subtract(const Duration(minutes: 8)),
      latitude: 33.5207,
      longitude: -86.8025,
      encounteredAgentIds: const <String>['peer-trusted-a', 'peer-trusted-b'],
    );
    final projection = PassiveDwellLearningProjection.fromEvent(dwellEvent);
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation.fromPassiveDwell(
        event: dwellEvent,
        projection: projection,
      ),
      personalAgentId: 'local-agent',
    );
    final routeReceipt = _routeReceipt(
      receiptId: 'field-ambient-promoted-interaction',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:peer-trusted-a',
      peerId: 'peer-trusted-a',
      peerNodeId: 'peer-trusted-a-node',
      hopCount: 1,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
      readAtUtc: now.add(const Duration(seconds: 2)),
      learningAppliedAtUtc: now.add(const Duration(seconds: 3)),
      readBy: 'peer-trusted-a',
      learningAppliedBy: 'peer-trusted-a',
    );
    await _runAi2AiLifecycle(
      messageId: 'field-ambient-promoted-interaction',
      conversationId: 'conversation-peer-trusted-a',
      peerId: 'peer-trusted-a',
      routeReceipt: routeReceipt,
      finalState: Ai2AiExchangeLifecycleState.peerApplied,
      observationAtUtc: now.add(const Duration(seconds: 3)),
    );
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation(
        source:
            AmbientSocialLearningObservationSource.ai2aiCompletedInteraction,
        observedAtUtc: now.add(const Duration(minutes: 1)),
        localityBinding: projection.localityBinding,
        discoveredPeerIds: const <String>['peer-trusted-a'],
        confirmedInteractivePeerIds: const <String>['peer-trusted-a'],
        confidence: 0.88,
        interactionQuality: 0.84,
        structuredSignals: const <String, dynamic>{
          'interactionTrusted': true,
          'promotionEligible': true,
        },
        lineageRef: 'ambient:ai2ai:peer-trusted-a',
      ),
      personalAgentId: 'local-agent',
    );
    final snapshot = ambientService.snapshot(capturedAtUtc: now);
    return _proof(
      scenario: DomainExecutionFieldScenario
          .ambientTrustedInteractionPromotesConfirmedPresence,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[routeReceipt],
      passed: snapshot.confirmedInteractionPromotionCount > 0 &&
          snapshot.latestConfirmedInteractivePeerCount > 0 &&
          snapshot.lastPromotionTrace != null &&
          snapshot.lastPromotionTrace!.confirmedInteractivePeerIds
              .contains('peer-trusted-a'),
      summary:
          'Completed trusted AI2AI interaction promoted candidate presence into confirmed interactive presence for the same locality window.',
      diagnostics: <String, dynamic>{
        'ambient_scenario': 'trusted_promotion',
        ..._ambientDiagnostics(snapshot),
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runAmbientDuplicateEvidenceMerged() async {
    final ambientService = _requireAmbientSocialRealityLearningService();
    final now = _nowUtc();
    final dwellEvent = DwellEvent(
      startTime: now.subtract(const Duration(minutes: 20)),
      endTime: now.subtract(const Duration(minutes: 4)),
      latitude: 33.5207,
      longitude: -86.8025,
      encounteredAgentIds: const <String>['peer-duplicate-a'],
    );
    final projection = PassiveDwellLearningProjection.fromEvent(dwellEvent);
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation.fromPassiveDwell(
        event: dwellEvent,
        projection: projection,
      ),
      personalAgentId: 'local-agent',
    );
    final promotion = AmbientSocialLearningObservation(
      source: AmbientSocialLearningObservationSource.ai2aiCompletedInteraction,
      observedAtUtc: now.add(const Duration(minutes: 1)),
      localityBinding: projection.localityBinding,
      discoveredPeerIds: const <String>['peer-duplicate-a'],
      confirmedInteractivePeerIds: const <String>['peer-duplicate-a'],
      confidence: 0.83,
      interactionQuality: 0.79,
      structuredSignals: const <String, dynamic>{
        'interactionTrusted': true,
        'promotionEligible': true,
      },
      lineageRef: 'ambient:ai2ai:peer-duplicate-a',
    );
    await ambientService.applyObservation(
      observation: promotion,
      personalAgentId: 'local-agent',
    );
    await ambientService.applyObservation(
      observation: promotion,
      personalAgentId: 'local-agent',
    );
    final snapshot = ambientService.snapshot(capturedAtUtc: now);
    final receipt = _routeReceipt(
      receiptId: 'field-ambient-duplicate-merge',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'forwarded',
      routeId: 'ble:peer-duplicate-a',
      peerId: 'peer-duplicate-a',
      peerNodeId: 'peer-duplicate-a-node',
      hopCount: 1,
      recordedAtUtc: now,
      deliveredAtUtc: now.add(const Duration(seconds: 1)),
    );
    return _proof(
      scenario: DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: snapshot.confirmedInteractionPromotionCount == 1 &&
          snapshot.duplicateMergeCount > 0 &&
          snapshot.latestConfirmedInteractivePeerCount == 1,
      summary:
          'Duplicate passive and AI2AI evidence merged into one locality window without double-counting confirmed interaction.',
      diagnostics: <String, dynamic>{
        'ambient_scenario': 'duplicate_merged',
        ..._ambientDiagnostics(snapshot),
      },
    );
  }

  Future<DomainExecutionFieldScenarioProof>
      _runAmbientUntrustedInteractionNotPromoted() async {
    final ambientService = _requireAmbientSocialRealityLearningService();
    final now = _nowUtc();
    final dwellEvent = DwellEvent(
      startTime: now.subtract(const Duration(minutes: 18)),
      endTime: now.subtract(const Duration(minutes: 3)),
      latitude: 33.5207,
      longitude: -86.8025,
      encounteredAgentIds: const <String>['peer-untrusted-a'],
    );
    final projection = PassiveDwellLearningProjection.fromEvent(dwellEvent);
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation.fromPassiveDwell(
        event: dwellEvent,
        projection: projection,
      ),
      personalAgentId: 'local-agent',
    );
    final before = ambientService.snapshot(capturedAtUtc: now);
    await ambientService.applyObservation(
      observation: AmbientSocialLearningObservation(
        source:
            AmbientSocialLearningObservationSource.ai2aiCompletedInteraction,
        observedAtUtc: now.add(const Duration(minutes: 1)),
        localityBinding: projection.localityBinding,
        discoveredPeerIds: const <String>['peer-untrusted-a'],
        confidence: 0.22,
        structuredSignals: const <String, dynamic>{
          'interactionTrusted': false,
          'promotionEligible': false,
          'rejectionReason': 'trusted_route_unavailable',
        },
        lineageRef: 'ambient:ai2ai:peer-untrusted-a',
      ),
      personalAgentId: 'local-agent',
    );
    final snapshot = ambientService.snapshot(capturedAtUtc: now);
    final receipt = _routeReceipt(
      receiptId: 'field-ambient-untrusted-not-promoted',
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      status: 'queued',
      routeId: 'ble:none',
      peerId: 'peer-untrusted-a',
      peerNodeId: 'peer-untrusted-a-node',
      hopCount: 1,
      recordedAtUtc: now,
      queuedAtUtc: now,
      metadata: const <String, dynamic>{
        'ambient_validation': true,
        'validation_kind': 'untrusted_not_promoted',
      },
    );
    return _proof(
      scenario:
          DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
      privacyMode: MeshTransportPrivacyMode.privateMesh,
      routeReceipts: <TransportRouteReceipt>[receipt],
      passed: snapshot.confirmedInteractionPromotionCount ==
              before.confirmedInteractionPromotionCount &&
          snapshot.rejectedInteractionPromotionCount >
              before.rejectedInteractionPromotionCount &&
          snapshot.whatIngestionCount == before.whatIngestionCount &&
          snapshot.localityVibeUpdateCount == before.localityVibeUpdateCount &&
          snapshot.personalDnaAppliedCount == before.personalDnaAppliedCount,
      summary:
          'Untrusted AI2AI interaction was rejected for promotion and did not create a false confirmed-interaction, place-vibe, or DNA update.',
      diagnostics: <String, dynamic>{
        'ambient_scenario': 'untrusted_not_promoted',
        ..._ambientDiagnostics(snapshot),
      },
    );
  }

  Future<void> _runAi2AiLifecycle({
    required String messageId,
    required String conversationId,
    required String peerId,
    required TransportRouteReceipt routeReceipt,
    required Ai2AiExchangeLifecycleState finalState,
    required DateTime observationAtUtc,
  }) async {
    final candidate = Ai2AiExchangeCandidate(
      exchangeId: messageId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: Ai2AiExchangeArtifactClass.learningDelta,
      envelope: _envelope(
        eventId: '$messageId-envelope',
        entityId: messageId,
        routeReceipt: routeReceipt,
      ),
      governanceBundle: _governanceBundle(
        conversationId: conversationId,
        destinationId: peerId,
      ),
      routeReceipt: routeReceipt,
      requiresApplyReceipt: true,
      context: const <String, dynamic>{
        'field_validation': true,
      },
    );
    final plan = await _ai2aiKernel.planExchange(candidate);
    await _ai2aiKernel.commitExchange(
      Ai2AiExchangeCommit(
        attemptId: '$messageId-commit',
        plan: plan,
        envelope: candidate.envelope,
      ),
    );
    if (finalState.index >= Ai2AiExchangeLifecycleState.peerReceived.index) {
      await _ai2aiKernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: '$messageId-observation-delivered',
          exchangeId: messageId,
          conversationId: conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.peerReceived,
          observedAtUtc: routeReceipt.deliveredAtUtc ?? observationAtUtc,
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: routeReceipt,
        ),
      );
    }
    if (finalState.index >= Ai2AiExchangeLifecycleState.peerConsumed.index) {
      await _ai2aiKernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: '$messageId-observation-read',
          exchangeId: messageId,
          conversationId: conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.peerConsumed,
          observedAtUtc: routeReceipt.readAtUtc ?? observationAtUtc,
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: routeReceipt,
        ),
      );
    }
    if (finalState.index >= Ai2AiExchangeLifecycleState.peerApplied.index) {
      await _ai2aiKernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: '$messageId-observation-learning',
          exchangeId: messageId,
          conversationId: conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.peerApplied,
          observedAtUtc: routeReceipt.learningAppliedAtUtc ?? observationAtUtc,
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: routeReceipt,
        ),
      );
      return;
    }
    await _ai2aiKernel.observeExchange(
      Ai2AiExchangeObservation(
        observationId: '$messageId-observation',
        exchangeId: messageId,
        conversationId: conversationId,
        lifecycleState: finalState,
        observedAtUtc: observationAtUtc,
        envelope: candidate.envelope,
        governanceBundle: candidate.governanceBundle,
        routeReceipt: routeReceipt,
      ),
    );
  }

  MeshRoutePlanningRequest _meshPlanningRequest({
    required String planningId,
    required String destinationId,
    required TransportRouteReceipt routeReceipt,
  }) {
    return MeshRoutePlanningRequest(
      planningId: planningId,
      destinationId: destinationId,
      envelope: _envelope(
        eventId: '$planningId-envelope',
        entityId: planningId,
        routeReceipt: routeReceipt,
      ),
      governanceBundle: _governanceBundle(
        conversationId: 'conversation-$destinationId',
        destinationId: destinationId,
      ),
      routeReceipt: routeReceipt,
      runtimeContext: const <String, dynamic>{
        'field_validation': true,
      },
    );
  }

  KernelEventEnvelope _envelope({
    required String eventId,
    required String entityId,
    required TransportRouteReceipt routeReceipt,
  }) {
    return KernelEventEnvelope(
      eventId: eventId,
      occurredAtUtc: routeReceipt.recordedAtUtc,
      userId: 'local-user',
      agentId: 'local-agent',
      sourceSystem: 'domain_execution_field_runner',
      eventType: 'field_validation',
      actionType: 'validate',
      entityId: entityId,
      entityType: 'field_validation',
      privacyMode: routeReceipt.metadata['privacy_mode']?.toString() ??
          MeshTransportPrivacyMode.privateMesh,
      routeReceipt: routeReceipt,
      policyContext: const <String, dynamic>{
        'governed_runtime_path': true,
        'requires_signal_session': true,
      },
      context: const <String, dynamic>{
        'field_validation': true,
      },
    );
  }

  KernelContextBundle _governanceBundle({
    required String conversationId,
    required String destinationId,
  }) {
    final now = _nowUtc();
    return KernelContextBundle(
      who: WhoKernelSnapshot(
        primaryActor: 'local-agent',
        affectedActor: destinationId,
        companionActors: const <String>[],
        actorRoles: const <String>['peer'],
        trustScope: 'private',
        cohortRefs: const <String>[],
        identityConfidence: 0.92,
      ),
      what: WhatKernelSnapshot(
        actionType: 'deliver',
        targetEntityType: 'message',
        targetEntityId: conversationId,
        stateTransitionType: 'planned_to_observed',
        outcomeType: 'field_validation',
        semanticTags: const <String>['mesh', 'ai2ai'],
        taxonomyConfidence: 0.87,
      ),
      when: WhenKernelSnapshot(
        observedAt: now,
        freshness: 0.94,
        recencyBucket: 'hot',
        timingConflictFlags: const <String>[],
        temporalConfidence: 0.91,
      ),
      where: const WhereKernelSnapshot(
        localityToken: 'where:bham:field',
        cityCode: 'bham',
        localityCode: 'field',
        projection: <String, dynamic>{'mode': 'local'},
        boundaryTension: 0.08,
        spatialConfidence: 0.86,
        travelFriction: 0.18,
        placeFitFlags: <String>['proximate'],
      ),
      how: const HowKernelSnapshot(
        executionPath: 'domain_execution_field_runner',
        workflowStage: 'validation',
        transportMode: 'mesh',
        plannerMode: 'governed',
        modelFamily: 'signal_reticulum',
        interventionChain: <String>['plan', 'commit', 'observe'],
        failureMechanism: 'none',
        mechanismConfidence: 0.9,
      ),
      vibe: null,
      vibeStack: null,
      why: WhyKernelSnapshot(
        goal: 'validate_field_execution',
        summary: 'Field validation proof bundle generation.',
        rootCauseType: WhyRootCauseType.mechanism,
        confidence: 0.84,
        drivers: const <WhySignal>[
          WhySignal(label: 'field_validation', weight: 1.0),
        ],
        inhibitors: const <WhySignal>[],
        counterfactuals: const <WhyCounterfactual>[],
        createdAtUtc: now,
      ),
    );
  }

  TransportRouteReceipt _routeReceipt({
    required String receiptId,
    required String privacyMode,
    required String status,
    required String routeId,
    required String peerId,
    required String peerNodeId,
    required int hopCount,
    required DateTime recordedAtUtc,
    DateTime? queuedAtUtc,
    DateTime? deliveredAtUtc,
    DateTime? readAtUtc,
    String? readBy,
    DateTime? learningAppliedAtUtc,
    String? learningAppliedBy,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return TransportRouteReceiptCompatibilityTranslator.buildFieldValidation(
      receiptId: receiptId,
      privacyMode: privacyMode,
      status: status,
      recordedAtUtc: recordedAtUtc,
      routeId: routeId,
      peerId: peerId,
      peerNodeId: peerNodeId,
      hopCount: hopCount,
      queuedAtUtc: queuedAtUtc,
      deliveredAtUtc: deliveredAtUtc,
      readAtUtc: readAtUtc,
      readBy: readBy,
      learningAppliedAtUtc: learningAppliedAtUtc,
      learningAppliedBy: learningAppliedBy,
      metadata: metadata,
    );
  }

  MeshAnnounceUpdateResult? _firstAcceptedUpdateOrNull(
    List<MeshAnnounceUpdateResult> updates,
  ) {
    for (final update in updates) {
      if (update.accepted) {
        return update;
      }
    }
    return null;
  }

  MeshAnnounceUpdateResult? _firstRejectedUpdateOrNull(
    List<MeshAnnounceUpdateResult> updates,
  ) {
    for (final update in updates) {
      if (!update.accepted) {
        return update;
      }
    }
    return null;
  }

  TransportRouteCandidate _winningRouteForReceipt(
    TransportRouteReceipt receipt,
  ) {
    if (receipt.winningRoute case final winningRoute?) {
      return winningRoute;
    }
    if (receipt.plannedRoutes.isNotEmpty) {
      return receipt.plannedRoutes.first;
    }
    return TransportRouteCandidate(
      routeId: '${receipt.channel}:field_validation_fallback',
      mode: TransportMode.ble,
      confidence: 0.0,
      estimatedLatencyMs: 0,
      rationale: 'field_validation_fallback',
    );
  }

  Future<DomainExecutionFieldScenarioProof> _proof({
    required DomainExecutionFieldScenario scenario,
    required String privacyMode,
    required List<TransportRouteReceipt> routeReceipts,
    required bool passed,
    required String summary,
    Map<String, dynamic> diagnostics = const <String, dynamic>{},
  }) async {
    final meshHealth = await _meshKernel.diagnoseMesh();
    final ai2aiHealth = await _ai2aiKernel.diagnoseAi2Ai();
    final conformanceReport = await _conformanceService.buildReport();
    final meshRuntimeStateFrame = _meshRuntimeStateFrameService.buildFrame(
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      announceLedger: _announceLedger,
      interfaceRegistry: _interfaceRegistry,
      privacyMode: privacyMode,
      credentialRefreshService: _meshCredentialRefreshService,
      revocationStore: _meshRevocationStore,
    );
    final ai2aiRuntimeStateFrame =
        _ai2aiRuntimeStateFrameService.buildFrameFromMonitor(
      _networkActivityMonitor,
    );
    final rendezvousScheduler = _ai2aiRendezvousScheduler;
    final ambientSocialSnapshot =
        _ambientSocialRealityLearningService?.snapshot(
      capturedAtUtc: _nowUtc(),
    );
    final mergedDiagnostics = <String, dynamic>{
      'trusted_enforcement_enabled': _trustedAnnounceEnforcementEnabled,
      'mesh_trusted_active_announce_count':
          meshRuntimeStateFrame.trustedActiveAnnounceCount,
      'mesh_rejected_announce_count':
          meshRuntimeStateFrame.rejectedAnnounceCount,
      'mesh_rejection_reason_counts':
          meshRuntimeStateFrame.rejectionReasonCounts,
      'mesh_trusted_replay_trigger_count':
          meshRuntimeStateFrame.trustedReplayTriggerCount,
      'mesh_trusted_replay_trigger_source_counts':
          meshRuntimeStateFrame.trustedReplayTriggerSourceCounts,
      'mesh_active_announce_source_counts':
          meshRuntimeStateFrame.activeAnnounceSourceCounts,
      'mesh_rejected_announce_source_counts':
          meshRuntimeStateFrame.rejectedAnnounceSourceCounts,
      if (rendezvousScheduler != null)
        'ai2ai_rendezvous_active_count':
            rendezvousScheduler.activeRendezvousCount,
      if (rendezvousScheduler != null)
        'ai2ai_rendezvous_blocked_count':
            rendezvousScheduler.blockedByConditionCount,
      if (rendezvousScheduler != null)
        'ai2ai_rendezvous_trusted_route_unavailable_block_count':
            rendezvousScheduler.trustedRouteUnavailableBlockCount,
      if (rendezvousScheduler != null)
        'ai2ai_rendezvous_last_blocked_reason':
            rendezvousScheduler.lastBlockedReason,
      'ai2ai_peer_received_count': ai2aiRuntimeStateFrame.peerReceivedCount,
      'ai2ai_peer_validated_count': ai2aiRuntimeStateFrame.peerValidatedCount,
      'ai2ai_peer_consumed_count': ai2aiRuntimeStateFrame.peerConsumedCount,
      'ai2ai_peer_applied_count': ai2aiRuntimeStateFrame.peerAppliedCount,
      if (ambientSocialSnapshot != null)
        'ambient_social_diagnostics': ambientSocialSnapshot.toJson(),
      ...diagnostics,
    };
    return DomainExecutionFieldScenarioProof(
      scenario: scenario,
      passed: passed,
      summary: summary,
      privacyMode: privacyMode,
      routeReceipts: routeReceipts,
      meshHealth: meshHealth,
      ai2aiHealth: ai2aiHealth,
      conformanceReport: conformanceReport,
      meshRuntimeStateFrame: meshRuntimeStateFrame,
      ai2aiRuntimeStateFrame: ai2aiRuntimeStateFrame,
      diagnostics: mergedDiagnostics,
    );
  }

  DeviceDiscoveryService _requireDiscovery() {
    final discovery = _discovery;
    if (discovery == null) {
      throw StateError(
        'DomainExecutionFieldScenarioRunner requires discovery for trust producer validation scenarios.',
      );
    }
    return discovery;
  }

  Ai2AiExchangeSubmissionLane _requireExchangeSubmissionLane() {
    final submissionLane = _ai2aiExchangeSubmissionLane;
    if (submissionLane == null) {
      throw StateError(
        'DomainExecutionFieldScenarioRunner requires an Ai2AiExchangeSubmissionLane for rendezvous trust scenarios.',
      );
    }
    return submissionLane;
  }

  Ai2AiRendezvousScheduler _requireRendezvousScheduler() {
    final rendezvousScheduler = _ai2aiRendezvousScheduler;
    if (rendezvousScheduler == null) {
      throw StateError(
        'DomainExecutionFieldScenarioRunner requires an Ai2AiRendezvousScheduler for rendezvous trust scenarios.',
      );
    }
    return rendezvousScheduler;
  }

  AmbientSocialRealityLearningService
      _requireAmbientSocialRealityLearningService() {
    final ambientService = _ambientSocialRealityLearningService;
    if (ambientService == null) {
      throw StateError(
        'DomainExecutionFieldScenarioRunner requires AmbientSocialRealityLearningService for ambient validation scenarios.',
      );
    }
    return ambientService;
  }

  Map<String, dynamic> _ambientDiagnostics(
    AmbientSocialLearningDiagnosticsSnapshot snapshot,
  ) {
    return <String, dynamic>{
      'ambient_snapshot': snapshot.toJson(),
    };
  }

  Future<List<MeshAnnounceUpdateResult>> _syncReachablePeers({
    required Iterable<String> reachablePeerIds,
    required String privacyMode,
    required DateTime observedAtUtc,
    required bool attachTrustMaterial,
  }) {
    return MeshAnnounceProducerLane.syncReachablePeers(
      announceLedger: _announceLedger,
      reachablePeerIds: reachablePeerIds,
      discovery: _requireDiscovery(),
      interfaceRegistry: _interfaceRegistry,
      privacyMode: privacyMode,
      segmentProfileResolver:
          attachTrustMaterial ? _segmentProfileResolver : null,
      segmentCredentialFactory:
          attachTrustMaterial ? _segmentCredentialFactory : null,
      announceAttestationFactory:
          attachTrustMaterial ? _announceAttestationFactory : null,
      credentialRefreshService: _meshCredentialRefreshService,
      routeLedger: _routeLedger,
      observedAtUtc: observedAtUtc,
    );
  }

  Future<List<MeshAnnounceUpdateResult>> _seedCloudAvailability({
    required Iterable<String> destinationIds,
    required String privacyMode,
    required DateTime observedAtUtc,
    required bool attachTrustMaterial,
  }) {
    return MeshAnnounceProducerLane.seedCloudAvailability(
      announceLedger: _announceLedger,
      destinationIds: destinationIds,
      interfaceRegistry: _interfaceRegistry,
      privacyMode: privacyMode,
      segmentProfileResolver:
          attachTrustMaterial ? _segmentProfileResolver : null,
      segmentCredentialFactory:
          attachTrustMaterial ? _segmentCredentialFactory : null,
      announceAttestationFactory:
          attachTrustMaterial ? _announceAttestationFactory : null,
      credentialRefreshService: _meshCredentialRefreshService,
      observedAtUtc: observedAtUtc,
    );
  }
}
