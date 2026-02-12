import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Message Encryption Service Abstraction
///
/// Provides encryption abstraction for messages, ready for Signal Protocol upgrade.
/// Currently uses AES-256-GCM, but can be swapped for Signal Protocol implementation.
///
/// **Signal Protocol Ready:**
/// - Abstract interface allows swapping implementations
/// - Message models include encryption_type field
/// - Can switch from AES-256-GCM to Signal Protocol without breaking changes
abstract class MessageEncryptionService {
  /// Encrypt a message for a recipient.
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId);

  /// Decrypt a message from a sender.
  Future<String> decrypt(EncryptedMessage encrypted, String senderId);

  /// Get the encryption type this service provides.
  EncryptionType get encryptionType;
}

/// Encrypted message data structure.
class EncryptedMessage {
  final Uint8List encryptedContent;
  final EncryptionType encryptionType;

  /// Optional metadata for future Signal Protocol session info, etc.
  final Map<String, dynamic>? metadata;

  EncryptedMessage({
    required this.encryptedContent,
    required this.encryptionType,
    this.metadata,
  });

  /// Convert to base64 string for storage.
  String toBase64() => base64Encode(encryptedContent);

  /// Create from base64 string.
  factory EncryptedMessage.fromBase64(
    String base64,
    EncryptionType type, {
    Map<String, dynamic>? metadata,
  }) {
    return EncryptedMessage(
      encryptedContent: base64Decode(base64),
      encryptionType: type,
      metadata: metadata,
    );
  }
}

/// Encryption type enum.
enum EncryptionType {
  aes256gcm,
  signalProtocol,
}

/// AES-256-GCM Encryption Service Implementation.
///
/// Current implementation using AES-256-GCM authenticated encryption.
/// This can be swapped for SignalProtocolEncryptionService when Signal Protocol is implemented.
class AES256GCMEncryptionService implements MessageEncryptionService {
  static const String _logName = 'AES256GCMEncryptionService';

  // Key management - in production, keys should be derived from shared secrets.
  // For now, using a simple key derivation (should be replaced with proper key exchange).
  final Map<String, Uint8List> _sessionKeys = {};

  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  /// Get or generate session key for a recipient.
  ///
  /// TODO(Phase 14): Replace with proper key exchange (ECDH + PBKDF2) when Signal Protocol is implemented.
  Future<Uint8List> _getOrGenerateSessionKey(String recipientId) async {
    if (_sessionKeys.containsKey(recipientId)) {
      return _sessionKeys[recipientId]!;
    }

    final random = math.Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }

    _sessionKeys[recipientId] = key;
    developer.log(
      'Generated session key for recipient: $recipientId',
      name: _logName,
    );
    return key;
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    try {
      final key = await _getOrGenerateSessionKey(recipientId);
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

      final iv = _generateIV();
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(
            KeyParameter(key),
            128,
            iv,
            Uint8List(0),
          ),
        );

      final ciphertext = cipher.process(plaintextBytes);
      final tag = cipher.mac;

      // Combine: IV + ciphertext + tag
      final encrypted = Uint8List(iv.length + ciphertext.length + tag.length);
      encrypted.setRange(0, iv.length, iv);
      encrypted.setRange(iv.length, iv.length + ciphertext.length, ciphertext);
      encrypted.setRange(iv.length + ciphertext.length, encrypted.length, tag);

      developer.log('Message encrypted for recipient: $recipientId', name: _logName);
      return EncryptedMessage(
        encryptedContent: encrypted,
        encryptionType: EncryptionType.aes256gcm,
      );
    } catch (e) {
      developer.log('Error encrypting message: $e', name: _logName);
      throw Exception('Encryption failed: $e');
    }
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    try {
      if (encrypted.encryptionType != EncryptionType.aes256gcm) {
        throw Exception('Unsupported encryption type: ${encrypted.encryptionType}');
      }

      final key = await _getOrGenerateSessionKey(senderId);
      final encryptedBytes = encrypted.encryptedContent;

      // Extract IV, ciphertext, and tag
      if (encryptedBytes.length < 12 + 16) {
        throw Exception('Invalid encrypted data length: ${encryptedBytes.length}');
      }

      final iv = encryptedBytes.sublist(0, 12);
      final tag = encryptedBytes.sublist(encryptedBytes.length - 16);
      final ciphertext = encryptedBytes.sublist(12, encryptedBytes.length - 16);

      final cipher = GCMBlockCipher(AESEngine());
      cipher.init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          Uint8List(0),
        ),
      );

      final plaintext = cipher.process(ciphertext);

      // Verify authentication tag (prevents tampering).
      final calculatedTag = cipher.mac;
      if (!_constantTimeEquals(tag, calculatedTag)) {
        throw Exception('Authentication tag mismatch - message may be tampered');
      }

      developer.log('Message decrypted from sender: $senderId', name: _logName);
      return utf8.decode(plaintext);
    } catch (e) {
      developer.log('Error decrypting message: $e', name: _logName);
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate random IV (Initialization Vector) for AES-GCM.
  Uint8List _generateIV() {
    final random = math.Random.secure();
    final iv = Uint8List(12);
    for (int i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

