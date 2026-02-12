import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'signed_manifest.dart';

class LocalLlmSignedManifestVerifier {
  static const String _defaultKeyId = 'v1';

  /// Base64-encoded Ed25519 public keys by key id.
  ///
  /// Rotate by adding a new key id and leaving old ones for verification.
  static const Map<String, String> _defaultPublicKeysB64 = <String, String>{};

  // Build-time override (recommended for release builds).
  //
  // Example:
  // --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<base64 public key>
  static const String _pubKeyV1FromEnv =
      String.fromEnvironment('LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1');

  final Ed25519 _ed25519;
  final Map<String, String> _publicKeysB64;

  LocalLlmSignedManifestVerifier({
    Ed25519? ed25519,
    Map<String, String>? publicKeysB64Override,
  })  : _ed25519 = ed25519 ?? Ed25519(),
        _publicKeysB64 = publicKeysB64Override ??
            <String, String>{
              ..._defaultPublicKeysB64,
              if (_pubKeyV1FromEnv.isNotEmpty) _defaultKeyId: _pubKeyV1FromEnv,
            };

  Future<Uint8List> verifyAndExtractPayloadBytes(
    LocalLlmSignedManifestEnvelope envelope,
  ) async {
    final keyId = envelope.keyId.isEmpty ? _defaultKeyId : envelope.keyId;
    final pkB64 = _publicKeysB64[keyId];
    if (pkB64 == null || pkB64.isEmpty) {
      throw Exception(
        'Signing public key not configured for key_id=$keyId. '
        'Set --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=... or pass publicKeysB64Override.',
      );
    }

    final pkBytes = base64Decode(pkB64);
    if (pkBytes.length != 32) {
      throw Exception('Invalid public key length for key_id=$keyId');
    }

    final payload = envelope.payloadBytes();
    final sig = envelope.signatureBytes();
    if (sig.length != 64) {
      throw Exception('Invalid signature length');
    }

    final ok = await _ed25519.verify(
      payload,
      signature: Signature(
        sig,
        publicKey: SimplePublicKey(pkBytes, type: KeyPairType.ed25519),
      ),
    );
    if (!ok) {
      throw Exception('Manifest signature verification failed');
    }

    return payload;
  }
}

