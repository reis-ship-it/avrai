// Calendar Context Provider
//
// Phase 4.5: Calendar-aware list suggestions
//
// Purpose: Adjust suggestions based on user's calendar events

import 'dart:developer' as developer;

/// Calendar Context Provider
///
/// Provides calendar context for list generation.
/// Adjusts place suggestions based on upcoming events and free time.
///
/// Note: Actual calendar integration requires platform-specific implementation
/// (device_calendar plugin or Apple Calendar/Google Calendar APIs)
///
/// Part of Phase 4.5: Calendar-Aware Suggestions

class CalendarContextProvider {
  static const String _logName = 'CalendarContextProvider';

  /// Cached calendar events
  List<CalendarEvent> _cachedEvents = [];
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  CalendarContextProvider();

  /// Get calendar context for a time window
  Future<CalendarContext?> getCalendarContext({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Check cache
      if (_cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _buildContext(_cachedEvents, startTime, endTime);
      }

      // Fetch events from calendar
      final events = await _fetchCalendarEvents(userId, startTime, endTime);
      _cachedEvents = events;
      _cacheTime = DateTime.now();

      return _buildContext(events, startTime, endTime);
    } catch (e) {
      developer.log('Error getting calendar context: $e', name: _logName);
      return null;
    }
  }

  /// Fetch calendar events (stub - needs platform-specific implementation)
  Future<List<CalendarEvent>> _fetchCalendarEvents(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // TODO(Phase 4.5): Integrate with device_calendar or platform calendar APIs
    // For now, return empty list (no calendar access)
    developer.log(
      'Calendar integration not yet implemented',
      name: _logName,
    );
    return [];
  }

  /// Build calendar context from events
  CalendarContext _buildContext(
    List<CalendarEvent> events,
    DateTime startTime,
    DateTime endTime,
  ) {
    // Find free time slots
    final freeSlots = _findFreeSlots(events, startTime, endTime);

    // Check for upcoming events
    final upcomingEvents = events.where((e) {
      return e.startTime.isAfter(DateTime.now()) &&
          e.startTime.isBefore(DateTime.now().add(const Duration(hours: 3)));
    }).toList();

    // Calculate busyness level
    final busyness = _calculateBusyness(events, startTime, endTime);

    return CalendarContext(
      freeTimeSlots: freeSlots,
      upcomingEvents: upcomingEvents,
      busynessLevel: busyness,
      hasFlexibleTime: freeSlots.any((s) => s.duration.inMinutes >= 60),
    );
  }

  /// Find free time slots between events
  List<TimeSlotWindow> _findFreeSlots(
    List<CalendarEvent> events,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (events.isEmpty) {
      return [
        TimeSlotWindow(
          startTime: startTime,
          endTime: endTime,
        ),
      ];
    }

    final freeSlots = <TimeSlotWindow>[];
    final sortedEvents = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Free time before first event
    if (sortedEvents.first.startTime.isAfter(startTime)) {
      freeSlots.add(TimeSlotWindow(
        startTime: startTime,
        endTime: sortedEvents.first.startTime,
      ));
    }

    // Free time between events
    for (var i = 0; i < sortedEvents.length - 1; i++) {
      final currentEnd = sortedEvents[i].endTime;
      final nextStart = sortedEvents[i + 1].startTime;

      if (nextStart.isAfter(currentEnd)) {
        freeSlots.add(TimeSlotWindow(
          startTime: currentEnd,
          endTime: nextStart,
        ));
      }
    }

    // Free time after last event
    if (sortedEvents.last.endTime.isBefore(endTime)) {
      freeSlots.add(TimeSlotWindow(
        startTime: sortedEvents.last.endTime,
        endTime: endTime,
      ));
    }

    return freeSlots;
  }

  /// Calculate busyness level (0.0 = free, 1.0 = fully booked)
  double _calculateBusyness(
    List<CalendarEvent> events,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (events.isEmpty) return 0.0;

    final totalMinutes = endTime.difference(startTime).inMinutes;
    if (totalMinutes <= 0) return 0.0;

    final busyMinutes = events.fold<int>(0, (sum, event) {
      final eventDuration = event.endTime.difference(event.startTime).inMinutes;
      return sum + eventDuration;
    });

    return (busyMinutes / totalMinutes).clamp(0.0, 1.0);
  }

  /// Get category adjustments based on calendar context
  Map<String, double> getCategoryAdjustments(CalendarContext context) {
    final adjustments = <String, double>{};

    // If user is busy, boost quick options
    if (context.busynessLevel > 0.7) {
      adjustments['cafes'] = 0.2;
      adjustments['restaurants'] = -0.1;
      adjustments['entertainment'] = -0.2;
    }

    // If user has lots of free time, boost longer activities
    if (context.hasFlexibleTime && context.busynessLevel < 0.3) {
      adjustments['museums'] = 0.2;
      adjustments['entertainment'] = 0.2;
      adjustments['outdoors'] = 0.2;
    }

    return adjustments;
  }
}

/// Calendar event data
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.isAllDay = false,
  });

  Duration get duration => endTime.difference(startTime);
}

/// Free time slot window
class TimeSlotWindow {
  final DateTime startTime;
  final DateTime endTime;

  const TimeSlotWindow({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);
}

/// Calendar context for list generation
class CalendarContext {
  /// Available free time slots
  final List<TimeSlotWindow> freeTimeSlots;

  /// Upcoming events in the next few hours
  final List<CalendarEvent> upcomingEvents;

  /// Busyness level (0.0 = free, 1.0 = fully booked)
  final double busynessLevel;

  /// Whether user has flexible time (60+ minutes free)
  final bool hasFlexibleTime;

  const CalendarContext({
    required this.freeTimeSlots,
    required this.upcomingEvents,
    required this.busynessLevel,
    required this.hasFlexibleTime,
  });

  /// Get the longest free time slot
  TimeSlotWindow? get longestFreeSlot {
    if (freeTimeSlots.isEmpty) return null;
    return freeTimeSlots.reduce((a, b) => a.duration > b.duration ? a : b);
  }
}
