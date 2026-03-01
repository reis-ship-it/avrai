import 'dart:developer' as developer;

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/places_datasource.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/places/organic_spot_discovery_service.dart';

import '../models/visit_pattern.dart';

/// Location Pattern Analyzer
///
/// Tracks where and when users go with atomic timestamp precision.
/// Used for learning timing preferences and behavioral patterns.
///
/// When a visit doesn't match any known place (placeId == null), the visit
/// is forwarded to [OrganicSpotDiscoveryService] for organic spot detection.
/// This enables the system to learn about meaningful locations that don't
/// exist in any external database (parks, garages, hidden gems, etc.).
///
/// Part of Phase 2: Perpetual List Orchestrator
///
/// Phase 26: Migrated from Sembast to GetStorage.

class LocationPatternAnalyzer {
  static const String _logName = 'LocationPatternAnalyzer';
  static const int _maxStoredPatterns = 500;
  static const String _boxName = 'visit_patterns';

  // GetStorage for pattern persistence
  static GetStorage? _storage;

  GetStorage get _box {
    _storage ??= GetStorage(_boxName);
    return _storage!;
  }

  /// Initialize storage
  static Future<void> initStorage() async {
    await GetStorage.init(_boxName);
  }

  final AtomicClockService _atomicClock;
  final PlacesDataSource _placesDataSource;

  /// Optional organic spot discovery service. When provided, unmatched
  /// visits (no placeId) are forwarded for organic spot detection.
  /// This enables the system to learn about informal/hidden locations.
  final OrganicSpotDiscoveryService? _organicDiscoveryService;

  LocationPatternAnalyzer({
    required AtomicClockService atomicClock,
    required PlacesDataSource placesDataSource,
    OrganicSpotDiscoveryService? organicDiscoveryService,
  })  : _atomicClock = atomicClock,
        _placesDataSource = placesDataSource,
        _organicDiscoveryService = organicDiscoveryService;

  /// Record a visit with atomic timestamp
  ///
  /// Matches the location to a known place and stores the visit pattern.
  Future<VisitPattern> recordVisit({
    required String userId,
    required double latitude,
    required double longitude,
    required Duration dwellTime,
    int? groupSize,
  }) async {
    developer.log(
      'Recording visit for user: $userId at ($latitude, $longitude)',
      name: _logName,
    );

    // Get atomic timestamp (millisecond precision, drift-corrected)
    final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
    final timestamp = atomicTimestamp.serverTime;

    // Match location to known place
    final place = await _matchToPlace(latitude, longitude);

    // Get existing visits to this place
    final existingVisits = await _getVisitsToPlace(userId, place?.id);
    final isRepeatVisit = existingVisits.isNotEmpty;
    final visitFrequency = existingVisits.length + 1;

    // Calculate time since last visit to this place
    Duration? timeSinceLastVisit;
    if (existingVisits.isNotEmpty) {
      existingVisits.sort(
        (a, b) => b.atomicTimestamp.compareTo(a.atomicTimestamp),
      );
      timeSinceLastVisit = timestamp.difference(
        existingVisits.first.atomicTimestamp,
      );
    }

    final pattern = VisitPattern(
      id: const Uuid().v4(),
      userId: userId,
      placeId: place?.id,
      placeName: place?.name,
      category: place?.category ?? 'unknown',
      latitude: latitude,
      longitude: longitude,
      atomicTimestamp: timestamp,
      dwellTime: dwellTime,
      dayOfWeek: getDayOfWeekFromDateTime(timestamp),
      timeSlot: getTimeSlotFromDateTime(timestamp),
      isRepeatVisit: isRepeatVisit,
      visitFrequency: visitFrequency,
      timeSinceLastVisit: timeSinceLastVisit,
      groupSize: groupSize ?? 1,
    );

    // Store pattern
    await _storeVisitPattern(pattern);

    // Forward unmatched visits to organic spot discovery service.
    // When no known place matches (placeId == null), this visit might be
    // at a hidden gem -- a park, garage, rooftop, or informal gathering
    // place that doesn't exist in any database. The discovery service
    // clusters these visits and surfaces meaningful locations organically.
    if (place == null && _organicDiscoveryService != null) {
      try {
        await _organicDiscoveryService.processUnmatchedVisit(
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          dwellTime: dwellTime,
          timestamp: timestamp,
          dayOfWeek: pattern.dayOfWeek,
          timeSlot: pattern.timeSlot,
          groupSize: groupSize ?? 1,
        );
      } catch (e) {
        developer.log(
          'Error forwarding unmatched visit to organic discovery: $e',
          name: _logName,
        );
        // Non-critical -- don't fail the visit recording
      }
    }

    developer.log(
      'Visit recorded: ${place?.name ?? 'unknown'} at ${timestamp.toIso8601String()}',
      name: _logName,
    );

    return pattern;
  }

  /// Get visit patterns for a user
  Future<List<VisitPattern>> getVisitPatterns({
    required String userId,
    int lookbackDays = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: lookbackDays));
    final patterns = await _loadVisitPatterns(userId);

    return patterns.where((p) => p.atomicTimestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => b.atomicTimestamp.compareTo(a.atomicTimestamp));
  }

  /// Analyze timing patterns for a user
  Future<TimingPreferences> analyzeTimingPatterns(String userId) async {
    final patterns = await getVisitPatterns(userId: userId, lookbackDays: 90);

    if (patterns.isEmpty) {
      return TimingPreferences.defaults();
    }

    // Calculate preferred times for each category
    final categoryTiming = <String, List<TimeSlot>>{};
    for (final pattern in patterns) {
      categoryTiming[pattern.category] ??= [];
      categoryTiming[pattern.category]!.add(pattern.timeSlot);
    }

    // Calculate preferred days for each category
    final categoryDays = <String, List<DayOfWeek>>{};
    for (final pattern in patterns) {
      categoryDays[pattern.category] ??= [];
      categoryDays[pattern.category]!.add(pattern.dayOfWeek);
    }

    // Calculate average dwell time per category
    final categoryDwellTime = <String, Duration>{};
    for (final category in categoryTiming.keys) {
      final categoryPatterns =
          patterns.where((p) => p.category == category).toList();
      final totalDwell = categoryPatterns
          .map((p) => p.dwellTime.inMinutes)
          .fold(0, (a, b) => a + b);
      categoryDwellTime[category] = Duration(
        minutes: totalDwell ~/ categoryPatterns.length,
      );
    }

    // Find peak activity windows
    final peakWindows = _findPeakActivityWindows(patterns);

    return TimingPreferences(
      categoryPreferredTimes: categoryTiming.map(
        (cat, times) => MapEntry(cat, _getMostCommonTimeSlot(times)),
      ),
      categoryPreferredDays: categoryDays.map(
        (cat, days) => MapEntry(cat, _getMostCommonDay(days)),
      ),
      categoryAvgDwellTime: categoryDwellTime,
      peakActivityWindows: peakWindows,
      weekendVsWeekdayRatio: _calculateWeekendRatio(patterns),
    );
  }

  /// Get habitual categories (categories visited regularly)
  Future<Map<String, double>> getHabitualCategories(String userId) async {
    final patterns = await getVisitPatterns(userId: userId, lookbackDays: 60);

    // Group by category
    final categoryFrequency = <String, int>{};
    for (final pattern in patterns) {
      categoryFrequency[pattern.category] =
          (categoryFrequency[pattern.category] ?? 0) + 1;
    }

    // Calculate regularity (visits per week)
    const weeksAnalyzed = 60 / 7;
    return categoryFrequency.map(
      (cat, count) => MapEntry(cat, count / weeksAnalyzed),
    );
  }

  /// Get frequently visited places
  Future<List<FrequentPlace>> getFrequentPlaces({
    required String userId,
    int limit = 10,
  }) async {
    final patterns = await getVisitPatterns(userId: userId, lookbackDays: 90);

    // Group by place ID
    final placeCounts = <String, List<VisitPattern>>{};
    for (final pattern in patterns) {
      if (pattern.placeId != null) {
        placeCounts[pattern.placeId!] ??= [];
        placeCounts[pattern.placeId!]!.add(pattern);
      }
    }

    // Convert to FrequentPlace objects
    final frequentPlaces = <FrequentPlace>[];
    for (final entry in placeCounts.entries) {
      final visits = entry.value;
      if (visits.length >= 2) {
        // At least 2 visits to be considered "frequent"
        final avgDwellMinutes =
            visits.map((v) => v.dwellTime.inMinutes).reduce((a, b) => a + b) ~/
                visits.length;

        frequentPlaces.add(FrequentPlace(
          placeId: entry.key,
          placeName: visits.first.placeName,
          category: visits.first.category,
          visitCount: visits.length,
          averageDwellTime: Duration(minutes: avgDwellMinutes),
          lastVisit: visits
              .map((v) => v.atomicTimestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          preferredTimeSlot: _getMostCommonTimeSlot(
            visits.map((v) => v.timeSlot).toList(),
          ),
        ));
      }
    }

    // Sort by visit count
    frequentPlaces.sort((a, b) => b.visitCount.compareTo(a.visitCount));

    return frequentPlaces.take(limit).toList();
  }

  /// Match a location to a known place
  Future<Spot?> _matchToPlace(double latitude, double longitude) async {
    try {
      // Search for nearby places (within 50 meters)
      final places = await _placesDataSource.searchNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radius: 50,
      );

      if (places.isEmpty) return null;

      // Return the closest place
      return places.first;
    } catch (e) {
      developer.log(
        'Error matching location to place: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Get visits to a specific place
  Future<List<VisitPattern>> _getVisitsToPlace(
    String userId,
    String? placeId,
  ) async {
    if (placeId == null) return [];

    final patterns = await _loadVisitPatterns(userId);
    return patterns.where((p) => p.placeId == placeId).toList();
  }

  /// Store a visit pattern
  Future<void> _storeVisitPattern(VisitPattern pattern) async {
    try {
      final key = '${pattern.userId}_${pattern.id}';
      await _box.write(key, pattern.toJson());

      // Cleanup old patterns if we have too many
      await _cleanupOldPatterns(pattern.userId);
    } catch (e) {
      developer.log(
        'Error storing visit pattern: $e',
        name: _logName,
      );
    }
  }

  /// Load visit patterns for a user
  Future<List<VisitPattern>> _loadVisitPatterns(String userId) async {
    try {
      final allKeys = _box.getKeys<Iterable<String>>();

      final patterns = <VisitPattern>[];
      for (final key in allKeys) {
        if (key.startsWith('${userId}_')) {
          final json = _box.read<Map<String, dynamic>>(key);
          if (json != null) {
            patterns.add(VisitPattern.fromJson(json));
          }
        }
      }

      return patterns;
    } catch (e) {
      developer.log(
        'Error loading visit patterns: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Cleanup old patterns to prevent storage bloat
  Future<void> _cleanupOldPatterns(String userId) async {
    try {
      final patterns = await _loadVisitPatterns(userId);
      if (patterns.length <= _maxStoredPatterns) return;

      // Sort by timestamp and remove oldest
      patterns.sort((a, b) => a.atomicTimestamp.compareTo(b.atomicTimestamp));
      final toRemove = patterns.take(patterns.length - _maxStoredPatterns);

      for (final pattern in toRemove) {
        final key = '${pattern.userId}_${pattern.id}';
        await _box.remove(key);
      }

      developer.log(
        'Cleaned up ${toRemove.length} old visit patterns',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error cleaning up old patterns: $e',
        name: _logName,
      );
    }
  }

  /// Find peak activity windows from patterns
  List<ActivityWindow> _findPeakActivityWindows(List<VisitPattern> patterns) {
    // Count visits by time slot and day
    final slotDayCounts = <TimeSlot, Map<DayOfWeek, int>>{};
    for (final pattern in patterns) {
      slotDayCounts[pattern.timeSlot] ??= {};
      slotDayCounts[pattern.timeSlot]![pattern.dayOfWeek] =
          (slotDayCounts[pattern.timeSlot]![pattern.dayOfWeek] ?? 0) + 1;
    }

    // Find top time slots
    final windows = <ActivityWindow>[];
    for (final entry in slotDayCounts.entries) {
      final totalForSlot = entry.value.values.fold(0, (a, b) => a + b);
      final strength = totalForSlot / patterns.length;

      if (strength > 0.15) {
        // At least 15% of visits in this slot
        final activeDays = entry.value.entries
            .where((e) => e.value >= 2)
            .map((e) => e.key)
            .toList();

        windows.add(ActivityWindow(
          startSlot: entry.key,
          activeDays: activeDays,
          activityStrength: strength,
        ));
      }
    }

    windows.sort((a, b) => b.activityStrength.compareTo(a.activityStrength));
    return windows;
  }

  /// Get most common time slot from a list
  TimeSlot _getMostCommonTimeSlot(List<TimeSlot> slots) {
    if (slots.isEmpty) return TimeSlot.afternoon;

    final counts = <TimeSlot, int>{};
    for (final slot in slots) {
      counts[slot] = (counts[slot] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get most common day from a list
  DayOfWeek _getMostCommonDay(List<DayOfWeek> days) {
    if (days.isEmpty) return DayOfWeek.saturday;

    final counts = <DayOfWeek, int>{};
    for (final day in days) {
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculate weekend vs weekday ratio
  double _calculateWeekendRatio(List<VisitPattern> patterns) {
    if (patterns.isEmpty) return 0.5;

    final weekendCount = patterns.where((p) => p.isWeekend).length;
    return weekendCount / patterns.length;
  }
}

/// Represents a frequently visited place
class FrequentPlace {
  final String placeId;
  final String? placeName;
  final String category;
  final int visitCount;
  final Duration averageDwellTime;
  final DateTime lastVisit;
  final TimeSlot preferredTimeSlot;

  const FrequentPlace({
    required this.placeId,
    this.placeName,
    required this.category,
    required this.visitCount,
    required this.averageDwellTime,
    required this.lastVisit,
    required this.preferredTimeSlot,
  });

  /// Check if this place is a regular habit (visited weekly or more)
  bool get isRegularHabit => visitCount >= 4;

  @override
  String toString() {
    return 'FrequentPlace(${placeName ?? placeId}: $visitCount visits)';
  }
}
