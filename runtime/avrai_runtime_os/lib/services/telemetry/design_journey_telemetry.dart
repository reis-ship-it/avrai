import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';

class DesignJourneyTelemetry {
  const DesignJourneyTelemetry._();

  static Future<void> log(
    String eventName, {
    Map<String, Object> params = const {},
  }) async {
    developer.log(
      'event=$eventName params=$params',
      name: 'DesignJourneyTelemetry',
    );

    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.logEvent(name: eventName, parameters: params);
    } catch (_) {
      // Analytics may be unavailable in some environments; logs still preserve signal.
    }
  }
}
