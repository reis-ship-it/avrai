import 'package:avrai_core/models/discovery/discovery_models.dart';

class DailySerendipityDropStorage {
  static const int schemaVersion = 3;
  static const String latestDropKey = 'latest_daily_serendipity_drop_v3';

  const DailySerendipityDropStorage._();
}

class DailySerendipityDrop {
  final int schemaVersion;
  final DateTime date;
  final String cityName;
  final String llmContextualInsight;
  final DateTime generatedAtUtc;
  final DateTime expiresAtUtc;
  final String refreshReason;
  final DropSpot spot;
  final DropList list;
  final DropEvent event;
  final DropClub club;
  final DropCommunity community;

  const DailySerendipityDrop({
    this.schemaVersion = DailySerendipityDropStorage.schemaVersion,
    required this.date,
    required this.cityName,
    required this.llmContextualInsight,
    required this.generatedAtUtc,
    required this.expiresAtUtc,
    required this.refreshReason,
    required this.spot,
    required this.list,
    required this.event,
    required this.club,
    required this.community,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'date': date.toUtc().toIso8601String(),
      'cityName': cityName,
      'llmContextualInsight': llmContextualInsight,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
      'refreshReason': refreshReason,
      'spot': spot.toJson(),
      'list': list.toJson(),
      'event': event.toJson(),
      'club': club.toJson(),
      'community': community.toJson(),
    };
  }

  factory DailySerendipityDrop.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (schemaVersion != DailySerendipityDropStorage.schemaVersion) {
      throw FormatException(
        'Unsupported daily drop schema version: $schemaVersion',
      );
    }

    return DailySerendipityDrop(
      schemaVersion: schemaVersion,
      date: DateTime.parse(json['date'] as String).toUtc(),
      cityName: json['cityName'] as String? ?? 'Birmingham',
      llmContextualInsight: json['llmContextualInsight'] as String? ?? '',
      generatedAtUtc: DateTime.parse(json['generatedAtUtc'] as String).toUtc(),
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
      refreshReason: json['refreshReason'] as String? ?? 'scheduled_refresh',
      spot: DropSpot.fromJson(Map<String, dynamic>.from(
        json['spot'] as Map? ?? const <String, dynamic>{},
      )),
      list: DropList.fromJson(Map<String, dynamic>.from(
        json['list'] as Map? ?? const <String, dynamic>{},
      )),
      event: DropEvent.fromJson(Map<String, dynamic>.from(
        json['event'] as Map? ?? const <String, dynamic>{},
      )),
      club: DropClub.fromJson(Map<String, dynamic>.from(
        json['club'] as Map? ?? const <String, dynamic>{},
      )),
      community: DropCommunity.fromJson(Map<String, dynamic>.from(
        json['community'] as Map? ?? const <String, dynamic>{},
      )),
    );
  }
}

abstract class DropItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? signatureSummary;
  final double archetypeAffinity;
  final bool isPlaceholder;
  final bool generatedByAi;
  final String? placeholderReason;
  final DiscoveryEntityReference objectRef;
  final RecommendationAttribution attribution;
  final bool isSaved;

  const DropItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.signatureSummary,
    required this.archetypeAffinity,
    required this.objectRef,
    required this.attribution,
    this.isSaved = false,
    this.isPlaceholder = false,
    this.generatedByAi = false,
    this.placeholderReason,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'signatureSummary': signatureSummary,
      'archetypeAffinity': archetypeAffinity,
      'objectRef': objectRef.toJson(),
      'attribution': attribution.toJson(),
      'isSaved': isSaved,
      'isPlaceholder': isPlaceholder,
      'generatedByAi': generatedByAi,
      'placeholderReason': placeholderReason,
      'type': runtimeType.toString(),
    };
  }
}

class DropEvent extends DropItem {
  final DateTime time;
  final String locationName;

  const DropEvent({
    required super.id,
    required super.title,
    required super.subtitle,
    super.imageUrl,
    super.signatureSummary,
    required super.archetypeAffinity,
    required super.objectRef,
    required super.attribution,
    super.isSaved,
    super.isPlaceholder,
    super.generatedByAi,
    super.placeholderReason,
    required this.time,
    required this.locationName,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['time'] = time.toUtc().toIso8601String();
    map['locationName'] = locationName;
    return map;
  }

  factory DropEvent.fromJson(Map<String, dynamic> json) {
    return DropEvent(
      id: json['id'] as String? ?? 'event',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      signatureSummary: json['signatureSummary'] as String?,
      archetypeAffinity: (json['archetypeAffinity'] as num?)?.toDouble() ?? 0.0,
      objectRef: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['objectRef'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      attribution: RecommendationAttribution.fromJson(
        Map<String, dynamic>.from(
          json['attribution'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      isSaved: json['isSaved'] as bool? ?? false,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      placeholderReason: json['placeholderReason'] as String?,
      time: DateTime.tryParse(json['time'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      locationName: json['locationName'] as String? ?? '',
    );
  }
}

class DropSpot extends DropItem {
  final String category;
  final double distanceMiles;

  const DropSpot({
    required super.id,
    required super.title,
    required super.subtitle,
    super.imageUrl,
    super.signatureSummary,
    required super.archetypeAffinity,
    required super.objectRef,
    required super.attribution,
    super.isSaved,
    super.isPlaceholder,
    super.generatedByAi,
    super.placeholderReason,
    required this.category,
    required this.distanceMiles,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['category'] = category;
    map['distanceMiles'] = distanceMiles;
    return map;
  }

  factory DropSpot.fromJson(Map<String, dynamic> json) {
    return DropSpot(
      id: json['id'] as String? ?? 'spot',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      signatureSummary: json['signatureSummary'] as String?,
      archetypeAffinity: (json['archetypeAffinity'] as num?)?.toDouble() ?? 0.0,
      objectRef: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['objectRef'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      attribution: RecommendationAttribution.fromJson(
        Map<String, dynamic>.from(
          json['attribution'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      isSaved: json['isSaved'] as bool? ?? false,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      placeholderReason: json['placeholderReason'] as String?,
      category: json['category'] as String? ?? '',
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DropList extends DropItem {
  final int itemCount;
  final String curatorNote;

  const DropList({
    required super.id,
    required super.title,
    required super.subtitle,
    super.imageUrl,
    super.signatureSummary,
    required super.archetypeAffinity,
    required super.objectRef,
    required super.attribution,
    super.isSaved,
    super.isPlaceholder,
    super.generatedByAi,
    super.placeholderReason,
    required this.itemCount,
    required this.curatorNote,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['itemCount'] = itemCount;
    map['curatorNote'] = curatorNote;
    return map;
  }

  factory DropList.fromJson(Map<String, dynamic> json) {
    return DropList(
      id: json['id'] as String? ?? 'list',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      signatureSummary: json['signatureSummary'] as String?,
      archetypeAffinity: (json['archetypeAffinity'] as num?)?.toDouble() ?? 0.0,
      objectRef: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['objectRef'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      attribution: RecommendationAttribution.fromJson(
        Map<String, dynamic>.from(
          json['attribution'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      isSaved: json['isSaved'] as bool? ?? false,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      placeholderReason: json['placeholderReason'] as String?,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      curatorNote: json['curatorNote'] as String? ?? '',
    );
  }
}

class DropCommunity extends DropItem {
  final int memberCount;
  final List<String> commonInterests;

  const DropCommunity({
    required super.id,
    required super.title,
    required super.subtitle,
    super.imageUrl,
    super.signatureSummary,
    required super.archetypeAffinity,
    required super.objectRef,
    required super.attribution,
    super.isSaved,
    super.isPlaceholder,
    super.generatedByAi,
    super.placeholderReason,
    required this.memberCount,
    required this.commonInterests,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['memberCount'] = memberCount;
    map['commonInterests'] = commonInterests;
    return map;
  }

  factory DropCommunity.fromJson(Map<String, dynamic> json) {
    return DropCommunity(
      id: json['id'] as String? ?? 'community',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      signatureSummary: json['signatureSummary'] as String?,
      archetypeAffinity: (json['archetypeAffinity'] as num?)?.toDouble() ?? 0.0,
      objectRef: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['objectRef'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      attribution: RecommendationAttribution.fromJson(
        Map<String, dynamic>.from(
          json['attribution'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      isSaved: json['isSaved'] as bool? ?? false,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      placeholderReason: json['placeholderReason'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      commonInterests: List<String>.from(
        json['commonInterests'] as List? ?? const <String>[],
      ),
    );
  }
}

class DropClub extends DropItem {
  final String applicationStatus;
  final String vibe;

  const DropClub({
    required super.id,
    required super.title,
    required super.subtitle,
    super.imageUrl,
    super.signatureSummary,
    required super.archetypeAffinity,
    required super.objectRef,
    required super.attribution,
    super.isSaved,
    super.isPlaceholder,
    super.generatedByAi,
    super.placeholderReason,
    required this.applicationStatus,
    required this.vibe,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['applicationStatus'] = applicationStatus;
    map['vibe'] = vibe;
    return map;
  }

  factory DropClub.fromJson(Map<String, dynamic> json) {
    return DropClub(
      id: json['id'] as String? ?? 'club',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      signatureSummary: json['signatureSummary'] as String?,
      archetypeAffinity: (json['archetypeAffinity'] as num?)?.toDouble() ?? 0.0,
      objectRef: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['objectRef'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      attribution: RecommendationAttribution.fromJson(
        Map<String, dynamic>.from(
          json['attribution'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      isSaved: json['isSaved'] as bool? ?? false,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      placeholderReason: json['placeholderReason'] as String?,
      applicationStatus: json['applicationStatus'] as String? ?? '',
      vibe: json['vibe'] as String? ?? '',
    );
  }
}
