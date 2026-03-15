import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultDomainExecutionConformanceService', () {
    test(
        'reports runtime and field pilot readiness when both kernels are ready',
        () async {
      final service = DefaultDomainExecutionConformanceService(
        meshKernel: _StaticMeshKernel(
          const MeshKernelHealthSnapshot(
            kernelId: 'mesh_runtime_governance',
            status: MeshHealthStatus.healthy,
            nativeBacked: true,
            headlessReady: true,
            summary: 'mesh ready',
            diagnostics: <String, dynamic>{
              'route_receipt_truth_present': true,
              'snapshot_supported': true,
              'replay_supported': true,
              'plaintext_fallback_violation_count': 0,
            },
          ),
        ),
        ai2aiKernel: _StaticAi2AiKernel(
          const Ai2AiKernelHealthSnapshot(
            kernelId: 'ai2ai_runtime_governance',
            status: Ai2AiHealthStatus.healthy,
            nativeBacked: true,
            headlessReady: true,
            summary: 'ai2ai ready',
            diagnostics: <String, dynamic>{
              'delivery_truth_present': true,
              'learning_truth_present': true,
              'snapshot_supported': true,
              'replay_supported': true,
            },
          ),
        ),
        encryptionService: _StaticEncryptionService(
          EncryptionType.signalProtocol,
        ),
        featureFlagService: _AlwaysEnabledFeatureFlagService(),
      );

      final report = await service.buildReport();

      expect(report.runtimeReady, isTrue);
      expect(report.fieldPilotReady, isTrue);
      expect(report.violations, isEmpty);
      expect(report.fieldPilotBlockers, isEmpty);
    });

    test(
        'reports blockers when native, rollout, and signal guarantees are missing',
        () async {
      final service = DefaultDomainExecutionConformanceService(
        meshKernel: _StaticMeshKernel(
          const MeshKernelHealthSnapshot(
            kernelId: 'mesh_runtime_governance',
            status: MeshHealthStatus.degraded,
            nativeBacked: false,
            headlessReady: true,
            summary: 'mesh degraded',
            diagnostics: <String, dynamic>{
              'route_receipt_truth_present': false,
              'snapshot_supported': true,
              'replay_supported': false,
              'plaintext_fallback_violation_count': 1,
            },
          ),
        ),
        ai2aiKernel: _StaticAi2AiKernel(
          const Ai2AiKernelHealthSnapshot(
            kernelId: 'ai2ai_runtime_governance',
            status: Ai2AiHealthStatus.degraded,
            nativeBacked: false,
            headlessReady: true,
            summary: 'ai2ai degraded',
            diagnostics: <String, dynamic>{
              'delivery_truth_present': false,
              'learning_truth_present': false,
              'snapshot_supported': true,
              'replay_supported': false,
            },
          ),
        ),
        encryptionService: _StaticEncryptionService(EncryptionType.aes256gcm),
        featureFlagService: _AlwaysDisabledFeatureFlagService(),
      );

      final report = await service.buildReport();

      expect(report.runtimeReady, isFalse);
      expect(report.fieldPilotReady, isFalse);
      expect(report.violations, contains('mesh:route_truth_missing'));
      expect(
          report.fieldPilotBlockers, contains('mesh:native_backing_missing'));
      expect(
          report.fieldPilotBlockers, contains('ai2ai:native_backing_missing'));
      expect(report.fieldPilotBlockers, contains('mesh:feature_flag_disabled'));
      expect(
          report.fieldPilotBlockers, contains('ai2ai:feature_flag_disabled'));
    });
  });
}

class _StaticMeshKernel extends MeshKernelContract {
  const _StaticMeshKernel(this.health);

  final MeshKernelHealthSnapshot health;

  @override
  Future<MeshKernelHealthSnapshot> diagnoseMesh() async => health;

  @override
  Future<MeshTransportReceipt> commitTransport(MeshTransportCommit request) {
    throw UnimplementedError();
  }

  @override
  Future<MeshTransportReceipt> observeTransport(MeshObservation observation) {
    throw UnimplementedError();
  }

  @override
  Future<MeshTransportPlan> planTransport(MeshRoutePlanningRequest request) {
    throw UnimplementedError();
  }

  @override
  MeshTransportSnapshot? snapshotTransport(String subjectId) => null;
}

class _StaticAi2AiKernel extends Ai2AiKernelContract {
  const _StaticAi2AiKernel(this.health);

  final Ai2AiKernelHealthSnapshot health;

  @override
  Future<Ai2AiKernelHealthSnapshot> diagnoseAi2Ai() async => health;

  @override
  Future<Ai2AiExchangeReceipt> commitExchange(Ai2AiExchangeCommit request) {
    throw UnimplementedError();
  }

  @override
  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Ai2AiExchangePlan> planExchange(Ai2AiExchangeCandidate candidate) {
    throw UnimplementedError();
  }

  @override
  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId) => null;
}

class _StaticEncryptionService implements MessageEncryptionService {
  const _StaticEncryptionService(this.encryptionType);

  @override
  final EncryptionType encryptionType;

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

class _AlwaysDisabledFeatureFlagService extends FeatureFlagService {
  _AlwaysDisabledFeatureFlagService() : super(storage: StorageService.instance);

  @override
  Future<bool> isEnabled(
    String featureName, {
    String? userId,
    bool defaultValue = false,
  }) async {
    return false;
  }
}
