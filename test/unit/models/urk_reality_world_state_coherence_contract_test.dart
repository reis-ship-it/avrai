import 'package:avrai/core/models/urk_reality_world_state_coherence_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkRealityWorldStateCoherenceValidator', () {
    const validator = UrkRealityWorldStateCoherenceValidator();

    test('passes when reality world-state coherence is healthy', () {
      const snapshot = UrkRealityWorldStateCoherenceSnapshot(
        observedPlaneConsistencyCoveragePct: 100.0,
        observedKnotStringConstraintCoveragePct: 100.0,
        observedCrossPlaneConflicts: 0,
        observedUnresolvedStateTransitions: 0,
      );
      const policy = UrkRealityWorldStateCoherencePolicy(
        requiredPlaneConsistencyCoveragePct: 100.0,
        requiredKnotStringConstraintCoveragePct: 100.0,
        maxCrossPlaneConflicts: 0,
        maxUnresolvedStateTransitions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when coherence coverage regresses', () {
      const snapshot = UrkRealityWorldStateCoherenceSnapshot(
        observedPlaneConsistencyCoveragePct: 93.0,
        observedKnotStringConstraintCoveragePct: 89.0,
        observedCrossPlaneConflicts: 0,
        observedUnresolvedStateTransitions: 0,
      );
      const policy = UrkRealityWorldStateCoherencePolicy(
        requiredPlaneConsistencyCoveragePct: 100.0,
        requiredKnotStringConstraintCoveragePct: 100.0,
        maxCrossPlaneConflicts: 0,
        maxUnresolvedStateTransitions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkRealityWorldStateCoherenceFailure
              .planeConsistencyCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkRealityWorldStateCoherenceFailure
              .knotStringConstraintCoverageBelowThreshold,
        ),
      );
    });

    test('fails when conflicts or unresolved transitions exist', () {
      const snapshot = UrkRealityWorldStateCoherenceSnapshot(
        observedPlaneConsistencyCoveragePct: 100.0,
        observedKnotStringConstraintCoveragePct: 100.0,
        observedCrossPlaneConflicts: 2,
        observedUnresolvedStateTransitions: 1,
      );
      const policy = UrkRealityWorldStateCoherencePolicy(
        requiredPlaneConsistencyCoveragePct: 100.0,
        requiredKnotStringConstraintCoveragePct: 100.0,
        maxCrossPlaneConflicts: 0,
        maxUnresolvedStateTransitions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkRealityWorldStateCoherenceFailure.crossPlaneConflictDetected),
      );
      expect(
        result.failures,
        contains(
          UrkRealityWorldStateCoherenceFailure.unresolvedStateTransitionDetected,
        ),
      );
    });
  });
}
