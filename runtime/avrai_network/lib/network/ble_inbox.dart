import 'dart:developer' as developer;

import 'package:flutter/services.dart';

class BleInboxMessage {
  final String senderId;
  final Uint8List data;
  final int receivedAtMs;

  const BleInboxMessage({
    required this.senderId,
    required this.data,
    required this.receivedAtMs,
  });
}

/// Dart access to the native BLE inbox (messages written to our GATT server).
///
/// This is used to process "silent" background AI2AI packets and establish
/// Signal sessions offline (Mode 2).
class BleInbox {
  static const MethodChannel _channel = MethodChannel('avra/ble_inbox');
  static const String _logName = 'BleInbox';

  static Future<List<BleInboxMessage>> pollMessages({
    int maxMessages = 50,
  }) async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pollMessages',
        <String, Object>{'maxMessages': maxMessages},
      );

      final list = result ?? const [];
      return list.whereType<Map>().map((m) => Map<String, Object?>.from(m)).map(
        (m) {
          final senderId = (m['senderId'] as String?) ?? '';
          final data = m['data'] as Uint8List? ?? Uint8List(0);
          final receivedAtMs = (m['receivedAtMs'] as int?) ?? 0;
          return BleInboxMessage(
            senderId: senderId,
            data: data,
            receivedAtMs: receivedAtMs,
          );
        },
      ).toList();
    } catch (e, st) {
      developer.log(
        'Failed to poll BLE inbox messages',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  static Future<bool> clearMessages() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearMessages');
      return result ?? false;
    } catch (e, st) {
      developer.log(
        'Failed to clear BLE inbox messages',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
