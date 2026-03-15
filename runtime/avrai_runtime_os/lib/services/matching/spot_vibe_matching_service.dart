import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/user/unified_models.dart' hide UnifiedUser;
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/quantum/location_compatibility_calculator.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_calculator.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

/// Spot Vibe Matching Service
///
/// CORE PHILOSOPHY: Vibe-based matching
/// - Business accounts define their spot's unique vibe
/// - Users are "called" to spots based on vibe compatibility
/// - Spot vibe + User vibe = Better matches, happier everyone
///
/// The overall vibe of the spot (defined by business accounts) should match
/// the overall vibe of the user (known through AI2AI system).
///
/// Example: Bemelmans might have a sophisticated, art-focused, cultural vibe.
/// Users with matching vibes (sophisticated, art-loving, cultural) are "called" to it.
///
/// This is better than matching based on individual behaviors because:
/// - It considers the overall atmosphere and character of the spot
/// - It matches the whole person, not just one trait
/// - Business accounts can accurately represent their spot's vibe
/// - Users get better matches, spots get better customers, everyone is happier
class SpotVibeMatchingService {
  static const String _logName = 'SpotVibeMatchingService';

  final UserVibeAnalyzer _vibeAnalyzer;
  final CallingScoreCalculator? _callingScoreCalculator;
  final FeatureFlagService? _featureFlags;
  final EntitySignatureService? _entitySignatureService;
  final EntityKnotService? _entityKnotService;
  final PersonalityKnotService? _personalityKnotService;
  final CanonicalVibeProjectionService _canonicalVibeProjectionService;

  SpotVibeMatchingService({
    required UserVibeAnalyzer vibeAnalyzer,
    CallingScoreCalculator? callingScoreCalculator,
    FeatureFlagService? featureFlags,
    EntitySignatureService? entitySignatureService,
    EntityKnotService? entityKnotService,
    PersonalityKnotService? personalityKnotService,
    CanonicalVibeProjectionService? canonicalVibeProjectionService,
  })  : _vibeAnalyzer = vibeAnalyzer,
        _callingScoreCalculator = callingScoreCalculator,
        _featureFlags = featureFlags,
        _entitySignatureService = entitySignatureService,
        _entityKnotService = entityKnotService,
        _personalityKnotService = personalityKnotService,
        _canonicalVibeProjectionService =
            canonicalVibeProjectionService ?? CanonicalVibeProjectionService();

  /// Calculate vibe compatibility between a user and a spot
  /// Returns compatibility score (0.0 to 1.0)
  /// Higher = better match, user should be "called" to this spot
  ///
  /// **Enhanced with Location Entanglement:**
  /// If userLocation and spotLocation are provided, uses enhanced formula:
  /// ```
  /// compatibility = 0.5 * vibe_compatibility + 0.3 * location_compatibility + 0.2 * timing_compatibility
  /// ```
  ///
  /// **Parameters:**
  /// - `user`: User to match
  /// - `spot`: Spot to match against
  /// - `userPersonality`: User's personality profile
  /// - `spotVibe`: Optional spot vibe (if not provided, inferred from spot)
  /// - `userLocation`: Optional user location for location entanglement
  /// - `spotLocation`: Optional spot location for location entanglement
  /// - `timingCompatibility`: Optional timing compatibility (0.0 to 1.0)
  Future<double> calculateSpotUserCompatibility({
    required UnifiedUser user,
    required Spot spot,
    required PersonalityProfile userPersonality,
    SpotVibe? spotVibe, // If provided, use it; otherwise infer from spot
    UnifiedLocation? userLocation, // Optional: for location entanglement
    UnifiedLocation? spotLocation, // Optional: for location entanglement
    double? timingCompatibility, // Optional: timing compatibility
  }) async {
    final result = await calculateSpotUserCompatibilityResult(
      user: user,
      spot: spot,
      userPersonality: userPersonality,
      spotVibe: spotVibe,
      userLocation: userLocation,
      spotLocation: spotLocation,
      timingCompatibility: timingCompatibility,
    );
    return result.finalScore;
  }

  Future<SignatureMatchResult> calculateSpotUserCompatibilityResult({
    required UnifiedUser user,
    required Spot spot,
    required PersonalityProfile userPersonality,
    SpotVibe? spotVibe,
    UnifiedLocation? userLocation,
    UnifiedLocation? spotLocation,
    double? timingCompatibility,
  }) async {
    final canonicalPersonality = await _canonicalizeUserPersonality(
      user.id,
      userPersonality,
    );
    final legacyCompatibility = await _calculateLegacySpotUserCompatibility(
      user: user,
      spot: spot,
      userPersonality: canonicalPersonality,
      spotVibe: spotVibe,
      userLocation: userLocation,
      spotLocation: spotLocation,
      timingCompatibility: timingCompatibility,
    );
    if (_entitySignatureService == null) {
      return SignatureMatchResult(
        entityId: spot.id,
        entityKind: SignatureEntityKind.spot,
        dnaScore: legacyCompatibility,
        pheromoneScore: legacyCompatibility,
        signatureScore: legacyCompatibility,
        finalScore: legacyCompatibility,
        fallbackScore: legacyCompatibility,
        confidence: 0.5,
        freshness: 0.5,
        mode: SignatureScoreMode.fallback,
        summary: 'Fallback spot score only.',
      );
    }

    try {
      return await _entitySignatureService.matchUserToSpot(
        user: user,
        spot: spot,
        fallbackScore: legacyCompatibility,
        personality: canonicalPersonality,
      );
    } catch (e, st) {
      developer.log(
        'Error applying signature-first spot compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return SignatureMatchResult(
        entityId: spot.id,
        entityKind: SignatureEntityKind.spot,
        dnaScore: legacyCompatibility,
        pheromoneScore: legacyCompatibility,
        signatureScore: legacyCompatibility,
        finalScore: legacyCompatibility,
        fallbackScore: legacyCompatibility,
        confidence: 0.5,
        freshness: 0.5,
        mode: SignatureScoreMode.fallback,
        summary: 'Fallback spot score only.',
      );
    }
  }

  Future<double> _calculateLegacySpotUserCompatibility({
    required UnifiedUser user,
    required Spot spot,
    required PersonalityProfile userPersonality,
    SpotVibe? spotVibe,
    UnifiedLocation? userLocation,
    UnifiedLocation? spotLocation,
    double? timingCompatibility,
  }) async {
    try {
      final userVibe = await _vibeAnalyzer.compileUserVibe(
        user.id,
        userPersonality,
      );
      final vibe = spotVibe ?? _inferSpotVibe(spot);
      final vibeCompatibility = vibe.calculateVibeCompatibility(userVibe);
      final knotBonus = await _calculateKnotCompatibilityBonus(
        user: user,
        userPersonality: userPersonality,
        spot: spot,
      );
      final baseCompatibility = vibeCompatibility * 0.85 + knotBonus * 0.15;

      final locationEntanglementEnabled = _featureFlags != null
          ? await _featureFlags.isEnabled(
              QuantumFeatureFlags.locationEntanglement,
              userId: user.id,
              defaultValue: false,
            )
          : false;

      if (locationEntanglementEnabled &&
          userLocation != null &&
          spotLocation != null) {
        final locationCompatibility =
            LocationCompatibilityCalculator.calculateLocationCompatibility(
          locationA: userLocation,
          locationB: spotLocation,
        );
        final enhancedCompatibility =
            LocationCompatibilityCalculator.calculateEnhancedCompatibility(
          personalityCompatibility: baseCompatibility,
          locationCompatibility: locationCompatibility,
          timingCompatibility: timingCompatibility,
        );

        developer.log(
          'Spot-User compatibility (with location + knot): ${spot.name} <-> ${user.id}: '
          'vibe=${(vibeCompatibility * 100).toStringAsFixed(1)}%, '
          'knot=${(knotBonus * 100).toStringAsFixed(1)}%, '
          'location=${(locationCompatibility * 100).toStringAsFixed(1)}%, '
          'total=${(enhancedCompatibility * 100).toStringAsFixed(1)}%',
          name: _logName,
        );

        return enhancedCompatibility;
      }

      developer.log(
        'Spot-User compatibility (legacy vibe+knot): ${spot.name} <-> ${user.id}: '
        'vibe=${(vibeCompatibility * 100).toStringAsFixed(1)}%, '
        'knot=${(knotBonus * 100).toStringAsFixed(1)}%, '
        'total=${(baseCompatibility * 100).toStringAsFixed(1)}%',
        name: _logName,
      );
      return baseCompatibility;
    } catch (e) {
      developer.log(
        'Error calculating legacy spot-user compatibility: $e',
        name: _logName,
      );
      return 0.5;
    }
  }

  /// Check if a spot should "call" a user
  /// Returns true if calling score is high enough for recommendation
  ///
  /// NEW: Uses unified calling score if available, falls back to compatibility
  Future<bool> shouldCallUserToSpot({
    required UnifiedUser user,
    required Spot spot,
    required PersonalityProfile userPersonality,
    SpotVibe? spotVibe,
    Position? currentLocation,
    double threshold = 0.7, // 70% calling score threshold
  }) async {
    final canonicalPersonality = await _canonicalizeUserPersonality(
      user.id,
      userPersonality,
    );
    // Use calling score calculator if available
    if (_callingScoreCalculator != null) {
      try {
        final userVibe =
            await _vibeAnalyzer.compileUserVibe(user.id, canonicalPersonality);
        final vibe = spotVibe ?? _inferSpotVibe(spot);

        final context = currentLocation != null
            ? CallingContext.fromLocation(
                currentLocation,
                Position(
                  latitude: spot.latitude,
                  longitude: spot.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0.0,
                  altitude: 0.0,
                  altitudeAccuracy: 0.0,
                  heading: 0.0,
                  headingAccuracy: 0.0,
                  speed: 0.0,
                  speedAccuracy: 0.0,
                ),
              )
            : CallingContext.empty();

        final timing = TimingFactors.fromDateTime(DateTime.now());

        final callingScore =
            await _callingScoreCalculator.calculateCallingScore(
          userVibe: userVibe,
          opportunityVibe: vibe,
          context: context,
          timing: timing,
          userPersonality: canonicalPersonality,
          userId: user.id, // Phase 12: For data collection
        );

        return callingScore.isCalled;
      } catch (e) {
        developer.log(
            'Error calculating calling score, falling back to compatibility: $e',
            name: _logName);
        // Fall through to compatibility-based check
      }
    }

    // Fallback to compatibility-based check
    final compatibility = await calculateSpotUserCompatibility(
      user: user,
      spot: spot,
      userPersonality: canonicalPersonality,
      spotVibe: spotVibe,
    );

    return compatibility >= threshold;
  }

  /// Find spots that should "call" a user
  /// Returns spots sorted by vibe compatibility (highest first)
  Future<List<SpotMatch>> findMatchingSpots({
    required UnifiedUser user,
    required List<Spot> candidateSpots,
    required PersonalityProfile userPersonality,
    Map<String, SpotVibe>? spotVibes, // Map of spotId -> SpotVibe
    double minCompatibility = 0.7, // Minimum compatibility to include
    int maxResults = 20, // Maximum number of results
  }) async {
    try {
      final canonicalPersonality = await _canonicalizeUserPersonality(
        user.id,
        userPersonality,
      );
      // Get user vibe from AI2AI system
      final userVibe = await _vibeAnalyzer.compileUserVibe(
        user.id,
        canonicalPersonality,
      );

      final matches = <SpotMatch>[];

      for (final spot in candidateSpots) {
        // Get spot vibe (from provided map or infer)
        final spotVibe = spotVibes?[spot.id] ?? _inferSpotVibe(spot);

        // Calculate compatibility
        final compatibility = spotVibe.calculateVibeCompatibility(userVibe);

        if (compatibility >= minCompatibility) {
          matches.add(SpotMatch(
            spot: spot,
            spotVibe: spotVibe,
            compatibility: compatibility,
            shouldCall: true,
          ));
        }
      }

      // Sort by compatibility (highest first)
      matches.sort((a, b) => b.compatibility.compareTo(a.compatibility));

      // Limit results
      final results = matches.take(maxResults).toList();

      developer.log(
        'Found ${results.length} matching spots for user ${user.id} '
        '(min compatibility: ${(minCompatibility * 100).toStringAsFixed(0)}%)',
        name: _logName,
      );

      return results;
    } catch (e) {
      developer.log('Error finding matching spots: $e', name: _logName);
      return [];
    }
  }

  /// Infer spot vibe from spot characteristics (fallback if no business definition)
  SpotVibe _inferSpotVibe(Spot spot) {
    return SpotVibe.fromSpotCharacteristics(
      spotId: spot.id,
      category: spot.category,
      tags: spot.tags,
      description: spot.description,
      rating: spot.rating,
    );
  }

  /// Calculate knot compatibility bonus for spot-user matching
  ///
  /// Calculates knot-only compatibility (topology + weave) between
  /// the user personality knot and the spot entity knot.
  ///
  /// **Important:** We intentionally do **not** call
  /// `CrossEntityCompatibilityService.calculateIntegratedCompatibility()` here,
  /// because that method currently contains a placeholder "quantum" term.
  ///
  /// **Returns:** Compatibility score (0.0 to 1.0), or 0.5 (neutral) if unavailable
  Future<double> _calculateKnotCompatibilityBonus({
    required UnifiedUser user,
    required PersonalityProfile userPersonality,
    required Spot spot,
  }) async {
    // If knot services not available, return neutral score
    if (_entityKnotService == null || _personalityKnotService == null) {
      return 0.5;
    }

    try {
      // Get user personality knot
      final userKnot = userPersonality.personalityKnot ??
          await _personalityKnotService.generateKnot(userPersonality);

      // Generate spot entity knot
      final spotEntityKnot = await _entityKnotService.generateKnotForEntity(
        entityType: EntityType.place,
        entity: spot,
      );

      // Knot-only compatibility:
      // - Topological compatibility from braid/invariants
      // - Weave similarity from crossing + polynomial similarity
      final topological = calculateTopologicalCompatibility(
        braidDataA: userKnot.braidData,
        braidDataB: spotEntityKnot.knot.braidData,
      ).clamp(0.0, 1.0);

      final weave = _calculateWeaveCompatibility(userKnot, spotEntityKnot.knot);

      // Blend knot signals (knot-only). This is a "bonus" term elsewhere.
      final compatibility = (0.6 * topological + 0.4 * weave).clamp(0.0, 1.0);

      developer.log(
        'Knot compatibility bonus for spot ${spot.name}: ${(compatibility * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      return compatibility;
    } catch (e) {
      developer.log(
        'Error calculating knot compatibility bonus: $e, using neutral score',
        name: _logName,
      );
      // Return neutral score on error (don't break matching)
      return 0.5;
    }
  }

  double _calculateWeaveCompatibility(
    dynamic knotA,
    dynamic knotB,
  ) {
    final aCross = (knotA.invariants.crossingNumber as int).toDouble();
    final bCross = (knotB.invariants.crossingNumber as int).toDouble();
    final crossingDiff = (aCross - bCross).abs();
    final maxCross = math.max(aCross, bCross).clamp(1.0, double.infinity);
    final crossingSimilarity =
        (1.0 - (crossingDiff / maxCross)).clamp(0.0, 1.0);

    final polyDistance = polynomialDistance(
      coefficientsA:
          List<double>.from(knotA.invariants.jonesPolynomial as List),
      coefficientsB:
          List<double>.from(knotB.invariants.jonesPolynomial as List),
    );
    final polynomialSimilarity = (1.0 / (1.0 + polyDistance)).clamp(0.0, 1.0);

    return (0.6 * crossingSimilarity + 0.4 * polynomialSimilarity)
        .clamp(0.0, 1.0);
  }

  Future<PersonalityProfile> _canonicalizeUserPersonality(
    String userId,
    PersonalityProfile userPersonality,
  ) {
    return _canonicalVibeProjectionService.canonicalizeUserProfile(
      userId: userId,
      profile: userPersonality,
    );
  }
}

/// Spot Match Result
/// Represents a spot that matches a user's vibe
class SpotMatch {
  final Spot spot;
  final SpotVibe spotVibe;
  final double compatibility; // 0.0 to 1.0
  final bool shouldCall; // Should this spot "call" the user?

  SpotMatch({
    required this.spot,
    required this.spotVibe,
    required this.compatibility,
    required this.shouldCall,
  });

  /// Get match quality description
  String get matchQuality {
    if (compatibility >= 0.9) return 'Perfect Match';
    if (compatibility >= 0.8) return 'Excellent Match';
    if (compatibility >= 0.7) return 'Great Match';
    if (compatibility >= 0.6) return 'Good Match';
    return 'Moderate Match';
  }
}
