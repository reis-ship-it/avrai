// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
part of 'reservation_calendar_service.dart';

class _CachedKnotSignature {
  final String signature;
  final DateTime cachedAt;

  _CachedKnotSignature({
    required this.signature,
    required this.cachedAt,
  });
}

class _CachedCompatibility {
  final double compatibility;
  final DateTime cachedAt;

  _CachedCompatibility({
    required this.compatibility,
    required this.cachedAt,
  });
}

class _CachedCalendarEvent {
  final String eventId;
  final DateTime cachedAt;

  _CachedCalendarEvent({
    required this.eventId,
    required this.cachedAt,
  });
}
