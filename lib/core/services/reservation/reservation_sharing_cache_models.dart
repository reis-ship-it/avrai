// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
part of 'reservation_sharing_service.dart';

class _CachedCompatibility {
  final double compatibility;
  final DateTime cachedAt;

  _CachedCompatibility({
    required this.compatibility,
    required this.cachedAt,
  });
}
