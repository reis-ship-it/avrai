import 'package:avrai/core/models/social_media/social_media_connection.dart';

/// Base interface for platform-specific social media connection services
///
/// Each platform (Google, Instagram, Facebook, etc.) implements this interface
/// to provide platform-specific OAuth and data fetching logic.
abstract class SocialMediaPlatformService {
  /// Platform name (e.g., 'google', 'instagram', 'facebook')
  String get platformName;

  /// Connect to the platform (runs OAuth flow and stores tokens)
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// SocialMediaConnection record after successful OAuth
  ///
  /// **Throws:**
  /// Exception if OAuth flow fails
  Future<SocialMediaConnection> connect({
    required String agentId,
    required String userId,
  });

  /// Disconnect from the platform (removes tokens and connection)
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  ///
  /// **Throws:**
  /// Exception if disconnection fails
  Future<void> disconnect({
    required String agentId,
  });

  /// Fetch profile data from the platform
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record
  ///
  /// **Returns:**
  /// Map with profile data (platform-specific structure)
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  );

  /// Fetch follows/connections from the platform
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record
  ///
  /// **Returns:**
  /// List of follow/connection data
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  );

  /// Refresh OAuth tokens if needed
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record
  ///
  /// **Returns:**
  /// true if token was refreshed, false otherwise
  Future<bool> refreshToken(SocialMediaConnection connection);
}
