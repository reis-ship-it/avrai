// Location and Timing Quantum State Service
//
// Converts physical locations and timing preferences to quantum states
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Section 19.3: Location and Timing Quantum States
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Service for converting locations and timing to quantum states
///
/// **Location Quantum State:**
/// |ψ_location(t_atomic)⟩ = [latitude_quantum_state, longitude_quantum_state, location_type, accessibility_score, vibe_location_match]ᵀ
///
/// **Timing Quantum State:**
/// |ψ_timing(t_atomic)⟩ = [time_of_day_preference, day_of_week_preference, frequency_preference, duration_preference, timing_vibe_match]ᵀ
class LocationTimingQuantumStateService {
  static const String _logName = 'LocationTimingQuantumStateService';

  // TODO(Phase 19.3): Use atomic clock for future timestamp tracking in location/timing states
  // final AtomicClockService _atomicClock;

  LocationTimingQuantumStateService({
    AtomicClockService? atomicClock, // Optional for future use
  });

  /// Convert UnifiedLocationData to EntityLocationQuantumState
  ///
  /// **Formula:**
  /// |ψ_location(t_atomic)⟩ = [
  ///   latitude_quantum_state,      // Normalized: (lat + 90) / 180
  ///   longitude_quantum_state,     // Normalized: (lon + 180) / 360
  ///   location_type,               // 0.0 (rural) to 1.0 (urban)
  ///   accessibility_score,        // 0.0 to 1.0
  ///   vibe_location_match          // 0.0 to 1.0
  /// ]ᵀ
  ///
  /// **Parameters:**
  /// - `location`: Physical location (UnifiedLocationData)
  /// - `locationType`: Optional location type (0.0 = rural, 0.5 = suburban, 1.0 = urban)
  /// - `accessibilityScore`: Optional accessibility score (0.0 to 1.0)
  /// - `vibeLocationMatch`: Optional vibe location match (0.0 to 1.0)
  ///
  /// **Returns:**
  /// EntityLocationQuantumState with atomic timestamp
  Future<EntityLocationQuantumState> createLocationQuantumState({
    required UnifiedLocationData location,
    double? locationType,
    double? accessibilityScore,
    double? vibeLocationMatch,
  }) async {
    developer.log(
      'Creating location quantum state for location: ${location.latitude}, ${location.longitude}',
      name: _logName,
    );

    try {
      // Convert latitude to quantum state (normalized to [0, 1] range)
      // Latitude range: -90 to 90, normalize to [0, 1]
      final normalizedLat = (location.latitude + 90.0) / 180.0;
      final latQuantumState = normalizedLat.clamp(0.0, 1.0);

      // Convert longitude to quantum state (normalized to [0, 1] range)
      // Longitude range: -180 to 180, normalize to [0, 1]
      final normalizedLon = (location.longitude + 180.0) / 360.0;
      final lonQuantumState = normalizedLon.clamp(0.0, 1.0);

      // Infer location type from city/address if not provided
      final inferredLocationType = locationType ?? _inferLocationType(
        location.city,
        location.address,
      );

      // Default accessibility score if not provided
      final inferredAccessibility = accessibilityScore ?? 0.7;

      // Default vibe location match if not provided
      final inferredVibeMatch = vibeLocationMatch ?? 0.5;

      final locationState = EntityLocationQuantumState(
        latitudeQuantumState: latQuantumState,
        longitudeQuantumState: lonQuantumState,
        locationType: _locationTypeToString(inferredLocationType),
        accessibilityScore: inferredAccessibility,
        vibeLocationMatch: inferredVibeMatch,
      );

      developer.log(
        '✅ Created location quantum state: type=${locationState.locationType}, accessibility=${locationState.accessibilityScore}',
        name: _logName,
      );

      return locationState;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error creating location quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Convert timing preferences to EntityTimingQuantumState
  ///
  /// **Formula:**
  /// |ψ_timing(t_atomic)⟩ = [
  ///   time_of_day_preference,      // 0.0 (morning) to 1.0 (night)
  ///   day_of_week_preference,      // 0.0 (weekday) to 1.0 (weekend)
  ///   frequency_preference,        // 0.0 (rare) to 1.0 (frequent)
  ///   duration_preference,         // 0.0 (short) to 1.0 (long)
  ///   timing_vibe_match            // 0.0 to 1.0
  /// ]ᵀ
  ///
  /// **Parameters:**
  /// - `timeOfDayPreference`: Time of day preference (0.0 = morning, 1.0 = night)
  /// - `dayOfWeekPreference`: Day of week preference (0.0 = weekday, 1.0 = weekend)
  /// - `frequencyPreference`: Frequency preference (0.0 = rare, 1.0 = frequent)
  /// - `durationPreference`: Duration preference (0.0 = short, 1.0 = long)
  /// - `timingVibeMatch`: Optional timing vibe match (0.0 to 1.0)
  ///
  /// **Returns:**
  /// EntityTimingQuantumState with atomic timestamp
  Future<EntityTimingQuantumState> createTimingQuantumState({
    required double timeOfDayPreference,
    required double dayOfWeekPreference,
    required double frequencyPreference,
    required double durationPreference,
    double? timingVibeMatch,
  }) async {
    developer.log(
      'Creating timing quantum state: timeOfDay=$timeOfDayPreference, dayOfWeek=$dayOfWeekPreference',
      name: _logName,
    );

    try {
      // Clamp all preferences to [0, 1]
      final clampedTimeOfDay = timeOfDayPreference.clamp(0.0, 1.0);
      final clampedDayOfWeek = dayOfWeekPreference.clamp(0.0, 1.0);
      final clampedFrequency = frequencyPreference.clamp(0.0, 1.0);
      final clampedDuration = durationPreference.clamp(0.0, 1.0);
      final clampedVibeMatch = (timingVibeMatch ?? 0.5).clamp(0.0, 1.0);

      final timingState = EntityTimingQuantumState(
        timeOfDayPreference: clampedTimeOfDay,
        dayOfWeekPreference: clampedDayOfWeek,
        frequencyPreference: clampedFrequency,
        durationPreference: clampedDuration,
        timingVibeMatch: clampedVibeMatch,
      );

      developer.log(
        '✅ Created timing quantum state: frequency=$clampedFrequency, duration=$clampedDuration',
        name: _logName,
      );

      return timingState;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error creating timing quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Create timing quantum state with intuitive values
  ///
  /// **Parameters:**
  /// - `timeOfDayHour`: Hour of day (0-23, where 0 = midnight, 23 = 11 PM)
  /// - `dayOfWeek`: Day of week (0-6, where 0 = Monday, 6 = Sunday) OR (1-7, where 1 = Monday, 7 = Sunday)
  /// - `frequencyPreference`: Frequency preference (0.0 = rare, 1.0 = frequent)
  /// - `durationPreference`: Duration preference (0.0 = short, 1.0 = long)
  /// - `timingVibeMatch`: Optional timing vibe match (0.0 to 1.0)
  ///
  /// **Returns:**
  /// EntityTimingQuantumState with normalized values (0-1) for quantum math
  Future<EntityTimingQuantumState> createTimingQuantumStateFromIntuitive({
    required int timeOfDayHour, // 0-23
    required int dayOfWeek, // 0-6 (Monday-Sunday) or 1-7 (Monday-Sunday)
    required double frequencyPreference,
    required double durationPreference,
    double? timingVibeMatch,
  }) async {
    // Convert hour (0-23) to normalized (0-1)
    final normalizedTimeOfDay = (timeOfDayHour.clamp(0, 23) / 24.0);

    // Convert day of week to weekend preference
    // If input is 1-7, convert to 0-6 first
    final dayIndex = dayOfWeek > 7 ? dayOfWeek - 1 : dayOfWeek;
    final clampedDay = dayIndex.clamp(0, 6);
    // 0-4 = weekday (0.0), 5-6 = weekend (1.0)
    final normalizedDayOfWeek = clampedDay >= 5 ? 1.0 : 0.0;

    return createTimingQuantumState(
      timeOfDayPreference: normalizedTimeOfDay,
      dayOfWeekPreference: normalizedDayOfWeek,
      frequencyPreference: frequencyPreference,
      durationPreference: durationPreference,
      timingVibeMatch: timingVibeMatch,
    );
  }

  /// Create timing quantum state with day of week as specific day preference
  ///
  /// Allows specifying which days of the week are preferred (not just weekday vs weekend)
  ///
  /// **Parameters:**
  /// - `timeOfDayHour`: Hour of day (0-23)
  /// - `preferredDays`: List of preferred days (0-6 for Monday-Sunday, or 1-7)
  /// - `frequencyPreference`: Frequency preference (0.0 = rare, 1.0 = frequent)
  /// - `durationPreference`: Duration preference (0.0 = short, 1.0 = long)
  /// - `timingVibeMatch`: Optional timing vibe match (0.0 to 1.0)
  ///
  /// **Returns:**
  /// EntityTimingQuantumState with day preference calculated from preferred days
  Future<EntityTimingQuantumState> createTimingQuantumStateWithPreferredDays({
    required int timeOfDayHour, // 0-23
    required List<int> preferredDays, // 0-6 or 1-7
    required double frequencyPreference,
    required double durationPreference,
    double? timingVibeMatch,
  }) async {
    // Convert hour to normalized
    final normalizedTimeOfDay = (timeOfDayHour.clamp(0, 23) / 24.0);

    // Calculate day preference based on preferred days
    // Normalize preferred days to 0-6 range
    final normalizedDays = preferredDays.map((day) => day > 7 ? day - 1 : day).toList();

    // Calculate preference: more weekend days = higher preference
    final weekendDays = normalizedDays.where((day) => day >= 5).length;
    final totalDays = normalizedDays.length;

    // Preference is weighted by weekend ratio
    final dayPreference = totalDays > 0
        ? (weekendDays / totalDays)
        : 0.5; // Default to middle if no days specified

    return createTimingQuantumState(
      timeOfDayPreference: normalizedTimeOfDay,
      dayOfWeekPreference: dayPreference,
      frequencyPreference: frequencyPreference,
      durationPreference: durationPreference,
      timingVibeMatch: timingVibeMatch,
    );
  }

  /// Create timing quantum state from DateTime preferences
  ///
  /// Converts actual DateTime values to preference scores
  /// - Time of day: hour (0-23) → normalized (0-1)
  /// - Day of week: weekday (1-5) → 0.0, weekend (6-7) → 1.0
  Future<EntityTimingQuantumState> createTimingQuantumStateFromDateTime({
    required DateTime preferredTime,
    required double frequencyPreference, // 0.0 (rare) to 1.0 (frequent)
    required double durationPreference, // 0.0 (short) to 1.0 (long)
    double? timingVibeMatch,
  }) async {
    // Extract time of day (0-23 hours) and normalize to [0, 1]
    final hour = preferredTime.hour;
    final minute = preferredTime.minute;
    final timeOfDayPreference = (hour * 60 + minute) / (24 * 60); // Normalize to [0, 1]

    // Extract day of week (1 = Monday, 7 = Sunday)
    // Convert to weekday (0.0) vs weekend (1.0) preference
    final weekday = preferredTime.weekday; // 1 = Monday, 7 = Sunday
    final dayOfWeekPreference = weekday >= 6 ? 1.0 : 0.0; // Saturday/Sunday = weekend

    return createTimingQuantumState(
      timeOfDayPreference: timeOfDayPreference,
      dayOfWeekPreference: dayOfWeekPreference,
      frequencyPreference: frequencyPreference,
      durationPreference: durationPreference,
      timingVibeMatch: timingVibeMatch,
    );
  }

  /// Infer location type from city/address
  ///
  /// Returns: 0.0 (rural), 0.5 (suburban), 1.0 (urban)
  double _inferLocationType(String? city, String? address) {
    if (city == null && address == null) {
      return 0.5; // Default to suburban
    }

    final locationText = '${city ?? ''} ${address ?? ''}'.toLowerCase();

    // Urban indicators
    if (locationText.contains('downtown') ||
        locationText.contains('city center') ||
        locationText.contains('urban') ||
        locationText.contains('metro') ||
        locationText.contains('midtown') ||
        locationText.contains('central')) {
      return 1.0;
    }

    // Rural indicators
    if (locationText.contains('rural') ||
        locationText.contains('countryside') ||
        locationText.contains('farm') ||
        locationText.contains('village')) {
      return 0.0;
    }

    // Default to suburban
    return 0.5;
  }

  /// Convert location type double to string
  String _locationTypeToString(double locationType) {
    if (locationType >= 0.75) {
      return 'urban';
    } else if (locationType <= 0.25) {
      return 'rural';
    } else {
      return 'suburban';
    }
  }
}

/// Location compatibility calculator
///
/// Calculates compatibility between two location quantum states
class LocationCompatibilityCalculator {
  /// Calculate location compatibility between two location quantum states
  ///
  /// **Formula:**
  /// F(ρ_location_A, ρ_location_B) = |⟨ψ_location_A|ψ_location_B⟩|²
  ///
  /// **Returns:**
  /// Location compatibility score (0.0 to 1.0)
  static double calculateLocationCompatibility(
    EntityLocationQuantumState locationA,
    EntityLocationQuantumState locationB,
  ) {
    // Calculate inner product: ⟨ψ_location_A|ψ_location_B⟩
    var innerProduct = 0.0;

    // Latitude contribution
    innerProduct += locationA.latitudeQuantumState * locationB.latitudeQuantumState;

    // Longitude contribution
    innerProduct += locationA.longitudeQuantumState * locationB.longitudeQuantumState;

    // Location type contribution (match if same type)
    final typeMatch = locationA.locationType == locationB.locationType ? 1.0 : 0.5;
    innerProduct += typeMatch * 0.2; // Weight location type match

    // Accessibility contribution
    innerProduct += locationA.accessibilityScore * locationB.accessibilityScore;

    // Vibe location match contribution
    innerProduct += locationA.vibeLocationMatch * locationB.vibeLocationMatch;

    // Normalize by number of components (5 components)
    innerProduct /= 5.0;

    // Fidelity: |⟨ψ_location_A|ψ_location_B⟩|²
    final fidelity = innerProduct * innerProduct;

    return fidelity.clamp(0.0, 1.0);
  }

  /// Calculate distance-based location compatibility
  ///
  /// Uses Haversine formula for distance, then converts to compatibility
  /// Closer locations have higher compatibility
  static double calculateDistanceBasedCompatibility(
    UnifiedLocationData locationA,
    UnifiedLocationData locationB, {
    double maxDistanceKm = 50.0, // Maximum distance for full compatibility
  }) {
    final distanceMeters = locationA.distanceTo(locationB);
    final distanceKm = distanceMeters / 1000.0; // Convert meters to kilometers

    // Convert distance to compatibility (exponential decay)
    // Compatibility = exp(-distance / maxDistance)
    final compatibility = math.exp(-distanceKm / maxDistanceKm);

    return compatibility.clamp(0.0, 1.0);
  }
}

/// Timing compatibility calculator
///
/// Calculates compatibility between two timing quantum states
class TimingCompatibilityCalculator {
  /// Calculate timing compatibility between two timing quantum states
  ///
  /// **Formula:**
  /// F(ρ_timing_A, ρ_timing_B) = |⟨ψ_timing_A|ψ_timing_B⟩|²
  ///
  /// **Returns:**
  /// Timing compatibility score (0.0 to 1.0)
  static double calculateTimingCompatibility(
    EntityTimingQuantumState timingA,
    EntityTimingQuantumState timingB,
  ) {
    // Calculate inner product: ⟨ψ_timing_A|ψ_timing_B⟩
    var innerProduct = 0.0;

    // Time of day contribution
    innerProduct += timingA.timeOfDayPreference * timingB.timeOfDayPreference;

    // Day of week contribution
    innerProduct += timingA.dayOfWeekPreference * timingB.dayOfWeekPreference;

    // Frequency contribution
    innerProduct += timingA.frequencyPreference * timingB.frequencyPreference;

    // Duration contribution
    innerProduct += timingA.durationPreference * timingB.durationPreference;

    // Timing vibe match contribution
    innerProduct += timingA.timingVibeMatch * timingB.timingVibeMatch;

    // Normalize by number of components (5 components)
    innerProduct /= 5.0;

    // Fidelity: |⟨ψ_timing_A|ψ_timing_B⟩|²
    final fidelity = innerProduct * innerProduct;

    return fidelity.clamp(0.0, 1.0);
  }

  /// Calculate time overlap compatibility
  ///
  /// For events with specific start/end times, calculate overlap with preferences
  static double calculateTimeOverlapCompatibility({
    required EntityTimingQuantumState userTiming,
    required DateTime eventStartTime,
    required DateTime eventEndTime,
  }) {
    // Extract event time of day (normalized to [0, 1])
    final eventHour = eventStartTime.hour;
    final eventMinute = eventStartTime.minute;
    final eventTimeOfDay = (eventHour * 60 + eventMinute) / (24 * 60);

    // Calculate time of day compatibility (Gaussian-like function)
    final timeDiff = (eventTimeOfDay - userTiming.timeOfDayPreference).abs();
    final timeCompatibility = math.exp(-timeDiff * timeDiff * 10.0); // Sharp peak

    // Extract event day of week
    final eventWeekday = eventStartTime.weekday;
    final eventIsWeekend = eventWeekday >= 6;
    final userPrefersWeekend = userTiming.dayOfWeekPreference > 0.5;
    final dayCompatibility = eventIsWeekend == userPrefersWeekend ? 1.0 : 0.5;

    // Calculate duration compatibility
    final eventDurationHours = eventEndTime.difference(eventStartTime).inHours.toDouble();
    final normalizedDuration = (eventDurationHours / 24.0).clamp(0.0, 1.0);
    final durationDiff = (normalizedDuration - userTiming.durationPreference).abs();
    final durationCompatibility = math.exp(-durationDiff * durationDiff * 5.0);

    // Combined compatibility
    final compatibility = (timeCompatibility * 0.4 + dayCompatibility * 0.3 + durationCompatibility * 0.3);

    return compatibility.clamp(0.0, 1.0);
  }
}
