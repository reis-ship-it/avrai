import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/native_backed_ai2ai_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/dart_mesh_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/mesh/native_backed_mesh_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kernel-Backed Routing Integration', () {
    test('proves direct delivery, custody replay, and relay routing', () async {
      final harness = _FieldHarness();

      final directProof = await harness.runner.run(
        DomainExecutionFieldScenario.directNearbyDeliveryWithReadReceipt,
      );
      final custodyProof = await harness.runner.run(
        DomainExecutionFieldScenario.custodyQueuedPeerReturns,
      );
      final relayProof = await harness.runner.run(
        DomainExecutionFieldScenario.threeDeviceRelaySelection,
      );

      expect(directProof.passed, isTrue);
      expect(directProof.routeReceipts.last.readAtUtc, isNotNull);
      expect(custodyProof.passed, isTrue);
      expect(custodyProof.meshRuntimeStateFrame.announceTriggeredReplayCount,
          greaterThan(0));
      expect(relayProof.passed, isTrue);
      expect(relayProof.routeReceipts.single.hopCount, 2);
      expect(
          relayProof
              .routeReceipts.single.metadata['mesh_route_resolution_mode'],
          'announce');
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
