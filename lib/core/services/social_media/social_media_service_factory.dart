import 'package:avrai/core/services/social_media/base/social_media_platform_service.dart';

/// Factory for creating platform-specific social media services
///
/// Routes platform names to appropriate service implementations.
/// This allows the main SocialMediaConnectionService to delegate
/// platform-specific logic to specialized services.
class SocialMediaServiceFactory {
  final Map<String, SocialMediaPlatformService> _services;

  SocialMediaServiceFactory({
    required Map<String, SocialMediaPlatformService> services,
  }) : _services = services;

  /// Get platform service for a given platform name
  ///
  /// **Parameters:**
  /// - `platform`: Platform name (e.g., 'google', 'instagram', 'facebook')
  ///
  /// **Returns:**
  /// Platform-specific service, or null if platform is not supported
  SocialMediaPlatformService? getService(String platform) {
    final normalizedPlatform = platform.toLowerCase();
    return _services[normalizedPlatform];
  }

  /// Check if a platform is supported
  bool isSupported(String platform) {
    return _services.containsKey(platform.toLowerCase());
  }

  /// Get all supported platforms
  List<String> getSupportedPlatforms() {
    return _services.keys.toList();
  }
}
