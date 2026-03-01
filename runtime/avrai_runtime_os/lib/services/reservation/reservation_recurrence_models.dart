part of 'reservation_recurrence_service.dart';

/// Cached recurrence calculation.
class _CachedRecurrenceCalculation {
  final List<DateTime> instances;
  final DateTime cachedAt;

  _CachedRecurrenceCalculation({
    required this.instances,
    required this.cachedAt,
  });
}
