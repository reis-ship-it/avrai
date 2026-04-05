// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_core/models/social_media/social_media_connection.dart';

class SocialPlaceholderProfileBuilder {
  const SocialPlaceholderProfileBuilder._();

  static Map<String, dynamic> build(SocialMediaConnection connection) {
    switch (connection.platform) {
      case 'google':
        return {
          'profile': {
            'name': connection.platformUsername ?? 'Google User',
            'email': 'user@example.com',
          },
          'savedPlaces': [],
          'reviews': [],
          'photos': [],
          'locationHistory': null,
        };
      case 'instagram':
      case 'facebook':
      case 'twitter':
      case 'tiktok':
      case 'linkedin':
      default:
        return {
          'profile': {
            'name':
                connection.platformUsername ?? '${connection.platform} User',
            'username': connection.platformUsername,
          },
          'follows': [],
          'posts': [],
        };
    }
  }
}
