import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/dna_encoder_service.dart';

void main() {
  group('DnaEncoderService', () {
    late DnaEncoderService encoder;

    setUp(() {
      encoder = DnaEncoderService();
    });

    PersonalityKnot createTestKnot({
      bool withPhysics = true,
      bool withOptionals = true,
    }) {
      final now = DateTime.now().toUtc();
      // Ensure milliseconds are stripped for exact equality test after roundtrip
      final truncatedNow = DateTime.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch,
        isUtc: true,
      );

      return PersonalityKnot(
        agentId: 'user_12345_test_agent_id_that_is_somewhat_long',
        createdAt: truncatedNow,
        lastUpdated: truncatedNow,
        braidData: [1.0, 2.5, -3.1, 0.0, 4.2],
        physics: withPhysics
            ? KnotPhysics(energy: 12.345, stability: 0.987, length: 55.5)
            : null,
        invariants: KnotInvariants(
          crossingNumber: 8,
          writhe: -2,
          signature: 4,
          bridgeNumber: 3,
          braidIndex: 4,
          determinant: 17,
          unknottingNumber: withOptionals ? 2 : null,
          arfInvariant: withOptionals ? 1 : null,
          hyperbolicVolume: withOptionals ? 3.14159 : null,
          jonesPolynomial: [1.0, -1.0, 2.0, -2.0, 1.0],
          alexanderPolynomial: [1.0, -3.0, 5.0, -3.0, 1.0],
          homflyPolynomial: withOptionals ? [1.0, 0.0, -1.0, 2.0] : null,
        ),
      );
    }

    test('should serialize and deserialize correctly (round-trip)', () {
      final original = createTestKnot(withPhysics: true, withOptionals: true);

      // Act
      final bytes = encoder.encode(original);
      final restored = encoder.decode(bytes);

      // Assert
      expect(restored.agentId, equals(original.agentId));
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        equals(original.createdAt.millisecondsSinceEpoch),
      );
      expect(
        restored.lastUpdated.millisecondsSinceEpoch,
        equals(original.lastUpdated.millisecondsSinceEpoch),
      );

      // Verify Braid Data
      expect(restored.braidData.length, equals(original.braidData.length));
      for (int i = 0; i < restored.braidData.length; i++) {
        expect(restored.braidData[i], closeTo(original.braidData[i], 0.001));
      }

      // Verify Physics
      expect(restored.physics, isNotNull);
      expect(
        restored.physics!.energy,
        closeTo(original.physics!.energy, 0.001),
      );
      expect(
        restored.physics!.stability,
        closeTo(original.physics!.stability, 0.001),
      );
      expect(
        restored.physics!.length,
        closeTo(original.physics!.length, 0.001),
      );

      // Verify Invariants
      final origInv = original.invariants;
      final restInv = restored.invariants;
      expect(restInv.crossingNumber, equals(origInv.crossingNumber));
      expect(restInv.writhe, equals(origInv.writhe));
      expect(restInv.signature, equals(origInv.signature));
      expect(restInv.bridgeNumber, equals(origInv.bridgeNumber));
      expect(restInv.braidIndex, equals(origInv.braidIndex));
      expect(restInv.determinant, equals(origInv.determinant));
      expect(restInv.unknottingNumber, equals(origInv.unknottingNumber));
      expect(restInv.arfInvariant, equals(origInv.arfInvariant));
      expect(
        restInv.hyperbolicVolume,
        closeTo(origInv.hyperbolicVolume!, 0.001),
      );

      // Verify Polynomials
      expect(
        restInv.jonesPolynomial.length,
        equals(origInv.jonesPolynomial.length),
      );
      for (int i = 0; i < restInv.jonesPolynomial.length; i++) {
        expect(
          restInv.jonesPolynomial[i],
          closeTo(origInv.jonesPolynomial[i], 0.001),
        );
      }

      expect(
        restInv.alexanderPolynomial.length,
        equals(origInv.alexanderPolynomial.length),
      );
      for (int i = 0; i < restInv.alexanderPolynomial.length; i++) {
        expect(
          restInv.alexanderPolynomial[i],
          closeTo(origInv.alexanderPolynomial[i], 0.001),
        );
      }

      expect(
        restInv.homflyPolynomial!.length,
        equals(origInv.homflyPolynomial!.length),
      );
      for (int i = 0; i < restInv.homflyPolynomial!.length; i++) {
        expect(
          restInv.homflyPolynomial![i],
          closeTo(origInv.homflyPolynomial![i], 0.001),
        );
      }
    });

    test('should correctly round-trip when optional fields are null', () {
      final original = createTestKnot(withPhysics: false, withOptionals: false);

      // Act
      final bytes = encoder.encode(original);
      final restored = encoder.decode(bytes);

      // Assert
      expect(restored.physics, isNull);
      expect(restored.invariants.unknottingNumber, isNull);
      expect(restored.invariants.arfInvariant, isNull);
      expect(restored.invariants.hyperbolicVolume, isNull);
      expect(restored.invariants.homflyPolynomial, isNull);
    });

    test('should serialize and deserialize from hex string', () {
      final original = createTestKnot();

      // Act
      final hexString = encoder.encodeToHex(original);
      final restored = encoder.decodeFromHex(hexString);

      // Assert
      expect(restored.agentId, equals(original.agentId));
      expect(
        restored.invariants.crossingNumber,
        equals(original.invariants.crossingNumber),
      );
    });

    test(
      'should compress knot strictly under 2KB (2048 bytes) for BLE compatibility',
      () {
        // Create a heavily populated knot with realistic sizes
        final now = DateTime.now();
        final heavyKnot = PersonalityKnot(
          agentId:
              'a_very_long_agent_id_that_might_be_used_in_production_environments_1234567890',
          createdAt: now,
          lastUpdated: now,
          braidData: List.generate(
            50,
            (i) => i * 0.5,
          ), // realistic braid size for complex knots
          physics: KnotPhysics(energy: 1.0, stability: 2.0, length: 3.0),
          invariants: KnotInvariants(
            crossingNumber: 15,
            writhe: -5,
            signature: 6,
            bridgeNumber: 4,
            braidIndex: 5,
            determinant: 45,
            unknottingNumber: 3,
            arfInvariant: 1,
            hyperbolicVolume: 4.567,
            jonesPolynomial: List.generate(
              15,
              (i) => i.toDouble(),
            ), // typical polynomial degree ~ crossing number
            alexanderPolynomial: List.generate(15, (i) => i.toDouble()),
            homflyPolynomial: List.generate(15, (i) => i.toDouble()),
          ),
        );

        final bytes = encoder.encode(heavyKnot);

        // It should be extremely small, far below 2KB
        expect(bytes.length, lessThan(2048));

        // With realistic sizes, it should be well under 1000 bytes
        expect(bytes.length, lessThan(1000));
      },
    );

    test('should throw FormatException for invalid hex string', () {
      expect(
        () => encoder.decodeFromHex('invalid_hex!'),
        throwsFormatException,
      );
      expect(
        () => encoder.decodeFromHex('123'),
        throwsFormatException,
      ); // Odd length
    });
  });
}
