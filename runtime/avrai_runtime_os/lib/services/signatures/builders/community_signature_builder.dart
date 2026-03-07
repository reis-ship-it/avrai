import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';

import '../signature_confidence_service.dart';
import '../signature_freshness_tracker.dart';
import 'signature_builder_support.dart';

class CommunitySignatureBuilder {
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  const CommunitySignatureBuilder({
    required SignatureConfidenceService confidenceService,
    required SignatureFreshnessTracker freshnessTracker,
  })  : _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  EntitySignature build({
    required Community community,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final dnaSeed = community.vibeCentroidDimensions ??
        heuristicDimensionsFromText(
          title: community.name,
          subtitle: community.description,
          category: community.category,
          tags: community.currentLocalities,
        );

    final dna = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        dnaSeed,
        heuristicDimensionsFromText(
          title: community.name,
          subtitle: community.description,
          category: community.category,
          tags: community.currentLocalities,
        ),
      ],
      weights: community.vibeCentroidDimensions == null
          ? const <double>[0.5, 0.5]
          : const <double>[0.8, 0.2],
    );

    final pheromones = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        SignatureDimensions.nudge(
          dnaSeed,
          <String, double>{
            'community_orientation': community.memberCount > 20 ? 0.12 : 0.05,
            'social_discovery_style': community.eventCount > 0 ? 0.10 : 0.0,
            'trust_network_reliance':
                community.activityLevel == ActivityLevel.growing ? 0.08 : 0.02,
          },
        ),
        metroPheromoneShape(
          cityCode: community.cityCode,
          localityCode: community.localityCode,
          label: community.originalLocality,
          title: community.name,
          category: community.category,
          priors: MetroExperienceService.profileForMetroKey(
            metroKey: MetroExperienceService.resolveMetroKey(
              cityCode: community.cityCode,
              displayName: community.localityCode,
              fallbackLabel: community.originalLocality,
            ),
            cityCode: community.cityCode,
            localityCode: community.localityCode,
          ).communityPriors,
        ),
      ],
      weights: const <double>[0.82, 0.18],
    );

    final confidence = _confidenceService.blend(
      <double>[
        _confidenceService.completeness(
          presentFields: [
            community.name,
            community.category,
            community.originalLocality,
            if ((community.description ?? '').isNotEmpty) 'description',
          ].length,
          expectedFields: 4,
        ),
        community.vibeCentroidContributors > 0
            ? (0.55 +
                (community.vibeCentroidContributors / 20.0).clamp(0.0, 0.35))
            : 0.58,
        community.externalSyncMetadata != null ? 0.82 : 0.72,
      ],
    );

    final freshness = _freshnessTracker.blend(
      <double>[
        _freshnessTracker.fromTimestamp(
          community.updatedAt,
          decayWindow: const Duration(days: 30),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          community.lastEventAt,
          decayWindow: const Duration(days: 14),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          community.externalSyncMetadata?.lastSyncedAt,
          decayWindow: const Duration(days: 7),
          now: referenceTime,
        ),
      ],
    );

    return EntitySignature(
      signatureId: 'community:${community.id}',
      entityId: community.id,
      entityKind: SignatureEntityKind.community,
      dna: dna,
      pheromones: pheromones,
      confidence: confidence,
      freshness: freshness,
      updatedAt: referenceTime,
      cityCode: community.cityCode,
      localityCode: community.localityCode ?? community.originalLocality,
      summary:
          '${community.category} community with ${community.memberCount} member rhythm.',
      sourceTrace: <SignatureSourceTrace>[
        SignatureSourceTrace(
          kind: community.vibeCentroidDimensions == null
              ? SignatureSourceKind.derived
              : SignatureSourceKind.vibe,
          label: community.vibeCentroidDimensions == null
              ? 'community structure heuristics'
              : 'aggregated community centroid',
          sourceId: community.id,
          weight: 0.8,
        ),
        if (community.externalSyncMetadata != null)
          SignatureSourceTrace(
            kind: SignatureSourceKind.intake,
            label: community.externalSyncMetadata!.sourceProvider,
            sourceId: community.externalSyncMetadata!.externalId,
            weight: 0.2,
          ),
      ],
    );
  }
}
