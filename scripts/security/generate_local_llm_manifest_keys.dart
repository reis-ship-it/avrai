import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final ed = Ed25519();

  // Generate a random 32-byte seed for Ed25519 signing.
  final rng = Random.secure();
  final seed = Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
  final kp = await ed.newKeyPairFromSeed(seed);
  final pk = await kp.extractPublicKey();

  final signingKeyB64 = base64Encode(seed);
  final publicKeyB64 = base64Encode(pk.bytes);

  // Output in a copy/paste friendly format.
  // IMPORTANT: Treat signingKeyB64 like a password (server-only secret).
  //
  // Supabase secrets:
  // - LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<signingKeyB64>
  // - LOCAL_LLM_MANIFEST_KEY_ID=v1
  //
  // App build:
  // - --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<publicKeyB64>
  final out = <String, dynamic>{
    'key_id': 'v1',
    'LOCAL_LLM_MANIFEST_SIGNING_KEY_B64': signingKeyB64,
    'LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1': publicKeyB64,
  };
  // ignore: avoid_print
  print(const JsonEncoder.withIndent('  ').convert(out));
}

