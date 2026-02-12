// Location and Timing Quantum State Service Tests
//
// Tests for Phase 19 Section 19.3: Location and Timing Quantum States
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/unified_location_data.dart';

void main() {
  group('LocationTimingQuantumStateService', () {
    late LocationTimingQuantumStateService service;

    setUp(() {
      service = LocationTimingQuantumStateService();
    });

    test('should create location quantum state from UnifiedLocationData', () async {
      const location = UnifiedLocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        address: 'Downtown Manhattan',
      );

      final locationState = await service.createLocationQuantumState(
        location: location,
      );

      expect(locationState.latitudeQuantumState, greaterThanOrEqualTo(0.0));
      expect(locationState.latitudeQuantumState, lessThanOrEqualTo(1.0));
      expect(locationState.longitudeQuantumState, greaterThanOrEqualTo(0.0));
      expect(locationState.longitudeQuantumState, lessThanOrEqualTo(1.0));
      expect(locationState.locationType, isA<String>());
      expect(locationState.accessibilityScore, greaterThanOrEqualTo(0.0));
      expect(locationState.accessibilityScore, lessThanOrEqualTo(1.0));
      expect(locationState.vibeLocationMatch, greaterThanOrEqualTo(0.0));
      expect(locationState.vibeLocationMatch, lessThanOrEqualTo(1.0));
    });

    test('should infer urban location type from city/address', () async {
      const location = UnifiedLocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        address: 'Downtown Manhattan',
      );

      final locationState = await service.createLocationQuantumState(
        location: location,
      );

      expect(locationState.locationType, equals('urban'));
    });

    test('should create timing quantum state from preferences', () async {
      final timingState = await service.createTimingQuantumState(
        timeOfDayPreference: 0.7, // Evening preference
        dayOfWeekPreference: 0.8, // Weekend preference
        frequencyPreference: 0.6, // Moderate frequency
        durationPreference: 0.5, // Medium duration
        timingVibeMatch: 0.75,
      );

      expect(timingState.timeOfDayPreference, equals(0.7));
      expect(timingState.dayOfWeekPreference, equals(0.8));
      expect(timingState.frequencyPreference, equals(0.6));
      expect(timingState.durationPreference, equals(0.5));
      expect(timingState.timingVibeMatch, equals(0.75));
    });

    test('should create timing quantum state from intuitive values', () async {
      final timingState = await service.createTimingQuantumStateFromIntuitive(
        timeOfDayHour: 18, // 6 PM
        dayOfWeek: 6, // Sunday (0-6 format)
        frequencyPreference: 0.7,
        durationPreference: 0.6,
      );

      // Time of day should be normalized (18/24 = 0.75)
      expect(timingState.timeOfDayPreference, closeTo(0.75, 0.01));
      // Sunday is weekend
      expect(timingState.dayOfWeekPreference, equals(1.0));
      expect(timingState.frequencyPreference, equals(0.7));
      expect(timingState.durationPreference, equals(0.6));
      
      // Test getters
      expect(timingState.timeOfDayHour, equals(18));
      expect(timingState.prefersWeekend, isTrue);
      expect(timingState.prefersWeekday, isFalse);
    });

    test('should create timing quantum state from DateTime', () async {
      // January 18, 2025 is a Saturday
      final preferredTime = DateTime(2025, 1, 18, 18, 30); // Saturday 6:30 PM

      final timingState = await service.createTimingQuantumStateFromDateTime(
        preferredTime: preferredTime,
        frequencyPreference: 0.7,
        durationPreference: 0.6,
      );

      // Time of day should be normalized (18:30 = 0.77)
      expect(timingState.timeOfDayPreference, greaterThan(0.7));
      expect(timingState.timeOfDayPreference, lessThan(0.8));
      // Saturday is weekend (weekday 6)
      expect(timingState.dayOfWeekPreference, equals(1.0));
      expect(timingState.frequencyPreference, equals(0.7));
      expect(timingState.durationPreference, equals(0.6));
      
      // Test getters (18:30 rounds to hour 19 due to rounding)
      expect(timingState.timeOfDayHour, greaterThanOrEqualTo(18));
      expect(timingState.timeOfDayHour, lessThanOrEqualTo(19));
      expect(timingState.prefersWeekend, isTrue);
    });

    test('should create timing quantum state with preferred days', () async {
      final timingState = await service.createTimingQuantumStateWithPreferredDays(
        timeOfDayHour: 14, // 2 PM
        preferredDays: [5, 6], // Saturday and Sunday
        frequencyPreference: 0.8,
        durationPreference: 0.7,
      );

      // Should prefer weekend (all preferred days are weekend)
      expect(timingState.dayOfWeekPreference, equals(1.0));
      expect(timingState.timeOfDayHour, equals(14));
      expect(timingState.prefersWeekend, isTrue);
    });

    test('should clamp preferences to valid range', () async {
      final timingState = await service.createTimingQuantumState(
        timeOfDayPreference: 1.5, // Out of range
        dayOfWeekPreference: -0.5, // Out of range
        frequencyPreference: 0.5,
        durationPreference: 0.5,
      );

      expect(timingState.timeOfDayPreference, equals(1.0));
      expect(timingState.dayOfWeekPreference, equals(0.0));
    });
  });

  group('LocationCompatibilityCalculator', () {
    test('should calculate location compatibility', () {
      final locationA = EntityLocationQuantumState(
        latitudeQuantumState: 0.5,
        longitudeQuantumState: 0.5,
        locationType: 'urban',
        accessibilityScore: 0.8,
        vibeLocationMatch: 0.7,
      );

      final locationB = EntityLocationQuantumState(
        latitudeQuantumState: 0.52,
        longitudeQuantumState: 0.48,
        locationType: 'urban',
        accessibilityScore: 0.75,
        vibeLocationMatch: 0.65,
      );

      final compatibility = LocationCompatibilityCalculator.calculateLocationCompatibility(
        locationA,
        locationB,
      );

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });

    test('should calculate distance-based compatibility', () {
      const locationA = UnifiedLocationData(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      const locationB = UnifiedLocationData(
        latitude: 40.7580,
        longitude: -73.9855,
      );

      final compatibility = LocationCompatibilityCalculator.calculateDistanceBasedCompatibility(
        locationA,
        locationB,
        maxDistanceKm: 10.0,
      );

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
      // Locations are close (Manhattan), should have high compatibility
      expect(compatibility, greaterThan(0.5));
    });
  });

  group('TimingCompatibilityCalculator', () {
    test('should calculate timing compatibility', () {
      final timingA = EntityTimingQuantumState(
        timeOfDayPreference: 0.7,
        dayOfWeekPreference: 0.8,
        frequencyPreference: 0.6,
        durationPreference: 0.5,
        timingVibeMatch: 0.75,
      );

      final timingB = EntityTimingQuantumState(
        timeOfDayPreference: 0.72,
        dayOfWeekPreference: 0.75,
        frequencyPreference: 0.65,
        durationPreference: 0.55,
        timingVibeMatch: 0.70,
      );

      final compatibility = TimingCompatibilityCalculator.calculateTimingCompatibility(
        timingA,
        timingB,
      );

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });

    test('should calculate time overlap compatibility', () {
      final userTiming = EntityTimingQuantumState(
        timeOfDayPreference: 0.7, // Evening (around 6 PM)
        dayOfWeekPreference: 0.8, // Weekend preference
        frequencyPreference: 0.6,
        durationPreference: 0.5,
        timingVibeMatch: 0.75,
      );

      final eventStartTime = DateTime(2025, 1, 18, 18, 0); // Saturday 6 PM
      final eventEndTime = DateTime(2025, 1, 18, 20, 0); // Saturday 8 PM

      final compatibility = TimingCompatibilityCalculator.calculateTimeOverlapCompatibility(
        userTiming: userTiming,
        eventStartTime: eventStartTime,
        eventEndTime: eventEndTime,
      );

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
      // Should have high compatibility (matches time and day)
      expect(compatibility, greaterThan(0.5));
    });
  });
}
