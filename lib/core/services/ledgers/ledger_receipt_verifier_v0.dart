import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' show sha256;

import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_op_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_v0.dart';

/// Verifies v0 ledger receipts.
///
/// **Security model (v0):**
/// - Server mints an Ed25519 signature over a deterministic canonical JSON payload.
/// - Client recomputes canonical JSON from the live ledger row and verifies:
///   1) sha256(canonical_json) matches `sha256` in signature row
///   2) signature verifies with the configured public key for `key_id`
class LedgerReceiptVerifierV0 {
  static const String _defaultKeyId = 'v1';

  /// Base64-encoded Ed25519 public keys by key id.
  ///
  /// Rotate by adding a new key id and leaving old ones for verification.
  static const Map<String, String> _defaultPublicKeysB64 = <String, String>{
    // v0 receipts signing public key (Ed25519, 32 bytes, base64).
    //
    // This is safe to ship in the app. Rotate by adding a new key id and leaving
    // old ones for verification.
    _defaultKeyId: 'GALdZwF/fFvCKEajfD6hahFJHd7BZrpolxvt+7ST8vs=',
  };

  // Build-time override (recommended for release builds).
  //
  // Example:
  // --dart-define=LEDGER_RECEIPTS_PUBLIC_KEY_B64_V1=<base64 public key>
  static const String _pubKeyV1FromEnv =
      String.fromEnvironment('LEDGER_RECEIPTS_PUBLIC_KEY_B64_V1');

  final Ed25519 _ed25519;
  final Map<String, String> _publicKeysB64;

  LedgerReceiptVerifierV0({
    Ed25519? ed25519,
    Map<String, String>? publicKeysB64Override,
  })  : _ed25519 = ed25519 ?? Ed25519(),
        _publicKeysB64 = publicKeysB64Override ??
            <String, String>{
              ..._defaultPublicKeysB64,
              if (_pubKeyV1FromEnv.isNotEmpty) _defaultKeyId: _pubKeyV1FromEnv,
            };

  /// Verifies the receipt signature and sha256 (tamper-evident).
  Future<bool> verify(LedgerReceiptV0 receipt) async {
    final sig = receipt.signature;
    if (sig == null) return false;

    final keyId = sig.keyId.isEmpty ? _defaultKeyId : sig.keyId;
    final pkB64 = _publicKeysB64[keyId];
    if (pkB64 == null || pkB64.isEmpty) {
      return false;
    }

    final pkBytes = base64Decode(pkB64);
    if (pkBytes.length != 32) return false;

    final canonicalJson = canonicalJsonForEvent(receipt);
    final canonicalSha = sha256.convert(utf8.encode(canonicalJson)).toString();
    if (canonicalSha.toLowerCase() != sig.sha256.toLowerCase()) {
      return false;
    }

    final sigBytes = base64Decode(sig.signatureB64);
    if (sigBytes.length != 64) return false;

    final msgBytes = Uint8List.fromList(utf8.encode(canonicalJson));
    return await _ed25519.verify(
      msgBytes,
      signature: Signature(
        sigBytes,
        publicKey: SimplePublicKey(pkBytes, type: KeyPairType.ed25519),
      ),
    );
  }

  /// Build canonical JSON (must match server canonicalization exactly).
  String canonicalJsonForEvent(LedgerReceiptV0 receipt) {
    final e = receipt.event;
    final canonical = <String, Object?>{
      'receipt_schema_version': 0,
      'ledger_row_id': e.id,
      'domain': e.domain.wireName,
      'owner_user_id': e.ownerUserId,
      'owner_agent_id': e.ownerAgentId,
      'logical_id': e.logicalId,
      'revision': e.revision,
      'supersedes_id': e.supersedesId,
      'op': e.op.wireName,
      'event_type': e.eventType,
      'entity_type': e.entityType,
      'entity_id': e.entityId,
      'category': e.category,
      'city_code': e.cityCode,
      'locality_code': e.localityCode,
      'occurred_at': _formatIsoMillisUtc(e.occurredAt),
      'atomic_timestamp_id': e.atomicTimestampId,
      'payload': e.payload,
      'created_at': e.createdAt != null ? _formatIsoMillisUtc(e.createdAt!) : null,
    };

    final normalized = _canonicalize(canonical);
    return jsonEncode(normalized);
  }

  // ---------------------------------------------------------------------------
  // Canonicalization helpers
  // ---------------------------------------------------------------------------

  static String _formatIsoMillisUtc(DateTime dt) {
    // Match JS Date#toISOString(): YYYY-MM-DDTHH:mm:ss.SSSZ
    final u = dt.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final hh = u.hour.toString().padLeft(2, '0');
    final mm = u.minute.toString().padLeft(2, '0');
    final ss = u.second.toString().padLeft(2, '0');
    final ms = u.millisecond.toString().padLeft(3, '0');
    return '$y-$m-${d}T$hh:$mm:$ss.${ms}Z';
  }

  static Object? _canonicalize(Object? value) {
    if (value == null) return null;
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final out = <String, Object?>{};
      for (final k in keys) {
        out[k] = _canonicalize(value[k]);
      }
      return out;
    }
    return value;
  }
}

