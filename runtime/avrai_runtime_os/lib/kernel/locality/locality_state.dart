import 'package:equatable/equatable.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

enum LocalityReliabilityTier {
  zeroLocality,
  bootstrap,
  candidate,
  established,
  advisory,
}

enum LocalityAdvisoryStatus {
  inactive,
  eligible,
  active,
  coolingDown,
}

enum LocalityObservationType {
  onboardingSeed,
  visitComplete,
  meshLocalityUpdate,
  federatedPriorUpdate,
  advisoryResult,
  happinessSignal,
  organicDiscoverySignal,
}

enum LocalityProjectionAudience {
  user,
  admin,
  debug,
}

class LocalitySourceMix extends Equatable {
  final double local;
  final double mesh;
  final double federated;
  final double geometry;
  final double syntheticPrior;

  const LocalitySourceMix({
    this.local = 0.0,
    this.mesh = 0.0,
    this.federated = 0.0,
    this.geometry = 0.0,
    this.syntheticPrior = 0.0,
  });

  const LocalitySourceMix.localFirst()
      : local = 1.0,
        mesh = 0.0,
        federated = 0.0,
        geometry = 0.0,
        syntheticPrior = 0.0;

  const LocalitySourceMix.syntheticBootstrap()
      : local = 0.0,
        mesh = 0.0,
        federated = 0.0,
        geometry = 0.0,
        syntheticPrior = 1.0;

  Map<String, dynamic> toJson() => {
        'local': local,
        'mesh': mesh,
        'federated': federated,
        'geometry': geometry,
        'syntheticPrior': syntheticPrior,
      };

  factory LocalitySourceMix.fromJson(Map<String, dynamic> json) {
    return LocalitySourceMix(
      local: (json['local'] as num?)?.toDouble() ?? 0.0,
      mesh: (json['mesh'] as num?)?.toDouble() ?? 0.0,
      federated: (json['federated'] as num?)?.toDouble() ?? 0.0,
      geometry: (json['geometry'] as num?)?.toDouble() ?? 0.0,
      syntheticPrior: (json['syntheticPrior'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [local, mesh, federated, geometry, syntheticPrior];
}

class LocalityState extends Equatable {
  final LocalityToken activeToken;
  final List<double> embedding;
  final double confidence;
  final double boundaryTension;
  final LocalityReliabilityTier reliabilityTier;
  final DateTime freshness;
  final int evidenceCount;
  final double evolutionRate;
  final LocalityToken? parentToken;
  final String? topAlias;
  final LocalityAdvisoryStatus advisoryStatus;
  final LocalitySourceMix sourceMix;

  const LocalityState({
    required this.activeToken,
    required this.embedding,
    required this.confidence,
    required this.boundaryTension,
    required this.reliabilityTier,
    required this.freshness,
    required this.evidenceCount,
    required this.evolutionRate,
    required this.advisoryStatus,
    required this.sourceMix,
    this.parentToken,
    this.topAlias,
  }) : assert(embedding.length == 12);

  factory LocalityState.zero({
    String id = 'unresolved',
    String? alias,
  }) {
    return LocalityState(
      activeToken: LocalityToken(
        kind: LocalityTokenKind.syntheticBootstrap,
        id: id,
        alias: alias,
      ),
      embedding: List<double>.filled(12, 0.5),
      confidence: 0.0,
      boundaryTension: 1.0,
      reliabilityTier: LocalityReliabilityTier.zeroLocality,
      freshness: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      evidenceCount: 0,
      evolutionRate: 0.0,
      advisoryStatus: LocalityAdvisoryStatus.inactive,
      sourceMix: const LocalitySourceMix.syntheticBootstrap(),
      topAlias: alias,
    );
  }

  LocalityState copyWith({
    LocalityToken? activeToken,
    List<double>? embedding,
    double? confidence,
    double? boundaryTension,
    LocalityReliabilityTier? reliabilityTier,
    DateTime? freshness,
    int? evidenceCount,
    double? evolutionRate,
    LocalityToken? parentToken,
    String? topAlias,
    LocalityAdvisoryStatus? advisoryStatus,
    LocalitySourceMix? sourceMix,
  }) {
    return LocalityState(
      activeToken: activeToken ?? this.activeToken,
      embedding: embedding ?? this.embedding,
      confidence: confidence ?? this.confidence,
      boundaryTension: boundaryTension ?? this.boundaryTension,
      reliabilityTier: reliabilityTier ?? this.reliabilityTier,
      freshness: freshness ?? this.freshness,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      evolutionRate: evolutionRate ?? this.evolutionRate,
      parentToken: parentToken ?? this.parentToken,
      topAlias: topAlias ?? this.topAlias,
      advisoryStatus: advisoryStatus ?? this.advisoryStatus,
      sourceMix: sourceMix ?? this.sourceMix,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeToken': activeToken.toJson(),
        'embedding': embedding,
        'confidence': confidence,
        'boundaryTension': boundaryTension,
        'reliabilityTier': reliabilityTier.name,
        'freshness': freshness.toIso8601String(),
        'evidenceCount': evidenceCount,
        'evolutionRate': evolutionRate,
        if (parentToken != null) 'parentToken': parentToken!.toJson(),
        if (topAlias != null) 'topAlias': topAlias,
        'advisoryStatus': advisoryStatus.name,
        'sourceMix': sourceMix.toJson(),
      };

  factory LocalityState.fromJson(Map<String, dynamic> json) {
    final embedding = (json['embedding'] as List?)
            ?.map((entry) => (entry as num).toDouble())
            .toList() ??
        List<double>.filled(12, 0.5);
    return LocalityState(
      activeToken: LocalityToken.fromJson(
        Map<String, dynamic>.from(
          json['activeToken'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      embedding:
          embedding.length == 12 ? embedding : List<double>.filled(12, 0.5),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      boundaryTension: (json['boundaryTension'] as num?)?.toDouble() ?? 1.0,
      reliabilityTier: LocalityReliabilityTier.values.firstWhere(
        (value) =>
            value.name ==
            (json['reliabilityTier'] ??
                LocalityReliabilityTier.zeroLocality.name),
        orElse: () => LocalityReliabilityTier.zeroLocality,
      ),
      freshness: DateTime.tryParse((json['freshness'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      evolutionRate: (json['evolutionRate'] as num?)?.toDouble() ?? 0.0,
      parentToken: json['parentToken'] == null
          ? null
          : LocalityToken.fromJson(
              Map<String, dynamic>.from(json['parentToken'] as Map),
            ),
      topAlias: (json['topAlias'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['topAlias'] as String?,
      advisoryStatus: LocalityAdvisoryStatus.values.firstWhere(
        (value) =>
            value.name ==
            (json['advisoryStatus'] ?? LocalityAdvisoryStatus.inactive.name),
        orElse: () => LocalityAdvisoryStatus.inactive,
      ),
      sourceMix: LocalitySourceMix.fromJson(
        Map<String, dynamic>.from(
          json['sourceMix'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
        activeToken,
        embedding,
        confidence,
        boundaryTension,
        reliabilityTier,
        freshness,
        evidenceCount,
        evolutionRate,
        parentToken,
        topAlias,
        advisoryStatus,
        sourceMix,
      ];
}

class LocalityPerceptionInput extends Equatable {
  final String agentId;
  final double? latitude;
  final double? longitude;
  final DateTime occurredAtUtc;
  final String? topAlias;
  final String? motionContext;
  final String? meshContext;
  final String? geometryHint;
  final ({double lat, double lon})? knownHomebase;
  final LocalityAgentKeyV1? localityKeyHint;

  const LocalityPerceptionInput({
    required this.agentId,
    required this.occurredAtUtc,
    this.latitude,
    this.longitude,
    this.topAlias,
    this.motionContext,
    this.meshContext,
    this.geometryHint,
    this.knownHomebase,
    this.localityKeyHint,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'occurredAtUtc': occurredAtUtc.toIso8601String(),
        if (topAlias != null) 'topAlias': topAlias,
        if (motionContext != null) 'motionContext': motionContext,
        if (meshContext != null) 'meshContext': meshContext,
        if (geometryHint != null) 'geometryHint': geometryHint,
        if (knownHomebase != null)
          'knownHomebase': {
            'lat': knownHomebase!.lat,
            'lon': knownHomebase!.lon,
          },
        if (localityKeyHint != null)
          'localityKeyHint': localityKeyHint!.toJson(),
      };

  factory LocalityPerceptionInput.fromJson(Map<String, dynamic> json) {
    final knownHomebaseJson = json['knownHomebase'] as Map?;
    return LocalityPerceptionInput(
      agentId: (json['agentId'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      occurredAtUtc:
          DateTime.tryParse((json['occurredAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      topAlias: json['topAlias'] as String?,
      motionContext: json['motionContext'] as String?,
      meshContext: json['meshContext'] as String?,
      geometryHint: json['geometryHint'] as String?,
      knownHomebase: knownHomebaseJson == null
          ? null
          : (
              lat: ((knownHomebaseJson['lat'] as num?)?.toDouble() ?? 0.0),
              lon: ((knownHomebaseJson['lon'] as num?)?.toDouble() ?? 0.0),
            ),
      localityKeyHint: json['localityKeyHint'] == null
          ? null
          : LocalityAgentKeyV1.fromJson(
              Map<String, dynamic>.from(json['localityKeyHint'] as Map),
            ),
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        latitude,
        longitude,
        occurredAtUtc,
        topAlias,
        motionContext,
        meshContext,
        geometryHint,
        knownHomebase?.lat,
        knownHomebase?.lon,
        localityKeyHint,
      ];
}

class LocalityObservation extends Equatable {
  final String userId;
  final String agentId;
  final LocalityObservationType type;
  final LocalityAgentKeyV1 key;
  final DateTime occurredAtUtc;
  final String source;
  final String? reportedCityCode;
  final String? inferredCityCode;
  final int? dwellMinutes;
  final double? qualityScore;
  final bool? isRepeatVisit;
  final String? topAlias;

  const LocalityObservation({
    required this.userId,
    required this.agentId,
    required this.type,
    required this.key,
    required this.occurredAtUtc,
    required this.source,
    this.reportedCityCode,
    this.inferredCityCode,
    this.dwellMinutes,
    this.qualityScore,
    this.isRepeatVisit,
    this.topAlias,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'agentId': agentId,
        'type': type.name,
        'key': key.toJson(),
        'occurredAtUtc': occurredAtUtc.toIso8601String(),
        'source': source,
        if (reportedCityCode != null) 'reportedCityCode': reportedCityCode,
        if (inferredCityCode != null) 'inferredCityCode': inferredCityCode,
        if (dwellMinutes != null) 'dwellMinutes': dwellMinutes,
        if (qualityScore != null) 'qualityScore': qualityScore,
        if (isRepeatVisit != null) 'isRepeatVisit': isRepeatVisit,
        if (topAlias != null) 'topAlias': topAlias,
      };

  factory LocalityObservation.fromJson(Map<String, dynamic> json) {
    return LocalityObservation(
      userId: (json['userId'] as String?) ?? '',
      agentId: (json['agentId'] as String?) ?? '',
      type: LocalityObservationType.values.firstWhere(
        (value) =>
            value.name ==
            (json['type'] ?? LocalityObservationType.visitComplete.name),
        orElse: () => LocalityObservationType.visitComplete,
      ),
      key: LocalityAgentKeyV1.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      occurredAtUtc:
          DateTime.tryParse((json['occurredAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: (json['source'] as String?) ?? 'unknown',
      reportedCityCode: json['reportedCityCode'] as String?,
      inferredCityCode: json['inferredCityCode'] as String?,
      dwellMinutes: (json['dwellMinutes'] as num?)?.toInt(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      isRepeatVisit: json['isRepeatVisit'] as bool?,
      topAlias: json['topAlias'] as String?,
    );
  }

  LocalityAgentUpdateEventV1 toUpdateEvent() {
    return LocalityAgentUpdateEventV1(
      key: key,
      occurredAtUtc: occurredAtUtc,
      source: source,
      reportedCityCode: reportedCityCode,
      inferredCityCode: inferredCityCode,
      dwellMinutes: dwellMinutes,
      qualityScore: qualityScore,
      isRepeatVisit: isRepeatVisit,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        agentId,
        type,
        key,
        occurredAtUtc,
        source,
        reportedCityCode,
        inferredCityCode,
        dwellMinutes,
        qualityScore,
        isRepeatVisit,
        topAlias,
      ];
}

class LocalityUpdateReceipt extends Equatable {
  final LocalityState state;
  final bool cloudUpdated;
  final bool meshForwarded;

  const LocalityUpdateReceipt({
    required this.state,
    this.cloudUpdated = false,
    this.meshForwarded = false,
  });

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        'cloudUpdated': cloudUpdated,
        'meshForwarded': meshForwarded,
      };

  factory LocalityUpdateReceipt.fromJson(Map<String, dynamic> json) {
    return LocalityUpdateReceipt(
      state: LocalityState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      cloudUpdated: json['cloudUpdated'] as bool? ?? false,
      meshForwarded: json['meshForwarded'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [state, cloudUpdated, meshForwarded];
}

class LocalitySyncRequest extends Equatable {
  final String agentId;
  final bool allowCloud;
  final bool allowMesh;

  const LocalitySyncRequest({
    required this.agentId,
    this.allowCloud = true,
    this.allowMesh = true,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'allowCloud': allowCloud,
        'allowMesh': allowMesh,
      };

  factory LocalitySyncRequest.fromJson(Map<String, dynamic> json) {
    return LocalitySyncRequest(
      agentId: (json['agentId'] as String?) ?? '',
      allowCloud: json['allowCloud'] as bool? ?? true,
      allowMesh: json['allowMesh'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [agentId, allowCloud, allowMesh];
}

class LocalitySyncResult extends Equatable {
  final bool synced;
  final String message;

  const LocalitySyncResult({
    required this.synced,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'synced': synced,
        'message': message,
      };

  factory LocalitySyncResult.fromJson(Map<String, dynamic> json) {
    return LocalitySyncResult(
      synced: json['synced'] as bool? ?? false,
      message: (json['message'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [synced, message];
}

class LocalityProjectionRequest extends Equatable {
  final LocalityProjectionAudience audience;
  final LocalityState state;
  final bool includeGeometry;
  final bool includeAttribution;
  final bool includePrediction;

  const LocalityProjectionRequest({
    required this.audience,
    required this.state,
    this.includeGeometry = false,
    this.includeAttribution = false,
    this.includePrediction = false,
  });

  Map<String, dynamic> toJson() => {
        'audience': audience.name,
        'state': state.toJson(),
        'includeGeometry': includeGeometry,
        'includeAttribution': includeAttribution,
        'includePrediction': includePrediction,
      };

  factory LocalityProjectionRequest.fromJson(Map<String, dynamic> json) {
    return LocalityProjectionRequest(
      audience: LocalityProjectionAudience.values.firstWhere(
        (value) =>
            value.name ==
            (json['audience'] ?? LocalityProjectionAudience.user.name),
        orElse: () => LocalityProjectionAudience.user,
      ),
      state: LocalityState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      includeGeometry: json['includeGeometry'] as bool? ?? false,
      includeAttribution: json['includeAttribution'] as bool? ?? false,
      includePrediction: json['includePrediction'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        audience,
        state,
        includeGeometry,
        includeAttribution,
        includePrediction,
      ];
}

class LocalityPointQuery extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime occurredAtUtc;
  final String? agentId;
  final String? topAlias;
  final LocalityProjectionAudience audience;
  final bool includeGeometry;
  final bool includeAttribution;
  final bool includePrediction;

  const LocalityPointQuery({
    required this.latitude,
    required this.longitude,
    required this.occurredAtUtc,
    this.agentId,
    this.topAlias,
    this.audience = LocalityProjectionAudience.user,
    this.includeGeometry = false,
    this.includeAttribution = false,
    this.includePrediction = false,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'occurredAtUtc': occurredAtUtc.toIso8601String(),
        if (agentId != null) 'agentId': agentId,
        if (topAlias != null) 'topAlias': topAlias,
        'audience': audience.name,
        'includeGeometry': includeGeometry,
        'includeAttribution': includeAttribution,
        'includePrediction': includePrediction,
      };

  factory LocalityPointQuery.fromJson(Map<String, dynamic> json) {
    return LocalityPointQuery(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      occurredAtUtc:
          DateTime.tryParse((json['occurredAtUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      agentId: json['agentId'] as String?,
      topAlias: json['topAlias'] as String?,
      audience: LocalityProjectionAudience.values.firstWhere(
        (value) =>
            value.name ==
            (json['audience'] ?? LocalityProjectionAudience.user.name),
        orElse: () => LocalityProjectionAudience.user,
      ),
      includeGeometry: json['includeGeometry'] as bool? ?? false,
      includeAttribution: json['includeAttribution'] as bool? ?? false,
      includePrediction: json['includePrediction'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        occurredAtUtc,
        agentId,
        topAlias,
        audience,
        includeGeometry,
        includeAttribution,
        includePrediction,
      ];
}

class LocalityProjection extends Equatable {
  final String primaryLabel;
  final String confidenceBucket;
  final bool nearBoundary;
  final LocalityToken activeToken;
  final Map<String, dynamic> metadata;

  const LocalityProjection({
    required this.primaryLabel,
    required this.confidenceBucket,
    required this.nearBoundary,
    required this.activeToken,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() => {
        'primaryLabel': primaryLabel,
        'confidenceBucket': confidenceBucket,
        'nearBoundary': nearBoundary,
        'activeToken': activeToken.toJson(),
        'metadata': metadata,
      };

  factory LocalityProjection.fromJson(Map<String, dynamic> json) {
    return LocalityProjection(
      primaryLabel: (json['primaryLabel'] as String?) ?? '',
      confidenceBucket: (json['confidenceBucket'] as String?) ?? 'low',
      nearBoundary: json['nearBoundary'] as bool? ?? false,
      activeToken: LocalityToken.fromJson(
        Map<String, dynamic>.from(json['activeToken'] as Map? ?? const {}),
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props =>
      [primaryLabel, confidenceBucket, nearBoundary, activeToken, metadata];
}

class LocalityPointResolution extends Equatable {
  final LocalityState state;
  final LocalityProjection projection;
  final String? cityCode;
  final String? localityCode;
  final String? displayName;

  const LocalityPointResolution({
    required this.state,
    required this.projection,
    this.cityCode,
    this.localityCode,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        'projection': projection.toJson(),
        if (cityCode != null) 'cityCode': cityCode,
        if (localityCode != null) 'localityCode': localityCode,
        if (displayName != null) 'displayName': displayName,
      };

  factory LocalityPointResolution.fromJson(Map<String, dynamic> json) {
    return LocalityPointResolution(
      state: LocalityState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      projection: LocalityProjection.fromJson(
        Map<String, dynamic>.from(json['projection'] as Map? ?? const {}),
      ),
      cityCode: json['cityCode'] as String?,
      localityCode: json['localityCode'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        state,
        projection,
        cityCode,
        localityCode,
        displayName,
      ];
}

class LocalityKernelSnapshot extends Equatable {
  final String agentId;
  final LocalityState state;
  final DateTime savedAtUtc;

  const LocalityKernelSnapshot({
    required this.agentId,
    required this.state,
    required this.savedAtUtc,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'state': state.toJson(),
        'savedAtUtc': savedAtUtc.toIso8601String(),
      };

  factory LocalityKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return LocalityKernelSnapshot(
      agentId: (json['agentId'] as String?) ?? '',
      state: LocalityState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      savedAtUtc: DateTime.tryParse((json['savedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [agentId, state, savedAtUtc];
}

class LocalityCandidateRecord extends Equatable {
  final LocalityToken token;
  final int coherenceCount;
  final DateTime firstSeenUtc;
  final DateTime lastSeenUtc;

  const LocalityCandidateRecord({
    required this.token,
    required this.coherenceCount,
    required this.firstSeenUtc,
    required this.lastSeenUtc,
  });

  Map<String, dynamic> toJson() => {
        'token': token.toJson(),
        'coherenceCount': coherenceCount,
        'firstSeenUtc': firstSeenUtc.toIso8601String(),
        'lastSeenUtc': lastSeenUtc.toIso8601String(),
      };

  factory LocalityCandidateRecord.fromJson(Map<String, dynamic> json) {
    return LocalityCandidateRecord(
      token: LocalityToken.fromJson(
        Map<String, dynamic>.from(json['token'] as Map? ?? const {}),
      ),
      coherenceCount: (json['coherenceCount'] as num?)?.toInt() ?? 0,
      firstSeenUtc:
          DateTime.tryParse((json['firstSeenUtc'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastSeenUtc: DateTime.tryParse((json['lastSeenUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [token, coherenceCount, firstSeenUtc, lastSeenUtc];
}

class LocalityRecoveryRequest extends Equatable {
  final String agentId;

  const LocalityRecoveryRequest({required this.agentId});

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
      };

  factory LocalityRecoveryRequest.fromJson(Map<String, dynamic> json) {
    return LocalityRecoveryRequest(
      agentId: (json['agentId'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [agentId];
}

class LocalityRecoveryResult extends Equatable {
  final LocalityState state;
  final bool recoveredFromSnapshot;

  const LocalityRecoveryResult({
    required this.state,
    required this.recoveredFromSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'state': state.toJson(),
        'recoveredFromSnapshot': recoveredFromSnapshot,
      };

  factory LocalityRecoveryResult.fromJson(Map<String, dynamic> json) {
    return LocalityRecoveryResult(
      state: LocalityState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      ),
      recoveredFromSnapshot: json['recoveredFromSnapshot'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [state, recoveredFromSnapshot];
}
