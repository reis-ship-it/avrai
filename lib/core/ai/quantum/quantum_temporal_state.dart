import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Quantum Temporal State
///
/// Represents a quantum temporal state `|ψ_temporal⟩ = |t_atomic⟩ ⊗ |t_quantum⟩ ⊗ |t_phase⟩`
/// for quantum temporal compatibility, entanglement, and decoherence calculations.
///
/// **Patent #30: Quantum Atomic Clock System**
/// This implements the quantum temporal state generation from atomic timestamps.
class QuantumTemporalState {
  /// Atomic timestamp quantum state `|t_atomic⟩`
  final List<double> atomicState;

  /// Quantum temporal state `|t_quantum⟩` (time-of-day, weekday, seasonal)
  final List<double> quantumState;

  /// Quantum phase state `|t_phase⟩`
  final List<double> phaseState;

  /// Complete quantum temporal state `|ψ_temporal⟩`
  final List<double> temporalState;

  /// Atomic timestamp used to generate this state
  final AtomicTimestamp atomicTimestamp;

  QuantumTemporalState({
    required this.atomicState,
    required this.quantumState,
    required this.phaseState,
    required this.temporalState,
    required this.atomicTimestamp,
  });

  /// Calculate quantum inner product with another temporal state
  /// Returns: `⟨ψ_temporal_A|ψ_temporal_B⟩`
  double innerProduct(QuantumTemporalState other) {
    if (temporalState.length != other.temporalState.length) {
      throw ArgumentError('Temporal states must have same dimension');
    }

    double result = 0.0;
    for (int i = 0; i < temporalState.length; i++) {
      result += temporalState[i] * other.temporalState[i];
    }
    return result;
  }

  /// Calculate quantum temporal compatibility
  /// Returns: `C_temporal = |⟨ψ_temporal_A|ψ_temporal_B⟩|²`
  double temporalCompatibility(QuantumTemporalState other) {
    final innerProd = innerProduct(other);
    return innerProd * innerProd; // Squared magnitude
  }

  /// Normalize the quantum temporal state
  void normalize() {
    final norm = math.sqrt(
      temporalState.fold(0.0, (sum, val) => sum + val * val),
    );
    if (norm > 0) {
      for (int i = 0; i < temporalState.length; i++) {
        temporalState[i] /= norm;
      }
    }
  }

  /// Get normalization value
  double get normalization {
    return math.sqrt(
      temporalState.fold(0.0, (sum, val) => sum + val * val),
    );
  }

  @override
  String toString() {
    return 'QuantumTemporalState(norm: ${normalization.toStringAsFixed(4)}, timestamp: $atomicTimestamp)';
  }
}

/// Quantum Temporal State Generator
///
/// Generates quantum temporal states from atomic timestamps.
/// Implements Patent #30: Quantum Atomic Clock System.
class QuantumTemporalStateGenerator {
  static const String _logName = 'QuantumTemporalStateGenerator';

  /// Reference atomic timestamp for phase calculation
  static final DateTime _referenceTime = DateTime(2025, 1, 1);

  /// Period for quantum phase oscillation (1 day)
  static const Duration _phasePeriod = Duration(days: 1);

  /// Generate quantum temporal state from atomic timestamp
  ///
  /// Formula: `|ψ_temporal⟩ = |t_atomic⟩ ⊗ |t_quantum⟩ ⊗ |t_phase⟩`
  static QuantumTemporalState generate(AtomicTimestamp atomicTimestamp) {
    developer.log(
      'Generating quantum temporal state from atomic timestamp: ${atomicTimestamp.timestampId}',
      name: _logName,
    );

    // 1. Generate atomic timestamp quantum state `|t_atomic⟩`
    final atomicState = _generateAtomicState(atomicTimestamp);

    // 2. Generate quantum temporal state `|t_quantum⟩`
    final quantumState = _generateQuantumState(atomicTimestamp);

    // 3. Generate quantum phase state `|t_phase⟩`
    final phaseState = _generatePhaseState(atomicTimestamp);

    // 4. Combine into quantum temporal state (tensor product)
    final temporalState = _combineStates(atomicState, quantumState, phaseState);

    // 5. Normalize
    final normalizedState = _normalizeState(temporalState);

    return QuantumTemporalState(
      atomicState: atomicState,
      quantumState: quantumState,
      phaseState: phaseState,
      temporalState: normalizedState,
      atomicTimestamp: atomicTimestamp,
    );
  }

  /// Generate atomic timestamp quantum state `|t_atomic⟩`
  ///
  /// Formula: `|t_atomic⟩ = √(w_nano) |nanosecond⟩ + √(w_milli) |millisecond⟩ + √(w_second) |second⟩`
  static List<double> _generateAtomicState(AtomicTimestamp atomicTimestamp) {
    final state = <double>[0.0, 0.0, 0.0]; // [nanosecond, millisecond, second]

    // Weights based on precision
    double wNano = 0.0;
    double wMilli = 0.0;
    double wSecond = 0.0;

    if (atomicTimestamp.precision == TimePrecision.nanosecond) {
      wNano = 0.5;
      wMilli = 0.3;
      wSecond = 0.2;
    } else {
      wMilli = 0.6;
      wSecond = 0.4;
    }

    // Normalize weights
    final total = wNano + wMilli + wSecond;
    wNano /= total;
    wMilli /= total;
    wSecond /= total;

    state[0] = math.sqrt(wNano);
    state[1] = math.sqrt(wMilli);
    state[2] = math.sqrt(wSecond);

    return state;
  }

  /// Generate quantum temporal state `|t_quantum⟩`
  ///
  /// Formula: `|t_quantum⟩ = √(w_hour) |hour_of_day⟩ ⊗ √(w_weekday) |weekday⟩ ⊗ √(w_season) |season⟩`
  /// 
  /// **Timezone-Aware:** Uses local time for cross-timezone quantum temporal matching.
  /// This enables matching entities based on local time-of-day (e.g., 9am in Tokyo matches 9am in San Francisco).
  static List<double> _generateQuantumState(AtomicTimestamp atomicTimestamp) {
    // Use LOCAL time for timezone-aware matching
    // This enables cross-timezone quantum temporal compatibility
    final localTime = atomicTimestamp.localTime;

    // Hour of day (0-23) -> 24-dimensional state (LOCAL hour)
    // This is the key innovation: matching based on local time, not UTC
    final hour = localTime.hour;
    final hourState = List<double>.filled(24, 0.0);
    hourState[hour] = 1.0; // One-hot encoding

    // Weekday (0=Monday, 6=Sunday) -> 7-dimensional state (LOCAL weekday)
    final weekday = localTime.weekday - 1; // Convert to 0-6
    final weekdayState = List<double>.filled(7, 0.0);
    weekdayState[weekday] = 1.0; // One-hot encoding

    // Season (Spring, Summer, Fall, Winter) -> 4-dimensional state (LOCAL season)
    final month = localTime.month;
    int seasonIndex;
    if (month >= 3 && month <= 5) {
      seasonIndex = 0; // Spring
    } else if (month >= 6 && month <= 8) {
      seasonIndex = 1; // Summer
    } else if (month >= 9 && month <= 11) {
      seasonIndex = 2; // Fall
    } else {
      seasonIndex = 3; // Winter
    }
    final seasonState = List<double>.filled(4, 0.0);
    seasonState[seasonIndex] = 1.0; // One-hot encoding

    // Combine with weights (tensor product approximation)
    // For simplicity, we'll create a combined state vector
    final combinedState = <double>[];
    combinedState.addAll(hourState.map((v) => v * math.sqrt(0.4)));
    combinedState.addAll(weekdayState.map((v) => v * math.sqrt(0.3)));
    combinedState.addAll(seasonState.map((v) => v * math.sqrt(0.3)));

    return combinedState;
  }

  /// Generate quantum phase state `|t_phase⟩`
  ///
  /// Formula: `|t_phase⟩ = e^(iφ(t_atomic)) |t_atomic⟩`
  /// where `φ(t_atomic) = 2π * (t_atomic - t_atomic_reference) / T_period`
  /// 
  /// **Note:** Phase uses server time for synchronization, but quantum state uses local time for matching
  static List<double> _generatePhaseState(AtomicTimestamp atomicTimestamp) {
    final serverTime = atomicTimestamp.serverTime;
    final timeDiff = serverTime.difference(_referenceTime);
    final phase = (2 * math.pi * timeDiff.inSeconds) / _phasePeriod.inSeconds;

    // Phase state: [cos(φ), sin(φ)]
    return [math.cos(phase), math.sin(phase)];
  }

  /// Combine states using tensor product (simplified)
  ///
  /// Formula: `|ψ_temporal⟩ = |t_atomic⟩ ⊗ |t_quantum⟩ ⊗ |t_phase⟩`
  static List<double> _combineStates(
    List<double> atomicState,
    List<double> quantumState,
    List<double> phaseState,
  ) {
    // Simplified tensor product: concatenate and normalize
    final combined = <double>[];
    combined.addAll(atomicState);
    combined.addAll(quantumState);
    combined.addAll(phaseState);
    return combined;
  }

  /// Normalize quantum temporal state
  ///
  /// Ensures: `⟨ψ_temporal|ψ_temporal⟩ = 1`
  static List<double> _normalizeState(List<double> state) {
    final norm = math.sqrt(
      state.fold(0.0, (sum, val) => sum + val * val),
    );
    if (norm > 0) {
      return state.map((val) => val / norm).toList();
    }
    return state;
  }

  /// Calculate quantum temporal compatibility between two states
  ///
  /// Formula: `C_temporal = |⟨ψ_temporal_A|ψ_temporal_B⟩|²`
  static double calculateTemporalCompatibility(
    QuantumTemporalState stateA,
    QuantumTemporalState stateB,
  ) {
    return stateA.temporalCompatibility(stateB);
  }

  /// Create quantum temporal entanglement between two states
  ///
  /// Formula: `|ψ_temporal_entangled⟩ = |ψ_temporal_A⟩ ⊗ |ψ_temporal_B⟩`
  static QuantumTemporalState createTemporalEntanglement(
    QuantumTemporalState stateA,
    QuantumTemporalState stateB,
  ) {
    // Entangled state is tensor product
    final entangledState = <double>[];
    for (final a in stateA.temporalState) {
      for (final b in stateB.temporalState) {
        entangledState.add(a * b);
      }
    }

    // Normalize
    final normalized = _normalizeState(entangledState);

    // Use combined atomic timestamp
    final combinedTimestamp = stateA.atomicTimestamp.isAfter(stateB.atomicTimestamp)
        ? stateA.atomicTimestamp
        : stateB.atomicTimestamp;

    return QuantumTemporalState(
      atomicState: stateA.atomicState,
      quantumState: stateB.quantumState,
      phaseState: _generatePhaseState(combinedTimestamp),
      temporalState: normalized,
      atomicTimestamp: combinedTimestamp,
    );
  }

  /// Calculate quantum temporal decoherence
  ///
  /// Formula: `|ψ_temporal(t_atomic)⟩ = |ψ_temporal(0)⟩ * e^(-γ_temporal * (t_atomic - t_atomic_0))`
  static QuantumTemporalState calculateTemporalDecoherence(
    QuantumTemporalState initialState,
    AtomicTimestamp currentTimestamp,
    double decoherenceRate,
  ) {
    final timeDiff = currentTimestamp.serverTime
        .difference(initialState.atomicTimestamp.serverTime);
    final timeSeconds = timeDiff.inSeconds.toDouble();
    final decayFactor = math.exp(-decoherenceRate * timeSeconds);

    final decoheredState = initialState.temporalState
        .map((val) => val * decayFactor)
        .toList();

    // Normalize
    final normalized = _normalizeState(decoheredState);

    return QuantumTemporalState(
      atomicState: initialState.atomicState,
      quantumState: initialState.quantumState,
      phaseState: initialState.phaseState,
      temporalState: normalized,
      atomicTimestamp: currentTimestamp,
    );
  }
}

