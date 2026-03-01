// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

class DiscoveryLoop {
  const DiscoveryLoop._();

  static Timer start({
    Duration interval = const Duration(minutes: 2),
    required Future<void> Function() discoverNearby,
    required void Function(Object error) onError,
  }) {
    return Timer.periodic(interval, (timer) async {
      try {
        await discoverNearby();
      } catch (e) {
        onError(e);
      }
    });
  }
}
