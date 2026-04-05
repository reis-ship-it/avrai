import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

import '../signature_confidence_service.dart';
import '../signature_freshness_tracker.dart';
import 'signature_builder_support.dart';

class UserSignatureBuilder {
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  const UserSignatureBuilder({
    required SignatureConfidenceService confidenceService,
    required SignatureFreshnessTracker freshnessTracker,
  })  : _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  EntitySignature build({
    required UnifiedUser user,
    required PersonalityProfile personality,
    required UserVibe userVibe,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final dna = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        personality.corePersonality,
        personality.dimensions,
      ],
      weights: const <double>[0.65, 0.35],
    );

    final pheromones = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        userVibe.anonymizedDimensions,
        heuristicDimensionsFromText(
          title: user.displayName,
          subtitle: user.location,
          category: user.expertise,
          tags: [
            ...user.tags,
            ...user.expertiseMap.keys,
          ],
        ),
      ],
      weights: const <double>[0.8, 0.2],
    );

    final knot = personality.personalityKnot;
    final knotConfidence = knot == null
        ? 0.45
        : ((knot.invariants.crossingNumber / 12.0).clamp(0.0, 1.0) * 0.3) +
            0.55;

    final confidence = _confidenceService.blend(
      <double>[
        _confidenceService.dimensionConfidence(personality.dimensionConfidence),
        knotConfidence,
        userVibe.verifyIntegrity() ? 0.9 : 0.55,
        user.hasCompletedOnboarding == true ? 0.85 : 0.65,
      ],
    );

    final freshness = _freshnessTracker.blend(
      <double>[
        _freshnessTracker.fromTimestamp(
          personality.lastUpdated,
          decayWindow: const Duration(days: 30),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          userVibe.createdAt,
          decayWindow: const Duration(days: 7),
          now: referenceTime,
        ),
      ],
    );

    return EntitySignature(
      signatureId: 'user:${user.id}',
      entityId: user.id,
      entityKind: SignatureEntityKind.user,
      dna: dna,
      pheromones: pheromones,
      confidence: confidence,
      freshness: freshness,
      updatedAt: referenceTime,
      localityCode: user.location,
      summary:
          '${personality.archetype} rhythm with ${userVibe.getVibeArchetype().replaceAll('_', ' ')} pull.',
      sourceTrace: <SignatureSourceTrace>[
        const SignatureSourceTrace(
          kind: SignatureSourceKind.personality,
          label: 'core personality profile',
          weight: 0.65,
        ),
        const SignatureSourceTrace(
          kind: SignatureSourceKind.vibe,
          label: 'privacy-safe user vibe',
          weight: 0.8,
        ),
        if (knot != null)
          const SignatureSourceTrace(
            kind: SignatureSourceKind.knot,
            label: 'personality knot invariants',
            weight: 0.3,
          ),
      ],
    );
  }
}
