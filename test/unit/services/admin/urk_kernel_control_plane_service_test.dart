import 'dart:convert';

import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../../mocks/mock_storage_service.dart';

class _FakeUrkKernelRegistryService extends UrkKernelRegistryService {
  const _FakeUrkKernelRegistryService();

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
          activationTriggers: [
            'incident_closed',
            'admin_control_plane_state_change'
          ],
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

void main() {
  group('UrkKernelControlPlaneService', () {
    late SharedPreferencesCompat prefs;
    late UrkKernelControlPlaneService service;

    setUp(() async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_control_plane_test');
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      service = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _FakeUrkKernelRegistryService(),
      );
    });

    test('lists kernels with default runtime state from registry lifecycle',
        () async {
      final kernels = await service.listKernels();
      expect(kernels, hasLength(1));
      expect(kernels.first.kernel.kernelId, 'k_activation');
      expect(kernels.first.state.state, UrkKernelRuntimeState.active);
      expect(kernels.first.health.status, UrkKernelHealthStatus.healthy);
    });

    test('persists state transitions and lineage events', () async {
      await service.setKernelState(
        kernelId: 'k_activation',
        desiredState: UrkKernelRuntimeState.paused,
        actor: 'test_admin',
        reason: 'maintenance_window',
      );

      final state = await service.getKernelState('k_activation');
      expect(state.state, UrkKernelRuntimeState.paused);
      expect(state.updatedBy, 'test_admin');

      final lineage = await service.getKernelLineage('k_activation');
      expect(lineage, isNotEmpty);
      expect(lineage.where((event) => event.eventType == 'state_change'),
          isNotEmpty);
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });

    test('blocks disabled -> active direct transitions', () async {
      await service.setKernelState(
        kernelId: 'k_activation',
        desiredState: UrkKernelRuntimeState.disabled,
        actor: 'test_admin',
        reason: 'disable_for_incident',
      );

      expect(
        () => service.setKernelState(
          kernelId: 'k_activation',
          desiredState: UrkKernelRuntimeState.active,
          actor: 'test_admin',
          reason: 'unsafe_direct_reenable',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('records activation receipts in lineage', () async {
      await service.recordActivationReceipt(
        kernelId: 'k_activation',
        requestId: 'req-42',
        actor: 'runtime_engine',
        reason: 'activated_after_policy_gate',
      );

      final lineage = await service.getKernelLineage('k_activation');
      expect(lineage, isNotEmpty);
      expect(lineage.first.eventType, 'activation_receipt');
      expect(lineage.first.requestId, 'req-42');
    });

    test('falls back safely when persisted state or lineage payload is invalid',
        () async {
      await prefs.setString(
        'urk_kernel_control_plane_state_v1',
        'not-json',
      );
      await prefs.setString(
        'urk_kernel_control_plane_lineage_v1',
        '{"unexpected":"map"}',
      );

      final kernels = await service.listKernels();
      expect(kernels, hasLength(1));
      expect(kernels.first.kernel.kernelId, 'k_activation');
      expect(kernels.first.state.state, UrkKernelRuntimeState.active);

      final lineage = await service.getKernelLineage('k_activation', limit: 10);
      expect(lineage, isEmpty);
    });

    test('caps lineage persistence to last 5000 events', () async {
      final seed = List<Map<String, dynamic>>.generate(5000, (index) {
        return <String, dynamic>{
          'kernel_id': 'k_activation',
          'event_type': 'activation_receipt',
          'actor': 'seed_actor',
          'reason': 'seed_reason',
          'timestamp': DateTime.utc(2026, 1, 1)
              .add(Duration(seconds: index))
              .toIso8601String(),
          'request_id': 'seed-$index',
        };
      });
      await prefs.setString(
        'urk_kernel_control_plane_lineage_v1',
        jsonEncode(seed),
      );

      await service.recordActivationReceipt(
        kernelId: 'k_activation',
        requestId: 'latest-request',
        actor: 'runtime_engine',
        reason: 'post-cap-check',
      );

      final lineage =
          await service.getKernelLineage('k_activation', limit: 6000);
      expect(lineage, hasLength(5000));
      expect(lineage.first.requestId, 'latest-request');
      expect(lineage.any((event) => event.requestId == 'seed-0'), isFalse);
      expect(lineage.any((event) => event.requestId == 'seed-1'), isTrue);
    });

    test('summarizes user-runtime learning acceptance and opt-out rates',
        () async {
      await service.recordActivationReceipt(
        kernelId: 'k_user_runtime_learning',
        requestId: 'req-user-1',
        actor: 'anon_a',
        reason:
            'user_runtime_learning_intake_accepted;runtime_lane=user_runtime;privacy_mode=local_sovereign;consent_toggle=user_runtime_learning_enabled',
      );
      await service.recordActivationReceipt(
        kernelId: 'k_user_runtime_learning',
        requestId: 'req-user-2',
        actor: 'anon_b',
        reason:
            'user_runtime_learning_intake_rejected;runtime_lane=user_runtime;privacy_mode=local_sovereign;consent_toggle=user_runtime_learning_enabled;reason_code=missing_user_runtime_learning_consent',
      );

      final summary = await service.summarizeUserRuntimeLearning();
      expect(summary.totalAccepted, 1);
      expect(summary.totalRejected, 1);
      expect(summary.totalOptOut, 1);
      expect(summary.buckets, hasLength(1));
      final bucket = summary.buckets.first;
      expect(bucket.runtimeLane, 'user_runtime');
      expect(bucket.privacyMode, 'local_sovereign');
      expect(bucket.acceptedCount, 1);
      expect(bucket.rejectedCount, 1);
      expect(bucket.optOutCount, 1);
    });
  });
}
