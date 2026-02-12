import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/user/unified_models.dart';

/// Location Quantum State
///
/// Represents a location as a quantum state vector for quantum compatibility calculations.
/// Implements Patent #8: Multi-Entity Quantum Entanglement Matching - Location Quantum States.
///
/// **Location Quantum State Structure:**
/// ```
/// |ψ_location⟩ = [
///   latitude_quantum_state,      // Quantum state of latitude
///   longitude_quantum_state,     // Quantum state of longitude
///   location_type,               // Urban, suburban, rural, etc.
///   accessibility_score,         // How accessible the location is
///   vibe_location_match          // How location vibe matches entity vibe
/// ]ᵀ
/// ```
///
/// **Location Compatibility Formula:**
/// ```
/// location_compatibility = |⟨ψ_entity_location|ψ_event_location⟩|²
/// ```
class LocationQuantumState {
  /// Quantum state of latitude (normalized)
  final List<double> latitudeState;

  /// Quantum state of longitude (normalized)
  final List<double> longitudeState;

  /// Location type (0.0 = rural, 0.5 = suburban, 1.0 = urban)
  final double locationType;

  /// Accessibility score (0.0 to 1.0)
  final double accessibilityScore;

  /// Vibe location match (0.0 to 1.0) - How location vibe matches entity vibe
  final double vibeLocationMatch;

  /// Atomic timestamp when this state was created
  final AtomicTimestamp atomicTimestamp;

  /// Complete location quantum state vector
  final List<double> stateVector;

  LocationQuantumState({
    required this.latitudeState,
    required this.longitudeState,
    required this.locationType,
    required this.accessibilityScore,
    required this.vibeLocationMatch,
    required this.atomicTimestamp,
    required this.stateVector,
  });

  /// Create location quantum state from UnifiedLocation
  ///
  /// Converts a physical location into a quantum state representation.
  factory LocationQuantumState.fromLocation(
    UnifiedLocation location, {
    double? locationType,
    double? accessibilityScore,
    double? vibeLocationMatch,
    AtomicTimestamp? atomicTimestamp,
  }) {
    final timestamp = atomicTimestamp ??
        AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

    // Convert latitude to quantum state (normalized to [0, 1] range)
    // Latitude range: -90 to 90, normalize to [0, 1]
    final normalizedLat = (location.latitude + 90.0) / 180.0;
    final latState = _createQuantumState(normalizedLat);

    // Convert longitude to quantum state (normalized to [0, 1] range)
    // Longitude range: -180 to 180, normalize to [0, 1]
    final normalizedLon = (location.longitude + 180.0) / 360.0;
    final lonState = _createQuantumState(normalizedLon);

    // Infer location type from city/address if not provided
    final inferredLocationType = locationType ??
        _inferLocationType(location.city, location.address);

    // Default accessibility score if not provided
    final inferredAccessibility = accessibilityScore ?? 0.7;

    // Default vibe location match if not provided
    final inferredVibeMatch = vibeLocationMatch ?? 0.5;

    // Create complete state vector
    final stateVector = [
      ...latState,
      ...lonState,
      inferredLocationType,
      inferredAccessibility,
      inferredVibeMatch,
    ];

    return LocationQuantumState(
      latitudeState: latState,
      longitudeState: lonState,
      locationType: inferredLocationType,
      accessibilityScore: inferredAccessibility,
      vibeLocationMatch: inferredVibeMatch,
      atomicTimestamp: timestamp,
      stateVector: stateVector,
    );
  }

  /// Create quantum state from a normalized value (0.0 to 1.0)
  ///
  /// Uses quantum superposition: |ψ⟩ = √(value) |0⟩ + √(1-value) |1⟩
  static List<double> _createQuantumState(double normalizedValue) {
    // Clamp to [0, 1]
    final value = normalizedValue.clamp(0.0, 1.0);

    // Quantum superposition: |ψ⟩ = √(value) |0⟩ + √(1-value) |1⟩
    final amplitude0 = math.sqrt(value);
    final amplitude1 = math.sqrt(1.0 - value);

    return [amplitude0, amplitude1];
  }

  /// Infer location type from city/address
  ///
  /// Returns: 0.0 (rural), 0.5 (suburban), 1.0 (urban)
  static double _inferLocationType(String? city, String? address) {
    if (city == null && address == null) {
      return 0.5; // Default to suburban
    }

    final locationText = '${city ?? ''} ${address ?? ''}'.toLowerCase();

    // Urban indicators
    if (locationText.contains('downtown') ||
        locationText.contains('city center') ||
        locationText.contains('urban') ||
        locationText.contains('metro')) {
      return 1.0;
    }

    // Rural indicators
    if (locationText.contains('rural') ||
        locationText.contains('countryside') ||
        locationText.contains('farm')) {
      return 0.0;
    }

    // Default to suburban
    return 0.5;
  }

  /// Calculate quantum inner product with another location state
  ///
  /// Returns: `⟨ψ_location_A|ψ_location_B⟩`
  double innerProduct(LocationQuantumState other) {
    // The stateVector includes non-amplitude scalar features (locationType,
    // accessibilityScore, vibeLocationMatch) which can cause dot products > 1.0
    // and break the quantum inner product contract.
    //
    // Instead, we model location overlap as a Gaussian wavefunction overlap on
    // normalized lat/lon (0..1), which yields an inner product in (0..1].
    //
    // This preserves the contract: `compatibility = |⟨ψA|ψB⟩|² ∈ [0,1]` and
    // produces meaningful decay for distant locations.
    const sigma = 0.1; // "spread" in normalized coordinate space
    const denom = 2 * sigma * sigma;

    final latA = latitudeState.isNotEmpty ? latitudeState.first * latitudeState.first : 0.5;
    final latB = other.latitudeState.isNotEmpty ? other.latitudeState.first * other.latitudeState.first : 0.5;
    final lonA = longitudeState.isNotEmpty ? longitudeState.first * longitudeState.first : 0.5;
    final lonB = other.longitudeState.isNotEmpty ? other.longitudeState.first * other.longitudeState.first : 0.5;

    final dLat = (latA - latB).abs();
    var dLon = (lonA - lonB).abs();
    // Longitude is circular; take shortest wrap-around distance.
    dLon = math.min(dLon, 1.0 - dLon);

    final latOverlap = math.exp(-(dLat * dLat) / denom);
    final lonOverlap = math.exp(-(dLon * dLon) / denom);

    // Soft similarity for additional scalar features (0..1). Defaults are
    // identical in many cases, so this does not dominate distance effects.
    double scalarSimilarity(double a, double b) =>
        (1.0 - (a - b).abs()).clamp(0.0, 1.0);

    final typeOverlap = scalarSimilarity(locationType, other.locationType);
    final accessibilityOverlap =
        scalarSimilarity(accessibilityScore, other.accessibilityScore);
    final vibeOverlap =
        scalarSimilarity(vibeLocationMatch, other.vibeLocationMatch);

    final inner = latOverlap * lonOverlap * typeOverlap * accessibilityOverlap * vibeOverlap;
    if (inner.isNaN || inner.isInfinite) return 0.0;
    return inner.clamp(0.0, 1.0);
  }

  /// Calculate location compatibility
  ///
  /// Returns: `C_location = |⟨ψ_location_A|ψ_location_B⟩|²`
  double locationCompatibility(LocationQuantumState other) {
    final innerProd = innerProduct(other);
    return (innerProd * innerProd).clamp(0.0, 1.0); // Squared magnitude
  }

  /// Normalize the location quantum state
  void normalize() {
    final norm = math.sqrt(
      stateVector.fold(0.0, (sum, value) => sum + value * value),
    );

    if (norm > 0.0) {
      for (int i = 0; i < stateVector.length; i++) {
        stateVector[i] = stateVector[i] / norm;
      }
    }
  }

  /// Calculate distance to another location (in kilometers)
  ///
  /// Uses Haversine formula for great-circle distance.
  /// Note: This requires the original location coordinates, not quantum states.
  /// For distance calculation, use UnifiedLocation.distanceTo() instead.
  ///
  /// This method is kept for compatibility but should use the original location.
  double distanceTo(UnifiedLocation other) {
    // Note: This requires the original location to calculate distance properly
    // The quantum state representation doesn't preserve exact coordinates
    // For accurate distance, use UnifiedLocation.distanceTo() with original locations
    throw UnimplementedError(
      'Distance calculation requires original location coordinates. '
      'Use UnifiedLocation.distanceTo() instead.',
    );
  }

  @override
  String toString() {
    return 'LocationQuantumState('
        'locationType: $locationType, '
        'accessibility: $accessibilityScore, '
        'vibeMatch: $vibeLocationMatch, '
        'timestamp: $atomicTimestamp)';
  }
}

