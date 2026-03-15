import 'package:avrai_runtime_os/kernel/contracts/urk_governance_inspection_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkGovernanceInspectionValidator', () {
    const validator = UrkGovernanceInspectionValidator();

    test('passes when governance inspection controls are healthy', () {
      const snapshot = UrkGovernanceInspectionSnapshot(
        observedGovernanceStrataCoveragePct: 100.0,
        observedSummaryVisibilityCoveragePct: 100.0,
        observedBreakGlassAuditCoveragePct: 100.0,
        observedUnauditedBreakGlassInspections: 0,
        observedHiddenInspectionPaths: 0,
      );
      const policy = UrkGovernanceInspectionPolicy(
        requiredGovernanceStrataCoveragePct: 100.0,
        requiredSummaryVisibilityCoveragePct: 100.0,
        requiredBreakGlassAuditCoveragePct: 100.0,
        maxUnauditedBreakGlassInspections: 0,
        maxHiddenInspectionPaths: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when coverage regresses', () {
      const snapshot = UrkGovernanceInspectionSnapshot(
        observedGovernanceStrataCoveragePct: 75.0,
        observedSummaryVisibilityCoveragePct: 80.0,
        observedBreakGlassAuditCoveragePct: 90.0,
        observedUnauditedBreakGlassInspections: 0,
        observedHiddenInspectionPaths: 0,
      );
      const policy = UrkGovernanceInspectionPolicy(
        requiredGovernanceStrataCoveragePct: 100.0,
        requiredSummaryVisibilityCoveragePct: 100.0,
        requiredBreakGlassAuditCoveragePct: 100.0,
        maxUnauditedBreakGlassInspections: 0,
        maxHiddenInspectionPaths: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkGovernanceInspectionFailure
            .governanceStrataCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(UrkGovernanceInspectionFailure
            .summaryVisibilityCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(UrkGovernanceInspectionFailure
            .breakGlassAuditCoverageBelowThreshold),
      );
    });

    test('fails when unaudited or hidden inspection paths appear', () {
      const snapshot = UrkGovernanceInspectionSnapshot(
        observedGovernanceStrataCoveragePct: 100.0,
        observedSummaryVisibilityCoveragePct: 100.0,
        observedBreakGlassAuditCoveragePct: 100.0,
        observedUnauditedBreakGlassInspections: 1,
        observedHiddenInspectionPaths: 2,
      );
      const policy = UrkGovernanceInspectionPolicy(
        requiredGovernanceStrataCoveragePct: 100.0,
        requiredSummaryVisibilityCoveragePct: 100.0,
        requiredBreakGlassAuditCoveragePct: 100.0,
        maxUnauditedBreakGlassInspections: 0,
        maxHiddenInspectionPaths: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkGovernanceInspectionFailure
            .unauditedBreakGlassInspectionDetected),
      );
      expect(
        result.failures,
        contains(UrkGovernanceInspectionFailure.hiddenInspectionPathDetected),
      );
    });
  });
}
