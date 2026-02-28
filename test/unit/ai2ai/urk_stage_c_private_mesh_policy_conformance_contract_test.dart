import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_stage_c_private_mesh_policy_conformance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageCPrivateMeshPolicyConformanceValidator', () {
    const validator = UrkStageCPrivateMeshPolicyConformanceValidator();

    test('passes when private mesh payload, encryption, and policy checks are healthy', () {
      const snapshot = UrkStageCPrivateMeshPolicyConformanceSnapshot(
        observedSchemaConformancePct: 100.0,
        observedDirectIdentifierLeaks: 0,
        observedDoubleEncryptionCoveragePct: 100.0,
        observedKeyRotationCoveragePct: 100.0,
        observedLineageTagCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedPolicyBypassEvents: 0,
      );
      const policy = UrkStageCPrivateMeshPolicyConformancePolicy(
        requiredSchemaConformancePct: 100.0,
        maxDirectIdentifierLeaks: 0,
        requiredDoubleEncryptionCoveragePct: 100.0,
        requiredKeyRotationCoveragePct: 100.0,
        requiredLineageTagCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        maxPolicyBypassEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when payload minimization leaks identifiers', () {
      const snapshot = UrkStageCPrivateMeshPolicyConformanceSnapshot(
        observedSchemaConformancePct: 94.0,
        observedDirectIdentifierLeaks: 2,
        observedDoubleEncryptionCoveragePct: 100.0,
        observedKeyRotationCoveragePct: 100.0,
        observedLineageTagCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedPolicyBypassEvents: 0,
      );
      const policy = UrkStageCPrivateMeshPolicyConformancePolicy(
        requiredSchemaConformancePct: 100.0,
        maxDirectIdentifierLeaks: 0,
        requiredDoubleEncryptionCoveragePct: 100.0,
        requiredKeyRotationCoveragePct: 100.0,
        requiredLineageTagCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        maxPolicyBypassEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .payloadSchemaCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .directIdentifierLeakDetected,
        ),
      );
    });

    test('fails when encryption/key rotation and lineage-policy gates regress', () {
      const snapshot = UrkStageCPrivateMeshPolicyConformanceSnapshot(
        observedSchemaConformancePct: 100.0,
        observedDirectIdentifierLeaks: 0,
        observedDoubleEncryptionCoveragePct: 88.0,
        observedKeyRotationCoveragePct: 79.0,
        observedLineageTagCoveragePct: 86.0,
        observedPolicyGateCoveragePct: 90.0,
        observedPolicyBypassEvents: 3,
      );
      const policy = UrkStageCPrivateMeshPolicyConformancePolicy(
        requiredSchemaConformancePct: 100.0,
        maxDirectIdentifierLeaks: 0,
        requiredDoubleEncryptionCoveragePct: 100.0,
        requiredKeyRotationCoveragePct: 100.0,
        requiredLineageTagCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        maxPolicyBypassEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .doubleEncryptionCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .keyRotationCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .lineageTagCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure
              .policyGateCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageCPrivateMeshPolicyConformanceFailure.policyBypassDetected,
        ),
      );
    });
  });
}
