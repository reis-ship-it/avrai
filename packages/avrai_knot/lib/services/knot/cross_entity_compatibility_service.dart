// Cross-Entity Compatibility Service
// 
// Service for calculating compatibility between any entity types
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

/// Service for calculating compatibility between any entity types
/// 
/// **Supported Compatibility Types:**
/// - Person ↔ Person
/// - Person ↔ Event
/// - Person ↔ Place
/// - Person ↔ Company
/// - Event ↔ Place
/// - Event ↔ Company
/// - Place ↔ Company
/// - Multi-entity weave compatibility
/// 
/// **Compatibility Formula:**
/// C_integrated = α·C_quantum + β·C_topological + γ·C_weave
/// 
/// Where:
/// - α = 0.5 (quantum weight)
/// - β = 0.3 (topological weight)
/// - γ = 0.2 (weave weight)
class CrossEntityCompatibilityService {
  static const String _logName = 'CrossEntityCompatibilityService';
  
  // Compatibility weights
  static const double _quantumWeight = 0.5;
  static const double _topologicalWeight = 0.3;
  static const double _weaveWeight = 0.2;
  static const int _polyWidth = 32;
  static const double _epsilon = 1e-9;

  CrossEntityCompatibilityService({
    PersonalityKnotService? knotService,
  }) {
    // knotService parameter reserved for future use
    // Currently, compatibility calculations use direct FFI calls
    if (knotService != null) {
      // Future: Use knotService for additional operations
    }
  }

  /// Calculate integrated compatibility between any two entities
  /// 
  /// **Formula:** C_integrated = α·C_quantum + β·C_topological + γ·C_weave
  /// 
  /// **Returns:** Compatibility score in [0, 1]
  Future<double> calculateIntegratedCompatibility({
    required EntityKnot entityA,
    required EntityKnot entityB,
  }) async {
    developer.log(
      'Calculating compatibility between ${entityA.entityType} and ${entityB.entityType}',
      name: _logName,
    );

    try {
      // Quantum compatibility (from existing system)
      // TODO: Integrate with QuantumCompatibilityService when available
      final quantum = await _calculateQuantumCompatibility(entityA, entityB);
      
      // Topological compatibility (knot invariants)
      final topological = calculateTopologicalCompatibility(
        braidDataA: entityA.knot.braidData,
        braidDataB: entityB.knot.braidData,
      );
      
      // Weave compatibility (if applicable)
      final weave = await _calculateWeaveCompatibility(entityA.knot, entityB.knot);
      
      // Combined: α·C_quantum + β·C_topological + γ·C_weave
      final compatibility = (_quantumWeight * quantum) +
                           (_topologicalWeight * topological) +
                           (_weaveWeight * weave);
      
      developer.log(
        '✅ Compatibility calculated: $compatibility (quantum: $quantum, topological: $topological, weave: $weave)',
        name: _logName,
      );
      
      return compatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate **knot-only** compatibility (topology + weave), excluding the quantum term.
  ///
  /// This is the correct primitive to use when you already have a separate
  /// quantum fidelity term and want knot theory as an additional signal.
  Future<double> calculateKnotOnlyCompatibility({
    required EntityKnot entityA,
    required EntityKnot entityB,
  }) async {
    try {
      final topological = calculateTopologicalCompatibility(
        braidDataA: entityA.knot.braidData,
        braidDataB: entityB.knot.braidData,
      ).clamp(0.0, 1.0);

      final weave =
          await _calculateWeaveCompatibility(entityA.knot, entityB.knot);

      // Knot-only blend (matches our other knot-only consumers).
      final knotOnly = (0.6 * topological + 0.4 * weave).clamp(0.0, 1.0);
      return knotOnly;
    } catch (e, st) {
      developer.log(
        '❌ Failed to calculate knot-only compatibility: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate quantum compatibility between two entities
  /// 
  /// **Truthfulness note:**
  /// This is intentionally **not** a hardcoded placeholder.
  ///
  /// We compute a real fidelity score \( |⟨a|b⟩|² \) from the best available
  /// state vectors:
  /// - Prefer explicit `vibeDimensions`/`dimensions` found in `EntityKnot.metadata`
  /// - Otherwise derive a deterministic “state” from knot invariants (crossings,
  ///   writhe, Jones/Alexander coefficients)
  Future<double> _calculateQuantumCompatibility(
    EntityKnot entityA,
    EntityKnot entityB,
  ) async {
    final mapA = _extractVibeMap(entityA);
    final mapB = _extractVibeMap(entityB);
    if (mapA != null && mapA.isNotEmpty && mapB != null && mapB.isNotEmpty) {
      return _quantumFidelityFromMaps(mapA, mapB);
    }

    final vecA = _vectorFromKnot(entityA.knot);
    final vecB = _vectorFromKnot(entityB.knot);

    return _quantumFidelity(vecA, vecB);
  }

  Map<String, double>? _extractVibeMap(EntityKnot entity) {
    final meta = entity.metadata;
    if (meta.isEmpty) return null;

    final candidates = <dynamic>[
      meta['vibeDimensions'],
      meta['vibe_dimensions'],
      meta['dimensions'],
      meta['personality_dimensions'],
    ];

    for (final raw in candidates) {
      final m = _tryExtractNumericMap(raw);
      if (m == null || m.isEmpty) continue;
      return m.map((k, v) => MapEntry(k, v.clamp(0.0, 1.0)));
    }

    return null;
  }

  Map<String, double>? _tryExtractNumericMap(dynamic raw) {
    if (raw is! Map) return null;

    final out = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (value is num) {
        out[key] = value.toDouble();
      }
    }

    return out;
  }

  List<double> _vectorFromKnot(PersonalityKnot knot) {
    final vec = <double>[
      _normalizeCrossing(knot.invariants.crossingNumber.toDouble()),
      _normalizeWrithe(knot.invariants.writhe.toDouble()),
    ];

    void addPoly(List<double> poly) {
      for (var i = 0; i < _polyWidth; i++) {
        final v = i < poly.length ? poly[i] : 0.0;
        vec.add(_squash(v));
      }
    }

    addPoly(knot.invariants.jonesPolynomial);
    addPoly(knot.invariants.alexanderPolynomial);

    return vec;
  }

  double _normalizeCrossing(double crossing) {
    // Saturating normalization: keeps values in (0, 1).
    return (crossing / (crossing + 10.0)).clamp(0.0, 1.0);
  }

  double _normalizeWrithe(double writhe) {
    // Map (-∞, +∞) → (0, 1) via tanh.
    final t = _tanh(writhe / 10.0);
    return ((t + 1.0) / 2.0).clamp(0.0, 1.0);
  }

  double _squash(double v) {
    // Map (-∞, +∞) → (0, 1) via tanh with gentler scale.
    final t = _tanh(v / 5.0);
    return ((t + 1.0) / 2.0).clamp(0.0, 1.0);
  }

  double _tanh(double x) {
    // Numerically stable tanh implementation.
    if (x.isNaN) return 0.0;
    if (x == double.infinity) return 1.0;
    if (x == double.negativeInfinity) return -1.0;

    // For large |x|, exp(2x) can overflow. Use stable equivalents:
    // tanh(x) = (1 - e^{-2x}) / (1 + e^{-2x}) for x >= 0
    // tanh(x) = -tanh(-x) for x < 0
    if (x >= 0) {
      final e = math.exp(-2.0 * x);
      return (1.0 - e) / (1.0 + e);
    } else {
      final e = math.exp(2.0 * x);
      return (e - 1.0) / (e + 1.0);
    }
  }

  double _quantumFidelityFromMaps(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    final keys = <String>{...a.keys, ...b.keys}.toList()..sort();
    if (keys.isEmpty) return 0.0;

    var normA = 0.0;
    var normB = 0.0;
    var inner = 0.0;

    for (final k in keys) {
      final av = (a[k] ?? 0.0).clamp(0.0, 1.0);
      final bv = (b[k] ?? 0.0).clamp(0.0, 1.0);
      normA += av * av;
      normB += bv * bv;
      inner += av * bv;
    }

    normA = math.sqrt(normA);
    normB = math.sqrt(normB);
    if (normA < _epsilon || normB < _epsilon) return 0.0;

    final normalizedInner = inner / (normA * normB);
    return (normalizedInner * normalizedInner).clamp(0.0, 1.0);
  }

  double _quantumFidelity(List<double> a, List<double> b) {
    final n = math.max(a.length, b.length);
    if (n == 0) return 0.0;

    var normA = 0.0;
    var normB = 0.0;
    var inner = 0.0;

    for (var i = 0; i < n; i++) {
      final av = i < a.length ? a[i] : 0.0;
      final bv = i < b.length ? b[i] : 0.0;
      normA += av * av;
      normB += bv * bv;
      inner += av * bv;
    }

    normA = math.sqrt(normA);
    normB = math.sqrt(normB);
    if (normA < _epsilon || normB < _epsilon) return 0.0;

    final normalizedInner = inner / (normA * normB);
    return (normalizedInner * normalizedInner).clamp(0.0, 1.0);
  }

  /// Calculate weave compatibility between two knots
  /// 
  /// **Algorithm:**
  /// - Analyze how well the two knots can be woven together
  /// - Consider knot complexity, crossing numbers, and topological structure
  Future<double> _calculateWeaveCompatibility(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) async {
    // Simple weave compatibility based on knot similarity
    // More similar knots are easier to weave together
    
    final crossingDiff =
        (knotA.invariants.crossingNumber - knotB.invariants.crossingNumber).abs();
    final maxCrossings = math.max(
      math.max(knotA.invariants.crossingNumber, knotB.invariants.crossingNumber),
      1,
    );
    
    // Similar crossing numbers = easier to weave
    final crossingSimilarity = 1.0 - (crossingDiff / maxCrossings).clamp(0.0, 1.0);
    
    // Polynomial similarity (using polynomial distance)
    final polyDistance = polynomialDistance(
      coefficientsA: knotA.invariants.jonesPolynomial,
      coefficientsB: knotB.invariants.jonesPolynomial,
    );

    // Normalize polynomial distance
    final polynomialSimilarity =
        (1.0 / (1.0 + polyDistance)).clamp(0.0, 1.0);
    
    // Combined weave compatibility
    final weave = (0.6 * crossingSimilarity) + (0.4 * polynomialSimilarity);
    
    return weave.clamp(0.0, 1.0);
  }

  /// Calculate multi-entity weave compatibility
  /// 
  /// **Algorithm:**
  /// - Create multi-entity braid from all entity knots
  /// - Calculate braided knot stability
  /// - Return stability as compatibility score
  Future<double> calculateMultiEntityWeaveCompatibility({
    required List<EntityKnot> entities,
  }) async {
    developer.log(
      'Calculating multi-entity weave compatibility for ${entities.length} entities',
      name: _logName,
    );

    if (entities.length < 2) {
      return 1.0; // Single entity is perfectly compatible with itself
    }

    try {
      // Patent-aligned implementation: stability of a multi-strand braid fabric.
      final fabricService = KnotFabricService();
      final fabric = await fabricService.generateMultiStrandBraidFabric(
        userKnots: entities.map((e) => e.knot).toList(),
      );
      final stability = await fabricService.measureFabricStability(fabric);

      developer.log(
        '✅ Multi-entity weave compatibility (fabric stability): $stability',
        name: _logName,
      );

      return stability.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate multi-entity weave compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );

      // Fallback: average pairwise integrated compatibility (legacy behavior).
      double totalCompatibility = 0.0;
      int pairCount = 0;

      for (int i = 0; i < entities.length; i++) {
        for (int j = i + 1; j < entities.length; j++) {
          final compatibility = await calculateIntegratedCompatibility(
            entityA: entities[i],
            entityB: entities[j],
          );
          totalCompatibility += compatibility;
          pairCount++;
        }
      }

      final averageCompatibility =
          pairCount > 0 ? totalCompatibility / pairCount : 1.0;
      return averageCompatibility.clamp(0.0, 1.0);
    }
  }
}
