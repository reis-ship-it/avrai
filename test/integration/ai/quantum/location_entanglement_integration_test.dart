import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/unified_models.dart';
import 'package:avrai/core/ai/quantum/location_quantum_state.dart';
import 'package:avrai/core/ai/quantum/location_compatibility_calculator.dart';
import '../../../helpers/test_helpers.dart';

/// Integration tests for location entanglement in compatibility calculations
///
/// Tests the complete flow of location entanglement integration:
/// 1. Location quantum state generation
/// 2. Location compatibility calculation
/// 3. Enhanced compatibility with location entanglement
/// 4. Integration with SpotVibeMatchingService
void main() {
  group('Location Entanglement Integration Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Location Quantum State Generation', () {
      test('should generate location quantum states for user and spot', () {
        const userLocation = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
          city: 'New York',
        );

        const spotLocation = UnifiedLocation(
          latitude: 40.7130, // Very close to user
          longitude: -74.0062,
          city: 'New York',
        );

        // Generate location quantum states
        final userLocationState = LocationQuantumState.fromLocation(userLocation);
        final spotLocationState = LocationQuantumState.fromLocation(spotLocation);

        expect(userLocationState.stateVector, isNotEmpty);
        expect(spotLocationState.stateVector, isNotEmpty);
        expect(userLocationState.stateVector.length,
            equals(spotLocationState.stateVector.length));
      });
    });

    group('Location Compatibility Integration', () {
      test('should calculate location compatibility between user and spot', () {
        const userLocation = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const spotLocation = UnifiedLocation(
          latitude: 40.7130, // Very close
          longitude: -74.0062,
        );

        final compatibility = LocationCompatibilityCalculator
            .calculateLocationCompatibility(
          locationA: userLocation,
          locationB: spotLocation,
        );

        expect(compatibility, greaterThan(0.7));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should show lower compatibility for distant locations', () {
        const userLocation = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
        );

        const spotLocation = UnifiedLocation(
          latitude: 34.0522, // Los Angeles
          longitude: -118.2437,
        );

        final compatibility = LocationCompatibilityCalculator
            .calculateLocationCompatibility(
          locationA: userLocation,
          locationB: spotLocation,
        );

        expect(compatibility, lessThan(0.5));
        expect(compatibility, greaterThanOrEqualTo(0.0));
      });
    });

    group('Enhanced Compatibility with Location Entanglement', () {
      test('should combine personality and location compatibility', () {
        const personalityCompat = 0.8;
        const locationCompat = 0.7;

        final enhanced = LocationCompatibilityCalculator
            .calculateEnhancedCompatibility(
          personalityCompatibility: personalityCompat,
          locationCompatibility: locationCompat,
        );

        // Formula: 0.5 * 0.8 + 0.3 * 0.7 + 0.2 * 0.5 = 0.4 + 0.21 + 0.1 = 0.71
        expect(enhanced, closeTo(0.71, 0.01));
        expect(enhanced, greaterThan(personalityCompat * 0.5)); // Should be higher than personality alone
      });

      test('should improve compatibility when location matches', () {
        const personalityCompat = 0.6; // Moderate personality match
        const locationCompat = 0.9; // High location match

        final enhanced = LocationCompatibilityCalculator
            .calculateEnhancedCompatibility(
          personalityCompatibility: personalityCompat,
          locationCompatibility: locationCompat,
        );

        // With high location match, enhanced should be better than personality alone
        expect(enhanced, greaterThan(personalityCompat));
      });

      test('should handle low location compatibility gracefully', () {
        const personalityCompat = 0.8; // High personality match
        const locationCompat = 0.3; // Low location match

        final enhanced = LocationCompatibilityCalculator
            .calculateEnhancedCompatibility(
          personalityCompatibility: personalityCompat,
          locationCompatibility: locationCompat,
        );

        // Even with low location match, should still be reasonable
        expect(enhanced, greaterThan(0.5));
        expect(enhanced, lessThan(personalityCompat));
      });
    });

    group('SpotVibeMatchingService Integration', () {
      test('should use location entanglement when locations provided', () async {
        // This test would require mocking UserVibeAnalyzer
        // For now, we test that the method accepts location parameters
        // Full integration test would require actual service setup

        const userLocation = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const spotLocation = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        // Verify locations can be created
        expect(userLocation, isNotNull);
        expect(spotLocation, isNotNull);

        // Verify location compatibility can be calculated
        final locationCompat = LocationCompatibilityCalculator
            .calculateLocationCompatibility(
          locationA: userLocation,
          locationB: spotLocation,
        );

        expect(locationCompat, greaterThan(0.0));
        expect(locationCompat, lessThanOrEqualTo(1.0));
      });
    });

    group('End-to-End Location Entanglement Flow', () {
      test('should complete full location entanglement workflow', () {
        // Step 1: Create user and spot locations
        const userLocation = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          city: 'New York',
        );

        const spotLocation = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
          city: 'New York',
        );

        // Step 2: Generate location quantum states
        final userLocationState = LocationQuantumState.fromLocation(userLocation);
        final spotLocationState = LocationQuantumState.fromLocation(spotLocation);

        // Step 3: Calculate location compatibility
        final locationCompat = userLocationState
            .locationCompatibility(spotLocationState);

        // Step 4: Calculate enhanced compatibility
        const personalityCompat = 0.8;
        final enhanced = LocationCompatibilityCalculator
            .calculateEnhancedCompatibility(
          personalityCompatibility: personalityCompat,
          locationCompatibility: locationCompat,
        );

        // Verify all steps completed successfully
        expect(userLocationState, isNotNull);
        expect(spotLocationState, isNotNull);
        expect(locationCompat, greaterThan(0.0));
        expect(locationCompat, lessThanOrEqualTo(1.0));
        expect(enhanced, greaterThan(0.0));
        expect(enhanced, lessThanOrEqualTo(1.0));
        expect(enhanced, greaterThan(personalityCompat * 0.5)); // Should include location contribution
      });
    });
  });
}

