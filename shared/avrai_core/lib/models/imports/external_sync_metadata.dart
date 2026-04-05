import 'package:equatable/equatable.dart';

enum ExternalSyncState {
  pending,
  active,
  needsReview,
  stale,
  failed,
  paused,
}

enum ExternalConnectionMode {
  url,
  feed,
  api,
  oauth,
  emailList,
  manual,
}

/// Metadata that tracks a one-way imported entity's source and sync lifecycle.
class ExternalSyncMetadata extends Equatable {
  final String sourceProvider;
  final String? sourceUrl;
  final String? externalId;
  final ExternalSyncState syncState;
  final ExternalConnectionMode connectionMode;
  final DateTime? lastSyncedAt;
  final DateTime? importedAt;
  final bool isImported;
  final bool needsReview;
  final String? ownerUserId;
  final bool isClaimable;
  final String? cityCode;
  final String? localityCode;
  final String? sourceLabel;
  final String? syncNotes;

  const ExternalSyncMetadata({
    required this.sourceProvider,
    this.sourceUrl,
    this.externalId,
    this.syncState = ExternalSyncState.pending,
    this.connectionMode = ExternalConnectionMode.manual,
    this.lastSyncedAt,
    this.importedAt,
    this.isImported = true,
    this.needsReview = false,
    this.ownerUserId,
    this.isClaimable = false,
    this.cityCode,
    this.localityCode,
    this.sourceLabel,
    this.syncNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceProvider': sourceProvider,
      'sourceUrl': sourceUrl,
      'externalId': externalId,
      'syncState': syncState.name,
      'connectionMode': connectionMode.name,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'importedAt': importedAt?.toIso8601String(),
      'isImported': isImported,
      'needsReview': needsReview,
      'ownerUserId': ownerUserId,
      'isClaimable': isClaimable,
      'cityCode': cityCode,
      'localityCode': localityCode,
      'sourceLabel': sourceLabel,
      'syncNotes': syncNotes,
    };
  }

  factory ExternalSyncMetadata.fromJson(Map<String, dynamic> json) {
    return ExternalSyncMetadata(
      sourceProvider: (json['sourceProvider'] ?? 'external').toString(),
      sourceUrl: json['sourceUrl'] as String?,
      externalId: json['externalId'] as String?,
      syncState: ExternalSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => ExternalSyncState.pending,
      ),
      connectionMode: ExternalConnectionMode.values.firstWhere(
        (value) => value.name == json['connectionMode'],
        orElse: () => ExternalConnectionMode.manual,
      ),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      importedAt: json['importedAt'] != null
          ? DateTime.tryParse(json['importedAt'] as String)
          : null,
      isImported: json['isImported'] as bool? ?? true,
      needsReview: json['needsReview'] as bool? ?? false,
      ownerUserId: json['ownerUserId'] as String?,
      isClaimable: json['isClaimable'] as bool? ?? false,
      cityCode: json['cityCode'] as String?,
      localityCode: json['localityCode'] as String?,
      sourceLabel: json['sourceLabel'] as String?,
      syncNotes: json['syncNotes'] as String?,
    );
  }

  ExternalSyncMetadata copyWith({
    String? sourceProvider,
    Object? sourceUrl = _sentinel,
    Object? externalId = _sentinel,
    ExternalSyncState? syncState,
    ExternalConnectionMode? connectionMode,
    Object? lastSyncedAt = _sentinel,
    Object? importedAt = _sentinel,
    bool? isImported,
    bool? needsReview,
    Object? ownerUserId = _sentinel,
    bool? isClaimable,
    Object? cityCode = _sentinel,
    Object? localityCode = _sentinel,
    Object? sourceLabel = _sentinel,
    Object? syncNotes = _sentinel,
  }) {
    return ExternalSyncMetadata(
      sourceProvider: sourceProvider ?? this.sourceProvider,
      sourceUrl: sourceUrl == _sentinel ? this.sourceUrl : sourceUrl as String?,
      externalId:
          externalId == _sentinel ? this.externalId : externalId as String?,
      syncState: syncState ?? this.syncState,
      connectionMode: connectionMode ?? this.connectionMode,
      lastSyncedAt: lastSyncedAt == _sentinel
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      importedAt:
          importedAt == _sentinel ? this.importedAt : importedAt as DateTime?,
      isImported: isImported ?? this.isImported,
      needsReview: needsReview ?? this.needsReview,
      ownerUserId:
          ownerUserId == _sentinel ? this.ownerUserId : ownerUserId as String?,
      isClaimable: isClaimable ?? this.isClaimable,
      cityCode: cityCode == _sentinel ? this.cityCode : cityCode as String?,
      localityCode: localityCode == _sentinel
          ? this.localityCode
          : localityCode as String?,
      sourceLabel:
          sourceLabel == _sentinel ? this.sourceLabel : sourceLabel as String?,
      syncNotes: syncNotes == _sentinel ? this.syncNotes : syncNotes as String?,
    );
  }

  @override
  List<Object?> get props => [
        sourceProvider,
        sourceUrl,
        externalId,
        syncState,
        connectionMode,
        lastSyncedAt,
        importedAt,
        isImported,
        needsReview,
        ownerUserId,
        isClaimable,
        cityCode,
        localityCode,
        sourceLabel,
        syncNotes,
      ];
}

const Object _sentinel = Object();
