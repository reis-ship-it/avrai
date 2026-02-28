import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';

enum UrkStageDExpertRuntimeReplicationFailure {
  invalidPipelineThreshold,
  invalidLineageThreshold,
  invalidCommitSafetyThreshold,
  pipelineCoverageBelowThreshold,
  expertisePolicyGateCoverageBelowThreshold,
  lineageCoverageBelowThreshold,
  provenanceTagCoverageBelowThreshold,
  unverifiedExpertCommitDetected,
  highImpactReviewCoverageBelowThreshold,
}

class UrkStageDExpertRuntimeReplicationPolicy {
  const UrkStageDExpertRuntimeReplicationPolicy({
    required this.requiredPipelineCoveragePct,
    required this.requiredExpertisePolicyGateCoveragePct,
    required this.requiredLineageCoveragePct,
    required this.requiredProvenanceTagCoveragePct,
    required this.maxUnverifiedExpertCommits,
    required this.requiredHighImpactReviewCoveragePct,
  });

  final double requiredPipelineCoveragePct;
  final double requiredExpertisePolicyGateCoveragePct;
  final double requiredLineageCoveragePct;
  final double requiredProvenanceTagCoveragePct;
  final int maxUnverifiedExpertCommits;
  final double requiredHighImpactReviewCoveragePct;
}

class UrkStageDExpertRuntimeReplicationSnapshot {
  const UrkStageDExpertRuntimeReplicationSnapshot({
    required this.observedPipelineCoveragePct,
    required this.observedExpertisePolicyGateCoveragePct,
    required this.observedLineageCoveragePct,
    required this.observedProvenanceTagCoveragePct,
    required this.observedUnverifiedExpertCommits,
    required this.observedHighImpactReviewCoveragePct,
  });

  final double observedPipelineCoveragePct;
  final double observedExpertisePolicyGateCoveragePct;
  final double observedLineageCoveragePct;
  final double observedProvenanceTagCoveragePct;
  final int observedUnverifiedExpertCommits;
  final double observedHighImpactReviewCoveragePct;
}

class UrkStageDExpertRuntimeReplicationValidationResult {
  const UrkStageDExpertRuntimeReplicationValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageDExpertRuntimeReplicationValidationResult.pass() {
    return const UrkStageDExpertRuntimeReplicationValidationResult._(
      isPassing: true,
      failures: <UrkStageDExpertRuntimeReplicationFailure>[],
    );
  }

  factory UrkStageDExpertRuntimeReplicationValidationResult.fail(
    List<UrkStageDExpertRuntimeReplicationFailure> failures,
  ) {
    return UrkStageDExpertRuntimeReplicationValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageDExpertRuntimeReplicationFailure> failures;
}

class UrkStageDExpertRuntimeReplicationValidator {
  const UrkStageDExpertRuntimeReplicationValidator();

  UrkStageDExpertRuntimeReplicationValidationResult validate({
    required UrkStageDExpertRuntimeReplicationSnapshot snapshot,
    required UrkStageDExpertRuntimeReplicationPolicy policy,
  }) {
    final failures = <UrkStageDExpertRuntimeReplicationFailure>[];

    if (policy.requiredPipelineCoveragePct < 0 ||
        policy.requiredExpertisePolicyGateCoveragePct < 0) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.invalidPipelineThreshold);
    }
    if (policy.requiredLineageCoveragePct < 0 ||
        policy.requiredProvenanceTagCoveragePct < 0) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.invalidLineageThreshold);
    }
    if (policy.maxUnverifiedExpertCommits < 0 ||
        policy.requiredHighImpactReviewCoveragePct < 0) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .invalidCommitSafetyThreshold);
    }

    if (snapshot.observedPipelineCoveragePct <
        policy.requiredPipelineCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .pipelineCoverageBelowThreshold);
    }
    if (snapshot.observedExpertisePolicyGateCoveragePct <
        policy.requiredExpertisePolicyGateCoveragePct) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure
            .expertisePolicyGateCoverageBelowThreshold,
      );
    }
    if (snapshot.observedLineageCoveragePct <
        policy.requiredLineageCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .lineageCoverageBelowThreshold);
    }
    if (snapshot.observedProvenanceTagCoveragePct <
        policy.requiredProvenanceTagCoveragePct) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure
            .provenanceTagCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnverifiedExpertCommits >
        policy.maxUnverifiedExpertCommits) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .unverifiedExpertCommitDetected);
    }
    if (snapshot.observedHighImpactReviewCoveragePct <
        policy.requiredHighImpactReviewCoveragePct) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure
            .highImpactReviewCoverageBelowThreshold,
      );
    }

    if (failures.isEmpty) {
      return UrkStageDExpertRuntimeReplicationValidationResult.pass();
    }
    return UrkStageDExpertRuntimeReplicationValidationResult.fail(failures);
  }

  Future<UrkStageDExpertRuntimeReplicationValidationResult>
      validateAndDispatch({
    required UrkStageDExpertRuntimeReplicationSnapshot snapshot,
    required UrkStageDExpertRuntimeReplicationPolicy policy,
    required UrkRuntimeActivationReceiptDispatcher activationDispatcher,
    required String actor,
    String requestIdPrefix = 'expert_runtime',
  }) async {
    final result = validate(snapshot: snapshot, policy: policy);
    final trigger = _mapResultToTrigger(result);
    await activationDispatcher.dispatch(
      requestId: '${requestIdPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      trigger: trigger,
      privacyMode: UrkPrivacyMode.privateMesh,
      actor: actor,
      reason: result.isPassing
          ? 'expert_runtime_validation_pass:trigger=$trigger'
          : 'expert_runtime_validation_fail:trigger=$trigger:${result.failures.map((f) => f.name).join(",")}',
    );
    return result;
  }

  String _mapResultToTrigger(
    UrkStageDExpertRuntimeReplicationValidationResult result,
  ) {
    if (result.isPassing) {
      return 'expert_runtime_request';
    }
    if (result.failures.contains(
      UrkStageDExpertRuntimeReplicationFailure.unverifiedExpertCommitDetected,
    )) {
      return 'runtime_health_breach';
    }
    return 'policy_violation_detected';
  }
}
