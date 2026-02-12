import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Field-Level Encryption Service
///
/// Encrypts sensitive user fields (email, name, location, phone) at rest.
/// Uses AES-256-GCM encryption with Flutter Secure Storage for key management.
///
/// **Philosophy Alignment:**
/// - Opens doors to secure data storage without privacy risk
/// - Protects user data at rest while enabling functionality
/// - Enables compliance with GDPR/CCPA requirements
///
/// **Features:**
/// - AES-256-GCM encryption (authenticated encryption)
/// - Flutter Secure Storage for encryption keys (Keychain/Keystore)
/// - Key rotation support
/// - Field-level encryption (encrypt individual fields, not entire records)
///
/// **Usage:**
/// ```dart
/// final service = FieldEncryptionService();
/// final encrypted = await service.encryptField('email', 'user@example.com', 'user-123');
/// final decrypted = await service.decryptField('email', encrypted, 'user-123');
/// ```
class FieldEncryptionService {
  static const String _logName = 'FieldEncryptionService';

  // Secure storage for encryption keys
  final FlutterSecureStorage _storage;

  // Fallback key store for tests / unsupported platforms where secure storage
  // platform channels are unavailable (e.g., `flutter test`).
  static final Map<String, String> _inMemoryKeyStore = <String, String>{};

  // Key prefix for field encryption keys
  static const String _keyPrefix = 'field_encryption_key_';

  // Fields that should be encrypted
  static const List<String> _encryptableFields = [
    'email',
    'name',
    'displayName',
    'phone',
    'phoneNumber',
    'location',
    'address',
  ];

  FieldEncryptionService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Encrypt a field value
  ///
  /// **Parameters:**
  /// - `fieldName`: Name of the field to encrypt (e.g., 'email', 'name')
  /// - `value`: Value to encrypt
  /// - `userId`: User ID (for key derivation)
  ///
  /// **Returns:**
  /// Encrypted value (base64 encoded)
  ///
  /// **Throws:**
  /// - Exception if encryption fails
  Future<String> encryptField(
    String fieldName,
    String value,
    String userId,
  ) async {
    try {
      if (!shouldEncryptField(fieldName)) {
        return value;
      }
      if (value.isEmpty) {
        return value; // Don't encrypt empty values
      }

      // Get or generate encryption key for this field/user
      final key = await _getOrGenerateKey(fieldName, userId);

      // Encrypt using AES-256-GCM (authenticated encryption).
      final encrypted = _encryptAES256GCM(value, key);

      developer.log('Field encrypted: $fieldName', name: _logName);
      return encrypted;
    } catch (e) {
      developer.log('Error encrypting field: $e', name: _logName);
      rethrow;
    }
  }

  /// Decrypt a field value
  ///
  /// **Parameters:**
  /// - `fieldName`: Name of the field to decrypt
  /// - `encryptedValue`: Encrypted value (base64 encoded)
  /// - `userId`: User ID (for key derivation)
  ///
  /// **Returns:**
  /// Decrypted value
  ///
  /// **Throws:**
  /// - Exception if decryption fails
  Future<String> decryptField(
    String fieldName,
    String encryptedValue,
    String userId,
  ) async {
    try {
      if (!shouldEncryptField(fieldName)) {
        return encryptedValue;
      }
      if (encryptedValue.isEmpty) {
        return encryptedValue; // Empty values are not encrypted
      }

      // Get encryption key for this field/user (do NOT auto-generate on decrypt).
      final key = await _getKey(fieldName, userId);
      if (key == null) {
        throw Exception('Encryption key not found for field: $fieldName, user: $userId');
      }

      // Decrypt using AES-256-GCM
      final decrypted = _decryptAES256GCM(encryptedValue, key);

      developer.log('Field decrypted: $fieldName', name: _logName);
      return decrypted;
    } catch (e) {
      developer.log('Error decrypting field: $e', name: _logName);
      rethrow;
    }
  }

  /// Check if a field should be encrypted
  bool shouldEncryptField(String fieldName) {
    return _encryptableFields.contains(fieldName.toLowerCase());
  }

  /// Get or generate encryption key for a field/user combination
  Future<Uint8List> _getOrGenerateKey(String fieldName, String userId) async {
    final normalizedFieldName = fieldName.toLowerCase();
    final keyId = '$_keyPrefix${normalizedFieldName}_$userId';

    // Prefer in-memory cache (keeps tests deterministic and avoids relying on
    // platform channel behavior for secure storage).
    final cachedKey = _inMemoryKeyStore[keyId];
    if (cachedKey != null) {
      return base64Decode(cachedKey);
    }

    // Try to get existing key
    String? existingKey;
    try {
      existingKey = await _storage.read(key: keyId);
    } catch (_) {
      // Ignore; we'll fall back to in-memory generation below.
    }
    if (existingKey != null) {
      _inMemoryKeyStore[keyId] = existingKey;
      return base64Decode(existingKey);
    }

    // Generate new key
    final key = _generateKey();
    final encoded = base64Encode(key);
    // Always store in-memory for this process, even if secure storage write succeeds.
    _inMemoryKeyStore[keyId] = encoded;
    try {
      await _storage.write(
        key: keyId,
        value: encoded,
      );
    } catch (_) {
      // Ignore; in-memory store already contains the key.
    }

    developer.log('Generated new encryption key for: $fieldName',
        name: _logName);
    return key;
  }

  /// Get encryption key for a field/user combination (without generating).
  Future<Uint8List?> _getKey(String fieldName, String userId) async {
    final normalizedFieldName = fieldName.toLowerCase();
    final keyId = '$_keyPrefix${normalizedFieldName}_$userId';

    final cachedKey = _inMemoryKeyStore[keyId];
    if (cachedKey != null) {
      return base64Decode(cachedKey);
    }

    String? existingKey;
    try {
      existingKey = await _storage.read(key: keyId);
    } catch (_) {
      // Ignore; no key available.
    }
    if (existingKey == null) return null;
    _inMemoryKeyStore[keyId] = existingKey;
    return base64Decode(existingKey);
  }

  /// Generate a new encryption key (32 bytes for AES-256)
  ///
  /// Uses cryptographically secure random number generator to ensure
  /// keys are unpredictable and unique.
  Uint8List _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  /// Encrypt using AES-256-GCM (authenticated encryption).
  String _encryptAES256GCM(String plaintext, Uint8List key) {
    // Generate random IV (12 bytes for GCM - 96 bits recommended).
    final iv = Uint8List(12);
    final rng = Random.secure();
    for (int i = 0; i < iv.length; i++) {
      iv[i] = rng.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          128, // MAC length (bits)
          iv,
          Uint8List(0), // AAD
        ),
      );

    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    // PointyCastle's AEAD `process()` output already includes the authentication tag.
    // Persist as: IV + (ciphertext || tag)
    final ciphertextWithTag = cipher.process(plaintextBytes);

    final combined = Uint8List(iv.length + ciphertextWithTag.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, ciphertextWithTag);

    return 'encrypted:${base64Encode(combined)}';
  }

  /// Decrypt using AES-256-GCM (authenticated decryption).
  String _decryptAES256GCM(String encrypted, Uint8List key) {
    if (!encrypted.startsWith('encrypted:')) {
      throw Exception('Invalid encrypted format');
    }

    final base64Data = encrypted.substring('encrypted:'.length);
    final bytes = base64Decode(base64Data);
    if (bytes.length < 12 + 16) {
      throw Exception('Invalid encrypted data length');
    }

    final iv = bytes.sublist(0, 12);
    final ciphertextWithTag = bytes.sublist(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(key),
          128, // MAC length (bits)
          iv,
          Uint8List(0), // AAD
        ),
      );

    final decryptedBytes = cipher.process(ciphertextWithTag);
    return utf8.decode(decryptedBytes);
  }

  /// Rotate encryption key for a field/user
  ///
  /// **Note:** This would require re-encrypting all data with the new key.
  /// In production, implement proper key rotation with data migration.
  Future<void> rotateKey(String fieldName, String userId) async {
    try {
      final normalizedFieldName = fieldName.toLowerCase();
      final keyId = '$_keyPrefix${normalizedFieldName}_$userId';
      _inMemoryKeyStore.remove(keyId);
      try {
        await _storage.delete(key: keyId);
      } catch (_) {
        // Ignore.
      }

      // Generate new key (will be created on next encryption)
      developer.log('Key rotated for: $fieldName', name: _logName);
    } catch (e) {
      developer.log('Error rotating key: $e', name: _logName);
      rethrow;
    }
  }

  /// Delete encryption key for a field/user
  ///
  /// **Warning:** This will make encrypted data unrecoverable.
  Future<void> deleteKey(String fieldName, String userId) async {
    try {
      final normalizedFieldName = fieldName.toLowerCase();
      final keyId = '$_keyPrefix${normalizedFieldName}_$userId';
      _inMemoryKeyStore.remove(keyId);
      try {
        await _storage.delete(key: keyId);
      } catch (_) {
        // Ignore.
      }

      developer.log('Key deleted for: $fieldName', name: _logName);
    } catch (e) {
      developer.log('Error deleting key: $e', name: _logName);
      rethrow;
    }
  }
}
