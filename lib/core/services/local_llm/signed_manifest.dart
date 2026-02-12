import 'dart:convert';
import 'dart:typed_data';

class LocalLlmSignedManifestEnvelope {
  final String keyId;
  final String payloadB64;
  final String signatureB64;

  const LocalLlmSignedManifestEnvelope({
    required this.keyId,
    required this.payloadB64,
    required this.signatureB64,
  });

  factory LocalLlmSignedManifestEnvelope.fromJson(Map<String, dynamic> json) {
    return LocalLlmSignedManifestEnvelope(
      keyId: (json['key_id'] as String?) ?? '',
      payloadB64: (json['payload_b64'] as String?) ?? '',
      signatureB64: (json['sig_b64'] as String?) ?? '',
    );
  }

  Uint8List payloadBytes() => base64Decode(payloadB64);
  Uint8List signatureBytes() => base64Decode(signatureB64);
}

