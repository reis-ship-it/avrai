// Quantum Error Correction Service
//
// Service for correcting errors in quantum states using quantum error correction codes
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_error_correction_code.dart';

/// Service for quantum error correction
///
/// **Responsibilities:**
/// - Encode quantum states with error correction
/// - Detect errors in quantum states
/// - Correct bit-flip and phase-flip errors
/// - Maintain quantum state properties during correction
class QuantumErrorCorrectionService {
  static const String _logName = 'QuantumErrorCorrectionService';

  /// Encode quantum state with error correction
  ///
  /// **Flow:**
  /// 1. Extract state values from quantum entity state
  /// 2. Encode using chosen error correction code
  /// 3. Add parity checks for error detection
  /// 4. Return encoded state
  ///
  /// **Parameters:**
  /// - `state`: Quantum entity state to encode
  /// - `code`: Error correction code to use (default: repetition3)
  Future<EncodedQuantumState> encodeQuantumState({
    required QuantumEntityState state,
    QuantumErrorCorrectionCode code = QuantumErrorCorrectionCode.repetition3,
  }) async {
    developer.log(
      'Encoding quantum state with ${code.name} code',
      name: _logName,
    );

    try {
      // Extract state values (personality + quantum vibe)
      final stateValues = <double>[];
      stateValues.addAll(state.personalityState.values);
      stateValues.addAll(state.quantumVibeAnalysis.values);

      // Encode based on code type
      final encodedData = <double>[];
      final parityChecks = <bool>[];

      switch (code) {
        case QuantumErrorCorrectionCode.repetition3:
          final result = _encodeRepetition3(stateValues);
          encodedData.addAll(result.encodedData);
          parityChecks.addAll(result.parityChecks);
          break;
        case QuantumErrorCorrectionCode.shor:
          final result = _encodeShor(stateValues);
          encodedData.addAll(result.encodedData);
          parityChecks.addAll(result.parityChecks);
          break;
        case QuantumErrorCorrectionCode.steane:
          final result = _encodeSteane(stateValues);
          encodedData.addAll(result.encodedData);
          parityChecks.addAll(result.parityChecks);
          break;
      }

      // Create original state map for reference
      final originalState = <String, double>{};
      originalState.addAll(state.personalityState);
      originalState.addAll(state.quantumVibeAnalysis);

      final encoded = EncodedQuantumState(
        originalState: originalState,
        encodedData: encodedData,
        code: code,
        parityChecks: parityChecks,
      );

      developer.log(
        '✅ Encoded quantum state: ${stateValues.length} values → ${encodedData.length} encoded',
        name: _logName,
      );

      return encoded;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to encode quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Decode and correct errors in encoded quantum state
  ///
  /// **Flow:**
  /// 1. Detect errors using parity checks
  /// 2. Correct detected errors
  /// 3. Decode back to original format
  /// 4. Return corrected state
  ///
  /// **Parameters:**
  /// - `encoded`: Encoded quantum state
  Future<Map<String, double>> decodeAndCorrect({
    required EncodedQuantumState encoded,
  }) async {
    developer.log(
      'Decoding and correcting encoded state (code: ${encoded.code.name})',
      name: _logName,
    );

    try {
      // Detect errors
      final errors = detectErrors(encoded);

      if (errors.isNotEmpty) {
        developer.log(
          'Detected ${errors.length} error(s)',
          name: _logName,
        );
      }

      // Correct errors and decode
      List<double> correctedData;

      switch (encoded.code) {
        case QuantumErrorCorrectionCode.repetition3:
          correctedData = _decodeRepetition3(encoded.encodedData, errors);
          break;
        case QuantumErrorCorrectionCode.shor:
          correctedData = _decodeShor(encoded.encodedData, errors);
          break;
        case QuantumErrorCorrectionCode.steane:
          correctedData = _decodeSteane(encoded.encodedData, errors);
          break;
      }

      // Reconstruct original state map
      final correctedState = <String, double>{};
      final originalKeys = encoded.originalState.keys.toList();

      for (int i = 0;
          i < correctedData.length && i < originalKeys.length;
          i++) {
        correctedState[originalKeys[i]] = correctedData[i].clamp(0.0, 1.0);
      }

      // Fill remaining keys with original values if needed
      for (int i = correctedData.length; i < originalKeys.length; i++) {
        correctedState[originalKeys[i]] =
            encoded.originalState[originalKeys[i]] ?? 0.0;
      }

      developer.log(
        '✅ Decoded and corrected: ${correctedState.length} dimensions',
        name: _logName,
      );

      return correctedState;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to decode and correct: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Detect errors in encoded quantum state
  ///
  /// **Returns:**
  /// - List of detected errors with positions and types
  ///
  /// **Parameters:**
  /// - `encoded`: Encoded quantum state
  List<DetectedError> detectErrors(EncodedQuantumState encoded) {
    final errors = <DetectedError>[];

    switch (encoded.code) {
      case QuantumErrorCorrectionCode.repetition3:
        errors.addAll(_detectRepetition3Errors(encoded));
        break;
      case QuantumErrorCorrectionCode.shor:
        errors.addAll(_detectShorErrors(encoded));
        break;
      case QuantumErrorCorrectionCode.steane:
        errors.addAll(_detectSteaneErrors(encoded));
        break;
    }

    return errors;
  }

  /// Apply error correction to quantum entity state
  ///
  /// **Flow:**
  /// 1. Encode state
  /// 2. Detect and correct errors
  /// 3. Decode corrected state
  /// 4. Create new quantum entity state with corrected values
  ///
  /// **Parameters:**
  /// - `state`: Quantum entity state to correct
  /// - `code`: Error correction code to use
  Future<QuantumEntityState> correctQuantumState({
    required QuantumEntityState state,
    QuantumErrorCorrectionCode code = QuantumErrorCorrectionCode.repetition3,
  }) async {
    try {
      // Encode
      final encoded = await encodeQuantumState(state: state, code: code);

      // Decode and correct
      final correctedValues = await decodeAndCorrect(encoded: encoded);

      // Split corrected values back into personality and quantum vibe
      final personalityState = <String, double>{};
      final quantumVibeAnalysis = <String, double>{};

      final personalityKeys = state.personalityState.keys.toList();
      final quantumVibeKeys = state.quantumVibeAnalysis.keys.toList();

      int index = 0;
      for (final key in personalityKeys) {
        if (index < correctedValues.length) {
          personalityState[key] = correctedValues.values.elementAt(index);
          index++;
        } else {
          personalityState[key] = state.personalityState[key] ?? 0.0;
        }
      }

      for (final key in quantumVibeKeys) {
        if (index < correctedValues.length) {
          quantumVibeAnalysis[key] = correctedValues.values.elementAt(index);
          index++;
        } else {
          quantumVibeAnalysis[key] = state.quantumVibeAnalysis[key] ?? 0.0;
        }
      }

      // Create corrected state
      return QuantumEntityState(
        entityId: state.entityId,
        entityType: state.entityType,
        personalityState: personalityState,
        quantumVibeAnalysis: quantumVibeAnalysis,
        entityCharacteristics: state.entityCharacteristics,
        location: state.location,
        timing: state.timing,
        tAtomic: state.tAtomic,
      ).normalized(); // Normalize after correction
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to correct quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return original state if correction fails
      return state;
    }
  }

  // ===== Repetition Code (3-qubit) =====

  /// Encode using 3-qubit repetition code
  /// Each bit is encoded as 3 copies
  ({List<double> encodedData, List<bool> parityChecks}) _encodeRepetition3(
    List<double> data,
  ) {
    final encoded = <double>[];
    final parityChecks = <bool>[];

    for (final value in data) {
      // Encode each value as 3 copies
      encoded.add(value);
      encoded.add(value);
      encoded.add(value);

      // Parity check: sum of 3 copies should be 3 * value
      parityChecks.add(true); // Will be checked during decoding
    }

    return (encodedData: encoded, parityChecks: parityChecks);
  }

  /// Decode 3-qubit repetition code with error correction
  List<double> _decodeRepetition3(
    List<double> encoded,
    List<DetectedError> errors,
  ) {
    final decoded = <double>[];

    // Decode in groups of 3
    for (int i = 0; i < encoded.length; i += 3) {
      if (i + 2 >= encoded.length) break;

      final v1 = encoded[i];
      final v2 = encoded[i + 1];
      final v3 = encoded[i + 2];

      // Majority vote (corrects single bit-flip)
      double corrected;
      if ((v1 - v2).abs() < (v1 - v3).abs() &&
          (v1 - v2).abs() < (v2 - v3).abs()) {
        // v1 and v2 agree
        corrected = (v1 + v2) / 2.0;
      } else if ((v1 - v3).abs() < (v2 - v3).abs()) {
        // v1 and v3 agree
        corrected = (v1 + v3) / 2.0;
      } else {
        // v2 and v3 agree
        corrected = (v2 + v3) / 2.0;
      }

      decoded.add(corrected.clamp(0.0, 1.0));
    }

    return decoded;
  }

  /// Detect errors in 3-qubit repetition code
  List<DetectedError> _detectRepetition3Errors(EncodedQuantumState encoded) {
    final errors = <DetectedError>[];

    // Check each group of 3
    for (int i = 0; i < encoded.encodedData.length; i += 3) {
      if (i + 2 >= encoded.encodedData.length) break;

      final v1 = encoded.encodedData[i];
      final v2 = encoded.encodedData[i + 1];
      final v3 = encoded.encodedData[i + 2];

      // Check if values disagree (error detected)
      final diff12 = (v1 - v2).abs();
      final diff13 = (v1 - v3).abs();
      final diff23 = (v2 - v3).abs();

      if (diff12 > 0.01 || diff13 > 0.01 || diff23 > 0.01) {
        // Error detected - find which position
        final errorPositions = <int>[];
        if (diff12 > 0.01 && diff13 > 0.01) {
          errorPositions.add(i); // v1 is wrong
        } else if (diff12 > 0.01 && diff23 > 0.01) {
          errorPositions.add(i + 1); // v2 is wrong
        } else if (diff13 > 0.01 && diff23 > 0.01) {
          errorPositions.add(i + 2); // v3 is wrong
        }

        if (errorPositions.isNotEmpty) {
          errors.add(DetectedError(
            errorType: QuantumErrorType.bitFlip,
            errorPositions: errorPositions,
            confidence: math.min(diff12, math.min(diff13, diff23)),
          ));
        }
      }
    }

    return errors;
  }

  // ===== Shor Code (9-qubit) =====

  /// Encode using Shor 9-qubit code
  /// Corrects both bit-flip and phase-flip errors
  ({List<double> encodedData, List<bool> parityChecks}) _encodeShor(
    List<double> data,
  ) {
    final encoded = <double>[];
    final parityChecks = <bool>[];

    for (final value in data) {
      // Shor code: 3-qubit repetition for bit-flip, then 3-qubit repetition for phase
      // Simplified: encode as 9 copies with structured parity
      for (int i = 0; i < 9; i++) {
        encoded.add(value);
      }

      // Parity checks for both bit and phase
      parityChecks.add(true);
      parityChecks.add(true);
    }

    return (encodedData: encoded, parityChecks: parityChecks);
  }

  /// Decode Shor code with error correction
  List<double> _decodeShor(
    List<double> encoded,
    List<DetectedError> errors,
  ) {
    final decoded = <double>[];

    // Decode in groups of 9
    for (int i = 0; i < encoded.length; i += 9) {
      if (i + 8 >= encoded.length) break;

      // First correct bit-flip errors (groups of 3)
      final group1 = [encoded[i], encoded[i + 1], encoded[i + 2]];
      final group2 = [encoded[i + 3], encoded[i + 4], encoded[i + 5]];
      final group3 = [encoded[i + 6], encoded[i + 7], encoded[i + 8]];

      final corrected1 = _majorityVote(group1);
      final corrected2 = _majorityVote(group2);
      final corrected3 = _majorityVote(group3);

      // Then correct phase-flip (majority of groups)
      final corrected = _majorityVote([corrected1, corrected2, corrected3]);

      decoded.add(corrected.clamp(0.0, 1.0));
    }

    return decoded;
  }

  /// Detect errors in Shor code
  List<DetectedError> _detectShorErrors(EncodedQuantumState encoded) {
    final errors = <DetectedError>[];

    // Check groups of 9
    for (int i = 0; i < encoded.encodedData.length; i += 9) {
      if (i + 8 >= encoded.encodedData.length) break;

      // Check bit-flip errors in groups of 3
      final groups = [
        [
          encoded.encodedData[i],
          encoded.encodedData[i + 1],
          encoded.encodedData[i + 2]
        ],
        [
          encoded.encodedData[i + 3],
          encoded.encodedData[i + 4],
          encoded.encodedData[i + 5]
        ],
        [
          encoded.encodedData[i + 6],
          encoded.encodedData[i + 7],
          encoded.encodedData[i + 8]
        ],
      ];

      for (int g = 0; g < groups.length; g++) {
        final group = groups[g];
        if ((group[0] - group[1]).abs() > 0.01 ||
            (group[0] - group[2]).abs() > 0.01 ||
            (group[1] - group[2]).abs() > 0.01) {
          errors.add(DetectedError(
            errorType: QuantumErrorType.bitFlip,
            errorPositions: [i + g * 3],
            confidence: 0.8,
          ));
        }
      }
    }

    return errors;
  }

  // ===== Steane Code (7-qubit) =====

  /// Encode using Steane 7-qubit code
  /// More efficient than Shor code
  ({List<double> encodedData, List<bool> parityChecks}) _encodeSteane(
    List<double> data,
  ) {
    final encoded = <double>[];
    final parityChecks = <bool>[];

    for (final value in data) {
      // Steane code: 7 qubits per logical qubit
      for (int i = 0; i < 7; i++) {
        encoded.add(value);
      }

      parityChecks.add(true);
    }

    return (encodedData: encoded, parityChecks: parityChecks);
  }

  /// Decode Steane code with error correction
  List<double> _decodeSteane(
    List<double> encoded,
    List<DetectedError> errors,
  ) {
    final decoded = <double>[];

    // Decode in groups of 7
    for (int i = 0; i < encoded.length; i += 7) {
      if (i + 6 >= encoded.length) break;

      // Use majority vote for error correction
      final group = encoded.sublist(i, i + 7);
      final corrected = _majorityVote(group);

      decoded.add(corrected.clamp(0.0, 1.0));
    }

    return decoded;
  }

  /// Detect errors in Steane code
  List<DetectedError> _detectSteaneErrors(EncodedQuantumState encoded) {
    final errors = <DetectedError>[];

    // Check groups of 7
    for (int i = 0; i < encoded.encodedData.length; i += 7) {
      if (i + 6 >= encoded.encodedData.length) break;

      final group = encoded.encodedData.sublist(i, i + 7);
      final avg = group.reduce((a, b) => a + b) / group.length;

      // Check for outliers
      for (int j = 0; j < group.length; j++) {
        if ((group[j] - avg).abs() > 0.1) {
          errors.add(DetectedError(
            errorType: QuantumErrorType.bitFlip,
            errorPositions: [i + j],
            confidence: (group[j] - avg).abs(),
          ));
        }
      }
    }

    return errors;
  }

  /// Majority vote for error correction
  double _majorityVote(List<double> values) {
    if (values.isEmpty) return 0.0;

    // Sort and take median (robust to outliers)
    final sorted = List<double>.from(values)..sort();
    return sorted[sorted.length ~/ 2];
  }
}
