import 'dart:developer' as developer;

import 'package:device_calendar/device_calendar.dart';

import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';

/// Service for tracking calendar events to enable AI learning from user's schedule
///
/// Collects calendar data for the AI to learn:
/// - Schedule patterns (work hours, social events, routines)
/// - Event types (meetings, social, personal)
/// - Location patterns from event venues
/// - Time-of-day preferences
///
/// All data is processed locally on-device per avrai privacy philosophy.
/// Data never leaves the device - learning happens entirely on your phone.

class CalendarTrackingService {
  static const String _logName = 'CalendarTrackingService';

  final DeviceCalendarPlugin _calendarPlugin;
  bool _isInitialized = false;
  bool _hasPermission = false;
  List<Calendar>? _calendars;

  // Status tracking
  CollectionStatus _status = CollectionStatus.notInitialized;
  String? _lastError;
  DateTime? _lastSuccessfulCollection;

  CalendarTrackingService({
    DeviceCalendarPlugin? calendarPlugin,
  }) : _calendarPlugin = calendarPlugin ?? DeviceCalendarPlugin();

  /// Current collection status
  CollectionStatus get status => _status;

  /// Last error message (if any)
  String? get lastError => _lastError;

  /// Last successful collection time
  DateTime? get lastSuccessfulCollection => _lastSuccessfulCollection;

  /// Whether the service is actively collecting
  bool get isCollecting => _status == CollectionStatus.collecting;

  /// Initialize and request calendar permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      final permissionResult = await _calendarPlugin.requestPermissions();
      _hasPermission =
          permissionResult.isSuccess && permissionResult.data == true;

      if (_hasPermission) {
        // Retrieve available calendars
        final calendarsResult = await _calendarPlugin.retrieveCalendars();
        if (calendarsResult.isSuccess) {
          _calendars = calendarsResult.data;
          _status = CollectionStatus.collecting;
          developer.log(
            'CalendarTrackingService initialized with ${_calendars?.length ?? 0} calendars',
            name: _logName,
          );
        }
      } else {
        _status = CollectionStatus.permissionDenied;
        developer.log(
          'Calendar permission denied',
          name: _logName,
        );
      }

      _isInitialized = true;
    } catch (e, st) {
      _status = CollectionStatus.error;
      _lastError = e.toString();
      developer.log(
        'Error initializing CalendarTrackingService',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      _isInitialized = true;
      _hasPermission = false;
    }
  }

  /// Check if calendar tracking is available
  bool get isAvailable => _isInitialized && _hasPermission;

  /// Collect calendar events for the specified time range
  ///
  /// Returns a list of calendar event data for AI learning.
  /// Default range is past 7 days to next 7 days.
  Future<List<Map<String, dynamic>>> collectCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_hasPermission || _calendars == null || _calendars!.isEmpty) {
      _status = CollectionStatus.permissionDenied;
      developer.log('No calendar access available', name: _logName);
      return [];
    }

    final events = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));
    final end = endDate ?? now.add(const Duration(days: 7));

    try {
      for (final calendar in _calendars!) {
        if (calendar.id == null) continue;

        final eventsResult = await _calendarPlugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(
            startDate: start,
            endDate: end,
          ),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (final event in eventsResult.data!) {
            final eventData = _extractEventData(event, calendar);
            if (eventData != null) {
              events.add(eventData);
            }
          }
        }
      }

      // Update status after successful collection
      if (events.isNotEmpty) {
        _status = CollectionStatus.collecting;
        _lastSuccessfulCollection = DateTime.now();
        _lastError = null;
      } else {
        _status = CollectionStatus.noData;
      }

      developer.log(
        'Collected ${events.length} calendar events',
        name: _logName,
      );

      return events;
    } catch (e, st) {
      _status = CollectionStatus.error;
      _lastError = e.toString();
      developer.log(
        'Error collecting calendar events',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return [];
    }
  }

  /// Extract relevant data from a calendar event for learning
  ///
  /// Extracts:
  /// - Time information (start, end, duration, day of week)
  /// - Event type inference (work, social, personal)
  /// - Location (if available)
  /// - Recurrence patterns
  Map<String, dynamic>? _extractEventData(Event event, Calendar calendar) {
    if (event.start == null) return null;

    final start = event.start!;
    final end = event.end ?? start.add(const Duration(hours: 1));
    final duration = end.difference(start);

    return {
      'event_id': event.eventId,
      'calendar_name': calendar.name,
      'calendar_id': calendar.id,
      // Time information
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'duration_minutes': duration.inMinutes,
      'day_of_week': start.weekday,
      'hour_of_day': start.hour,
      'is_all_day': event.allDay ?? false,
      // Location
      'has_location': event.location != null && event.location!.isNotEmpty,
      'location': event.location,
      // Event type inference
      'inferred_type': _inferEventType(event),
      'is_recurring': event.recurrenceRule != null,
      // Timing category
      'time_category': _categorizeTimeOfDay(start.hour),
      'is_weekend': start.weekday >= 6,
      // For pattern detection
      'title_keywords': _extractKeywords(event.title),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Infer the type of event based on title, time, and other metadata
  ///
  /// Categories:
  /// - work: meetings, calls, standups, reviews
  /// - social: dinner, drinks, party, hangout
  /// - fitness: gym, run, workout, yoga
  /// - personal: appointment, errand
  /// - entertainment: concert, movie, show, game
  String _inferEventType(Event event) {
    final title = (event.title ?? '').toLowerCase();
    final hour = event.start?.hour ?? 12;
    final isWeekend = (event.start?.weekday ?? 1) >= 6;

    // Work-related keywords
    final workKeywords = [
      'meeting',
      'call',
      'standup',
      'review',
      'sync',
      'interview',
      '1:1',
      'one-on-one',
      'sprint',
      'demo',
      'planning',
      'retro',
      'scrum',
      'client',
      'conference',
      'presentation',
      'workshop',
    ];

    // Social keywords
    final socialKeywords = [
      'dinner',
      'lunch',
      'drinks',
      'party',
      'hangout',
      'birthday',
      'wedding',
      'brunch',
      'coffee',
      'happy hour',
      'date',
      'get together',
      'meetup',
      'gathering',
    ];

    // Fitness keywords
    final fitnessKeywords = [
      'gym',
      'workout',
      'run',
      'yoga',
      'fitness',
      'crossfit',
      'spin',
      'pilates',
      'swim',
      'tennis',
      'basketball',
      'soccer',
      'hiking',
      'climbing',
    ];

    // Entertainment keywords
    final entertainmentKeywords = [
      'concert',
      'show',
      'movie',
      'game',
      'theater',
      'theatre',
      'museum',
      'festival',
      'exhibition',
      'comedy',
      'live',
      'performance',
    ];

    // Check for matches
    for (final keyword in workKeywords) {
      if (title.contains(keyword)) return 'work';
    }
    for (final keyword in socialKeywords) {
      if (title.contains(keyword)) return 'social';
    }
    for (final keyword in fitnessKeywords) {
      if (title.contains(keyword)) return 'fitness';
    }
    for (final keyword in entertainmentKeywords) {
      if (title.contains(keyword)) return 'entertainment';
    }

    // Time-based inference if no keyword match
    if (!isWeekend && hour >= 9 && hour <= 18) {
      return 'work'; // Default to work during business hours on weekdays
    }
    if (hour >= 18 || hour < 6) {
      return 'personal'; // Evening/night events
    }

    return 'personal';
  }

  /// Categorize time of day
  String _categorizeTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Extract keywords from event title for pattern matching
  List<String> _extractKeywords(String? title) {
    if (title == null || title.isEmpty) return [];

    // Simple keyword extraction - split by spaces and filter
    final words = title.toLowerCase().split(RegExp(r'[\s,\-:]+'));
    return words
        .where((w) => w.length > 2) // Filter short words
        .where((w) => !_stopWords.contains(w)) // Filter stop words
        .toList();
  }

  /// Common stop words to filter out
  static const _stopWords = {
    'the',
    'and',
    'for',
    'with',
    'from',
    'this',
    'that',
    'are',
    'was',
    'will',
    'have',
    'has',
    'been',
    'being',
  };

  /// Get aggregated calendar patterns for learning
  ///
  /// Analyzes collected events to extract patterns:
  /// - Time preferences (when user schedules events)
  /// - Event type distribution
  /// - Location patterns
  /// - Recurring event patterns
  Future<Map<String, dynamic>> getCalendarPatterns() async {
    final events = await collectCalendarEvents(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (events.isEmpty) {
      return {'has_data': false};
    }

    // Aggregate patterns
    final typeDistribution = <String, int>{};
    final hourDistribution = <int, int>{};
    final dayDistribution = <int, int>{};
    int totalEvents = 0;
    int eventsWithLocation = 0;
    int recurringEvents = 0;

    for (final event in events) {
      totalEvents++;

      // Type distribution
      final type = event['inferred_type'] as String;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;

      // Hour distribution
      final hour = event['hour_of_day'] as int;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;

      // Day distribution
      final day = event['day_of_week'] as int;
      dayDistribution[day] = (dayDistribution[day] ?? 0) + 1;

      // Location tracking
      if (event['has_location'] == true) {
        eventsWithLocation++;
      }

      // Recurring events
      if (event['is_recurring'] == true) {
        recurringEvents++;
      }
    }

    // Find peak hours
    final peakHours = hourDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find busiest days
    final busiestDays = dayDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'has_data': true,
      'total_events': totalEvents,
      'type_distribution': typeDistribution,
      'peak_hours': peakHours.take(3).map((e) => e.key).toList(),
      'busiest_days': busiestDays.take(3).map((e) => e.key).toList(),
      'events_with_location_percent': totalEvents > 0
          ? (eventsWithLocation / totalEvents * 100).round()
          : 0,
      'recurring_percent':
          totalEvents > 0 ? (recurringEvents / totalEvents * 100).round() : 0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get upcoming events for context-aware suggestions
  ///
  /// Returns events in the next [hours] hours for real-time AI context.
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int hours = 24}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    return collectCalendarEvents(
      startDate: now,
      endDate: now.add(Duration(hours: hours)),
    );
  }
}
