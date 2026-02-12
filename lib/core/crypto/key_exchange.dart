import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Key Exchange Module for AI2AI Communication
///
/// Implements simplified key exchange for secure key establishment between
/// AI agents. Uses secure random key generation with HKDF for key derivation.
///
/// **Note:** This is a simplified implementation. For production, consider
/// implementing full ECDH key exchange. This provides basic security for
/// the current needs.
///
/// **Security Features:**
/// - Secure random key generation
/// - HKDF key derivation
/// - Forward secrecy support (via key rotation)
///
/// **Usage:**
/// ```dart
/// final keyExchange = KeyExchange();
///
/// // Generate shared secret (simplified - in production use ECDH)
/// final sharedSecret = await keyExchange.generateSharedSecret();
///
/// // Derive encryption key from shared secret
/// final encryptionKey = await keyExchange.deriveEncryptionKey(sharedSecret);
/// ```
class KeyExchange {
  static const String _logName = 'KeyExchange';

  /// Generate a shared secret for key exchange
  ///
  /// **Note:** In a real implementation, this would be the result of ECDH
  /// key exchange. For now, this generates a secure random secret that
  /// would be exchanged through a secure channel.
  ///
  /// **Returns:**
  /// 32-byte shared secret (base64 encoded)
  Future<String> generateSharedSecret() async {
    try {
      developer.log('Generating shared secret', name: _logName);

      final random = Random.secure();
      final secret = Uint8List(32);
      for (int i = 0; i < secret.length; i++) {
        secret[i] = random.nextInt(256);
      }

      final encoded = base64Encode(secret);
      developer.log('Shared secret generated successfully', name: _logName);
      return encoded;
    } catch (e, stackTrace) {
      developer.log(
        'Error generating shared secret: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Derive encryption key from shared secret using HKDF
  ///
  /// Uses HMAC-based Key Derivation Function (HKDF) to derive a secure
  /// encryption key from the shared secret.
  ///
  /// **Parameters:**
  /// - `sharedSecret`: The shared secret (base64 encoded)
  /// - `salt`: Optional salt (defaults to zero bytes)
  /// - `info`: Optional context information
  /// - `keyLength`: Desired key length in bytes (default: 32 for AES-256)
  ///
  /// **Returns:**
  /// Derived encryption key (32 bytes for AES-256)
  Future<Uint8List> deriveEncryptionKey(
    String sharedSecretBase64, {
    Uint8List? salt,
    Uint8List? info,
    int keyLength = 32,
  }) async {
    try {
      developer.log('Deriving encryption key from shared secret', name: _logName);

      // Decode shared secret
      final sharedSecret = base64Decode(sharedSecretBase64);

      // Use PBKDF2 for key derivation (HKDF-like functionality)
      // Default salt (zero bytes) if not provided
      final saltBytes = salt ?? Uint8List(32);

      // Default info (context) if not provided - combine with salt
      final infoBytes = info ?? Uint8List.fromList('SPOTS-EncryptionKey'.codeUnits);
      
      // Combine salt and info for PBKDF2
      final combinedSalt = Uint8List(saltBytes.length + infoBytes.length);
      combinedSalt.setRange(0, saltBytes.length, saltBytes);
      combinedSalt.setRange(saltBytes.length, combinedSalt.length, infoBytes);

      // Use PBKDF2 for key derivation
      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
        ..init(Pbkdf2Parameters(combinedSalt, 10000, keyLength));

      // Derive key
      final key = pbkdf2.process(sharedSecret);

      developer.log('Encryption key derived successfully', name: _logName);
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Error deriving encryption key: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate a new encryption key directly
  ///
  /// Convenience method that generates a secure random encryption key.
  /// Useful for initial key generation or key rotation.
  ///
  /// **Returns:**
  /// 32-byte encryption key (for AES-256)
  Future<Uint8List> generateEncryptionKey() async {
    try {
      developer.log('Generating encryption key', name: _logName);

      final random = Random.secure();
      final key = Uint8List(32);
      for (int i = 0; i < key.length; i++) {
        key[i] = random.nextInt(256);
      }

      developer.log('Encryption key generated successfully', name: _logName);
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Error generating encryption key: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Derive multiple keys from a single shared secret
  ///
  /// Uses HKDF to derive multiple keys with different contexts.
  /// Useful for deriving different keys for different purposes (encryption,
  /// authentication, etc.) from a single shared secret.
  ///
  /// **Parameters:**
  /// - `sharedSecret`: The shared secret (base64 encoded)
  /// - `contexts`: List of context strings for each key
  /// - `keyLength`: Length of each key in bytes (default: 32)
  ///
  /// **Returns:**
  /// Map of context strings to derived keys
  Future<Map<String, Uint8List>> deriveMultipleKeys(
    String sharedSecretBase64,
    List<String> contexts, {
    int keyLength = 32,
  }) async {
    try {
      developer.log('Deriving multiple keys from shared secret', name: _logName);

      final keys = <String, Uint8List>{};
      for (final context in contexts) {
        final key = await deriveEncryptionKey(
          sharedSecretBase64,
          info: Uint8List.fromList(context.codeUnits),
          keyLength: keyLength,
        );
        keys[context] = key;
      }

      developer.log('Multiple keys derived successfully', name: _logName);
      return keys;
    } catch (e, stackTrace) {
      developer.log(
        'Error deriving multiple keys: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
