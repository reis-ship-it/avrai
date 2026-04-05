// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_core/models/social_media/social_media_connection.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class SocialTokenRefreshLane {
  const SocialTokenRefreshLane._();

  static Future<bool> refreshIfNeeded({
    required String platform,
    required Future<List<SocialMediaConnection>> Function(String platform)
        getAllConnectionsForPlatform,
    required Future<bool> Function(SocialMediaConnection connection)
        refreshForConnection,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      const platforms = <String>['google', 'instagram', 'facebook'];
      for (final candidatePlatform in platforms) {
        final connections =
            await getAllConnectionsForPlatform(candidatePlatform);
        for (final connection in connections) {
          if (connection.platform == platform && connection.isActive) {
            return refreshForConnection(connection);
          }
        }
      }
      return false;
    } catch (e) {
      logger.error('Failed to refresh token: $e', tag: logName);
      return false;
    }
  }

  static bool shouldRefreshToken({
    required String? expiresAtIso8601,
    DateTime? now,
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (expiresAtIso8601 == null) return true;
    try {
      final expiresAt = DateTime.parse(expiresAtIso8601);
      return expiresAt.difference(now ?? DateTime.now()) <= threshold;
    } catch (_) {
      // If parsing fails, fail safe and refresh.
      return true;
    }
  }
}
