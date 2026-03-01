// Temporal Interference Service
//
// Service for detecting constructive/destructive interference patterns in temporal quantum states
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'quantum_temporal_state.dart';

/// Type of temporal interference
enum TemporalInterferenceType {
  constructive, // Phases align - higher compatibility
  destructive, // Phases oppose - lower compatibility
  neutral, // No clear interference pattern
}

/// Temporal interference pattern result
class TemporalInterferencePattern {
  /// Type of interference
  final TemporalInterferenceType type;

  /// Interference strength (0.0-1.0)
  final double strength;

  /// Phase difference (in radians)
  final double phaseDifference;

  /// Affected frequencies (daily, weekly, seasonal)
  final List<String> affectedFrequencies;

  TemporalInterferencePattern({
    required this.type,
    required this.strength,
    required this.phaseDifference,
    required this.affectedFrequencies,
  });
}

/// Service for detecting temporal interference patterns
///
/// **Responsibilities:**
/// - Detect constructive/destructive interference between temporal states
/// - Calculate phase differences at multiple frequencies
/// - Predict interference effects on compatibility
class TemporalInterferenceService {
  static const String _logName = 'TemporalInterferenceService';

  /// Detect interference pattern between two temporal states
  ///
  /// **Returns:**
  /// - TemporalInterferencePattern with type, strength, and affected frequencies
  ///
  /// **Parameters:**
  /// - `state1`: First quantum temporal state
  /// - `state2`: Second quantum temporal state
  Future<TemporalInterferencePattern> detectInterferencePattern({
    required QuantumTemporalState state1,
    required QuantumTemporalState state2,
  }) async {
    developer.log(
      'Detecting temporal interference pattern',
      name: _logName,
    );

    try {
      // Extract phase states (last 6 elements: daily, weekly, seasonal phases)
      final phase1 = state1.phaseState;
      final phase2 = state2.phaseState;

      if (phase1.length < 6 || phase2.length < 6) {
        // Fallback for old format (single phase)
        return _detectSinglePhaseInterference(phase1, phase2);
      }

      // Analyze interference at each frequency
      final dailyInterference = _analyzePhaseInterference(
        phase1[0], phase1[1], // daily cos, sin
        phase2[0], phase2[1],
      );

      final weeklyInterference = _analyzePhaseInterference(
        phase1[2], phase1[3], // weekly cos, sin
        phase2[2], phase2[3],
      );

      final seasonalInterference = _analyzePhaseInterference(
        phase1[4], phase1[5], // seasonal cos, sin
        phase2[4], phase2[5],
      );

      // Determine overall interference type
      final interferences = [
        dailyInterference,
        weeklyInterference,
        seasonalInterference
      ];
      final constructiveCount =
          interferences.where((i) => i['type'] == 'constructive').length;
      final destructiveCount =
          interferences.where((i) => i['type'] == 'destructive').length;

      TemporalInterferenceType overallType;
      if (constructiveCount > destructiveCount) {
        overallType = TemporalInterferenceType.constructive;
      } else if (destructiveCount > constructiveCount) {
        overallType = TemporalInterferenceType.destructive;
      } else {
        overallType = TemporalInterferenceType.neutral;
      }

      // Calculate overall strength (average of all frequencies)
      final avgStrength = interferences
              .map((i) => i['strength'] as double)
              .reduce((a, b) => a + b) /
          interferences.length;

      // Calculate average phase difference
      final avgPhaseDiff = interferences
              .map((i) => i['phaseDiff'] as double)
              .reduce((a, b) => a + b) /
          interferences.length;

      // Determine affected frequencies
      final affectedFrequencies = <String>[];
      if (dailyInterference['strength'] as double > 0.5) {
        affectedFrequencies.add('daily');
      }
      if (weeklyInterference['strength'] as double > 0.5) {
        affectedFrequencies.add('weekly');
      }
      if (seasonalInterference['strength'] as double > 0.5) {
        affectedFrequencies.add('seasonal');
      }

      final pattern = TemporalInterferencePattern(
        type: overallType,
        strength: avgStrength,
        phaseDifference: avgPhaseDiff,
        affectedFrequencies: affectedFrequencies,
      );

      developer.log(
        '✅ Detected interference: type=${pattern.type.name}, strength=${pattern.strength.toStringAsFixed(3)}',
        name: _logName,
      );

      return pattern;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to detect interference pattern: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate temporal compatibility with interference correction
  ///
  /// **Returns:**
  /// - Corrected compatibility score accounting for interference
  ///
  /// **Parameters:**
  /// - `state1`: First quantum temporal state
  /// - `state2`: Second quantum temporal state
  Future<double> calculateInterferenceCorrectedCompatibility({
    required QuantumTemporalState state1,
    required QuantumTemporalState state2,
  }) async {
    // Calculate base compatibility
    final baseCompatibility = state1.temporalCompatibility(state2);

    // Detect interference pattern
    final interference = await detectInterferencePattern(
      state1: state1,
      state2: state2,
    );

    // Apply interference correction
    double correctedCompatibility;
    switch (interference.type) {
      case TemporalInterferenceType.constructive:
        // Constructive interference increases compatibility
        correctedCompatibility =
            baseCompatibility + (interference.strength * 0.1);
        break;
      case TemporalInterferenceType.destructive:
        // Destructive interference decreases compatibility
        correctedCompatibility =
            baseCompatibility - (interference.strength * 0.1);
        break;
      case TemporalInterferenceType.neutral:
        correctedCompatibility = baseCompatibility;
        break;
    }

    return correctedCompatibility.clamp(0.0, 1.0);
  }

  /// Analyze phase interference between two phase components
  Map<String, dynamic> _analyzePhaseInterference(
    double cos1,
    double sin1,
    double cos2,
    double sin2,
  ) {
    // Calculate phase angles
    final phase1 = math.atan2(sin1, cos1);
    final phase2 = math.atan2(sin2, cos2);

    // Calculate phase difference
    var phaseDiff = (phase2 - phase1).abs();
    if (phaseDiff > math.pi) {
      phaseDiff = 2 * math.pi - phaseDiff;
    }

    // Determine interference type
    String type;
    if (phaseDiff < math.pi / 4) {
      // Phases are aligned (within 45 degrees)
      type = 'constructive';
    } else if (phaseDiff > 3 * math.pi / 4) {
      // Phases are opposed (more than 135 degrees)
      type = 'destructive';
    } else {
      type = 'neutral';
    }

    // Calculate interference strength (based on phase alignment)
    final strength = type == 'constructive'
        ? 1.0 - (phaseDiff / (math.pi / 4))
        : type == 'destructive'
            ? (phaseDiff - 3 * math.pi / 4) / (math.pi / 4)
            : 0.5;

    return {
      'type': type,
      'strength': strength.clamp(0.0, 1.0),
      'phaseDiff': phaseDiff,
    };
  }

  /// Detect interference for single-phase format (backward compatibility)
  TemporalInterferencePattern _detectSinglePhaseInterference(
    List<double> phase1,
    List<double> phase2,
  ) {
    if (phase1.length < 2 || phase2.length < 2) {
      return TemporalInterferencePattern(
        type: TemporalInterferenceType.neutral,
        strength: 0.0,
        phaseDifference: 0.0,
        affectedFrequencies: [],
      );
    }

    final interference = _analyzePhaseInterference(
      phase1[0],
      phase1[1],
      phase2[0],
      phase2[1],
    );

    return TemporalInterferencePattern(
      type: interference['type'] == 'constructive'
          ? TemporalInterferenceType.constructive
          : interference['type'] == 'destructive'
              ? TemporalInterferenceType.destructive
              : TemporalInterferenceType.neutral,
      strength: interference['strength'] as double,
      phaseDifference: interference['phaseDiff'] as double,
      affectedFrequencies: ['daily'], // Single phase = daily only
    );
  }
}
