import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';

void main() {
  group('OutcomeTaxonomy asymmetric loss amplification', () {
    const taxonomy = OutcomeTaxonomy();

    test('doubles effective training weight for negative binary outcomes', () {
      final signal = taxonomy.classify(
        eventType: 'explicit_rejection',
        parameters: const {'signal_weight': 5.0},
      );

      expect(signal.category, OutcomeCategory.binary);
      expect(signal.metadata['negative_outcome_amplified'], isTrue);
      expect(signal.metadata['base_signal_weight'], 5.0);
      expect(signal.metadata['asymmetric_loss_factor'], 2.0);
      expect(signal.metadata['effective_training_weight'], 10.0);
    });

    test('applies 1-star vs 5-star asymmetric weighting at 10x base signal',
        () {
      final negative = taxonomy.classify(
        eventType: 'feedback_rating',
        parameters: const {'rating': 1},
      );
      final positive = taxonomy.classify(
        eventType: 'feedback_rating',
        parameters: const {'rating': 5},
      );

      expect(negative.metadata['base_signal_weight'], 10.0);
      expect(negative.metadata['negative_outcome_amplified'], isTrue);
      expect(negative.metadata['effective_training_weight'], 20.0);

      expect(positive.metadata['base_signal_weight'], 10.0);
      expect(positive.metadata['negative_outcome_amplified'], isFalse);
      expect(positive.metadata['effective_training_weight'], 10.0);
    });

    test('keeps neutral/positive outcomes at base weight', () {
      final signal = taxonomy.classify(
        eventType: 'return_visit_within_days',
        parameters: const {'days': 7},
      );

      expect(signal.metadata['negative_outcome_amplified'], isFalse);
      expect(signal.metadata['base_signal_weight'], 8.0);
      expect(signal.metadata['effective_training_weight'], 8.0);
    });
  });
}
