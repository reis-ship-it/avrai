import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/native_backed_ai2ai_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/dart_mesh_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/mesh/native_backed_mesh_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainExecutionFieldScenarioRunner', () {
    test(
        'produces deterministic proof bundles for all required field scenarios',
        () async {
      const baseScenarios = <DomainExecutionFieldScenario>[
        DomainExecutionFieldScenario.directNearbyDeliveryWithReadReceipt,
        DomainExecutionFieldScenario.custodyQueuedPeerReturns,
        DomainExecutionFieldScenario.hybridCloudFallback,
        DomainExecutionFieldScenario.privateMeshRejectsCloudRescue,
        DomainExecutionFieldScenario.threeDeviceRelaySelection,
        DomainExecutionFieldScenario.learningAppliedAfterGovernedIntake,
      ];
      const trustScenarios = <DomainExecutionFieldScenario>[
        DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
        DomainExecutionFieldScenario.trustedCloudAnnounceAccepted,
        DomainExecutionFieldScenario.untrustedAnnounceRejected,
        DomainExecutionFieldScenario
            .deferredRendezvousBlockedByTrustedRouteUnavailable,
        DomainExecutionFieldScenario.trustedHeardForwardRoutable,
        DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
        DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
      ];
      const ambientScenarios = <DomainExecutionFieldScenario>[
        DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
        DomainExecutionFieldScenario
            .ambientTrustedInteractionPromotesConfirmedPresence,
        DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
        DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
      ];

      for (final scenario in baseScenarios) {
        final proof = await _FieldHarness().runner.run(scenario);

        expect(proof.passed, isTrue, reason: scenario.name);
        expect(proof.routeReceipts, isNotEmpty, reason: scenario.name);
        expect(proof.meshHealth.nativeBacked, isTrue, reason: scenario.name);
        expect(proof.ai2aiHealth.nativeBacked, isTrue, reason: scenario.name);
        expect(proof.conformanceReport.runtimeReady, isTrue,
            reason: scenario.name);
        expect(proof.conformanceReport.fieldPilotReady, isTrue,
            reason: scenario.name);
      }

      for (final scenario in trustScenarios) {
        final proof = await _TrustedFieldHarness().runner.run(scenario);

        expect(proof.passed, isTrue, reason: scenario.name);
        expect(proof.routeReceipts, isNotEmpty, reason: scenario.name);
        expect(proof.meshHealth.nativeBacked, isTrue, reason: scenario.name);
        expect(proof.ai2aiHealth.nativeBacked, isTrue, reason: scenario.name);
        expect(proof.conformanceReport.runtimeReady, isTrue,
            reason: scenario.name);
        expect(proof.conformanceReport.fieldPilotReady, isTrue,
            reason: scenario.name);
      }

      for (final scenario in ambientScenarios) {
        final proof = await _TrustedFieldHarness().runner.run(scenario);

        expect(proof.passed, isTrue, reason: scenario.name);
        expect(proof.routeReceipts, isNotEmpty, reason: scenario.name);
        expect(
          (proof.diagnostics['ambient_social_diagnostics'] as Map?)?[
              'what_ingestion_count'],
          isNotNull,
          reason: scenario.name,
        );
      }
    });

    test('serializes proof bundles with mesh and AI2AI state frames', () async {
      final proof = await _TrustedFieldHarness().runner.run(
            DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
          );
      final json = proof.toJson();

      expect(json['scenario'], 'trustedDirectAnnounceRecovery');
      expect(
          (json['mesh_runtime_state_frame'] as Map)['destinations'], isNotNull);
      expect((json['ai2ai_runtime_state_frame'] as Map)['peers'], isNotNull);
      expect(
        (json['diagnostics'] as Map)['mesh_trusted_active_announce_count'],
        isNotNull,
      );
    });
  });
}

class _FieldHarness {
  _FieldHarness() {
    final now = DateTime.utc(2026, 3, 12, 18);
    final routeLedger = MeshRouteLedger(
      store: InMemoryMeshRuntimeStateStore(),
      nowUtc: () => now,
    );
    final custodyOutbox = MeshCustodyOutbox(
      store: InMemoryMeshRuntimeStateStore(),
      nowUtc: () => now,
      defaultRetryBackoff: const Duration(seconds: 10),
    );
    final announceLedger = MeshAnnounceLedger(
      store: InMemoryMeshRuntimeStateStore(),
      nowUtc: () => now,
    );
    final interfaceRegistry =
        MeshInterfaceRegistry(cloudInterfaceAvailable: true);
    final refreshService = MeshSegmentCredentialRefreshService(
      nowUtc: () => now,
    );
    final networkActivityMonitor = NetworkActivityMonitor();
    final meshKernel = NativeBackedMeshKernel(
      nativeBridge: _MeshPilotBridge(),
      fallback: DartMeshRuntimeKernel(
        routeLedger: routeLedger,
        custodyOutbox: custodyOutbox,
        announceLedger: announceLedger,
        interfaceRegistry: interfaceRegistry,
        nowUtc: () => now,
      ),
    );
    final ai2aiKernel = NativeBackedAi2AiKernel(
      nativeBridge: _Ai2AiPilotBridge(),
      fallback: DartAi2AiRuntimeKernel(
        networkActivityMonitor: networkActivityMonitor,
        nowUtc: () => now,
      ),
    );
    final conformanceService = DefaultDomainExecutionConformanceService(
      meshKernel: meshKernel,
      ai2aiKernel: ai2aiKernel,
      encryptionService: const _SignalEncryptionService(),
      featureFlagService: _AlwaysEnabledFeatureFlagService(),
    );
    runner = DomainExecutionFieldScenarioRunner(
      meshKernel: meshKernel,
      ai2aiKernel: ai2aiKernel,
      conformanceService: conformanceService,
      routeLedger: routeLedger,
      custodyOutbox: custodyOutbox,
      announceLedger: announceLedger,
      interfaceRegistry: interfaceRegistry,
      meshRuntimeStateFrameService: const MeshRuntimeStateFrameService(),
      ai2aiRuntimeStateFrameService: const Ai2AiRuntimeStateFrameService(),
      networkActivityMonitor: networkActivityMonitor,
      meshCredentialRefreshService: refreshService,
      nowUtc: () => now,
    );
  }

  late final DomainExecutionFieldScenarioRunner runner;
}

class _TrustedFieldHarness {
  _TrustedFieldHarness() {
    final now = DateTime.now().toUtc();
    final signatureRepository = _FakeSignatureRepository();
    final routeLedger = MeshRouteLedger(
      store: InMemoryMeshRuntimeStateStore(),
      nowUtc: () => now,
    );
    final custodyOutbox = MeshCustodyOutbox(
      store: InMemoryMeshRuntimeStateStore(),
      nowUtc: () => now,
      defaultRetryBackoff: const Duration(seconds: 10),
    );
    final announceLedger = MeshAnnounceLedger(
      store: InMemoryMeshRuntimeStateStore(),
      announceValidator: MeshAnnounceValidator(
        signatureRepository: signatureRepository,
      ),
      nowUtc: () => now,
    );
    final interfaceRegistry =
        MeshInterfaceRegistry(cloudInterfaceAvailable: true);
    final refreshService = MeshSegmentCredentialRefreshService(
      nowUtc: () => now,
    );
    final networkActivityMonitor = NetworkActivityMonitor();
    final rendezvousStore = Ai2AiRendezvousStore();
    final meshKernel = NativeBackedMeshKernel(
      nativeBridge: _MeshPilotBridge(),
      fallback: DartMeshRuntimeKernel(
        routeLedger: routeLedger,
        custodyOutbox: custodyOutbox,
        announceLedger: announceLedger,
        interfaceRegistry: interfaceRegistry,
        nowUtc: () => now,
      ),
    );
    final ai2aiKernel = NativeBackedAi2AiKernel(
      nativeBridge: _Ai2AiPilotBridge(),
      fallback: DartAi2AiRuntimeKernel(
        networkActivityMonitor: networkActivityMonitor,
        rendezvousStore: rendezvousStore,
        nowUtc: () => now,
      ),
    );
    final submissionLane = Ai2AiExchangeSubmissionLane(
      ai2aiKernel: ai2aiKernel,
      transportAdapter: const _NoopLegacyAi2AiExchangeTransportAdapter(),
      nowUtc: () => now,
    );
    final rendezvousScheduler = Ai2AiRendezvousScheduler(
      store: rendezvousStore,
      submissionLane: submissionLane,
      releasePolicy: const Ai2AiRendezvousReleasePolicy(),
      hasTrustedRoute: (peerId) async => announceLedger
          .activeRecords(destinationId: peerId)
          .any((record) => record.attestationId != null),
      nowUtc: () => now,
    );
    final conformanceService = DefaultDomainExecutionConformanceService(
      meshKernel: meshKernel,
      ai2aiKernel: ai2aiKernel,
      encryptionService: const _SignalEncryptionService(),
      featureFlagService: _AlwaysEnabledFeatureFlagService(),
    );
    final ambientSocialService = AmbientSocialRealityLearningService(
      whatIngestion: _FakeWhatRuntimeIngestionService(),
      nowUtc: () => now,
    );
    runner = DomainExecutionFieldScenarioRunner(
      meshKernel: meshKernel,
      ai2aiKernel: ai2aiKernel,
      conformanceService: conformanceService,
      routeLedger: routeLedger,
      custodyOutbox: custodyOutbox,
      announceLedger: announceLedger,
      interfaceRegistry: interfaceRegistry,
      meshRuntimeStateFrameService: const MeshRuntimeStateFrameService(),
      ai2aiRuntimeStateFrameService: const Ai2AiRuntimeStateFrameService(),
      networkActivityMonitor: networkActivityMonitor,
      discovery: _FakeDiscoveryService(
        <String, DiscoveredDevice>{
          'peer-c': _device('peer-c'),
          'peer-trusted': _device('peer-trusted'),
          'peer-untrusted': _device('peer-untrusted'),
          'relay-heard': _device('relay-heard'),
          'relay-refresh': _device('relay-refresh'),
          'peer-rendezvous-release': _device('peer-rendezvous-release'),
        },
      ),
      segmentProfileResolver: const MeshSegmentProfileResolver(),
      segmentCredentialFactory: MeshSegmentCredentialFactory(
        signatureRepository: signatureRepository,
      ),
      announceAttestationFactory: MeshAnnounceAttestationFactory(
        signatureRepository: signatureRepository,
      ),
      meshCredentialRefreshService: refreshService,
      ambientSocialRealityLearningService: ambientSocialService,
      ai2aiExchangeSubmissionLane: submissionLane,
      ai2aiRendezvousScheduler: rendezvousScheduler,
      trustedAnnounceEnforcementEnabled: true,
      nowUtc: () => now,
    );
  }

  late final DomainExecutionFieldScenarioRunner runner;
}

class _MeshPilotBridge implements MeshNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    if (syscall == 'diagnose_mesh_kernel') {
      return const <String, dynamic>{
        'handled': true,
        'payload': <String, dynamic>{
          'route_receipt_truth_present': true,
          'snapshot_supported': true,
          'replay_supported': true,
          'plaintext_fallback_violation_count': 0,
        },
      };
    }
    return const <String, dynamic>{'handled': false};
  }
}

class _Ai2AiPilotBridge implements Ai2AiNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    if (syscall == 'diagnose_ai2ai_kernel') {
      return const <String, dynamic>{
        'handled': true,
        'payload': <String, dynamic>{
          'delivery_truth_present': true,
          'learning_truth_present': true,
          'snapshot_supported': true,
          'replay_supported': true,
        },
      };
    }
    return const <String, dynamic>{'handled': false};
  }
}

class _SignalEncryptionService implements MessageEncryptionService {
  const _SignalEncryptionService();

  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) {
    throw UnimplementedError();
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) {
    throw UnimplementedError();
  }
}

class _AlwaysEnabledFeatureFlagService extends FeatureFlagService {
  _AlwaysEnabledFeatureFlagService() : super(storage: StorageService.instance);

  @override
  Future<bool> isEnabled(
    String featureName, {
    String? userId,
    bool defaultValue = false,
  }) async {
    return true;
  }
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices);

  final Map<String, DiscoveredDevice> _devices;

  @override
  DiscoveredDevice? getDevice(String deviceId) => _devices[deviceId];
}

class _FakeSignatureRepository extends SignatureRepository {
  @override
  EntitySignature? get({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
    return EntitySignature(
      signatureId: 'sig-$entityId',
      entityId: entityId,
      entityKind: entityKind,
      dna: const <String, double>{'trust': 0.9},
      pheromones: const <String, double>{'fresh': 0.9},
      confidence: 0.95,
      freshness: 0.95,
      updatedAt: DateTime.utc(2026, 3, 12, 17),
      summary: 'Trusted signature for field validation.',
    );
  }
}

class _NoopLegacyAi2AiExchangeTransportAdapter
    implements LegacyAi2AiExchangeTransportAdapter {
  const _NoopLegacyAi2AiExchangeTransportAdapter();

  @override
  Future<void> dispatchExchange({
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required Map<String, dynamic> payload,
    String? legacyMessageTypeName,
  }) async {}
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  @override
  Future<String?> currentAgentId() async => 'local-agent';

  @override
  Future<WhatUpdateReceipt?> ingestAmbientSocialObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async {
    return WhatUpdateReceipt(
      state: WhatState(
        entityRef: entityRef,
        canonicalType: 'third_place',
        subtypes: const <String>[],
        aliases: const <String>[],
        placeType: 'third_place',
        activityTypes: activityContext == null
            ? const <String>[]
            : <String>[activityContext],
        socialContexts:
            socialContext == null ? const <String>[] : <String>[socialContext],
        affordanceVector: const <String, double>{},
        vibeSignature: const <String, double>{},
        confidence: confidence,
        evidenceCount: 1,
        firstObservedAtUtc: observedAtUtc,
        lastObservedAtUtc: observedAtUtc,
        sourceMix: const WhatSourceMix(structured: 1.0),
        lineageRefs:
            lineageRef == null ? const <String>[] : <String>[lineageRef],
      ),
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestEventAttendanceObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestListInteractionObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.57,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestPassiveDwellObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.58,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestPluginSemanticObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.6,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestVisitObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.62,
    String? lineageRef,
  }) async => null;
}

DiscoveredDevice _device(String deviceId) {
  return DiscoveredDevice(
    deviceId: deviceId,
    deviceName: deviceId,
    type: DeviceType.bluetooth,
    isSpotsEnabled: true,
    signalStrength: -44,
    discoveredAt: DateTime.now().toUtc(),
    metadata: <String, dynamic>{'node_id': '$deviceId-node'},
  );
}
