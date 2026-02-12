import 'package:equatable/equatable.dart';

/// Community Model
///
/// Represents communities that form from events (people who attend together).
///
/// This model lives in `spots_core` so other packages can depend on it without
/// importing the main app package.
enum OriginatingEventType {
  communityEvent,
  expertiseEvent,
}

enum ActivityLevel {
  active,
  growing,
  stable,
  declining,
}

class Community extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String category;

  /// Link to originating event
  final String originatingEventId;
  final OriginatingEventType originatingEventType;

  /// Track members
  final List<String> memberIds;
  final int memberCount;
  final String founderId;

  /// Track events
  final List<String> eventIds;
  final int eventCount;

  /// Track growth
  final double memberGrowthRate;
  final double eventGrowthRate;
  final DateTime createdAt;
  final DateTime? lastEventAt;

  /// Store community metrics
  final double engagementScore;
  final double diversityScore;
  final ActivityLevel activityLevel;

  /// Geographic tracking
  final String originalLocality;
  final List<String> currentLocalities;

  /// Privacy-safe, aggregated community vibe centroid (12D).
  final Map<String, double>? vibeCentroidDimensions;

  /// Number of contributors included in `vibeCentroidDimensions`.
  final int vibeCentroidContributors;

  final DateTime updatedAt;

  const Community({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.originatingEventId,
    required this.originatingEventType,
    this.memberIds = const [],
    this.memberCount = 0,
    required this.founderId,
    this.eventIds = const [],
    this.eventCount = 0,
    this.memberGrowthRate = 0.0,
    this.eventGrowthRate = 0.0,
    required this.createdAt,
    this.lastEventAt,
    this.engagementScore = 0.0,
    this.diversityScore = 0.0,
    this.activityLevel = ActivityLevel.active,
    required this.originalLocality,
    this.currentLocalities = const [],
    this.vibeCentroidDimensions,
    this.vibeCentroidContributors = 0,
    required this.updatedAt,
  });

  bool isMember(String userId) => memberIds.contains(userId);
  bool isFounder(String userId) => founderId == userId;
  bool get hasEvents => eventCount > 0;
  bool get isGrowing => memberGrowthRate > 0.0 || eventGrowthRate > 0.0;

  /// Returns display name for activity level
  String getActivityLevelDisplayName() {
    switch (activityLevel) {
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.growing:
        return 'Growing';
      case ActivityLevel.stable:
        return 'Stable';
      case ActivityLevel.declining:
        return 'Declining';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'originatingEventId': originatingEventId,
      'originatingEventType': originatingEventType.name,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'founderId': founderId,
      'eventIds': eventIds,
      'eventCount': eventCount,
      'memberGrowthRate': memberGrowthRate,
      'eventGrowthRate': eventGrowthRate,
      'createdAt': createdAt.toIso8601String(),
      'lastEventAt': lastEventAt?.toIso8601String(),
      'engagementScore': engagementScore,
      'diversityScore': diversityScore,
      'activityLevel': activityLevel.name,
      'originalLocality': originalLocality,
      'currentLocalities': currentLocalities,
      'vibeCentroidDimensions': vibeCentroidDimensions,
      'vibeCentroidContributors': vibeCentroidContributors,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    Map<String, double>? parseDoubleMap(Object? raw) {
      if (raw is! Map) return null;
      final out = <String, double>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is num) {
          out[key] = value.toDouble();
        }
      }
      return out.isEmpty ? null : out;
    }

    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      originatingEventId: json['originatingEventId'] as String,
      originatingEventType: OriginatingEventType.values.firstWhere(
        (type) => type.name == json['originatingEventType'],
        orElse: () => OriginatingEventType.communityEvent,
      ),
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      memberCount: json['memberCount'] as int? ?? 0,
      founderId: json['founderId'] as String,
      eventIds: List<String>.from(json['eventIds'] as List? ?? []),
      eventCount: json['eventCount'] as int? ?? 0,
      memberGrowthRate: (json['memberGrowthRate'] as num?)?.toDouble() ?? 0.0,
      eventGrowthRate: (json['eventGrowthRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastEventAt: json['lastEventAt'] != null
          ? DateTime.parse(json['lastEventAt'] as String)
          : null,
      engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
      diversityScore: (json['diversityScore'] as num?)?.toDouble() ?? 0.0,
      activityLevel: ActivityLevel.values.firstWhere(
        (level) => level.name == json['activityLevel'],
        orElse: () => ActivityLevel.active,
      ),
      originalLocality: json['originalLocality'] as String,
      currentLocalities:
          List<String>.from(json['currentLocalities'] as List? ?? []),
      vibeCentroidDimensions: parseDoubleMap(json['vibeCentroidDimensions']),
      vibeCentroidContributors: json['vibeCentroidContributors'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? originatingEventId,
    OriginatingEventType? originatingEventType,
    List<String>? memberIds,
    int? memberCount,
    String? founderId,
    List<String>? eventIds,
    int? eventCount,
    double? memberGrowthRate,
    double? eventGrowthRate,
    DateTime? createdAt,
    DateTime? lastEventAt,
    double? engagementScore,
    double? diversityScore,
    ActivityLevel? activityLevel,
    String? originalLocality,
    List<String>? currentLocalities,
    Map<String, double>? vibeCentroidDimensions,
    bool clearVibeCentroidDimensions = false,
    int? vibeCentroidContributors,
    DateTime? updatedAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      originatingEventId: originatingEventId ?? this.originatingEventId,
      originatingEventType: originatingEventType ?? this.originatingEventType,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      founderId: founderId ?? this.founderId,
      eventIds: eventIds ?? this.eventIds,
      eventCount: eventCount ?? this.eventCount,
      memberGrowthRate: memberGrowthRate ?? this.memberGrowthRate,
      eventGrowthRate: eventGrowthRate ?? this.eventGrowthRate,
      createdAt: createdAt ?? this.createdAt,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      engagementScore: engagementScore ?? this.engagementScore,
      diversityScore: diversityScore ?? this.diversityScore,
      activityLevel: activityLevel ?? this.activityLevel,
      originalLocality: originalLocality ?? this.originalLocality,
      currentLocalities: currentLocalities ?? this.currentLocalities,
      vibeCentroidDimensions: clearVibeCentroidDimensions
          ? null
          : (vibeCentroidDimensions ?? this.vibeCentroidDimensions),
      vibeCentroidContributors:
          vibeCentroidContributors ?? this.vibeCentroidContributors,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        originatingEventId,
        originatingEventType,
        memberIds,
        memberCount,
        founderId,
        eventIds,
        eventCount,
        memberGrowthRate,
        eventGrowthRate,
        createdAt,
        lastEventAt,
        engagementScore,
        diversityScore,
        activityLevel,
        originalLocality,
        currentLocalities,
        vibeCentroidDimensions,
        vibeCentroidContributors,
        updatedAt,
      ];
}

