import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/misc/platform_phase.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for PlatformPhase model
void main() {
  group('PlatformPhase Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Phase Qualification', () {
      test('should qualify for phase when user count meets threshold', () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.bootstrap,
          userCountThreshold: 1000,
          saturationFactors: const SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(phase.qualifiesForPhase(1000), isTrue);
        expect(phase.qualifiesForPhase(1500), isTrue);
        expect(phase.qualifiesForPhase(999), isFalse);
      });
    });

    group('Category Multipliers', () {
      test('should return correct multipliers for known and unknown categories',
          () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          categoryMultipliers: const {
            'Coffee': 1.5,
            'Food': 1.2,
          },
          saturationFactors: const SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Test business logic: multiplier lookup
        expect(phase.getCategoryMultiplier('Coffee'), equals(1.5));
        expect(phase.getCategoryMultiplier('Food'), equals(1.2));
        expect(phase.getCategoryMultiplier('Unknown'), equals(1.0)); // Default
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested saturation factors correctly',
          () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          categoryMultipliers: const {'Coffee': 1.5},
          saturationFactors: const SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = phase.toJson();
        final restored = PlatformPhase.fromJson(json);

        // Test nested structure preserved (business logic)
        expect(restored.name, equals(PhaseName.growth));
        expect(restored.categoryMultipliers, equals({'Coffee': 1.5}));
        expect(restored.saturationFactors, isNotNull);
      });
    });

    group('Phase Name Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test(
          'should parse phase name from string with case handling and defaults',
          () {
        // Test business logic: string parsing with error handling
        expect(
          PhaseNameExtension.fromString('bootstrap'),
          equals(PhaseName.bootstrap),
        );
        expect(
          PhaseNameExtension.fromString('growth'),
          equals(PhaseName.growth),
        );
        expect(
          PhaseNameExtension.fromString('unknown'),
          equals(PhaseName.bootstrap), // Default
        );
      });
    });

    group('Saturation Factors', () {
      test(
          'should get multiplier based on saturation ratio and serialize correctly',
          () {
        // Test business logic: multiplier calculation and JSON serialization
        const factors = SaturationFactors();

        expect(factors.getMultiplierForSaturation(0.005), equals(0.8)); // Low
        expect(
            factors.getMultiplierForSaturation(0.015), equals(1.0)); // Medium
        expect(factors.getMultiplierForSaturation(0.025), equals(1.5)); // High
        expect(factors.getMultiplierForSaturation(0.035),
            equals(2.0)); // Very high

        // Test JSON serialization
        final json = factors.toJson();
        expect(json['baseMultiplier'], equals(1.0));
        expect(json['lowSaturationMultiplier'], equals(0.8));
        expect(json['highSaturationMultiplier'], equals(1.5));
      });
    });
  });
}
