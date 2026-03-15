import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';

class DartWhatFallbackKernel extends WhatKernelFallbackSurface {
  final Map<String, WhatState> _statesByEntity = <String, WhatState>{};
  final Map<String, WhatKernelSnapshot> _snapshotsByAgent =
      <String, WhatKernelSnapshot>{};

  @override
  Future<WhatState> resolveWhat(WhatPerceptionInput input) async {
    final classification = _classify(
      entityRef: input.entityRef,
      labels: input.candidateLabels,
      tuples: input.semanticTuples,
      activityHint: input.activityHint,
      socialHint: input.socialContextHint,
    );
    final state = WhatState(
      entityRef: input.entityRef,
      canonicalType: classification.canonicalType,
      subtypes: classification.subtypes,
      aliases: classification.aliases,
      placeType: classification.placeType,
      activityTypes: classification.activityTypes,
      socialContexts: classification.socialContexts,
      affordanceVector: _affordancesFor(
        classification.canonicalType,
        classification.activityTypes,
        classification.socialContexts,
      ),
      vibeSignature: _vibesFor(
        classification.canonicalType,
        classification.activityTypes,
        classification.socialContexts,
      ),
      confidence: 0.42,
      evidenceCount: 1,
      lifecycleState: WhatLifecycleState.candidate,
      firstObservedAtUtc: input.observedAtUtc,
      lastObservedAtUtc: input.observedAtUtc,
      sourceMix: WhatSourceMix(
        tuple: input.semanticTuples.isEmpty ? 0.0 : 0.65,
        structured: 0.25,
      ),
      lineageRefs: input.lineageRef == null ? const [] : [input.lineageRef!],
    );
    _saveSnapshot(input.agentId, state);
    return state;
  }

  @override
  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation) async {
    final classification = _classify(
      entityRef: observation.entityRef,
      labels: <String>[
        if (observation.activityContext != null) observation.activityContext!,
        if (observation.socialContext != null) observation.socialContext!,
      ],
      tuples: observation.semanticTuples,
      activityHint: observation.activityContext,
      socialHint: observation.socialContext,
    );
    final previous = _statesByEntity[observation.entityRef];
    final evidenceCount = (previous?.evidenceCount ?? 0) + 1;
    final trust = ((previous?.trust ?? 0.12) + 0.11).clamp(0.0, 1.0);
    final novelty = ((previous?.novelty ?? 0.86) - 0.09).clamp(0.05, 1.0);
    final saturation =
        ((previous?.saturation ?? 0.04) + (evidenceCount >= 8 ? 0.16 : 0.08))
            .clamp(0.0, 1.0);
    final lifecycle = evidenceCount >= 10 && novelty <= 0.22
        ? WhatLifecycleState.overexposed
        : evidenceCount >= 7 && trust >= 0.7
            ? WhatLifecycleState.trusted
            : evidenceCount >= 3
                ? WhatLifecycleState.established
                : WhatLifecycleState.candidate;
    final relation = observation.observationKind == WhatObservationKind.visit &&
            evidenceCount >= 4
        ? WhatUserRelation.prefers
        : observation.observationKind == WhatObservationKind.listInteraction
            ? WhatUserRelation.curiousAbout
            : previous?.userRelation ?? WhatUserRelation.neutral;
    final mergedActivities = _merge(
      previous?.activityTypes ?? const [],
      classification.activityTypes,
    );
    final mergedSocialContexts = _merge(
      previous?.socialContexts ?? const [],
      classification.socialContexts,
    );
    final canonicalType =
        classification.canonicalType == 'destination_venue' && previous != null
            ? previous.canonicalType
            : classification.canonicalType;
    final placeType =
        classification.placeType == 'destination_venue' && previous != null
            ? previous.placeType
            : classification.placeType;
    final state = WhatState(
      entityRef: observation.entityRef,
      canonicalType: canonicalType,
      subtypes: _merge(previous?.subtypes ?? const [], classification.subtypes),
      aliases: _merge(previous?.aliases ?? const [], classification.aliases),
      placeType: placeType,
      activityTypes: mergedActivities,
      socialContexts: mergedSocialContexts,
      affordanceVector: _affordancesFor(
        canonicalType,
        mergedActivities,
        mergedSocialContexts,
      ),
      vibeSignature: _vibesFor(
        canonicalType,
        mergedActivities,
        mergedSocialContexts,
      ),
      userRelation: relation,
      lifecycleState: lifecycle,
      novelty: novelty,
      familiarity: ((previous?.familiarity ?? 0.14) + 0.12).clamp(0.0, 1.0),
      trust: trust,
      saturation: saturation,
      confidence:
          ((previous?.confidence ?? 0.32) + observation.confidence + 0.10)
              .clamp(0.0, 0.96),
      evidenceCount: evidenceCount,
      firstObservedAtUtc:
          previous?.firstObservedAtUtc ?? observation.observedAtUtc,
      lastObservedAtUtc: observation.observedAtUtc,
      sourceMix: WhatSourceMix(
        tuple: observation.semanticTuples.isEmpty ? 0.0 : 0.65,
        structured:
            observation.observationKind == WhatObservationKind.ambientSocialEvent
                ? 0.9
                : 0.75,
        mesh: observation.observationKind ==
                WhatObservationKind.meshSemanticUpdate
            ? 0.8
            : 0.0,
        federated: observation.observationKind ==
                WhatObservationKind.pluginSemanticEvent
            ? 0.35
            : 0.0,
      ),
      lineageRefs: _merge(
        previous?.lineageRefs ?? const [],
        observation.lineageRef == null ? const [] : [observation.lineageRef!],
      ),
    );
    _saveSnapshot(observation.agentId, state);
    final projection = projectWhat(
      WhatProjectionRequest(
        agentId: observation.agentId,
        entityRef: observation.entityRef,
        state: state,
      ),
    );
    return WhatUpdateReceipt(
      state: state,
      projection: projection,
      cloudUpdated:
          observation.observationKind != WhatObservationKind.passiveDwell,
      meshForwarded:
          observation.observationKind == WhatObservationKind.meshSemanticUpdate,
    );
  }

  @override
  WhatProjection projectWhat(WhatProjectionRequest request) {
    final state = request.state ?? _statesByEntity[request.entityRef];
    if (state == null) {
      return const WhatProjection(baseEntityRef: 'unknown_entity');
    }
    final opportunities = <String>[
      if (state.canonicalType == 'cafe' &&
          state.activityTypes.contains('deep_work'))
        'solo work refuge',
      if (state.canonicalType == 'cafe') 'low-pressure meeting space',
      if (state.activityTypes.contains('date')) 'repeatable date ritual',
      if (state.socialContexts.contains('small_group') ||
          state.socialContexts.contains('social_cluster'))
        'group bonding anchor',
      if (state.socialContexts.contains('dyad'))
        'one-to-one connection pocket',
      if (state.socialContexts.contains('crowd'))
        'high-serendipity social field',
    ];
    return WhatProjection(
      baseEntityRef: state.entityRef,
      projectedTypes: [state.canonicalType],
      projectedAffordances: {
        ...state.affordanceVector,
        'ritual_repeatability':
            state.affordanceVector['ritual_repeatability'] ?? 0.67,
      },
      projectedVibeSignature: state.vibeSignature,
      adjacentOpportunities: opportunities.isEmpty
          ? ['adjacent exploration opportunity']
          : opportunities,
      confidence: (state.confidence + state.trust) / 2,
      basis:
          '${state.canonicalType}:${state.lifecycleState.name}:${_relationName(state.userRelation)}',
    );
  }

  @override
  WhatKernelSnapshot? snapshotWhat(String agentId) =>
      _snapshotsByAgent[agentId];

  @override
  Future<WhatSyncResult> syncWhat(WhatSyncRequest request) async {
    final merged = <String>[];
    var accepted = 0;
    var rejected = 0;
    for (final delta in request.deltas) {
      final current = _statesByEntity[delta.entityRef];
      final accept = current == null ||
          delta.confidence > current.confidence ||
          delta.lastObservedAtUtc.isAfter(current.lastObservedAtUtc);
      merged.add(delta.entityRef);
      if (accept) {
        accepted += 1;
        _saveSnapshot(request.agentId, delta);
      } else {
        rejected += 1;
      }
    }
    return WhatSyncResult(
      acceptedCount: accepted,
      rejectedCount: rejected,
      mergedEntityRefs: merged,
      savedAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<WhatRecoveryResult> recoverWhat(WhatRecoveryRequest request) async {
    final envelope = request.persistedEnvelope;
    if (envelope != null && envelope['snapshots'] is Map) {
      final snapshots = Map<String, dynamic>.from(envelope['snapshots'] as Map);
      for (final entry in snapshots.entries) {
        final snapshot = WhatKernelSnapshot.fromJson(
            Map<String, dynamic>.from(entry.value as Map));
        _snapshotsByAgent[entry.key] = snapshot;
        for (final state in snapshot.states) {
          _statesByEntity[state.entityRef] = state;
        }
      }
    }
    return WhatRecoveryResult(
      restoredCount: _statesByEntity.length,
      droppedCount: 0,
      schemaVersion: 1,
      savedAtUtc: DateTime.now().toUtc(),
    );
  }

  void _saveSnapshot(String agentId, WhatState state) {
    _statesByEntity[state.entityRef] = state;
    final previous = _snapshotsByAgent[agentId];
    final states = <WhatState>[
      ...(previous?.states ?? const <WhatState>[]).where(
        (entry) => entry.entityRef != state.entityRef,
      ),
      state,
    ];
    _snapshotsByAgent[agentId] = WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.now().toUtc(),
      states: states,
      schemaVersion: 1,
    );
  }
}

class _Classification {
  final String canonicalType;
  final String placeType;
  final List<String> subtypes;
  final List<String> aliases;
  final List<String> activityTypes;
  final List<String> socialContexts;

  const _Classification({
    required this.canonicalType,
    required this.placeType,
    required this.subtypes,
    required this.aliases,
    required this.activityTypes,
    required this.socialContexts,
  });
}

_Classification _classify({
  required String entityRef,
  required List<String> labels,
  required List<WhatSemanticTuple> tuples,
  String? activityHint,
  String? socialHint,
}) {
  final normalized = <String>[
    ...labels.map((entry) => entry.toLowerCase()),
    ...tuples.map((entry) => entry.object.toLowerCase()),
    ...tuples.map((entry) => entry.predicate.toLowerCase()),
    if (activityHint != null) activityHint.toLowerCase(),
    if (socialHint != null) socialHint.toLowerCase(),
  ];
  var canonicalType = 'destination_venue';
  var placeType = 'destination_venue';
  final subtypes = <String>[];
  final activityTypes = <String>[];
  final socialContexts = <String>[];
  final aliases = <String>[entityRef];

  for (final label in normalized) {
    switch (label) {
      case 'coffee shop':
      case 'cafe':
      case 'location_category_cafe':
        canonicalType = 'cafe';
        placeType = 'cafe';
        aliases.add('coffee shop');
        _push(activityTypes, 'deep_work');
        _push(activityTypes, 'casual_socializing');
        break;
      case 'study spot':
      case 'workspace':
      case 'coworking':
        canonicalType = 'workspace';
        placeType = 'workspace';
        _push(activityTypes, 'deep_work');
        _push(subtypes, 'study_spot');
        break;
      case 'date spot':
        canonicalType = 'third_place';
        placeType = 'third_place';
        _push(activityTypes, 'date');
        break;
      case 'hangout':
        _push(activityTypes, 'casual_socializing');
        break;
      case 'gallery':
        canonicalType = 'gallery';
        placeType = 'gallery';
        _push(activityTypes, 'learning');
        _push(activityTypes, 'exploration');
        break;
      case 'bar':
        canonicalType = 'bar';
        placeType = 'bar';
        _push(activityTypes, 'casual_socializing');
        break;
      case 'park':
        canonicalType = 'park';
        placeType = 'park';
        _push(activityTypes, 'recovery');
        _push(activityTypes, 'movement');
        break;
      case 'music_venue':
      case 'music venue':
        canonicalType = 'music_venue';
        placeType = 'music_venue';
        _push(activityTypes, 'celebration');
        break;
      case 'solo':
        _push(socialContexts, 'solo');
        break;
      case 'dyad':
        _push(socialContexts, 'dyad');
        break;
      case 'small_group':
        _push(socialContexts, 'small_group');
        break;
      case 'social_cluster':
        _push(socialContexts, 'social_cluster');
        break;
      case 'crowd':
        _push(socialContexts, 'crowd');
        break;
      case 'ambient_socializing':
        _push(activityTypes, 'casual_socializing');
        _push(activityTypes, 'ambient_socializing');
        break;
      case 'lingering':
      case 'dwelled_at':
        _push(activityTypes, 'lingering');
        break;
      case 'meeting':
        _push(activityTypes, 'meeting');
        break;
      default:
        break;
    }
  }
  if (activityTypes.isEmpty) {
    _push(activityTypes, 'exploration');
  }
  if (socialContexts.isEmpty) {
    _push(socialContexts, 'ambient_social');
  }
  return _Classification(
    canonicalType: canonicalType,
    placeType: placeType,
    subtypes: subtypes,
    aliases: aliases,
    activityTypes: activityTypes,
    socialContexts: socialContexts,
  );
}

Map<String, double> _affordancesFor(
  String canonicalType,
  List<String> activities,
  List<String> socialContexts,
) {
  final values = <String, double>{};
  switch (canonicalType) {
    case 'cafe':
      values['focus'] = 0.71;
      values['conversation'] = 0.74;
      values['low_friction_stop'] = 0.79;
      values['ritual_repeatability'] = 0.76;
      break;
    case 'workspace':
      values['focus'] = 0.93;
      values['learning'] = 0.58;
      values['ritual_repeatability'] = 0.70;
      break;
    case 'park':
      values['recovery'] = 0.83;
      values['quiet_presence'] = 0.72;
      break;
    default:
      values['novelty'] = 0.40;
  }
  if (activities.contains('date')) {
    values['romance'] = 0.91;
  }
  if (activities.contains('learning')) {
    values['learning'] = 0.88;
  }
  if (socialContexts.contains('dyad')) {
    values['intimate_conversation'] = 0.82;
  }
  if (socialContexts.contains('small_group') ||
      socialContexts.contains('social_cluster')) {
    values['serendipity'] = 0.79;
    values['group_bonding'] = 0.76;
  }
  if (socialContexts.contains('crowd')) {
    values['social_energy'] = 0.86;
  }
  return values;
}

Map<String, double> _vibesFor(
  String canonicalType,
  List<String> activities,
  List<String> socialContexts,
) {
  return <String, double>{
    'calm': canonicalType == 'cafe' ? 0.68 : 0.50,
    'lively': socialContexts.contains('crowd')
        ? 0.88
        : canonicalType == 'bar'
            ? 0.84
            : 0.50,
    'intimate': activities.contains('date') || socialContexts.contains('dyad')
        ? 0.84
        : 0.35,
    'cerebral': activities.contains('deep_work') ? 0.88 : 0.50,
    'chaotic': socialContexts.contains('crowd')
        ? 0.71
        : canonicalType == 'music_venue'
            ? 0.63
            : 0.20,
    'warm': activities.contains('date') ? 0.82 : 0.50,
    'cool': 0.50,
    'grounded': canonicalType == 'park' ? 0.83 : 0.50,
    'aspirational': canonicalType == 'gallery' ? 0.75 : 0.50,
    'playful': canonicalType == 'bar' ? 0.72 : 0.50,
  };
}

List<String> _merge(List<String> left, List<String> right) {
  final merged = <String>[...left];
  for (final value in right) {
    _push(merged, value);
  }
  return merged;
}

void _push(List<String> values, String value) {
  if (!values.contains(value)) {
    values.add(value);
  }
}

String _relationName(WhatUserRelation relation) {
  switch (relation) {
    case WhatUserRelation.curiousAbout:
      return 'curious_about';
    case WhatUserRelation.contextualLike:
      return 'contextual_like';
    case WhatUserRelation.usedToLike:
      return 'used_to_like';
    default:
      return relation.name;
  }
}
