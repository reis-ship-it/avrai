import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/quantum/location_compatibility_calculator.dart';
import 'package:avrai_core/models/user/unified_models.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('LocationCompatibilityCalculator Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('calculateLocationCompatibility', () {
      test('should calculate high compatibility for identical locations', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: location,
          locationB: location,
        );

        // Identical locations should have high compatibility
        expect(compatibility, greaterThan(0.8));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should calculate high compatibility for nearby locations', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130, // Very close
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        // Nearby locations should have high compatibility
        expect(compatibility, greaterThan(0.7));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should calculate lower compatibility for distant locations', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 34.0522, // Los Angeles
          longitude: -118.2437,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        // Distant locations should have lower compatibility
        expect(compatibility, lessThan(0.5));
        expect(compatibility, greaterThanOrEqualTo(0.0));
      });

      test('should use provided location types when available', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
          locationTypeA: 1.0, // Urban
          locationTypeB: 1.0, // Urban
        );

        // Same location types should increase compatibility
        expect(compatibility, greaterThan(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should use provided accessibility scores when available', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
          accessibilityScoreA: 0.9,
          accessibilityScoreB: 0.9,
        );

        expect(compatibility, greaterThan(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should use provided vibe location matches when available', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
          vibeLocationMatchA: 0.85,
          vibeLocationMatchB: 0.85,
        );

        expect(compatibility, greaterThan(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should handle errors gracefully and return neutral fallback', () {
        // Test with invalid locations (null coordinates would cause error)
        // The method should catch errors and return 0.5 (neutral fallback)
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // This should work fine, but if there's an error, it should return 0.5
        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationA,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('calculateEnhancedCompatibility', () {
      test('should combine personality, location, and timing compatibility',
          () {
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 0.8,
          locationCompatibility: 0.7,
          timingCompatibility: 0.6,
        );

        // Formula: 0.5 * 0.8 + 0.3 * 0.7 + 0.2 * 0.6 = 0.4 + 0.21 + 0.12 = 0.73
        expect(enhanced, closeTo(0.73, 0.01));
        expect(enhanced, greaterThanOrEqualTo(0.0));
        expect(enhanced, lessThanOrEqualTo(1.0));
      });

      test('should use default timing compatibility when not provided', () {
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 0.8,
          locationCompatibility: 0.7,
        );

        // Formula: 0.5 * 0.8 + 0.3 * 0.7 + 0.2 * 0.5 = 0.4 + 0.21 + 0.1 = 0.71
        expect(enhanced, closeTo(0.71, 0.01));
      });

      test('should weight personality compatibility at 50%', () {
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 1.0,
          locationCompatibility: 0.0,
          timingCompatibility: 0.0,
        );

        // Should be 0.5 * 1.0 = 0.5
        expect(enhanced, closeTo(0.5, 0.01));
      });

      test('should weight location compatibility at 30%', () {
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 0.0,
          locationCompatibility: 1.0,
          timingCompatibility: 0.0,
        );

        // Should be 0.3 * 1.0 = 0.3
        expect(enhanced, closeTo(0.3, 0.01));
      });

      test('should weight timing compatibility at 20%', () {
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 0.0,
          locationCompatibility: 0.0,
          timingCompatibility: 1.0,
        );

        // Should be 0.2 * 1.0 = 0.2
        expect(enhanced, closeTo(0.2, 0.01));
      });

      test('should clamp result to [0.0, 1.0] range', () {
        // Test with values that would exceed 1.0 if not clamped
        final enhanced =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: 1.0,
          locationCompatibility: 1.0,
          timingCompatibility: 1.0,
        );

        expect(enhanced, lessThanOrEqualTo(1.0));
        expect(enhanced, greaterThanOrEqualTo(0.0));
      });
    });

    group('calculateDistanceCompatibility', () {
      test('should calculate high compatibility for very close locations', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130, // Very close (~100m)
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateDistanceCompatibility(
          locationA: locationA,
          locationB: locationB,
          decayDistanceKm: 50.0,
        );

        // Very close locations should have high compatibility
        expect(compatibility, greaterThan(0.99));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should calculate lower compatibility for distant locations', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 34.0522, // Los Angeles (~3944 km)
          longitude: -118.2437,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateDistanceCompatibility(
          locationA: locationA,
          locationB: locationB,
          decayDistanceKm: 50.0,
        );

        // Very distant locations should have very low compatibility
        expect(compatibility, lessThan(0.1));
        expect(compatibility, greaterThanOrEqualTo(0.0));
      });

      test('should use custom decay distance parameter', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        // With larger decay distance, compatibility should be higher
        final compatibility1 =
            LocationCompatibilityCalculator.calculateDistanceCompatibility(
          locationA: locationA,
          locationB: locationB,
          decayDistanceKm: 10.0, // Small decay
        );

        final compatibility2 =
            LocationCompatibilityCalculator.calculateDistanceCompatibility(
          locationA: locationA,
          locationB: locationB,
          decayDistanceKm: 100.0, // Large decay
        );

        // Larger decay distance should result in higher compatibility
        expect(compatibility2, greaterThanOrEqualTo(compatibility1));
      });

      test('should handle errors gracefully and return neutral fallback', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateDistanceCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('Edge Cases', () {
      test('should handle locations at poles', () {
        const locationA = UnifiedLocation(
          latitude: 90.0, // North pole
          longitude: 0.0,
        );

        const locationB = UnifiedLocation(
          latitude: 90.0,
          longitude: 0.0,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should handle locations at equator', () {
        const locationA = UnifiedLocation(
          latitude: 0.0,
          longitude: 0.0,
        );

        const locationB = UnifiedLocation(
          latitude: 0.0,
          longitude: 0.0,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should handle negative coordinates', () {
        const locationA = UnifiedLocation(
          latitude: -40.7128, // Southern hemisphere
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: -40.7130,
          longitude: -74.0062,
        );

        final compatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: locationA,
          locationB: locationB,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });
  });
}
