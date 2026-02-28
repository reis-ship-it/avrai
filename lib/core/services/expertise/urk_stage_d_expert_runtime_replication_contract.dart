import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';

enum UrkStageDExpertRuntimeReplicationFailure {
  invalidPipelineThreshold,
  invalidLineageThreshold,
  invalidProvenanceThreshold,
  invalidCommitSafetyThreshold,
  pipelineCoverageBelowThreshold,
  policyGateCoverageBelowThreshold,
  lineageCoverageBelowThreshold,
  unattributedActionsDetected,
  provenanceCoverageBelowThreshold,
  unverifiedOutputsDetected,
  highImpactReviewCoverageBelowThreshold,
  unreviewedHighImpactCommitDetected,
}

class UrkStageDExpertRuntimeReplicationPolicy {
  const UrkStageDExpertRuntimeReplicationPolicy({
    required this.requiredPipelineCoveragePct,
    required this.requiredPolicyGateCoveragePct,
    required this.requiredLineageCoveragePct,
    required this.maxUnattributedActions,
    required this.requiredProvenanceCoveragePct,
    required this.maxUnverifiedOutputs,
    required this.requiredHighImpactReviewCoveragePct,
    required this.maxUnreviewedHighImpactCommits,
  });

  final double requiredPipelineCoveragePct;
  final double requiredPolicyGateCoveragePct;
  final double requiredLineageCoveragePct;
  final int maxUnattributedActions;
  final double requiredProvenanceCoveragePct;
  final int maxUnverifiedOutputs;
  final double requiredHighImpactReviewCoveragePct;
  final int maxUnreviewedHighImpactCommits;
}

class UrkStageDExpertRuntimeReplicationSnapshot {
  const UrkStageDExpertRuntimeReplicationSnapshot({
    required this.observedPipelineCoveragePct,
    required this.observedPolicyGateCoveragePct,
    required this.observedLineageCoveragePct,
    required this.observedUnattributedActions,
    required this.observedProvenanceCoveragePct,
    required this.observedUnverifiedOutputs,
    required this.observedHighImpactReviewCoveragePct,
    required this.observedUnreviewedHighImpactCommits,
  });

  final double observedPipelineCoveragePct;
  final double observedPolicyGateCoveragePct;
  final double observedLineageCoveragePct;
  final int observedUnattributedActions;
  final double observedProvenanceCoveragePct;
  final int observedUnverifiedOutputs;
  final double observedHighImpactReviewCoveragePct;
  final int observedUnreviewedHighImpactCommits;
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
        policy.requiredPolicyGateCoveragePct < 0) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.invalidPipelineThreshold);
    }
    if (policy.requiredLineageCoveragePct < 0 ||
        policy.maxUnattributedActions < 0) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.invalidLineageThreshold);
    }
    if (policy.requiredProvenanceCoveragePct < 0 ||
        policy.maxUnverifiedOutputs < 0) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.invalidProvenanceThreshold);
    }
    if (policy.requiredHighImpactReviewCoveragePct < 0 ||
        policy.maxUnreviewedHighImpactCommits < 0) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure.invalidCommitSafetyThreshold,
      );
    }

    if (snapshot.observedPipelineCoveragePct <
        policy.requiredPipelineCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .pipelineCoverageBelowThreshold);
    }
    if (snapshot.observedPolicyGateCoveragePct <
        policy.requiredPolicyGateCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .policyGateCoverageBelowThreshold);
    }
    if (snapshot.observedLineageCoveragePct <
        policy.requiredLineageCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .lineageCoverageBelowThreshold);
    }
    if (snapshot.observedUnattributedActions > policy.maxUnattributedActions) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.unattributedActionsDetected);
    }
    if (snapshot.observedProvenanceCoveragePct <
        policy.requiredProvenanceCoveragePct) {
      failures.add(UrkStageDExpertRuntimeReplicationFailure
          .provenanceCoverageBelowThreshold);
    }
    if (snapshot.observedUnverifiedOutputs > policy.maxUnverifiedOutputs) {
      failures.add(
          UrkStageDExpertRuntimeReplicationFailure.unverifiedOutputsDetected);
    }
    if (snapshot.observedHighImpactReviewCoveragePct <
        policy.requiredHighImpactReviewCoveragePct) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure
            .highImpactReviewCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnreviewedHighImpactCommits >
        policy.maxUnreviewedHighImpactCommits) {
      failures.add(
        UrkStageDExpertRuntimeReplicationFailure
            .unreviewedHighImpactCommitDetected,
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
      UrkStageDExpertRuntimeReplicationFailure.unverifiedOutputsDetected,
    )) {
      return 'runtime_health_breach';
    }
    return 'policy_violation_detected';
  }
}
