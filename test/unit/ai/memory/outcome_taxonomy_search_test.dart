import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';

void main() {
  group('OutcomeTaxonomy search events', () {
    const taxonomy = OutcomeTaxonomy();

    test('classifies search_result_click as binary success', () {
      final signal = taxonomy.classify(
        eventType: 'search_result_click',
        parameters: const {'selected_item_id': 'spot-1'},
      );

      expect(signal.type, 'search_result_click');
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies search_result_no_action as zero behavioral shift', () {
      final signal = taxonomy.classify(
        eventType: 'search_result_no_action',
        parameters: const {},
      );

      expect(signal.type, 'search_result_no_action');
      expect(signal.category, OutcomeCategory.behavioral);
      expect(signal.value, 0.0);
    });

    test('classifies recommendation post-view abandonment as binary negative',
        () {
      final signal = taxonomy.classify(
        eventType: 'recommendation_post_view_abandonment',
        parameters: const {'days_absent': 4},
      );

      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 0.0);
    });

    test('classifies explicit_preference as binary positive', () {
      final signal = taxonomy.classify(
        eventType: 'explicit_preference',
        parameters: const {'category': 'nightlife'},
      );

      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });
  });
}
