import 'visit_pattern.dart';

/// User Preference Signals Model
///
/// Behavioral preferences derived from visit patterns and personality.
/// Used for intelligent list generation and matching.
///
/// Part of Phase 1: Core Models for Perpetual List Orchestrator

class UserPreferenceSignals {
  /// Category weights based on visit frequency (0.0 to 1.0)
  /// Higher = more visits to this category
  final Map<String, double> categoryWeights;

  /// Average group size for outings
  final double averageGroupSize;

  /// Noise preference (0.0 = quiet, 1.0 = loud)
  /// Derived from crowd_tolerance personality dimension
  final double noisePreference;

  /// Crowd tolerance (0.0 = quiet/intimate, 1.0 = bustling/popular)
  final double crowdTolerance;

  /// Price point preference (0.0 = budget, 1.0 = premium)
  /// Derived from value_orientation personality dimension
  final double pricePointPreference;

  /// Spontaneity level (0.0 = planned, 1.0 = spontaneous)
  /// Derived from temporal_flexibility personality dimension
  final double spontaneityLevel;

  /// Activity weights by time slot (0.0 to 1.0)
  final Map<TimeSlot, double> activeTimeSlots;

  /// Activity weights by day of week (0.0 to 1.0)
  final Map<DayOfWeek, double> activeDays;

  /// User's age (for filtering)
  final int age;

  /// Categories user has explicitly opted into (for sensitive categories)
  final Set<String>? optInCategories;

  /// Exploration vs familiarity preference (0.0 = familiar, 1.0 = explore)
  /// Derived from novelty_seeking personality dimension
  final double explorationWillingness;

  /// Energy preference (0.0 = chill, 1.0 = high-energy)
  final double energyPreference;

  const UserPreferenceSignals({
    this.categoryWeights = const {},
    this.averageGroupSize = 2.0,
    this.noisePreference = 0.5,
    this.crowdTolerance = 0.5,
    this.pricePointPreference = 0.5,
    this.spontaneityLevel = 0.5,
    this.activeTimeSlots = const {},
    this.activeDays = const {},
    required this.age,
    this.optInCategories,
    this.explorationWillingness = 0.5,
    this.energyPreference = 0.5,
  });

  /// Create default signals for new users (cold start)
  factory UserPreferenceSignals.defaults({required int age}) {
    return UserPreferenceSignals(
      categoryWeights: {},
      averageGroupSize: 2.0,
      noisePreference: 0.5,
      crowdTolerance: 0.5,
      pricePointPreference: 0.5,
      spontaneityLevel: 0.5,
      activeTimeSlots: {
        TimeSlot.morning: 0.6,
        TimeSlot.afternoon: 0.7,
        TimeSlot.evening: 0.8,
        TimeSlot.night: 0.5,
      },
      activeDays: {
        DayOfWeek.friday: 0.8,
        DayOfWeek.saturday: 0.9,
        DayOfWeek.sunday: 0.7,
      },
      age: age,
      explorationWillingness: 0.5,
      energyPreference: 0.5,
    );
  }

  /// Get top N categories by weight
  List<String> getTopCategories(int n) {
    final sorted = categoryWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Get weight for a specific category
  double getCategoryWeight(String category) {
    return categoryWeights[category] ?? 0.0;
  }

  /// Check if user prefers solo outings
  bool get prefersSolo => averageGroupSize < 1.5;

  /// Check if user prefers group outings
  bool get prefersGroups => averageGroupSize >= 3.0;

  /// Check if user prefers quiet places
  bool get prefersQuiet => noisePreference < 0.4;

  /// Check if user prefers lively places
  bool get prefersLively => noisePreference > 0.6;

  /// Check if user is budget-conscious
  bool get isBudgetConscious => pricePointPreference < 0.4;

  /// Check if user prefers premium experiences
  bool get prefersPremium => pricePointPreference > 0.6;

  /// Check if user is spontaneous
  bool get isSpontaneous => spontaneityLevel > 0.6;

  /// Check if user prefers planning
  bool get prefersPlanning => spontaneityLevel < 0.4;

  /// Check if user prefers exploring new places
  bool get prefersExploring => explorationWillingness > 0.6;

  /// Check if user prefers familiar places
  bool get prefersFamiliar => explorationWillingness < 0.4;

  /// Check if user can access 21+ venues
  bool get canAccess21Plus => age >= 21;

  /// Check if user can access 18+ venues
  bool get canAccess18Plus => age >= 18;

  /// Get most active time slot
  TimeSlot? get mostActiveTimeSlot {
    if (activeTimeSlots.isEmpty) return null;
    return activeTimeSlots.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most active day
  DayOfWeek? get mostActiveDay {
    if (activeDays.isEmpty) return null;
    return activeDays.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculate activity score for a given time/day
  double getActivityScore(TimeSlot slot, DayOfWeek day) {
    final slotWeight = activeTimeSlots[slot] ?? 0.5;
    final dayWeight = activeDays[day] ?? 0.5;
    return (slotWeight + dayWeight) / 2.0;
  }

  /// Check if user has opted into a sensitive category
  bool hasOptedInto(String category) {
    return optInCategories?.contains(category) ?? false;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryWeights': categoryWeights,
      'averageGroupSize': averageGroupSize,
      'noisePreference': noisePreference,
      'crowdTolerance': crowdTolerance,
      'pricePointPreference': pricePointPreference,
      'spontaneityLevel': spontaneityLevel,
      'activeTimeSlots': activeTimeSlots.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'activeDays': activeDays.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'age': age,
      'optInCategories': optInCategories?.toList(),
      'explorationWillingness': explorationWillingness,
      'energyPreference': energyPreference,
    };
  }

  /// Create from JSON
  factory UserPreferenceSignals.fromJson(Map<String, dynamic> json) {
    return UserPreferenceSignals(
      categoryWeights: Map<String, double>.from(
        json['categoryWeights'] as Map? ?? {},
      ),
      averageGroupSize: (json['averageGroupSize'] as num?)?.toDouble() ?? 2.0,
      noisePreference: (json['noisePreference'] as num?)?.toDouble() ?? 0.5,
      crowdTolerance: (json['crowdTolerance'] as num?)?.toDouble() ?? 0.5,
      pricePointPreference:
          (json['pricePointPreference'] as num?)?.toDouble() ?? 0.5,
      spontaneityLevel: (json['spontaneityLevel'] as num?)?.toDouble() ?? 0.5,
      activeTimeSlots: (json['activeTimeSlots'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              TimeSlot.values.firstWhere((t) => t.name == k),
              (v as num).toDouble(),
            ),
          ) ??
          {},
      activeDays: (json['activeDays'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              DayOfWeek.values.firstWhere((d) => d.name == k),
              (v as num).toDouble(),
            ),
          ) ??
          {},
      age: json['age'] as int? ?? 18,
      optInCategories:
          (json['optInCategories'] as List?)?.cast<String>().toSet(),
      explorationWillingness:
          (json['explorationWillingness'] as num?)?.toDouble() ?? 0.5,
      energyPreference: (json['energyPreference'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  String toString() {
    return 'UserPreferenceSignals(age: $age, '
        'topCategories: ${getTopCategories(3)}, '
        'groupSize: ${averageGroupSize.toStringAsFixed(1)})';
  }
}
