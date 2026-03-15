import 'package:equatable/equatable.dart';

enum WhatObservationKind {
  tupleIntake,
  visit,
  eventAttendance,
  listInteraction,
  passiveDwell,
  ambientSocialEvent,
  pluginSemanticEvent,
  meshSemanticUpdate,
}

enum WhatLifecycleState {
  unknown,
  candidate,
  established,
  trusted,
  overexposed,
  retired,
  rediscovered,
}

enum WhatUserRelation {
  neutral,
  prefers,
  avoids,
  curiousAbout,
  contextualLike,
  usedToLike,
  aspirational,
}

class WhatSourceMix extends Equatable {
  final double tuple;
  final double structured;
  final double mesh;
  final double federated;

  const WhatSourceMix({
    this.tuple = 0.0,
    this.structured = 0.0,
    this.mesh = 0.0,
    this.federated = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'tuple': tuple,
        'structured': structured,
        'mesh': mesh,
        'federated': federated,
      };

  factory WhatSourceMix.fromJson(Map<String, dynamic> json) {
    return WhatSourceMix(
      tuple: (json['tuple'] as num?)?.toDouble() ?? 0.0,
      structured: (json['structured'] as num?)?.toDouble() ?? 0.0,
      mesh: (json['mesh'] as num?)?.toDouble() ?? 0.0,
      federated: (json['federated'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [tuple, structured, mesh, federated];
}

class WhatSemanticTuple extends Equatable {
  final String category;
  final String subject;
  final String predicate;
  final String object;
  final double confidence;
  final DateTime extractedAt;

  const WhatSemanticTuple({
    required this.category,
    required this.subject,
    required this.predicate,
    required this.object,
    required this.confidence,
    required this.extractedAt,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'subject': subject,
        'predicate': predicate,
        'object': object,
        'confidence': confidence,
        'extractedAt': extractedAt.toIso8601String(),
      };

  factory WhatSemanticTuple.fromJson(Map<String, dynamic> json) {
    return WhatSemanticTuple(
      category: (json['category'] as String?) ?? 'unknown',
      subject: (json['subject'] as String?) ?? 'unknown',
      predicate: (json['predicate'] as String?) ?? 'unknown',
      object: (json['object'] as String?) ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      extractedAt: DateTime.tryParse((json['extractedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props =>
      [category, subject, predicate, object, confidence, extractedAt];
}

class WhatPerceptionInput extends Equatable {
  final String agentId;
  final DateTime observedAtUtc;
  final String source;
  final String entityRef;
  final List<String> candidateLabels;
  final List<WhatSemanticTuple> semanticTuples;
  final Map<String, dynamic>? locationContext;
  final Map<String, dynamic>? temporalContext;
  final String? socialContextHint;
  final String? activityHint;
  final Map<String, dynamic>? structuredMetadata;
  final String? lineageRef;

  const WhatPerceptionInput({
    required this.agentId,
    required this.observedAtUtc,
    required this.source,
    required this.entityRef,
    this.candidateLabels = const [],
    this.semanticTuples = const [],
    this.locationContext,
    this.temporalContext,
    this.socialContextHint,
    this.activityHint,
    this.structuredMetadata,
    this.lineageRef,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'observedAtUtc': observedAtUtc.toIso8601String(),
        'source': source,
        'entityRef': entityRef,
        'candidateLabels': candidateLabels,
        'semanticTuples':
            semanticTuples.map((entry) => entry.toJson()).toList(),
        if (locationContext != null) 'locationContext': locationContext,
        if (temporalContext != null) 'temporalContext': temporalContext,
        if (socialContextHint != null) 'socialContextHint': socialContextHint,
        if (activityHint != null) 'activityHint': activityHint,
        if (structuredMetadata != null)
          'structuredMetadata': structuredMetadata,
        if (lineageRef != null) 'lineageRef': lineageRef,
      };

  factory WhatPerceptionInput.fromJson(Map<String, dynamic> json) {
    return WhatPerceptionInput(
      agentId: (json['agentId'] as String?) ?? '',
      observedAtUtc:
          DateTime.tryParse((json['observedAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: (json['source'] as String?) ?? 'unknown',
      entityRef: (json['entityRef'] as String?) ?? 'unknown_entity',
      candidateLabels: (json['candidateLabels'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      semanticTuples: (json['semanticTuples'] as List?)
              ?.map(
                (entry) => WhatSemanticTuple.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      locationContext: json['locationContext'] == null
          ? null
          : Map<String, dynamic>.from(json['locationContext'] as Map),
      temporalContext: json['temporalContext'] == null
          ? null
          : Map<String, dynamic>.from(json['temporalContext'] as Map),
      socialContextHint: json['socialContextHint'] as String?,
      activityHint: json['activityHint'] as String?,
      structuredMetadata: json['structuredMetadata'] == null
          ? null
          : Map<String, dynamic>.from(json['structuredMetadata'] as Map),
      lineageRef: json['lineageRef'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        observedAtUtc,
        source,
        entityRef,
        candidateLabels,
        semanticTuples,
        locationContext,
        temporalContext,
        socialContextHint,
        activityHint,
        structuredMetadata,
        lineageRef,
      ];
}

class WhatObservation extends Equatable {
  final String agentId;
  final DateTime observedAtUtc;
  final String source;
  final String entityRef;
  final WhatObservationKind observationKind;
  final List<WhatSemanticTuple> semanticTuples;
  final Map<String, dynamic>? structuredSignals;
  final Map<String, dynamic>? locationContext;
  final Map<String, dynamic>? temporalContext;
  final String? socialContext;
  final String? activityContext;
  final double confidence;
  final String? lineageRef;

  const WhatObservation({
    required this.agentId,
    required this.observedAtUtc,
    required this.source,
    required this.entityRef,
    required this.observationKind,
    this.semanticTuples = const [],
    this.structuredSignals,
    this.locationContext,
    this.temporalContext,
    this.socialContext,
    this.activityContext,
    this.confidence = 0.42,
    this.lineageRef,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'observedAtUtc': observedAtUtc.toIso8601String(),
        'source': source,
        'entityRef': entityRef,
        'observationKind': _observationKindName(observationKind),
        'semanticTuples':
            semanticTuples.map((entry) => entry.toJson()).toList(),
        if (structuredSignals != null) 'structuredSignals': structuredSignals,
        if (locationContext != null) 'locationContext': locationContext,
        if (temporalContext != null) 'temporalContext': temporalContext,
        if (socialContext != null) 'socialContextHint': socialContext,
        if (activityContext != null) 'activityHint': activityContext,
        'confidence': confidence,
        if (lineageRef != null) 'lineageRef': lineageRef,
      };

  factory WhatObservation.fromJson(Map<String, dynamic> json) {
    return WhatObservation(
      agentId: (json['agentId'] as String?) ?? '',
      observedAtUtc:
          DateTime.tryParse((json['observedAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: (json['source'] as String?) ?? 'unknown',
      entityRef: (json['entityRef'] as String?) ?? 'unknown_entity',
      observationKind:
          _parseObservationKind((json['observationKind'] as String?) ?? ''),
      semanticTuples: (json['semanticTuples'] as List?)
              ?.map(
                (entry) => WhatSemanticTuple.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      structuredSignals: json['structuredSignals'] == null
          ? null
          : Map<String, dynamic>.from(json['structuredSignals'] as Map),
      locationContext: json['locationContext'] == null
          ? null
          : Map<String, dynamic>.from(json['locationContext'] as Map),
      temporalContext: json['temporalContext'] == null
          ? null
          : Map<String, dynamic>.from(json['temporalContext'] as Map),
      socialContext: json['socialContextHint'] as String?,
      activityContext: json['activityHint'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.42,
      lineageRef: json['lineageRef'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        observedAtUtc,
        source,
        entityRef,
        observationKind,
        semanticTuples,
        structuredSignals,
        locationContext,
        temporalContext,
        socialContext,
        activityContext,
        confidence,
        lineageRef,
      ];
}

class WhatState extends Equatable {
  final String entityRef;
  final String canonicalType;
  final List<String> subtypes;
  final List<String> aliases;
  final String placeType;
  final List<String> activityTypes;
  final List<String> socialContexts;
  final Map<String, double> affordanceVector;
  final Map<String, double> vibeSignature;
  final WhatUserRelation userRelation;
  final WhatLifecycleState lifecycleState;
  final double novelty;
  final double familiarity;
  final double trust;
  final double saturation;
  final double confidence;
  final int evidenceCount;
  final DateTime firstObservedAtUtc;
  final DateTime lastObservedAtUtc;
  final WhatSourceMix sourceMix;
  final List<String> lineageRefs;

  const WhatState({
    required this.entityRef,
    required this.canonicalType,
    this.subtypes = const [],
    this.aliases = const [],
    required this.placeType,
    this.activityTypes = const [],
    this.socialContexts = const [],
    this.affordanceVector = const {},
    this.vibeSignature = const {},
    this.userRelation = WhatUserRelation.neutral,
    this.lifecycleState = WhatLifecycleState.unknown,
    this.novelty = 1.0,
    this.familiarity = 0.0,
    this.trust = 0.0,
    this.saturation = 0.0,
    this.confidence = 0.0,
    this.evidenceCount = 0,
    required this.firstObservedAtUtc,
    required this.lastObservedAtUtc,
    this.sourceMix = const WhatSourceMix(),
    this.lineageRefs = const [],
  });

  factory WhatState.unresolved({String entityRef = 'unknown_entity'}) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return WhatState(
      entityRef: entityRef,
      canonicalType: 'destination_venue',
      placeType: 'destination_venue',
      firstObservedAtUtc: epoch,
      lastObservedAtUtc: epoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'entityRef': entityRef,
        'canonicalType': canonicalType,
        'subtypes': subtypes,
        'aliases': aliases,
        'placeType': placeType,
        'activityTypes': activityTypes,
        'socialContexts': socialContexts,
        'affordanceVector': affordanceVector,
        'vibeSignature': vibeSignature,
        'userRelation': _userRelationName(userRelation),
        'lifecycleState': lifecycleState.name,
        'novelty': novelty,
        'familiarity': familiarity,
        'trust': trust,
        'saturation': saturation,
        'confidence': confidence,
        'evidenceCount': evidenceCount,
        'firstObservedAtUtc': firstObservedAtUtc.toIso8601String(),
        'lastObservedAtUtc': lastObservedAtUtc.toIso8601String(),
        'sourceMix': sourceMix.toJson(),
        'lineageRefs': lineageRefs,
      };

  factory WhatState.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(dynamic value) {
      if (value is! Map) return const {};
      return value.map(
        (key, entry) => MapEntry(
          key.toString(),
          (entry as num?)?.toDouble() ?? 0.0,
        ),
      );
    }

    return WhatState(
      entityRef: (json['entityRef'] as String?) ?? 'unknown_entity',
      canonicalType: (json['canonicalType'] as String?) ?? 'destination_venue',
      subtypes: (json['subtypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      aliases: (json['aliases'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      placeType: (json['placeType'] as String?) ?? 'destination_venue',
      activityTypes: (json['activityTypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      socialContexts: (json['socialContexts'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      affordanceVector: toDoubleMap(json['affordanceVector']),
      vibeSignature: toDoubleMap(json['vibeSignature']),
      userRelation: _parseUserRelation((json['userRelation'] as String?) ?? ''),
      lifecycleState:
          _parseLifecycle((json['lifecycleState'] as String?) ?? 'unknown'),
      novelty: (json['novelty'] as num?)?.toDouble() ?? 1.0,
      familiarity: (json['familiarity'] as num?)?.toDouble() ?? 0.0,
      trust: (json['trust'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      firstObservedAtUtc:
          DateTime.tryParse((json['firstObservedAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastObservedAtUtc:
          DateTime.tryParse((json['lastObservedAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceMix: WhatSourceMix.fromJson(
        Map<String, dynamic>.from(
          json['sourceMix'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      lineageRefs: (json['lineageRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        entityRef,
        canonicalType,
        subtypes,
        aliases,
        placeType,
        activityTypes,
        socialContexts,
        affordanceVector,
        vibeSignature,
        userRelation,
        lifecycleState,
        novelty,
        familiarity,
        trust,
        saturation,
        confidence,
        evidenceCount,
        firstObservedAtUtc,
        lastObservedAtUtc,
        sourceMix,
        lineageRefs,
      ];
}

class WhatProjectionRequest extends Equatable {
  final String agentId;
  final String entityRef;
  final WhatState? state;

  const WhatProjectionRequest({
    required this.agentId,
    required this.entityRef,
    this.state,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'entityRef': entityRef,
        if (state != null) 'state': state!.toJson(),
      };

  factory WhatProjectionRequest.fromJson(Map<String, dynamic> json) {
    return WhatProjectionRequest(
      agentId: (json['agentId'] as String?) ?? '',
      entityRef: (json['entityRef'] as String?) ?? 'unknown_entity',
      state: json['state'] == null
          ? null
          : WhatState.fromJson(Map<String, dynamic>.from(json['state'] as Map)),
    );
  }

  @override
  List<Object?> get props => [agentId, entityRef, state];
}

class WhatProjection extends Equatable {
  final String baseEntityRef;
  final List<String> projectedTypes;
  final Map<String, double> projectedAffordances;
  final Map<String, double> projectedVibeSignature;
  final List<String> adjacentOpportunities;
  final double confidence;
  final String basis;

  const WhatProjection({
    required this.baseEntityRef,
    this.projectedTypes = const [],
    this.projectedAffordances = const {},
    this.projectedVibeSignature = const {},
    this.adjacentOpportunities = const [],
    this.confidence = 0.0,
    this.basis = 'unknown',
  });

  Map<String, dynamic> toJson() => {
        'baseEntityRef': baseEntityRef,
        'projectedTypes': projectedTypes,
        'projectedAffordances': projectedAffordances,
        'projectedVibeSignature': projectedVibeSignature,
        'adjacentOpportunities': adjacentOpportunities,
        'confidence': confidence,
        'basis': basis,
      };

  factory WhatProjection.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(dynamic value) {
      if (value is! Map) return const {};
      return value.map(
        (key, entry) => MapEntry(
          key.toString(),
          (entry as num?)?.toDouble() ?? 0.0,
        ),
      );
    }

    return WhatProjection(
      baseEntityRef: (json['baseEntityRef'] as String?) ?? 'unknown_entity',
      projectedTypes: (json['projectedTypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      projectedAffordances: toDoubleMap(json['projectedAffordances']),
      projectedVibeSignature: toDoubleMap(json['projectedVibeSignature']),
      adjacentOpportunities: (json['adjacentOpportunities'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      basis: (json['basis'] as String?) ?? 'unknown',
    );
  }

  @override
  List<Object?> get props => [
        baseEntityRef,
        projectedTypes,
        projectedAffordances,
        projectedVibeSignature,
        adjacentOpportunities,
        confidence,
        basis,
      ];
}

class WhatKernelSnapshot extends Equatable {
  final String agentId;
  final DateTime savedAtUtc;
  final List<WhatState> states;
  final int schemaVersion;

  const WhatKernelSnapshot({
    required this.agentId,
    required this.savedAtUtc,
    this.states = const [],
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'savedAtUtc': savedAtUtc.toIso8601String(),
        'states': states.map((entry) => entry.toJson()).toList(),
        'schemaVersion': schemaVersion,
      };

  factory WhatKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhatKernelSnapshot(
      agentId: (json['agentId'] as String?) ?? '',
      savedAtUtc: DateTime.tryParse((json['savedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      states: (json['states'] as List?)
              ?.map(
                (entry) => WhatState.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [agentId, savedAtUtc, states, schemaVersion];
}

class WhatSyncRequest extends Equatable {
  final String agentId;
  final String peerRuntimeId;
  final List<WhatState> deltas;
  final Map<String, dynamic>? policy;
  final DateTime observedAtUtc;

  const WhatSyncRequest({
    required this.agentId,
    required this.peerRuntimeId,
    required this.deltas,
    required this.observedAtUtc,
    this.policy,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'peerRuntimeId': peerRuntimeId,
        'deltas': deltas.map((entry) => entry.toJson()).toList(),
        'observedAtUtc': observedAtUtc.toIso8601String(),
        if (policy != null) 'policy': policy,
      };

  factory WhatSyncRequest.fromJson(Map<String, dynamic> json) {
    return WhatSyncRequest(
      agentId: (json['agentId'] as String?) ?? '',
      peerRuntimeId: (json['peerRuntimeId'] as String?) ?? '',
      deltas: (json['deltas'] as List?)
              ?.map(
                (entry) => WhatState.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      observedAtUtc:
          DateTime.tryParse((json['observedAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      policy: json['policy'] == null
          ? null
          : Map<String, dynamic>.from(json['policy'] as Map),
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        peerRuntimeId,
        deltas,
        policy,
        observedAtUtc,
      ];
}

class WhatSyncResult extends Equatable {
  final int acceptedCount;
  final int rejectedCount;
  final List<String> mergedEntityRefs;
  final DateTime savedAtUtc;

  const WhatSyncResult({
    required this.acceptedCount,
    required this.rejectedCount,
    required this.mergedEntityRefs,
    required this.savedAtUtc,
  });

  factory WhatSyncResult.fromJson(Map<String, dynamic> json) {
    return WhatSyncResult(
      acceptedCount: (json['acceptedCount'] as num?)?.toInt() ?? 0,
      rejectedCount: (json['rejectedCount'] as num?)?.toInt() ?? 0,
      mergedEntityRefs: (json['mergedEntityRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      savedAtUtc: DateTime.tryParse((json['savedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props =>
      [acceptedCount, rejectedCount, mergedEntityRefs, savedAtUtc];
}

class WhatRecoveryRequest extends Equatable {
  final String agentId;
  final Map<String, dynamic>? persistedEnvelope;
  final String mode;

  const WhatRecoveryRequest({
    required this.agentId,
    this.persistedEnvelope,
    this.mode = 'restore',
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        if (persistedEnvelope != null) 'persistedEnvelope': persistedEnvelope,
        'mode': mode,
      };

  factory WhatRecoveryRequest.fromJson(Map<String, dynamic> json) {
    return WhatRecoveryRequest(
      agentId: (json['agentId'] as String?) ?? '',
      persistedEnvelope: json['persistedEnvelope'] == null
          ? null
          : Map<String, dynamic>.from(json['persistedEnvelope'] as Map),
      mode: (json['mode'] as String?) ?? 'restore',
    );
  }

  @override
  List<Object?> get props => [agentId, persistedEnvelope, mode];
}

class WhatRecoveryResult extends Equatable {
  final int restoredCount;
  final int droppedCount;
  final int schemaVersion;
  final DateTime savedAtUtc;

  const WhatRecoveryResult({
    required this.restoredCount,
    required this.droppedCount,
    required this.schemaVersion,
    required this.savedAtUtc,
  });

  factory WhatRecoveryResult.fromJson(Map<String, dynamic> json) {
    return WhatRecoveryResult(
      restoredCount: (json['restoredCount'] as num?)?.toInt() ?? 0,
      droppedCount: (json['droppedCount'] as num?)?.toInt() ?? 0,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      savedAtUtc: DateTime.tryParse((json['savedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props =>
      [restoredCount, droppedCount, schemaVersion, savedAtUtc];
}

class WhatUpdateReceipt extends Equatable {
  final WhatState state;
  final WhatProjection? projection;
  final bool cloudUpdated;
  final bool meshForwarded;

  const WhatUpdateReceipt({
    required this.state,
    this.projection,
    this.cloudUpdated = false,
    this.meshForwarded = false,
  });

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        if (projection != null) 'projection': projection!.toJson(),
        'cloudUpdated': cloudUpdated,
        'meshForwarded': meshForwarded,
      };

  factory WhatUpdateReceipt.fromJson(Map<String, dynamic> json) {
    return WhatUpdateReceipt(
      state: WhatState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      projection: json['projection'] == null
          ? null
          : WhatProjection.fromJson(
              Map<String, dynamic>.from(json['projection'] as Map),
            ),
      cloudUpdated: json['cloudUpdated'] as bool? ?? false,
      meshForwarded: json['meshForwarded'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [state, projection, cloudUpdated, meshForwarded];
}

String _observationKindName(WhatObservationKind kind) {
  switch (kind) {
    case WhatObservationKind.tupleIntake:
      return 'tuple_intake';
    case WhatObservationKind.visit:
      return 'visit';
    case WhatObservationKind.eventAttendance:
      return 'event_attendance';
    case WhatObservationKind.listInteraction:
      return 'list_interaction';
    case WhatObservationKind.passiveDwell:
      return 'passive_dwell';
    case WhatObservationKind.ambientSocialEvent:
      return 'ambient_social_event';
    case WhatObservationKind.pluginSemanticEvent:
      return 'plugin_semantic_event';
    case WhatObservationKind.meshSemanticUpdate:
      return 'mesh_semantic_update';
  }
}

WhatObservationKind _parseObservationKind(String value) {
  switch (value) {
    case 'visit':
      return WhatObservationKind.visit;
    case 'event_attendance':
      return WhatObservationKind.eventAttendance;
    case 'list_interaction':
      return WhatObservationKind.listInteraction;
    case 'passive_dwell':
      return WhatObservationKind.passiveDwell;
    case 'ambient_social_event':
      return WhatObservationKind.ambientSocialEvent;
    case 'plugin_semantic_event':
      return WhatObservationKind.pluginSemanticEvent;
    case 'mesh_semantic_update':
      return WhatObservationKind.meshSemanticUpdate;
    case 'tuple_intake':
    default:
      return WhatObservationKind.tupleIntake;
  }
}

String _userRelationName(WhatUserRelation relation) {
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

WhatUserRelation _parseUserRelation(String value) {
  switch (value) {
    case 'prefers':
      return WhatUserRelation.prefers;
    case 'avoids':
      return WhatUserRelation.avoids;
    case 'curious_about':
      return WhatUserRelation.curiousAbout;
    case 'contextual_like':
      return WhatUserRelation.contextualLike;
    case 'used_to_like':
      return WhatUserRelation.usedToLike;
    case 'aspirational':
      return WhatUserRelation.aspirational;
    case 'neutral':
    default:
      return WhatUserRelation.neutral;
  }
}

WhatLifecycleState _parseLifecycle(String value) {
  return WhatLifecycleState.values.firstWhere(
    (entry) => entry.name == value,
    orElse: () => WhatLifecycleState.unknown,
  );
}
