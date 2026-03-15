import 'package:equatable/equatable.dart';

enum VibeSubjectKind {
  personalAgent,
  geographicAgent,
  scopedAgent,
  localityAgent,
  cityAgent,
  regionAgent,
  topLevelAgent,
  entity;

  String toWireValue() => switch (this) {
        VibeSubjectKind.personalAgent => 'personal_agent',
        VibeSubjectKind.geographicAgent => 'geographic_agent',
        VibeSubjectKind.scopedAgent => 'scoped_agent',
        VibeSubjectKind.localityAgent => 'locality_agent',
        VibeSubjectKind.cityAgent => 'city_agent',
        VibeSubjectKind.regionAgent => 'region_agent',
        VibeSubjectKind.topLevelAgent => 'top_level_agent',
        VibeSubjectKind.entity => 'entity',
      };

  static VibeSubjectKind fromWireValue(String? value) => switch (value) {
        'geographic_agent' => VibeSubjectKind.geographicAgent,
        'scoped_agent' => VibeSubjectKind.scopedAgent,
        'locality_agent' => VibeSubjectKind.localityAgent,
        'city_agent' => VibeSubjectKind.cityAgent,
        'region_agent' => VibeSubjectKind.regionAgent,
        'top_level_agent' => VibeSubjectKind.topLevelAgent,
        'entity' => VibeSubjectKind.entity,
        'user' => VibeSubjectKind.personalAgent,
        _ => VibeSubjectKind.personalAgent,
      };

  bool get isLegacyGeographicAlias => switch (this) {
        VibeSubjectKind.localityAgent ||
        VibeSubjectKind.cityAgent ||
        VibeSubjectKind.regionAgent ||
        VibeSubjectKind.topLevelAgent =>
          true,
        _ => false,
      };

  VibeSubjectKind get canonicalKind =>
      isLegacyGeographicAlias ? VibeSubjectKind.geographicAgent : this;
}

enum GeographicAgentLevel {
  locality,
  district,
  city,
  region,
  country,
  global;

  String toWireValue() => switch (this) {
        GeographicAgentLevel.locality => 'locality',
        GeographicAgentLevel.district => 'district',
        GeographicAgentLevel.city => 'city',
        GeographicAgentLevel.region => 'region',
        GeographicAgentLevel.country => 'country',
        GeographicAgentLevel.global => 'global',
      };

  static GeographicAgentLevel? fromWireValue(String? value) => switch (value) {
        'locality' => GeographicAgentLevel.locality,
        'district' => GeographicAgentLevel.district,
        'city' => GeographicAgentLevel.city,
        'region' => GeographicAgentLevel.region,
        'country' => GeographicAgentLevel.country,
        'global' => GeographicAgentLevel.global,
        _ => null,
      };
}

enum ScopedAgentKind {
  university,
  campus,
  organization,
  scene,
  communityNetwork;

  String toWireValue() => switch (this) {
        ScopedAgentKind.university => 'university',
        ScopedAgentKind.campus => 'campus',
        ScopedAgentKind.organization => 'organization',
        ScopedAgentKind.scene => 'scene',
        ScopedAgentKind.communityNetwork => 'community_network',
      };

  static ScopedAgentKind? fromWireValue(String? value) => switch (value) {
        'university' => ScopedAgentKind.university,
        'campus' => ScopedAgentKind.campus,
        'organization' => ScopedAgentKind.organization,
        'scene' => ScopedAgentKind.scene,
        'community_network' => ScopedAgentKind.communityNetwork,
        _ => null,
      };
}

class VibeSubjectRef extends Equatable {
  const VibeSubjectRef({
    required this.subjectId,
    required this.kind,
    this.geographicLevel,
    this.scopedKind,
    this.entityType,
    this.displayLabel,
  });

  final String subjectId;
  final VibeSubjectKind kind;
  final GeographicAgentLevel? geographicLevel;
  final ScopedAgentKind? scopedKind;
  final String? entityType;
  final String? displayLabel;

  factory VibeSubjectRef.personal(String agentId, {String? displayLabel}) {
    return VibeSubjectRef(
      subjectId: agentId,
      kind: VibeSubjectKind.personalAgent,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.geographic({
    required String subjectId,
    required GeographicAgentLevel level,
    String? displayLabel,
  }) {
    return VibeSubjectRef(
      subjectId: subjectId,
      kind: VibeSubjectKind.geographicAgent,
      geographicLevel: level,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.locality(String stableKey, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'locality-agent:$stableKey',
      level: GeographicAgentLevel.locality,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.district(String districtCode, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'district-agent:$districtCode',
      level: GeographicAgentLevel.district,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.city(String cityCode, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'city-agent:$cityCode',
      level: GeographicAgentLevel.city,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.region(String regionCode, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'region-agent:$regionCode',
      level: GeographicAgentLevel.region,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.country(String countryCode, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'country-agent:$countryCode',
      level: GeographicAgentLevel.country,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.topLevel(String topLevelCode, {String? displayLabel}) {
    return VibeSubjectRef(
      subjectId: 'top-level-agent:$topLevelCode',
      kind: VibeSubjectKind.topLevelAgent,
      geographicLevel: GeographicAgentLevel.global,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.global(String globalCode, {String? displayLabel}) {
    return VibeSubjectRef.geographic(
      subjectId: 'global-agent:$globalCode',
      level: GeographicAgentLevel.global,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.scoped({
    required String scopedId,
    required ScopedAgentKind scopedKind,
    String? displayLabel,
  }) {
    return VibeSubjectRef(
      subjectId: scopedId,
      kind: VibeSubjectKind.scopedAgent,
      scopedKind: scopedKind,
      displayLabel: displayLabel,
    );
  }

  factory VibeSubjectRef.entity({
    required String entityId,
    required String entityType,
    String? displayLabel,
  }) {
    return VibeSubjectRef(
      subjectId: entityId,
      kind: VibeSubjectKind.entity,
      entityType: entityType,
      displayLabel: displayLabel,
    );
  }

  GeographicAgentLevel? get effectiveGeographicLevel {
    if (geographicLevel != null) {
      return geographicLevel;
    }
    return switch (kind) {
      VibeSubjectKind.localityAgent => GeographicAgentLevel.locality,
      VibeSubjectKind.cityAgent => GeographicAgentLevel.city,
      VibeSubjectKind.regionAgent => GeographicAgentLevel.region,
      VibeSubjectKind.topLevelAgent => GeographicAgentLevel.global,
      _ => null,
    };
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'kind': kind.toWireValue(),
        if (effectiveGeographicLevel != null)
          'geographic_level': effectiveGeographicLevel!.toWireValue(),
        if (scopedKind != null) 'scoped_kind': scopedKind!.toWireValue(),
        if (entityType != null) 'entity_type': entityType,
        if (displayLabel != null) 'display_label': displayLabel,
      };

  factory VibeSubjectRef.fromJson(Map<String, dynamic> json) {
    final kind = VibeSubjectKind.fromWireValue(json['kind'] as String?);
    final geographicLevel = GeographicAgentLevel.fromWireValue(
            json['geographic_level'] as String?) ??
        switch (kind) {
          VibeSubjectKind.localityAgent => GeographicAgentLevel.locality,
          VibeSubjectKind.cityAgent => GeographicAgentLevel.city,
          VibeSubjectKind.regionAgent => GeographicAgentLevel.region,
          VibeSubjectKind.topLevelAgent => GeographicAgentLevel.global,
          _ => null,
        };
    return VibeSubjectRef(
      subjectId: json['subject_id'] as String? ?? 'unknown_subject',
      kind: kind,
      geographicLevel: geographicLevel,
      scopedKind: ScopedAgentKind.fromWireValue(json['scoped_kind'] as String?),
      entityType: (json['entity_type'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['entity_type'] as String?,
      displayLabel: (json['display_label'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['display_label'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        subjectId,
        kind,
        effectiveGeographicLevel,
        scopedKind,
        entityType,
        displayLabel,
      ];
}

enum VibeSignalKind {
  identity,
  pheromone,
  behavior,
  affective,
  style;

  String toWireValue() => switch (this) {
        VibeSignalKind.identity => 'identity',
        VibeSignalKind.pheromone => 'pheromone',
        VibeSignalKind.behavior => 'behavior',
        VibeSignalKind.affective => 'affective',
        VibeSignalKind.style => 'style',
      };

  static VibeSignalKind fromWireValue(String? value) => switch (value) {
        'identity' => VibeSignalKind.identity,
        'pheromone' => VibeSignalKind.pheromone,
        'behavior' => VibeSignalKind.behavior,
        'affective' => VibeSignalKind.affective,
        _ => VibeSignalKind.style,
      };
}

class VibeSignal extends Equatable {
  const VibeSignal({
    required this.key,
    required this.kind,
    required this.value,
    required this.confidence,
    this.provenance = const <String>[],
  });

  final String key;
  final VibeSignalKind kind;
  final double value;
  final double confidence;
  final List<String> provenance;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'kind': kind.toWireValue(),
        'value': value,
        'confidence': confidence,
        'provenance': provenance,
      };

  factory VibeSignal.fromJson(Map<String, dynamic> json) {
    return VibeSignal(
      key: json['key'] as String? ?? 'unknown_signal',
      kind: VibeSignalKind.fromWireValue(json['kind'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      provenance: ((json['provenance'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[key, kind, value, confidence, provenance];
}

class VibeEvidence extends Equatable {
  const VibeEvidence({
    required this.summary,
    required this.identitySignals,
    required this.pheromoneSignals,
    required this.behaviorSignals,
    required this.affectiveSignals,
    required this.styleSignals,
    this.schemaVersion = 1,
  });

  final String summary;
  final List<VibeSignal> identitySignals;
  final List<VibeSignal> pheromoneSignals;
  final List<VibeSignal> behaviorSignals;
  final List<VibeSignal> affectiveSignals;
  final List<VibeSignal> styleSignals;
  final int schemaVersion;

  bool get hasAnySignals =>
      identitySignals.isNotEmpty ||
      pheromoneSignals.isNotEmpty ||
      behaviorSignals.isNotEmpty ||
      affectiveSignals.isNotEmpty ||
      styleSignals.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'summary': summary,
        'identity_signals':
            identitySignals.map((entry) => entry.toJson()).toList(),
        'pheromone_signals':
            pheromoneSignals.map((entry) => entry.toJson()).toList(),
        'behavior_signals':
            behaviorSignals.map((entry) => entry.toJson()).toList(),
        'affective_signals':
            affectiveSignals.map((entry) => entry.toJson()).toList(),
        'style_signals': styleSignals.map((entry) => entry.toJson()).toList(),
        'schema_version': schemaVersion,
      };

  factory VibeEvidence.fromJson(Map<String, dynamic> json) {
    List<VibeSignal> decodeSignals(String key) {
      return ((json[key] as List?) ?? const <dynamic>[])
          .map(
            (entry) => VibeSignal.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
    }

    return VibeEvidence(
      summary: json['summary'] as String? ?? '',
      identitySignals: decodeSignals('identity_signals'),
      pheromoneSignals: decodeSignals('pheromone_signals'),
      behaviorSignals: decodeSignals('behavior_signals'),
      affectiveSignals: decodeSignals('affective_signals'),
      styleSignals: decodeSignals('style_signals'),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        summary,
        identitySignals,
        pheromoneSignals,
        behaviorSignals,
        affectiveSignals,
        styleSignals,
        schemaVersion,
      ];
}

class VibeMutationDecision extends Equatable {
  const VibeMutationDecision({
    required this.stateWriteAllowed,
    required this.dnaWriteAllowed,
    required this.pheromoneWriteAllowed,
    required this.behaviorWriteAllowed,
    required this.affectiveWriteAllowed,
    required this.styleWriteAllowed,
    required this.reasonCodes,
    this.governanceScope = 'personal',
    this.airGapEnvelopeRequired = false,
    this.schemaVersion = 1,
  });

  final bool stateWriteAllowed;
  final bool dnaWriteAllowed;
  final bool pheromoneWriteAllowed;
  final bool behaviorWriteAllowed;
  final bool affectiveWriteAllowed;
  final bool styleWriteAllowed;
  final List<String> reasonCodes;
  final String governanceScope;
  final bool airGapEnvelopeRequired;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'state_write_allowed': stateWriteAllowed,
        'dna_write_allowed': dnaWriteAllowed,
        'pheromone_write_allowed': pheromoneWriteAllowed,
        'behavior_write_allowed': behaviorWriteAllowed,
        'affective_write_allowed': affectiveWriteAllowed,
        'style_write_allowed': styleWriteAllowed,
        'reason_codes': reasonCodes,
        'governance_scope': governanceScope,
        'air_gap_envelope_required': airGapEnvelopeRequired,
        'schema_version': schemaVersion,
      };

  factory VibeMutationDecision.fromJson(Map<String, dynamic> json) {
    return VibeMutationDecision(
      stateWriteAllowed: json['state_write_allowed'] as bool? ?? false,
      dnaWriteAllowed: json['dna_write_allowed'] as bool? ?? false,
      pheromoneWriteAllowed: json['pheromone_write_allowed'] as bool? ?? false,
      behaviorWriteAllowed: json['behavior_write_allowed'] as bool? ?? false,
      affectiveWriteAllowed: json['affective_write_allowed'] as bool? ?? false,
      styleWriteAllowed: json['style_write_allowed'] as bool? ?? false,
      reasonCodes: ((json['reason_codes'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      governanceScope: json['governance_scope'] as String? ?? 'personal',
      airGapEnvelopeRequired:
          json['air_gap_envelope_required'] as bool? ?? false,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        stateWriteAllowed,
        dnaWriteAllowed,
        pheromoneWriteAllowed,
        behaviorWriteAllowed,
        affectiveWriteAllowed,
        styleWriteAllowed,
        reasonCodes,
        governanceScope,
        airGapEnvelopeRequired,
        schemaVersion,
      ];
}

class CoreDnaState extends Equatable {
  const CoreDnaState({
    required this.dimensions,
    required this.dimensionConfidence,
    required this.driftBudgetRemaining,
  });

  final Map<String, double> dimensions;
  final Map<String, double> dimensionConfidence;
  final double driftBudgetRemaining;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dimensions': dimensions,
        'dimension_confidence': dimensionConfidence,
        'drift_budget_remaining': driftBudgetRemaining,
      };

  factory CoreDnaState.fromJson(Map<String, dynamic> json) {
    Map<String, double> decodeMap(String key) {
      return ((json[key] as Map?) ?? const <String, dynamic>{}).map(
        (mapKey, value) =>
            MapEntry(mapKey.toString(), (value as num?)?.toDouble() ?? 0.0),
      );
    }

    return CoreDnaState(
      dimensions: decodeMap('dimensions'),
      dimensionConfidence: decodeMap('dimension_confidence'),
      driftBudgetRemaining:
          (json['drift_budget_remaining'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[dimensions, dimensionConfidence, driftBudgetRemaining];
}

class QuantumVibeState extends Equatable {
  const QuantumVibeState({
    required this.amplitudes,
    required this.phaseAlignment,
    required this.coherence,
  });

  final Map<String, double> amplitudes;
  final double phaseAlignment;
  final double coherence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amplitudes': amplitudes,
        'phase_alignment': phaseAlignment,
        'coherence': coherence,
      };

  factory QuantumVibeState.fromJson(Map<String, dynamic> json) {
    return QuantumVibeState(
      amplitudes:
          ((json['amplitudes'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      ),
      phaseAlignment: (json['phase_alignment'] as num?)?.toDouble() ?? 0.0,
      coherence: (json['coherence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => <Object?>[amplitudes, phaseAlignment, coherence];
}

class PheromoneState extends Equatable {
  const PheromoneState({
    required this.vectors,
    required this.decayRate,
    required this.lastDecayAtUtc,
  });

  final Map<String, double> vectors;
  final double decayRate;
  final DateTime lastDecayAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vectors': vectors,
        'decay_rate': decayRate,
        'last_decay_at_utc': lastDecayAtUtc.toUtc().toIso8601String(),
      };

  factory PheromoneState.fromJson(Map<String, dynamic> json) {
    return PheromoneState(
      vectors: ((json['vectors'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      ),
      decayRate: (json['decay_rate'] as num?)?.toDouble() ?? 0.08,
      lastDecayAtUtc:
          DateTime.tryParse(json['last_decay_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => <Object?>[vectors, decayRate, lastDecayAtUtc];
}

class BehaviorPatternState extends Equatable {
  const BehaviorPatternState({
    required this.patternWeights,
    required this.observationCount,
    required this.cadenceHours,
  });

  final Map<String, double> patternWeights;
  final int observationCount;
  final double cadenceHours;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pattern_weights': patternWeights,
        'observation_count': observationCount,
        'cadence_hours': cadenceHours,
      };

  factory BehaviorPatternState.fromJson(Map<String, dynamic> json) {
    return BehaviorPatternState(
      patternWeights:
          ((json['pattern_weights'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      ),
      observationCount: (json['observation_count'] as num?)?.toInt() ?? 0,
      cadenceHours: (json['cadence_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[patternWeights, observationCount, cadenceHours];
}

class AffectiveState extends Equatable {
  const AffectiveState({
    required this.valence,
    required this.arousal,
    required this.dominance,
    required this.label,
    required this.confidence,
    this.expiresAtUtc,
  });

  final double valence;
  final double arousal;
  final double dominance;
  final String label;
  final double confidence;
  final DateTime? expiresAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'valence': valence,
        'arousal': arousal,
        'dominance': dominance,
        'label': label,
        'confidence': confidence,
        if (expiresAtUtc != null)
          'expires_at_utc': expiresAtUtc!.toUtc().toIso8601String(),
      };

  factory AffectiveState.fromJson(Map<String, dynamic> json) {
    return AffectiveState(
      valence: (json['valence'] as num?)?.toDouble() ?? 0.0,
      arousal: (json['arousal'] as num?)?.toDouble() ?? 0.0,
      dominance: (json['dominance'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String? ?? 'neutral',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      expiresAtUtc:
          DateTime.tryParse(json['expires_at_utc'] as String? ?? '')?.toUtc(),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[valence, arousal, dominance, label, confidence, expiresAtUtc];
}

class KnotInvariantState extends Equatable {
  const KnotInvariantState({
    required this.crossingNumber,
    required this.tension,
    required this.symmetry,
  });

  final double crossingNumber;
  final double tension;
  final double symmetry;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'crossing_number': crossingNumber,
        'tension': tension,
        'symmetry': symmetry,
      };

  factory KnotInvariantState.fromJson(Map<String, dynamic> json) {
    return KnotInvariantState(
      crossingNumber: (json['crossing_number'] as num?)?.toDouble() ?? 0.0,
      tension: (json['tension'] as num?)?.toDouble() ?? 0.0,
      symmetry: (json['symmetry'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => <Object?>[crossingNumber, tension, symmetry];
}

class WorldsheetState extends Equatable {
  const WorldsheetState({
    required this.temporalPhase,
    required this.momentum,
    required this.curvature,
  });

  final double temporalPhase;
  final double momentum;
  final double curvature;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'temporal_phase': temporalPhase,
        'momentum': momentum,
        'curvature': curvature,
      };

  factory WorldsheetState.fromJson(Map<String, dynamic> json) {
    return WorldsheetState(
      temporalPhase: (json['temporal_phase'] as num?)?.toDouble() ?? 0.0,
      momentum: (json['momentum'] as num?)?.toDouble() ?? 0.0,
      curvature: (json['curvature'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => <Object?>[temporalPhase, momentum, curvature];
}

class StringEvolutionState extends Equatable {
  const StringEvolutionState({
    required this.coupling,
    required this.mutationVelocity,
    required this.harmonics,
  });

  final double coupling;
  final double mutationVelocity;
  final Map<String, double> harmonics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coupling': coupling,
        'mutation_velocity': mutationVelocity,
        'harmonics': harmonics,
      };

  factory StringEvolutionState.fromJson(Map<String, dynamic> json) {
    return StringEvolutionState(
      coupling: (json['coupling'] as num?)?.toDouble() ?? 0.0,
      mutationVelocity: (json['mutation_velocity'] as num?)?.toDouble() ?? 0.0,
      harmonics: ((json['harmonics'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[coupling, mutationVelocity, harmonics];
}

class DecoherenceState extends Equatable {
  const DecoherenceState({
    required this.noise,
    required this.stability,
    required this.decoherence,
  });

  final double noise;
  final double stability;
  final double decoherence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'noise': noise,
        'stability': stability,
        'decoherence': decoherence,
      };

  factory DecoherenceState.fromJson(Map<String, dynamic> json) {
    return DecoherenceState(
      noise: (json['noise'] as num?)?.toDouble() ?? 0.0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      decoherence: (json['decoherence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => <Object?>[noise, stability, decoherence];
}

class VibeExpressionContext extends Equatable {
  const VibeExpressionContext({
    required this.toneProfile,
    required this.pacingProfile,
    required this.uncertaintyProfile,
    required this.socialCadence,
    required this.energy,
    required this.directness,
  });

  final String toneProfile;
  final String pacingProfile;
  final String uncertaintyProfile;
  final double socialCadence;
  final double energy;
  final double directness;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tone_profile': toneProfile,
        'pacing_profile': pacingProfile,
        'uncertainty_profile': uncertaintyProfile,
        'social_cadence': socialCadence,
        'energy': energy,
        'directness': directness,
      };

  factory VibeExpressionContext.fromJson(Map<String, dynamic> json) {
    return VibeExpressionContext(
      toneProfile: json['tone_profile'] as String? ?? 'clear_calm',
      pacingProfile: json['pacing_profile'] as String? ?? 'steady',
      uncertaintyProfile: json['uncertainty_profile'] as String? ?? 'explicit',
      socialCadence: (json['social_cadence'] as num?)?.toDouble() ?? 0.5,
      energy: (json['energy'] as num?)?.toDouble() ?? 0.5,
      directness: (json['directness'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        toneProfile,
        pacingProfile,
        uncertaintyProfile,
        socialCadence,
        energy,
        directness,
      ];
}

class VibeStateSnapshot extends Equatable {
  const VibeStateSnapshot({
    required this.subjectId,
    required this.subjectKind,
    required this.coreDna,
    required this.quantumVibe,
    required this.pheromones,
    required this.behaviorPatterns,
    required this.affectiveState,
    required this.knotInvariants,
    required this.worldsheet,
    required this.stringEvolution,
    required this.decoherenceState,
    required this.expressionContext,
    required this.confidence,
    required this.freshnessHours,
    required this.provenanceTags,
    required this.updatedAtUtc,
    this.schemaVersion = 1,
  });

  final String subjectId;
  final String subjectKind;
  final CoreDnaState coreDna;
  final QuantumVibeState quantumVibe;
  final PheromoneState pheromones;
  final BehaviorPatternState behaviorPatterns;
  final AffectiveState affectiveState;
  final KnotInvariantState knotInvariants;
  final WorldsheetState worldsheet;
  final StringEvolutionState stringEvolution;
  final DecoherenceState decoherenceState;
  final VibeExpressionContext expressionContext;
  final double confidence;
  final double freshnessHours;
  final List<String> provenanceTags;
  final DateTime updatedAtUtc;
  final int schemaVersion;

  VibeSubjectRef get subjectRef {
    final resolvedKind = VibeSubjectKind.fromWireValue(subjectKind);
    GeographicAgentLevel? inferGeographicLevel() {
      if (subjectId.startsWith('locality-agent:')) {
        return GeographicAgentLevel.locality;
      }
      if (subjectId.startsWith('district-agent:')) {
        return GeographicAgentLevel.district;
      }
      if (subjectId.startsWith('city-agent:')) {
        return GeographicAgentLevel.city;
      }
      if (subjectId.startsWith('region-agent:')) {
        return GeographicAgentLevel.region;
      }
      if (subjectId.startsWith('country-agent:')) {
        return GeographicAgentLevel.country;
      }
      if (subjectId.startsWith('global-agent:') ||
          subjectId.startsWith('top-level-agent:')) {
        return GeographicAgentLevel.global;
      }
      return switch (resolvedKind) {
        VibeSubjectKind.localityAgent => GeographicAgentLevel.locality,
        VibeSubjectKind.cityAgent => GeographicAgentLevel.city,
        VibeSubjectKind.regionAgent => GeographicAgentLevel.region,
        VibeSubjectKind.topLevelAgent => GeographicAgentLevel.global,
        _ => null,
      };
    }

    return VibeSubjectRef(
      subjectId: subjectId,
      kind: resolvedKind,
      geographicLevel: inferGeographicLevel(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'subject_kind': subjectKind,
        'core_dna': coreDna.toJson(),
        'quantum_vibe': quantumVibe.toJson(),
        'pheromones': pheromones.toJson(),
        'behavior_patterns': behaviorPatterns.toJson(),
        'affective_state': affectiveState.toJson(),
        'knot_invariants': knotInvariants.toJson(),
        'worldsheet': worldsheet.toJson(),
        'string_evolution': stringEvolution.toJson(),
        'decoherence_state': decoherenceState.toJson(),
        'expression_context': expressionContext.toJson(),
        'confidence': confidence,
        'freshness_hours': freshnessHours,
        'provenance_tags': provenanceTags,
        'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
        'schema_version': schemaVersion,
      };

  factory VibeStateSnapshot.fromJson(Map<String, dynamic> json) {
    return VibeStateSnapshot(
      subjectId: json['subject_id'] as String? ?? 'unknown_subject',
      subjectKind: json['subject_kind'] as String? ?? 'user',
      coreDna: CoreDnaState.fromJson(
        Map<String, dynamic>.from(
          (json['core_dna'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      quantumVibe: QuantumVibeState.fromJson(
        Map<String, dynamic>.from(
          (json['quantum_vibe'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      pheromones: PheromoneState.fromJson(
        Map<String, dynamic>.from(
          (json['pheromones'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      behaviorPatterns: BehaviorPatternState.fromJson(
        Map<String, dynamic>.from(
          (json['behavior_patterns'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      affectiveState: AffectiveState.fromJson(
        Map<String, dynamic>.from(
          (json['affective_state'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      knotInvariants: KnotInvariantState.fromJson(
        Map<String, dynamic>.from(
          (json['knot_invariants'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      worldsheet: WorldsheetState.fromJson(
        Map<String, dynamic>.from(
          (json['worldsheet'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      stringEvolution: StringEvolutionState.fromJson(
        Map<String, dynamic>.from(
          (json['string_evolution'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      decoherenceState: DecoherenceState.fromJson(
        Map<String, dynamic>.from(
          (json['decoherence_state'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      expressionContext: VibeExpressionContext.fromJson(
        Map<String, dynamic>.from(
          (json['expression_context'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      freshnessHours: (json['freshness_hours'] as num?)?.toDouble() ?? 0.0,
      provenanceTags: ((json['provenance_tags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      updatedAtUtc:
          DateTime.tryParse(json['updated_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        subjectId,
        subjectKind,
        coreDna,
        quantumVibe,
        pheromones,
        behaviorPatterns,
        affectiveState,
        knotInvariants,
        worldsheet,
        stringEvolution,
        decoherenceState,
        expressionContext,
        confidence,
        freshnessHours,
        provenanceTags,
        updatedAtUtc,
        schemaVersion,
      ];
}

class EntityVibeSnapshot extends Equatable {
  const EntityVibeSnapshot({
    required this.entityId,
    required this.entityType,
    required this.vibe,
  });

  final String entityId;
  final String entityType;
  final VibeStateSnapshot vibe;

  VibeSubjectRef get subjectRef => VibeSubjectRef.entity(
        entityId: entityId,
        entityType: entityType,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entity_id': entityId,
        'entity_type': entityType,
        'vibe': vibe.toJson(),
      };

  factory EntityVibeSnapshot.fromJson(Map<String, dynamic> json) {
    return EntityVibeSnapshot(
      entityId: json['entity_id'] as String? ?? 'unknown_entity',
      entityType: json['entity_type'] as String? ?? 'entity',
      vibe: VibeStateSnapshot.fromJson(
        Map<String, dynamic>.from(
          (json['vibe'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[entityId, entityType, vibe];
}

class VibeUpdateReceipt extends Equatable {
  const VibeUpdateReceipt({
    required this.subjectId,
    required this.accepted,
    required this.reasonCodes,
    required this.updatedAtUtc,
    required this.snapshot,
  });

  final String subjectId;
  final bool accepted;
  final List<String> reasonCodes;
  final DateTime updatedAtUtc;
  final VibeStateSnapshot snapshot;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'accepted': accepted,
        'reason_codes': reasonCodes,
        'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
        'snapshot': snapshot.toJson(),
      };

  factory VibeUpdateReceipt.fromJson(Map<String, dynamic> json) {
    return VibeUpdateReceipt(
      subjectId: json['subject_id'] as String? ?? 'unknown_subject',
      accepted: json['accepted'] as bool? ?? false,
      reasonCodes: ((json['reason_codes'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      updatedAtUtc:
          DateTime.tryParse(json['updated_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      snapshot: VibeStateSnapshot.fromJson(
        Map<String, dynamic>.from(
          (json['snapshot'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[subjectId, accepted, reasonCodes, updatedAtUtc, snapshot];
}

class VibeSnapshotEnvelope extends Equatable {
  const VibeSnapshotEnvelope({
    required this.exportedAtUtc,
    this.subjectSnapshots = const <VibeStateSnapshot>[],
    this.entitySnapshots = const <EntityVibeSnapshot>[],
    this.migrationReceipts = const <String>[],
    this.metadata = const <String, dynamic>{},
    this.schemaVersion = 1,
  });

  final DateTime exportedAtUtc;
  final List<VibeStateSnapshot> subjectSnapshots;
  final List<EntityVibeSnapshot> entitySnapshots;
  final List<String> migrationReceipts;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exported_at_utc': exportedAtUtc.toUtc().toIso8601String(),
        'subject_snapshots':
            subjectSnapshots.map((entry) => entry.toJson()).toList(),
        'entity_snapshots':
            entitySnapshots.map((entry) => entry.toJson()).toList(),
        'migration_receipts': migrationReceipts,
        'metadata': metadata,
        'schema_version': schemaVersion,
      };

  factory VibeSnapshotEnvelope.fromJson(Map<String, dynamic> json) {
    return VibeSnapshotEnvelope(
      exportedAtUtc: DateTime.tryParse(json['exported_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      subjectSnapshots:
          ((json['subject_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => VibeStateSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      entitySnapshots:
          ((json['entity_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => EntityVibeSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      migrationReceipts:
          ((json['migration_receipts'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        exportedAtUtc,
        subjectSnapshots,
        entitySnapshots,
        migrationReceipts,
        metadata,
        schemaVersion,
      ];
}

class VibeKernelManifestSubject extends Equatable {
  const VibeKernelManifestSubject({
    required this.subjectRef,
    required this.snapshotStorageKey,
    required this.journalStorageKey,
    this.isEntitySnapshot = false,
    this.metadata = const <String, dynamic>{},
  });

  final VibeSubjectRef subjectRef;
  final String snapshotStorageKey;
  final String journalStorageKey;
  final bool isEntitySnapshot;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_ref': subjectRef.toJson(),
        'snapshot_storage_key': snapshotStorageKey,
        'journal_storage_key': journalStorageKey,
        'is_entity_snapshot': isEntitySnapshot,
        'metadata': metadata,
      };

  factory VibeKernelManifestSubject.fromJson(Map<String, dynamic> json) {
    return VibeKernelManifestSubject(
      subjectRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['subject_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      snapshotStorageKey:
          json['snapshot_storage_key'] as String? ?? 'unknown_snapshot_key',
      journalStorageKey:
          json['journal_storage_key'] as String? ?? 'unknown_journal_key',
      isEntitySnapshot: json['is_entity_snapshot'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        subjectRef,
        snapshotStorageKey,
        journalStorageKey,
        isEntitySnapshot,
        metadata,
      ];
}

class VibeKernelManifest extends Equatable {
  const VibeKernelManifest({
    required this.exportedAtUtc,
    required this.subjects,
    this.migrationVersion = 0,
    this.migrationReceipts = const <String>[],
    this.metadata = const <String, dynamic>{},
    this.schemaVersion = 1,
  });

  final DateTime exportedAtUtc;
  final List<VibeKernelManifestSubject> subjects;
  final int migrationVersion;
  final List<String> migrationReceipts;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exported_at_utc': exportedAtUtc.toUtc().toIso8601String(),
        'subjects': subjects.map((entry) => entry.toJson()).toList(),
        'migration_version': migrationVersion,
        'migration_receipts': migrationReceipts,
        'metadata': metadata,
        'schema_version': schemaVersion,
      };

  factory VibeKernelManifest.fromJson(Map<String, dynamic> json) {
    return VibeKernelManifest(
      exportedAtUtc: DateTime.tryParse(json['exported_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      subjects: ((json['subjects'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => VibeKernelManifestSubject.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      migrationVersion: (json['migration_version'] as num?)?.toInt() ?? 0,
      migrationReceipts:
          ((json['migration_receipts'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        exportedAtUtc,
        subjects,
        migrationVersion,
        migrationReceipts,
        metadata,
        schemaVersion,
      ];
}

class GeographicVibeBinding extends Equatable {
  const GeographicVibeBinding({
    required this.localityRef,
    required this.stableKey,
    this.higherGeographicRefs = const <VibeSubjectRef>[],
    this.scope = 'locality',
    this.districtCode,
    this.cityCode,
    this.regionCode,
    this.countryCode,
    this.globalCode,
    this.metadata = const <String, dynamic>{},
  });

  final VibeSubjectRef localityRef;
  final String stableKey;
  final List<VibeSubjectRef> higherGeographicRefs;
  final String scope;
  final String? districtCode;
  final String? cityCode;
  final String? regionCode;
  final String? countryCode;
  final String? globalCode;
  final Map<String, dynamic> metadata;

  List<VibeSubjectRef> get orderedGeographicRefs =>
      <VibeSubjectRef>[localityRef, ...higherGeographicRefs];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'locality_ref': localityRef.toJson(),
        'stable_key': stableKey,
        'higher_geographic_refs':
            higherGeographicRefs.map((entry) => entry.toJson()).toList(),
        'higher_agent_refs':
            higherGeographicRefs.map((entry) => entry.toJson()).toList(),
        'scope': scope,
        if (districtCode != null) 'district_code': districtCode,
        if (cityCode != null) 'city_code': cityCode,
        if (regionCode != null) 'region_code': regionCode,
        if (countryCode != null) 'country_code': countryCode,
        if (globalCode != null) 'global_code': globalCode,
        if (globalCode != null) 'top_level_code': globalCode,
        'metadata': metadata,
      };

  factory GeographicVibeBinding.fromJson(Map<String, dynamic> json) {
    final higherRefs = ((json['higher_geographic_refs'] as List?) ??
            (json['higher_agent_refs'] as List?) ??
            const <dynamic>[])
        .map(
          (entry) => VibeSubjectRef.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
    return GeographicVibeBinding(
      localityRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['locality_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      stableKey: json['stable_key'] as String? ?? 'unknown_locality',
      higherGeographicRefs: higherRefs,
      scope: json['scope'] as String? ?? 'locality',
      districtCode: (json['district_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['district_code'] as String?,
      cityCode: (json['city_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['city_code'] as String?,
      regionCode: (json['region_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['region_code'] as String?,
      countryCode: (json['country_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['country_code'] as String?,
      globalCode: ((json['global_code'] as String?) ??
                      (json['top_level_code'] as String?))
                  ?.trim()
                  .isEmpty ??
              true
          ? null
          : ((json['global_code'] as String?) ??
              (json['top_level_code'] as String?)),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        localityRef,
        stableKey,
        higherGeographicRefs,
        scope,
        districtCode,
        cityCode,
        regionCode,
        countryCode,
        globalCode,
        metadata,
      ];
}

class ScopedVibeBinding extends Equatable {
  const ScopedVibeBinding({
    required this.contextRef,
    required this.scopedKind,
    this.anchorGeographicRef,
    this.metadata = const <String, dynamic>{},
  });

  final VibeSubjectRef contextRef;
  final ScopedAgentKind scopedKind;
  final VibeSubjectRef? anchorGeographicRef;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'context_ref': contextRef.toJson(),
        'scoped_kind': scopedKind.toWireValue(),
        if (anchorGeographicRef != null)
          'anchor_geographic_ref': anchorGeographicRef!.toJson(),
        'metadata': metadata,
      };

  factory ScopedVibeBinding.fromJson(Map<String, dynamic> json) {
    return ScopedVibeBinding(
      contextRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['context_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      scopedKind: ScopedAgentKind.fromWireValue(
            json['scoped_kind'] as String?,
          ) ??
          ScopedAgentKind.organization,
      anchorGeographicRef: json['anchor_geographic_ref'] is Map
          ? VibeSubjectRef.fromJson(
              Map<String, dynamic>.from(json['anchor_geographic_ref'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[contextRef, scopedKind, anchorGeographicRef, metadata];
}

class LocalityVibeBinding extends Equatable {
  const LocalityVibeBinding({
    required this.localityRef,
    required this.stableKey,
    this.higherAgentRefs = const <VibeSubjectRef>[],
    this.scope = 'locality',
    this.cityCode,
    this.regionCode,
    this.topLevelCode,
    this.metadata = const <String, dynamic>{},
  });

  final VibeSubjectRef localityRef;
  final String stableKey;
  final List<VibeSubjectRef> higherAgentRefs;
  final String scope;
  final String? cityCode;
  final String? regionCode;
  final String? topLevelCode;
  final Map<String, dynamic> metadata;

  GeographicVibeBinding toGeographicBinding() => GeographicVibeBinding(
        localityRef: localityRef,
        stableKey: stableKey,
        higherGeographicRefs: higherAgentRefs,
        scope: scope,
        cityCode: cityCode,
        regionCode: regionCode,
        globalCode: topLevelCode,
        metadata: metadata,
      );

  factory LocalityVibeBinding.fromGeographicBinding(
    GeographicVibeBinding binding,
  ) {
    return LocalityVibeBinding(
      localityRef: binding.localityRef,
      stableKey: binding.stableKey,
      higherAgentRefs: binding.higherGeographicRefs,
      scope: binding.scope,
      cityCode: binding.cityCode,
      regionCode: binding.regionCode,
      topLevelCode: binding.globalCode,
      metadata: binding.metadata,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'locality_ref': localityRef.toJson(),
        'stable_key': stableKey,
        'higher_agent_refs':
            higherAgentRefs.map((entry) => entry.toJson()).toList(),
        'scope': scope,
        if (cityCode != null) 'city_code': cityCode,
        if (regionCode != null) 'region_code': regionCode,
        if (topLevelCode != null) 'top_level_code': topLevelCode,
        'metadata': metadata,
      };

  factory LocalityVibeBinding.fromJson(Map<String, dynamic> json) {
    return LocalityVibeBinding(
      localityRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['locality_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      stableKey: json['stable_key'] as String? ?? 'unknown_locality',
      higherAgentRefs:
          ((json['higher_agent_refs'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => VibeSubjectRef.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      scope: json['scope'] as String? ?? 'locality',
      cityCode: (json['city_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['city_code'] as String?,
      regionCode: (json['region_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['region_code'] as String?,
      topLevelCode: (json['top_level_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['top_level_code'] as String?,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        localityRef,
        stableKey,
        higherAgentRefs,
        scope,
        cityCode,
        regionCode,
        topLevelCode,
        metadata,
      ];
}

class HierarchicalVibeStack extends Equatable {
  const HierarchicalVibeStack({
    required this.primarySnapshot,
    this.geographicSnapshots = const <VibeStateSnapshot>[],
    this.scopedContextSnapshots = const <VibeStateSnapshot>[],
    this.geographicBinding,
    this.scopedBindings = const <ScopedVibeBinding>[],
    this.activeLocalitySnapshot,
    this.higherAgentSnapshots = const <VibeStateSnapshot>[],
    this.selectedEntitySnapshots = const <EntityVibeSnapshot>[],
    this.localityBinding,
  });

  final VibeStateSnapshot primarySnapshot;
  final List<VibeStateSnapshot> geographicSnapshots;
  final List<VibeStateSnapshot> scopedContextSnapshots;
  final GeographicVibeBinding? geographicBinding;
  final List<ScopedVibeBinding> scopedBindings;
  final VibeStateSnapshot? activeLocalitySnapshot;
  final List<VibeStateSnapshot> higherAgentSnapshots;
  final List<EntityVibeSnapshot> selectedEntitySnapshots;
  final LocalityVibeBinding? localityBinding;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'primary_snapshot': primarySnapshot.toJson(),
        'geographic_snapshots':
            geographicSnapshots.map((entry) => entry.toJson()).toList(),
        'scoped_context_snapshots':
            scopedContextSnapshots.map((entry) => entry.toJson()).toList(),
        if (geographicBinding != null)
          'geographic_binding': geographicBinding!.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        if (activeLocalitySnapshot != null)
          'active_locality_snapshot': activeLocalitySnapshot!.toJson(),
        'higher_agent_snapshots':
            higherAgentSnapshots.map((entry) => entry.toJson()).toList(),
        'selected_entity_snapshots':
            selectedEntitySnapshots.map((entry) => entry.toJson()).toList(),
        if (localityBinding != null)
          'locality_binding': localityBinding!.toJson(),
      };

  factory HierarchicalVibeStack.fromJson(Map<String, dynamic> json) {
    final geographicSnapshots =
        ((json['geographic_snapshots'] as List?) ?? const <dynamic>[])
            .map(
              (entry) => VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final higherAgentSnapshots =
        ((json['higher_agent_snapshots'] as List?) ?? const <dynamic>[])
            .map(
              (entry) => VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final explicitActiveLocalitySnapshot =
        json['active_locality_snapshot'] is Map
            ? VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(
                  json['active_locality_snapshot'] as Map,
                ),
              )
            : null;
    final activeLocalitySnapshot = explicitActiveLocalitySnapshot ??
        (geographicSnapshots.isNotEmpty ? geographicSnapshots.first : null);
    final derivedGeographicBinding = activeLocalitySnapshot == null
        ? null
        : GeographicVibeBinding(
            localityRef: activeLocalitySnapshot.subjectRef,
            stableKey: activeLocalitySnapshot.subjectRef.subjectId
                    .split(':')
                    .skip(1)
                    .join(':')
                    .trim()
                    .isEmpty
                ? activeLocalitySnapshot.subjectRef.subjectId
                : activeLocalitySnapshot.subjectRef.subjectId
                    .split(':')
                    .skip(1)
                    .join(':'),
            higherGeographicRefs:
                higherAgentSnapshots.map((entry) => entry.subjectRef).toList(),
            metadata: const <String, dynamic>{'derived_from_snapshot': true},
          );
    return HierarchicalVibeStack(
      primarySnapshot: VibeStateSnapshot.fromJson(
        Map<String, dynamic>.from(
          (json['primary_snapshot'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      geographicSnapshots: geographicSnapshots.isNotEmpty
          ? geographicSnapshots
          : <VibeStateSnapshot>[
              if (activeLocalitySnapshot != null) activeLocalitySnapshot,
              ...higherAgentSnapshots,
            ],
      scopedContextSnapshots:
          ((json['scoped_context_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => VibeStateSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      geographicBinding: json['geographic_binding'] is Map
          ? GeographicVibeBinding.fromJson(
              Map<String, dynamic>.from(json['geographic_binding'] as Map),
            )
          : json['locality_binding'] is Map
              ? LocalityVibeBinding.fromJson(
                  Map<String, dynamic>.from(json['locality_binding'] as Map),
                ).toGeographicBinding()
              : derivedGeographicBinding,
      scopedBindings: ((json['scoped_bindings'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ScopedVibeBinding.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      activeLocalitySnapshot: activeLocalitySnapshot,
      higherAgentSnapshots: higherAgentSnapshots.isNotEmpty
          ? higherAgentSnapshots
          : geographicSnapshots.length > 1
              ? geographicSnapshots.sublist(1)
              : const <VibeStateSnapshot>[],
      selectedEntitySnapshots:
          ((json['selected_entity_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => EntityVibeSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      localityBinding: json['locality_binding'] is Map
          ? LocalityVibeBinding.fromJson(
              Map<String, dynamic>.from(json['locality_binding'] as Map),
            )
          : derivedGeographicBinding == null
              ? null
              : LocalityVibeBinding.fromGeographicBinding(
                  derivedGeographicBinding,
                ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        primarySnapshot,
        geographicSnapshots,
        scopedContextSnapshots,
        geographicBinding,
        scopedBindings,
        activeLocalitySnapshot,
        higherAgentSnapshots,
        selectedEntitySnapshots,
        localityBinding,
      ];
}

class Ai2AiVibeReference extends Equatable {
  const Ai2AiVibeReference({
    required this.subjectRef,
    required this.scope,
    required this.confidence,
    this.geographicBinding,
    this.scopedBindings = const <ScopedVibeBinding>[],
    this.snapshotUpdatedAtUtc,
    this.metadata = const <String, dynamic>{},
  });

  final VibeSubjectRef subjectRef;
  final String scope;
  final double confidence;
  final GeographicVibeBinding? geographicBinding;
  final List<ScopedVibeBinding> scopedBindings;
  final DateTime? snapshotUpdatedAtUtc;
  final Map<String, dynamic> metadata;

  LocalityVibeBinding? get binding => geographicBinding == null
      ? null
      : LocalityVibeBinding.fromGeographicBinding(geographicBinding!);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_ref': subjectRef.toJson(),
        'scope': scope,
        'confidence': confidence,
        if (geographicBinding != null)
          'geographic_binding': geographicBinding!.toJson(),
        if (binding != null) 'binding': binding!.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        if (snapshotUpdatedAtUtc != null)
          'snapshot_updated_at_utc':
              snapshotUpdatedAtUtc!.toUtc().toIso8601String(),
        'metadata': metadata,
      };

  factory Ai2AiVibeReference.fromJson(Map<String, dynamic> json) {
    return Ai2AiVibeReference(
      subjectRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['subject_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      scope: json['scope'] as String? ?? 'locality',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      geographicBinding: json['geographic_binding'] is Map
          ? GeographicVibeBinding.fromJson(
              Map<String, dynamic>.from(json['geographic_binding'] as Map),
            )
          : json['binding'] is Map
              ? LocalityVibeBinding.fromJson(
                  Map<String, dynamic>.from(json['binding'] as Map),
                ).toGeographicBinding()
              : null,
      scopedBindings: ((json['scoped_bindings'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ScopedVibeBinding.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      snapshotUpdatedAtUtc:
          DateTime.tryParse(json['snapshot_updated_at_utc'] as String? ?? '')
              ?.toUtc(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        subjectRef,
        scope,
        confidence,
        geographicBinding,
        scopedBindings,
        snapshotUpdatedAtUtc,
        metadata,
      ];
}

class CanonicalPeerCompatibilitySurface extends Equatable {
  const CanonicalPeerCompatibilitySurface({
    required this.signatureHash,
    required this.archetype,
    required this.dimensionWindow,
    required this.energy,
    required this.socialCadence,
    required this.directness,
    required this.confidence,
    this.metadata = const <String, dynamic>{},
  });

  final String signatureHash;
  final String archetype;
  final Map<String, double> dimensionWindow;
  final double energy;
  final double socialCadence;
  final double directness;
  final double confidence;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'signature_hash': signatureHash,
        'archetype': archetype,
        'dimension_window': dimensionWindow,
        'energy': energy,
        'social_cadence': socialCadence,
        'directness': directness,
        'confidence': confidence,
        'metadata': metadata,
      };

  factory CanonicalPeerCompatibilitySurface.fromJson(
      Map<String, dynamic> json) {
    return CanonicalPeerCompatibilitySurface(
      signatureHash: json['signature_hash'] as String? ?? 'unknown_signature',
      archetype: json['archetype'] as String? ?? 'balanced_explorer',
      dimensionWindow:
          ((json['dimension_window'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) => MapEntry(
          key.toString(),
          (value as num?)?.toDouble() ?? 0.5,
        ),
      ),
      energy: (json['energy'] as num?)?.toDouble() ?? 0.5,
      socialCadence: (json['social_cadence'] as num?)?.toDouble() ?? 0.5,
      directness: (json['directness'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        signatureHash,
        archetype,
        dimensionWindow,
        energy,
        socialCadence,
        directness,
        confidence,
        metadata,
      ];
}

class Ai2AiCanonicalPeerPayload extends Equatable {
  const Ai2AiCanonicalPeerPayload({
    required this.reference,
    required this.personalSurface,
    required this.freshnessHours,
    required this.confidence,
    required this.generatedAtUtc,
    this.geographicBinding,
    this.scopedBindings = const <ScopedVibeBinding>[],
    this.metadata = const <String, dynamic>{},
  });

  final Ai2AiVibeReference reference;
  final CanonicalPeerCompatibilitySurface personalSurface;
  final GeographicVibeBinding? geographicBinding;
  final List<ScopedVibeBinding> scopedBindings;
  final double freshnessHours;
  final double confidence;
  final DateTime generatedAtUtc;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reference': reference.toJson(),
        'personal_surface': personalSurface.toJson(),
        if (geographicBinding != null)
          'geographic_binding': geographicBinding!.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        'freshness_hours': freshnessHours,
        'confidence': confidence,
        'generated_at_utc': generatedAtUtc.toUtc().toIso8601String(),
        'metadata': metadata,
      };

  factory Ai2AiCanonicalPeerPayload.fromJson(Map<String, dynamic> json) {
    return Ai2AiCanonicalPeerPayload(
      reference: Ai2AiVibeReference.fromJson(
        Map<String, dynamic>.from(
          (json['reference'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      personalSurface: CanonicalPeerCompatibilitySurface.fromJson(
        Map<String, dynamic>.from(
          (json['personal_surface'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      geographicBinding: json['geographic_binding'] is Map
          ? GeographicVibeBinding.fromJson(
              Map<String, dynamic>.from(json['geographic_binding'] as Map),
            )
          : null,
      scopedBindings: ((json['scoped_bindings'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ScopedVibeBinding.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      freshnessHours: (json['freshness_hours'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      generatedAtUtc:
          DateTime.tryParse(json['generated_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        reference,
        personalSurface,
        geographicBinding,
        scopedBindings,
        freshnessHours,
        confidence,
        generatedAtUtc,
        metadata,
      ];
}

class ResolvedPeerVibeContext extends Equatable {
  const ResolvedPeerVibeContext({
    required this.reference,
    required this.personalSurface,
    required this.freshnessHours,
    required this.confidence,
    required this.resolvedAtUtc,
    this.geographicBinding,
    this.scopedBindings = const <ScopedVibeBinding>[],
    this.governanceMetadata = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  final Ai2AiVibeReference reference;
  final CanonicalPeerCompatibilitySurface personalSurface;
  final GeographicVibeBinding? geographicBinding;
  final List<ScopedVibeBinding> scopedBindings;
  final double freshnessHours;
  final double confidence;
  final DateTime resolvedAtUtc;
  final Map<String, dynamic> governanceMetadata;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reference': reference.toJson(),
        'personal_surface': personalSurface.toJson(),
        if (geographicBinding != null)
          'geographic_binding': geographicBinding!.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        'freshness_hours': freshnessHours,
        'confidence': confidence,
        'resolved_at_utc': resolvedAtUtc.toUtc().toIso8601String(),
        'governance_metadata': governanceMetadata,
        'metadata': metadata,
      };

  factory ResolvedPeerVibeContext.fromJson(Map<String, dynamic> json) {
    return ResolvedPeerVibeContext(
      reference: Ai2AiVibeReference.fromJson(
        Map<String, dynamic>.from(
          (json['reference'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      personalSurface: CanonicalPeerCompatibilitySurface.fromJson(
        Map<String, dynamic>.from(
          (json['personal_surface'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      geographicBinding: json['geographic_binding'] is Map
          ? GeographicVibeBinding.fromJson(
              Map<String, dynamic>.from(json['geographic_binding'] as Map),
            )
          : null,
      scopedBindings: ((json['scoped_bindings'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ScopedVibeBinding.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      freshnessHours: (json['freshness_hours'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      resolvedAtUtc: DateTime.tryParse(json['resolved_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      governanceMetadata: Map<String, dynamic>.from(
        (json['governance_metadata'] as Map?) ?? const <String, dynamic>{},
      ),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        reference,
        personalSurface,
        geographicBinding,
        scopedBindings,
        freshnessHours,
        confidence,
        resolvedAtUtc,
        governanceMetadata,
        metadata,
      ];
}

class TrajectoryMutationRecord extends Equatable {
  const TrajectoryMutationRecord({
    required this.recordId,
    required this.subjectRef,
    required this.category,
    required this.occurredAtUtc,
    this.accepted = true,
    this.reasonCodes = const <String>[],
    this.governanceScope = 'personal',
    this.evidenceSummary,
    this.snapshotUpdatedAtUtc,
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final VibeSubjectRef subjectRef;
  final String category;
  final DateTime occurredAtUtc;
  final bool accepted;
  final List<String> reasonCodes;
  final String governanceScope;
  final String? evidenceSummary;
  final DateTime? snapshotUpdatedAtUtc;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'record_id': recordId,
        'subject_ref': subjectRef.toJson(),
        'category': category,
        'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
        'accepted': accepted,
        'reason_codes': reasonCodes,
        'governance_scope': governanceScope,
        if (evidenceSummary != null) 'evidence_summary': evidenceSummary,
        if (snapshotUpdatedAtUtc != null)
          'snapshot_updated_at_utc':
              snapshotUpdatedAtUtc!.toUtc().toIso8601String(),
        'metadata': metadata,
      };

  factory TrajectoryMutationRecord.fromJson(Map<String, dynamic> json) {
    return TrajectoryMutationRecord(
      recordId: json['record_id'] as String? ?? 'unknown_record',
      subjectRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['subject_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      category: json['category'] as String? ?? 'unknown',
      occurredAtUtc: DateTime.tryParse(json['occurred_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      accepted: json['accepted'] as bool? ?? true,
      reasonCodes: ((json['reason_codes'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      governanceScope: json['governance_scope'] as String? ?? 'personal',
      evidenceSummary:
          (json['evidence_summary'] as String?)?.trim().isEmpty ?? true
              ? null
              : json['evidence_summary'] as String?,
      snapshotUpdatedAtUtc:
          DateTime.tryParse(json['snapshot_updated_at_utc'] as String? ?? '')
              ?.toUtc(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        recordId,
        subjectRef,
        category,
        occurredAtUtc,
        accepted,
        reasonCodes,
        governanceScope,
        evidenceSummary,
        snapshotUpdatedAtUtc,
        metadata,
      ];
}

class TrajectoryHydrationCheckpoint extends Equatable {
  const TrajectoryHydrationCheckpoint({
    required this.checkpointId,
    required this.subjectRef,
    required this.snapshot,
    required this.recordedAtUtc,
    this.sourceRecordIds = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String checkpointId;
  final VibeSubjectRef subjectRef;
  final VibeStateSnapshot snapshot;
  final DateTime recordedAtUtc;
  final List<String> sourceRecordIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checkpoint_id': checkpointId,
        'subject_ref': subjectRef.toJson(),
        'snapshot': snapshot.toJson(),
        'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
        'source_record_ids': sourceRecordIds,
        'metadata': metadata,
      };

  factory TrajectoryHydrationCheckpoint.fromJson(Map<String, dynamic> json) {
    return TrajectoryHydrationCheckpoint(
      checkpointId: json['checkpoint_id'] as String? ?? 'unknown_checkpoint',
      subjectRef: VibeSubjectRef.fromJson(
        Map<String, dynamic>.from(
          (json['subject_ref'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      snapshot: VibeStateSnapshot.fromJson(
        Map<String, dynamic>.from(
          (json['snapshot'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      recordedAtUtc: DateTime.tryParse(json['recorded_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceRecordIds:
          ((json['source_record_ids'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        checkpointId,
        subjectRef,
        snapshot,
        recordedAtUtc,
        sourceRecordIds,
        metadata,
      ];
}

class StateEncoderInputSnapshot extends Equatable {
  const StateEncoderInputSnapshot({
    required this.userSnapshot,
    this.entitySnapshot,
    this.geographicSnapshots = const <VibeStateSnapshot>[],
    this.scopedContextSnapshots = const <VibeStateSnapshot>[],
    this.geographicBinding,
    this.scopedBindings = const <ScopedVibeBinding>[],
    this.activeLocalitySnapshot,
    this.higherAgentSnapshots = const <VibeStateSnapshot>[],
    this.selectedEntitySnapshots = const <EntityVibeSnapshot>[],
    this.hierarchicalStack,
    this.metadata = const <String, dynamic>{},
  });

  final VibeStateSnapshot userSnapshot;
  final EntityVibeSnapshot? entitySnapshot;
  final List<VibeStateSnapshot> geographicSnapshots;
  final List<VibeStateSnapshot> scopedContextSnapshots;
  final GeographicVibeBinding? geographicBinding;
  final List<ScopedVibeBinding> scopedBindings;
  final VibeStateSnapshot? activeLocalitySnapshot;
  final List<VibeStateSnapshot> higherAgentSnapshots;
  final List<EntityVibeSnapshot> selectedEntitySnapshots;
  final HierarchicalVibeStack? hierarchicalStack;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user_snapshot': userSnapshot.toJson(),
        if (entitySnapshot != null) 'entity_snapshot': entitySnapshot!.toJson(),
        'geographic_snapshots':
            geographicSnapshots.map((entry) => entry.toJson()).toList(),
        'scoped_context_snapshots':
            scopedContextSnapshots.map((entry) => entry.toJson()).toList(),
        if (geographicBinding != null)
          'geographic_binding': geographicBinding!.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        if (activeLocalitySnapshot != null)
          'active_locality_snapshot': activeLocalitySnapshot!.toJson(),
        'higher_agent_snapshots':
            higherAgentSnapshots.map((entry) => entry.toJson()).toList(),
        'selected_entity_snapshots':
            selectedEntitySnapshots.map((entry) => entry.toJson()).toList(),
        if (hierarchicalStack != null)
          'hierarchical_stack': hierarchicalStack!.toJson(),
        'metadata': metadata,
      };

  factory StateEncoderInputSnapshot.fromJson(Map<String, dynamic> json) {
    final explicitActiveLocalitySnapshot =
        json['active_locality_snapshot'] is Map
            ? VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(
                  json['active_locality_snapshot'] as Map,
                ),
              )
            : null;
    final higherAgentSnapshots =
        ((json['higher_agent_snapshots'] as List?) ?? const <dynamic>[])
            .map(
              (entry) => VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final geographicSnapshots =
        ((json['geographic_snapshots'] as List?) ?? const <dynamic>[])
            .map(
              (entry) => VibeStateSnapshot.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final activeLocalitySnapshot = explicitActiveLocalitySnapshot ??
        (geographicSnapshots.isNotEmpty ? geographicSnapshots.first : null);
    final derivedGeographicBinding = activeLocalitySnapshot == null
        ? null
        : GeographicVibeBinding(
            localityRef: activeLocalitySnapshot.subjectRef,
            stableKey: activeLocalitySnapshot.subjectRef.subjectId
                    .split(':')
                    .skip(1)
                    .join(':')
                    .trim()
                    .isEmpty
                ? activeLocalitySnapshot.subjectRef.subjectId
                : activeLocalitySnapshot.subjectRef.subjectId
                    .split(':')
                    .skip(1)
                    .join(':'),
            higherGeographicRefs:
                higherAgentSnapshots.map((entry) => entry.subjectRef).toList(),
            metadata: const <String, dynamic>{'derived_from_snapshot': true},
          );
    return StateEncoderInputSnapshot(
      userSnapshot: VibeStateSnapshot.fromJson(
        Map<String, dynamic>.from(
          (json['user_snapshot'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      entitySnapshot: json['entity_snapshot'] is Map
          ? EntityVibeSnapshot.fromJson(
              Map<String, dynamic>.from(json['entity_snapshot'] as Map),
            )
          : null,
      geographicSnapshots: geographicSnapshots.isNotEmpty
          ? geographicSnapshots
          : <VibeStateSnapshot>[
              if (activeLocalitySnapshot != null) activeLocalitySnapshot,
              ...higherAgentSnapshots,
            ],
      scopedContextSnapshots:
          ((json['scoped_context_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => VibeStateSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      geographicBinding: json['geographic_binding'] is Map
          ? GeographicVibeBinding.fromJson(
              Map<String, dynamic>.from(json['geographic_binding'] as Map),
            )
          : json['locality_binding'] is Map
              ? LocalityVibeBinding.fromJson(
                  Map<String, dynamic>.from(json['locality_binding'] as Map),
                ).toGeographicBinding()
              : derivedGeographicBinding,
      scopedBindings: ((json['scoped_bindings'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ScopedVibeBinding.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      activeLocalitySnapshot: activeLocalitySnapshot,
      higherAgentSnapshots: higherAgentSnapshots.isNotEmpty
          ? higherAgentSnapshots
          : geographicSnapshots.length > 1
              ? geographicSnapshots.sublist(1)
              : const <VibeStateSnapshot>[],
      selectedEntitySnapshots:
          ((json['selected_entity_snapshots'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => EntityVibeSnapshot.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      hierarchicalStack: json['hierarchical_stack'] is Map
          ? HierarchicalVibeStack.fromJson(
              Map<String, dynamic>.from(json['hierarchical_stack'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        userSnapshot,
        entitySnapshot,
        geographicSnapshots,
        scopedContextSnapshots,
        geographicBinding,
        scopedBindings,
        activeLocalitySnapshot,
        higherAgentSnapshots,
        selectedEntitySnapshots,
        hierarchicalStack,
        metadata,
      ];
}
