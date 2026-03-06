import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';

import '../signature_confidence_service.dart';
import '../signature_freshness_tracker.dart';
import 'signature_builder_support.dart';

class EventSignatureBuilder {
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  const EventSignatureBuilder({
    required SignatureConfidenceService confidenceService,
    required SignatureFreshnessTracker freshnessTracker,
  })  : _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  EntitySignature build({
    required ExpertiseEvent event,
    EntitySignature? bundleSignature,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final eventHeuristics = heuristicDimensionsFromText(
      title: event.title,
      subtitle: event.description,
      category: '${event.category} ${event.eventType.name}',
      tags: <String>[
        event.location ?? '',
        ...event.spots.map((spot) => spot.category),
      ],
    );

    final hostHeuristics = heuristicDimensionsFromText(
      title: event.host.displayName,
      subtitle: event.host.location,
      category: event.host.expertise,
      tags: event.host.tags,
    );

    final dna = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        eventHeuristics,
        hostHeuristics,
        if (bundleSignature != null) bundleSignature.dna,
      ],
      weights: <double>[
        0.55,
        0.2,
        if (bundleSignature != null) 0.25,
      ],
    );

    final hoursUntilStart =
        event.startTime.difference(referenceTime).inMinutes.toDouble() / 60.0;
    final liveNowBoost = event.status == EventStatus.ongoing
        ? 0.18
        : hoursUntilStart <= 6
            ? 0.12
            : hoursUntilStart <= 24
                ? 0.06
                : 0.0;
    final attendanceFill = event.maxAttendees == 0
        ? 0.0
        : (event.attendeeCount / event.maxAttendees).clamp(0.0, 1.0);

    final pheromones = SignatureDimensions.weightedBlend(
      <Map<String, double>>[
        SignatureDimensions.nudge(
          eventHeuristics,
          <String, double>{
            'energy_preference': liveNowBoost,
            'social_discovery_style': attendanceFill * 0.14,
            'community_orientation': event.attendeeCount > 8 ? 0.08 : 0.03,
          },
        ),
        if (bundleSignature != null) bundleSignature.pheromones,
        metroPheromoneShape(
          cityCode: event.cityCode,
          localityCode: event.localityCode,
          label: event.location,
          title: event.title,
          category: event.category,
          priors: MetroExperienceService.profileForMetroKey(
            metroKey: MetroExperienceService.resolveMetroKey(
              cityCode: event.cityCode,
              displayName: event.localityCode,
              fallbackLabel: event.location,
            ),
            cityCode: event.cityCode,
            localityCode: event.localityCode,
          ).eventPriors,
        ),
      ],
      weights: <double>[
        0.7,
        if (bundleSignature != null) 0.2,
        0.1,
      ],
    );

    final confidence = _confidenceService.blend(
      <double>[
        _confidenceService.completeness(
          presentFields: [
            event.title,
            event.description,
            event.category,
            event.startTime.toIso8601String(),
            if ((event.location ?? '').isNotEmpty) event.location!,
          ].length,
          expectedFields: 5,
        ),
        event.externalSyncMetadata != null ? 0.84 : 0.72,
        bundleSignature?.confidence ?? 0.68,
      ],
    );

    final freshness = _freshnessTracker.blend(
      <double>[
        _freshnessTracker.fromTimestamp(
          event.updatedAt,
          decayWindow: const Duration(days: 14),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          event.externalSyncMetadata?.lastSyncedAt,
          decayWindow: const Duration(days: 7),
          now: referenceTime,
        ),
        _freshnessTracker.fromTimestamp(
          event.startTime,
          decayWindow: const Duration(days: 3),
          now: referenceTime,
        ),
      ],
    );

    return EntitySignature(
      signatureId: 'event:${event.id}',
      entityId: event.id,
      entityKind: SignatureEntityKind.event,
      dna: dna,
      pheromones: pheromones,
      confidence: confidence,
      freshness: freshness,
      updatedAt: referenceTime,
      cityCode: event.cityCode,
      localityCode: event.localityCode,
      summary:
          '${event.category} ${event.eventType.name} with ${event.attendeeCount} person momentum.',
      sourceTrace: <SignatureSourceTrace>[
        const SignatureSourceTrace(
          kind: SignatureSourceKind.derived,
          label: 'event structure and timing',
          weight: 0.55,
        ),
        SignatureSourceTrace(
          kind: SignatureSourceKind.derived,
          label: 'host pattern',
          sourceId: event.host.id,
          weight: 0.2,
        ),
        if (bundleSignature != null)
          SignatureSourceTrace(
            kind: SignatureSourceKind.bundle,
            label: 'linked bundle signature',
            sourceId: bundleSignature.entityId,
            weight: 0.25,
          ),
        if (event.externalSyncMetadata != null)
          SignatureSourceTrace(
            kind: SignatureSourceKind.intake,
            label: event.externalSyncMetadata!.sourceProvider,
            sourceId: event.externalSyncMetadata!.externalId,
            weight: 0.15,
          ),
      ],
      bundleEntityIds: bundleSignature?.bundleEntityIds ?? const <String>[],
    );
  }
}
