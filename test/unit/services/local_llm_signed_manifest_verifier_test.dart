import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/local_llm/signed_manifest.dart';
import 'package:avrai/core/services/local_llm/signed_manifest_verifier.dart';

// #region agent debug log helpers
void _agentLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
}) {
  try {
    final payload = <String, Object?>{
      'sessionId': 'debug-session',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/reisgordon/SPOTS/.cursor/debug.log').writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // Best-effort: never fail tests due to debug logging.
  }
}
// #endregion

void main() {
  test('verifies signed manifest payload and rejects tampering', () async {
    const runId = 'pre-fix';
    final ed = Ed25519();
    final kp = await ed.newKeyPair();
    final pk = await kp.extractPublicKey();
    final sk = await kp.extractPrivateKeyBytes();

    final payload = utf8.encode('{"hello":"world"}');
    final sig = await ed.sign(payload, keyPair: kp);

    _agentLog(
      runId: runId,
      hypothesisId: 'H-D',
      location: 'local_llm_signed_manifest_verifier_test.dart:seedless',
      message: 'generated keypair + signature',
      data: {
        'payloadLen': payload.length,
        'sigLen': sig.bytes.length,
        'pubKeyLen': pk.bytes.length,
        'privateKeyLen': sk.length,
      },
    );

    final verifier = LocalLlmSignedManifestVerifier(
      publicKeysB64Override: <String, String>{
        'v1': base64Encode(pk.bytes),
      },
    );

    final envelope = LocalLlmSignedManifestEnvelope(
      keyId: 'v1',
      payloadB64: base64Encode(payload),
      signatureB64: base64Encode(sig.bytes),
    );

    final out = await verifier.verifyAndExtractPayloadBytes(envelope);
    expect(utf8.decode(out), equals('{"hello":"world"}'));

    // Tamper.
    final tampered = LocalLlmSignedManifestEnvelope(
      keyId: 'v1',
      payloadB64: base64Encode(utf8.encode('{"hello":"hacked"}')),
      signatureB64: base64Encode(sig.bytes),
    );

    expect(
      () => verifier.verifyAndExtractPayloadBytes(tampered),
      throwsA(isA<Exception>()),
    );

    _agentLog(
      runId: runId,
      hypothesisId: 'H-C',
      location: 'local_llm_signed_manifest_verifier_test.dart:tamper',
      message: 'tampered payload expected to fail verification',
      data: {
        'tamperedPayloadLen': utf8.encode('{"hello":"hacked"}').length,
        'sigLen': sig.bytes.length,
      },
    );

    // Also ensure we actually used the keypair (avoid analyzer optimizing away).
    expect(sk.length, greaterThan(0));
  });

  test('fails without configured public key (no override, no env)', () async {
    const runId = 'pre-fix';

    final ed = Ed25519();
    final kp = await ed.newKeyPair();
    final payload = utf8.encode('{"hello":"world"}');
    final sig = await ed.sign(payload, keyPair: kp);

    final verifier = LocalLlmSignedManifestVerifier();
    final envelope = LocalLlmSignedManifestEnvelope(
      keyId: 'v1',
      payloadB64: base64Encode(payload),
      signatureB64: base64Encode(sig.bytes),
    );

    try {
      await verifier.verifyAndExtractPayloadBytes(envelope);
      _agentLog(
        runId: runId,
        hypothesisId: 'H-A',
        location: 'local_llm_signed_manifest_verifier_test.dart:defaultKey',
        message: 'unexpected success verifying with default keys',
      );
      fail('Expected verification to fail without configured public key');
    } catch (e) {
      expect(e.toString(), contains('Signing public key not configured'));
      _agentLog(
        runId: runId,
        hypothesisId: 'H-A',
        location: 'local_llm_signed_manifest_verifier_test.dart:defaultKey',
        message: 'failed as expected without configured public key',
        data: {
          'errorType': e.runtimeType.toString(),
          'error': e.toString(),
        },
      );
    }
  });
}

