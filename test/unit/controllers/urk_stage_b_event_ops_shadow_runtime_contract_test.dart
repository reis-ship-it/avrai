import 'package:avrai/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _EventOpsKernelRegistryService extends UrkKernelRegistryService {
  const _EventOpsKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'multi_mode': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_event_ops_runtime',
          title: 'Event Ops Runtime',
          purpose: 'Stage B event ops dispatch coverage',
          runtimeScope: ['event_ops_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['multi_mode'],
          impactTier: 'L3',
          localityScope: ['device', 'mesh', 'cloud'],
          activationTriggers: [
            'event_ops_shadow_execution',
            'runtime_health_breach',
            'policy_violation_detected',
          ],
          authorityMode: 'shadow',
          dependencies: ['M7-P7-4'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M7-P7-4',
          status: 'done',
        ),
      ],
    );
  }
}

void main() {
  group('UrkStageBEventOpsShadowRuntimeValidator', () {
    const validator = UrkStageBEventOpsShadowRuntimeValidator();

    test(
        'passes when shadow runtime pipeline, lineage, and guard checks are healthy',
        () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when ingest-plan-gate-observe pipeline coverage regresses', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 82.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.pipelineCoverageBelowThreshold,
        ),
      );
    });

    test('fails when decision envelopes/lineage are incomplete', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 94.0,
        observedLineageCompletenessPct: 91.0,
        observedOrphanActionStates: 2,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure
              .decisionEnvelopeCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure
              .lineageCompletenessBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
            UrkStageBEventOpsShadowRuntimeFailure.orphanActionStatesDetected),
      );
    });

    test('fails when high-impact autocommits occur in shadow mode', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 1,
        observedShadowBlockCoveragePct: 89.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.highImpactAutocommitDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure
              .shadowBlockCoverageBelowThreshold,
        ),
      );
    });

    test('dispatches event ops activation receipt on pass', () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_event_ops_dispatch_pass');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _EventOpsKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _EventOpsKernelRegistryService(),
      );

      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = await validator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: 'EventOpsRuntimeService',
      );

      expect(result.isPassing, isTrue);
      final lineage =
          await controlPlane.getKernelLineage('k_event_ops_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });
  });
}
