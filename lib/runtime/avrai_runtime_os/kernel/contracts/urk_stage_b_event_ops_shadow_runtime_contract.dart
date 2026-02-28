// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';

enum UrkStageBEventOpsShadowRuntimeFailure {
  invalidPipelineThreshold,
  invalidDecisionEnvelopeThreshold,
  invalidLineageThreshold,
  invalidGuardThreshold,
  pipelineCoverageBelowThreshold,
  decisionEnvelopeCoverageBelowThreshold,
  lineageCompletenessBelowThreshold,
  orphanActionStatesDetected,
  highImpactAutocommitDetected,
  shadowBlockCoverageBelowThreshold,
}

class UrkStageBEventOpsShadowRuntimePolicy {
  const UrkStageBEventOpsShadowRuntimePolicy({
    required this.requiredPipelineCoveragePct,
    required this.requiredDecisionEnvelopeCoveragePct,
    required this.requiredLineageCompletenessPct,
    required this.maxOrphanActionStates,
    required this.maxHighImpactAutocommits,
    required this.requiredShadowBlockCoveragePct,
  });

  final double requiredPipelineCoveragePct;
  final double requiredDecisionEnvelopeCoveragePct;
  final double requiredLineageCompletenessPct;
  final int maxOrphanActionStates;
  final int maxHighImpactAutocommits;
  final double requiredShadowBlockCoveragePct;
}

class UrkStageBEventOpsShadowRuntimeSnapshot {
  const UrkStageBEventOpsShadowRuntimeSnapshot({
    required this.observedPipelineCoveragePct,
    required this.observedDecisionEnvelopeCoveragePct,
    required this.observedLineageCompletenessPct,
    required this.observedOrphanActionStates,
    required this.observedHighImpactAutocommits,
    required this.observedShadowBlockCoveragePct,
  });

  final double observedPipelineCoveragePct;
  final double observedDecisionEnvelopeCoveragePct;
  final double observedLineageCompletenessPct;
  final int observedOrphanActionStates;
  final int observedHighImpactAutocommits;
  final double observedShadowBlockCoveragePct;
}

class UrkStageBEventOpsShadowRuntimeValidationResult {
  const UrkStageBEventOpsShadowRuntimeValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageBEventOpsShadowRuntimeValidationResult.pass() {
    return const UrkStageBEventOpsShadowRuntimeValidationResult._(
      isPassing: true,
      failures: <UrkStageBEventOpsShadowRuntimeFailure>[],
    );
  }

  factory UrkStageBEventOpsShadowRuntimeValidationResult.fail(
    List<UrkStageBEventOpsShadowRuntimeFailure> failures,
  ) {
    return UrkStageBEventOpsShadowRuntimeValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageBEventOpsShadowRuntimeFailure> failures;
}

class UrkStageBEventOpsShadowRuntimeValidator {
  const UrkStageBEventOpsShadowRuntimeValidator();

  UrkStageBEventOpsShadowRuntimeValidationResult validate({
    required UrkStageBEventOpsShadowRuntimeSnapshot snapshot,
    required UrkStageBEventOpsShadowRuntimePolicy policy,
  }) {
    final failures = <UrkStageBEventOpsShadowRuntimeFailure>[];

    if (policy.requiredPipelineCoveragePct < 0) {
      failures
          .add(UrkStageBEventOpsShadowRuntimeFailure.invalidPipelineThreshold);
    }
    if (policy.requiredDecisionEnvelopeCoveragePct < 0) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure.invalidDecisionEnvelopeThreshold,
      );
    }
    if (policy.requiredLineageCompletenessPct < 0 ||
        policy.maxOrphanActionStates < 0) {
      failures
          .add(UrkStageBEventOpsShadowRuntimeFailure.invalidLineageThreshold);
    }
    if (policy.maxHighImpactAutocommits < 0 ||
        policy.requiredShadowBlockCoveragePct < 0) {
      failures.add(UrkStageBEventOpsShadowRuntimeFailure.invalidGuardThreshold);
    }

    if (snapshot.observedPipelineCoveragePct <
        policy.requiredPipelineCoveragePct) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure.pipelineCoverageBelowThreshold,
      );
    }
    if (snapshot.observedDecisionEnvelopeCoveragePct <
        policy.requiredDecisionEnvelopeCoveragePct) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure
            .decisionEnvelopeCoverageBelowThreshold,
      );
    }
    if (snapshot.observedLineageCompletenessPct <
        policy.requiredLineageCompletenessPct) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure.lineageCompletenessBelowThreshold,
      );
    }
    if (snapshot.observedOrphanActionStates > policy.maxOrphanActionStates) {
      failures.add(
          UrkStageBEventOpsShadowRuntimeFailure.orphanActionStatesDetected);
    }
    if (snapshot.observedHighImpactAutocommits >
        policy.maxHighImpactAutocommits) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure.highImpactAutocommitDetected,
      );
    }
    if (snapshot.observedShadowBlockCoveragePct <
        policy.requiredShadowBlockCoveragePct) {
      failures.add(
        UrkStageBEventOpsShadowRuntimeFailure.shadowBlockCoverageBelowThreshold,
      );
    }

    if (failures.isEmpty) {
      return UrkStageBEventOpsShadowRuntimeValidationResult.pass();
    }
    return UrkStageBEventOpsShadowRuntimeValidationResult.fail(failures);
  }

  Future<UrkStageBEventOpsShadowRuntimeValidationResult> validateAndDispatch({
    required UrkStageBEventOpsShadowRuntimeSnapshot snapshot,
    required UrkStageBEventOpsShadowRuntimePolicy policy,
    required UrkRuntimeActivationReceiptDispatcher activationDispatcher,
    required String actor,
    String requestIdPrefix = 'event_ops_runtime',
  }) async {
    final result = validate(snapshot: snapshot, policy: policy);
    final trigger = _mapResultToTrigger(result);
    await activationDispatcher.dispatch(
      requestId: '${requestIdPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      trigger: trigger,
      privacyMode: UrkPrivacyMode.multiMode,
      actor: actor,
      reason: result.isPassing
          ? 'event_ops_runtime_validation_pass:trigger=$trigger'
          : 'event_ops_runtime_validation_fail:trigger=$trigger:${result.failures.map((f) => f.name).join(",")}',
    );
    return result;
  }

  String _mapResultToTrigger(
    UrkStageBEventOpsShadowRuntimeValidationResult result,
  ) {
    if (result.isPassing) {
      return 'event_ops_shadow_execution';
    }
    if (result.failures.contains(
          UrkStageBEventOpsShadowRuntimeFailure.highImpactAutocommitDetected,
        ) ||
        result.failures.contains(
          UrkStageBEventOpsShadowRuntimeFailure.orphanActionStatesDetected,
        )) {
      return 'runtime_health_breach';
    }
    return 'policy_violation_detected';
  }
}
