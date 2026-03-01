import 'dart:math' as math;
import 'dart:developer' as developer;

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/brand_account.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/quantum/multi_scale_quantum_state_service.dart';
import 'package:avrai_runtime_os/services/matching/attraction_12d_resolver.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

part 'vibe_compatibility_models.dart';

/// A structured compatibility breakdown for any "vibe score".
///
/// This is the **truthful** scoring contract used by the app:
/// - **quantum**: pure-state fidelity \( |⟨a|b⟩|^2 \) over the 12 SPOTS dimensions
/// - **knotTopological**: knot-invariant similarity (braid/invariant based)
/// - **knotWeave**: weave-ability similarity (crossing + polynomial similarity)
/// - **combined**: weighted mix (quantum + knot topology + knot weave)
class VibeScore {
  final double combined;
  final double quantum;
  final double knotTopological;
  final double knotWeave;
  final Map<String, double> breakdown;

  const VibeScore({
    required this.combined,
    required this.quantum,
    required this.knotTopological,
    required this.knotWeave,
    this.breakdown = const {},
  });

  VibeScore clamped() => VibeScore(
        combined: combined.clamp(0.0, 1.0),
        quantum: quantum.clamp(0.0, 1.0),
        knotTopological: knotTopological.clamp(0.0, 1.0),
        knotWeave: knotWeave.clamp(0.0, 1.0),
        breakdown: breakdown.map((k, v) => MapEntry(k, v.clamp(0.0, 1.0))),
      );
}

/// Computes **truthful** compatibility scores using:
/// - Quantum-inspired fidelity over the 12-dim SPOTS vector
/// - Knot topology + weave similarity (when native knot runtime is available)
abstract class VibeCompatibilityService {
  Future<VibeScore> calculateUserBusinessVibe({
    required String userId,
    required BusinessAccount business,
  });

  Future<VibeScore> calculateEventBrandVibe({
    required ExpertiseEvent event,
    required BrandAccount brand,
  });

  /// Calculate a **truthful** vibe between a user and an event.
  ///
  /// This is the canonical score for event discovery/recommendations when we
  /// want **true compatibility**:
  /// - Quantum fidelity over 12D SPOTS
  /// - Knot topology + weave (best-effort, with graceful degradation)
  Future<VibeScore> calculateUserEventVibe({
    required String userId,
    required ExpertiseEvent event,
  });
}

/// Default production implementation (quantum + knot).
///
/// Notes:
/// - **Quantum** uses the 12-dim vectors directly (stable, no random noise).
/// - **Knot** is best-effort: if native knot runtime isn’t available (e.g. unit tests),
///   we degrade gracefully to quantum-only scoring.
class QuantumKnotVibeCompatibilityService implements VibeCompatibilityService {
  static const String _logName = 'QuantumKnotVibeCompatibilityService';

  // Match the knot-layer integrated weights (Patent #31 contract),
  // but allow graceful degradation if knot is unavailable.
  static const double _quantumWeight = 0.5;
  static const double _topologicalWeight = 0.3;
  static const double _weaveWeight = 0.2;

  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final PersonalityLearning _personalityLearning;
  final PersonalityKnotService _personalityKnotService;
  final EntityKnotService _entityKnotService;

  /// Optional: 12D attraction resolver for user–entity scoring.
  /// TODO(Phase 2): Integrate into vibe scoring pipeline.
  final Attraction12DResolver? attractionResolver;

  /// Optional: multi-scale quantum state service for scale-aware fidelity.
  /// TODO(Phase 2): Use multi-scale states instead of flat 12D vectors.
  final MultiScaleQuantumStateService? multiScaleService;

  QuantumKnotVibeCompatibilityService({
    required PersonalityLearning personalityLearning,
    required PersonalityKnotService personalityKnotService,
    required EntityKnotService entityKnotService,
    this.attractionResolver,
    this.multiScaleService,
  })  : _personalityLearning = personalityLearning,
        _personalityKnotService = personalityKnotService,
        _entityKnotService = entityKnotService;

  @override
  Future<VibeScore> calculateUserBusinessVibe({
    required String userId,
    required BusinessAccount business,
  }) async {
    final userProfile = await _getOrCreateUserProfile(userId);
    final userDims = _ensureAllDimensions(userProfile.dimensions);

    final businessDims = _inferBusinessVibeDimensions(business);

    final quantum = _quantumFidelity(userDims, businessDims);

    final knotScores = await _tryKnotScores(
      entityA: await _tryEntityKnotForPerson(userProfile),
      entityB: await _tryEntityKnotForBusiness(business),
    );

    final score = _combine(quantum: quantum, knot: knotScores);
    _logger.debug(
      'User↔Business vibe: user=$userId business=${business.id} '
      'combined=${(score.combined * 100).toStringAsFixed(1)}% '
      '(quantum=${(score.quantum * 100).toStringAsFixed(1)}%, '
      'topo=${(score.knotTopological * 100).toStringAsFixed(1)}%, '
      'weave=${(score.knotWeave * 100).toStringAsFixed(1)}%)',
      tag: _logName,
    );
    return score;
  }

  @override
  Future<VibeScore> calculateEventBrandVibe({
    required ExpertiseEvent event,
    required BrandAccount brand,
  }) async {
    final hostProfile = await _getOrCreateUserProfile(event.host.id);
    final eventDims = _ensureAllDimensions(hostProfile.dimensions);

    final brandDims = _inferBrandVibeDimensions(brand);

    final quantum = _quantumFidelity(eventDims, brandDims);

    final knotScores = await _tryKnotScores(
      entityA: await _tryEntityKnotForEvent(event),
      entityB: await _tryEntityKnotForBrand(brand),
    );

    final score = _combine(quantum: quantum, knot: knotScores);
    _logger.debug(
      'Event↔Brand vibe: event=${event.id} brand=${brand.id} '
      'combined=${(score.combined * 100).toStringAsFixed(1)}% '
      '(quantum=${(score.quantum * 100).toStringAsFixed(1)}%, '
      'topo=${(score.knotTopological * 100).toStringAsFixed(1)}%, '
      'weave=${(score.knotWeave * 100).toStringAsFixed(1)}%)',
      tag: _logName,
    );
    return score;
  }

  @override
  Future<VibeScore> calculateUserEventVibe({
    required String userId,
    required ExpertiseEvent event,
  }) async {
    final userProfile = await _getOrCreateUserProfile(userId);
    final userDims = _ensureAllDimensions(userProfile.dimensions);

    // Best-available event "vibe" proxy: host personality vector.
    // (Later: replace with a dedicated EventVibeProfile derived from host + attendees + event attributes.)
    final hostProfile = await _getOrCreateUserProfile(event.host.id);
    final eventDims = _ensureAllDimensions(hostProfile.dimensions);

    final quantum = _quantumFidelity(userDims, eventDims);

    // User knot ↔ event knot (entity knot) yields topological + weave components when available.
    final knotScores = await _tryKnotScores(
      entityA: await _tryEntityKnotForPerson(userProfile),
      entityB: await _tryEntityKnotForEvent(event),
    );

    final score = _combine(quantum: quantum, knot: knotScores);
    _logger.debug(
      'User↔Event vibe: user=$userId event=${event.id} '
      'combined=${(score.combined * 100).toStringAsFixed(1)}% '
      '(quantum=${(score.quantum * 100).toStringAsFixed(1)}%, '
      'topo=${(score.knotTopological * 100).toStringAsFixed(1)}%, '
      'weave=${(score.knotWeave * 100).toStringAsFixed(1)}%)',
      tag: _logName,
    );
    return score;
  }

  Future<PersonalityProfile> _getOrCreateUserProfile(String userId) async {
    final existing = await _personalityLearning.getCurrentPersonality(userId);
    if (existing != null) return existing;
    return _personalityLearning.initializePersonality(userId);
  }

  Map<String, double> _ensureAllDimensions(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (input[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    }
    return dims;
  }

  Map<String, double> _inferBusinessVibeDimensions(BusinessAccount business) {
    // If we ever store explicit dimensions for businesses, prefer them here.
    // For now: infer from business identity (type/categories/description) using SpotVibe inference.
    final inferred = SpotVibe.fromSpotCharacteristics(
      spotId: business.id,
      category: business.businessType,
      tags: business.categories,
      description: business.description ?? business.name,
      rating: 0.0,
    );
    return _ensureAllDimensions(inferred.vibeDimensions);
  }

  Map<String, double> _inferBrandVibeDimensions(BrandAccount brand) {
    // Prefer explicit dimensions if provided in matchingPreferences.
    final explicit = _extractExplicitVibeDimensions(brand.matchingPreferences);
    if (explicit != null) {
      return _ensureAllDimensions(explicit);
    }

    final inferred = SpotVibe.fromSpotCharacteristics(
      spotId: brand.id,
      category: brand.brandType,
      tags: brand.categories,
      description: brand.description ?? brand.name,
      rating: 0.0,
    );
    return _ensureAllDimensions(inferred.vibeDimensions);
  }

  Map<String, double>? _extractExplicitVibeDimensions(
    Map<String, dynamic>? preferences,
  ) {
    if (preferences == null) return null;

    final dynamic raw =
        preferences['vibeDimensions'] ?? preferences['vibe_dimensions'];
    if (raw is! Map) return null;

    final extracted = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      final v = raw[d];
      if (v is num) {
        extracted[d] = v.toDouble().clamp(0.0, 1.0);
      }
    }

    return extracted.isEmpty ? null : extracted;
  }

  double _quantumFidelity(Map<String, double> a, Map<String, double> b) {
    // Pure-state fidelity: |⟨a|b⟩|², with a/b normalized.
    final vecA = <double>[];
    final vecB = <double>[];
    for (final d in VibeConstants.coreDimensions) {
      vecA.add((a[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0));
      vecB.add((b[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0));
    }

    final normA = math.sqrt(vecA.fold<double>(0.0, (s, v) => s + v * v));
    final normB = math.sqrt(vecB.fold<double>(0.0, (s, v) => s + v * v));
    if (normA < 1e-9 || normB < 1e-9) return 0.0;

    var inner = 0.0;
    for (var i = 0; i < vecA.length; i++) {
      inner += (vecA[i] / normA) * (vecB[i] / normB);
    }

    final fidelity = (inner * inner).clamp(0.0, 1.0);
    return fidelity;
  }

  Future<EntityKnot?> _tryEntityKnotForPerson(
      PersonalityProfile profile) async {
    try {
      // Prefer embedded knot if present, otherwise generate.
      final knot = profile.personalityKnot ??
          await _personalityKnotService.generateKnot(profile);
      return EntityKnot(
        entityId: profile.agentId,
        entityType: EntityType.person,
        knot: knot,
        metadata: const {},
        createdAt: knot.createdAt,
        lastUpdated: knot.lastUpdated,
      );
    } catch (e, st) {
      developer.log(
        'Knot runtime unavailable for person, falling back to quantum-only: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<EntityKnot?> _tryEntityKnotForBusiness(
      BusinessAccount business) async {
    try {
      return await _entityKnotService.generateKnotForEntity(
        entityType: EntityType.company,
        entity: business,
      );
    } catch (e, st) {
      developer.log(
        'Knot runtime unavailable for business, falling back to quantum-only: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<EntityKnot?> _tryEntityKnotForEvent(ExpertiseEvent event) async {
    try {
      return await _entityKnotService.generateKnotForEntity(
        entityType: EntityType.event,
        entity: event,
      );
    } catch (e, st) {
      developer.log(
        'Knot runtime unavailable for event, falling back to quantum-only: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<EntityKnot?> _tryEntityKnotForBrand(BrandAccount brand) async {
    try {
      return await _entityKnotService.generateKnotForEntity(
        entityType: EntityType.brand,
        entity: brand,
      );
    } catch (e, st) {
      developer.log(
        'Knot runtime unavailable for brand, falling back to quantum-only: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<_KnotScores?> _tryKnotScores({
    required EntityKnot? entityA,
    required EntityKnot? entityB,
  }) async {
    if (entityA == null || entityB == null) return null;

    try {
      final topological = calculateTopologicalCompatibility(
        braidDataA: entityA.knot.braidData,
        braidDataB: entityB.knot.braidData,
      ).clamp(0.0, 1.0);

      final weave = _calculateWeaveCompatibility(entityA.knot, entityB.knot);

      return _KnotScores(
        topological: topological,
        weave: weave,
      );
    } catch (e, st) {
      developer.log(
        'Error computing knot compatibility (falling back to quantum-only): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  double _calculateWeaveCompatibility(
    // Reuse PersonalityKnot structure for invariants access
    dynamic knotA,
    dynamic knotB,
  ) {
    // Crossing similarity
    final aCross = (knotA.invariants.crossingNumber as int).toDouble();
    final bCross = (knotB.invariants.crossingNumber as int).toDouble();
    final crossingDiff = (aCross - bCross).abs();
    final maxCross = math.max(aCross, bCross).clamp(1.0, double.infinity);
    final crossingSimilarity =
        (1.0 - (crossingDiff / maxCross)).clamp(0.0, 1.0);

    // Polynomial similarity
    final polyDistance = polynomialDistance(
      coefficientsA:
          List<double>.from(knotA.invariants.jonesPolynomial as List),
      coefficientsB:
          List<double>.from(knotB.invariants.jonesPolynomial as List),
    );
    final polynomialSimilarity = (1.0 / (1.0 + polyDistance)).clamp(0.0, 1.0);

    // Combined weave similarity (matches CrossEntityCompatibilityService behavior)
    return (0.6 * crossingSimilarity + 0.4 * polynomialSimilarity)
        .clamp(0.0, 1.0);
  }

  VibeScore _combine({
    required double quantum,
    required _KnotScores? knot,
  }) {
    // If knot isn’t available, be truthful: return quantum-only.
    if (knot == null) {
      return VibeScore(
        combined: quantum,
        quantum: quantum,
        knotTopological: 0.0,
        knotWeave: 0.0,
        breakdown: const {'mode': 1.0}, // marker for consumers (optional)
      ).clamped();
    }

    final combined = (_quantumWeight * quantum) +
        (_topologicalWeight * knot.topological) +
        (_weaveWeight * knot.weave);

    return VibeScore(
      combined: combined,
      quantum: quantum,
      knotTopological: knot.topological,
      knotWeave: knot.weave,
      breakdown: {
        'quantum': quantum,
        'knot_topological': knot.topological,
        'knot_weave': knot.weave,
      },
    ).clamped();
  }
}
