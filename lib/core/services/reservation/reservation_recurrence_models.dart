// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
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
