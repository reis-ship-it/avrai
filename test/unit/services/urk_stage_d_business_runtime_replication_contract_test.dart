import 'package:avrai/core/services/business/urk_stage_d_business_runtime_replication_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _BusinessKernelRegistryService extends UrkKernelRegistryService {
  const _BusinessKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'federated_cloud': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_business_runtime',
          title: 'Business Runtime',
          purpose: 'Business runtime dispatch',
          runtimeScope: ['business_ops_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['federated_cloud'],
          impactTier: 'L3',
          localityScope: ['cloud'],
          activationTriggers: [
            'business_runtime_request',
            'runtime_health_breach',
            'policy_violation_detected',
          ],
          authorityMode: 'enforced',
          dependencies: ['M8-P9-2'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M8-P9-2',
          status: 'done',
        ),
      ],
    );
  }
}

void main() {
  group('UrkStageDBusinessRuntimeReplicationValidator', () {
    const validator = UrkStageDBusinessRuntimeReplicationValidator();

    test('passes when business runtime replication controls are healthy', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on pipeline/policy coverage regressions', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 88.0,
        observedPolicyGateCoveragePct: 93.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .pipelineCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .policyGateCoverageBelowThreshold,
        ),
      );
    });

    test('fails on lineage and high-impact review guard regressions', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 92.0,
        observedUnattributedActions: 2,
        observedHighImpactReviewCoveragePct: 90.0,
        observedUnreviewedHighImpactCommits: 1,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .lineageCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .unattributedActionsDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .highImpactReviewCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .unreviewedHighImpactCommitDetected,
        ),
      );
    });

    test('dispatches business activation receipt on pass', () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_business_dispatch_pass');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _BusinessKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _BusinessKernelRegistryService(),
      );

      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = await validator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: 'BusinessService',
      );

      expect(result.isPassing, isTrue);
      final lineage = await controlPlane.getKernelLineage('k_business_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });
  });
}
