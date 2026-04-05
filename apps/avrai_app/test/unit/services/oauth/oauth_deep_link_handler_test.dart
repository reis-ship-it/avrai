import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/infrastructure/oauth/oauth_deep_link_handler.dart';

void main() {
  group('OAuthDeepLinkHandler', () {
    test('forwards avrai oauth callbacks with query parameters', () {
      final handler = OAuthDeepLinkHandler();
      String? receivedPlatform;
      Map<String, String>? receivedParams;

      handler.onOAuthCallback = (platform, params) {
        receivedPlatform = platform;
        receivedParams = params;
      };

      handler.handleDeepLink(Uri.parse(
        'avrai://oauth?platform=google&code=test-code&state=test-state',
      ));

      expect(receivedPlatform, equals('google'));
      expect(receivedParams, containsPair('code', 'test-code'));
      expect(receivedParams, containsPair('state', 'test-state'));
    });

    test('ignores non oauth deep links', () {
      final handler = OAuthDeepLinkHandler();
      var callbackCount = 0;

      handler.onOAuthCallback = (_, __) {
        callbackCount += 1;
      };

      handler.handleDeepLink(Uri.parse('avrai://profile'));

      expect(callbackCount, equals(0));
    });
  });
}
