import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';
import 'package:reality_engine/reality_engine.dart';

double _lerp(double start, double end, double t) {
  return (start + ((end - start) * t)).clamp(0.0, 1.0);
}

String _socialContextForEncounterCount({
  required int encounteredCount,
  int confirmedInteractiveCount = 0,
}) {
  if (encounteredCount <= 0) {
    return 'solo';
  }
  if (encounteredCount == 1 && confirmedInteractiveCount > 0) {
    return 'dyad';
  }
  if (encounteredCount <= 2) {
    return 'small_group';
  }
  if (encounteredCount <= 4) {
    return 'social_cluster';
  }
  return 'crowd';
}

String _placeVibeLabelForEncounterCount({
  required int encounteredCount,
  int confirmedInteractiveCount = 0,
}) {
  if (encounteredCount <= 0) {
    return 'quiet_retreat';
  }
  if (encounteredCount == 1 && confirmedInteractiveCount > 0) {
    return 'intimate_social';
  }
  if (encounteredCount <= 2) {
    return 'intimate_social';
  }
  if (encounteredCount <= 4) {
    return 'social_hub';
  }
  return 'crowd_energy';
}

double _crowdRecognitionScoreForEncounterCount({
  required int encounteredCount,
  int confirmedInteractiveCount = 0,
  double interactionQuality = 0.0,
  double confidence = 0.0,
}) {
  final baseScore = switch (encounteredCount) {
    <= 0 => 0.0,
    1 => 0.38,
    2 => 0.62,
    <= 4 => 0.78,
    _ => 0.92,
  };
  final confirmedBoost = confirmedInteractiveCount <= 0
      ? 0.0
      : (0.12 + ((confirmedInteractiveCount - 1).clamp(0, 3) * 0.06))
          .clamp(0.0, 0.3);
  final qualityBoost = interactionQuality.clamp(0.0, 1.0) * 0.08;
  final confidenceBoost = confidence.clamp(0.0, 1.0) * 0.05;
  return (baseScore + confirmedBoost + qualityBoost + confidenceBoost)
      .clamp(0.0, 0.98);
}

class PassiveDwellLearningProjection {
  const PassiveDwellLearningProjection({
    required this.socialContext,
    required this.placeVibeLabel,
    required this.crowdRecognitionScore,
    required this.localityStableKey,
    required this.structuredSignals,
    required this.derivedSemanticTuples,
    required this.localityBinding,
    required this.localityDimensions,
    required this.personalDimensions,
  });

  final String socialContext;
  final String placeVibeLabel;
  final double crowdRecognitionScore;
  final String localityStableKey;
  final Map<String, dynamic> structuredSignals;
  final List<SemanticTuple> derivedSemanticTuples;
  final GeographicVibeBinding localityBinding;
  final Map<String, double> localityDimensions;
  final Map<String, double> personalDimensions;

  bool get hasPersonalLearning => personalDimensions.isNotEmpty;

  factory PassiveDwellLearningProjection.fromEvent(DwellEvent event) {
    final encounteredCount = event.encounteredAgentIds.toSet().length;
    final durationMinutes =
        event.endTime.difference(event.startTime).inMinutes.clamp(0, 24 * 60);
    final crowdRecognitionScore = _crowdRecognitionScoreForEncounterCount(
      encounteredCount: encounteredCount,
    );
    final socialContext = _socialContextForEncounterCount(
      encounteredCount: encounteredCount,
    );
    final placeVibeLabel = _placeVibeLabelForEncounterCount(
      encounteredCount: encounteredCount,
    );
    final dwellStrength = (durationMinutes / 120.0).clamp(0.2, 1.0);
    final socialIntensity =
        (crowdRecognitionScore * 0.78 + dwellStrength * 0.22).clamp(0.0, 1.0);
    final localityKey = LocalityAgentKeyV1(
      geohashPrefix: GeohashService.encode(
        latitude: event.latitude,
        longitude: event.longitude,
        precision: 7,
      ),
      precision: 7,
    );
    final localityStableKey = localityKey.stableKey;
    final localityBinding = GeographicVibeBinding(
      localityRef: VibeSubjectRef.locality(localityStableKey),
      stableKey: localityStableKey,
      scope: 'locality',
      metadata: <String, dynamic>{
        'passive_source': 'dwell_event',
        'place_vibe_label': placeVibeLabel,
        'social_context': socialContext,
        'encountered_agent_count': encounteredCount,
        'crowd_recognition_score': crowdRecognitionScore,
      },
    );
    final localityDimensions = <String, double>{
      'community_orientation': _lerp(0.28, 0.86, socialIntensity),
      'social_discovery_style': _lerp(0.26, 0.82, socialIntensity),
      'trust_network_reliance': _lerp(0.34, 0.74, socialIntensity),
      'energy_preference': _lerp(0.32, 0.83, socialIntensity),
      'crowd_tolerance': _lerp(0.18, 0.92, socialIntensity),
      'novelty_seeking': _lerp(0.40, 0.72, socialIntensity),
    };
    final personalDimensions = encounteredCount == 0
        ? const <String, double>{}
        : <String, double>{
            for (final entry in localityDimensions.entries)
              entry.key: (0.5 + ((entry.value - 0.5) * 0.34)).clamp(0.0, 1.0),
          };

    final structuredSignals = <String, dynamic>{
      'encounteredAgentCount': encounteredCount,
      'coPresenceDetected': encounteredCount > 0,
      'multiAgentDetected': encounteredCount > 1,
      'meshEncounterDetected': encounteredCount > 0,
      'socialDensityClass': socialContext,
      'placeVibeLabel': placeVibeLabel,
      'crowdRecognitionScore': crowdRecognitionScore,
      'dwellDurationMinutes': durationMinutes,
      'localityStableKey': localityStableKey,
      'autonomousCrowdRecognition': encounteredCount > 1,
    };

    final extractedAt = event.endTime.toUtc();
    final tupleSeed =
        '${event.startTime.microsecondsSinceEpoch}:${event.endTime.microsecondsSinceEpoch}:$localityStableKey';
    final derivedSemanticTuples = <SemanticTuple>[
      SemanticTuple(
        id: 'dwell-social:$tupleSeed',
        category: 'social_context',
        subject: 'dwell_context',
        predicate: 'recognized_social_density',
        object: socialContext,
        confidence: (0.54 + crowdRecognitionScore * 0.34).clamp(0.0, 0.96),
        extractedAt: extractedAt,
      ),
      SemanticTuple(
        id: 'dwell-place-vibe:$tupleSeed',
        category: 'place_vibe',
        subject: 'locality',
        predicate: 'expresses_place_vibe',
        object: placeVibeLabel,
        confidence: (0.58 + socialIntensity * 0.28).clamp(0.0, 0.96),
        extractedAt: extractedAt,
      ),
      if (encounteredCount > 0)
        SemanticTuple(
          id: 'dwell-copresence:$tupleSeed',
          category: 'mesh_presence',
          subject: 'passive_mesh',
          predicate: 'recognized_co_presence',
          object: encounteredCount > 1 ? 'multi_agent_presence' : 'single_peer',
          confidence: (0.60 + crowdRecognitionScore * 0.30).clamp(0.0, 0.96),
          extractedAt: extractedAt,
        ),
    ];

    return PassiveDwellLearningProjection(
      socialContext: socialContext,
      placeVibeLabel: placeVibeLabel,
      crowdRecognitionScore: crowdRecognitionScore,
      localityStableKey: localityStableKey,
      structuredSignals: structuredSignals,
      derivedSemanticTuples: derivedSemanticTuples,
      localityBinding: localityBinding,
      localityDimensions: localityDimensions,
      personalDimensions: personalDimensions,
    );
  }
}

enum AmbientSocialLearningObservationSource {
  passiveDwell('passive_dwell'),
  ai2aiCompletedInteraction('ai2ai_completed_interaction');

  const AmbientSocialLearningObservationSource(this.wireName);

  final String wireName;
}

class AmbientSocialLearningObservation {
  const AmbientSocialLearningObservation({
    required this.source,
    required this.observedAtUtc,
    required this.localityBinding,
    this.discoveredPeerIds = const <String>[],
    this.confirmedInteractivePeerIds = const <String>[],
    this.confidence = 0.58,
    this.interactionQuality,
    this.semanticTuples = const <SemanticTuple>[],
    this.structuredSignals = const <String, dynamic>{},
    this.locationContext = const <String, dynamic>{},
    this.temporalContext = const <String, dynamic>{},
    this.activityContext,
    this.lineageRef,
  });

  final AmbientSocialLearningObservationSource source;
  final DateTime observedAtUtc;
  final GeographicVibeBinding localityBinding;
  final List<String> discoveredPeerIds;
  final List<String> confirmedInteractivePeerIds;
  final double confidence;
  final double? interactionQuality;
  final List<SemanticTuple> semanticTuples;
  final Map<String, dynamic> structuredSignals;
  final Map<String, dynamic> locationContext;
  final Map<String, dynamic> temporalContext;
  final String? activityContext;
  final String? lineageRef;

  factory AmbientSocialLearningObservation.fromPassiveDwell({
    required DwellEvent event,
    required PassiveDwellLearningProjection projection,
  }) {
    return AmbientSocialLearningObservation(
      source: AmbientSocialLearningObservationSource.passiveDwell,
      observedAtUtc: event.endTime.toUtc(),
      localityBinding: projection.localityBinding,
      discoveredPeerIds: event.encounteredAgentIds.toSet().toList(growable: false),
      confidence: 0.59,
      semanticTuples: projection.derivedSemanticTuples,
      structuredSignals: projection.structuredSignals,
      locationContext: <String, dynamic>{
        'latitude': event.latitude,
        'longitude': event.longitude,
        'localityStableKey': projection.localityStableKey,
      },
      temporalContext: <String, dynamic>{
        'startTime': event.startTime.toUtc().toIso8601String(),
        'endTime': event.endTime.toUtc().toIso8601String(),
        'durationMinutes': event.endTime.difference(event.startTime).inMinutes,
      },
      activityContext: 'ambient_socializing',
      lineageRef:
          'ambient:dwell:${event.startTime.microsecondsSinceEpoch}:${event.endTime.microsecondsSinceEpoch}',
    );
  }
}

class AmbientSocialLearningDiagnosticsSnapshot {
  const AmbientSocialLearningDiagnosticsSnapshot({
    required this.capturedAtUtc,
    required this.normalizedObservationCount,
    required this.candidateCoPresenceObservationCount,
    required this.confirmedInteractionPromotionCount,
    required this.duplicateMergeCount,
    required this.rejectedInteractionPromotionCount,
    required this.crowdUpgradeCount,
    required this.whatIngestionCount,
    required this.localityVibeUpdateCount,
    required this.personalDnaAuthorizedCount,
    required this.personalDnaAppliedCount,
    required this.latestNearbyPeerCount,
    required this.latestConfirmedInteractivePeerCount,
    this.latestSocialContext,
    this.latestPlaceVibeLabel,
    this.latestLocalityStableKey,
    this.sourceCounts = const <String, int>{},
    this.lastPromotionTrace,
    this.recentPromotionTraces = const <AmbientSocialPromotionTrace>[],
  });

  final DateTime capturedAtUtc;
  final int normalizedObservationCount;
  final int candidateCoPresenceObservationCount;
  final int confirmedInteractionPromotionCount;
  final int duplicateMergeCount;
  final int rejectedInteractionPromotionCount;
  final int crowdUpgradeCount;
  final int whatIngestionCount;
  final int localityVibeUpdateCount;
  final int personalDnaAuthorizedCount;
  final int personalDnaAppliedCount;
  final int latestNearbyPeerCount;
  final int latestConfirmedInteractivePeerCount;
  final String? latestSocialContext;
  final String? latestPlaceVibeLabel;
  final String? latestLocalityStableKey;
  final Map<String, int> sourceCounts;
  final AmbientSocialPromotionTrace? lastPromotionTrace;
  final List<AmbientSocialPromotionTrace> recentPromotionTraces;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'captured_at_utc': capturedAtUtc.toUtc().toIso8601String(),
        'normalized_observation_count': normalizedObservationCount,
        'candidate_copresence_observation_count':
            candidateCoPresenceObservationCount,
        'confirmed_interaction_promotion_count':
            confirmedInteractionPromotionCount,
        'duplicate_merge_count': duplicateMergeCount,
        'rejected_interaction_promotion_count':
            rejectedInteractionPromotionCount,
        'crowd_upgrade_count': crowdUpgradeCount,
        'what_ingestion_count': whatIngestionCount,
        'locality_vibe_update_count': localityVibeUpdateCount,
        'personal_dna_authorized_count': personalDnaAuthorizedCount,
        'personal_dna_applied_count': personalDnaAppliedCount,
        'latest_nearby_peer_count': latestNearbyPeerCount,
        'latest_confirmed_interactive_peer_count':
            latestConfirmedInteractivePeerCount,
        if (latestSocialContext != null)
          'latest_social_context': latestSocialContext,
        if (latestPlaceVibeLabel != null)
          'latest_place_vibe_label': latestPlaceVibeLabel,
        if (latestLocalityStableKey != null)
          'latest_locality_stable_key': latestLocalityStableKey,
        'source_counts': sourceCounts,
        if (lastPromotionTrace != null)
          'last_promotion_trace': lastPromotionTrace!.toJson(),
        'recent_promotion_traces':
            recentPromotionTraces.map((entry) => entry.toJson()).toList(),
      };
}

class AmbientSocialPromotionTrace {
  const AmbientSocialPromotionTrace({
    required this.localityStableKey,
    required this.sourceKinds,
    required this.discoveredPeerIds,
    required this.confirmedInteractivePeerIds,
    required this.socialContext,
    required this.placeVibeLabel,
    required this.lineageRefs,
    required this.promotedAtUtc,
  });

  final String localityStableKey;
  final List<String> sourceKinds;
  final List<String> discoveredPeerIds;
  final List<String> confirmedInteractivePeerIds;
  final String socialContext;
  final String placeVibeLabel;
  final List<String> lineageRefs;
  final DateTime promotedAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'locality_stable_key': localityStableKey,
        'source_kinds': sourceKinds,
        'discovered_peer_ids': discoveredPeerIds,
        'confirmed_interactive_peer_ids': confirmedInteractivePeerIds,
        'social_context': socialContext,
        'place_vibe_label': placeVibeLabel,
        'lineage_refs': lineageRefs,
        'promoted_at_utc': promotedAtUtc.toUtc().toIso8601String(),
      };
}

class AmbientSocialRealityLearningService {
  AmbientSocialRealityLearningService({
    WhatRuntimeIngestionService? whatIngestion,
    HierarchicalLocalityVibeProjector? hierarchicalLocalityProjector,
    GovernanceKernelService? governanceKernelService,
    VibeKernel? vibeKernel,
    DateTime Function()? nowUtc,
  })  : _whatIngestion = whatIngestion,
        _hierarchicalLocalityProjector = hierarchicalLocalityProjector ??
            HierarchicalLocalityVibeProjector(),
        _governanceKernelService =
            governanceKernelService ?? GovernanceKernelService(),
        _vibeKernel = vibeKernel ?? VibeKernel(),
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const Duration _mergeWindow = Duration(minutes: 45);

  final WhatRuntimeIngestionService? _whatIngestion;
  final HierarchicalLocalityVibeProjector _hierarchicalLocalityProjector;
  final GovernanceKernelService _governanceKernelService;
  final VibeKernel _vibeKernel;
  final DateTime Function() _nowUtc;
  final Map<String, _AmbientSocialWindowState> _windowByLocality =
      <String, _AmbientSocialWindowState>{};

  int _normalizedObservationCount = 0;
  int _candidateCoPresenceObservationCount = 0;
  int _confirmedInteractionPromotionCount = 0;
  int _duplicateMergeCount = 0;
  int _rejectedInteractionPromotionCount = 0;
  int _crowdUpgradeCount = 0;
  int _whatIngestionCount = 0;
  int _localityVibeUpdateCount = 0;
  int _personalDnaAuthorizedCount = 0;
  int _personalDnaAppliedCount = 0;
  int _latestNearbyPeerCount = 0;
  int _latestConfirmedInteractivePeerCount = 0;
  String? _latestSocialContext;
  String? _latestPlaceVibeLabel;
  String? _latestLocalityStableKey;
  final Map<String, int> _sourceCounts = <String, int>{};
  final List<AmbientSocialPromotionTrace> _recentPromotionTraces =
      <AmbientSocialPromotionTrace>[];

  Future<void> applyObservation({
    required AmbientSocialLearningObservation observation,
    String? personalAgentId,
  }) async {
    _pruneStaleWindows(observation.observedAtUtc.toUtc());
    final localityStableKey = observation.localityBinding.stableKey.trim();
    if (localityStableKey.isEmpty) {
      return;
    }

    _normalizedObservationCount += 1;
    _sourceCounts[observation.source.wireName] =
        (_sourceCounts[observation.source.wireName] ?? 0) + 1;
    if (observation.discoveredPeerIds.isNotEmpty) {
      _candidateCoPresenceObservationCount += 1;
    }

    if (_shouldRejectInteractionPromotion(observation)) {
      _rejectedInteractionPromotionCount += 1;
      return;
    }

    final window = _windowByLocality.putIfAbsent(
      localityStableKey,
      () => _AmbientSocialWindowState(
        localityBinding: observation.localityBinding,
        startedAtUtc: observation.observedAtUtc.toUtc(),
      ),
    );
    final beforeNearbyCount = window.discoveredPeerIds.length;
    final beforeConfirmedCount = window.confirmedInteractivePeerIds.length;
    final beforeSourceCount = window.sourceKinds.length;
    final beforeLineageCount = window.lineageRefs.length;

    window.merge(observation);

    final nearbyPeerCount = window.discoveredPeerIds.length;
    final confirmedInteractivePeerCount =
        window.confirmedInteractivePeerIds.length;
    final duplicateMerge = nearbyPeerCount == beforeNearbyCount &&
        confirmedInteractivePeerCount == beforeConfirmedCount &&
        window.sourceKinds.length == beforeSourceCount &&
        window.lineageRefs.length == beforeLineageCount;
    if (duplicateMerge) {
      _duplicateMergeCount += 1;
      _latestNearbyPeerCount = nearbyPeerCount;
      _latestConfirmedInteractivePeerCount = confirmedInteractivePeerCount;
      _latestLocalityStableKey = localityStableKey;
      return;
    }
    if (observation.source ==
            AmbientSocialLearningObservationSource.ai2aiCompletedInteraction &&
        confirmedInteractivePeerCount > beforeConfirmedCount) {
      _confirmedInteractionPromotionCount +=
          confirmedInteractivePeerCount - beforeConfirmedCount;
    }
    if (observation.source ==
            AmbientSocialLearningObservationSource.ai2aiCompletedInteraction &&
        nearbyPeerCount > 1 &&
        (nearbyPeerCount > beforeNearbyCount ||
            confirmedInteractivePeerCount > beforeConfirmedCount)) {
      _crowdUpgradeCount += 1;
    }

    final socialContext = _socialContextForEncounterCount(
      encounteredCount: nearbyPeerCount,
      confirmedInteractiveCount: confirmedInteractivePeerCount,
    );
    final placeVibeLabel = _placeVibeLabelForEncounterCount(
      encounteredCount: nearbyPeerCount,
      confirmedInteractiveCount: confirmedInteractivePeerCount,
    );
    final crowdRecognitionScore = _crowdRecognitionScoreForEncounterCount(
      encounteredCount: nearbyPeerCount,
      confirmedInteractiveCount: confirmedInteractivePeerCount,
      interactionQuality: observation.interactionQuality ?? 0.0,
      confidence: observation.confidence,
    );
    final socialIntensity =
        (crowdRecognitionScore * 0.72 +
                (confirmedInteractivePeerCount > 0 ? 0.20 : 0.0) +
                (observation.confidence.clamp(0.0, 1.0) * 0.08))
            .clamp(0.0, 1.0);
    final localityDimensions = <String, double>{
      'community_orientation': _lerp(0.28, 0.88, socialIntensity),
      'social_discovery_style': _lerp(0.26, 0.84, socialIntensity),
      'trust_network_reliance': _lerp(0.34, 0.78, socialIntensity),
      'energy_preference': _lerp(0.32, 0.86, socialIntensity),
      'crowd_tolerance': _lerp(0.18, 0.93, socialIntensity),
      'novelty_seeking': _lerp(0.40, 0.76, socialIntensity),
    };
    final personalDimensions = nearbyPeerCount == 0
        ? const <String, double>{}
        : <String, double>{
            for (final entry in localityDimensions.entries)
              entry.key: (0.5 + ((entry.value - 0.5) * 0.34)).clamp(0.0, 1.0),
          };
    final provenanceTags = <String>[
      'ambient_social_runtime',
      'source:${observation.source.wireName}',
      'social:$socialContext',
      'place_vibe:$placeVibeLabel',
      'locality:$localityStableKey',
    ];

    final semanticTuples = <SemanticTuple>[
      ...observation.semanticTuples,
      SemanticTuple(
        id:
            'ambient-social-density:$localityStableKey:${window.startedAtUtc.microsecondsSinceEpoch}',
        category: 'social_context',
        subject: 'ambient_social_scene',
        predicate: 'recognized_social_density',
        object: socialContext,
        confidence: (0.56 + crowdRecognitionScore * 0.30).clamp(0.0, 0.97),
        extractedAt: observation.observedAtUtc.toUtc(),
      ),
      SemanticTuple(
        id:
            'ambient-place-vibe:$localityStableKey:${window.startedAtUtc.microsecondsSinceEpoch}',
        category: 'place_vibe',
        subject: 'locality',
        predicate: 'expresses_place_vibe',
        object: placeVibeLabel,
        confidence: (0.58 + socialIntensity * 0.28).clamp(0.0, 0.97),
        extractedAt: observation.observedAtUtc.toUtc(),
      ),
      if (nearbyPeerCount > 0)
        SemanticTuple(
          id:
              'ambient-copresence:$localityStableKey:${window.startedAtUtc.microsecondsSinceEpoch}',
          category: 'mesh_presence',
          subject: 'ambient_social_scene',
          predicate: 'recognized_co_presence',
          object: nearbyPeerCount > 1 ? 'multi_agent_presence' : 'single_peer',
          confidence: (0.60 + crowdRecognitionScore * 0.30).clamp(0.0, 0.97),
          extractedAt: observation.observedAtUtc.toUtc(),
        ),
      if (confirmedInteractivePeerCount > 0)
        SemanticTuple(
          id:
              'ambient-confirmed-interaction:$localityStableKey:${window.startedAtUtc.microsecondsSinceEpoch}',
          category: 'ai2ai_presence',
          subject: 'ai2ai_runtime',
          predicate: 'confirmed_interactive_presence',
          object: confirmedInteractivePeerCount > 1
              ? 'multi_peer_interaction'
              : 'single_peer_interaction',
          confidence:
              (0.68 + (observation.interactionQuality ?? 0.0) * 0.18)
                  .clamp(0.0, 0.98),
          extractedAt: observation.observedAtUtc.toUtc(),
        ),
    ];

    final structuredSignals = <String, dynamic>{
      ...observation.structuredSignals,
      'discoveredPeerCount': nearbyPeerCount,
      'confirmedInteractivePeerCount': confirmedInteractivePeerCount,
      'coPresenceDetected': nearbyPeerCount > 0,
      'multiAgentDetected': nearbyPeerCount > 1,
      'interactivePresenceConfirmed': confirmedInteractivePeerCount > 0,
      'socialDensityClass': socialContext,
      'placeVibeLabel': placeVibeLabel,
      'crowdRecognitionScore': crowdRecognitionScore,
      'localityStableKey': localityStableKey,
      'sourceKinds': window.sourceKinds.toList(growable: false),
      'autonomousCrowdRecognition': nearbyPeerCount > 1,
    };

    final resolvedAgentId = (personalAgentId != null &&
            personalAgentId.trim().isNotEmpty)
        ? personalAgentId.trim()
        : await _whatIngestion?.currentAgentId();
    if (_whatIngestion != null) {
      final receipt = await _whatIngestion.ingestAmbientSocialObservation(
        entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
          'ambient_social_scene',
          <String, Object?>{
            'locality': localityStableKey,
          },
        ),
        observedAtUtc: observation.observedAtUtc,
        agentId: resolvedAgentId,
        semanticTuples: semanticTuples,
        structuredSignals: structuredSignals,
        locationContext: <String, dynamic>{
          ...observation.locationContext,
          'localityStableKey': localityStableKey,
        },
        temporalContext: <String, dynamic>{
          ...observation.temporalContext,
          'windowStartedAtUtc': window.startedAtUtc.toUtc().toIso8601String(),
          'windowUpdatedAtUtc': window.lastObservedAtUtc.toUtc().toIso8601String(),
        },
        socialContext: socialContext,
        activityContext: observation.activityContext ?? 'ambient_socializing',
        confidence: (0.58 + crowdRecognitionScore * 0.24).clamp(0.0, 0.97),
        lineageRef: observation.lineageRef,
      );
      if (receipt != null) {
        _whatIngestionCount += 1;
      }
    }

    final localityReceipts = _hierarchicalLocalityProjector.projectObservation(
      binding: observation.localityBinding,
      dimensions: localityDimensions,
      source: 'ambient_social_place_vibe',
      provenanceTags: provenanceTags,
    );
    if (localityReceipts.isNotEmpty) {
      _localityVibeUpdateCount += 1;
    }

    if (resolvedAgentId != null &&
        resolvedAgentId.isNotEmpty &&
        personalDimensions.isNotEmpty) {
      _personalDnaAuthorizedCount += 1;
      final mutationDecision = _governanceKernelService.authorizeVibeMutation(
        subjectId: resolvedAgentId,
        governanceScope: 'personal',
        evidence: _buildPersonalEvidence(
          localityStableKey: localityStableKey,
          crowdRecognitionScore: crowdRecognitionScore,
          personalDimensions: personalDimensions,
          provenanceTags: provenanceTags,
        ),
      );
      if (mutationDecision.stateWriteAllowed) {
        _vibeKernel.ingestEcosystemObservation(
          subjectId: resolvedAgentId,
          source: 'ambient_social_place_vibe',
          dimensions: personalDimensions,
          provenanceTags: <String>[
            ...provenanceTags,
            'personal_feedback_loop',
          ],
        );
        _personalDnaAppliedCount += 1;
      }
    }

    _latestNearbyPeerCount = nearbyPeerCount;
    _latestConfirmedInteractivePeerCount = confirmedInteractivePeerCount;
    _latestSocialContext = socialContext;
    _latestPlaceVibeLabel = placeVibeLabel;
    _latestLocalityStableKey = localityStableKey;
    if (confirmedInteractivePeerCount > beforeConfirmedCount) {
      _recordPromotionTrace(
        AmbientSocialPromotionTrace(
          localityStableKey: localityStableKey,
          sourceKinds: window.sourceKinds.toList(growable: false),
          discoveredPeerIds: window.discoveredPeerIds.toList(growable: false),
          confirmedInteractivePeerIds:
              window.confirmedInteractivePeerIds.toList(growable: false),
          socialContext: socialContext,
          placeVibeLabel: placeVibeLabel,
          lineageRefs: window.lineageRefs.toList(growable: false),
          promotedAtUtc: observation.observedAtUtc.toUtc(),
        ),
      );
    }
  }

  AmbientSocialLearningDiagnosticsSnapshot snapshot({
    DateTime? capturedAtUtc,
  }) {
    return AmbientSocialLearningDiagnosticsSnapshot(
      capturedAtUtc: capturedAtUtc?.toUtc() ?? _nowUtc(),
      normalizedObservationCount: _normalizedObservationCount,
      candidateCoPresenceObservationCount:
          _candidateCoPresenceObservationCount,
      confirmedInteractionPromotionCount:
          _confirmedInteractionPromotionCount,
      duplicateMergeCount: _duplicateMergeCount,
      rejectedInteractionPromotionCount:
          _rejectedInteractionPromotionCount,
      crowdUpgradeCount: _crowdUpgradeCount,
      whatIngestionCount: _whatIngestionCount,
      localityVibeUpdateCount: _localityVibeUpdateCount,
      personalDnaAuthorizedCount: _personalDnaAuthorizedCount,
      personalDnaAppliedCount: _personalDnaAppliedCount,
      latestNearbyPeerCount: _latestNearbyPeerCount,
      latestConfirmedInteractivePeerCount:
          _latestConfirmedInteractivePeerCount,
      latestSocialContext: _latestSocialContext,
      latestPlaceVibeLabel: _latestPlaceVibeLabel,
      latestLocalityStableKey: _latestLocalityStableKey,
      sourceCounts: Map<String, int>.unmodifiable(_sourceCounts),
      lastPromotionTrace:
          _recentPromotionTraces.isEmpty ? null : _recentPromotionTraces.first,
      recentPromotionTraces:
          List<AmbientSocialPromotionTrace>.unmodifiable(_recentPromotionTraces),
    );
  }

  bool _shouldRejectInteractionPromotion(
    AmbientSocialLearningObservation observation,
  ) {
    if (observation.source !=
        AmbientSocialLearningObservationSource.ai2aiCompletedInteraction) {
      return false;
    }
    if (observation.structuredSignals['interactionTrusted'] == false ||
        observation.structuredSignals['promotionEligible'] == false) {
      return true;
    }
    return observation.confirmedInteractivePeerIds.isEmpty;
  }

  void _recordPromotionTrace(AmbientSocialPromotionTrace trace) {
    _recentPromotionTraces.insert(0, trace);
    if (_recentPromotionTraces.length > 5) {
      _recentPromotionTraces.removeRange(5, _recentPromotionTraces.length);
    }
  }

  void _pruneStaleWindows(DateTime nowUtc) {
    final staleKeys = _windowByLocality.entries
        .where(
          (entry) => nowUtc.difference(entry.value.lastObservedAtUtc) >
              _mergeWindow,
        )
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in staleKeys) {
      _windowByLocality.remove(key);
    }
  }

  VibeEvidence _buildPersonalEvidence({
    required String localityStableKey,
    required double crowdRecognitionScore,
    required Map<String, double> personalDimensions,
    required List<String> provenanceTags,
  }) {
    final confidence =
        (0.48 + crowdRecognitionScore * 0.30).clamp(0.0, 0.92);
    return VibeEvidence(
      summary:
          'Governed ambient-social observation for $localityStableKey.',
      identitySignals: const <VibeSignal>[],
      pheromoneSignals: const <VibeSignal>[],
      behaviorSignals: personalDimensions.entries
          .map(
            (entry) => VibeSignal(
              key: entry.key,
              kind: VibeSignalKind.behavior,
              value: entry.value,
              confidence: confidence,
              provenance: provenanceTags,
            ),
          )
          .toList(growable: false),
      affectiveSignals: const <VibeSignal>[],
      styleSignals: const <VibeSignal>[],
    );
  }
}

class _AmbientSocialWindowState {
  _AmbientSocialWindowState({
    required this.localityBinding,
    required this.startedAtUtc,
  }) : lastObservedAtUtc = startedAtUtc;

  final GeographicVibeBinding localityBinding;
  final DateTime startedAtUtc;
  DateTime lastObservedAtUtc;
  final Set<String> discoveredPeerIds = <String>{};
  final Set<String> confirmedInteractivePeerIds = <String>{};
  final Set<String> sourceKinds = <String>{};
  final Set<String> lineageRefs = <String>{};

  void merge(AmbientSocialLearningObservation observation) {
    lastObservedAtUtc = observation.observedAtUtc.toUtc();
    discoveredPeerIds.addAll(
      observation.discoveredPeerIds
          .where((entry) => entry.trim().isNotEmpty)
          .map((entry) => entry.trim()),
    );
    confirmedInteractivePeerIds.addAll(
      observation.confirmedInteractivePeerIds
          .where((entry) => entry.trim().isNotEmpty)
          .map((entry) => entry.trim()),
    );
    sourceKinds.add(observation.source.wireName);
    final lineageRef = observation.lineageRef?.trim();
    if (lineageRef != null && lineageRef.isNotEmpty) {
      lineageRefs.add(lineageRef);
    }
  }
}

class PassiveDwellRealityLearningService {
  PassiveDwellRealityLearningService({
    AmbientSocialRealityLearningService? ambientSocialLearningService,
    HierarchicalLocalityVibeProjector? hierarchicalLocalityProjector,
    GovernanceKernelService? governanceKernelService,
    VibeKernel? vibeKernel,
  })  : _ambientSocialLearningService = ambientSocialLearningService,
        _hierarchicalLocalityProjector = hierarchicalLocalityProjector ??
            HierarchicalLocalityVibeProjector(),
        _governanceKernelService =
            governanceKernelService ?? GovernanceKernelService(),
        _vibeKernel = vibeKernel ?? VibeKernel();

  final AmbientSocialRealityLearningService? _ambientSocialLearningService;

  final HierarchicalLocalityVibeProjector _hierarchicalLocalityProjector;
  final GovernanceKernelService _governanceKernelService;
  final VibeKernel _vibeKernel;

  Future<void> applyProjection({
    required DwellEvent event,
    required PassiveDwellLearningProjection projection,
    String? personalAgentId,
  }) async {
    final ambientSocialLearningService = _ambientSocialLearningService;
    if (ambientSocialLearningService != null) {
      await ambientSocialLearningService.applyObservation(
        observation: AmbientSocialLearningObservation.fromPassiveDwell(
          event: event,
          projection: projection,
        ),
        personalAgentId: personalAgentId,
      );
      return;
    }

    final provenanceTags = <String>[
      'passive_dwell_runtime',
      'place_vibe:${projection.placeVibeLabel}',
      'social:${projection.socialContext}',
      'locality:${projection.localityStableKey}',
    ];

    _hierarchicalLocalityProjector.projectObservation(
      binding: projection.localityBinding,
      dimensions: projection.localityDimensions,
      source: 'passive_dwell_place_vibe',
      provenanceTags: provenanceTags,
    );

    final agentId = personalAgentId?.trim();
    if (agentId == null || agentId.isEmpty || !projection.hasPersonalLearning) {
      return;
    }

    final mutationDecision = _governanceKernelService.authorizeVibeMutation(
      subjectId: agentId,
      governanceScope: 'personal',
      evidence: _buildPersonalEvidence(
        event: event,
        projection: projection,
        provenanceTags: provenanceTags,
      ),
    );
    if (!mutationDecision.stateWriteAllowed) {
      return;
    }
    _vibeKernel.ingestEcosystemObservation(
      subjectId: agentId,
      source: 'passive_dwell_place_vibe',
      dimensions: projection.personalDimensions,
      provenanceTags: <String>[
        ...provenanceTags,
        'personal_feedback_loop',
      ],
    );
  }

  VibeEvidence _buildPersonalEvidence({
    required DwellEvent event,
    required PassiveDwellLearningProjection projection,
    required List<String> provenanceTags,
  }) {
    final confidence =
        (0.46 + projection.crowdRecognitionScore * 0.32).clamp(0.0, 0.9);
    return VibeEvidence(
      summary:
          'Governed passive dwell crowd/place-vibe observation for ${projection.localityStableKey}.',
      identitySignals: const <VibeSignal>[],
      pheromoneSignals: const <VibeSignal>[],
      behaviorSignals: projection.personalDimensions.entries
          .map(
            (entry) => VibeSignal(
              key: entry.key,
              kind: VibeSignalKind.behavior,
              value: entry.value,
              confidence: confidence,
              provenance: <String>[
                ...provenanceTags,
                'duration:${event.endTime.difference(event.startTime).inMinutes}',
              ],
            ),
          )
          .toList(growable: false),
      affectiveSignals: const <VibeSignal>[],
      styleSignals: const <VibeSignal>[],
    );
  }
}
