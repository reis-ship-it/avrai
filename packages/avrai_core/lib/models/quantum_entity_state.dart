// Quantum Entity State Model
//
// Represents any entity (Expert, Business, Brand, Event, User, Sponsor) as a quantum state
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';

/// Quantum state vector for an entity
///
/// **Formula:**
/// |ψ_entity(t_atomic)⟩ = [personality_state, quantum_vibe_analysis, entity_characteristics, location, timing]ᵀ
///
/// **Normalization Constraint:**
/// ⟨ψ_entity|ψ_entity⟩ = 1
///
/// **Atomic Timing:**
/// All entity states include atomic timestamp for precise temporal tracking
class QuantumEntityState {
  /// Entity ID
  final String entityId;

  /// Entity type (Expert, Business, Brand, Event, User, Sponsor)
  final QuantumEntityType entityType;

  /// Personality state vector (12-dimensional quantum vibe analysis)
  /// From QuantumVibeEngine.compileVibeDimensionsQuantum()
  final Map<String, double> personalityState;

  /// Quantum vibe analysis (12 dimensions)
  /// Each dimension is a quantum state value (0.0 to 1.0)
  final Map<String, double> quantumVibeAnalysis;

  /// Entity characteristics (type-specific metadata)
  /// Examples:
  /// - Expert: expertise categories, level, verification status
  /// - Business: business type, categories, verification status
  /// - Brand: brand categories, values, verification status
  /// - Event: category, event type, host ID, location
  /// - User: user preferences, engagement level
  /// - Sponsor: sponsor type, categories
  final Map<String, dynamic> entityCharacteristics;

  /// Location quantum state (simplified for entity state vectors)
  /// [latitude_quantum_state, longitude_quantum_state, location_type, accessibility_score, vibe_location_match]ᵀ
  final EntityLocationQuantumState? location;

  /// Timing quantum state (for entity state vectors)
  /// [time_of_day_preference, day_of_week_preference, frequency_preference, duration_preference, timing_vibe_match]ᵀ
  final EntityTimingQuantumState? timing;

  /// Atomic timestamp of state creation
  /// Critical for quantum temporal calculations and entanglement synchronization
  final AtomicTimestamp tAtomic;

  /// Normalization factor (ensures ⟨ψ_entity|ψ_entity⟩ = 1)
  final double normalizationFactor;

  QuantumEntityState({
    required this.entityId,
    required this.entityType,
    required this.personalityState,
    required this.quantumVibeAnalysis,
    required this.entityCharacteristics,
    this.location,
    this.timing,
    required this.tAtomic,
    double? normalizationFactor,
  }) : normalizationFactor = normalizationFactor ?? 1.0;

  /// Calculate norm: ⟨ψ_entity|ψ_entity⟩
  double _calculateNorm() {
    double sum = 0.0;

    // Personality state contribution
    for (final value in personalityState.values) {
      sum += value * value;
    }

    // Quantum vibe analysis contribution
    for (final value in quantumVibeAnalysis.values) {
      sum += value * value;
    }

    // Location contribution (if present)
    if (location != null) {
      sum += location!.normSquared;
    }

    // Timing contribution (if present)
    if (timing != null) {
      sum += timing!.normSquared;
    }

    return sum;
  }

  /// Get normalized state (ensures ⟨ψ_entity|ψ_entity⟩ = 1)
  QuantumEntityState normalized() {
    final norm = _calculateNorm();
    if (norm < 0.0001) {
      // State is essentially zero, return as-is
      return this;
    }

    final scale = 1.0 / math.sqrt(norm);
    return QuantumEntityState(
      entityId: entityId,
      entityType: entityType,
      personalityState: personalityState.map((k, v) => MapEntry(k, v * scale)),
      quantumVibeAnalysis: quantumVibeAnalysis.map((k, v) => MapEntry(k, v * scale)),
      entityCharacteristics: entityCharacteristics,
      location: location?.scaled(scale),
      timing: timing?.scaled(scale),
      tAtomic: tAtomic,
      normalizationFactor: normalizationFactor * scale,
    );
  }

  /// Check if state is normalized (within tolerance)
  bool get isNormalized {
    final norm = _calculateNorm();
    return (norm - 1.0).abs() < 0.0001;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType.name,
      'personalityState': personalityState,
      'quantumVibeAnalysis': quantumVibeAnalysis,
      'entityCharacteristics': entityCharacteristics,
      'location': location?.toJson(),
      'timing': timing?.toJson(),
      'tAtomic': tAtomic.toJson(),
      'normalizationFactor': normalizationFactor,
    };
  }

  /// Create from JSON
  factory QuantumEntityState.fromJson(Map<String, dynamic> json) {
    return QuantumEntityState(
      entityId: json['entityId'] as String,
      entityType: QuantumEntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
        orElse: () => QuantumEntityType.user,
      ),
      personalityState: Map<String, double>.from(json['personalityState'] as Map),
      quantumVibeAnalysis: Map<String, double>.from(json['quantumVibeAnalysis'] as Map),
      entityCharacteristics: Map<String, dynamic>.from(json['entityCharacteristics'] as Map),
      location: json['location'] != null
          ? EntityLocationQuantumState.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      timing: json['timing'] != null
          ? EntityTimingQuantumState.fromJson(json['timing'] as Map<String, dynamic>)
          : null,
      tAtomic: AtomicTimestamp.fromJson(json['tAtomic'] as Map<String, dynamic>),
      normalizationFactor: (json['normalizationFactor'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'QuantumEntityState(entityId: $entityId, type: $entityType, tAtomic: $tAtomic, normalized: $isNormalized)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuantumEntityState && other.entityId == entityId && other.tAtomic.timestampId == tAtomic.timestampId;
  }

  @override
  int get hashCode => Object.hash(entityId, tAtomic.timestampId);
}

/// Entity location quantum state (simplified for entity state vectors)
///
/// **Formula:**
/// |ψ_location(t_atomic)⟩ = [latitude_quantum_state, longitude_quantum_state, location_type, accessibility_score, vibe_location_match]ᵀ
///
/// **Note:** This is a simplified representation for entity state vectors.
/// For full quantum superposition location states, see `LocationQuantumState` in `lib/core/ai/quantum/location_quantum_state.dart`
class EntityLocationQuantumState {
  final double latitudeQuantumState;
  final double longitudeQuantumState;
  final String locationType; // e.g., "restaurant", "venue", "outdoor"
  final double accessibilityScore; // 0.0 to 1.0
  final double vibeLocationMatch; // 0.0 to 1.0

  EntityLocationQuantumState({
    required this.latitudeQuantumState,
    required this.longitudeQuantumState,
    required this.locationType,
    required this.accessibilityScore,
    required this.vibeLocationMatch,
  });

  /// Calculate norm squared: |ψ_location|²
  double get normSquared {
    return latitudeQuantumState * latitudeQuantumState +
        longitudeQuantumState * longitudeQuantumState +
        accessibilityScore * accessibilityScore +
        vibeLocationMatch * vibeLocationMatch;
  }

  /// Scale location state
  EntityLocationQuantumState scaled(double scale) {
    return EntityLocationQuantumState(
      latitudeQuantumState: latitudeQuantumState * scale,
      longitudeQuantumState: longitudeQuantumState * scale,
      locationType: locationType,
      accessibilityScore: accessibilityScore * scale,
      vibeLocationMatch: vibeLocationMatch * scale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitudeQuantumState': latitudeQuantumState,
      'longitudeQuantumState': longitudeQuantumState,
      'locationType': locationType,
      'accessibilityScore': accessibilityScore,
      'vibeLocationMatch': vibeLocationMatch,
    };
  }

  factory EntityLocationQuantumState.fromJson(Map<String, dynamic> json) {
    return EntityLocationQuantumState(
      latitudeQuantumState: (json['latitudeQuantumState'] as num).toDouble(),
      longitudeQuantumState: (json['longitudeQuantumState'] as num).toDouble(),
      locationType: json['locationType'] as String,
      accessibilityScore: (json['accessibilityScore'] as num).toDouble(),
      vibeLocationMatch: (json['vibeLocationMatch'] as num).toDouble(),
    );
  }
}

/// Entity timing quantum state (for entity state vectors)
///
/// **Formula:**
/// |ψ_timing(t_atomic)⟩ = [time_of_day_preference, day_of_week_preference, frequency_preference, duration_preference, timing_vibe_match]ᵀ
class EntityTimingQuantumState {
  final double timeOfDayPreference; // 0.0 (morning) to 1.0 (night)
  final double dayOfWeekPreference; // 0.0 (weekday) to 1.0 (weekend)
  final double frequencyPreference; // 0.0 (rare) to 1.0 (frequent)
  final double durationPreference; // 0.0 (short) to 1.0 (long)
  final double timingVibeMatch; // 0.0 to 1.0

  EntityTimingQuantumState({
    required this.timeOfDayPreference,
    required this.dayOfWeekPreference,
    required this.frequencyPreference,
    required this.durationPreference,
    required this.timingVibeMatch,
  });

  /// Get time of day as hour (0-23)
  /// Converts normalized value (0-1) back to hour of day
  int get timeOfDayHour => (timeOfDayPreference * 24).round().clamp(0, 23);

  /// Get day of week as index (0-6, where 0 = Monday, 6 = Sunday)
  /// Note: This is derived from the preference value, not a direct mapping
  /// For exact day mapping, use prefersWeekend/prefersWeekday
  int get dayOfWeekIndex {
    // Convert preference (0.0 = weekday, 1.0 = weekend) to a day index
    // This is approximate - exact day requires more information
    return dayOfWeekPreference > 0.5 ? 6 : 0; // Weekend -> Sunday, Weekday -> Monday
  }

  /// Check if prefers weekend
  bool get prefersWeekend => dayOfWeekPreference > 0.5;

  /// Check if prefers weekday
  bool get prefersWeekday => dayOfWeekPreference < 0.5;

  /// Calculate norm squared: |ψ_timing|²
  double get normSquared {
    return timeOfDayPreference * timeOfDayPreference +
        dayOfWeekPreference * dayOfWeekPreference +
        frequencyPreference * frequencyPreference +
        durationPreference * durationPreference +
        timingVibeMatch * timingVibeMatch;
  }

  /// Scale timing state
  EntityTimingQuantumState scaled(double scale) {
    return EntityTimingQuantumState(
      timeOfDayPreference: timeOfDayPreference * scale,
      dayOfWeekPreference: dayOfWeekPreference * scale,
      frequencyPreference: frequencyPreference * scale,
      durationPreference: durationPreference * scale,
      timingVibeMatch: timingVibeMatch * scale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeOfDayPreference': timeOfDayPreference,
      'dayOfWeekPreference': dayOfWeekPreference,
      'frequencyPreference': frequencyPreference,
      'durationPreference': durationPreference,
      'timingVibeMatch': timingVibeMatch,
    };
  }

  factory EntityTimingQuantumState.fromJson(Map<String, dynamic> json) {
    return EntityTimingQuantumState(
      timeOfDayPreference: (json['timeOfDayPreference'] as num).toDouble(),
      dayOfWeekPreference: (json['dayOfWeekPreference'] as num).toDouble(),
      frequencyPreference: (json['frequencyPreference'] as num).toDouble(),
      durationPreference: (json['durationPreference'] as num).toDouble(),
      timingVibeMatch: (json['timingVibeMatch'] as num).toDouble(),
    );
  }
}