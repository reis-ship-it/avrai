import 'package:avrai/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _ExpertKernelRegistryService extends UrkKernelRegistryService {
  const _ExpertKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'private_mesh': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_expert_runtime',
          title: 'Expert Runtime',
          purpose: 'Expert runtime dispatch',
          runtimeScope: ['expert_services_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['private_mesh'],
          impactTier: 'L3',
          localityScope: ['mesh'],
          activationTriggers: [
            'expert_runtime_request',
            'runtime_health_breach',
            'policy_violation_detected',
          ],
          authorityMode: 'enforced',
          dependencies: ['M8-P11-2'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M8-P11-2',
          status: 'done',
        ),
      ],
    );
  }
}

void main() {
  group('UrkStageDExpertRuntimeReplicationValidator', () {
    const validator = UrkStageDExpertRuntimeReplicationValidator();

    test('passes when expert runtime replication controls are healthy', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedProvenanceCoveragePct: 100.0,
        observedUnverifiedOutputs: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on pipeline, policy, and lineage regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 91.0,
        observedPolicyGateCoveragePct: 92.0,
        observedLineageCoveragePct: 93.0,
        observedUnattributedActions: 2,
        observedProvenanceCoveragePct: 100.0,
        observedUnverifiedOutputs: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .pipelineCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .policyGateCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .lineageCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.unattributedActionsDetected,
        ),
      );
    });

    test('fails on provenance and high-impact review safety regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedProvenanceCoveragePct: 94.0,
        observedUnverifiedOutputs: 3,
        observedHighImpactReviewCoveragePct: 96.0,
        observedUnreviewedHighImpactCommits: 1,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .provenanceCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.unverifiedOutputsDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .highImpactReviewCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .unreviewedHighImpactCommitDetected,
        ),
      );
    });

    test('dispatches expert activation receipt on pass', () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_expert_dispatch_pass');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _ExpertKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _ExpertKernelRegistryService(),
      );

      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedProvenanceCoveragePct: 100.0,
        observedUnverifiedOutputs: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = await validator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: 'ExpertRecommendationsService',
      );

      expect(result.isPassing, isTrue);
      final lineage = await controlPlane.getKernelLineage('k_expert_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });
  });
}
