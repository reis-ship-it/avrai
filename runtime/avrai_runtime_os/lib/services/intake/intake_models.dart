import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';

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

  const ExternalSyncJob({
    required this.id,
    required this.sourceId,
    required this.startedAt,
    required this.updatedAt,
    this.state = ExternalSyncState.pending,
    this.failureReason,
    this.importedCount = 0,
    this.reviewCount = 0,
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
