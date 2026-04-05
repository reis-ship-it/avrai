// Quantum Error Correction Code Model
//
// Models for quantum error correction codes
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

/// Type of quantum error
enum QuantumErrorType {
  bitFlip, // X error (flips |0⟩ ↔ |1⟩)
  phaseFlip, // Z error (flips phase: |+⟩ ↔ |-⟩)
  both, // Y error (both bit and phase flip)
}

/// Quantum error correction code type
enum QuantumErrorCorrectionCode {
  repetition3, // 3-qubit repetition code (simple, corrects single bit-flip)
  shor, // Shor 9-qubit code (corrects both bit-flip and phase-flip)
  steane, // Steane 7-qubit code (more efficient than Shor)
}

/// Encoded quantum state with error correction
class EncodedQuantumState {
  /// Original state data (before encoding)
  final Map<String, double> originalState;

  /// Encoded state (with redundancy for error correction)
  final List<double> encodedData;

  /// Error correction code used
  final QuantumErrorCorrectionCode code;

  /// Parity check results (for error detection)
  final List<bool> parityChecks;

  EncodedQuantumState({
    required this.originalState,
    required this.encodedData,
    required this.code,
    required this.parityChecks,
  });

  /// Create from JSON
  factory EncodedQuantumState.fromJson(Map<String, dynamic> json) {
    return EncodedQuantumState(
      originalState: Map<String, double>.from(
        (json['originalState'] as Map<dynamic, dynamic>?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
            {},
      ),
      encodedData: List<double>.from(json['encodedData'] ?? []),
      code: QuantumErrorCorrectionCode.values.firstWhere(
        (c) => c.name == json['code'],
        orElse: () => QuantumErrorCorrectionCode.repetition3,
      ),
      parityChecks: List<bool>.from(json['parityChecks'] ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'originalState': originalState,
      'encodedData': encodedData,
      'code': code.name,
      'parityChecks': parityChecks,
    };
  }
}

/// Detected error information
class DetectedError {
  /// Type of error detected
  final QuantumErrorType errorType;

  /// Position(s) where error occurred (qubit indices)
  final List<int> errorPositions;

  /// Confidence level (0.0-1.0) in error detection
  final double confidence;

  DetectedError({
    required this.errorType,
    required this.errorPositions,
    required this.confidence,
  });
}
