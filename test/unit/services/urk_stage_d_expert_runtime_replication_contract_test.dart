import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_stage_d_expert_runtime_replication_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_kernel_control_plane_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
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
          purpose: 'Expert runtime dispatch coverage',
          runtimeScope: ['expert_services_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['private_mesh'],
          impactTier: 'L3',
          localityScope: ['mesh', 'cloud'],
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
        observedExpertisePolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedProvenanceTagCoveragePct: 100.0,
        observedUnverifiedExpertCommits: 0,
        observedHighImpactReviewCoveragePct: 100.0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredExpertisePolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        requiredProvenanceTagCoveragePct: 100.0,
        maxUnverifiedExpertCommits: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on pipeline and expertise policy gate regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 90.0,
        observedExpertisePolicyGateCoveragePct: 87.0,
        observedLineageCoveragePct: 100.0,
        observedProvenanceTagCoveragePct: 100.0,
        observedUnverifiedExpertCommits: 0,
        observedHighImpactReviewCoveragePct: 100.0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredExpertisePolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        requiredProvenanceTagCoveragePct: 100.0,
        maxUnverifiedExpertCommits: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkStageDExpertRuntimeReplicationFailure
            .pipelineCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .expertisePolicyGateCoverageBelowThreshold,
        ),
      );
    });

    test('fails on lineage/provenance and commit safety regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedExpertisePolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 93.0,
        observedProvenanceTagCoveragePct: 91.0,
        observedUnverifiedExpertCommits: 2,
        observedHighImpactReviewCoveragePct: 88.0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredExpertisePolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        requiredProvenanceTagCoveragePct: 100.0,
        maxUnverifiedExpertCommits: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkStageDExpertRuntimeReplicationFailure
            .lineageCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .provenanceTagCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .unverifiedExpertCommitDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .highImpactReviewCoverageBelowThreshold,
        ),
      );
    });

    test('dispatches expert runtime activation receipt on pass', () async {
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
        observedExpertisePolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedProvenanceTagCoveragePct: 100.0,
        observedUnverifiedExpertCommits: 0,
        observedHighImpactReviewCoveragePct: 100.0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredExpertisePolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        requiredProvenanceTagCoveragePct: 100.0,
        maxUnverifiedExpertCommits: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
      );

      final result = await validator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: 'ExpertRuntimeService',
      );

      expect(result.isPassing, isTrue);
      final lineage = await controlPlane.getKernelLineage('k_expert_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });

    test('dispatches runtime health breach trigger on unverified commits',
        () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_expert_dispatch_fail');
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
        observedExpertisePolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedProvenanceTagCoveragePct: 100.0,
        observedUnverifiedExpertCommits: 1,
        observedHighImpactReviewCoveragePct: 100.0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredExpertisePolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        requiredProvenanceTagCoveragePct: 100.0,
        maxUnverifiedExpertCommits: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
      );

      final result = await validator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: 'ExpertRuntimeService',
      );

      expect(result.isPassing, isFalse);
      final lineage = await controlPlane.getKernelLineage('k_expert_runtime');
      final receipts =
          lineage.where((event) => event.eventType == 'activation_receipt');
      expect(receipts, isNotEmpty);
      expect(receipts.first.reason, contains('runtime_health_breach'));
    });
  });
}
