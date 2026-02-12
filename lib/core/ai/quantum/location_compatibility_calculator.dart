import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai/core/ai/quantum/location_quantum_state.dart';
import 'package:avrai/core/models/user/unified_models.dart';

/// Location Compatibility Calculator
///
/// Calculates location compatibility using quantum location states.
/// Implements Patent #8: Multi-Entity Quantum Entanglement Matching - Location Compatibility.
///
/// **Location Compatibility Formula:**
/// ```
/// location_compatibility = |⟨ψ_entity_location|ψ_event_location⟩|²
/// ```
///
/// **Enhanced Compatibility Formula (with Location Entanglement):**
/// ```
/// user_entangled_compatibility = 0.5 * |⟨ψ_user|ψ_entangled⟩|² +
///                               0.3 * |⟨ψ_user_location|ψ_event_location⟩|² +
///                               0.2 * |⟨ψ_user_timing|ψ_event_timing⟩|²
/// ```
class LocationCompatibilityCalculator {
  static const String _logName = 'LocationCompatibilityCalculator';

  /// Calculate location compatibility between two locations
  ///
  /// Returns: `C_location = |⟨ψ_location_A|ψ_location_B⟩|²`
  ///
  /// **Parameters:**
  /// - `locationA`: First location (e.g., user location)
  /// - `locationB`: Second location (e.g., event location)
  /// - `locationTypeA`: Optional location type for location A (0.0 = rural, 0.5 = suburban, 1.0 = urban)
  /// - `locationTypeB`: Optional location type for location B
  /// - `accessibilityScoreA`: Optional accessibility score for location A (0.0 to 1.0)
  /// - `accessibilityScoreB`: Optional accessibility score for location B
  /// - `vibeLocationMatchA`: Optional vibe location match for location A (0.0 to 1.0)
  /// - `vibeLocationMatchB`: Optional vibe location match for location B
  ///
  /// **Returns:** Location compatibility score (0.0 to 1.0)
  static double calculateLocationCompatibility({
    required UnifiedLocation locationA,
    required UnifiedLocation locationB,
    double? locationTypeA,
    double? locationTypeB,
    double? accessibilityScoreA,
    double? accessibilityScoreB,
    double? vibeLocationMatchA,
    double? vibeLocationMatchB,
  }) {
    try {
      // Create location quantum states
      final stateA = LocationQuantumState.fromLocation(
        locationA,
        locationType: locationTypeA,
        accessibilityScore: accessibilityScoreA,
        vibeLocationMatch: vibeLocationMatchA,
      );

      final stateB = LocationQuantumState.fromLocation(
        locationB,
        locationType: locationTypeB,
        accessibilityScore: accessibilityScoreB,
        vibeLocationMatch: vibeLocationMatchB,
      );

      // Calculate compatibility: |⟨ψ_location_A|ψ_location_B⟩|²
      final compatibility = stateA.locationCompatibility(stateB);

      developer.log(
        'Location compatibility: ${(compatibility * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      return compatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating location compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0.5; // Neutral fallback
    }
  }

  /// Calculate enhanced compatibility with location entanglement
  ///
  /// Combines personality compatibility with location and timing compatibility.
  ///
  /// **Formula:**
  /// ```
  /// user_entangled_compatibility = 0.5 * personality_compatibility +
  ///                               0.3 * location_compatibility +
  ///                               0.2 * timing_compatibility
  /// ```
  ///
  /// **Parameters:**
  /// - `personalityCompatibility`: Personality compatibility score (0.0 to 1.0)
  /// - `locationCompatibility`: Location compatibility score (0.0 to 1.0)
  /// - `timingCompatibility`: Timing compatibility score (0.0 to 1.0), optional
  ///
  /// **Returns:** Enhanced compatibility score (0.0 to 1.0)
  static double calculateEnhancedCompatibility({
    required double personalityCompatibility,
    required double locationCompatibility,
    double? timingCompatibility,
  }) {
    // Default timing compatibility if not provided
    final timing = timingCompatibility ?? 0.5;

    // Enhanced compatibility formula
    final enhanced = (personalityCompatibility * 0.5) +
        (locationCompatibility * 0.3) +
        (timing * 0.2);

    developer.log(
      'Enhanced compatibility: '
      'personality=${(personalityCompatibility * 100).toStringAsFixed(1)}%, '
      'location=${(locationCompatibility * 100).toStringAsFixed(1)}%, '
      'timing=${(timing * 100).toStringAsFixed(1)}%, '
      'total=${(enhanced * 100).toStringAsFixed(1)}%',
      name: _logName,
    );

    return enhanced.clamp(0.0, 1.0);
  }

  /// Calculate distance-based location compatibility
  ///
  /// Uses physical distance to calculate compatibility (closer = higher compatibility).
  ///
  /// **Formula:**
  /// ```
  /// distance_compatibility = e^(-distance_km / decay_distance_km)
  /// ```
  ///
  /// **Parameters:**
  /// - `locationA`: First location
  /// - `locationB`: Second location
  /// - `decayDistanceKm`: Distance decay factor in kilometers (default: 50km)
  ///
  /// **Returns:** Distance-based compatibility score (0.0 to 1.0)
  static double calculateDistanceCompatibility({
    required UnifiedLocation locationA,
    required UnifiedLocation locationB,
    double decayDistanceKm = 50.0,
  }) {
    try {
      // Calculate distance in kilometers
      final distanceKm = locationA.distanceTo(locationB) / 1000.0;

      // Exponential decay: e^(-distance / decay_distance)
      final compatibility = math.exp(-distanceKm / decayDistanceKm);

      developer.log(
        'Distance compatibility: ${distanceKm.toStringAsFixed(1)}km -> '
        '${(compatibility * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      return compatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating distance compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0.5; // Neutral fallback
    }
  }
}

