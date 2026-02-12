/// Visit Pattern Model
///
/// Represents a user's visit to a location with atomic timestamp precision.
/// Used for learning timing preferences and behavioral patterns.
///
/// Part of Phase 1: Core Models for Perpetual List Orchestrator
library;

/// Time slot categories for visit timing analysis
enum TimeSlot {
  /// 5am - 8am
  earlyMorning,

  /// 8am - 12pm
  morning,

  /// 12pm - 5pm
  afternoon,

  /// 5pm - 9pm
  evening,

  /// 9pm - 12am
  night,

  /// 12am - 5am
  lateNight,
}

/// Days of the week
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Record of a user's visit to a location
class VisitPattern {
  /// Unique identifier for this visit
  final String id;

  /// User ID (for storage/lookup)
  final String userId;

  /// Place ID from Google Places or Apple Maps (if matched)
  final String? placeId;

  /// Name of the place (if matched)
  final String? placeName;

  /// Category of the place (coffee, bar, museum, etc.)
  final String category;

  /// Latitude of the visit
  final double latitude;

  /// Longitude of the visit
  final double longitude;

  /// Atomic timestamp of the visit (drift-corrected)
  final DateTime atomicTimestamp;

  /// How long the user stayed
  final Duration dwellTime;

  /// Day of the week
  final DayOfWeek dayOfWeek;

  /// Time slot category
  final TimeSlot timeSlot;

  /// Whether this is a repeat visit to this place
  final bool isRepeatVisit;

  /// Total number of visits to this place (including this one)
  final int visitFrequency;

  /// Time since last visit to this place
  final Duration? timeSinceLastVisit;

  /// Estimated group size (1 = solo, 2+ = group)
  final int groupSize;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  const VisitPattern({
    required this.id,
    required this.userId,
    this.placeId,
    this.placeName,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.atomicTimestamp,
    required this.dwellTime,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.isRepeatVisit,
    required this.visitFrequency,
    this.timeSinceLastVisit,
    required this.groupSize,
    this.metadata = const {},
  });

  /// Check if this is a solo visit
  bool get isSoloVisit => groupSize == 1;

  /// Check if this is a group visit
  bool get isGroupVisit => groupSize > 1;

  /// Check if this was a short visit (< 15 minutes)
  bool get isShortVisit => dwellTime.inMinutes < 15;

  /// Check if this was a long visit (> 2 hours)
  bool get isLongVisit => dwellTime.inHours >= 2;

  /// Check if this is a weekend visit
  bool get isWeekend =>
      dayOfWeek == DayOfWeek.saturday || dayOfWeek == DayOfWeek.sunday;

  /// Get hour of visit (0-23)
  int get hourOfVisit => atomicTimestamp.hour;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'placeId': placeId,
      'placeName': placeName,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'atomicTimestamp': atomicTimestamp.toIso8601String(),
      'dwellTimeMinutes': dwellTime.inMinutes,
      'dayOfWeek': dayOfWeek.name,
      'timeSlot': timeSlot.name,
      'isRepeatVisit': isRepeatVisit,
      'visitFrequency': visitFrequency,
      'timeSinceLastVisitMinutes': timeSinceLastVisit?.inMinutes,
      'groupSize': groupSize,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory VisitPattern.fromJson(Map<String, dynamic> json) {
    return VisitPattern(
      id: json['id'] as String,
      userId: json['userId'] as String,
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] as String?,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      atomicTimestamp: DateTime.parse(json['atomicTimestamp'] as String),
      dwellTime: Duration(minutes: json['dwellTimeMinutes'] as int),
      dayOfWeek: DayOfWeek.values.firstWhere(
        (d) => d.name == json['dayOfWeek'],
        orElse: () => DayOfWeek.monday,
      ),
      timeSlot: TimeSlot.values.firstWhere(
        (t) => t.name == json['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
      isRepeatVisit: json['isRepeatVisit'] as bool? ?? false,
      visitFrequency: json['visitFrequency'] as int? ?? 1,
      timeSinceLastVisit: json['timeSinceLastVisitMinutes'] != null
          ? Duration(minutes: json['timeSinceLastVisitMinutes'] as int)
          : null,
      groupSize: json['groupSize'] as int? ?? 1,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'VisitPattern(${placeName ?? category} at ${timeSlot.name} on ${dayOfWeek.name})';
  }
}

/// Timing preferences derived from visit patterns
class TimingPreferences {
  /// Preferred time slot for each category
  final Map<String, TimeSlot> categoryPreferredTimes;

  /// Preferred day for each category
  final Map<String, DayOfWeek> categoryPreferredDays;

  /// Average dwell time per category
  final Map<String, Duration> categoryAvgDwellTime;

  /// Peak activity windows (time ranges with most visits)
  final List<ActivityWindow> peakActivityWindows;

  /// Ratio of weekend to weekday visits (0.0 to 1.0)
  final double weekendVsWeekdayRatio;

  const TimingPreferences({
    this.categoryPreferredTimes = const {},
    this.categoryPreferredDays = const {},
    this.categoryAvgDwellTime = const {},
    this.peakActivityWindows = const [],
    this.weekendVsWeekdayRatio = 0.5,
  });

  /// Default preferences for new users
  factory TimingPreferences.defaults() {
    return const TimingPreferences(
      weekendVsWeekdayRatio: 0.5,
    );
  }

  /// Check if user prefers weekends
  bool get prefersWeekends => weekendVsWeekdayRatio > 0.6;

  /// Check if user prefers weekdays
  bool get prefersWeekdays => weekendVsWeekdayRatio < 0.4;
}

/// A time window representing peak activity
class ActivityWindow {
  /// Start time of the window
  final TimeSlot startSlot;

  /// Days this window is most active
  final List<DayOfWeek> activeDays;

  /// Strength of activity (0.0 to 1.0)
  final double activityStrength;

  const ActivityWindow({
    required this.startSlot,
    required this.activeDays,
    required this.activityStrength,
  });
}

/// Helper function to get TimeSlot from DateTime
TimeSlot getTimeSlotFromDateTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 8) return TimeSlot.earlyMorning;
  if (hour >= 8 && hour < 12) return TimeSlot.morning;
  if (hour >= 12 && hour < 17) return TimeSlot.afternoon;
  if (hour >= 17 && hour < 21) return TimeSlot.evening;
  if (hour >= 21 && hour < 24) return TimeSlot.night;
  return TimeSlot.lateNight;
}

/// Helper function to get DayOfWeek from DateTime
DayOfWeek getDayOfWeekFromDateTime(DateTime time) {
  // DateTime.weekday returns 1 for Monday, 7 for Sunday
  return DayOfWeek.values[time.weekday - 1];
}
