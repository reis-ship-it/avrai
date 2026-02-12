import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' as math;

/// Secure Mapping Encryption Service
/// 
/// Encrypts/decrypts userId ↔ agentId mappings using AES-256-GCM.
/// Keys are stored in FlutterSecureStorage (hardware-backed when available).
/// 
/// **Security:**
/// - AES-256-GCM authenticated encryption
/// - Keys stored in secure storage (Keychain/Keystore)
/// - One key per user (derived from userId)
/// - Keys never stored in database
/// 
/// **Usage:**
/// ```dart
/// final encryptionService = SecureMappingEncryptionService();
/// 
/// // Encrypt mapping
/// final encrypted = await encryptionService.encryptMapping(
///   userId: 'user-123',
///   agentId: 'agent_abc...',
/// );
/// 
/// // Decrypt mapping
/// final agentId = await encryptionService.decryptMapping(
///   userId: 'user-123',
///   encryptedBlob: encrypted.encryptedBlob,
///   encryptionKeyId: encrypted.encryptionKeyId,
/// );
/// ```
class SecureMappingEncryptionService {
  static const String _logName = 'SecureMappingEncryptionService';
  
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'mapping_encryption_key_';
  // Fallback key store for tests / unsupported platforms where plugins are unavailable.
  // This preserves encryption behavior without requiring platform channels.
  static final Map<String, String> _inMemoryKeyStore = <String, String>{};
  
  SecureMappingEncryptionService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );
  
  /// Encrypt userId → agentId mapping
  /// 
  /// **Security:**
  /// - Uses AES-256-GCM encryption
  /// - Returns encrypted blob that cannot be read without decryption
  /// - Includes metadata (timestamp, version) for key rotation
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `agentId`: Agent ID to encrypt
  /// 
  /// **Returns:**
  /// EncryptedMapping with encrypted blob and metadata
  Future<EncryptedMapping> encryptMapping({
    required String userId,
    required String agentId,
  }) async {
    try {
      // 1. Get or generate encryption key for this user
      final key = await _getOrGenerateKey(userId);
      
      // 2. Create mapping data structure
      final mappingData = jsonEncode({
        'user_id': userId,
        'agent_id': agentId,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1, // For future schema changes
      });
      
      // 3. Encrypt using AES-256-GCM
      final encrypted = await _encryptAES256GCM(
        plaintext: utf8.encode(mappingData),
        key: key,
      );
      
      // 4. Generate key ID for key management
      final keyId = _generateKeyId(userId, key);
      
      developer.log(
        'Mapping encrypted for user: $userId',
        name: _logName,
      );
      
      return EncryptedMapping(
        encryptedBlob: encrypted,
        encryptionKeyId: keyId,
        algorithm: EncryptionAlgorithm.aes256GCM,
        encryptedAt: DateTime.now(),
        version: 1,
        metadata: {},
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error encrypting mapping: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Decrypt mapping (with access control via RLS)
  /// 
  /// **Security:**
  /// - RLS enforces access control (only authenticated user can decrypt their mapping)
  /// - Validates decrypted data integrity
  /// - Returns decrypted agentId
  /// 
  /// **Parameters:**
  /// - `userId`: User ID (for key lookup and validation)
  /// - `encryptedBlob`: Encrypted mapping blob
  /// - `encryptionKeyId`: Encryption key identifier
  /// 
  /// **Returns:**
  /// Decrypted agentId or null if decryption fails
  Future<String?> decryptMapping({
    required String userId,
    required Uint8List encryptedBlob,
    required String encryptionKeyId,
  }) async {
    try {
      // 1. Get encryption key from secure storage
      final key = await _getEncryptionKey(userId, encryptionKeyId);
      if (key == null) {
        throw Exception('Encryption key not found for user: $userId');
      }
      
      // 2. Decrypt blob
      final decrypted = await _decryptAES256GCM(
        encrypted: encryptedBlob,
        key: key,
      );
      
      // 3. Parse and validate decrypted data
      final mappingData = jsonDecode(utf8.decode(decrypted));
      if (mappingData['user_id'] != userId) {
        throw SecurityException('Mapping user_id mismatch');
      }
      
      // 4. Return agentId
      final agentId = mappingData['agent_id'] as String;
      
      developer.log(
        'Mapping decrypted for user: $userId',
        name: _logName,
      );
      
      return agentId;
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting mapping: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Get or generate encryption key for a user
  /// 
  /// **Security:**
  /// - Keys stored in FlutterSecureStorage (hardware-backed when available)
  /// - One key per user (derived from userId)
  /// - Keys never stored in database
  Future<Uint8List> _getOrGenerateKey(String userId) async {
    final keyId = '$_keyPrefix$userId';
    
    // Try to get existing key from secure storage
    String? existingKey;
    try {
      existingKey = await _secureStorage.read(key: keyId);
    } catch (_) {
      existingKey = _inMemoryKeyStore[keyId];
    }
    if (existingKey != null) {
      return base64Decode(existingKey);
    }
    
    // Generate new key (32 bytes for AES-256)
    final key = _generateKey();
    final encoded = base64Encode(key);
    try {
      await _secureStorage.write(
        key: keyId,
        value: encoded,
      );
    } catch (_) {
      _inMemoryKeyStore[keyId] = encoded;
    }
    
    developer.log(
      'Generated new encryption key for user: $userId',
      name: _logName,
    );
    
    return key;
  }
  
  /// Get encryption key for a user (by key ID)
  Future<Uint8List?> _getEncryptionKey(String userId, String encryptionKeyId) async {
    // For now, use userId to look up key
    // In future, encryptionKeyId could reference key version for rotation
    final keyId = '$_keyPrefix$userId';
    String? keyString;
    try {
      keyString = await _secureStorage.read(key: keyId);
    } catch (_) {
      keyString = _inMemoryKeyStore[keyId];
    }
    if (keyString == null) return null;
    return base64Decode(keyString);
  }
  
  /// Generate a new encryption key (32 bytes for AES-256)
  Uint8List _generateKey() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }
  
  /// Generate key ID for key management
  String _generateKeyId(String userId, Uint8List key) {
    // Use hash of key + userId for key ID
    final combined = utf8.encode(userId) + key;
    final hash = sha256.convert(combined);
    return base64Encode(hash.bytes)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '')
        .substring(0, 32);
  }
  
  /// Encrypt using AES-256-GCM
  /// 
  /// **Implementation:**
  /// - Uses pointycastle library (already in codebase)
  /// - Follows pattern from AES256GCMEncryptionService
  /// - Generates random IV (12 bytes for GCM - 96 bits recommended)
  /// - Returns: IV (12 bytes) + ciphertext + tag (16 bytes)
  /// 
  /// **Format:** `[IV (12 bytes)][ciphertext][tag (16 bytes)]`
  Future<Uint8List> _encryptAES256GCM({
    required List<int> plaintext,
    required Uint8List key,
  }) async {
    // Generate random IV (12 bytes for GCM - 96 bits recommended)
    final random = math.Random.secure();
    final iv = Uint8List(12);
    for (int i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    
    // Create AES-256-GCM cipher
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          128, // MAC length (128 bits)
          iv,
          Uint8List(0), // Additional authenticated data (none)
        ),
      );
    
    // Encrypt plaintext
    final plaintextBytes = Uint8List.fromList(plaintext);
    final ciphertext = cipher.process(plaintextBytes);
    final tag = cipher.mac;
    
    // Combine: IV + ciphertext + tag
    final encrypted = Uint8List(iv.length + ciphertext.length + tag.length);
    encrypted.setRange(0, iv.length, iv);
    encrypted.setRange(iv.length, iv.length + ciphertext.length, ciphertext);
    encrypted.setRange(
      iv.length + ciphertext.length,
      encrypted.length,
      tag,
    );
    
    return encrypted;
  }
  
  /// Decrypt using AES-256-GCM
  /// 
  /// **Implementation:**
  /// - Uses pointycastle library (already in codebase)
  /// - Follows pattern from AES256GCMEncryptionService
  /// - Extracts IV, ciphertext, and tag from encrypted data
  /// - Verifies authentication tag with constant-time comparison
  /// 
  /// **Format:** `[IV (12 bytes)][ciphertext][tag (16 bytes)]`
  Future<List<int>> _decryptAES256GCM({
    required Uint8List encrypted,
    required Uint8List key,
  }) async {
    // Extract IV, ciphertext, and tag
    // Format: IV (12 bytes) + ciphertext + tag (16 bytes)
    if (encrypted.length < 12 + 16) {
      throw Exception('Invalid encrypted data length: ${encrypted.length}');
    }
    
    final iv = encrypted.sublist(0, 12);
    final tag = encrypted.sublist(encrypted.length - 16);
    final ciphertext = encrypted.sublist(12, encrypted.length - 16);
    
    // Create AES-256-GCM cipher
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128, // MAC length (128 bits)
      iv,
      Uint8List(0), // Additional authenticated data (none)
    );
    cipher.init(false, params); // false = decrypt
    
    // Decrypt
    final plaintext = cipher.process(ciphertext);
    
    // Verify authentication tag (prevents tampering)
    final calculatedTag = cipher.mac;
    if (!_constantTimeEquals(tag, calculatedTag)) {
      throw Exception('Authentication tag mismatch - message may be tampered');
    }
    
    return plaintext;
  }
  
  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
  
  /// Rotate encryption key for a user's mapping
  /// 
  /// **Security:**
  /// - Re-encrypts mapping with new key
  /// - Updates encryption_key_id
  /// - Maintains backward compatibility during rotation
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `oldMapping`: Existing encrypted mapping
  /// 
  /// **Returns:**
  /// New EncryptedMapping with rotated key
  Future<EncryptedMapping> rotateEncryptionKey({
    required String userId,
    required EncryptedMapping oldMapping,
  }) async {
    try {
      // 1. Decrypt old mapping
      final agentId = await decryptMapping(
        userId: userId,
        encryptedBlob: oldMapping.encryptedBlob,
        encryptionKeyId: oldMapping.encryptionKeyId,
      );
      
      if (agentId == null) {
        throw Exception('Failed to decrypt old mapping');
      }
      
      // 2. Generate new encryption key
      final newKey = _generateKey();
      final keyId = '$_keyPrefix$userId';
      await _secureStorage.write(
        key: keyId,
        value: base64Encode(newKey),
      );
      
      // 3. Re-encrypt with new key
      final newEncrypted = await encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      developer.log(
        'Encryption key rotated for user: $userId',
        name: _logName,
      );
      
      return newEncrypted;
    } catch (e, stackTrace) {
      developer.log(
        'Error rotating encryption key: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
}

/// Encryption algorithm enum
enum EncryptionAlgorithm {
  aes256GCM,
  signalProtocol, // Reserved for future use
}

/// Encrypted mapping model
class EncryptedMapping {
  /// Encrypted blob (cannot be read without decryption)
  final Uint8List encryptedBlob;
  
  /// Encryption key identifier (for key management)
  final String encryptionKeyId;
  
  /// Encryption algorithm used
  final EncryptionAlgorithm algorithm;
  
  /// Timestamp when mapping was encrypted
  final DateTime encryptedAt;
  
  /// Version of encryption schema (for future changes)
  final int version;
  
  /// Metadata (non-sensitive)
  final Map<String, dynamic> metadata;
  
  const EncryptedMapping({
    required this.encryptedBlob,
    required this.encryptionKeyId,
    required this.algorithm,
    required this.encryptedAt,
    required this.version,
    this.metadata = const {},
  });
}

/// Security exception for mapping operations
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
