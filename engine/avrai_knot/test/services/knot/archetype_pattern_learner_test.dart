import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/archetype_pattern_learner.dart';

void main() {
  group('ArchetypePatternLearner', () {
    late ArchetypePatternLearner learner;

    setUp(() {
      learner = ArchetypePatternLearner();
    });

    PersonalityKnot createTestKnot(int crossings, int writhe) {
      final now = DateTime.now();
      return PersonalityKnot(
        agentId: 'test_id',
        createdAt: now,
        lastUpdated: now,
        braidData: [],
        invariants: KnotInvariants(
          crossingNumber: crossings,
          writhe: writhe,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
          jonesPolynomial: [1.0, 2.0],
          alexanderPolynomial: [1.0],
        ),
      );
    }

    test('should derive an average archetype from positive encounters', () {
      // User syncs with two people
      learner.recordPositiveEncounter(createTestKnot(10, 5));
      learner.recordPositiveEncounter(createTestKnot(20, 15));

      final archetypes = learner.deriveArchetypes();

      expect(archetypes.length, equals(1));
      expect(
        archetypes[0].avgCrossingNumber,
        equals(15.0),
      ); // Average of 10 and 20
      expect(archetypes[0].avgWrithe, equals(10.0)); // Average of 5 and 15
      expect(archetypes[0].confidenceWeight, equals(0.2)); // 2 encounters * 0.1
    });

    test(
      'should return higher affinity for locations that match learned archetypes',
      () {
        final archetype = LearnedArchetype(
          label: 'Test Pattern',
          avgCrossingNumber: 15.0,
          avgWrithe: 10.0,
          baseJonesPolynomial: [],
          confidenceWeight: 1.0, // High confidence
        );

        // A coffee shop where the average patron has a knot of 15 crossings and 10 writhe
        final matchingLocationVibe = KnotInvariants(
          crossingNumber: 15,
          writhe: 10,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
          jonesPolynomial: [],
          alexanderPolynomial: [],
        );

        // A nightclub where the average patron has a knot of 30 crossings and -10 writhe
        final mismatchedLocationVibe = KnotInvariants(
          crossingNumber: 30,
          writhe: -10,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
          jonesPolynomial: [],
          alexanderPolynomial: [],
        );

        final matchingAffinity = learner.calculateLocationAffinity([
          archetype,
        ], matchingLocationVibe);
        final mismatchAffinity = learner.calculateLocationAffinity([
          archetype,
        ], mismatchedLocationVibe);

        // The matching location should have a perfect 1.0 affinity
        expect(matchingAffinity, closeTo(1.0, 0.001));

        // The mismatched location should have a much lower affinity
        expect(mismatchAffinity, lessThan(matchingAffinity));
        // Mismatch calculation:
        // crossDist = |15 - 30| = 15. Sim = 1 - 15/20 = 0.25
        // writheDist = |10 - (-10)| = 20. Sim = 1 - 20/20 = 0.0
        // avg = 0.125
        expect(mismatchAffinity, closeTo(0.125, 0.001));
      },
    );
  });
}
