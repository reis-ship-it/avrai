import 'dart:async';

import 'package:avrai/core/services/infrastructure/logger.dart';

class SocialRequestThrottle {
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};

  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 60;
  static const Duration _minRequestDelay = Duration(milliseconds: 100);

  Future<void> checkRateLimit({
    required String platform,
    required AppLogger logger,
    required String logName,
  }) async {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[platform];
    final requestCount = _requestCount[platform] ?? 0;

    if (lastRequest == null || now.difference(lastRequest) > _rateLimitWindow) {
      _requestCount[platform] = 0;
      _lastRequestTime[platform] = now;
      return;
    }

    if (requestCount >= _maxRequestsPerWindow) {
      final waitTime = _rateLimitWindow - now.difference(lastRequest);
      logger.warn(
        'Rate limit reached for $platform, waiting ${waitTime.inSeconds}s',
        tag: logName,
      );
      await Future.delayed(waitTime);
      _requestCount[platform] = 0;
      _lastRequestTime[platform] = DateTime.now();
      return;
    }

    final timeSinceLastRequest = now.difference(lastRequest);
    if (timeSinceLastRequest < _minRequestDelay) {
      await Future.delayed(_minRequestDelay - timeSinceLastRequest);
    }
  }

  void updateRateLimitTracking(String platform) {
    final now = DateTime.now();
    _lastRequestTime[platform] = now;
    _requestCount[platform] = (_requestCount[platform] ?? 0) + 1;
  }

  String extractPlatformFromUrl(String url) {
    if (url.contains('googleapis.com')) return 'google';
    if (url.contains('instagram.com')) return 'instagram';
    if (url.contains('facebook.com')) return 'facebook';
    return 'unknown';
  }
}
