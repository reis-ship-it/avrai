import 'dart:convert';

import 'package:crypto/crypto.dart';

class EventModeInitiatorPolicy {
  const EventModeInitiatorPolicy._();

  static bool mayInitiate({
    required String localBleNodeId,
    required int epoch,
    required int eligibilityPercent,
  }) {
    final value = _hashMod('$localBleNodeId:$epoch', mod: 100);
    return value < eligibilityPercent;
  }

  static int jitterMs({
    required String localBleNodeId,
    required int epoch,
    int maxJitterMs = 1500,
  }) {
    return _hashMod('$localBleNodeId:$epoch', mod: maxJitterMs);
  }

  static bool isTieBreakInitiator({
    required String localNodeTagKey,
    required String remoteNodeTagKey,
    required int epoch,
  }) {
    final localFirst = _hashU32('$localNodeTagKey:$remoteNodeTagKey:$epoch');
    final remoteFirst = _hashU32('$remoteNodeTagKey:$localNodeTagKey:$epoch');
    return localFirst < remoteFirst;
  }

  static int _hashU32(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  static int _hashMod(String input, {required int mod}) {
    final value = _hashU32(input) & 0x7FFFFFFF;
    return value % mod;
  }
}
