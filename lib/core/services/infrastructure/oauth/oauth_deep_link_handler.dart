// MIGRATION_SHIM: Legacy infrastructure oauth handler retained temporarily.
import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:avrai/core/services/infrastructure/oauth/oauth_runtime.dart';

/// OAuth deep-link runtime for callback capture.
///
/// Handles callback links like:
/// `avrai://oauth?platform=...&code=...&state=...`
class OAuthDeepLinkHandler implements OAuthRuntime {
  static const String _logName = 'OAuthDeepLinkHandler';
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Callback for OAuth completion.
  Function(String platform, Map<String, String> params)? onOAuthCallback;

  /// Start listening for deep links.
  @override
  void startListening() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        developer.log('Deep link error: $err', name: _logName);
      },
    );

    developer.log('Started listening for OAuth deep links', name: _logName);
  }

  void _handleDeepLink(Uri uri) {
    developer.log('Received deep link: $uri', name: _logName);

    if (uri.scheme == 'avrai' && uri.host == 'oauth') {
      final platform = uri.queryParameters['platform'] ?? 'unknown';

      developer.log(
        'OAuth callback received for platform: $platform',
        name: _logName,
      );

      final params = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        params[key] = value;
      });

      onOAuthCallback?.call(platform, params);
    }
  }

  /// Returns the initial launch deep link, if any.
  @override
  Future<Uri?> getInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        developer.log('Initial deep link: $initialLink', name: _logName);
        _handleDeepLink(initialLink);
      }
      return initialLink;
    } catch (e) {
      developer.log('Error getting initial link: $e', name: _logName);
      return null;
    }
  }

  /// Stop listening and release subscriptions.
  @override
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    developer.log('Stopped listening for OAuth deep links', name: _logName);
  }
}
