import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// AES-256-GCM codec for a caller-supplied fixed key.
///
/// This is used for "Sender Keys" style group messaging:
/// - group key is distributed rarely (Signal-encrypted shares)
/// - each message is encrypted ONCE with the shared key
class Aes256GcmFixedKeyCodec {
  static const int _ivLength = 12; // 96-bit recommended for GCM
  static const int _tagLengthBytes = 16; // 128-bit tag

  static Uint8List encryptBytes({
    required Uint8List key32,
    required Uint8List plaintext,
  }) {
    if (key32.length != 32) {
      throw ArgumentError('Expected 32-byte key, got ${key32.length}');
    }

    final iv = _generateIv();
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key32),
          128,
          iv,
          Uint8List(0),
        ),
      );

    final ciphertext = cipher.process(plaintext);
    final tag = cipher.mac;

    final out = Uint8List(iv.length + ciphertext.length + tag.length);
    out.setRange(0, iv.length, iv);
    out.setRange(iv.length, iv.length + ciphertext.length, ciphertext);
    out.setRange(iv.length + ciphertext.length, out.length, tag);
    return out;
  }

  static Uint8List decryptBytes({
    required Uint8List key32,
    required Uint8List encrypted,
  }) {
    if (key32.length != 32) {
      throw ArgumentError('Expected 32-byte key, got ${key32.length}');
    }
    if (encrypted.length < _ivLength + _tagLengthBytes) {
      throw ArgumentError('Invalid encrypted length: ${encrypted.length}');
    }

    final iv = encrypted.sublist(0, _ivLength);
    final tag = encrypted.sublist(encrypted.length - _tagLengthBytes);
    final ciphertext = encrypted.sublist(_ivLength, encrypted.length - _tagLengthBytes);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(
        KeyParameter(key32),
        128,
        iv,
        Uint8List(0),
      ),
    );

    final plaintext = cipher.process(ciphertext);
    final calculatedTag = cipher.mac;
    if (!_constantTimeEquals(tag, calculatedTag)) {
      throw StateError('Authentication tag mismatch');
    }
    return plaintext;
  }

  static String encryptStringToBase64({
    required Uint8List key32,
    required String plaintext,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(plaintext));
    return base64Encode(encryptBytes(key32: key32, plaintext: bytes));
  }

  static String decryptBase64ToString({
    required Uint8List key32,
    required String ciphertextBase64,
  }) {
    final encrypted = base64Decode(ciphertextBase64);
    final plaintext = decryptBytes(key32: key32, encrypted: encrypted);
    return utf8.decode(plaintext);
  }

  static Uint8List _generateIv() {
    final random = math.Random.secure();
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

