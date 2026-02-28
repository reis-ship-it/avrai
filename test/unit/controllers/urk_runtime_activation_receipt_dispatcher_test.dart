import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

class _ControlPlaneRegistryService extends UrkKernelRegistryService {
  const _ControlPlaneRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'multi_mode': 1},
      byImpactTier: const {'L4': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_activation',
          title: 'Activation',
          purpose: 'Activation runtime',
          runtimeScope: ['shared'],
          prongScope: 'runtime_core',
          privacyModes: ['multi_mode'],
          impactTier: 'L4',
          localityScope: ['device'],
          activationTriggers: ['policy_violation_detected'],
          authorityMode: 'enforced',
          dependencies: ['M10-P7-1'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M10-P7-1',
          status: 'done',
        ),
      ],
    );
  }
}

class _DispatcherRegistryService extends UrkKernelRegistryService {
  const _DispatcherRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'multi_mode': 1},
      byImpactTier: const {'L4': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_activation',
          title: 'Activation',
          purpose: 'Activation runtime',
          runtimeScope: ['shared'],
          prongScope: 'runtime_core',
          privacyModes: ['multi_mode'],
          impactTier: 'L4',
          localityScope: ['device'],
          activationTriggers: ['policy_violation_detected'],
          authorityMode: 'enforced',
          dependencies: [],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M10-P7-1',
          status: 'done',
        ),
      ],
    );
  }
}

void main() {
  group('UrkRuntimeActivationReceiptDispatcher', () {
    late UrkKernelControlPlaneService controlPlane;
    late UrkRuntimeActivationReceiptDispatcher dispatcher;

    setUp(() async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_dispatch_test');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _ControlPlaneRegistryService(),
      );
      dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _DispatcherRegistryService(),
      );
    });

    test('records activation receipt for matching trigger', () async {
      final receipt = await dispatcher.dispatch(
        requestId: 'req-100',
        trigger: 'policy_violation_detected',
        privacyMode: UrkPrivacyMode.multiMode,
        actor: 'ConvictionGate',
        reason: 'policy_checks_failed',
      );

      expect(receipt, isNotNull);
      expect(receipt!.decisions, isNotEmpty);
      expect(receipt.decisions.first.activated, isTrue);

      final lineage = await controlPlane.getKernelLineage('k_activation');
      expect(lineage, isNotEmpty);
      expect(lineage.first.eventType, 'activation_receipt');
      expect(lineage.first.requestId, 'req-100');
    });

    test('returns receipt but no activation when trigger does not match',
        () async {
      final receipt = await dispatcher.dispatch(
        requestId: 'req-101',
        trigger: 'release_candidate_validation',
        privacyMode: UrkPrivacyMode.multiMode,
        actor: 'ConvictionGate',
        reason: 'allow_decision',
      );

      expect(receipt, isNotNull);
      expect(receipt!.decisions, isEmpty);

      final lineage = await controlPlane.getKernelLineage('k_activation');
      expect(lineage, isEmpty);
    });

    test('ignores non-kernel dependency references during activation',
        () async {
      final receipt = await dispatcher.dispatch(
        requestId: 'req-102',
        trigger: 'policy_violation_detected',
        privacyMode: UrkPrivacyMode.multiMode,
        actor: 'ConvictionGate',
        reason: 'policy_checks_failed',
      );

      expect(receipt, isNotNull);
      expect(receipt!.decisions, isNotEmpty);
      expect(receipt.decisions.first.activated, isTrue);
    });
  });
}
