import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/deterministic_matcher_service.dart';

void main() {
  group('DeterministicMatcherService', () {
    late DeterministicMatcherService matcher;

    setUp(() {
      matcher = DeterministicMatcherService();
    });

    PersonalityKnot createTestKnot({
      required int crossingNumber,
      required int writhe,
      required int signature,
      required List<double> jones,
      required List<double> alexander,
    }) {
      final now = DateTime.now();
      return PersonalityKnot(
        agentId: 'test_agent',
        createdAt: now,
        lastUpdated: now,
        braidData: [],
        invariants: KnotInvariants(
          crossingNumber: crossingNumber,
          writhe: writhe,
          signature: signature,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
          jonesPolynomial: jones,
          alexanderPolynomial: alexander,
        ),
      );
    }

    test('should return 1.0 for perfectly identical knots', () {
      final knotA = createTestKnot(
        crossingNumber: 5,
        writhe: 2,
        signature: 1,
        jones: [1.0, 2.0, -1.0],
        alexander: [2.0, -3.0, 2.0],
      );

      final score = matcher.calculateVibeMatch(knotA, knotA);
      
      expect(score, closeTo(1.0, 0.001));
    });

    test('should heavily penalize radically different polynomial vectors', () {
      final knotA = createTestKnot(
        crossingNumber: 5,
        writhe: 2,
        signature: 1,
        jones: [1.0, 1.0, 1.0],
        alexander: [1.0, 1.0],
      );

      final knotB = createTestKnot(
        crossingNumber: 5, // Same scalars to isolate polynomial difference
        writhe: 2,
        signature: 1,
        jones: [-1.0, -1.0, -1.0], // Exactly opposite vectors (-1 cosine similarity)
        alexander: [-1.0, -1.0],   // Exactly opposite vectors
      );

      final score = matcher.calculateVibeMatch(knotA, knotB);
      
      // Scalar is 1.0 (weight 0.3)
      // Jones is 0.0 (weight 0.35) due to (cosine + 1) / 2 mapping
      // Alexander is 0.0 (weight 0.35)
      // Total expected: 0.3
      expect(score, closeTo(0.3, 0.001));
    });

    test('should degrade gracefully with differing scalar invariants', () {
      final knotA = createTestKnot(
        crossingNumber: 5,
        writhe: 2,
        signature: 1,
        jones: [1.0, 2.0], // Same polynomials to isolate scalar difference
        alexander: [2.0, -3.0],
      );

      final knotB = createTestKnot(
        crossingNumber: 15, // Differs by 10 (max 20, so 0.5 similarity)
        writhe: 12,         // Differs by 10 (max 20, so 0.5 similarity)
        signature: 6,       // Differs by 5 (max 10, so 0.5 similarity)
        jones: [1.0, 2.0],
        alexander: [2.0, -3.0],
      );

      final score = matcher.calculateVibeMatch(knotA, knotB);
      
      // Expected scalar sim: (0.5 * 0.4) + (0.5 * 0.4) + (0.5 * 0.2) = 0.5
      // Jones = 1.0 (weight 0.35)
      // Alexander = 1.0 (weight 0.35)
      // Total: (0.5 * 0.3) + 0.35 + 0.35 = 0.85
      
      expect(score, closeTo(0.85, 0.001));
    });

    test('should handle arrays of different lengths gracefully by zero-padding', () {
      final knotA = createTestKnot(
        crossingNumber: 5, writhe: 0, signature: 0,
        jones: [1.0, 2.0, 3.0], 
        alexander: [1.0],
      );

      final knotB = createTestKnot(
        crossingNumber: 5, writhe: 0, signature: 0,
        jones: [1.0], // Shorter
        alexander: [1.0, 0.0, 0.0, 0.0], // Longer
      );

      // Should not throw range errors
      final score = matcher.calculateVibeMatch(knotA, knotB);
      expect(score, inInclusiveRange(0.0, 1.0));
    });

    test('should execute extremely fast (simulating zero battery drain)', () {
      final knotA = createTestKnot(
        crossingNumber: 15, writhe: 5, signature: 3,
        jones: List.generate(50, (i) => i.toDouble()),
        alexander: List.generate(50, (i) => -i.toDouble()),
      );
      
      final knotB = createTestKnot(
        crossingNumber: 12, writhe: -2, signature: 1,
        jones: List.generate(50, (i) => i * 1.5),
        alexander: List.generate(50, (i) => i * 0.5),
      );

      final stopwatch = Stopwatch()..start();
      
      // Run 1000 times to get a measurable duration
      for (int i = 0; i < 1000; i++) {
        matcher.calculateVibeMatch(knotA, knotB);
      }
      
      stopwatch.stop();
      
      // 1000 math comparisons should easily take less than 100ms
      // (Proving it takes ~0.1ms or less per calculation)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
