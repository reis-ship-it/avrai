// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:convert';

import 'package:crypto/crypto.dart';

class GossipFingerprint {
  const GossipFingerprint({
    required this.messageHash,
    required this.scope,
  });

  final String messageHash;
  final String scope;

  static GossipFingerprint fromPayload(Map<String, dynamic> payload) {
    final messageHash =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    final scope = payload['scope'] as String? ?? 'locality';
    return GossipFingerprint(
      messageHash: messageHash,
      scope: scope,
    );
  }
}
