// Quantum Compute Backend Interface
//
// Abstract interface for quantum computation backends.
// Allows swapping between classical simulation and cloud quantum hardware
// without changing the rest of the codebase.
//
// Phase: ML Reality and Quantum Readiness - Phase 4.1

import 'package:avrai_core/models/quantum_entity_state.dart';

/// Entangled quantum state result from N-way entanglement computation
class EntangledQuantumState {
  /// Entity IDs involved in the entanglement
  final List<String> entityIds;

  /// Entanglement strength (0.0 = no entanglement, 1.0 = maximal)
  final double entanglementStrength;

  /// Pairwise fidelity scores between entities
  final Map<String, double> pairwiseFidelities;

  /// The combined state vector (classical representation)
  final List<double> combinedStateVector;

  /// Whether this was computed on real quantum hardware
  final bool isQuantumComputed;

  /// Backend that computed this state
  final String backendName;

  EntangledQuantumState({
    required this.entityIds,
    required this.entanglementStrength,
    required this.pairwiseFidelities,
    required this.combinedStateVector,
    required this.isQuantumComputed,
    required this.backendName,
  });
}

/// Abstract interface for quantum computation
///
/// Provides a clean abstraction layer so quantum compute can be swapped
/// from classical simulation to cloud quantum hardware without touching
/// the rest of the codebase.
///
/// **Current implementation:** [ClassicalQuantumBackend] wraps the existing
/// quantum-inspired math (inner products, tensor products, ONNX models).
///
/// **Future implementation:** [CloudQuantumBackend] will call IBM Quantum,
/// AWS Braket, or Google Cirq for true quantum computation when entity
/// counts are large enough to benefit (typically N >= 5).
abstract class QuantumComputeBackend {
  /// Calculate fidelity (compatibility) between two quantum states
  ///
  /// Returns a value between 0.0 (orthogonal) and 1.0 (identical).
  /// This is the core operation for pairwise matching.
  Future<double> calculateFidelity(
    List<double> stateA,
    List<double> stateB,
  );

  /// Create N-way entangled state from entity quantum states
  ///
  /// For 2 entities this is a simple inner product.
  /// For N >= 3, this involves tensor products and becomes exponentially
  /// expensive on classical hardware -- the primary quantum advantage case.
  Future<EntangledQuantumState> createEntangledState(
    List<QuantumEntityState> entityStates,
  );

  /// Detect entanglement patterns from personality dimensions
  ///
  /// Returns dimension correlation strengths indicating which personality
  /// dimensions are "entangled" (correlated) for a given profile.
  Future<Map<String, double>> detectEntanglementPatterns(
    Map<String, double> personalityDimensions,
  );

  /// Optimize superposition weights for a use case
  ///
  /// Determines the optimal weights for combining multiple data sources
  /// (personality, behavioral, relationship, temporal, contextual) into
  /// a single quantum state.
  Future<Map<String, double>> optimizeSuperpositionWeights(
    Map<String, double> personalityDimensions,
    String useCase,
  );

  /// Whether this backend uses true quantum hardware
  bool get isQuantumHardware;

  /// Backend name for logging and metrics
  String get backendName;

  /// Initialize the backend (load models, connect to services, etc.)
  Future<void> initialize();

  /// Dispose of resources
  Future<void> dispose();
}
