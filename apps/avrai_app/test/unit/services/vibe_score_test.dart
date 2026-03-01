import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';

void main() {
  group('VibeScore', () {
    test('clamped() bounds all fields to 0..1', () {
      final score = const VibeScore(
        combined: 2.0,
        quantum: -1.0,
        knotTopological: 1.5,
        knotWeave: -0.2,
        breakdown: {
          'a': -5.0,
          'b': 5.0,
        },
      ).clamped();

      expect(score.combined, equals(1.0));
      expect(score.quantum, equals(0.0));
      expect(score.knotTopological, equals(1.0));
      expect(score.knotWeave, equals(0.0));
      expect(score.breakdown['a'], equals(0.0));
      expect(score.breakdown['b'], equals(1.0));
    });
  });
}
