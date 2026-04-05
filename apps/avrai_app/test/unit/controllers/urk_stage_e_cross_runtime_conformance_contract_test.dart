import 'package:avrai_runtime_os/kernel/contracts/urk_stage_e_cross_runtime_conformance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageECrossRuntimeConformanceValidator', () {
    const validator = UrkStageECrossRuntimeConformanceValidator();

    test('passes when all runtime invariants are conformant', () {
      const snapshot = UrkStageECrossRuntimeConformanceSnapshot(
        observedRuntimeCount: 3,
        observedContractCoveragePct: 100.0,
        observedReplayDeterminismPct: 100.0,
        observedPolicyDivergenceEvents: 0,
      );
      const policy = UrkStageECrossRuntimeConformancePolicy(
        requiredRuntimeCount: 3,
        requiredContractCoveragePct: 100.0,
        requiredReplayDeterminismPct: 100.0,
        maxPolicyDivergenceEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when runtime set coverage is incomplete', () {
      const snapshot = UrkStageECrossRuntimeConformanceSnapshot(
        observedRuntimeCount: 2,
        observedContractCoveragePct: 100.0,
        observedReplayDeterminismPct: 100.0,
        observedPolicyDivergenceEvents: 0,
      );
      const policy = UrkStageECrossRuntimeConformancePolicy(
        requiredRuntimeCount: 3,
        requiredContractCoveragePct: 100.0,
        requiredReplayDeterminismPct: 100.0,
        maxPolicyDivergenceEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
            UrkStageECrossRuntimeConformanceFailure.runtimeCountBelowThreshold),
      );
    });

    test('fails when coverage/determinism regress or policy diverges', () {
      const snapshot = UrkStageECrossRuntimeConformanceSnapshot(
        observedRuntimeCount: 3,
        observedContractCoveragePct: 95.0,
        observedReplayDeterminismPct: 89.0,
        observedPolicyDivergenceEvents: 4,
      );
      const policy = UrkStageECrossRuntimeConformancePolicy(
        requiredRuntimeCount: 3,
        requiredContractCoveragePct: 100.0,
        requiredReplayDeterminismPct: 100.0,
        maxPolicyDivergenceEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkStageECrossRuntimeConformanceFailure
            .contractCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(
          UrkStageECrossRuntimeConformanceFailure
              .replayDeterminismBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
            UrkStageECrossRuntimeConformanceFailure.policyDivergenceDetected),
      );
    });
  });
}
