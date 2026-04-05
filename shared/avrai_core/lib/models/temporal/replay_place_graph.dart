import 'package:avrai_core/models/temporal/replay_entity_identity.dart';

class ReplayPlaceGraph {
  const ReplayPlaceGraph({
    required this.replayYear,
    required this.nodeCount,
    required this.localityCounts,
    required this.venueCategoryCounts,
    required this.organizationTypeCounts,
    required this.communityCategoryCounts,
    required this.eventCategoryCounts,
    required this.nodes,
    required this.venueProfiles,
    required this.clubProfiles,
    required this.organizationProfiles,
    required this.communityProfiles,
    required this.eventProfiles,
    this.metadata = const <String, dynamic>{},
  });

  final int replayYear;
  final int nodeCount;
  final Map<String, int> localityCounts;
  final Map<String, int> venueCategoryCounts;
  final Map<String, int> organizationTypeCounts;
  final Map<String, int> communityCategoryCounts;
  final Map<String, int> eventCategoryCounts;
  final List<ReplayPlaceGraphNode> nodes;
  final List<ReplayVenueProfile> venueProfiles;
  final List<ReplayClubProfile> clubProfiles;
  final List<ReplayOrganizationProfile> organizationProfiles;
  final List<ReplayCommunityProfile> communityProfiles;
  final List<ReplayEventProfile> eventProfiles;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'replayYear': replayYear,
      'nodeCount': nodeCount,
      'localityCounts': localityCounts,
      'venueCategoryCounts': venueCategoryCounts,
      'organizationTypeCounts': organizationTypeCounts,
      'communityCategoryCounts': communityCategoryCounts,
      'eventCategoryCounts': eventCategoryCounts,
      'nodes': nodes.map((entry) => entry.toJson()).toList(),
      'venueProfiles': venueProfiles.map((entry) => entry.toJson()).toList(),
      'clubProfiles': clubProfiles.map((entry) => entry.toJson()).toList(),
      'organizationProfiles':
          organizationProfiles.map((entry) => entry.toJson()).toList(),
      'communityProfiles':
          communityProfiles.map((entry) => entry.toJson()).toList(),
      'eventProfiles': eventProfiles.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayPlaceGraph.fromJson(Map<String, dynamic> json) {
    return ReplayPlaceGraph(
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      nodeCount: (json['nodeCount'] as num?)?.toInt() ?? 0,
      localityCounts: _readCounts(json['localityCounts']),
      venueCategoryCounts: _readCounts(json['venueCategoryCounts']),
      organizationTypeCounts: _readCounts(json['organizationTypeCounts']),
      communityCategoryCounts: _readCounts(json['communityCategoryCounts']),
      eventCategoryCounts: _readCounts(json['eventCategoryCounts']),
      nodes: (json['nodes'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayPlaceGraphNode.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayPlaceGraphNode>[],
      venueProfiles: (json['venueProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayVenueProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayVenueProfile>[],
      clubProfiles: (json['clubProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayClubProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayClubProfile>[],
      organizationProfiles: (json['organizationProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayOrganizationProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayOrganizationProfile>[],
      communityProfiles: (json['communityProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayCommunityProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayCommunityProfile>[],
      eventProfiles: (json['eventProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayEventProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayEventProfile>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  static Map<String, int> _readCounts(Object? raw) {
    return (raw as Map?)?.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        const <String, int>{};
  }
}

class ReplayPlaceGraphNode {
  const ReplayPlaceGraphNode({
    required this.nodeId,
    required this.identity,
    required this.nodeType,
    required this.localityAnchor,
    required this.statusInReplayYear,
    required this.sourceRefs,
    required this.associatedEntityIds,
    this.venueCategory,
    this.neighborhood,
    this.capacityBand,
    this.recurrenceAffinity,
    this.demandPressureBand,
    this.metadata = const <String, dynamic>{},
  });

  final String nodeId;
  final ReplayEntityIdentity identity;
  final String nodeType;
  final String localityAnchor;
  final String statusInReplayYear;
  final List<String> sourceRefs;
  final List<String> associatedEntityIds;
  final String? venueCategory;
  final String? neighborhood;
  final String? capacityBand;
  final String? recurrenceAffinity;
  final String? demandPressureBand;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nodeId': nodeId,
      'identity': identity.toJson(),
      'nodeType': nodeType,
      'localityAnchor': localityAnchor,
      'statusInReplayYear': statusInReplayYear,
      'sourceRefs': sourceRefs,
      'associatedEntityIds': associatedEntityIds,
      'venueCategory': venueCategory,
      'neighborhood': neighborhood,
      'capacityBand': capacityBand,
      'recurrenceAffinity': recurrenceAffinity,
      'demandPressureBand': demandPressureBand,
      'metadata': metadata,
    };
  }

  factory ReplayPlaceGraphNode.fromJson(Map<String, dynamic> json) {
    return ReplayPlaceGraphNode(
      nodeId: json['nodeId'] as String? ?? '',
      identity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      nodeType: json['nodeType'] as String? ?? 'unknown',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      statusInReplayYear: json['statusInReplayYear'] as String? ?? 'active',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      associatedEntityIds: (json['associatedEntityIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      venueCategory: json['venueCategory'] as String?,
      neighborhood: json['neighborhood'] as String?,
      capacityBand: json['capacityBand'] as String?,
      recurrenceAffinity: json['recurrenceAffinity'] as String?,
      demandPressureBand: json['demandPressureBand'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayVenueProfile {
  const ReplayVenueProfile({
    required this.identity,
    required this.localityAnchor,
    required this.venueCategory,
    required this.capacityBand,
    required this.recurrenceAffinity,
    required this.demandPressureBand,
    required this.sourceRefs,
    this.metadata = const <String, dynamic>{},
  });

  final ReplayEntityIdentity identity;
  final String localityAnchor;
  final String venueCategory;
  final String capacityBand;
  final String recurrenceAffinity;
  final String demandPressureBand;
  final List<String> sourceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identity': identity.toJson(),
      'localityAnchor': localityAnchor,
      'venueCategory': venueCategory,
      'capacityBand': capacityBand,
      'recurrenceAffinity': recurrenceAffinity,
      'demandPressureBand': demandPressureBand,
      'sourceRefs': sourceRefs,
      'metadata': metadata,
    };
  }

  factory ReplayVenueProfile.fromJson(Map<String, dynamic> json) {
    return ReplayVenueProfile(
      identity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      localityAnchor: json['localityAnchor'] as String? ?? '',
      venueCategory: json['venueCategory'] as String? ?? 'unknown',
      capacityBand: json['capacityBand'] as String? ?? 'small',
      recurrenceAffinity: json['recurrenceAffinity'] as String? ?? 'medium',
      demandPressureBand: json['demandPressureBand'] as String? ?? 'moderate',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayOrganizationProfile {
  const ReplayOrganizationProfile({
    required this.organizationId,
    required this.canonicalName,
    required this.organizationType,
    required this.localityAnchor,
    required this.sourceRefs,
    required this.associatedEntityIds,
    this.metadata = const <String, dynamic>{},
  });

  final String organizationId;
  final String canonicalName;
  final String organizationType;
  final String localityAnchor;
  final List<String> sourceRefs;
  final List<String> associatedEntityIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'canonicalName': canonicalName,
      'organizationType': organizationType,
      'localityAnchor': localityAnchor,
      'sourceRefs': sourceRefs,
      'associatedEntityIds': associatedEntityIds,
      'metadata': metadata,
    };
  }

  factory ReplayOrganizationProfile.fromJson(Map<String, dynamic> json) {
    return ReplayOrganizationProfile(
      organizationId: json['organizationId'] as String? ?? '',
      canonicalName: json['canonicalName'] as String? ?? '',
      organizationType: json['organizationType'] as String? ?? 'unknown',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      associatedEntityIds: (json['associatedEntityIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayClubProfile {
  const ReplayClubProfile({
    required this.identity,
    required this.localityAnchor,
    required this.clubCategory,
    required this.hostOrganizationId,
    required this.venueIds,
    required this.eventIds,
    required this.sourceRefs,
    this.metadata = const <String, dynamic>{},
  });

  final ReplayEntityIdentity identity;
  final String localityAnchor;
  final String clubCategory;
  final String? hostOrganizationId;
  final List<String> venueIds;
  final List<String> eventIds;
  final List<String> sourceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identity': identity.toJson(),
      'localityAnchor': localityAnchor,
      'clubCategory': clubCategory,
      'hostOrganizationId': hostOrganizationId,
      'venueIds': venueIds,
      'eventIds': eventIds,
      'sourceRefs': sourceRefs,
      'metadata': metadata,
    };
  }

  factory ReplayClubProfile.fromJson(Map<String, dynamic> json) {
    return ReplayClubProfile(
      identity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      localityAnchor: json['localityAnchor'] as String? ?? '',
      clubCategory: json['clubCategory'] as String? ?? 'general',
      hostOrganizationId: json['hostOrganizationId'] as String?,
      venueIds: (json['venueIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      eventIds: (json['eventIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayCommunityProfile {
  const ReplayCommunityProfile({
    required this.identity,
    required this.localityAnchor,
    required this.communityCategory,
    required this.organizationIds,
    required this.eventIds,
    this.metadata = const <String, dynamic>{},
  });

  final ReplayEntityIdentity identity;
  final String localityAnchor;
  final String communityCategory;
  final List<String> organizationIds;
  final List<String> eventIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identity': identity.toJson(),
      'localityAnchor': localityAnchor,
      'communityCategory': communityCategory,
      'organizationIds': organizationIds,
      'eventIds': eventIds,
      'metadata': metadata,
    };
  }

  factory ReplayCommunityProfile.fromJson(Map<String, dynamic> json) {
    return ReplayCommunityProfile(
      identity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      localityAnchor: json['localityAnchor'] as String? ?? '',
      communityCategory: json['communityCategory'] as String? ?? 'unknown',
      organizationIds: (json['organizationIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      eventIds: (json['eventIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayEventProfile {
  const ReplayEventProfile({
    required this.identity,
    required this.localityAnchor,
    required this.startsAtIso,
    required this.recurrenceClass,
    required this.attendanceBand,
    required this.sourceRefs,
    this.venueId,
    this.organizationId,
    this.metadata = const <String, dynamic>{},
  });

  final ReplayEntityIdentity identity;
  final String localityAnchor;
  final String startsAtIso;
  final String recurrenceClass;
  final String attendanceBand;
  final List<String> sourceRefs;
  final String? venueId;
  final String? organizationId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identity': identity.toJson(),
      'localityAnchor': localityAnchor,
      'startsAtIso': startsAtIso,
      'recurrenceClass': recurrenceClass,
      'attendanceBand': attendanceBand,
      'sourceRefs': sourceRefs,
      'venueId': venueId,
      'organizationId': organizationId,
      'metadata': metadata,
    };
  }

  factory ReplayEventProfile.fromJson(Map<String, dynamic> json) {
    return ReplayEventProfile(
      identity: ReplayEntityIdentity.fromJson(
        Map<String, dynamic>.from(json['identity'] as Map? ?? const {}),
      ),
      localityAnchor: json['localityAnchor'] as String? ?? '',
      startsAtIso: json['startsAtIso'] as String? ?? '',
      recurrenceClass: json['recurrenceClass'] as String? ?? 'one_off',
      attendanceBand: json['attendanceBand'] as String? ?? 'medium',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      venueId: json['venueId'] as String?,
      organizationId: json['organizationId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
