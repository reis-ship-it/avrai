import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/implicit_feedback_signals.dart';

void main() {
  group('ImplicitFeedbackSignals', () {
    const resolver = ImplicitFeedbackSignals();

    test('classifies long dwell as positive implicit feedback', () {
      final signal = resolver.resolve(
        eventType: 'spot_view_duration',
        parameters: const {'duration_ms': 90000},
        context: const {},
      );

      expect(signal, isNotNull);
      expect(signal!.type, ImplicitFeedbackSignalType.dwellTimeOnEntityListing);
      expect(signal.polarity, ImplicitFeedbackPolarity.positive);
      expect(signal.strength, 1.5);
    });

    test('classifies scroll past without tap as weak negative signal', () {
      final signal = resolver.resolve(
        eventType: 'scroll_past_without_tap',
        parameters: const {},
        context: const {},
      );

      expect(signal, isNotNull);
      expect(signal!.type, ImplicitFeedbackSignalType.scrollPastWithoutTap);
      expect(signal.polarity, ImplicitFeedbackPolarity.negative);
      expect(signal.strength, 0.5);
    });

    test('requires recommendation context for chat-after-recommendation', () {
      final noContextSignal = resolver.resolve(
        eventType: 'message_community',
        parameters: const {},
        context: const {},
      );
      expect(noContextSignal, isNull);

      final withContextSignal = resolver.resolve(
        eventType: 'message_community',
        parameters: const {'after_recommendation': true},
        context: const {},
      );
      expect(withContextSignal, isNotNull);
      expect(
        withContextSignal!.type,
        ImplicitFeedbackSignalType.chatAfterRecommendation,
      );
      expect(withContextSignal.polarity, ImplicitFeedbackPolarity.positive);
    });

    test('supports alias events and duration_seconds fallback', () {
      final dwellSignal = resolver.resolve(
        eventType: 'entity_detail_duration',
        parameters: const {'duration_seconds': 61},
        context: const {},
      );
      expect(dwellSignal, isNotNull);
      expect(dwellSignal!.type,
          ImplicitFeedbackSignalType.dwellTimeOnEntityListing);

      final saveSignal = resolver.resolve(
        eventType: 'save_entity',
        parameters: const {},
        context: const {},
      );
      expect(saveSignal, isNotNull);
      expect(saveSignal!.type, ImplicitFeedbackSignalType.saveAction);

      final dismissSignal = resolver.resolve(
        eventType: 'dismiss_entity',
        parameters: const {},
        context: const {},
      );
      expect(dismissSignal, isNotNull);
      expect(dismissSignal!.type, ImplicitFeedbackSignalType.dismissAction);
    });

    test('allows chat-after-recommendation when recommendation id is present',
        () {
      final signal = resolver.resolve(
        eventType: 'message_friend',
        parameters: const {'recommendation_id': 'rec-1'},
        context: const {},
      );
      expect(signal, isNotNull);
      expect(signal!.type, ImplicitFeedbackSignalType.chatAfterRecommendation);
    });
  });
}
