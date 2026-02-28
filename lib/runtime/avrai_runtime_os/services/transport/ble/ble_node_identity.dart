import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class BleNodeIdentity {
  const BleNodeIdentity({
    required this.nodeId,
    required this.nodeTagKey,
  });

  final String nodeId;
  final String nodeTagKey;

  static Future<BleNodeIdentity> ensure({
    required SharedPreferencesCompat prefs,
    required String prefsKeyNodeId,
    required String prefsKeyNodeIdExpiresAtMs,
    int validityHours = 24,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final storedId = prefs.getString(prefsKeyNodeId);
    final expiresAtMs = prefs.getInt(prefsKeyNodeIdExpiresAtMs) ?? 0;

    if (storedId != null && storedId.isNotEmpty && expiresAtMs > nowMs) {
      return BleNodeIdentity(
        nodeId: storedId,
        nodeTagKey: _nodeTagKeyFromNodeId(storedId),
      );
    }

    final nodeId = const Uuid().v4();
    final newExpiresAtMs =
        DateTime.now().add(Duration(hours: validityHours)).millisecondsSinceEpoch;
    await prefs.setString(prefsKeyNodeId, nodeId);
    await prefs.setInt(prefsKeyNodeIdExpiresAtMs, newExpiresAtMs);
    return BleNodeIdentity(
      nodeId: nodeId,
      nodeTagKey: _nodeTagKeyFromNodeId(nodeId),
    );
  }

  static String nodeTagKeyFromBytes(List<int> bytes4) {
    if (bytes4.length < 4) return bytes4.join(',');
    return '${bytes4[0]}-${bytes4[1]}-${bytes4[2]}-${bytes4[3]}';
  }

  static String _nodeTagKeyFromNodeId(String nodeId) {
    final digest = sha256.convert(utf8.encode(nodeId));
    final tagBytes = digest.bytes.sublist(0, 4);
    return nodeTagKeyFromBytes(tagBytes);
  }
}
