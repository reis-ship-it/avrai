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
