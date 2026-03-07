import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';

import '../signature_confidence_service.dart';
import '../signature_freshness_tracker.dart';
import 'signature_builder_support.dart';

class SpotSignatureBuilder {
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  const SpotSignatureBuilder({
    required SignatureConfidenceService confidenceService,
    required SignatureFreshnessTracker freshnessTracker,
  })  : _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  EntitySignature build({
    required Spot spot,
    SpotVibe? spotVibe,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final resolvedVibe = spotVibe ??
        SpotVibe.fromSpotCharacteristics(
          spotId: spot.id,
          category: spot.category,
          tags: spot.tags,
          description: spot.description,
          rating: spot.rating,
        );

    final dna = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        resolvedVibe.vibeDimensions,
        heuristicDimensionsFromText(
          title: spot.name,
          subtitle: spot.description,
          category: spot.category,
          tags: spot.tags,
        ),
      ],
      weights: const <double>[0.75, 0.25],
    );

    final pheromones = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        SignatureDimensions.nudge(
          resolvedVibe.vibeDimensions,
          <String, double>{
            'energy_preference': spot.rating >= 4.5 ? 0.08 : 0.0,
            'social_discovery_style':
                spot.metadata['is_external'] == true ? -0.04 : 0.06,
          },
        ),
        metroPheromoneShape(
          cityCode: spot.cityCode,
          localityCode: spot.localityCode,
          label: spot.address,
          title: spot.name,
          category: spot.category,
          priors: MetroExperienceService.profileForMetroKey(
            metroKey: MetroExperienceService.resolveMetroKey(
              cityCode: spot.cityCode,
              displayName: spot.localityCode,
              fallbackLabel: spot.address,
            ),
            cityCode: spot.cityCode,
            localityCode: spot.localityCode,
          ).spotPriors,
        ),
      ],
      weights: const <double>[0.8, 0.2],
    );

    final confidence = _confidenceService.blend(
      <double>[
        _confidenceService.completeness(
          presentFields: [
            spot.name,
            spot.description,
            spot.category,
            if ((spot.address ?? '').isNotEmpty) spot.address!,
            if (spot.tags.isNotEmpty) 'tags',
          ].length,
          expectedFields: 5,
        ),
        spot.externalSyncMetadata != null ? 0.82 : 0.7,
        resolvedVibe.definedBy != null ? 0.9 : 0.72,
      ],
    );

    final freshness = _freshnessTracker.blend(
      <double>[
        _freshnessTracker.fromTimestamp(
          spot.updatedAt,
          decayWindow: const Duration(days: 21),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          spot.externalSyncMetadata?.lastSyncedAt,
          decayWindow: const Duration(days: 7),
          now: referenceTime,
        ),
      ],
    );

    return EntitySignature(
      signatureId: 'spot:${spot.id}',
      entityId: spot.id,
      entityKind: SignatureEntityKind.spot,
      dna: dna,
      pheromones: pheromones,
      confidence: confidence,
      freshness: freshness,
      updatedAt: referenceTime,
      cityCode: spot.cityCode,
      localityCode: spot.localityCode,
      summary:
          '${spot.category} spot with ${resolvedVibe.vibeDescription} pull.',
      sourceTrace: <SignatureSourceTrace>[
        SignatureSourceTrace(
          kind: SignatureSourceKind.vibe,
          label: resolvedVibe.definedBy != null
              ? 'business-defined spot vibe'
              : 'inferred spot vibe',
          sourceId: resolvedVibe.spotId,
          weight: 0.75,
        ),
        if (spot.externalSyncMetadata != null)
          SignatureSourceTrace(
            kind: SignatureSourceKind.intake,
            label: spot.externalSyncMetadata!.sourceProvider,
            sourceId: spot.externalSyncMetadata!.externalId,
            weight: 0.25,
          ),
      ],
    );
  }
}
