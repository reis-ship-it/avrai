import 'dart:developer' as developer;

import 'package:flutter/services.dart';

/// Thin Flutter ↔ Android bridge for keeping background BLE work alive.
///
/// Android requires a foreground service (and a persistent notification) for
/// continuous background BLE scanning/advertising.
///
/// iOS does not use this channel; iOS background BLE is configured separately
/// via background modes + CoreBluetooth.
class BleForegroundService {
  static const MethodChannel _channel = MethodChannel('avra/ble_foreground');
  static const String _logName = 'BleForegroundService';

  /// Starts the Android foreground service that keeps the process alive.
  ///
  /// Returns `false` if the platform call fails or is unsupported.
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startService');
      return result ?? false;
    } catch (e, st) {
      developer.log(
        'Failed to start BLE foreground service',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Stops the Android foreground service.
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } catch (e, st) {
      developer.log(
        'Failed to stop BLE foreground service',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Updates the desired scan interval (in milliseconds) for adaptive background BLE.
  ///
  /// This is used by the Android foreground service runtime as we layer in
  /// native BLE scan/advertise + GATT handshake work.
  static Future<bool> updateScanInterval(Duration interval) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateScanInterval',
        <String, Object>{'intervalMs': interval.inMilliseconds},
      );
      return result ?? false;
    } catch (e, st) {
      developer.log(
        'Failed to update scan interval',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
