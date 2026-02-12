import 'dart:developer' as developer;

import 'package:flutter/services.dart';

/// Cross-platform BLE peripheral bridge used for Option B (BLE handshake).
///
/// - Android implementation runs inside the app's foreground service runtime.
/// - iOS implementation uses CoreBluetooth `CBPeripheralManager`.
///
/// This is intentionally minimal: it makes the device discoverable and exposes a
/// GATT characteristic that other devices can read to fetch the current payload.
class BlePeripheral {
  static const MethodChannel _channel = MethodChannel('avra/ble_peripheral');
  static const String _logName = 'BlePeripheral';

  /// Start advertising and hosting the SPOTS GATT service.
  ///
  /// `payload` should be small-ish (a few KB max). It will be returned as the
  /// value of the SPOTS "read" characteristic.
  static Future<bool> startPeripheral({required Uint8List payload}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startPeripheral',
        <String, Object>{'payload': payload},
      );
      return result ?? false;
    } catch (e, st) {
      developer.log('Failed to start BLE peripheral',
          name: _logName, error: e, stackTrace: st);
      return false;
    }
  }

  /// Stop advertising and hosting the SPOTS GATT service.
  static Future<bool> stopPeripheral() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopPeripheral');
      return result ?? false;
    } catch (e, st) {
      developer.log('Failed to stop BLE peripheral',
          name: _logName, error: e, stackTrace: st);
      return false;
    }
  }

  /// Update the current payload served by the SPOTS read characteristic.
  static Future<bool> updatePayload({required Uint8List payload}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updatePayload',
        <String, Object>{'payload': payload},
      );
      return result ?? false;
    } catch (e, st) {
      developer.log('Failed to update BLE peripheral payload',
          name: _logName, error: e, stackTrace: st);
      return false;
    }
  }

  /// Update the current Signal prekey payload served by the SPOTS stream-1 read.
  static Future<bool> updatePreKeyPayload({required Uint8List payload}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updatePreKeyPayload',
        <String, Object>{'payload': payload},
      );
      return result ?? false;
    } catch (e, st) {
      developer.log('Failed to update BLE peripheral prekey payload',
          name: _logName, error: e, stackTrace: st);
      return false;
    }
  }

  /// Update the current Service Data payload for the SPOTS service UUID.
  ///
  /// This is used for the 24-byte Event Mode frame v1 broadcast (connectionless sensing).
  /// Platform implementations may restart advertising for the update to take effect.
  static Future<bool> updateServiceDataFrameV1({
    required Uint8List frame,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateServiceDataFrameV1',
        <String, Object>{'frame': frame},
      );
      return result ?? false;
    } catch (e, st) {
      developer.log('Failed to update BLE peripheral service-data frame v1',
          name: _logName, error: e, stackTrace: st);
      return false;
    }
  }
}

