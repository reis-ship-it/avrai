import 'package:equatable/equatable.dart';

/// OUR_GUTS.md: "The key adapts to how YOU use it"
/// Philosophy: Track usage patterns, not just personality
/// Users engage with SPOTS differently - some want quick recommendations,
/// others want community discovery. The AI should adapt.
class UsagePattern extends Equatable {
  final String userId;
  
  // How does user engage with SPOTS?
  final double recommendationFocus;  // 0.0-1.0: Quick spot suggestions
  final double communityFocus;       // 0.0-1.0: Events, groups, third places
  final double eventEngagement;      // 0.0-1.0: Event attendance rate
  final double spotLoyalty;          // 0.0-1.0: Return to favorites vs. explore new
  
  // When are they receptive?
  final Map<String, double> receptivityByContext;  // work, social, exploration
  final Map<String, double> receptivityByTime;     // morning, afternoon, evening, night
  
  // What doors have they opened?
  final List<String> openedDoorTypes;  // 'spots', 'communities', 'events', 'people'
  final Map<String, int> doorTypeFrequency;
  
  // Engagement metrics
  final int totalSpotVisits;
  final int totalEventsAttended;
  final int totalCommunitiesJoined;
  final int daysActive;
  
  // Learning metadata
  final DateTime firstUsed;
  final DateTime lastUpdated;
  final int updateCount;
  
  const UsagePattern({
    required this.userId,
    this.recommendationFocus = 0.5,
    this.communityFocus = 0.5,
    this.eventEngagement = 0.0,
    this.spotLoyalty = 0.5,
    this.receptivityByContext = const {},
    this.receptivityByTime = const {},
    this.openedDoorTypes = const [],
    this.doorTypeFrequency = const {},
    this.totalSpotVisits = 0,
    this.totalEventsAttended = 0,
    this.totalCommunitiesJoined = 0,
    this.daysActive = 0,
    required this.firstUsed,
    required this.lastUpdated,
    this.updateCount = 0,
  });
  
  /// Get primary usage mode
  UsageMode get primaryMode {
    if (recommendationFocus > 0.7) return UsageMode.recommendations;
    if (communityFocus > 0.7) return UsageMode.community;
    if (eventEngagement > 0.7) return UsageMode.events;
    return UsageMode.balanced;
  }
  
  /// Check if user is receptive right now
  bool isReceptiveNow(String context) {
    final timeOfDay = _getTimeOfDay();
    
    final contextReceptivity = receptivityByContext[context] ?? 0.5;
    final timeReceptivity = receptivityByTime[timeOfDay] ?? 0.5;
    
    // Combined receptivity
    return (contextReceptivity + timeReceptivity) / 2 > 0.6;
  }
  
  /// Get most opened door type
  String? get favoriteDoOrType {
    if (doorTypeFrequency.isEmpty) return null;
    
    return doorTypeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  /// Calculate engagement score (0.0-1.0)
  double get engagementScore {
    final spotScore = totalSpotVisits > 0 ? 1.0 : 0.0;
    final eventScore = totalEventsAttended > 0 ? 1.0 : 0.0;
    final communityScore = totalCommunitiesJoined > 0 ? 1.0 : 0.0;
    final activeScore = daysActive > 7 ? 1.0 : (daysActive / 7.0);
    
    return (spotScore + eventScore + communityScore + activeScore) / 4.0;
  }
  
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    if (hour < 22) return 'evening';
    return 'night';
  }
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'recommendationFocus': recommendationFocus,
    'communityFocus': communityFocus,
    'eventEngagement': eventEngagement,
    'spotLoyalty': spotLoyalty,
    'receptivityByContext': receptivityByContext,
    'receptivityByTime': receptivityByTime,
    'openedDoorTypes': openedDoorTypes,
    'doorTypeFrequency': doorTypeFrequency,
    'totalSpotVisits': totalSpotVisits,
    'totalEventsAttended': totalEventsAttended,
    'totalCommunitiesJoined': totalCommunitiesJoined,
    'daysActive': daysActive,
    'firstUsed': firstUsed.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'updateCount': updateCount,
  };
  
  factory UsagePattern.fromJson(Map<String, dynamic> json) {
    return UsagePattern(
      userId: json['userId'],
      recommendationFocus: (json['recommendationFocus'] as num?)?.toDouble() ?? 0.5,
      communityFocus: (json['communityFocus'] as num?)?.toDouble() ?? 0.5,
      eventEngagement: (json['eventEngagement'] as num?)?.toDouble() ?? 0.0,
      spotLoyalty: (json['spotLoyalty'] as num?)?.toDouble() ?? 0.5,
      receptivityByContext: Map<String, double>.from(json['receptivityByContext'] ?? {}),
      receptivityByTime: Map<String, double>.from(json['receptivityByTime'] ?? {}),
      openedDoorTypes: List<String>.from(json['openedDoorTypes'] ?? []),
      doorTypeFrequency: Map<String, int>.from(json['doorTypeFrequency'] ?? {}),
      totalSpotVisits: (json['totalSpotVisits'] as num?)?.toInt() ?? 0,
      totalEventsAttended: (json['totalEventsAttended'] as num?)?.toInt() ?? 0,
      totalCommunitiesJoined: (json['totalCommunitiesJoined'] as num?)?.toInt() ?? 0,
      daysActive: (json['daysActive'] as num?)?.toInt() ?? 0,
      firstUsed: DateTime.parse(json['firstUsed']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      updateCount: (json['updateCount'] as num?)?.toInt() ?? 0,
    );
  }
  
  UsagePattern copyWith({
    String? userId,
    double? recommendationFocus,
    double? communityFocus,
    double? eventEngagement,
    double? spotLoyalty,
    Map<String, double>? receptivityByContext,
    Map<String, double>? receptivityByTime,
    List<String>? openedDoorTypes,
    Map<String, int>? doorTypeFrequency,
    int? totalSpotVisits,
    int? totalEventsAttended,
    int? totalCommunitiesJoined,
    int? daysActive,
    DateTime? firstUsed,
    DateTime? lastUpdated,
    int? updateCount,
  }) {
    return UsagePattern(
      userId: userId ?? this.userId,
      recommendationFocus: recommendationFocus ?? this.recommendationFocus,
      communityFocus: communityFocus ?? this.communityFocus,
      eventEngagement: eventEngagement ?? this.eventEngagement,
      spotLoyalty: spotLoyalty ?? this.spotLoyalty,
      receptivityByContext: receptivityByContext ?? this.receptivityByContext,
      receptivityByTime: receptivityByTime ?? this.receptivityByTime,
      openedDoorTypes: openedDoorTypes ?? this.openedDoorTypes,
      doorTypeFrequency: doorTypeFrequency ?? this.doorTypeFrequency,
      totalSpotVisits: totalSpotVisits ?? this.totalSpotVisits,
      totalEventsAttended: totalEventsAttended ?? this.totalEventsAttended,
      totalCommunitiesJoined: totalCommunitiesJoined ?? this.totalCommunitiesJoined,
      daysActive: daysActive ?? this.daysActive,
      firstUsed: firstUsed ?? this.firstUsed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updateCount: updateCount ?? this.updateCount,
    );
  }
  
  @override
  List<Object?> get props => [
    userId,
    recommendationFocus,
    communityFocus,
    eventEngagement,
    spotLoyalty,
    receptivityByContext,
    receptivityByTime,
    openedDoorTypes,
    doorTypeFrequency,
    totalSpotVisits,
    totalEventsAttended,
    totalCommunitiesJoined,
    daysActive,
    firstUsed,
    lastUpdated,
    updateCount,
  ];
}

/// Usage mode classification
enum UsageMode {
  recommendations,  // Quick spot suggestions
  community,        // Community discovery
  events,           // Event-focused
  balanced,         // Balanced usage
}

/// Receptivity context
enum ReceptivityContext {
  work,           // At work, need quick suggestions
  social,         // Social time, open to discovery
  exploration,    // Actively exploring
  routine,        // Regular patterns
  transition,     // Between activities
}

