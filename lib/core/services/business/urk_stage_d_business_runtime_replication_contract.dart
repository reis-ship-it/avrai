// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';

enum UrkStageDBusinessRuntimeReplicationFailure {
  invalidPipelineThreshold,
  invalidLineageThreshold,
  invalidCommitSafetyThreshold,
  pipelineCoverageBelowThreshold,
  policyGateCoverageBelowThreshold,
  lineageCoverageBelowThreshold,
  unattributedActionsDetected,
  highImpactReviewCoverageBelowThreshold,
  unreviewedHighImpactCommitDetected,
}

class UrkStageDBusinessRuntimeReplicationPolicy {
  const UrkStageDBusinessRuntimeReplicationPolicy({
    required this.requiredPipelineCoveragePct,
    required this.requiredPolicyGateCoveragePct,
    required this.requiredLineageCoveragePct,
    required this.maxUnattributedActions,
    required this.requiredHighImpactReviewCoveragePct,
    required this.maxUnreviewedHighImpactCommits,
  });

  final double requiredPipelineCoveragePct;
  final double requiredPolicyGateCoveragePct;
  final double requiredLineageCoveragePct;
  final int maxUnattributedActions;
  final double requiredHighImpactReviewCoveragePct;
  final int maxUnreviewedHighImpactCommits;
}

class UrkStageDBusinessRuntimeReplicationSnapshot {
  const UrkStageDBusinessRuntimeReplicationSnapshot({
    required this.observedPipelineCoveragePct,
    required this.observedPolicyGateCoveragePct,
    required this.observedLineageCoveragePct,
    required this.observedUnattributedActions,
    required this.observedHighImpactReviewCoveragePct,
    required this.observedUnreviewedHighImpactCommits,
  });

  final double observedPipelineCoveragePct;
  final double observedPolicyGateCoveragePct;
  final double observedLineageCoveragePct;
  final int observedUnattributedActions;
  final double observedHighImpactReviewCoveragePct;
  final int observedUnreviewedHighImpactCommits;
}

class UrkStageDBusinessRuntimeReplicationValidationResult {
  const UrkStageDBusinessRuntimeReplicationValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageDBusinessRuntimeReplicationValidationResult.pass() {
    return const UrkStageDBusinessRuntimeReplicationValidationResult._(
      isPassing: true,
      failures: <UrkStageDBusinessRuntimeReplicationFailure>[],
    );
  }

  factory UrkStageDBusinessRuntimeReplicationValidationResult.fail(
    List<UrkStageDBusinessRuntimeReplicationFailure> failures,
  ) {
    return UrkStageDBusinessRuntimeReplicationValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageDBusinessRuntimeReplicationFailure> failures;
}

class UrkStageDBusinessRuntimeReplicationValidator {
  const UrkStageDBusinessRuntimeReplicationValidator();

  UrkStageDBusinessRuntimeReplicationValidationResult validate({
    required UrkStageDBusinessRuntimeReplicationSnapshot snapshot,
    required UrkStageDBusinessRuntimeReplicationPolicy policy,
  }) {
    final failures = <UrkStageDBusinessRuntimeReplicationFailure>[];

    if (policy.requiredPipelineCoveragePct < 0 ||
        policy.requiredPolicyGateCoveragePct < 0) {
      failures.add(
          UrkStageDBusinessRuntimeReplicationFailure.invalidPipelineThreshold);
    }
    if (policy.requiredLineageCoveragePct < 0 ||
        policy.maxUnattributedActions < 0) {
      failures.add(
          UrkStageDBusinessRuntimeReplicationFailure.invalidLineageThreshold);
    }
    if (policy.requiredHighImpactReviewCoveragePct < 0 ||
        policy.maxUnreviewedHighImpactCommits < 0) {
      failures.add(
        UrkStageDBusinessRuntimeReplicationFailure.invalidCommitSafetyThreshold,
      );
    }

    if (snapshot.observedPipelineCoveragePct <
        policy.requiredPipelineCoveragePct) {
      failures.add(UrkStageDBusinessRuntimeReplicationFailure
          .pipelineCoverageBelowThreshold);
    }
    if (snapshot.observedPolicyGateCoveragePct <
        policy.requiredPolicyGateCoveragePct) {
      failures.add(UrkStageDBusinessRuntimeReplicationFailure
          .policyGateCoverageBelowThreshold);
    }
    if (snapshot.observedLineageCoveragePct <
        policy.requiredLineageCoveragePct) {
      failures.add(UrkStageDBusinessRuntimeReplicationFailure
          .lineageCoverageBelowThreshold);
    }
    if (snapshot.observedUnattributedActions > policy.maxUnattributedActions) {
      failures.add(UrkStageDBusinessRuntimeReplicationFailure
          .unattributedActionsDetected);
    }
    if (snapshot.observedHighImpactReviewCoveragePct <
        policy.requiredHighImpactReviewCoveragePct) {
      failures.add(
        UrkStageDBusinessRuntimeReplicationFailure
            .highImpactReviewCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnreviewedHighImpactCommits >
        policy.maxUnreviewedHighImpactCommits) {
      failures.add(
        UrkStageDBusinessRuntimeReplicationFailure
            .unreviewedHighImpactCommitDetected,
      );
    }

    if (failures.isEmpty) {
      return UrkStageDBusinessRuntimeReplicationValidationResult.pass();
    }
    return UrkStageDBusinessRuntimeReplicationValidationResult.fail(failures);
  }

  Future<UrkStageDBusinessRuntimeReplicationValidationResult>
      validateAndDispatch({
    required UrkStageDBusinessRuntimeReplicationSnapshot snapshot,
    required UrkStageDBusinessRuntimeReplicationPolicy policy,
    required UrkRuntimeActivationReceiptDispatcher activationDispatcher,
    required String actor,
    String requestIdPrefix = 'business_runtime',
  }) async {
    final result = validate(snapshot: snapshot, policy: policy);
    final trigger = _mapResultToTrigger(result);
    await activationDispatcher.dispatch(
      requestId: '${requestIdPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      trigger: trigger,
      privacyMode: UrkPrivacyMode.federatedCloud,
      actor: actor,
      reason: result.isPassing
          ? 'business_runtime_validation_pass:trigger=$trigger'
          : 'business_runtime_validation_fail:trigger=$trigger:${result.failures.map((f) => f.name).join(",")}',
    );
    return result;
  }

  String _mapResultToTrigger(
    UrkStageDBusinessRuntimeReplicationValidationResult result,
  ) {
    if (result.isPassing) {
      return 'business_runtime_request';
    }
    if (result.failures.contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .unreviewedHighImpactCommitDetected,
        ) ||
        result.failures.contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .unattributedActionsDetected,
        )) {
      return 'runtime_health_breach';
    }
    return 'policy_violation_detected';
  }
}
