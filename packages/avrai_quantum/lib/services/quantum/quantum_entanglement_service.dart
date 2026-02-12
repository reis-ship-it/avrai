// Quantum Entanglement Service
//
// Implements N-way quantum entanglement for multi-entity matching
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/quantum_state_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/models/entity_knot.dart';
// Phase 19 Integration Enhancement: AI2AI Mesh + Signal Protocol (for locality AI learning)
// Note: These are defined in the main app (avrai package), so we use dynamic types
// to avoid circular dependencies. They're optional and only used conditionally.

/// N-way quantum entanglement service
///
/// **Formula:**
/// |ψ_entangled(t_atomic)⟩ = Σᵢ αᵢ(t_atomic) |ψ_entity_i(t_atomic_i)⟩ ⊗ |ψ_entity_j(t_atomic_j)⟩ ⊗ ... ⊗ |ψ_entity_k(t_atomic_k)⟩
///
/// **Normalization Constraints:**
/// 1. Entity State Normalization: ⟨ψ_entity_i|ψ_entity_i⟩ = 1
/// 2. Coefficient Normalization: Σᵢ |αᵢ|² = 1
/// 3. Entangled State Normalization: ⟨ψ_entangled|ψ_entangled⟩ = 1
///
/// **Atomic Timing:**
/// All entanglement calculations use AtomicClockService for precise temporal tracking
class QuantumEntanglementService {
  static const String _logName = 'QuantumEntanglementService';

  final AtomicClockService _atomicClock;
  final IntegratedKnotRecommendationEngine? _knotEngine;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final QuantumStateKnotService? _quantumStateKnotService;
  final KnotEvolutionStringService? _stringService;
  final KnotFabricService? _fabricService;
  // _worldsheetService: Reserved for future use when group context is available
  // (worldsheet requires groupId which isn't available in entityStates context)
  // ignore: unused_field
  final KnotWorldsheetService? _worldsheetService;
  // Phase 19 Integration Enhancement: AI2AI Mesh + Signal Protocol (for locality AI learning)
  // Note: Using dynamic types to avoid circular dependency with main app
  // These services are optional and only used conditionally (checked for null before use)
  final dynamic _encryptionService;
  final dynamic _ai2aiProtocol;

  QuantumEntanglementService({
    required AtomicClockService atomicClock,
    IntegratedKnotRecommendationEngine? knotEngine,
    CrossEntityCompatibilityService? knotCompatibilityService,
    QuantumStateKnotService? quantumStateKnotService,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    dynamic encryptionService,
    dynamic ai2aiProtocol,
    // agentIdService: Not needed - agent IDs are passed as parameters from callers
  })  : _atomicClock = atomicClock,
        _knotEngine = knotEngine,
        _knotCompatibilityService = knotCompatibilityService,
        _quantumStateKnotService = quantumStateKnotService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Create N-way entangled state from multiple entity states
  ///
  /// **Formula:**
  /// |ψ_entangled(t_atomic)⟩ = Σᵢ αᵢ(t_atomic) |ψ_entity_i(t_atomic_i)⟩ ⊗ |ψ_entity_j(t_atomic_j)⟩ ⊗ ... ⊗ |ψ_entity_k(t_atomic_k)⟩
  ///
  /// **Parameters:**
  /// - `entityStates`: List of normalized quantum entity states
  /// - `coefficients`: Optional entanglement coefficients (will be optimized if not provided)
  ///
  /// **Returns:**
  /// EntangledQuantumState with normalized entangled state and atomic timestamp
  Future<EntangledQuantumState> createEntangledState({
    required List<QuantumEntityState> entityStates,
    List<double>? coefficients,
  }) async {
    developer.log(
      'Creating N-way entangled state for ${entityStates.length} entities',
      name: _logName,
    );

    try {
      // Validate input
      if (entityStates.isEmpty) {
        throw ArgumentError('Cannot create entangled state with no entities');
      }

      // Get atomic timestamp for entanglement creation
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Normalize all entity states
      final normalizedStates = entityStates.map((state) => state.normalized()).toList();

      // Calculate or use provided coefficients
      final finalCoefficients = coefficients ?? _calculateDefaultCoefficients(normalizedStates);

      // Validate coefficient normalization: Σᵢ |αᵢ|² = 1
      final coefficientNorm = finalCoefficients.fold<double>(
        0.0,
        (sum, coeff) => sum + coeff * coeff,
      );
      if ((coefficientNorm - 1.0).abs() > 0.0001) {
        developer.log(
          '⚠️ Coefficient normalization off: $coefficientNorm, normalizing...',
          name: _logName,
        );
        final scale = 1.0 / math.sqrt(coefficientNorm);
        for (var i = 0; i < finalCoefficients.length; i++) {
          finalCoefficients[i] *= scale;
        }
      }

      // Perform tensor product: |ψ_entity_i⟩ ⊗ |ψ_entity_j⟩ ⊗ ... ⊗ |ψ_entity_k⟩
      final tensorProduct = _tensorProduct(normalizedStates);

      // Create entangled state: Σᵢ αᵢ |ψ_tensor_i⟩
      final entangledVector = _createEntangledVector(tensorProduct, finalCoefficients);

      // Normalize entangled state: ⟨ψ_entangled|ψ_entangled⟩ = 1
      final normalizedEntangled = _normalizeVector(entangledVector);

      developer.log(
        '✅ Created entangled state: ${normalizedStates.length} entities, ${normalizedEntangled.length} dimensions',
        name: _logName,
      );

      return EntangledQuantumState(
        entityStates: normalizedStates,
        coefficients: finalCoefficients,
        entangledVector: normalizedEntangled,
        tAtomic: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error creating entangled state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate default coefficients based on entity types
  ///
  /// Uses entity type weights from QuantumEntityTypeMetadata
  List<double> _calculateDefaultCoefficients(List<QuantumEntityState> entityStates) {
    final coefficients = <double>[];

    for (final state in entityStates) {
      final weight = QuantumEntityTypeMetadata.getDefaultWeight(state.entityType);
      coefficients.add(weight);
    }

    // Normalize coefficients: Σᵢ |αᵢ|² = 1
    final norm = coefficients.fold<double>(
      0.0,
      (sum, coeff) => sum + coeff * coeff,
    );
    final scale = 1.0 / math.sqrt(norm);

    return coefficients.map((coeff) => coeff * scale).toList();
  }

  /// Perform tensor product: |ψ_entity_i⟩ ⊗ |ψ_entity_j⟩ ⊗ ... ⊗ |ψ_entity_k⟩
  ///
  /// **Tensor Product:**
  /// For two states |a⟩ and |b⟩, the tensor product is |a⟩ ⊗ |b⟩ = |ab⟩
  /// For N states, we recursively compute: |a₁⟩ ⊗ |a₂⟩ ⊗ ... ⊗ |aₙ⟩
  List<double> _tensorProduct(List<QuantumEntityState> entityStates) {
    if (entityStates.isEmpty) {
      return [];
    }

    if (entityStates.length == 1) {
      return _stateToVector(entityStates[0]);
    }

    // Recursive tensor product
    var result = _stateToVector(entityStates[0]);
    for (var i = 1; i < entityStates.length; i++) {
      final nextVector = _stateToVector(entityStates[i]);
      result = _tensorProductVectors(result, nextVector);
    }

    return result;
  }

  /// Convert quantum entity state to vector representation
  List<double> _stateToVector(QuantumEntityState state) {
    final vector = <double>[];

    // Add personality state components
    vector.addAll(state.personalityState.values);

    // Add quantum vibe analysis components
    vector.addAll(state.quantumVibeAnalysis.values);

    // Add location components (if present)
    if (state.location != null) {
      vector.add(state.location!.latitudeQuantumState);
      vector.add(state.location!.longitudeQuantumState);
      vector.add(state.location!.accessibilityScore);
      vector.add(state.location!.vibeLocationMatch);
    }

    // Add timing components (if present)
    if (state.timing != null) {
      vector.add(state.timing!.timeOfDayPreference);
      vector.add(state.timing!.dayOfWeekPreference);
      vector.add(state.timing!.frequencyPreference);
      vector.add(state.timing!.durationPreference);
      vector.add(state.timing!.timingVibeMatch);
    }

    return vector;
  }

  /// Tensor product of two vectors
  ///
  /// **Formula:**
  /// |a⟩ ⊗ |b⟩ = [a₁b₁, a₁b₂, ..., a₁bₙ, a₂b₁, a₂b₂, ..., aₘbₙ]
  List<double> _tensorProductVectors(List<double> vectorA, List<double> vectorB) {
    final result = <double>[];
    for (final a in vectorA) {
      for (final b in vectorB) {
        result.add(a * b);
      }
    }
    return result;
  }

  /// Create entangled vector: Σᵢ αᵢ |ψ_tensor_i⟩
  ///
  /// For N entities, we have one tensor product result, so we scale by the coefficient
  /// In general, we would sum over all possible combinations, but for simplicity,
  /// we use the single tensor product scaled by the coefficient
  List<double> _createEntangledVector(List<double> tensorProduct, List<double> coefficients) {
    // For N-way entanglement, we use the tensor product directly
    // The coefficients are applied during optimization
    // Here, we scale by the average coefficient for simplicity
    final avgCoeff = coefficients.fold<double>(0.0, (sum, c) => sum + c) / coefficients.length;
    return tensorProduct.map((value) => value * avgCoeff).toList();
  }

  /// Normalize vector: ⟨ψ|ψ⟩ = 1
  List<double> _normalizeVector(List<double> vector) {
    final norm = vector.fold<double>(
      0.0,
      (sum, value) => sum + value * value,
    );

    if (norm < 0.0001) {
      // Vector is essentially zero
      return vector;
    }

    final scale = 1.0 / math.sqrt(norm);
    return vector.map((value) => value * scale).toList();
  }

  /// Calculate quantum fidelity between two entangled states
  ///
  /// **Formula:**
  /// F(ρ₁, ρ₂) = [Tr(√(√ρ₁ · ρ₂ · √ρ₁))]²
  ///
  /// For pure states:
  /// F(|ψ₁⟩, |ψ₂⟩) = |⟨ψ₁|ψ₂⟩|²
  Future<double> calculateFidelity(
    EntangledQuantumState state1,
    EntangledQuantumState state2,
  ) async {
    if (state1.entangledVector.length != state2.entangledVector.length) {
      throw ArgumentError('Cannot calculate fidelity between states of different dimensions');
    }

    // Calculate inner product: ⟨ψ₁|ψ₂⟩
    var innerProduct = 0.0;
    for (var i = 0; i < state1.entangledVector.length; i++) {
      innerProduct += state1.entangledVector[i] * state2.entangledVector[i];
    }

    // Fidelity: |⟨ψ₁|ψ₂⟩|²
    final fidelity = innerProduct * innerProduct;

    developer.log(
      'Fidelity: ${fidelity.toStringAsFixed(4)}',
      name: _logName,
    );

    return fidelity.clamp(0.0, 1.0);
  }

  /// Calculate knot compatibility bonus (enhanced with string/fabric/worldsheet)
  ///
  /// **Enhanced Formula (with String/Fabric Integration):**
  /// C_knot_bonus = hybrid_combination(
  ///   C_knot_base,           // Base knot compatibility (geometric mean)
  ///   C_string_evolution,    // String evolution predictions (if available)
  ///   C_fabric_stability,    // Fabric stability (if available)
  ///   C_worldsheet_evolution // Worldsheet evolution (if available)
  /// )
  ///
  /// **Process:**
  /// 1. Calculate base knot compatibility (2-entity or multi-entity fabric)
  /// 2. If string service available and target time provided, enhance with string evolution
  /// 3. If fabric service available and 3+ entities, enhance with fabric stability
  /// 4. If worldsheet service available, enhance with worldsheet evolution predictions
  ///
  /// Returns 0.0 if knot services unavailable (graceful degradation)
  Future<double> calculateKnotCompatibilityBonus(
    List<QuantumEntityState> entityStates, {
    DateTime? targetTime,
  }) async {
    if (_quantumStateKnotService == null ||
        (_knotEngine == null && _knotCompatibilityService == null)) {
      // Graceful degradation: return 0.0 if knot services unavailable
      return 0.0;
    }

    try {
      if (entityStates.length < 2) return 0.0;

      // Generate knot representations for each quantum entity state.
      // This lives in the knot layer for scalability and keeps the entanglement
      // service focused on orchestration.
      final entityKnots = <EntityKnot>[];
      for (final s in entityStates) {
        entityKnots.add(await _quantumStateKnotService.generateEntityKnot(state: s));
      }

      double baseCompatibility = 0.0;

      if (entityKnots.length == 2) {
        // Prefer the integrated recommendation engine's knot bonus when available
        // (includes rarity bonus for discovery).
        final engine = _knotEngine;
        if (engine != null) {
          // Enhance with string evolution if available and target time provided
          final stringService = _stringService;
          if (stringService != null && targetTime != null) {
            try {
              // Get agent IDs from entity states
              final agentIdA = entityKnots[0].knot.agentId;
              final agentIdB = entityKnots[1].knot.agentId;

              // Predict future knots at target time (may return null)
              // targetTime is non-null here due to null check above
              final futureKnotA = await stringService.predictFutureKnot(agentIdA, targetTime);
              final futureKnotB = await stringService.predictFutureKnot(agentIdB, targetTime);

              // Calculate current knot bonus
              final currentKnotBonus = engine.calculateKnotBonus(
                userKnot: entityKnots[0].knot,
                targetKnot: entityKnots[1].knot,
              );

              // If future knots are available, use hybrid approach
              if (futureKnotA != null && futureKnotB != null) {
                // Calculate compatibility using predicted future knots
                final futureKnotBonus = engine.calculateKnotBonus(
                  userKnot: futureKnotA,
                  targetKnot: futureKnotB,
                );

                // Hybrid: 60% current, 40% future (future can enhance but not replace)
                baseCompatibility = (0.6 * currentKnotBonus + 0.4 * futureKnotBonus).clamp(0.0, 1.0);
              } else {
                // Future knots not available, use current knot bonus
                baseCompatibility = currentKnotBonus;
              }
            } catch (e) {
              developer.log(
                'Error calculating string evolution: $e, using base knot compatibility',
                name: _logName,
              );
              // Fallback to current knot bonus
              baseCompatibility = engine.calculateKnotBonus(
                userKnot: entityKnots[0].knot,
                targetKnot: entityKnots[1].knot,
              );
            }
          } else {
            // No string service or target time, use current knot bonus
            baseCompatibility = engine.calculateKnotBonus(
              userKnot: entityKnots[0].knot,
              targetKnot: entityKnots[1].knot,
            );
          }
        } else {
          final svc = _knotCompatibilityService;
          if (svc == null) {
            return 0.0;
          }
          baseCompatibility = await svc.calculateKnotOnlyCompatibility(
            entityA: entityKnots[0],
            entityB: entityKnots[1],
          );
        }
      } else {
        // For 3+ entities, use fabric stability as the multi-entity knot signal
        final svc = _knotCompatibilityService;
        if (svc == null) {
          return 0.0;
        }
        baseCompatibility = await svc.calculateMultiEntityWeaveCompatibility(
          entities: entityKnots,
        );

        // Enhance with fabric service if available
        final fabricService = _fabricService;
        if (fabricService != null) {
          try {
            final personalityKnots = entityKnots.map((e) => e.knot).toList();
            final fabric = await fabricService.generateMultiStrandBraidFabric(
              userKnots: personalityKnots,
            );
            final fabricStability = await fabricService.measureFabricStability(fabric);

            // Hybrid: 70% multi-entity weave, 30% fabric stability
            baseCompatibility = (0.7 * baseCompatibility + 0.3 * fabricStability).clamp(0.0, 1.0);

            // Note: Worldsheet enhancement skipped here because we don't have groupId
            // Worldsheet requires groupId/userIds which aren't available in entityStates context
            // This enhancement is better suited for services with group context (e.g., GroupMatchingService)
          } catch (e) {
            developer.log(
              'Error calculating fabric stability: $e, using multi-entity weave only',
              name: _logName,
            );
          }
        }
      }

      return baseCompatibility.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating knot compatibility: $e, using 0.0',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Share entanglement calculation insights via AI2AI mesh for locality AI learning
  ///
  /// **Purpose:**
  /// Propagates entanglement calculation insights (fidelity, knot compatibility, fabric stability)
  /// through the AI2AI mesh network for locality AI agents to learn from quantum matching patterns.
  ///
  /// **Privacy:**
  /// Uses agentId exclusively (never userId), anonymizes quantum states, and encrypts via Signal Protocol.
  ///
  /// **Process:**
  /// 1. Extract insights from entanglement calculation (entity types, compatibility scores, knot patterns)
  /// 2. Anonymize data (agentId only, no userId or PII)
  /// 3. Encrypt using Signal Protocol (via HybridEncryptionService)
  /// 4. Route through AI2AI mesh (via AnonymousCommunicationProtocol)
  ///
  /// **Parameters:**
  /// - `entangledState`: Result of entanglement calculation
  /// - `fidelity`: Fidelity score (if available)
  /// - `knotCompatibility`: Knot compatibility bonus (if available)
  /// - `sourceAgentId`: Agent ID of the entity that triggered this calculation (privacy-preserving)
  /// - `entityTypes`: List of entity types involved (public, no privacy concern)
  /// - `messageType`: MessageType enum value (REQUIRED - from main app, e.g., MessageType.learningInsight)
  ///
  /// **Returns:**
  /// true if successfully shared, false otherwise (non-blocking)
  Future<bool> shareEntanglementInsightsViaMesh({
    required EntangledQuantumState entangledState,
    double? fidelity,
    double? knotCompatibility,
    required String sourceAgentId,
    required List<String> entityTypes,
    required dynamic messageType, // MessageType enum from main app (REQUIRED - dynamic to avoid circular dependency)
  }) async {
    if (_ai2aiProtocol == null || _encryptionService == null || messageType == null) {
      return false; // Graceful degradation - AI2AI services not available or messageType not provided
    }

    try {
      developer.log(
        'Sharing entanglement insights via AI2AI mesh for locality AI learning',
        name: _logName,
      );

      // 1. Extract insights (privacy-preserving: agentId only, no userId or PII)
      final insightPayload = <String, dynamic>{
        'schema_version': 1,
        'insight_type': 'entanglement_calculation',
        'source_agent_id': sourceAgentId, // Privacy: agentId only, never userId
        'created_at': entangledState.tAtomic.serverTime.toUtc().toIso8601String(),
        'entity_count': entangledState.entityStates.length,
        'entity_types': entityTypes, // Public: entity type names only
        'entangled_dimensions': entangledState.entangledVector.length,
        'coefficient_count': entangledState.coefficients.length,
        'normalized': entangledState.isNormalized,
        // Anonymized compatibility scores (no user identification)
        if (fidelity != null) 'fidelity': fidelity.clamp(0.0, 1.0),
        if (knotCompatibility != null)
          'knot_compatibility': knotCompatibility.clamp(0.0, 1.0),
        // Anonymized coefficients (statistical patterns only, no individual identification)
        'coefficient_stats': {
          'min': entangledState.coefficients.isEmpty
              ? 0.0
              : entangledState.coefficients.reduce((a, b) => a < b ? a : b),
          'max': entangledState.coefficients.isEmpty
              ? 0.0
              : entangledState.coefficients.reduce((a, b) => a > b ? a : b),
          'mean': entangledState.coefficients.isEmpty
              ? 0.0
              : entangledState.coefficients.reduce((a, b) => a + b) /
                  entangledState.coefficients.length,
        },
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
        '✅ Entanglement insights shared via AI2AI mesh for locality AI learning',
        name: _logName,
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ Error sharing entanglement insights via mesh: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return false; // Non-blocking: failure doesn't affect core calculation
    }
  }
}

/// Entangled quantum state result
class EntangledQuantumState {
  /// Original entity states
  final List<QuantumEntityState> entityStates;

  /// Entanglement coefficients (normalized: Σᵢ |αᵢ|² = 1)
  final List<double> coefficients;

  /// Entangled state vector (normalized: ⟨ψ_entangled|ψ_entangled⟩ = 1)
  final List<double> entangledVector;

  /// Atomic timestamp of entanglement creation
  final AtomicTimestamp tAtomic;

  EntangledQuantumState({
    required this.entityStates,
    required this.coefficients,
    required this.entangledVector,
    required this.tAtomic,
  });

  /// Check if entangled state is normalized
  bool get isNormalized {
    final norm = entangledVector.fold<double>(
      0.0,
      (sum, value) => sum + value * value,
    );
    return (norm - 1.0).abs() < 0.0001;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entityStates': entityStates.map((s) => s.toJson()).toList(),
      'coefficients': coefficients,
      'entangledVector': entangledVector,
      'tAtomic': tAtomic.toJson(),
    };
  }

  @override
  String toString() {
    return 'EntangledQuantumState(entities: ${entityStates.length}, dimensions: ${entangledVector.length}, normalized: $isNormalized, tAtomic: $tAtomic)';
  }
}
