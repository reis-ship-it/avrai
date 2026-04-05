// Classical Quantum Backend
//
// Wraps the existing quantum-inspired classical math and ONNX models.
// This is what runs on-device today -- no behavior change from wrapping.
//
// Phase: ML Reality and Quantum Readiness - Phase 4.2

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_runtime_os/ai/quantum/quantum_compute_backend.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_entanglement_ml_service.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_ml_optimizer.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';

/// Classical implementation of [QuantumComputeBackend]
///
/// Uses quantum-inspired linear algebra (inner products, tensor products)
/// running on classical CPU. Delegates to ONNX models for optimization
/// and entanglement detection when available, with rule-based fallback.
///
/// This wraps the existing math from [QuantumVibeEngine],
/// [QuantumEntanglementMLService], and [QuantumMLOptimizer].
class ClassicalQuantumBackend implements QuantumComputeBackend {
  static const String _logName = 'ClassicalQuantumBackend';

  final QuantumEntanglementMLService? _entanglementService;
  final QuantumMLOptimizer? _mlOptimizer;
  bool _initialized = false;

  ClassicalQuantumBackend({
    QuantumEntanglementMLService? entanglementService,
    QuantumMLOptimizer? mlOptimizer,
  })  : _entanglementService = entanglementService,
        _mlOptimizer = mlOptimizer;

  @override
  bool get isQuantumHardware => false;

  @override
  String get backendName => 'classical';

  /// Whether the ONNX entanglement model is loaded
  bool get isEntanglementOnnxLoaded =>
      _entanglementService != null && _initialized;

  /// Whether the ONNX optimization model is loaded
  bool get isOptimizationOnnxLoaded => _mlOptimizer != null && _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    developer.log('Initializing classical quantum backend', name: _logName);

    // Initialize ONNX models (non-fatal if they fail)
    if (_entanglementService != null) {
      try {
        await _entanglementService.initialize();
        developer.log('Entanglement ONNX model loaded', name: _logName);
      } catch (e) {
        developer.log(
          'Entanglement ONNX model failed to load, using fallback: $e',
          name: _logName,
        );
      }
    }

    if (_mlOptimizer != null) {
      try {
        await _mlOptimizer.initialize();
        developer.log('Quantum optimization ONNX model loaded', name: _logName);
      } catch (e) {
        developer.log(
          'Quantum optimization ONNX model failed to load, using fallback: $e',
          name: _logName,
        );
      }
    }

    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    // ONNX sessions are managed by their respective services
    _initialized = false;
  }

  @override
  Future<double> calculateFidelity(
    List<double> stateA,
    List<double> stateB,
  ) async {
    // Classical inner product: |<A|B>|^2
    // This is the quantum fidelity between two pure states
    if (stateA.length != stateB.length || stateA.isEmpty) {
      return 0.0;
    }

    // Normalize states
    final normA = _normalize(stateA);
    final normB = _normalize(stateB);

    // Inner product
    double innerProduct = 0.0;
    for (int i = 0; i < normA.length; i++) {
      innerProduct += normA[i] * normB[i];
    }

    // Fidelity = |<A|B>|^2
    return (innerProduct * innerProduct).clamp(0.0, 1.0);
  }

  @override
  Future<EntangledQuantumState> createEntangledState(
    List<QuantumEntityState> entityStates,
  ) async {
    if (entityStates.isEmpty) {
      return EntangledQuantumState(
        entityIds: [],
        entanglementStrength: 0.0,
        pairwiseFidelities: {},
        combinedStateVector: [],
        isQuantumComputed: false,
        backendName: backendName,
      );
    }

    if (entityStates.length == 1) {
      final state = entityStates.first;
      return EntangledQuantumState(
        entityIds: [state.entityId],
        entanglementStrength: 1.0,
        pairwiseFidelities: {},
        combinedStateVector: state.personalityState.values.toList(),
        isQuantumComputed: false,
        backendName: backendName,
      );
    }

    // Compute pairwise fidelities
    final pairwiseFidelities = <String, double>{};

    for (int i = 0; i < entityStates.length; i++) {
      for (int j = i + 1; j < entityStates.length; j++) {
        final stateA = entityStates[i].personalityState.values.toList();
        final stateB = entityStates[j].personalityState.values.toList();
        final fidelity = await calculateFidelity(stateA, stateB);

        final key = '${entityStates[i].entityId}_${entityStates[j].entityId}';
        pairwiseFidelities[key] = fidelity;
      }
    }

    // For N-way entanglement on classical hardware:
    // average the state vectors (simplified tensor product)
    final dim = entityStates.first.personalityState.length;
    final combined = List<double>.filled(dim, 0.0);
    for (final state in entityStates) {
      final values = state.personalityState.values.toList();
      for (int d = 0; d < dim && d < values.length; d++) {
        combined[d] += values[d] / entityStates.length;
      }
    }

    // Entanglement strength: geometric mean of pairwise fidelities
    // gives higher penalty for any weak link
    double entanglementStrength;
    if (pairwiseFidelities.isEmpty) {
      entanglementStrength = 0.0;
    } else {
      double product = 1.0;
      for (final f in pairwiseFidelities.values) {
        product *= f;
      }
      entanglementStrength = math
          .pow(product, 1.0 / pairwiseFidelities.length)
          .toDouble()
          .clamp(0.0, 1.0);
    }

    return EntangledQuantumState(
      entityIds: entityStates.map((e) => e.entityId).toList(),
      entanglementStrength: entanglementStrength,
      pairwiseFidelities: pairwiseFidelities,
      combinedStateVector: combined,
      isQuantumComputed: false,
      backendName: backendName,
    );
  }

  @override
  Future<Map<String, double>> detectEntanglementPatterns(
    Map<String, double> personalityDimensions,
  ) async {
    // Delegate to ONNX entanglement ML service if available
    if (_entanglementService != null) {
      try {
        // Build a minimal PersonalityProfile from the dimension map
        final now = DateTime.now();
        final profile = PersonalityProfile(
          agentId: 'entanglement_query',
          dimensions: personalityDimensions,
          dimensionConfidence: {
            for (final key in personalityDimensions.keys) key: 0.8,
          },
          archetype: 'unknown',
          authenticity: 0.8,
          createdAt: now,
          lastUpdated: now,
          evolutionGeneration: 0,
          learningHistory: const {},
        );
        final result = await _entanglementService.detectEntanglementPatterns(
          profile,
        );
        return result;
      } catch (e) {
        developer.log(
          'ONNX entanglement detection failed, using fallback: $e',
          name: _logName,
        );
      }
    }

    // Fallback: hardcoded correlation groups
    return _fallbackEntanglementPatterns(personalityDimensions);
  }

  @override
  Future<Map<String, double>> optimizeSuperpositionWeights(
    Map<String, double> personalityDimensions,
    String useCase,
  ) async {
    // Delegate to ONNX ML optimizer if available
    if (_mlOptimizer != null) {
      try {
        // Build a QuantumEntityState from the dimension map
        final entityState = QuantumEntityState(
          entityId: 'optimization_query',
          entityType: QuantumEntityType.user,
          personalityState: personalityDimensions,
          quantumVibeAnalysis: personalityDimensions,
          entityCharacteristics: const {},
          tAtomic: AtomicTimestamp.now(precision: TimePrecision.millisecond),
          normalizationFactor: 1.0,
        );

        // Map useCase string to QuantumUseCase enum
        final qUseCase = _mapUseCase(useCase);

        final onnxResult = await _mlOptimizer.optimizeSuperpositionWeights(
          state: entityState,
          sources: QuantumDataSource.values,
          useCase: qUseCase,
        );

        // Convert QuantumDataSource keys to strings
        return onnxResult.map(
          (key, value) => MapEntry(key.name, value),
        );
      } catch (e) {
        developer.log(
          'ONNX optimization failed, using fallback: $e',
          name: _logName,
        );
      }
    }

    // Fallback: equal weights
    return {
      'personality': 0.35,
      'behavioral': 0.25,
      'relationship': 0.20,
      'temporal': 0.10,
      'contextual': 0.10,
    };
  }

  // ---- Private helpers ----

  List<double> _normalize(List<double> vector) {
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm == 0.0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  Map<String, double> _fallbackEntanglementPatterns(
    Map<String, double> dims,
  ) {
    // Known correlated dimension groups (hardcoded)
    // These represent dimensions that tend to move together
    return {
      'exploration_community': _correlationStrength(
        dims['exploration_eagerness'] ?? 0.5,
        dims['community_orientation'] ?? 0.5,
      ),
      'energy_social': _correlationStrength(
        dims['energy_preference'] ?? 0.5,
        dims['social_discovery_style'] ?? 0.5,
      ),
      'authenticity_curation': _correlationStrength(
        dims['authenticity_preference'] ?? 0.5,
        dims['curation_tendency'] ?? 0.5,
      ),
      'novelty_exploration': _correlationStrength(
        dims['novelty_seeking'] ?? 0.5,
        dims['exploration_eagerness'] ?? 0.5,
      ),
      'trust_community': _correlationStrength(
        dims['trust_network_reliance'] ?? 0.5,
        dims['community_orientation'] ?? 0.5,
      ),
      'value_curation': _correlationStrength(
        dims['value_orientation'] ?? 0.5,
        dims['curation_tendency'] ?? 0.5,
      ),
    };
  }

  QuantumUseCase _mapUseCase(String useCase) {
    switch (useCase.toLowerCase()) {
      case 'matching':
        return QuantumUseCase.matching;
      case 'recommendation':
        return QuantumUseCase.recommendation;
      case 'compatibility':
        return QuantumUseCase.compatibility;
      case 'prediction':
        return QuantumUseCase.prediction;
      case 'analysis':
        return QuantumUseCase.analysis;
      default:
        return QuantumUseCase.matching;
    }
  }

  double _correlationStrength(double a, double b) {
    // Simple correlation: 1 - |a - b| scaled to give higher values
    // when both are extreme (both high or both low)
    final similarity = 1.0 - (a - b).abs();
    final extremity = ((a - 0.5).abs() + (b - 0.5).abs()) / 2.0;
    return (similarity * 0.7 + extremity * 0.3).clamp(0.0, 1.0);
  }
}
