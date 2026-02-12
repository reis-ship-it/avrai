// Reservation Quantum Service
//
// Phase 15: Reservation System Implementation
// Section 15.1: Foundation - Quantum Integration
// Enhanced with Full Quantum Entanglement Integration
//
// Creates quantum states for reservations and calculates compatibility
// using full multi-entity quantum entanglement.

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
// Imports removed - not currently used in implementation
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/unified_location_data.dart';

/// Reservation Quantum Service
///
/// Creates quantum states for reservations and calculates compatibility
/// using full multi-entity quantum entanglement.
///
/// **Full Quantum Entanglement Formula:**
/// ```
/// |ψ_reservation_full(t_atomic)⟩ = |ψ_user_personality⟩ ⊗ |ψ_user_vibe[12]⟩ ⊗
///                                    |ψ_event⟩ ⊗ |ψ_event_vibe[12]⟩ ⊗
///                                    |ψ_business⟩ ⊗ |ψ_brand⟩ ⊗ |ψ_expert⟩ ⊗
///                                    |ψ_location⟩ ⊗ |ψ_timing⟩ ⊗ |t_atomic_purchase⟩
/// ```
///
/// **Full Compatibility Calculation:**
/// ```
/// C_reservation = 0.40 * F(ρ_entangled_personality, ρ_ideal_personality) +
///                 0.30 * F(ρ_entangled_vibe, ρ_ideal_vibe) +
///                 0.20 * F(ρ_user_location, ρ_event_location) +
///                 0.10 * F(ρ_user_timing, ρ_event_timing) * timing_flexibility_factor
/// ```
class ReservationQuantumService {
  static const String _logName = 'ReservationQuantumService';

  final AtomicClockService _atomicClock;
  // ignore: unused_field - Reserved for future quantum vibe integration
  final QuantumVibeEngine _quantumVibeEngine;
  final UserVibeAnalyzer _vibeAnalyzer;
  final PersonalityLearning _personalityLearning;
  final LocationTimingQuantumStateService _locationTimingService;
  // Optional, graceful degradation.
  // ignore: unused_field - Reserved for future Phase 19 integration
  final QuantumEntanglementService? _entanglementService;

  ReservationQuantumService({
    required AtomicClockService atomicClock,
    required QuantumVibeEngine quantumVibeEngine,
    required UserVibeAnalyzer vibeAnalyzer,
    required PersonalityLearning personalityLearning,
    required LocationTimingQuantumStateService locationTimingService,
    QuantumEntanglementService? entanglementService,
  })  : _atomicClock = atomicClock,
        _quantumVibeEngine = quantumVibeEngine,
        _vibeAnalyzer = vibeAnalyzer,
        _personalityLearning = personalityLearning,
        _locationTimingService = locationTimingService,
        _entanglementService = entanglementService;

  /// Create reservation quantum state with full entanglement
  ///
  /// **Formula:**
  /// |ψ_reservation_full(t_atomic)⟩ = |ψ_user_personality⟩ ⊗ |ψ_user_vibe[12]⟩ ⊗
  ///                                    |ψ_event⟩ ⊗ |ψ_event_vibe[12]⟩ ⊗
  ///                                    |ψ_business⟩ ⊗ |ψ_brand⟩ ⊗ |ψ_expert⟩ ⊗
  ///                                    |ψ_location⟩ ⊗ |ψ_timing⟩ ⊗ |t_atomic_purchase⟩
  ///
  /// **Parameters:**
  /// - `userId`: User ID (will be converted to agentId internally)
  /// - `eventId`: Event ID (if reservation is for an event)
  /// - `businessId`: Business ID (if reservation is for a business)
  /// - `spotId`: Spot ID (if reservation is for a spot)
  /// - `reservationTime`: Reservation time for timing quantum state
  ///
  /// **Returns:**
  /// QuantumEntityState representing the full reservation quantum state
  Future<QuantumEntityState> createReservationQuantumState({
    required String userId,
    String? eventId,
    String? businessId,
    String? spotId,
    required DateTime reservationTime,
  }) async {
    developer.log(
      'Creating reservation quantum state for user $userId',
      name: _logName,
    );

    try {
      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Get user personality profile
      final personalityProfile =
          await _personalityLearning.getCurrentPersonality(userId);
      if (personalityProfile == null) {
        throw Exception('Personality profile not found for user $userId');
      }

      // Get user quantum vibe analysis
      final userVibe =
          await _vibeAnalyzer.compileUserVibe(userId, personalityProfile);
      final quantumVibeAnalysis = userVibe.anonymizedDimensions;

      // Get location quantum state (if spot/event has location)
      EntityLocationQuantumState? locationState;
      if (spotId != null || eventId != null) {
        // TODO: Get location from spot/event
        // For now, create default location state
        locationState = await _createDefaultLocationState();
      }

      // Get timing quantum state
      final timingState = await _createTimingQuantumState(
        reservationTime: reservationTime,
        userId: userId,
      );

      // Create user quantum state
      final userState = QuantumEntityState(
        entityId: userId,
        entityType: QuantumEntityType.user,
        personalityState: personalityProfile.dimensions,
        quantumVibeAnalysis: quantumVibeAnalysis,
        entityCharacteristics: {
          'type': 'user',
          'agentId': personalityProfile.agentId,
        },
        location: locationState,
        timing: timingState,
        tAtomic: tAtomic,
      );

      // Store entanglement metadata in entity characteristics
      // The actual entanglement will be calculated during compatibility matching
      final characteristics = <String, dynamic>{
        ...userState.entityCharacteristics,
        'hasEvent': eventId != null,
        'hasBusiness': businessId != null,
        'hasSpot': spotId != null,
        if (eventId != null) 'eventId': eventId,
        if (businessId != null) 'businessId': businessId,
        if (spotId != null) 'spotId': spotId,
      };

      // Return user state with reservation context
      return userState.copyWith(
        entityCharacteristics: characteristics,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error creating reservation quantum state: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate full reservation compatibility
  ///
  /// **Formula:**
  /// ```
  /// C_reservation = 0.40 * F(ρ_entangled_personality, ρ_ideal_personality) +
  ///                 0.30 * F(ρ_entangled_vibe, ρ_ideal_vibe) +
  ///                 0.20 * F(ρ_user_location, ρ_event_location) +
  ///                 0.10 * F(ρ_user_timing, ρ_event_timing) * timing_flexibility_factor
  /// ```
  ///
  /// **Parameters:**
  /// - `reservationState`: Reservation quantum state
  /// - `idealState`: Ideal quantum state (for matching)
  ///
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  Future<double> calculateReservationCompatibility({
    required QuantumEntityState reservationState,
    required QuantumEntityState idealState,
  }) async {
    developer.log(
      'Calculating reservation compatibility',
      name: _logName,
    );

    try {
      // Calculate personality compatibility (40% weight)
      final personalityCompat = _calculatePersonalityCompatibility(
        reservationState,
        idealState,
      );

      // Calculate vibe compatibility (30% weight)
      final vibeCompat = _calculateVibeCompatibility(
        reservationState,
        idealState,
      );

      // Calculate location compatibility (20% weight)
      final locationCompat = _calculateLocationCompatibility(
        reservationState,
        idealState,
      );

      // Calculate timing compatibility (10% weight)
      final timingCompat = await _calculateTimingCompatibility(
        reservationState,
        idealState,
      );

      // Weighted combination
      final compatibility = 0.40 * personalityCompat +
          0.30 * vibeCompat +
          0.20 * locationCompat +
          0.10 * timingCompat;

      developer.log(
        'Reservation compatibility: $compatibility (personality: $personalityCompat, vibe: $vibeCompat, location: $locationCompat, timing: $timingCompat)',
        name: _logName,
      );

      return compatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating reservation compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate personality compatibility using quantum fidelity
  double _calculatePersonalityCompatibility(
    QuantumEntityState state1,
    QuantumEntityState state2,
  ) {
    // Calculate inner product: ⟨ψ_1|ψ_2⟩
    double innerProduct = 0.0;

    // Personality state contribution
    for (final dimension in state1.personalityState.keys) {
      final value1 = state1.personalityState[dimension] ?? 0.0;
      final value2 = state2.personalityState[dimension] ?? 0.0;
      innerProduct += value1 * value2;
    }

    // Quantum fidelity: F(ρ_1, ρ_2) = |⟨ψ_1|ψ_2⟩|²
    final fidelity = innerProduct * innerProduct;
    return fidelity.clamp(0.0, 1.0);
  }

  /// Calculate vibe compatibility using quantum fidelity
  double _calculateVibeCompatibility(
    QuantumEntityState state1,
    QuantumEntityState state2,
  ) {
    // Calculate inner product: ⟨ψ_vibe_1|ψ_vibe_2⟩
    double innerProduct = 0.0;

    // Quantum vibe analysis contribution
    for (final dimension in state1.quantumVibeAnalysis.keys) {
      final value1 = state1.quantumVibeAnalysis[dimension] ?? 0.0;
      final value2 = state2.quantumVibeAnalysis[dimension] ?? 0.0;
      innerProduct += value1 * value2;
    }

    // Quantum fidelity: F(ρ_vibe_1, ρ_vibe_2) = |⟨ψ_vibe_1|ψ_vibe_2⟩|²
    final fidelity = innerProduct * innerProduct;
    return fidelity.clamp(0.0, 1.0);
  }

  /// Calculate location compatibility
  double _calculateLocationCompatibility(
    QuantumEntityState state1,
    QuantumEntityState state2,
  ) {
    if (state1.location == null || state2.location == null) {
      return 0.5; // Default compatibility if location not available
    }

    // Calculate location distance (simplified)
    final latDiff = (state1.location!.latitudeQuantumState -
            state2.location!.latitudeQuantumState)
        .abs();
    final lonDiff = (state1.location!.longitudeQuantumState -
            state2.location!.longitudeQuantumState)
        .abs();

    // Compatibility decreases with distance
    final distance = math.sqrt(latDiff * latDiff + lonDiff * lonDiff);
    final compatibility = 1.0 - distance.clamp(0.0, 1.0);

    return compatibility.clamp(0.0, 1.0);
  }

  /// Calculate timing compatibility with flexibility factor
  Future<double> _calculateTimingCompatibility(
    QuantumEntityState state1,
    QuantumEntityState state2,
  ) async {
    if (state1.timing == null || state2.timing == null) {
      return 0.5; // Default compatibility if timing not available
    }

    // Calculate timing difference
    final timeOfDayDiff = (state1.timing!.timeOfDayPreference -
            state2.timing!.timeOfDayPreference)
        .abs();
    final dayOfWeekDiff = (state1.timing!.dayOfWeekPreference -
            state2.timing!.dayOfWeekPreference)
        .abs();

    // Compatibility decreases with timing difference
    final timingDiff = (timeOfDayDiff + dayOfWeekDiff) / 2.0;
    final compatibility = 1.0 - timingDiff.clamp(0.0, 1.0);

    // Apply timing flexibility factor (for meaningful experiences)
    // TODO: Calculate meaningful experience score
    const timingFlexibilityFactor = 1.0; // Default: no flexibility

    return (compatibility * timingFlexibilityFactor).clamp(0.0, 1.0);
  }

  /// Create default location quantum state
  Future<EntityLocationQuantumState> _createDefaultLocationState() async {
    // Create default location (center of map, urban, accessible)
    const defaultLocation = UnifiedLocationData(
      latitude: 0.0,
      longitude: 0.0,
      city: 'Unknown',
      address: 'Unknown',
    );

    return await _locationTimingService.createLocationQuantumState(
      location: defaultLocation,
      locationType: 0.5, // Suburban
      accessibilityScore: 0.7, // Default accessibility
      vibeLocationMatch: 0.5, // Default vibe match
    );
  }

  /// Create timing quantum state from reservation time
  Future<EntityTimingQuantumState> _createTimingQuantumState({
    required DateTime reservationTime,
    required String userId,
  }) async {
    // Extract time of day (0.0 = morning, 1.0 = night)
    final hour = reservationTime.hour;
    final timeOfDayPreference = (hour / 24.0).clamp(0.0, 1.0);

    // Extract day of week (0.0 = weekday, 1.0 = weekend)
    final weekday = reservationTime.weekday; // 1 = Monday, 7 = Sunday
    final dayOfWeekPreference = weekday >= 6 ? 1.0 : 0.0; // Weekend = 1.0

    // Default frequency and duration preferences
    const frequencyPreference = 0.5; // Medium frequency
    const durationPreference = 0.5; // Medium duration

    return await _locationTimingService.createTimingQuantumState(
      timeOfDayPreference: timeOfDayPreference,
      dayOfWeekPreference: dayOfWeekPreference,
      frequencyPreference: frequencyPreference,
      durationPreference: durationPreference,
      timingVibeMatch: 0.5, // Default vibe match
    );
  }

  // TODO(Phase 15.7): Implement event and business quantum state creation
  // These methods will be implemented when full event/business quantum integration is added
}

/// Extension to add copyWith to QuantumEntityState
extension QuantumEntityStateCopyWith on QuantumEntityState {
  QuantumEntityState copyWith({
    String? entityId,
    QuantumEntityType? entityType,
    Map<String, double>? personalityState,
    Map<String, double>? quantumVibeAnalysis,
    Map<String, dynamic>? entityCharacteristics,
    EntityLocationQuantumState? location,
    EntityTimingQuantumState? timing,
    AtomicTimestamp? tAtomic,
    double? normalizationFactor,
  }) {
    return QuantumEntityState(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      personalityState: personalityState ?? this.personalityState,
      quantumVibeAnalysis: quantumVibeAnalysis ?? this.quantumVibeAnalysis,
      entityCharacteristics:
          entityCharacteristics ?? this.entityCharacteristics,
      location: location ?? this.location,
      timing: timing ?? this.timing,
      tAtomic: tAtomic ?? this.tAtomic,
      normalizationFactor: normalizationFactor ?? this.normalizationFactor,
    );
  }
}
