// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/background/ai2ai_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/background/headless_background_runtime_coordinator.dart';
import 'package:avrai_runtime_os/services/background/mesh_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/passive_kernel_signal_intake_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/services/background/background_platform_wake_bridge.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_lifecycle_runtime_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeadlessBackgroundRuntimeCoordinator', () {
    test('starts the background envelope and routes a boot wake', () async {
      final transportAdapter = _RecordingLegacyAi2AiExchangeTransportAdapter();

      var passiveStartCount = 0;
      final segmentLifecycleLane = MeshSegmentLifecycleRuntimeLane(
        refreshService: MeshSegmentCredentialRefreshService(),
        refreshInterval: const Duration(hours: 1),
      );
      final coordinator = HeadlessBackgroundRuntimeCoordinator(
        bootstrapService: HeadlessAvraiOsBootstrapService(
          host: _FakeHeadlessHost(),
        ),
        meshLane: MeshBackgroundExecutionLane(
          discovery: _FakeDiscoveryService(
            <DiscoveredDevice>[
              DiscoveredDevice(
                deviceId: 'peer-boot',
                deviceName: 'Peer Boot',
                type: DeviceType.bluetooth,
                isSpotsEnabled: true,
                discoveredAt: DateTime.utc(2026, 3, 13, 12),
                metadata: <String, dynamic>{'node_id': 'node-boot'},
              ),
            ],
          ),
          packetCodec: GovernedMeshPacketCodec(
            encryptionService: AES256GCMEncryptionService(),
          ),
          routeLedger: MeshRouteLedger(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          custodyOutbox: MeshCustodyOutbox(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          interfaceRegistry: MeshInterfaceRegistry(),
          announceLedger: MeshAnnounceLedger(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          replayDueEntries: ({
            required context,
            required discoveredNodeIds,
            required localNodeId,
            required peerNodeIdByDeviceId,
            required logger,
            required logName,
            int maxEntries = 4,
            int maxCandidates = 2,
          }) async =>
              1,
        ),
        ai2aiLane: Ai2AiBackgroundExecutionLane(
          scheduler: Ai2AiRendezvousScheduler(
            store: Ai2AiRendezvousStore(),
            submissionLane: Ai2AiExchangeSubmissionLane(
              ai2aiKernel: DartAi2AiRuntimeKernel(
                rendezvousStore: Ai2AiRendezvousStore(),
              ),
              transportAdapter: transportAdapter,
            ),
            releasePolicy: const Ai2AiRendezvousReleasePolicy(),
          ),
        ),
        passiveLane: PassiveKernelSignalIntakeLane(
          passiveCollectionService: SmartPassiveCollectionService(
            motionService: DeviceMotionService(skipInitForTesting: true),
          ),
          dwellEventIntakeAdapter: DwellEventIntakeAdapter(_NoopAirGap()),
          startCollection: () {
            passiveStartCount += 1;
          },
          flushDwellEvents: () => const <DwellEvent>[],
        ),
        segmentLifecycleLane: segmentLifecycleLane,
      );

      final result = await coordinator.startForegroundRuntimeEnvelope();

      expect(result.bootstrapReady, isTrue);
      expect(result.meshResult.dueReplayCount, 1);
      expect(result.passiveResult.ingestedDwellEventCount, 0);
      expect(passiveStartCount, 1);
      await segmentLifecycleLane.dispose();
    });

    test('drains native queued wake reasons after startup', () async {
      final segmentLifecycleLane = MeshSegmentLifecycleRuntimeLane(
        refreshService: MeshSegmentCredentialRefreshService(),
        refreshInterval: const Duration(hours: 1),
      );
      final platformWakePort = _FakeBackgroundPlatformWakePort(
        <BackgroundWakeInvocationPayload>[
          BackgroundWakeInvocationPayload(
            reason: BackgroundWakeReason.significantLocation,
            platformSource: 'test_significant_location',
            wakeTimestampUtc: DateTime.utc(2026, 3, 13, 12, 30),
          ),
        ],
      );
      final coordinator = HeadlessBackgroundRuntimeCoordinator(
        bootstrapService: HeadlessAvraiOsBootstrapService(
          host: _FakeHeadlessHost(),
        ),
        meshLane: MeshBackgroundExecutionLane(
          discovery: _FakeDiscoveryService(const <DiscoveredDevice>[]),
          packetCodec: GovernedMeshPacketCodec(
            encryptionService: AES256GCMEncryptionService(),
          ),
          routeLedger: MeshRouteLedger(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          custodyOutbox: MeshCustodyOutbox(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          interfaceRegistry: MeshInterfaceRegistry(),
          announceLedger: MeshAnnounceLedger(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          replayDueEntries: ({
            required context,
            required discoveredNodeIds,
            required localNodeId,
            required peerNodeIdByDeviceId,
            required logger,
            required logName,
            int maxEntries = 4,
            int maxCandidates = 2,
          }) async =>
              0,
        ),
        ai2aiLane: Ai2AiBackgroundExecutionLane(
          scheduler: Ai2AiRendezvousScheduler(
            store: Ai2AiRendezvousStore(),
            submissionLane: Ai2AiExchangeSubmissionLane(
              ai2aiKernel: DartAi2AiRuntimeKernel(
                rendezvousStore: Ai2AiRendezvousStore(),
              ),
            ),
            releasePolicy: const Ai2AiRendezvousReleasePolicy(),
          ),
        ),
        passiveLane: PassiveKernelSignalIntakeLane(
          passiveCollectionService: SmartPassiveCollectionService(
            motionService: DeviceMotionService(skipInitForTesting: true),
          ),
          dwellEventIntakeAdapter: DwellEventIntakeAdapter(_NoopAirGap()),
          flushDwellEvents: () => const <DwellEvent>[],
        ),
        segmentLifecycleLane: segmentLifecycleLane,
        platformWakePort: platformWakePort,
      );

      final result = await coordinator.startForegroundRuntimeEnvelope();

      expect(
        result.capabilitySnapshot.wakeReason,
        BackgroundWakeReason.significantLocation,
      );
      expect(platformWakePort.scheduledInterval, const Duration(minutes: 30));
      expect(platformWakePort.notifyCount, 1);
      await segmentLifecycleLane.dispose();
    });

    test('ble encounter wake flushes passive intake into ambient candidate evidence and records the run',
        () async {
      final harness = _AmbientWakeHarness(
        dwellEvents: <DwellEvent>[
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 12, 0),
            endTime: DateTime.utc(2026, 3, 13, 12, 12),
            latitude: 33.5207,
            longitude: -86.8025,
            encounteredAgentIds: const <String>['peer-a', 'peer-b'],
          ),
        ],
      );

      final result = await harness.coordinator.handleWake(
        reason: BackgroundWakeReason.bleEncounter,
        platformSource: 'test_ble_encounter',
      );
      final snapshot = harness.ambientService.snapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 13, 12, 20),
      );
      final run = harness.runRecordStore.recentRecords(limit: 1).single;

      expect(result.bootstrapReady, isTrue);
      expect(result.passiveResult.ingestedDwellEventCount, 1);
      expect(snapshot.candidateCoPresenceObservationCount, 1);
      expect(snapshot.confirmedInteractionPromotionCount, 0);
      expect(run.reason, BackgroundWakeReason.bleEncounter);
      expect(run.platformSource, 'test_ble_encounter');
      expect(run.passiveIngestedDwellEventCount, 1);
      expect(run.ambientCandidateObservationDeltaCount, 1);
      expect(run.ambientConfirmedPromotionDeltaCount, 0);
      await harness.dispose();
    });

    test(
        'trusted announce refresh wake replays mesh reachability and releases deferred rendezvous when trusted route is available',
        () async {
      final harness = _AmbientWakeHarness(
        dueReplayCount: 1,
        recoveredReplayCount: 2,
        hasTrustedRoute: (peerId) async => peerId == 'peer-refresh',
      );
      await harness.seedDeferredWifiRendezvous(peerId: 'peer-refresh');

      final result = await harness.coordinator.handleWake(
        reason: BackgroundWakeReason.trustedAnnounceRefresh,
        isWifiAvailable: true,
        platformSource: 'test_trusted_refresh',
      );
      final run = harness.runRecordStore.recentRecords(limit: 1).single;

      expect(result.meshResult.dueReplayCount, 1);
      expect(result.meshResult.recoveredReachabilityReplayCount, 2);
      expect(result.ai2aiResult.releasedCount, 1);
      expect(harness.transportAdapter.dispatchCount, 1);
      expect(run.reason, BackgroundWakeReason.trustedAnnounceRefresh);
      expect(run.meshRecoveredReplayCount, 2);
      expect(run.ai2aiReleasedCount, 1);
      await harness.dispose();
    });

    test(
        'significant location wake ingests locality-bound passive evidence and updates ambient diagnostics',
        () async {
      final harness = _AmbientWakeHarness(
        dwellEvents: <DwellEvent>[
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 12, 30),
            endTime: DateTime.utc(2026, 3, 13, 12, 45),
            latitude: 33.5001,
            longitude: -86.7999,
            encounteredAgentIds: const <String>['peer-location-a'],
          ),
        ],
      );

      final result = await harness.coordinator.handleWake(
        reason: BackgroundWakeReason.significantLocation,
        platformSource: 'test_significant_location',
      );
      final snapshot = harness.ambientService.snapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 13, 12, 50),
      );
      final run = harness.runRecordStore.recentRecords(limit: 1).single;

      expect(result.passiveResult.ingestedDwellEventCount, 1);
      expect(snapshot.latestLocalityStableKey, isNotNull);
      expect(snapshot.latestNearbyPeerCount, 1);
      expect(run.reason, BackgroundWakeReason.significantLocation);
      expect(run.ambientCandidateObservationDeltaCount, 1);
      await harness.dispose();
    });

    test(
        'background task window wake releases deferred rendezvous, runs segment maintenance, and flushes pending passive intake',
        () async {
      final harness = _AmbientWakeHarness(
        dwellEvents: <DwellEvent>[
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 13, 0),
            endTime: DateTime.utc(2026, 3, 13, 13, 18),
            latitude: 33.5207,
            longitude: -86.8025,
            encounteredAgentIds: const <String>['peer-task-a'],
          ),
        ],
        hasTrustedRoute: (peerId) async => peerId == 'peer-task-a',
        seedExpiringCredential: true,
      );
      await harness.seedDeferredWifiRendezvous(peerId: 'peer-task-a');

      final result = await harness.coordinator.handleWake(
        reason: BackgroundWakeReason.backgroundTaskWindow,
        isWifiAvailable: true,
        platformSource: 'test_background_window',
      );
      final run = harness.runRecordStore.recentRecords(limit: 1).single;

      expect(result.ai2aiResult.releasedCount, 1);
      expect(result.passiveResult.ingestedDwellEventCount, 1);
      expect(harness.segmentLifecycleLane.lastRanAtUtc, isNotNull);
      expect(result.segmentRefreshCount, 1);
      expect(run.reason, BackgroundWakeReason.backgroundTaskWindow);
      expect(run.segmentRefreshCount, 1);
      await harness.dispose();
    });
  });
}

class _RecordingLegacyAi2AiExchangeTransportAdapter
    implements LegacyAi2AiExchangeTransportAdapter {
  int dispatchCount = 0;

  @override
  Future<void> dispatchExchange({
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required Map<String, dynamic> payload,
    String? legacyMessageTypeName,
  }) async {
    dispatchCount += 1;
  }
}

class _AmbientWakeHarness {
  _AmbientWakeHarness({
    this.dwellEvents = const <DwellEvent>[],
    this.dueReplayCount = 0,
    this.recoveredReplayCount = 0,
    this.seedExpiringCredential = false,
    Future<bool> Function(String peerId)? hasTrustedRoute,
  })  : ambientService = AmbientSocialRealityLearningService(
          nowUtc: () => DateTime.utc(2026, 3, 13, 12),
        ),
        runRecordStore = BackgroundWakeExecutionRunRecordStore(
          nowUtc: () => DateTime.utc(2026, 3, 13, 12),
        ),
        transportAdapter = _RecordingLegacyAi2AiExchangeTransportAdapter(),
        segmentRefreshService = MeshSegmentCredentialRefreshService(
          nowUtc: () => DateTime.utc(2026, 3, 13, 12),
        ),
        hasTrustedRoute =
            (hasTrustedRoute ?? ((peerId) async => false)) {
    if (seedExpiringCredential) {
      segmentRefreshService.recordIssued(
        credential: MeshSegmentCredential(
          credentialId: 'cred-1',
          segmentProfileId: 'seg-1',
          principalId: 'agent-local',
          principalKind: SignatureEntityKind.user,
          issuedAtUtc: DateTime.utc(2026, 3, 13, 11),
          expiresAtUtc: DateTime.utc(2026, 3, 13, 12, 20),
        ),
      );
    }
    segmentLifecycleLane = MeshSegmentLifecycleRuntimeLane(
      refreshService: segmentRefreshService,
      refreshThreshold: const Duration(minutes: 30),
      refreshInterval: const Duration(hours: 1),
      nowUtc: () => DateTime.utc(2026, 3, 13, 12, 15),
    );
    _routeLedger = MeshRouteLedger(
      store: InMemoryMeshRuntimeStateStore(),
    );
    _custodyOutbox = MeshCustodyOutbox(
      store: InMemoryMeshRuntimeStateStore(),
    );
    _announceLedger = MeshAnnounceLedger(
      store: InMemoryMeshRuntimeStateStore(),
    );
    _interfaceRegistry = MeshInterfaceRegistry();
    _rendezvousStore = Ai2AiRendezvousStore();
    final ai2aiKernel = DartAi2AiRuntimeKernel(
      rendezvousStore: _rendezvousStore,
    );
    _submissionLane = Ai2AiExchangeSubmissionLane(
      ai2aiKernel: ai2aiKernel,
      transportAdapter: transportAdapter,
    );
    _scheduler = Ai2AiRendezvousScheduler(
      store: _rendezvousStore,
      submissionLane: _submissionLane,
      releasePolicy: const Ai2AiRendezvousReleasePolicy(),
      hasTrustedRoute: this.hasTrustedRoute,
      nowUtc: () => DateTime.utc(2026, 3, 13, 12, 15),
    );
    coordinator = HeadlessBackgroundRuntimeCoordinator(
      bootstrapService: HeadlessAvraiOsBootstrapService(
        host: _FakeHeadlessHost(),
      ),
      meshLane: MeshBackgroundExecutionLane(
        discovery: _FakeDiscoveryService(const <DiscoveredDevice>[]),
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: AES256GCMEncryptionService(),
        ),
        routeLedger: _routeLedger,
        custodyOutbox: _custodyOutbox,
        interfaceRegistry: _interfaceRegistry,
        announceLedger: _announceLedger,
        replayDueEntries: ({
          required context,
          required discoveredNodeIds,
          required localNodeId,
          required peerNodeIdByDeviceId,
          required logger,
          required logName,
          int maxEntries = 4,
          int maxCandidates = 2,
        }) async =>
            dueReplayCount,
        replayRecoveredReachability: ({
          required context,
          required discoveredNodeIds,
          required localNodeId,
          required peerNodeIdByDeviceId,
          required logger,
          required logName,
          int maxEntriesPerDestination = 3,
          int maxEntriesPerCycle = 8,
          int maxCandidates = 2,
        }) async =>
            recoveredReplayCount,
      ),
      ai2aiLane: Ai2AiBackgroundExecutionLane(
        scheduler: _scheduler,
      ),
      passiveLane: PassiveKernelSignalIntakeLane(
        passiveCollectionService: SmartPassiveCollectionService(
          motionService: DeviceMotionService(skipInitForTesting: true),
        ),
        dwellEventIntakeAdapter: DwellEventIntakeAdapter(
          _NoopAirGap(),
          realityLearningService: PassiveDwellRealityLearningService(
            ambientSocialLearningService: ambientService,
          ),
        ),
        flushDwellEvents: () => List<DwellEvent>.from(dwellEvents),
      ),
      segmentLifecycleLane: segmentLifecycleLane,
      featureFlagService: _AlwaysEnabledFeatureFlagService(),
      runRecordStore: runRecordStore,
      ambientSocialLearningService: ambientService,
    );
  }

  final List<DwellEvent> dwellEvents;
  final int dueReplayCount;
  final int recoveredReplayCount;
  final bool seedExpiringCredential;
  final Future<bool> Function(String peerId) hasTrustedRoute;
  final AmbientSocialRealityLearningService ambientService;
  final BackgroundWakeExecutionRunRecordStore runRecordStore;
  final _RecordingLegacyAi2AiExchangeTransportAdapter transportAdapter;
  final MeshSegmentCredentialRefreshService segmentRefreshService;
  late final MeshRouteLedger _routeLedger;
  late final MeshCustodyOutbox _custodyOutbox;
  late final MeshAnnounceLedger _announceLedger;
  late final MeshInterfaceRegistry _interfaceRegistry;
  late final Ai2AiRendezvousStore _rendezvousStore;
  late final Ai2AiExchangeSubmissionLane _submissionLane;
  late final MeshSegmentLifecycleRuntimeLane segmentLifecycleLane;
  late final HeadlessBackgroundRuntimeCoordinator coordinator;
  late final Ai2AiRendezvousScheduler _scheduler;

  Future<void> seedDeferredWifiRendezvous({
    required String peerId,
  }) async {
    final now = DateTime.utc(2026, 3, 13, 12);
    await _scheduler.updateRuntimeState(isWifiAvailable: false, isIdle: false);
    await _submissionLane.submit(
      Ai2AiExchangeSubmissionRequest(
        exchangeId: 'exchange-$peerId',
        conversationId: 'conversation-$peerId',
        peerId: peerId,
        artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
        payload: const <String, dynamic>{'delta': 1},
        decision: Ai2AiExchangeDecision.exchangeWhenWifi,
        rendezvousPolicy: Ai2AiRendezvousPolicy(
          requiredConditions: const <Ai2AiRendezvousCondition>{
            Ai2AiRendezvousCondition.wifi,
          },
          expiresAtUtc: now.add(const Duration(days: 1)),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _scheduler.dispose();
    await segmentLifecycleLane.dispose();
  }
}

class _FakeBackgroundPlatformWakePort implements BackgroundPlatformWakePort {
  _FakeBackgroundPlatformWakePort(this._pendingWakeInvocations);

  final List<BackgroundWakeInvocationPayload> _pendingWakeInvocations;
  Duration? scheduledInterval;
  var notifyCount = 0;
  var headlessCompletionCount = 0;

  @override
  Future<List<BackgroundWakeInvocationPayload>>
      consumePendingWakeInvocations() async =>
          List<BackgroundWakeInvocationPayload>.from(_pendingWakeInvocations);

  @override
  Future<Map<String, dynamic>> getPlatformWakeCapabilities() async =>
      const <String, dynamic>{'supports_boot_restore': true};

  @override
  Future<void> notifyForegroundReady() async {
    notifyCount += 1;
  }

  @override
  Future<void> scheduleBackgroundTaskWindow({
    required Duration interval,
  }) async {
    scheduledInterval = interval;
  }

  @override
  Future<void> cancelBackgroundTaskWindow() async {}

  @override
  Future<void> notifyHeadlessExecutionComplete({
    required bool success,
    int handledInvocationCount = 0,
    String? failureSummary,
  }) async {
    headlessCompletionCount += 1;
  }
}

class _FakeHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async => HeadlessAvraiOsHostState(
        started: true,
        startedAtUtc: DateTime.utc(2026, 3, 13, 12),
        localityContainedInWhere: true,
        summary: 'fake host started',
      );

  @override
  Future<List<KernelHealthReport>> healthCheck() async =>
      const <KernelHealthReport>[
        KernelHealthReport(
          domain: KernelDomain.where,
          status: KernelHealthStatus.healthy,
          nativeBacked: true,
          headlessReady: true,
          authorityLevel: KernelAuthorityLevel.authoritative,
          summary: 'ready',
        ),
      ];

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices)
      : super(platform: _NoopDiscoveryPlatform());

  final List<DiscoveredDevice> _devices;

  @override
  List<DiscoveredDevice> getDiscoveredDevices() =>
      List<DiscoveredDevice>.from(_devices);

  @override
  DiscoveredDevice? getDevice(String deviceId) {
    for (final device in _devices) {
      if (device.deviceId == deviceId) {
        return device;
      }
    }
    return null;
  }
}

class _NoopDiscoveryPlatform implements DeviceDiscoveryPlatform {
  @override
  bool isSupported() => true;

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async =>
      const <String, dynamic>{};

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async =>
      const <DiscoveredDevice>[];
}

class _NoopAirGap implements AirGapContract {
  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async =>
      const <SemanticTuple>[];
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
