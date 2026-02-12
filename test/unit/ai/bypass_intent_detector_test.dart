/// Unit tests for BypassIntentDetector (RAG-as-answer Phase 4).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/bypass_intent_detector.dart';

void main() {
  group('BypassIntentDetector', () {
    late BypassIntentDetector detector;

    setUp(() {
      detector = BypassIntentDetector();
    });

    test('bypassRequested false for empty message', () {
      expect(detector.bypassRequested(''), isFalse);
    });

    test('bypassRequested true for tell me more', () {
      expect(
        detector.bypassRequested('Tell me more'),
        isTrue,
      );
      expect(
        detector.bypassRequested('Can you tell me more about that?'),
        isTrue,
      );
    });

    test('bypassRequested true for continue', () {
      expect(detector.bypassRequested('Continue'), isTrue);
      expect(detector.bypassRequested('Go on'), isTrue);
    });

    test('bypassRequested true for short follow-ups', () {
      expect(detector.bypassRequested('and?'), isTrue);
      expect(detector.bypassRequested('more?'), isTrue);
    });

    test('bypassRequested false for normal message', () {
      expect(
        detector.bypassRequested('What places do I like?'),
        isFalse,
      );
    });

    test(
        'bypassRequested true for new phrases dig deeper, expand further, give me more',
        () {
      expect(detector.bypassRequested('Dig deeper'), isTrue);
      expect(detector.bypassRequested('Expand further'), isTrue);
      expect(detector.bypassRequested('Give me more'), isTrue);
      expect(detector.bypassRequested('Can you dig deeper?'), isTrue);
    });

    test('bypassRequested true for keep going alone or short follow-up', () {
      expect(detector.bypassRequested('Keep going'), isTrue);
      expect(detector.bypassRequested('Keep going!'), isTrue);
      expect(detector.bypassRequested('keep going.'), isTrue);
      expect(
        detector.bypassRequested('keep going', lastAssistantMessage: 'Prior'),
        isTrue,
      );
    });

    test('bypassRequested false for keep going in longer non-follow-up context',
        () {
      expect(
        detector.bypassRequested('I want to keep going to the gym'),
        isFalse,
      );
      expect(
        detector.bypassRequested('We should keep going with the project'),
        isFalse,
      );
    });
  });
}
