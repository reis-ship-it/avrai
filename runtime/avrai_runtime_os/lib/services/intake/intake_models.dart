import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';

enum IntakeEntityType {
  spot,
  event,
  community,
  linkedBundle,
  review,
}

enum IntakeReviewDecision {
  publish,
  review,
}

class UpwardAirGapArtifact extends Equatable {
  const UpwardAirGapArtifact({
    required this.receiptId,
    required this.artifactVersion,
    required this.originPlane,
    required this.sourceKind,
    required this.sourceScope,
    required this.destinationCeiling,
    required this.issuedAtUtc,
    required this.expiresAtUtc,
    required this.contentSha256,
    required this.allowedNextStages,
    required this.sanitizedPayload,
    required this.attestation,
    this.pseudonymousActorRef,
  });

  final String receiptId;
  final String artifactVersion;
  final String originPlane;
  final String sourceKind;
  final String sourceScope;
  final String destinationCeiling;
  final DateTime issuedAtUtc;
  final DateTime expiresAtUtc;
  final String contentSha256;
  final List<String> allowedNextStages;
  final Map<String, dynamic> sanitizedPayload;
  final Map<String, dynamic> attestation;
  final String? pseudonymousActorRef;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiptId': receiptId,
      'artifactVersion': artifactVersion,
      'originPlane': originPlane,
      'sourceKind': sourceKind,
      'sourceScope': sourceScope,
      'destinationCeiling': destinationCeiling,
      'issuedAtUtc': issuedAtUtc.toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toIso8601String(),
      'contentSha256': contentSha256,
      'allowedNextStages': allowedNextStages,
      'sanitizedPayload': sanitizedPayload,
      'attestation': attestation,
      'pseudonymousActorRef': pseudonymousActorRef,
    };
  }

  factory UpwardAirGapArtifact.fromJson(Map<String, dynamic> json) {
    return UpwardAirGapArtifact(
      receiptId: (json['receiptId'] ?? '').toString(),
      artifactVersion: (json['artifactVersion'] ?? '0.1').toString(),
      originPlane: (json['originPlane'] ?? 'unknown').toString(),
      sourceKind: (json['sourceKind'] ?? 'unknown').toString(),
      sourceScope: (json['sourceScope'] ?? 'unknown').toString(),
      destinationCeiling:
          (json['destinationCeiling'] ?? 'reality_model_agent').toString(),
      issuedAtUtc: DateTime.parse(json['issuedAtUtc'] as String),
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      contentSha256: (json['contentSha256'] ?? '').toString(),
      allowedNextStages:
          (json['allowedNextStages'] as List? ?? const <dynamic>[])
              .map((value) => value.toString())
              .toList(),
      sanitizedPayload: Map<String, dynamic>.from(
        json['sanitizedPayload'] ?? const <String, dynamic>{},
      ),
      attestation: Map<String, dynamic>.from(
        json['attestation'] ?? const <String, dynamic>{},
      ),
      pseudonymousActorRef: json['pseudonymousActorRef'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        receiptId,
        artifactVersion,
        originPlane,
        sourceKind,
        sourceScope,
        destinationCeiling,
        issuedAtUtc,
        expiresAtUtc,
        contentSha256,
        allowedNextStages,
        sanitizedPayload,
        attestation,
        pseudonymousActorRef,
      ];
}

class KernelOfflineEvidenceReceipt extends Equatable {
  const KernelOfflineEvidenceReceipt({
    required this.receiptId,
    required this.receiptKind,
    required this.sourceSystem,
    required this.sourcePlane,
    required this.observedAtUtc,
    this.kernelId,
    this.requestId,
    this.lineageRef,
    this.environmentId,
    this.cityCode,
    this.localityCode,
    this.actorScope,
    this.boundedEvidence = const <String, dynamic>{},
    this.temporalLineage = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  final String receiptId;
  final String receiptKind;
  final String sourceSystem;
  final String sourcePlane;
  final DateTime observedAtUtc;
  final String? kernelId;
  final String? requestId;
  final String? lineageRef;
  final String? environmentId;
  final String? cityCode;
  final String? localityCode;
  final String? actorScope;
  final Map<String, dynamic> boundedEvidence;
  final Map<String, dynamic> temporalLineage;
  final List<String> signalTags;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiptId': receiptId,
      'receiptKind': receiptKind,
      'sourceSystem': sourceSystem,
      'sourcePlane': sourcePlane,
      'observedAtUtc': observedAtUtc.toIso8601String(),
      'kernelId': kernelId,
      'requestId': requestId,
      'lineageRef': lineageRef,
      'environmentId': environmentId,
      'cityCode': cityCode,
      'localityCode': localityCode,
      'actorScope': actorScope,
      'boundedEvidence': boundedEvidence,
      'temporalLineage': temporalLineage,
      'signalTags': signalTags,
    };
  }

  factory KernelOfflineEvidenceReceipt.fromJson(Map<String, dynamic> json) {
    return KernelOfflineEvidenceReceipt(
      receiptId: (json['receiptId'] ?? '').toString(),
      receiptKind: (json['receiptKind'] ?? 'kernel_receipt').toString(),
      sourceSystem: (json['sourceSystem'] ?? 'unknown').toString(),
      sourcePlane: (json['sourcePlane'] ?? 'offline_kernel').toString(),
      observedAtUtc: DateTime.parse(json['observedAtUtc'] as String),
      kernelId: json['kernelId'] as String?,
      requestId: json['requestId'] as String?,
      lineageRef: json['lineageRef'] as String?,
      environmentId: json['environmentId'] as String?,
      cityCode: json['cityCode'] as String?,
      localityCode: json['localityCode'] as String?,
      actorScope: json['actorScope'] as String?,
      boundedEvidence: Map<String, dynamic>.from(
        json['boundedEvidence'] ?? const <String, dynamic>{},
      ),
      temporalLineage: Map<String, dynamic>.from(
        json['temporalLineage'] ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        receiptId,
        receiptKind,
        sourceSystem,
        sourcePlane,
        observedAtUtc,
        kernelId,
        requestId,
        lineageRef,
        environmentId,
        cityCode,
        localityCode,
        actorScope,
        boundedEvidence,
        temporalLineage,
        signalTags,
      ];
}

class ExternalSourceDescriptor extends Equatable {
  final String id;
  final String ownerUserId;
  final String sourceProvider;
  final String? sourceUrl;
  final ExternalConnectionMode connectionMode;
  final IntakeEntityType? entityHint;
  final String? sourceLabel;
  final String? cityCode;
  final String? localityCode;
  final bool isOneWaySync;
  final bool isClaimable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final ExternalSyncState syncState;
  final Map<String, dynamic> metadata;
  final ArtifactLifecycleMetadata? lifecycle;

  const ExternalSourceDescriptor({
    required this.id,
    required this.ownerUserId,
    required this.sourceProvider,
    this.sourceUrl,
    this.connectionMode = ExternalConnectionMode.manual,
    this.entityHint,
    this.sourceLabel,
    this.cityCode,
    this.localityCode,
    this.isOneWaySync = true,
    this.isClaimable = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncState = ExternalSyncState.pending,
    this.metadata = const {},
    this.lifecycle,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'sourceProvider': sourceProvider,
      'sourceUrl': sourceUrl,
      'connectionMode': connectionMode.name,
      'entityHint': entityHint?.name,
      'sourceLabel': sourceLabel,
      'cityCode': cityCode,
      'localityCode': localityCode,
      'isOneWaySync': isOneWaySync,
      'isClaimable': isClaimable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncState': syncState.name,
      'metadata': metadata,
      'lifecycle': lifecycle?.toJson(),
    };
  }

  factory ExternalSourceDescriptor.fromJson(Map<String, dynamic> json) {
    return ExternalSourceDescriptor(
      id: (json['id'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? '').toString(),
      sourceProvider: (json['sourceProvider'] ?? 'external').toString(),
      sourceUrl: json['sourceUrl'] as String?,
      connectionMode: ExternalConnectionMode.values.firstWhere(
        (value) => value.name == json['connectionMode'],
        orElse: () => ExternalConnectionMode.manual,
      ),
      entityHint: json['entityHint'] == null
          ? null
          : IntakeEntityType.values.firstWhere(
              (value) => value.name == json['entityHint'],
              orElse: () => IntakeEntityType.review,
            ),
      sourceLabel: json['sourceLabel'] as String?,
      cityCode: json['cityCode'] as String?,
      localityCode: json['localityCode'] as String?,
      isOneWaySync: json['isOneWaySync'] as bool? ?? true,
      isClaimable: json['isClaimable'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      syncState: ExternalSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => ExternalSyncState.pending,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const {}),
      lifecycle: json['lifecycle'] is Map
          ? ArtifactLifecycleMetadata.fromJson(
              Map<String, dynamic>.from(json['lifecycle'] as Map),
            )
          : null,
    );
  }

  ExternalSourceDescriptor copyWith({
    String? id,
    String? ownerUserId,
    String? sourceProvider,
    Object? sourceUrl = _intakeSentinel,
    ExternalConnectionMode? connectionMode,
    Object? entityHint = _intakeSentinel,
    Object? sourceLabel = _intakeSentinel,
    Object? cityCode = _intakeSentinel,
    Object? localityCode = _intakeSentinel,
    bool? isOneWaySync,
    bool? isClaimable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastSyncedAt = _intakeSentinel,
    ExternalSyncState? syncState,
    Map<String, dynamic>? metadata,
    Object? lifecycle = _intakeSentinel,
  }) {
    return ExternalSourceDescriptor(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      sourceUrl:
          sourceUrl == _intakeSentinel ? this.sourceUrl : sourceUrl as String?,
      connectionMode: connectionMode ?? this.connectionMode,
      entityHint: entityHint == _intakeSentinel
          ? this.entityHint
          : entityHint as IntakeEntityType?,
      sourceLabel: sourceLabel == _intakeSentinel
          ? this.sourceLabel
          : sourceLabel as String?,
      cityCode:
          cityCode == _intakeSentinel ? this.cityCode : cityCode as String?,
      localityCode: localityCode == _intakeSentinel
          ? this.localityCode
          : localityCode as String?,
      isOneWaySync: isOneWaySync ?? this.isOneWaySync,
      isClaimable: isClaimable ?? this.isClaimable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt == _intakeSentinel
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      syncState: syncState ?? this.syncState,
      metadata: metadata ?? this.metadata,
      lifecycle: lifecycle == _intakeSentinel
          ? this.lifecycle
          : lifecycle as ArtifactLifecycleMetadata?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUserId,
        sourceProvider,
        sourceUrl,
        connectionMode,
        entityHint,
        sourceLabel,
        cityCode,
        localityCode,
        isOneWaySync,
        isClaimable,
        createdAt,
        updatedAt,
        lastSyncedAt,
        syncState,
        metadata,
        lifecycle,
      ];
}

class ExternalSyncJob extends Equatable {
  final String id;
  final String sourceId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final ExternalSyncState state;
  final String? failureReason;
  final int importedCount;
  final int reviewCount;
  final ArtifactLifecycleMetadata? lifecycle;

  const ExternalSyncJob({
    required this.id,
    required this.sourceId,
    required this.startedAt,
    required this.updatedAt,
    this.state = ExternalSyncState.pending,
    this.failureReason,
    this.importedCount = 0,
    this.reviewCount = 0,
    this.lifecycle,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'state': state.name,
      'failureReason': failureReason,
      'importedCount': importedCount,
      'reviewCount': reviewCount,
      'lifecycle': lifecycle?.toJson(),
    };
  }

  factory ExternalSyncJob.fromJson(Map<String, dynamic> json) {
    return ExternalSyncJob(
      id: (json['id'] ?? '').toString(),
      sourceId: (json['sourceId'] ?? '').toString(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      state: ExternalSyncState.values.firstWhere(
        (value) => value.name == json['state'],
        orElse: () => ExternalSyncState.pending,
      ),
      failureReason: json['failureReason'] as String?,
      importedCount: (json['importedCount'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lifecycle: json['lifecycle'] is Map
          ? ArtifactLifecycleMetadata.fromJson(
              Map<String, dynamic>.from(json['lifecycle'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        startedAt,
        updatedAt,
        state,
        failureReason,
        importedCount,
        reviewCount,
        lifecycle,
      ];
}

class IntakeCandidate extends Equatable {
  final String title;
  final String description;
  final String category;
  final String? organizerName;
  final String? locationLabel;
  final String? websiteUrl;
  final String? externalId;
  final String? sourceUrl;
  final double? latitude;
  final double? longitude;
  final String? cityCode;
  final String? localityCode;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> tags;
  final SafeArtifactEnvelope? compressedArtifactEnvelope;
  final CompressedKnowledgePacket? compressedKnowledgePacket;
  final CompressionBudgetProfile? compressionBudgetProfile;
  final Map<String, dynamic> rawPayload;

  const IntakeCandidate({
    required this.title,
    required this.description,
    required this.category,
    this.organizerName,
    this.locationLabel,
    this.websiteUrl,
    this.externalId,
    this.sourceUrl,
    this.latitude,
    this.longitude,
    this.cityCode,
    this.localityCode,
    this.startTime,
    this.endTime,
    this.tags = const [],
    this.compressedArtifactEnvelope,
    this.compressedKnowledgePacket,
    this.compressionBudgetProfile,
    this.rawPayload = const {},
  });

  bool get hasWho => (organizerName ?? '').trim().isNotEmpty;
  bool get hasWhat => title.trim().isNotEmpty || description.trim().isNotEmpty;
  bool get hasWhen => startTime != null || rawPayload['hours'] != null;
  bool get hasWhere =>
      (locationLabel ?? '').trim().isNotEmpty ||
      (latitude != null && longitude != null);

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        organizerName,
        locationLabel,
        websiteUrl,
        externalId,
        sourceUrl,
        latitude,
        longitude,
        cityCode,
        localityCode,
        startTime,
        endTime,
        tags,
        compressedArtifactEnvelope,
        compressedKnowledgePacket,
        compressionBudgetProfile,
        rawPayload,
      ];
}

class IntakeRouteDecision extends Equatable {
  final IntakeEntityType primaryType;
  final List<IntakeEntityType> linkedTypes;
  final IntakeReviewDecision reviewDecision;
  final double confidence;
  final List<String> reasons;

  const IntakeRouteDecision({
    required this.primaryType,
    this.linkedTypes = const [],
    required this.reviewDecision,
    required this.confidence,
    this.reasons = const [],
  });

  bool get shouldPublishImmediately =>
      reviewDecision == IntakeReviewDecision.publish;

  @override
  List<Object?> get props => [
        primaryType,
        linkedTypes,
        reviewDecision,
        confidence,
        reasons,
      ];
}

class OrganizerReviewItem extends Equatable {
  final String id;
  final String sourceId;
  final String ownerUserId;
  final IntakeEntityType targetType;
  final String title;
  final String summary;
  final List<String> missingFields;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final ArtifactLifecycleMetadata? lifecycle;

  const OrganizerReviewItem({
    required this.id,
    required this.sourceId,
    required this.ownerUserId,
    required this.targetType,
    required this.title,
    required this.summary,
    required this.missingFields,
    required this.createdAt,
    this.payload = const {},
    this.lifecycle,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'ownerUserId': ownerUserId,
      'targetType': targetType.name,
      'title': title,
      'summary': summary,
      'missingFields': missingFields,
      'createdAt': createdAt.toIso8601String(),
      'payload': payload,
      'lifecycle': lifecycle?.toJson(),
    };
  }

  factory OrganizerReviewItem.fromJson(Map<String, dynamic> json) {
    return OrganizerReviewItem(
      id: (json['id'] ?? '').toString(),
      sourceId: (json['sourceId'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? '').toString(),
      targetType: IntakeEntityType.values.firstWhere(
        (value) => value.name == json['targetType'],
        orElse: () => IntakeEntityType.review,
      ),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      missingFields: List<String>.from(json['missingFields'] ?? const []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: Map<String, dynamic>.from(json['payload'] ?? const {}),
      lifecycle: json['lifecycle'] is Map
          ? ArtifactLifecycleMetadata.fromJson(
              Map<String, dynamic>.from(json['lifecycle'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        ownerUserId,
        targetType,
        title,
        summary,
        missingFields,
        createdAt,
        payload,
        lifecycle,
      ];
}

class IntakeMaterializationResult extends Equatable {
  final IntakeRouteDecision decision;
  final String? spotId;
  final String? eventId;
  final String? communityId;
  final OrganizerReviewItem? reviewItem;

  const IntakeMaterializationResult({
    required this.decision,
    this.spotId,
    this.eventId,
    this.communityId,
    this.reviewItem,
  });

  @override
  List<Object?> get props => [
        decision,
        spotId,
        eventId,
        communityId,
        reviewItem,
      ];
}

const Object _intakeSentinel = Object();
