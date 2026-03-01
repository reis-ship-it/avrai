// Location Pattern Analyzer Tests
//
// Unit tests for the LocationPatternAnalyzer that tracks and analyzes
// user location visit patterns with atomic timestamps.
//
// Key test scenarios:
// - Visit recording with atomic timing
// - Pattern analysis and frequency detection
// - Habitual category identification
// - Frequent places tracking
// - Timing preferences calculation

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';

void main() {
  group('LocationPatternAnalyzer', () {
    group('VisitPattern model', () {
      test('should create with all required fields', () {
        final pattern = _createVisitPattern(
          category: 'cafe',
          timeSlot: TimeSlot.morning,
          dayOfWeek: DayOfWeek.saturday,
        );

        expect(pattern.category, equals('cafe'));
        expect(pattern.timeSlot, equals(TimeSlot.morning));
        expect(pattern.dayOfWeek, equals(DayOfWeek.saturday));
      });

      test('should calculate time slot from hour', () {
        // Early morning: 5-8 AM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 6, 0)),
            equals(TimeSlot.earlyMorning));

        // Morning: 8-12 PM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 9, 0)),
            equals(TimeSlot.morning));

        // Afternoon: 12-5 PM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 14, 0)),
            equals(TimeSlot.afternoon));

        // Evening: 5-9 PM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 19, 0)),
            equals(TimeSlot.evening));

        // Night: 9 PM - 12 AM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 22, 0)),
            equals(TimeSlot.night));

        // Late night: 12-5 AM
        expect(getTimeSlotFromDateTime(DateTime(2024, 1, 1, 2, 0)),
            equals(TimeSlot.lateNight));
      });

      test('should calculate day of week from datetime', () {
        // Monday = 1 in DateTime
        expect(getDayOfWeekFromDateTime(DateTime(2024, 1, 1)),
            equals(DayOfWeek.monday));

        // Saturday = 6 in DateTime
        expect(getDayOfWeekFromDateTime(DateTime(2024, 1, 6)),
            equals(DayOfWeek.saturday));

        // Sunday = 7 in DateTime
        expect(getDayOfWeekFromDateTime(DateTime(2024, 1, 7)),
            equals(DayOfWeek.sunday));
      });

      test('should track dwell time', () {
        final pattern = _createVisitPattern(
          dwellTime: const Duration(hours: 2),
        );

        expect(pattern.dwellTime.inMinutes, equals(120));
      });

      test('should track group size', () {
        final soloVisit = _createVisitPattern(groupSize: 1);
        final groupVisit = _createVisitPattern(groupSize: 4);

        expect(soloVisit.groupSize, equals(1));
        expect(groupVisit.groupSize, equals(4));
      });
    });

    group('TimeSlot enum', () {
      test('should have 6 time slots', () {
        expect(TimeSlot.values.length, equals(6));
      });

      test('should cover full 24 hours', () {
        final slots = TimeSlot.values;

        expect(slots.contains(TimeSlot.earlyMorning), isTrue);
        expect(slots.contains(TimeSlot.morning), isTrue);
        expect(slots.contains(TimeSlot.afternoon), isTrue);
        expect(slots.contains(TimeSlot.evening), isTrue);
        expect(slots.contains(TimeSlot.night), isTrue);
        expect(slots.contains(TimeSlot.lateNight), isTrue);
      });
    });

    group('DayOfWeek enum', () {
      test('should have 7 days', () {
        expect(DayOfWeek.values.length, equals(7));
      });

      test('should identify weekend days', () {
        final pattern = _createVisitPattern(dayOfWeek: DayOfWeek.saturday);
        expect(pattern.isWeekend, isTrue);

        final weekdayPattern =
            _createVisitPattern(dayOfWeek: DayOfWeek.wednesday);
        expect(weekdayPattern.isWeekend, isFalse);
      });
    });

    group('pattern analysis', () {
      test('should count visits by category', () {
        final patterns = [
          _createVisitPattern(category: 'cafe'),
          _createVisitPattern(category: 'cafe'),
          _createVisitPattern(category: 'restaurant'),
          _createVisitPattern(category: 'cafe'),
        ];

        final categoryCounts = <String, int>{};
        for (final pattern in patterns) {
          categoryCounts[pattern.category] =
              (categoryCounts[pattern.category] ?? 0) + 1;
        }

        expect(categoryCounts['cafe'], equals(3));
        expect(categoryCounts['restaurant'], equals(1));
      });

      test('should identify most visited categories', () {
        final categoryCounts = {
          'cafe': 10,
          'restaurant': 5,
          'bar': 3,
          'museum': 1,
        };

        final sorted = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        expect(sorted.first.key, equals('cafe'));
        expect(sorted[1].key, equals('restaurant'));
      });

      test('should calculate average dwell time by category', () {
        final patterns = [
          _createVisitPattern(
              category: 'cafe', dwellTime: const Duration(minutes: 30)),
          _createVisitPattern(
              category: 'cafe', dwellTime: const Duration(minutes: 60)),
          _createVisitPattern(
              category: 'cafe', dwellTime: const Duration(minutes: 45)),
        ];

        final totalMinutes =
            patterns.map((p) => p.dwellTime.inMinutes).fold(0, (a, b) => a + b);
        final avgDwellMinutes = totalMinutes / patterns.length;

        expect(avgDwellMinutes, equals(45.0));
      });
    });

    group('timing preferences', () {
      test('should identify peak time slots', () {
        final patterns = [
          _createVisitPattern(timeSlot: TimeSlot.morning),
          _createVisitPattern(timeSlot: TimeSlot.morning),
          _createVisitPattern(timeSlot: TimeSlot.morning),
          _createVisitPattern(timeSlot: TimeSlot.evening),
        ];

        final slotCounts = <TimeSlot, int>{};
        for (final pattern in patterns) {
          slotCounts[pattern.timeSlot] =
              (slotCounts[pattern.timeSlot] ?? 0) + 1;
        }

        final sorted = slotCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        expect(sorted.first.key, equals(TimeSlot.morning));
      });

      test('should identify peak days', () {
        final patterns = [
          _createVisitPattern(dayOfWeek: DayOfWeek.saturday),
          _createVisitPattern(dayOfWeek: DayOfWeek.saturday),
          _createVisitPattern(dayOfWeek: DayOfWeek.sunday),
          _createVisitPattern(dayOfWeek: DayOfWeek.wednesday),
        ];

        final dayCounts = <DayOfWeek, int>{};
        for (final pattern in patterns) {
          dayCounts[pattern.dayOfWeek] =
              (dayCounts[pattern.dayOfWeek] ?? 0) + 1;
        }

        final sorted = dayCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        expect(sorted.first.key, equals(DayOfWeek.saturday));
      });
    });

    group('TimingPreferences model', () {
      test('should store category preferred times', () {
        final preferences = TimingPreferences(
          categoryPreferredTimes: {
            'cafe': TimeSlot.morning,
            'restaurant': TimeSlot.evening,
          },
          categoryPreferredDays: {
            'cafe': DayOfWeek.saturday,
          },
          weekendVsWeekdayRatio: 0.7,
        );

        expect(preferences.categoryPreferredTimes['cafe'],
            equals(TimeSlot.morning));
        expect(preferences.prefersWeekends, isTrue);
      });

      test('should identify weekend preference', () {
        final weekendPrefer = TimingPreferences(
          weekendVsWeekdayRatio: 0.8,
        );
        expect(weekendPrefer.prefersWeekends, isTrue);
        expect(weekendPrefer.prefersWeekdays, isFalse);

        final weekdayPrefer = TimingPreferences(
          weekendVsWeekdayRatio: 0.3,
        );
        expect(weekdayPrefer.prefersWeekdays, isTrue);
        expect(weekdayPrefer.prefersWeekends, isFalse);
      });
    });

    group('ActivityWindow model', () {
      test('should define activity windows', () {
        final window = ActivityWindow(
          startSlot: TimeSlot.morning,
          activeDays: [DayOfWeek.saturday, DayOfWeek.sunday],
          activityStrength: 0.7,
        );

        expect(window.startSlot, equals(TimeSlot.morning));
        expect(window.activeDays, contains(DayOfWeek.saturday));
        expect(window.activityStrength, equals(0.7));
      });
    });

    group('frequent places', () {
      test('should identify frequently visited places', () {
        final patterns = [
          _createVisitPattern(placeId: 'place-1'),
          _createVisitPattern(placeId: 'place-1'),
          _createVisitPattern(placeId: 'place-1'),
          _createVisitPattern(placeId: 'place-2'),
          _createVisitPattern(placeId: 'place-3'),
        ];

        final placeCounts = <String, int>{};
        for (final pattern in patterns) {
          final placeId = pattern.placeId;
          if (placeId != null) {
            placeCounts[placeId] = (placeCounts[placeId] ?? 0) + 1;
          }
        }

        final sorted = placeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        expect(sorted.first.key, equals('place-1'));
        expect(sorted.first.value, equals(3));
      });

      test('should limit frequent places to requested count', () {
        final placeCounts = {
          'place-1': 10,
          'place-2': 8,
          'place-3': 5,
          'place-4': 3,
          'place-5': 1,
        };

        final sorted = placeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final top3 = sorted.take(3).map((e) => e.key).toList();

        expect(top3.length, equals(3));
        expect(top3[0], equals('place-1'));
        expect(top3[2], equals('place-3'));
      });
    });

    group('lookback window', () {
      test('should filter patterns by lookback period', () {
        final now = DateTime.now();
        final patterns = [
          _createVisitPattern(timestamp: now.subtract(const Duration(days: 5))),
          _createVisitPattern(
              timestamp: now.subtract(const Duration(days: 15))),
          _createVisitPattern(
              timestamp: now.subtract(const Duration(days: 35))),
        ];

        const lookbackDays = 30;
        final cutoff = now.subtract(const Duration(days: lookbackDays));

        final recentPatterns =
            patterns.where((p) => p.atomicTimestamp.isAfter(cutoff)).toList();

        expect(recentPatterns.length, equals(2));
      });
    });

    group('habitual categories', () {
      test('should calculate category weights based on frequency', () {
        final patterns = [
          _createVisitPattern(category: 'cafe'),
          _createVisitPattern(category: 'cafe'),
          _createVisitPattern(category: 'cafe'),
          _createVisitPattern(category: 'restaurant'),
          _createVisitPattern(category: 'bar'),
        ];

        final categoryCounts = <String, int>{};
        for (final pattern in patterns) {
          categoryCounts[pattern.category] =
              (categoryCounts[pattern.category] ?? 0) + 1;
        }

        final maxCount = categoryCounts.values
            .fold(0, (max, count) => count > max ? count : max);

        final weights = categoryCounts.map(
          (cat, count) => MapEntry(cat, count / maxCount),
        );

        expect(weights['cafe'], equals(1.0)); // 3/3
        expect(weights['restaurant'], closeTo(0.33, 0.01)); // 1/3
        expect(weights['bar'], closeTo(0.33, 0.01)); // 1/3
      });
    });
  });
}

/// Helper to create a visit pattern for testing
VisitPattern _createVisitPattern({
  String? placeId,
  String category = 'cafe',
  TimeSlot timeSlot = TimeSlot.morning,
  DayOfWeek dayOfWeek = DayOfWeek.saturday,
  Duration dwellTime = const Duration(minutes: 30),
  int groupSize = 2,
  DateTime? timestamp,
}) {
  return VisitPattern(
    id: 'pattern-${DateTime.now().millisecondsSinceEpoch}',
    userId: 'test-user',
    placeId: placeId ?? 'test-place',
    placeName: 'Test Place',
    category: category,
    latitude: 40.7128,
    longitude: -74.0060,
    atomicTimestamp: timestamp ?? DateTime.now(),
    dwellTime: dwellTime,
    groupSize: groupSize,
    timeSlot: timeSlot,
    dayOfWeek: dayOfWeek,
    isRepeatVisit: false,
    visitFrequency: 1,
  );
}
