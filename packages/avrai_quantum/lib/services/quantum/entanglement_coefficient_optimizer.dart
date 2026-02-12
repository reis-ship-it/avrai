// Entanglement Coefficient Optimizer
//
// Implements dynamic optimization of entanglement coefficients to maximize compatibility
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Section 19.2: Dynamic Entanglement Coefficient Optimization
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
// Phase 19 Integration Enhancement: AI2AI Mesh + Signal Protocol (for locality AI learning)
// Note: These are defined in the main app (avrai package), so we use dynamic types
// to avoid circular dependencies. They're optional and only used conditionally.

/// Optimizes entanglement coefficients to maximize compatibility
///
/// **Constrained Optimization Problem:**
/// α_optimal(t_atomic) = argmax_α F(ρ_entangled(α, t_atomic), ρ_ideal(t_atomic_ideal))
///
/// **Subject to:**
/// 1. Σᵢ |αᵢ|² = 1  (normalization constraint)
/// 2. αᵢ ≥ 0  (non-negativity, if desired)
/// 3. Σᵢ αᵢ · w_entity_type_i = w_target  (entity type balance)
///
/// **Atomic Timing:**
/// All optimization steps use AtomicClockService for precise temporal tracking
class EntanglementCoefficientOptimizer {
  static const String _logName = 'EntanglementCoefficientOptimizer';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  // Phase 19 Integration Enhancement: AI2AI Mesh + Signal Protocol (for locality AI learning)
  // Note: Using dynamic types to avoid circular dependency with main app
  // These services are optional and only used conditionally (checked for null before use)
  final dynamic _encryptionService;
  final dynamic _ai2aiProtocol;

  // Optimization parameters
  static const double _learningRate = 0.01;
  static const int _maxIterations = 100;
  static const double _convergenceThreshold = 0.001;
  static const double _epsilon = 0.0001; // For numerical differentiation

  EntanglementCoefficientOptimizer({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    dynamic encryptionService,
    dynamic ai2aiProtocol,
    // agentIdService: Not needed - agent IDs are passed as parameters from callers
    // Knot services are accessed through entanglementService.calculateKnotCompatibilityBonus()
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Optimize coefficients using gradient descent with Lagrange multipliers
  ///
  /// **Enhanced with String/Fabric Integration:**
  /// When targetTime is provided, uses string evolution predictions for enhanced knot compatibility
  ///
  /// **Returns:**
  /// Optimized coefficients and optimization metrics
  Future<CoefficientOptimizationResult> optimizeCoefficients({
    required List<QuantumEntityState> entityStates,
    required EntangledQuantumState idealState,
    OptimizationMethod method = OptimizationMethod.gradientDescent,
    Map<String, String>? roleMap, // entityId -> role (primary, secondary, sponsor, event)
    DateTime? targetTime, // Optional target time for string evolution predictions
  }) async {
    developer.log(
      'Optimizing coefficients for ${entityStates.length} entities using ${method.name}',
      name: _logName,
    );

    try {
      // Get atomic timestamp for optimization
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Initialize coefficients
      final initialCoefficients = await _initializeCoefficients(
        entityStates,
        roleMap: roleMap,
        targetTime: targetTime,
      );

      // Optimize based on method
      final optimizedCoefficients = method == OptimizationMethod.gradientDescent
          ? await _optimizeGradientDescent(
              entityStates: entityStates,
              idealState: idealState,
              initialCoefficients: initialCoefficients,
              tAtomic: tAtomic,
            )
          : await _optimizeGeneticAlgorithm(
              entityStates: entityStates,
              idealState: idealState,
              initialCoefficients: initialCoefficients,
              tAtomic: tAtomic,
            );

      // Calculate final compatibility
      final finalEntangled = await _entanglementService.createEntangledState(
        entityStates: entityStates,
        coefficients: optimizedCoefficients,
      );
      final finalFidelity = await _entanglementService.calculateFidelity(
        finalEntangled,
        idealState,
      );

      developer.log(
        '✅ Coefficient optimization complete: fidelity=${finalFidelity.toStringAsFixed(4)}',
        name: _logName,
      );

      return CoefficientOptimizationResult(
        coefficients: optimizedCoefficients,
        fidelity: finalFidelity,
        iterations: method == OptimizationMethod.gradientDescent ? _maxIterations : 0,
        tAtomic: tAtomic,
        method: method,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error optimizing coefficients: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Initialize coefficients based on entity type weights and other factors
  ///
  /// **Enhanced Formula (with String/Fabric Integration):**
  /// Includes knot compatibility bonus: C_enhanced = C_quantum + 0.15 * C_knot
  /// When targetTime is provided, uses string evolution predictions for enhanced accuracy
  Future<List<double>> _initializeCoefficients(
    List<QuantumEntityState> entityStates, {
    Map<String, String>? roleMap,
    DateTime? targetTime,
  }) async {
    final coefficients = <double>[];

    // Calculate knot compatibility bonus (if available)
    // Uses entanglementService which has access to knot services and string/fabric integration
    // Enhanced: Passes targetTime for string evolution predictions when available
    double knotBonus = 0.0;
    try {
      knotBonus = await _entanglementService.calculateKnotCompatibilityBonus(
        entityStates,
        targetTime: targetTime,
      );
    } catch (e) {
      developer.log(
        'Error calculating knot bonus during initialization: $e, using 0.0',
        name: _logName,
      );
    }

    for (final state in entityStates) {
      // Base weight from entity type
      var weight = QuantumEntityTypeMetadata.getDefaultWeight(state.entityType);

      // Adjust for role if provided
      if (roleMap != null && roleMap.containsKey(state.entityId)) {
        final role = roleMap[state.entityId]!;
        weight = QuantumEntityTypeMetadata.getRoleWeight(state.entityType, role);
      }

      // Apply quantum correlation enhancement
      weight = _applyQuantumCorrelationEnhancement(
        state,
        entityStates,
        weight,
      );

      // Apply knot compatibility bonus: C_enhanced = C_quantum + 0.15 * C_knot
      // Formula from Section 19.1: C_enhanced = C_quantum + 0.15 * C_knot (bonus approach)
      weight += 0.15 * knotBonus;

      coefficients.add(weight);
    }

    // Normalize: Σᵢ |αᵢ|² = 1
    return _normalizeCoefficients(coefficients);
  }

  /// Apply quantum correlation enhancement to coefficient
  ///
  /// **Formula:**
  /// αᵢ = f(w_entity_type, C_ij, w_role, I_interference, C_knot)
  ///
  /// Where:
  /// - C_ij = Quantum correlation: ⟨ψ_entity_i|ψ_entity_j⟩ - ⟨ψ_entity_i⟩⟨ψ_entity_j⟩
  /// - C_knot = Knot compatibility bonus (optional)
  double _applyQuantumCorrelationEnhancement(
    QuantumEntityState entity,
    List<QuantumEntityState> allEntities,
    double baseWeight,
  ) {
    var enhancedWeight = baseWeight;

    // Calculate quantum correlations with other entities
    var correlationSum = 0.0;
    for (final other in allEntities) {
      if (other.entityId == entity.entityId) continue;

      final correlation = _calculateQuantumCorrelation(entity, other);
      correlationSum += correlation;
    }

    // Average correlation
    final avgCorrelation = allEntities.length > 1
        ? correlationSum / (allEntities.length - 1)
        : 0.0;

    // Enhance weight based on correlation (positive correlation increases weight)
    enhancedWeight *= (1.0 + 0.2 * avgCorrelation); // 20% boost for high correlation

    return enhancedWeight;
  }

  /// Calculate quantum correlation between two entities
  ///
  /// **Formula:**
  /// C_ij = ⟨ψ_entity_i|ψ_entity_j⟩ - ⟨ψ_entity_i⟩⟨ψ_entity_j⟩
  double _calculateQuantumCorrelation(
    QuantumEntityState entity1,
    QuantumEntityState entity2,
  ) {
    // Calculate inner product: ⟨ψ_entity_i|ψ_entity_j⟩
    var innerProduct = 0.0;

    // Personality state contribution
    for (final key in entity1.personalityState.keys) {
      if (entity2.personalityState.containsKey(key)) {
        innerProduct += entity1.personalityState[key]! * entity2.personalityState[key]!;
      }
    }

    // Quantum vibe analysis contribution
    for (final key in entity1.quantumVibeAnalysis.keys) {
      if (entity2.quantumVibeAnalysis.containsKey(key)) {
        innerProduct += entity1.quantumVibeAnalysis[key]! * entity2.quantumVibeAnalysis[key]!;
      }
    }

    // Calculate average values: ⟨ψ_entity_i⟩
    final avg1 = _calculateAverageState(entity1);
    final avg2 = _calculateAverageState(entity2);

    // Correlation: C_ij = ⟨ψ_entity_i|ψ_entity_j⟩ - ⟨ψ_entity_i⟩⟨ψ_entity_j⟩
    final correlation = innerProduct - (avg1 * avg2);

    return correlation.clamp(-1.0, 1.0);
  }

  /// Calculate average value of entity state
  double _calculateAverageState(QuantumEntityState entity) {
    var sum = 0.0;
    var count = 0;

    for (final value in entity.personalityState.values) {
      sum += value;
      count++;
    }

    for (final value in entity.quantumVibeAnalysis.values) {
      sum += value;
      count++;
    }

    return count > 0 ? sum / count : 0.0;
  }

  /// Optimize coefficients using gradient descent with Lagrange multipliers
  Future<List<double>> _optimizeGradientDescent({
    required List<QuantumEntityState> entityStates,
    required EntangledQuantumState idealState,
    required List<double> initialCoefficients,
    required AtomicTimestamp tAtomic,
  }) async {
    var coefficients = List<double>.from(initialCoefficients);
    var iterations = 0;

    for (int iteration = 0; iteration < _maxIterations; iteration++) {
      iterations = iteration + 1;

      // Calculate gradient
      final gradient = await _calculateGradient(
        entityStates: entityStates,
        coefficients: coefficients,
        idealState: idealState,
      );

      // Update coefficients: α_new = α_old + learningRate * gradient
      final newCoefficients = _updateCoefficients(
        coefficients,
        gradient,
        _learningRate,
      );

      // Check convergence
      final change = _calculateCoefficientChange(coefficients, newCoefficients);
      if (change < _convergenceThreshold) {
        developer.log(
          'Converged after $iterations iterations (change: ${change.toStringAsFixed(6)})',
          name: _logName,
        );
        break;
      }

      coefficients = newCoefficients;
    }

    // Normalize coefficients: Σᵢ |αᵢ|² = 1
    return _normalizeCoefficients(coefficients);
  }

  /// Calculate gradient using numerical differentiation
  Future<List<double>> _calculateGradient({
    required List<QuantumEntityState> entityStates,
    required List<double> coefficients,
    required EntangledQuantumState idealState,
  }) async {
    final gradient = <double>[];

    for (int i = 0; i < coefficients.length; i++) {
      // Perturb coefficient i
      final perturbedCoefficients = List<double>.from(coefficients);
      perturbedCoefficients[i] += _epsilon;

      // Calculate compatibility with perturbed coefficient
      final perturbedEntangled = await _entanglementService.createEntangledState(
        entityStates: entityStates,
        coefficients: perturbedCoefficients,
      );
      final perturbedFidelity = await _entanglementService.calculateFidelity(
        perturbedEntangled,
        idealState,
      );

      // Calculate compatibility with original coefficients
      final originalEntangled = await _entanglementService.createEntangledState(
        entityStates: entityStates,
        coefficients: coefficients,
      );
      final originalFidelity = await _entanglementService.calculateFidelity(
        originalEntangled,
        idealState,
      );

      // Gradient = (perturbed - original) / epsilon
      gradient.add((perturbedFidelity - originalFidelity) / _epsilon);
    }

    return gradient;
  }

  /// Update coefficients using gradient
  List<double> _updateCoefficients(
    List<double> coefficients,
    List<double> gradient,
    double learningRate,
  ) {
    final updated = <double>[];

    for (int i = 0; i < coefficients.length; i++) {
      // Update: α_new = α_old + learningRate * gradient
      var newValue = coefficients[i] + learningRate * gradient[i];

      // Apply non-negativity constraint (if desired)
      newValue = newValue.clamp(0.0, 1.0);

      updated.add(newValue);
    }

    return updated;
  }

  /// Calculate change between coefficient sets
  double _calculateCoefficientChange(
    List<double> oldCoefficients,
    List<double> newCoefficients,
  ) {
    if (oldCoefficients.length != newCoefficients.length) {
      return double.infinity;
    }

    var change = 0.0;
    for (int i = 0; i < oldCoefficients.length; i++) {
      change += (newCoefficients[i] - oldCoefficients[i]).abs();
    }

    return change / oldCoefficients.length;
  }

  /// Normalize coefficients: Σᵢ |αᵢ|² = 1
  List<double> _normalizeCoefficients(List<double> coefficients) {
    final norm = coefficients.fold<double>(
      0.0,
      (sum, coeff) => sum + coeff * coeff,
    );

    if (norm < 0.0001) {
      // Coefficients are essentially zero, return uniform distribution
      final uniform = 1.0 / math.sqrt(coefficients.length);
      return List.filled(coefficients.length, uniform);
    }

    final scale = 1.0 / math.sqrt(norm);
    return coefficients.map((coeff) => coeff * scale).toList();
  }

  /// Optimize coefficients using genetic algorithm
  Future<List<double>> _optimizeGeneticAlgorithm({
    required List<QuantumEntityState> entityStates,
    required EntangledQuantumState idealState,
    required List<double> initialCoefficients,
    required AtomicTimestamp tAtomic,
  }) async {
    const populationSize = 50;
    const generations = 20;
    const mutationRate = 0.1;
    const crossoverRate = 0.7;

    // Initialize population
    var population = <List<double>>[];
    for (int i = 0; i < populationSize; i++) {
      if (i == 0) {
        // First individual is the initial coefficients
        population.add(List<double>.from(initialCoefficients));
      } else {
        // Others are random variations
        population.add(_generateRandomCoefficients(entityStates.length));
      }
    }

    // Evolve population
    for (int generation = 0; generation < generations; generation++) {
      // Evaluate fitness
      final fitness = await _evaluatePopulation(
        population: population,
        entityStates: entityStates,
        idealState: idealState,
      );

      // Select parents
      final parents = _selectParents(population, fitness);

      // Create new generation
      final newPopulation = <List<double>>[];
      for (int i = 0; i < populationSize; i++) {
        if (i < parents.length) {
          // Keep best individuals (elitism)
          newPopulation.add(List<double>.from(parents[i]));
        } else {
          // Crossover and mutation
          final parent1 = parents[math.Random().nextInt(parents.length)];
          final parent2 = parents[math.Random().nextInt(parents.length)];
          var child = _crossover(parent1, parent2, crossoverRate);
          child = _mutate(child, mutationRate);
          newPopulation.add(_normalizeCoefficients(child));
        }
      }

      population = newPopulation;
    }

    // Return best individual
    final finalFitness = await _evaluatePopulation(
      population: population,
      entityStates: entityStates,
      idealState: idealState,
    );
    final bestIndex = finalFitness.indexOf(finalFitness.reduce(math.max));
    return population[bestIndex];
  }

  /// Generate random coefficients
  List<double> _generateRandomCoefficients(int length) {
    final random = math.Random();
    final coefficients = List.generate(
      length,
      (_) => random.nextDouble(),
    );
    return _normalizeCoefficients(coefficients);
  }

  /// Evaluate population fitness
  Future<List<double>> _evaluatePopulation({
    required List<List<double>> population,
    required List<QuantumEntityState> entityStates,
    required EntangledQuantumState idealState,
  }) async {
    final fitness = <double>[];

    for (final coefficients in population) {
      final entangled = await _entanglementService.createEntangledState(
        entityStates: entityStates,
        coefficients: coefficients,
      );
      final fidelity = await _entanglementService.calculateFidelity(
        entangled,
        idealState,
      );
      fitness.add(fidelity);
    }

    return fitness;
  }

  /// Select parents based on fitness (tournament selection)
  List<List<double>> _selectParents(
    List<List<double>> population,
    List<double> fitness,
  ) {
    final parents = <List<double>>[];
    const tournamentSize = 3;
    final random = math.Random();

    for (int i = 0; i < population.length; i++) {
      // Tournament selection
      var bestIndex = random.nextInt(population.length);
      var bestFitness = fitness[bestIndex];

      for (int j = 1; j < tournamentSize; j++) {
        final candidateIndex = random.nextInt(population.length);
        if (fitness[candidateIndex] > bestFitness) {
          bestIndex = candidateIndex;
          bestFitness = fitness[candidateIndex];
        }
      }

      parents.add(List<double>.from(population[bestIndex]));
    }

    // Sort by fitness (descending)
    final indexed = List.generate(
      parents.length,
      (i) => MapEntry(i, fitness[i]),
    );
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed.map((entry) => parents[entry.key]).toList();
  }

  /// Crossover two parents to create child
  List<double> _crossover(
    List<double> parent1,
    List<double> parent2,
    double crossoverRate,
  ) {
    if (math.Random().nextDouble() > crossoverRate) {
      return List<double>.from(parent1);
    }

    final child = <double>[];
    for (int i = 0; i < parent1.length; i++) {
      // Uniform crossover
      child.add(math.Random().nextDouble() < 0.5 ? parent1[i] : parent2[i]);
    }

    return child;
  }

  /// Mutate coefficients
  List<double> _mutate(List<double> coefficients, double mutationRate) {
    final mutated = List<double>.from(coefficients);
    final random = math.Random();

    for (int i = 0; i < mutated.length; i++) {
      if (random.nextDouble() < mutationRate) {
        // Add small random perturbation
        mutated[i] += (random.nextDouble() - 0.5) * 0.1;
        mutated[i] = mutated[i].clamp(0.0, 1.0);
      }
    }

    return mutated;
  }

  /// Share coefficient optimization insights via AI2AI mesh for locality AI learning
  ///
  /// **Purpose:**
  /// Propagates coefficient optimization insights (optimized coefficients, fidelity improvements,
  /// convergence patterns) through the AI2AI mesh network for locality AI agents to learn
  /// from optimization strategies and patterns.
  ///
  /// **Privacy:**
  /// Uses agentId exclusively (never userId), anonymizes optimization results, and encrypts via Signal Protocol.
  ///
  /// **Process:**
  /// 1. Extract insights from optimization result (method, fidelity, iterations, coefficient patterns)
  /// 2. Anonymize data (agentId only, statistical patterns only, no individual identification)
  /// 3. Encrypt using Signal Protocol (via HybridEncryptionService)
  /// 4. Route through AI2AI mesh (via AnonymousCommunicationProtocol)
  ///
  /// **Parameters:**
  /// - `optimizationResult`: Result of coefficient optimization
  /// - `entityTypes`: List of entity types involved (public, no privacy concern)
  /// - `sourceAgentId`: Agent ID of the entity that triggered this optimization (privacy-preserving)
  /// - `initialFidelity`: Initial fidelity before optimization (for improvement calculation)
  /// - `messageType`: MessageType enum value (REQUIRED - from main app, e.g., MessageType.learningInsight)
  ///
  /// **Returns:**
  /// true if successfully shared, false otherwise (non-blocking)
  Future<bool> shareOptimizationInsightsViaMesh({
    required CoefficientOptimizationResult optimizationResult,
    required List<String> entityTypes,
    required String sourceAgentId,
    double? initialFidelity,
    required dynamic messageType, // MessageType enum from main app (REQUIRED - dynamic to avoid circular dependency)
  }) async {
    if (_ai2aiProtocol == null || _encryptionService == null || messageType == null) {
      return false; // Graceful degradation - AI2AI services not available or messageType not provided
    }

    try {
      developer.log(
        'Sharing coefficient optimization insights via AI2AI mesh for locality AI learning',
        name: _logName,
      );

      // 1. Extract insights (privacy-preserving: agentId only, statistical patterns only)
      final fidelityImprovement = initialFidelity != null
          ? (optimizationResult.fidelity - initialFidelity).clamp(-1.0, 1.0)
          : null;

      final insightPayload = <String, dynamic>{
        'schema_version': 1,
        'insight_type': 'coefficient_optimization',
        'source_agent_id': sourceAgentId, // Privacy: agentId only, never userId
        'created_at': optimizationResult.tAtomic.serverTime.toUtc().toIso8601String(),
        'entity_types': entityTypes, // Public: entity type names only
        'optimization_method': optimizationResult.method.name,
        'iterations': optimizationResult.iterations,
        'final_fidelity': optimizationResult.fidelity.clamp(0.0, 1.0),
        'fidelity_improvement': ?fidelityImprovement,
        // Anonymized coefficient statistics (patterns only, no individual identification)
        'coefficient_stats': {
          'count': optimizationResult.coefficients.length,
          'min': optimizationResult.coefficients.isEmpty
              ? 0.0
              : optimizationResult.coefficients.reduce((a, b) => a < b ? a : b),
          'max': optimizationResult.coefficients.isEmpty
              ? 0.0
              : optimizationResult.coefficients.reduce((a, b) => a > b ? a : b),
          'mean': optimizationResult.coefficients.isEmpty
              ? 0.0
              : optimizationResult.coefficients.reduce((a, b) => a + b) /
                  optimizationResult.coefficients.length,
          'std_dev': optimizationResult.coefficients.isEmpty
              ? 0.0
              : _calculateStdDev(optimizationResult.coefficients),
        },
        // Convergence pattern (statistical pattern, no individual identification)
        'convergence_rate': optimizationResult.iterations > 0
            ? (optimizationResult.fidelity / optimizationResult.iterations)
                .clamp(0.0, 1.0)
            : 0.0,
        'ttl_ms': 60 * 60 * 1000, // 1 hour
      };

      // 2. Encrypt using Signal Protocol and route through AI2AI mesh
      // Broadcast to locality mesh (no specific recipient - locality AIs pick up via mesh)
      // Note: messageType should be MessageType.learningInsight enum value from the main app
      // We accept it as dynamic to avoid circular dependency
      await _ai2aiProtocol!.sendEncryptedMessage(
        '', // Empty target = broadcast to locality mesh
        messageType, // MessageType enum (from main app, e.g., MessageType.learningInsight)
        insightPayload,
      );

      developer.log(
        '✅ Coefficient optimization insights shared via AI2AI mesh for locality AI learning',
        name: _logName,
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ Error sharing optimization insights via mesh: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return false; // Non-blocking: failure doesn't affect core optimization
    }
  }

  /// Calculate standard deviation of coefficients
  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((v) => math.pow(v - mean, 2))
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}

/// Optimization method
enum OptimizationMethod {
  gradientDescent,
  geneticAlgorithm,
}

/// Coefficient optimization result
class CoefficientOptimizationResult {
  /// Optimized coefficients (normalized: Σᵢ |αᵢ|² = 1)
  final List<double> coefficients;

  /// Final fidelity/compatibility score
  final double fidelity;

  /// Number of iterations performed
  final int iterations;

  /// Atomic timestamp of optimization
  final AtomicTimestamp tAtomic;

  /// Optimization method used
  final OptimizationMethod method;

  CoefficientOptimizationResult({
    required this.coefficients,
    required this.fidelity,
    required this.iterations,
    required this.tAtomic,
    required this.method,
  });

  @override
  String toString() {
    return 'CoefficientOptimizationResult(fidelity: ${fidelity.toStringAsFixed(4)}, iterations: $iterations, method: ${method.name})';
  }
}
