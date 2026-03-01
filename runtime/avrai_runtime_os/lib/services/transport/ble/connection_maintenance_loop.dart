// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

class ConnectionMaintenanceLoop {
  const ConnectionMaintenanceLoop._();

  static Timer start({
    Duration interval = const Duration(seconds: 30),
    required Future<void> Function() manageActiveConnections,
    required Future<void> Function() manageSessionLifecycle,
    required Future<void> Function() managePreKeyBundleRotation,
    required void Function(Object error) onError,
  }) {
    return Timer.periodic(interval, (timer) async {
      try {
        await manageActiveConnections();
        await manageSessionLifecycle();
        await managePreKeyBundleRotation();
      } catch (e) {
        onError(e);
      }
    });
  }
}
