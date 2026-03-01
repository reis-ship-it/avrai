import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/quantum/saturation_metrics.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for SaturationMetrics model
void main() {
  group('SaturationMetrics Model Tests', () {
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

    group('Saturation Multiplier', () {
      test('should return correct multiplier based on saturation level', () {
        // Test business logic: multiplier calculation
        final lowSaturation = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 10,
          totalUserCount: 5000,
          saturationRatio: 0.002, // 0.2%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: const SaturationFactors(
            supplyRatio: 0.2,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.3,
          recommendation: SaturationRecommendation.decrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );
        final mediumSaturation = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 75,
          totalUserCount: 5000,
          saturationRatio: 0.015, // 1.5%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: const SaturationFactors(
            supplyRatio: 0.5,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );
        final highSaturation = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 150,
          totalUserCount: 5000,
          saturationRatio: 0.03, // 3%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: const SaturationFactors(
            supplyRatio: 0.8,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.7,
          recommendation: SaturationRecommendation.increase,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(lowSaturation.getSaturationMultiplier(), equals(0.8));
        expect(mediumSaturation.getSaturationMultiplier(), equals(1.0));
        expect(highSaturation.getSaturationMultiplier(), equals(2.0));
      });
    });

    group('Oversaturation Checks', () {
      test('should detect oversaturation', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 200,
          totalUserCount: 5000,
          saturationRatio: 0.04,
          qualityScore: 0.7,
          growthRate: 15.0,
          competitionLevel: 0.8,
          marketDemand: 0.4,
          factors: const SaturationFactors(
            supplyRatio: 0.9,
            qualityDistribution: 0.6,
            utilizationRate: 0.5,
            demandSignal: 0.3,
            growthVelocity: 0.8,
            geographicDistribution: 0.7,
          ),
          saturationScore: 0.75,
          recommendation: SaturationRecommendation.significantIncrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.isOversaturated, isTrue);
      });

      test('should detect need for more experts', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 20,
          totalUserCount: 5000,
          saturationRatio: 0.004,
          qualityScore: 0.9,
          growthRate: 2.0,
          competitionLevel: 0.2,
          marketDemand: 0.8,
          factors: const SaturationFactors(
            supplyRatio: 0.2,
            qualityDistribution: 0.9,
            utilizationRate: 0.9,
            demandSignal: 0.8,
            growthVelocity: 0.1,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.25,
          recommendation: SaturationRecommendation.decrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.needsMoreExperts, isTrue);
      });
    });

    group('Saturation Factors', () {
      test('should calculate saturation score within valid range', () {
        // Test business logic: score calculation
        const factors = SaturationFactors(
          supplyRatio: 0.5,
          qualityDistribution: 0.8,
          utilizationRate: 0.7,
          demandSignal: 0.6,
          growthVelocity: 0.3,
          geographicDistribution: 0.4,
        );

        final score = factors.calculateSaturationScore();
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        const factors = SaturationFactors(
          supplyRatio: 0.5,
          qualityDistribution: 0.8,
          utilizationRate: 0.7,
          demandSignal: 0.6,
          growthVelocity: 0.3,
          geographicDistribution: 0.4,
        );

        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.85,
          growthRate: 10.0,
          competitionLevel: 0.6,
          marketDemand: 0.7,
          factors: factors,
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        final json = metrics.toJson();
        final restored = SaturationMetrics.fromJson(json);

        // Test critical business fields preserved
        expect(restored.getSaturationMultiplier(),
            equals(metrics.getSaturationMultiplier()));
        expect(restored.isOversaturated, equals(metrics.isOversaturated));
      });
    });

    group('Saturation Recommendation Extension', () {
      test('should parse recommendation from string with defaults', () {
        // Test business logic: string parsing with error handling
        expect(SaturationRecommendationExtension.fromString('decrease'),
            equals(SaturationRecommendation.decrease));
        expect(SaturationRecommendationExtension.fromString('maintain'),
            equals(SaturationRecommendation.maintain));
        expect(SaturationRecommendationExtension.fromString('unknown'),
            equals(SaturationRecommendation.maintain)); // Default
      });
    });
  });
}
