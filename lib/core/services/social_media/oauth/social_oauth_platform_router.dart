import 'package:avrai/core/models/social_media/social_media_connection.dart';

typedef SocialConnectionFactory = Future<SocialMediaConnection> Function();

class SocialOAuthPlatformRouter {
  Future<SocialMediaConnection> route({
    required String platform,
    required Map<String, SocialConnectionFactory> handlers,
    required SocialConnectionFactory fallback,
  }) async {
    final handler = handlers[platform];
    if (handler != null) {
      return handler();
    }
    return fallback();
  }
}
