/// Discovered Spot Candidate Model
///
/// Represents a location the system has organically discovered from user
/// behavior patterns -- places that don't exist in any external maps database
/// but that the user (or multiple users via mesh) repeatedly visit.
///
/// Lifecycle: detected → prompted → created (becomes full Spot) OR dismissed
///
/// Part of Organic Spot Discovery system.
/// See: docs/plans/organic_spot_discovery/ORGANIC_SPOT_DISCOVERY_PLAN.md
///
/// Philosophy: "Every spot is a door." These are doors that haven't been
/// named yet -- the system learns them from how people live.
library;

/// Status of a discovered spot candidate
enum DiscoveredSpotStatus {
  /// System has detected a pattern but threshold not yet met
  detecting,

  /// Threshold met, candidate is ready to surface to user
  ready,

  /// User has been prompted about this location
  prompted,

  /// User created a full Spot from this candidate
  created,

  /// User dismissed this candidate
  dismissed,
}

/// Inferred category based on visit timing and dwell patterns
enum InferredCategory {
  /// Morning visits, moderate dwell (coffee spot, breakfast place)
  morningHangout,

  /// Daytime visits, long dwell (park, workspace, study spot)
  daytimeRetreat,

  /// Evening visits, moderate-long dwell (social spot, gathering place)
  eveningSpot,

  /// Late night visits (late-night hangout)
  lateNightSpot,

  /// Weekend-heavy visits (weekend activity spot)
  weekendSpot,

  /// Short visits, high frequency (errand stop, transit point)
  quickStop,

  /// Long dwell, any time (relaxation spot, scenic viewpoint)
  lingering,

  /// Group visits detected (gathering place, meetup spot)
  gatheringPlace,

  /// Unknown pattern
  unknown,
}

/// A location the system has organically discovered from behavior patterns
class DiscoveredSpotCandidate {
  /// Unique identifier for this candidate
  final String id;

  /// User who triggered the discovery (primary discoverer)
  final String userId;

  /// Centroid latitude of the visit cluster
  final double centroidLatitude;

  /// Centroid longitude of the visit cluster
  final double centroidLongitude;

  /// Geohash at precision 7 (~153m) for clustering
  final String geohash;

  /// Number of visits by the primary user
  final int visitCount;

  /// Number of unique users who have visited (from mesh signals)
  final int uniqueUserCount;

  /// Confidence score (0.0 to 1.0) based on visit frequency, dwell time,
  /// unique users, and pattern consistency
  final double confidence;

  /// Inferred category from timing and dwell patterns
  final InferredCategory inferredCategory;

  /// Current status of this candidate
  final DiscoveredSpotStatus status;

  /// When the first unmatched visit was recorded at this cluster
  final DateTime firstVisitAt;

  /// When the most recent visit was recorded
  final DateTime lastVisitAt;

  /// Average dwell time across all visits (in minutes)
  final int averageDwellMinutes;

  /// Whether visits tend to happen on weekends
  final bool weekendHeavy;

  /// Whether visits tend to happen with groups
  final bool groupVisitsDetected;

  /// Suggested name from reverse geocoding (if available)
  final String? suggestedName;

  /// Suggested address from reverse geocoding (if available)
  final String? suggestedAddress;

  /// ID of the created Spot (if status == created)
  final String? createdSpotId;

  /// Additional metadata for extensibility
  final Map<String, dynamic> metadata;

  const DiscoveredSpotCandidate({
    required this.id,
    required this.userId,
    required this.centroidLatitude,
    required this.centroidLongitude,
    required this.geohash,
    required this.visitCount,
    this.uniqueUserCount = 1,
    required this.confidence,
    required this.inferredCategory,
    required this.status,
    required this.firstVisitAt,
    required this.lastVisitAt,
    required this.averageDwellMinutes,
    this.weekendHeavy = false,
    this.groupVisitsDetected = false,
    this.suggestedName,
    this.suggestedAddress,
    this.createdSpotId,
    this.metadata = const {},
  });

  /// Whether this candidate has reached the threshold for surfacing
  bool get isReadyToSurface =>
      visitCount >= 3 || uniqueUserCount >= 2;

  /// Whether this is a high-confidence discovery
  bool get isHighConfidence => confidence >= 0.7;

  /// Whether this candidate was ever acted on (created or dismissed)
  bool get isResolved =>
      status == DiscoveredSpotStatus.created ||
      status == DiscoveredSpotStatus.dismissed;

  /// Human-readable description of the inferred category
  String get categoryDescription {
    switch (inferredCategory) {
      case InferredCategory.morningHangout:
        return 'Morning hangout';
      case InferredCategory.daytimeRetreat:
        return 'Daytime retreat';
      case InferredCategory.eveningSpot:
        return 'Evening spot';
      case InferredCategory.lateNightSpot:
        return 'Late night spot';
      case InferredCategory.weekendSpot:
        return 'Weekend spot';
      case InferredCategory.quickStop:
        return 'Quick stop';
      case InferredCategory.lingering:
        return 'Place to linger';
      case InferredCategory.gatheringPlace:
        return 'Gathering place';
      case InferredCategory.unknown:
        return 'Interesting place';
    }
  }

  /// Create a copy with updated fields
  DiscoveredSpotCandidate copyWith({
    String? id,
    String? userId,
    double? centroidLatitude,
    double? centroidLongitude,
    String? geohash,
    int? visitCount,
    int? uniqueUserCount,
    double? confidence,
    InferredCategory? inferredCategory,
    DiscoveredSpotStatus? status,
    DateTime? firstVisitAt,
    DateTime? lastVisitAt,
    int? averageDwellMinutes,
    bool? weekendHeavy,
    bool? groupVisitsDetected,
    String? suggestedName,
    String? suggestedAddress,
    String? createdSpotId,
    Map<String, dynamic>? metadata,
  }) {
    return DiscoveredSpotCandidate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      centroidLatitude: centroidLatitude ?? this.centroidLatitude,
      centroidLongitude: centroidLongitude ?? this.centroidLongitude,
      geohash: geohash ?? this.geohash,
      visitCount: visitCount ?? this.visitCount,
      uniqueUserCount: uniqueUserCount ?? this.uniqueUserCount,
      confidence: confidence ?? this.confidence,
      inferredCategory: inferredCategory ?? this.inferredCategory,
      status: status ?? this.status,
      firstVisitAt: firstVisitAt ?? this.firstVisitAt,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      averageDwellMinutes: averageDwellMinutes ?? this.averageDwellMinutes,
      weekendHeavy: weekendHeavy ?? this.weekendHeavy,
      groupVisitsDetected: groupVisitsDetected ?? this.groupVisitsDetected,
      suggestedName: suggestedName ?? this.suggestedName,
      suggestedAddress: suggestedAddress ?? this.suggestedAddress,
      createdSpotId: createdSpotId ?? this.createdSpotId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'centroidLatitude': centroidLatitude,
      'centroidLongitude': centroidLongitude,
      'geohash': geohash,
      'visitCount': visitCount,
      'uniqueUserCount': uniqueUserCount,
      'confidence': confidence,
      'inferredCategory': inferredCategory.name,
      'status': status.name,
      'firstVisitAt': firstVisitAt.toIso8601String(),
      'lastVisitAt': lastVisitAt.toIso8601String(),
      'averageDwellMinutes': averageDwellMinutes,
      'weekendHeavy': weekendHeavy,
      'groupVisitsDetected': groupVisitsDetected,
      'suggestedName': suggestedName,
      'suggestedAddress': suggestedAddress,
      'createdSpotId': createdSpotId,
      'metadata': metadata,
    };
  }

  /// Deserialize from JSON
  factory DiscoveredSpotCandidate.fromJson(Map<String, dynamic> json) {
    return DiscoveredSpotCandidate(
      id: json['id'] as String,
      userId: json['userId'] as String,
      centroidLatitude: (json['centroidLatitude'] as num).toDouble(),
      centroidLongitude: (json['centroidLongitude'] as num).toDouble(),
      geohash: json['geohash'] as String,
      visitCount: json['visitCount'] as int? ?? 1,
      uniqueUserCount: json['uniqueUserCount'] as int? ?? 1,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      inferredCategory: InferredCategory.values.firstWhere(
        (c) => c.name == json['inferredCategory'],
        orElse: () => InferredCategory.unknown,
      ),
      status: DiscoveredSpotStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DiscoveredSpotStatus.detecting,
      ),
      firstVisitAt: DateTime.parse(json['firstVisitAt'] as String),
      lastVisitAt: DateTime.parse(json['lastVisitAt'] as String),
      averageDwellMinutes: json['averageDwellMinutes'] as int? ?? 0,
      weekendHeavy: json['weekendHeavy'] as bool? ?? false,
      groupVisitsDetected: json['groupVisitsDetected'] as bool? ?? false,
      suggestedName: json['suggestedName'] as String?,
      suggestedAddress: json['suggestedAddress'] as String?,
      createdSpotId: json['createdSpotId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'DiscoveredSpotCandidate('
        '${suggestedName ?? geohash}: '
        '$visitCount visits, '
        '$uniqueUserCount users, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'status: ${status.name})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredSpotCandidate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
