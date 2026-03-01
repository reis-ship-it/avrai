import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/quantum/location_quantum_state.dart';
import 'package:avrai_core/models/user/unified_models.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('LocationQuantumState Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('fromLocation Factory', () {
      test('should create location quantum state from UnifiedLocation', () {
        const location = UnifiedLocation(
          latitude: 40.7128, // New York City
          longitude: -74.0060,
          city: 'New York',
          state: 'NY',
          country: 'USA',
        );

        final state = LocationQuantumState.fromLocation(location);

        expect(state.latitudeState, isNotEmpty);
        expect(state.longitudeState, isNotEmpty);
        expect(state.locationType, isA<double>());
        expect(state.accessibilityScore, isA<double>());
        expect(state.vibeLocationMatch, isA<double>());
        expect(state.atomicTimestamp, isA<AtomicTimestamp>());
        expect(state.stateVector, isNotEmpty);
      });

      test('should normalize latitude to [0, 1] range', () {
        const location = UnifiedLocation(
          latitude: 90.0, // North pole
          longitude: 0.0,
        );

        final state = LocationQuantumState.fromLocation(location);

        // Latitude 90 should normalize to 1.0
        expect(state.latitudeState[0], closeTo(1.0, 0.1));
      });

      test('should normalize longitude to [0, 1] range', () {
        const location = UnifiedLocation(
          latitude: 0.0,
          longitude: 180.0, // International date line
        );

        final state = LocationQuantumState.fromLocation(location);

        // Longitude 180 should normalize to 1.0
        expect(state.longitudeState[0], closeTo(1.0, 0.1));
      });

      test('should infer urban location type from city name', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          city: 'Downtown New York',
        );

        final state = LocationQuantumState.fromLocation(location);

        // Urban indicators should result in locationType close to 1.0
        expect(state.locationType, greaterThan(0.7));
      });

      test('should infer rural location type from address', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          address: 'Rural countryside farm',
        );

        final state = LocationQuantumState.fromLocation(location);

        // Rural indicators should result in locationType close to 0.0
        expect(state.locationType, lessThan(0.3));
      });

      test('should use provided location type when available', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(
          location,
          locationType: 0.8,
        );

        expect(state.locationType, 0.8);
      });

      test('should use provided accessibility score when available', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(
          location,
          accessibilityScore: 0.9,
        );

        expect(state.accessibilityScore, 0.9);
      });

      test('should use provided vibe location match when available', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(
          location,
          vibeLocationMatch: 0.85,
        );

        expect(state.vibeLocationMatch, 0.85);
      });
    });

    group('Quantum State Properties', () {
      test('should create quantum state with correct structure', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(location);

        // State vector should contain: lat (2), lon (2), type (1), accessibility (1), vibe (1) = 7 elements
        expect(state.stateVector.length, 7);
        expect(state.latitudeState.length, 2);
        expect(state.longitudeState.length, 2);
      });

      test('should have normalized quantum states', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(location);

        // Quantum states should be normalized (sum of squares ≈ 1)
        final latNorm = state.latitudeState[0] * state.latitudeState[0] +
            state.latitudeState[1] * state.latitudeState[1];
        expect(latNorm, closeTo(1.0, 0.1));

        final lonNorm = state.longitudeState[0] * state.longitudeState[0] +
            state.longitudeState[1] * state.longitudeState[1];
        expect(lonNorm, closeTo(1.0, 0.1));
      });
    });

    group('Location Compatibility Calculation', () {
      test('should calculate compatibility between identical locations', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final stateA = LocationQuantumState.fromLocation(location);
        final stateB = LocationQuantumState.fromLocation(location);

        final compatibility = stateA.locationCompatibility(stateB);

        // Identical locations should have high compatibility
        expect(compatibility, greaterThan(0.8));
      });

      test('should calculate compatibility between nearby locations', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130, // Very close
          longitude: -74.0062,
        );

        final stateA = LocationQuantumState.fromLocation(locationA);
        final stateB = LocationQuantumState.fromLocation(locationB);

        final compatibility = stateA.locationCompatibility(stateB);

        // Nearby locations should have high compatibility
        expect(compatibility, greaterThan(0.7));
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

        final stateA = LocationQuantumState.fromLocation(locationA);
        final stateB = LocationQuantumState.fromLocation(locationB);

        final compatibility = stateA.locationCompatibility(stateB);

        // Distant locations should have lower compatibility
        expect(compatibility, lessThan(0.5));
      });

      test('should handle inner product calculation correctly', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final stateA = LocationQuantumState.fromLocation(locationA);
        final stateB = LocationQuantumState.fromLocation(locationB);

        final innerProduct = stateA.innerProduct(stateB);
        final compatibility = stateA.locationCompatibility(stateB);

        // Compatibility should be inner product squared
        expect(compatibility, closeTo(innerProduct * innerProduct, 0.001));
      });
    });

    group('Normalization', () {
      test('should normalize state vector correctly', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(location);

        state.normalize();

        final normalizedNorm = state.stateVector.fold(
          0.0,
          (sum, val) => sum + val * val,
        );

        // After normalization, norm should be 1.0
        expect(normalizedNorm, closeTo(1.0, 0.001));
      });
    });

    group('Distance Calculation', () {
      test('should throw UnimplementedError for distance calculation', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130, // Very close
          longitude: -74.0062,
        );

        final state = LocationQuantumState.fromLocation(locationA);

        // Distance calculation requires original coordinates, not quantum states
        expect(
          () => state.distanceTo(locationB),
          throwsUnimplementedError,
        );
      });

      test('should use UnifiedLocation.distanceTo for actual distance', () {
        const locationA = UnifiedLocation(
          latitude: 40.7128, // New York
          longitude: -74.0060,
        );

        const locationB = UnifiedLocation(
          latitude: 40.7130, // Very close
          longitude: -74.0062,
        );

        // Use UnifiedLocation's distanceTo method for actual distance
        final distance = locationA.distanceTo(locationB);

        // Distance should be small (less than 1km for very close locations)
        expect(distance, lessThan(1000.0)); // In meters
      });
    });

    group('Edge Cases', () {
      test('should handle locations at poles', () {
        const location = UnifiedLocation(
          latitude: 90.0, // North pole
          longitude: 0.0,
        );

        final state = LocationQuantumState.fromLocation(location);

        expect(state.latitudeState, isNotEmpty);
        expect(state.longitudeState, isNotEmpty);
      });

      test('should handle locations at equator', () {
        const location = UnifiedLocation(
          latitude: 0.0,
          longitude: 0.0,
        );

        final state = LocationQuantumState.fromLocation(location);

        expect(state.latitudeState, isNotEmpty);
        expect(state.longitudeState, isNotEmpty);
      });

      test('should handle locations with missing city/address', () {
        const location = UnifiedLocation(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(location);

        // Should default to suburban (0.5)
        expect(state.locationType, 0.5);
      });

      test('should handle negative coordinates', () {
        const location = UnifiedLocation(
          latitude: -40.7128, // Southern hemisphere
          longitude: -74.0060,
        );

        final state = LocationQuantumState.fromLocation(location);

        expect(state.latitudeState, isNotEmpty);
        expect(state.longitudeState, isNotEmpty);
      });
    });
  });
}
