import 'package:avrai/core/services/calling_score/formula_ab_testing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormulaABTestingService', () {
    const service = FormulaABTestingService();

    test('stable assignment is deterministic for same subject', () {
      final first = service.isTreatmentGroup(stableSubjectId: 'agent-abc');
      final second = service.isTreatmentGroup(stableSubjectId: 'agent-abc');
      expect(first, equals(second));
    });

    test('calculates group metrics and comparison improvements', () {
      final control = service.calculateGroupMetrics([
        {
          'calling_score': 0.4,
          'is_called': false,
          'outcome_type': 'negative',
          'outcome_score': 0.1,
        },
        {
          'calling_score': 0.5,
          'is_called': true,
          'outcome_type': 'positive',
          'outcome_score': 0.6,
        },
      ]);

      final treatment = service.calculateGroupMetrics([
        {
          'calling_score': 0.8,
          'is_called': true,
          'outcome_type': 'positive',
          'outcome_score': 0.9,
        },
        {
          'calling_score': 0.7,
          'is_called': true,
          'outcome_type': 'positive',
          'outcome_score': 0.8,
        },
      ]);

      final comparison = service.compare(
        controlGroup: control,
        treatmentGroup: treatment,
      );

      expect(control.totalOutcomes, equals(2));
      expect(treatment.totalOutcomes, equals(2));
      expect(comparison.scoreImprovement, greaterThan(0));
      expect(comparison.positiveOutcomeRateImprovement, greaterThan(0));
      expect(comparison.outcomeScoreImprovement, greaterThan(0));
    });
  });
}
