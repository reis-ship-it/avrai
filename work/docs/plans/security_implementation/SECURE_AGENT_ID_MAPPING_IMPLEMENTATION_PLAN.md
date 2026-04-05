# Secure Agent ID Mapping Implementation Plan

**Date:** December 30, 2025 (Updated with Compatibility Fixes)  
**Status:** 📋 Ready for Implementation  
**Priority:** P0 - Critical Security Fix  
**Timeline:** 2-3 weeks  
**Dependencies:** 
- ✅ Signal Protocol Implementation (Phase 14)
- ✅ AgentIdService exists
- ✅ Supabase database access
- ✅ FlutterSecureStorage available

---

## 🚨 **CRITICAL SECURITY ISSUE**

**Current Problem:**
The `userId` ↔ `agentId` mapping is stored in **plaintext** in the database, creating a critical security vulnerability. Anyone with database access can see which agent ID belongs to which user, completely breaking anonymity.

**Current Implementation (INSECURE):**
```dart
// ❌ INSECURE: Plaintext storage
await client.from('user_agent_mappings').insert({
  'user_id': userId,        // Plaintext userId
  'agent_id': agentId,      // Plaintext agentId
  'created_at': DateTime.now().toIso8601String(),
});
```

**Required Solution:**
The mapping must be **encrypted using dedicated encryption keys** (stored in FlutterSecureStorage) before storage. The database should never contain readable userId/agentId pairs—only encrypted blobs that can be decrypted only by the authenticated user.

---

## 🎯 **GOAL**

Implement secure, encrypted storage of userId ↔ agentId mappings using AES-256-GCM encryption with keys stored in FlutterSecureStorage, ensuring:
- ✅ Complete anonymity protection
- ✅ Encrypted mapping storage
- ✅ Access control (RLS + user authentication)
- ✅ Key management and rotation
- ✅ Migration from insecure plaintext storage
- ✅ Performance optimization (caching, batching)
- ✅ Comprehensive security validation

---

## 📋 **IMPLEMENTATION PLAN**

### **Phase 1: Create SecureMappingEncryptionService**

#### **1.1 Create SecureMappingEncryptionService**

**Purpose:** Encrypt/decrypt userId ↔ agentId mappings using AES-256-GCM with keys from FlutterSecureStorage

**Location:** `lib/core/services/secure_mapping_encryption_service.dart`

**Key Design Decisions:**
- ✅ Use dedicated encryption keys (not Signal Protocol) - follows `FieldEncryptionService` pattern
- ✅ Store keys in FlutterSecureStorage (hardware-backed when available)
- ✅ Use AES-256-GCM for authenticated encryption
- ✅ One key per user (derived from userId)

**Key Methods:**
```dart
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' as math;

// Note: pointycastle is already in pubspec.yaml

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
class SecureMappingEncryptionService {
  static const String _logName = 'SecureMappingEncryptionService';
  
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'mapping_encryption_key_';
  
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
    final existingKey = await _secureStorage.read(key: keyId);
    if (existingKey != null) {
      return base64Decode(existingKey);
    }
    
    // Generate new key (32 bytes for AES-256)
    final key = _generateKey();
    await _secureStorage.write(
      key: keyId,
      value: base64Encode(key),
    );
    
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
    final keyString = await _secureStorage.read(key: keyId);
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
```

**Deliverables:**
- ✅ `SecureMappingEncryptionService` class
- ✅ `EncryptedMapping` model
- ✅ AES-256-GCM encryption using `pointycastle` (production-ready)
- ✅ Key management (FlutterSecureStorage)
- ✅ Key rotation support
- ✅ Unit tests
- ✅ Integration tests

**Note:** Uses `pointycastle` library (already in codebase) following the pattern from `AES256GCMEncryptionService` in `lib/core/services/message_encryption_service.dart`.

---

### **Phase 2: Database Schema Migration**

#### **2.1 Create Secure Mapping Table Schema**

**Purpose:** Replace plaintext mapping table with encrypted blob storage

**Location:** `supabase/migrations/023_secure_agent_id_mappings.sql`

**Key Design Decisions:**
- ✅ User-authenticated INSERTs (not service role) - RLS enforces access control
- ✅ RLS performance pattern: `(select auth.uid())` wrapped in subquery
- ✅ Separate policies for INSERT/UPDATE/DELETE/SELECT
- ✅ Audit log table for security monitoring

**New Schema:**
```sql
-- Migration: Secure Agent ID Mappings
-- Created: 2025-12-30
-- Purpose: Encrypt userId ↔ agentId mappings using AES-256-GCM
-- Security: Critical - Replaces insecure plaintext storage

-- Create new secure mapping table
CREATE TABLE IF NOT EXISTS public.user_agent_mappings_secure (
    -- Primary key
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Encrypted mapping blob (NOT plaintext)
    encrypted_mapping BYTEA NOT NULL,
    
    -- Encryption metadata
    encryption_key_id TEXT NOT NULL,
    encryption_algorithm TEXT NOT NULL DEFAULT 'aes256_gcm',
    encryption_version INTEGER NOT NULL DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_rotated_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    
    -- Security metadata
    access_count INTEGER DEFAULT 0,
    rotation_count INTEGER DEFAULT 0,
    
    -- Constraints
    CONSTRAINT encryption_algorithm_check CHECK (encryption_algorithm IN ('signal_protocol', 'aes256_gcm')),
    CONSTRAINT encryption_version_check CHECK (encryption_version >= 1)
);

-- Indexes (for performance, NOT for reverse lookup)
CREATE INDEX IF NOT EXISTS idx_user_agent_mappings_secure_user_id 
    ON public.user_agent_mappings_secure(user_id);
CREATE INDEX IF NOT EXISTS idx_user_agent_mappings_secure_key_id 
    ON public.user_agent_mappings_secure(encryption_key_id);

-- RLS Policies (CRITICAL for security)
ALTER TABLE public.user_agent_mappings_secure ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only SELECT their own encrypted mapping
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can access own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR SELECT
    USING ((select auth.uid()) = user_id);

-- Policy: Users can INSERT their own mapping (with RLS enforcement)
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can insert own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

-- Policy: Users can UPDATE their own mapping (for rotation)
-- Performance: Wrap auth.uid() in subquery for caching
CREATE POLICY "Users can update own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

-- Policy: Service role can manage all mappings (for admin operations)
-- Performance: Wrap auth.role() in subquery for caching
CREATE POLICY "Service role can manage encrypted mappings"
    ON public.user_agent_mappings_secure
    FOR ALL
    USING ((select auth.role()) = 'service_role')
    WITH CHECK ((select auth.role()) = 'service_role');

-- Audit log table (for security monitoring)
CREATE TABLE IF NOT EXISTS public.agent_mapping_audit_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'created', 'accessed', 'rotated', 'deleted'
    encryption_key_id TEXT,
    accessed_by TEXT, -- 'user' or 'service_role'
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT action_check CHECK (action IN ('created', 'accessed', 'rotated', 'deleted'))
);

-- Index for audit log
CREATE INDEX IF NOT EXISTS idx_agent_mapping_audit_log_user_id 
    ON public.agent_mapping_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_mapping_audit_log_created_at 
    ON public.agent_mapping_audit_log(created_at DESC);

-- RLS for audit log (users can only see their own audit entries)
ALTER TABLE public.agent_mapping_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own audit log"
    ON public.agent_mapping_audit_log
    FOR SELECT
    USING ((select auth.uid()) = user_id);

-- Service role can view all audit logs (for security monitoring)
CREATE POLICY "Service role can view all audit logs"
    ON public.agent_mapping_audit_log
    FOR SELECT
    USING ((select auth.role()) = 'service_role');
```

**Migration Strategy:**
1. Create new secure table alongside old table
2. Migrate existing mappings (encrypt and move) - see Phase 5
3. Update application code to use new table
4. Verify all mappings migrated successfully
5. Keep old table for rollback period (30 days)
6. Drop old insecure table (after verification)

**Deliverables:**
- ✅ Migration SQL file
- ✅ Secure table schema
- ✅ RLS policies (with performance optimization)
- ✅ Audit log table
- ✅ Migration script (Dart) for encrypting existing mappings

---

### **Phase 3: Update AgentIdService with Caching**

#### **3.1 Refactor AgentIdService for Encrypted Storage**

**Purpose:** Update `AgentIdService` to use encrypted mappings with performance caching

**Location:** `lib/core/services/agent_id_service.dart`

**Key Design Decisions:**
- ✅ Add in-memory caching (5 minute TTL) for performance
- ✅ Remove redundant access control (rely on RLS)
- ✅ Async audit logging (non-blocking)
- ✅ Graceful error handling with fallback

**Changes Required:**

1. **Add SecureMappingEncryptionService dependency and caching:**
```dart
import 'dart:developer' as developer;
import 'package:spots/core/services/supabase_service.dart';
import 'package:spots/core/services/secure_mapping_encryption_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Agent ID Service
/// 
/// Manages agent ID lookup and generation for users and businesses.
/// Agent IDs are used for ai2ai network routing.
/// 
/// **Security:**
/// - All mappings encrypted using SecureMappingEncryptionService
/// - Keys stored in FlutterSecureStorage (hardware-backed)
/// - RLS enforces access control at database level
class AgentIdService {
  static const String _logName = 'AgentIdService';
  final SupabaseService _supabaseService;
  final SecureMappingEncryptionService _encryptionService;
  
  // In-memory cache for decrypted agent IDs (5 minute TTL)
  final Map<String, CachedAgentId> _agentIdCache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  // Async audit log queue (batched for performance)
  final List<Map<String, dynamic>> _auditLogQueue = [];
  static const int _auditLogBatchSize = 100;
  static const Duration _auditLogFlushInterval = Duration(seconds: 5);
  DateTime? _lastAuditLogFlush;

  AgentIdService({
    SupabaseService? supabaseService,
    required SecureMappingEncryptionService encryptionService,
    BusinessAccountService? businessService, // Reserved for future use
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _encryptionService = encryptionService;
  
  /// Get agent ID for a user
  /// 
  /// **Performance:**
  /// - Checks in-memory cache first (5 minute TTL)
  /// - Decrypts mapping if not cached
  /// - Updates cache after decryption
  /// 
  /// **Security:**
  /// - RLS enforces access control (only authenticated user can access their mapping)
  /// - All mappings encrypted
  Future<String> getUserAgentId(String userId) async {
    try {
      // Check cache first (performance optimization)
      final cached = _agentIdCache[userId];
      if (cached != null && 
          DateTime.now().difference(cached.cachedAt) < _cacheTTL) {
        return cached.agentId;
      }
      
      if (!_supabaseService.isAvailable) {
        // Fallback: Generate deterministic agent ID from user ID
        return _generateDeterministicAgentId('user_$userId');
      }

      final client = _supabaseService.client;

      // Check for existing encrypted mapping
      try {
        final response = await client
            .from('user_agent_mappings_secure') // NEW: Use secure table
            .select('encrypted_mapping, encryption_key_id, encryption_algorithm')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          // Decrypt mapping (RLS enforces access control)
          final agentId = await _encryptionService.decryptMapping(
            userId: userId,
            encryptedBlob: Uint8List.fromList(
              List<int>.from(response['encrypted_mapping'] as List),
            ),
            encryptionKeyId: response['encryption_key_id'] as String,
          );
          
          if (agentId != null) {
            // Update cache
            _agentIdCache[userId] = CachedAgentId(
              agentId: agentId,
              cachedAt: DateTime.now(),
            );
            
            // Update last_accessed_at (async, non-blocking)
            _updateLastAccessed(userId);
            
            // Log access (async, batched)
            _logMappingAccess(userId, 'accessed');
            
            return agentId;
          }
        }
      } catch (e) {
        developer.log('Error checking encrypted mapping: $e', name: _logName);
      }

      // Generate new agent ID
      final agentId = _generateSecureAgentId();
      
      // Encrypt mapping
      final encrypted = await _encryptionService.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      // Store encrypted mapping (RLS enforces user can only insert their own)
      try {
        await client.from('user_agent_mappings_secure').insert({
          'user_id': userId,
          'encrypted_mapping': encrypted.encryptedBlob.toList(),
          'encryption_key_id': encrypted.encryptionKeyId,
          'encryption_algorithm': encrypted.algorithm.name,
          'encryption_version': encrypted.version,
          'created_at': encrypted.encryptedAt.toIso8601String(),
        });
      } catch (e) {
        developer.log('Error storing encrypted mapping: $e', name: _logName);
        // Continue with generated ID even if storage fails
      }
      
      // Update cache
      _agentIdCache[userId] = CachedAgentId(
        agentId: agentId,
        cachedAt: DateTime.now(),
      );
      
      // Log creation (async, batched)
      _logMappingAccess(userId, 'created');

      return agentId;
    } catch (e) {
      developer.log('Error getting user agent ID: $e', name: _logName);
      // Fallback: Generate deterministic agent ID
      return _generateDeterministicAgentId('user_$userId');
    }
  }
  
  /// Update last accessed timestamp (async, non-blocking)
  Future<void> _updateLastAccessed(String userId) async {
    try {
      final client = _supabaseService.client;
      await client
          .from('user_agent_mappings_secure')
          .update({
            'last_accessed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      developer.log('Error updating last accessed: $e', name: _logName);
      // Don't fail if update fails
    }
  }
  
  /// Log mapping access (async, batched for performance)
  void _logMappingAccess(String userId, String action) {
    _auditLogQueue.add({
      'user_id': userId,
      'action': action,
      'accessed_by': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Flush queue if batch size reached or interval elapsed
    if (_auditLogQueue.length >= _auditLogBatchSize ||
        (_lastAuditLogFlush != null &&
         DateTime.now().difference(_lastAuditLogFlush!) > _auditLogFlushInterval)) {
      _flushAuditLogs();
    }
  }
  
  /// Flush audit log queue to database
  Future<void> _flushAuditLogs() async {
    if (_auditLogQueue.isEmpty) return;
    
    try {
      final client = _supabaseService.client;
      final batch = List<Map<String, dynamic>>.from(_auditLogQueue);
      _auditLogQueue.clear();
      
      await client.from('agent_mapping_audit_log').insert(batch);
      _lastAuditLogFlush = DateTime.now();
    } catch (e) {
      developer.log('Error flushing audit logs: $e', name: _logName);
      // Don't fail if audit logging fails
    }
  }
  
  /// Rotate encryption key for a user's mapping
  Future<void> rotateMappingEncryptionKey(String userId) async {
    try {
      final client = _supabaseService.client;
      
      // Get old encrypted mapping
      final response = await client
          .from('user_agent_mappings_secure')
          .select('encrypted_mapping, encryption_key_id, encryption_algorithm')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) {
        throw Exception('No mapping found for user');
      }
      
      // Create EncryptedMapping from response
      final oldMapping = EncryptedMapping(
        encryptedBlob: Uint8List.fromList(
          List<int>.from(response['encrypted_mapping'] as List),
        ),
        encryptionKeyId: response['encryption_key_id'] as String,
        algorithm: EncryptionAlgorithm.values.firstWhere(
          (e) => e.name == response['encryption_algorithm'],
        ),
        encryptedAt: DateTime.now(), // Approximate
        version: 1,
      );
      
      // Rotate encryption key (re-encrypt with new key)
      final newEncrypted = await _encryptionService.rotateEncryptionKey(
        userId: userId,
        oldMapping: oldMapping,
      );
      
      // Update database with new encrypted mapping
      await client
          .from('user_agent_mappings_secure')
          .update({
            'encrypted_mapping': newEncrypted.encryptedBlob.toList(),
            'encryption_key_id': newEncrypted.encryptionKeyId,
            'last_rotated_at': DateTime.now().toIso8601String(),
            'rotation_count': client.rpc('increment_rotation_count', params: {'user_id': userId}),
          })
          .eq('user_id', userId);
      
      // Clear cache (force re-fetch)
      _agentIdCache.remove(userId);
      
      // Log rotation
      _logMappingAccess(userId, 'rotated');
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
  
  /// Clear cache (useful for testing or when user changes)
  void clearCache() {
    _agentIdCache.clear();
  }
  
  /// Flush audit logs (call on app shutdown)
  Future<void> flushAuditLogs() async {
    await _flushAuditLogs();
  }

  // ... (existing methods: getBusinessAgentId, _generateSecureAgentId, etc.)
}

/// Cached agent ID model
class CachedAgentId {
  final String agentId;
  final DateTime cachedAt;
  
  CachedAgentId({
    required this.agentId,
    required this.cachedAt,
  });
}
```

**Deliverables:**
- ✅ Updated `AgentIdService` with encryption
- ✅ In-memory caching (5 minute TTL)
- ✅ Async audit logging (batched)
- ✅ Key rotation support
- ✅ Graceful error handling
- ✅ Unit tests
- ✅ Integration tests

---

### **Phase 4: Migration Script**

#### **4.1 Create Migration Script**

**Purpose:** Migrate existing plaintext mappings to encrypted storage

**Location:** `scripts/migrate_agent_id_mappings.dart`

**Key Design Decisions:**
- ✅ Phased migration (dual-write during transition)
- ✅ Verification after migration
- ✅ Rollback capability
- ✅ Progress tracking

**Process:**
```dart
import 'dart:developer' as developer;
import 'package:spots/core/services/supabase_service.dart';
import 'package:spots/core/services/secure_mapping_encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Migrate plaintext agent ID mappings to encrypted storage
/// 
/// **Process:**
/// 1. Read all plaintext mappings from old table
/// 2. Encrypt each mapping
/// 3. Store in new secure table
/// 4. Verify encryption/decryption works
/// 5. Report results
Future<void> migrateAgentIdMappings() async {
  developer.log('Starting agent ID mapping migration...', name: 'Migration');
  
  // Initialize services
  final encryptionService = SecureMappingEncryptionService(
    secureStorage: const FlutterSecureStorage(),
  );
  final supabaseService = SupabaseService();
  final client = supabaseService.client;
  
  // Get all plaintext mappings from old table
  final plaintextMappings = await client
      .from('user_agent_mappings')
      .select('user_id, agent_id, created_at');
  
  developer.log('Found ${plaintextMappings.length} mappings to migrate', name: 'Migration');
  
  // Migrate each mapping
  int successCount = 0;
  int errorCount = 0;
  final errors = <String, String>{};
  
  for (int i = 0; i < plaintextMappings.length; i++) {
    final mapping = plaintextMappings[i];
    final userId = mapping['user_id'] as String;
    final agentId = mapping['agent_id'] as String;
    
    try {
      // Encrypt mapping
      final encrypted = await encryptionService.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      // Store encrypted mapping in new table
      await client.from('user_agent_mappings_secure').insert({
        'user_id': userId,
        'encrypted_mapping': encrypted.encryptedBlob.toList(),
        'encryption_key_id': encrypted.encryptionKeyId,
        'encryption_algorithm': encrypted.algorithm.name,
        'encryption_version': encrypted.version,
        'created_at': mapping['created_at'],
      });
      
      // Verify (decrypt and check)
      final decrypted = await encryptionService.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted.encryptedBlob,
        encryptionKeyId: encrypted.encryptionKeyId,
      );
      
      if (decrypted != agentId) {
        throw Exception('Decryption verification failed: $decrypted != $agentId');
      }
      
      successCount++;
      
      // Log progress every 100 mappings
      if (successCount % 100 == 0) {
        developer.log('Migrated $successCount mappings...', name: 'Migration');
      }
    } catch (e) {
      errorCount++;
      errors[userId] = e.toString();
      developer.log(
        'Error migrating mapping for user $userId: $e',
        name: 'Migration',
      );
    }
  }
  
  // Report results
  developer.log(
    'Migration complete: $successCount successful, $errorCount errors',
    name: 'Migration',
  );
  
  if (errors.isNotEmpty) {
    developer.log('Errors: $errors', name: 'Migration');
  }
  
  // Verify all mappings migrated
  final oldCount = (await client.from('user_agent_mappings').select('user_id')).length;
  final newCount = (await client.from('user_agent_mappings_secure').select('user_id')).length;
  
  if (oldCount != newCount) {
    throw Exception('Migration incomplete: $oldCount old mappings, $newCount new mappings');
  }
  
  developer.log('Migration verification passed', name: 'Migration');
}
```

**Deliverables:**
- ✅ Migration script
- ✅ Verification process
- ✅ Rollback capability
- ✅ Migration report

---

### **Phase 5: Key Rotation Service**

#### **5.1 Implement Key Rotation Service**

**Purpose:** Rotate encryption keys periodically for enhanced security

**Location:** `lib/core/services/mapping_key_rotation_service.dart`

**Key Design Decisions:**
- ✅ Batch rotation (100 users at a time)
- ✅ Rate limiting (1 batch per second)
- ✅ Background processing
- ✅ Progress tracking

**Implementation:**
```dart
import 'dart:developer' as developer;
import 'package:spots/core/services/agent_id_service.dart';
import 'package:spots/core/services/supabase_service.dart';

/// Mapping Key Rotation Service
/// 
/// Rotates encryption keys for agent ID mappings periodically.
/// 
/// **Security:**
/// - Re-encrypts mappings with new keys
/// - Maintains backward compatibility during rotation
/// - Batch processing for performance
class MappingKeyRotationService {
  static const String _logName = 'MappingKeyRotationService';
  
  final AgentIdService _agentIdService;
  final SupabaseService _supabaseService;
  
  MappingKeyRotationService({
    required AgentIdService agentIdService,
    required SupabaseService supabaseService,
  }) : _agentIdService = agentIdService,
       _supabaseService = supabaseService;
  
  /// Rotate encryption key for a user's mapping
  Future<void> rotateKeyForUser(String userId) async {
    await _agentIdService.rotateMappingEncryptionKey(userId);
  }
  
  /// Rotate keys for all users (scheduled task)
  /// 
  /// **Performance:**
  /// - Batch processing (100 users at a time)
  /// - Rate limiting (1 batch per second)
  /// - Progress tracking
  Future<RotationReport> rotateAllKeys({
    Duration? rotationInterval,
  }) async {
    final interval = rotationInterval ?? const Duration(days: 90);
    final cutoffDate = DateTime.now().subtract(interval);
    
    developer.log(
      'Starting key rotation for mappings older than $cutoffDate',
      name: _logName,
    );
    
    // Get all mappings that need rotation
    final client = _supabaseService.client;
    final mappings = await client
        .from('user_agent_mappings_secure')
        .select('user_id, last_rotated_at, created_at')
        .or('last_rotated_at.is.null,last_rotated_at.lt.$cutoffDate');
    
    developer.log('Found ${mappings.length} mappings needing rotation', name: _logName);
    
    int successCount = 0;
    int errorCount = 0;
    final batchSize = 100;
    
    // Process in batches
    for (int i = 0; i < mappings.length; i += batchSize) {
      final batch = mappings.skip(i).take(batchSize);
      
      // Rotate keys in parallel (within batch)
      final results = await Future.wait(
        batch.map((mapping) async {
          try {
            await rotateKeyForUser(mapping['user_id'] as String);
            return true;
          } catch (e) {
            developer.log(
              'Error rotating key for user ${mapping['user_id']}: $e',
              name: _logName,
            );
            return false;
          }
        }),
      );
      
      successCount += results.where((r) => r).length;
      errorCount += results.where((r) => !r).length;
      
      developer.log(
        'Rotated batch ${i ~/ batchSize + 1}: $successCount successful, $errorCount errors',
        name: _logName,
      );
      
      // Rate limit: 1 batch per second
      if (i + batchSize < mappings.length) {
        await Future.delayed(Duration(seconds: 1));
      }
    }
    
    return RotationReport(
      totalMappings: mappings.length,
      rotated: successCount,
      errors: errorCount,
    );
  }
  
  /// Check if key rotation is needed
  Future<bool> shouldRotateKey(String userId) async {
    final client = _supabaseService.client;
    final response = await client
        .from('user_agent_mappings_secure')
        .select('last_rotated_at, created_at')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return false;
    
    final lastRotated = response['last_rotated_at'] as DateTime?;
    final createdAt = response['created_at'] as DateTime;
    final checkDate = lastRotated ?? createdAt;
    
    // Rotate if older than 90 days
    return DateTime.now().difference(checkDate).inDays > 90;
  }
}

/// Rotation report model
class RotationReport {
  final int totalMappings;
  final int rotated;
  final int errors;
  
  RotationReport({
    required this.totalMappings,
    required this.rotated,
    required this.errors,
  });
}
```

**Deliverables:**
- ✅ `MappingKeyRotationService` class
- ✅ Batch rotation processing
- ✅ Rate limiting
- ✅ Progress tracking
- ✅ Unit tests

---

### **Phase 6: Update Dependent Services**

#### **6.1 Update Service Dependencies**

**Services that need updates:**
- `SignalProtocolEncryptionService` (already uses AgentIdService)
- `RealTimeUserCallingService` (uses AgentIdService)
- `UserJourneyTrackingService` (uses AgentIdService)
- `MeaningfulConnectionMetricsService` (uses AgentIdService)
- `QuantumMatchingController` (uses AgentIdService)
- Any other services using `AgentIdService`

**Changes Required:**
- Update DI registration to include `SecureMappingEncryptionService`
- No code changes needed (AgentIdService interface stays the same)
- Verify all services work with encrypted mappings

**DI Registration Update:**
```dart
// Register FlutterSecureStorage first (dependency)
sl.registerLazySingleton<FlutterSecureStorage>(
  () => const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  ),
);

// Register SecureMappingEncryptionService
sl.registerLazySingleton<SecureMappingEncryptionService>(
  () => SecureMappingEncryptionService(
    secureStorage: sl<FlutterSecureStorage>(),
  ),
);

// Update AgentIdService registration
sl.registerLazySingleton<AgentIdService>(
  () => AgentIdService(
    supabaseService: sl<SupabaseService>(),
    encryptionService: sl<SecureMappingEncryptionService>(), // NEW
  ),
);

// Register MappingKeyRotationService (optional)
sl.registerLazySingleton<MappingKeyRotationService>(
  () => MappingKeyRotationService(
    agentIdService: sl<AgentIdService>(),
    supabaseService: sl<SupabaseService>(),
  ),
);
```

**Deliverables:**
- ✅ Updated DI registrations
- ✅ Service compatibility verification
- ✅ Integration tests

---

### **Phase 7: Security Validation and Testing**

#### **7.1 Security Validation**

**Purpose:** Verify no security vulnerabilities remain

**Validation Checklist:**
- [ ] No plaintext userId/agentId pairs in database
- [ ] All mappings encrypted
- [ ] Access control enforced (RLS)
- [ ] Key management secure (FlutterSecureStorage)
- [ ] Audit logging working
- [ ] No personal data leakage
- [ ] Migration completed successfully
- [ ] Rollback tested
- [ ] Performance acceptable (< 100ms encryption/decryption with cache)

#### **7.2 Comprehensive Testing**

**Test Coverage:**
- Unit tests for `SecureMappingEncryptionService`
- Unit tests for updated `AgentIdService`
- Integration tests for encrypted storage/retrieval
- Security tests (access control, encryption validation)
- Migration tests (plaintext → encrypted)
- Key rotation tests
- Audit logging tests
- Performance tests (encryption/decryption speed, caching)
- Cache invalidation tests

**Deliverables:**
- ✅ Security validation report
- ✅ Comprehensive test suite
- ✅ Performance benchmarks
- ✅ Security audit report

---

### **Phase 8: Documentation Updates**

#### **8.1 Update Documentation**

**Documents to Update:**
- `docs/security/AGENT_ID_SYSTEM.md` - Update with encryption details
- `docs/plans/multi_entity_quantum_matching/MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING_IMPLEMENTATION_PLAN.md` - Update Section 19.13
- `docs/SECURITY_ANALYSIS.md` - Update security recommendations
- Create new: `docs/security/SECURE_MAPPING_ENCRYPTION.md`

**Content:**
- Encryption architecture
- Key management process
- Access control details (RLS)
- Migration process
- Security guarantees
- Performance optimizations
- Best practices

**Deliverables:**
- ✅ Updated documentation
- ✅ Security architecture diagram
- ✅ Migration guide
- ✅ Security best practices guide

---

## 🔒 **ADDITIONAL SECURITY IMPROVEMENTS**

### **1. Agent ID Rotation**

**Purpose:** Allow users to rotate their agent ID for enhanced privacy

**Implementation:**
- User-initiated rotation
- Automatic rotation (optional, configurable)
- Rotation history tracking
- Update all references to old agent ID

### **2. Mapping Expiration**

**Purpose:** Expire old mappings that haven't been accessed

**Implementation:**
- Configurable expiration period (e.g., 1 year)
- Automatic cleanup of expired mappings
- User notification before expiration

### **3. Rate Limiting**

**Purpose:** Prevent brute force attacks on encrypted mappings

**Implementation:**
- Limit mapping access attempts per user
- Rate limit key rotation requests
- Monitor for suspicious access patterns

---

## 📊 **IMPLEMENTATION TIMELINE**

**Week 1:**
- Day 1-2: Create `SecureMappingEncryptionService`
- Day 3-4: Create database migration
- Day 5: Update `AgentIdService` with caching

**Week 2:**
- Day 1-2: Migration script and testing
- Day 3: Key rotation service
- Day 4-5: Testing and validation

**Week 3:**
- Day 1-2: Update all dependent services
- Day 3: Security validation
- Day 4: Performance optimization
- Day 5: Documentation and final review

---

## ✅ **ACCEPTANCE CRITERIA**

- [ ] All userId ↔ agentId mappings encrypted
- [ ] No plaintext mappings in database
- [ ] Access control enforced (RLS only, no redundant checks)
- [ ] Key management secure (FlutterSecureStorage)
- [ ] Key rotation working
- [ ] Migration completed successfully
- [ ] All tests passing
- [ ] Security validation passed
- [ ] Documentation updated
- [ ] Performance acceptable (< 100ms with cache, < 200ms without cache)

---

## 🚨 **CRITICAL SECURITY REQUIREMENTS**

1. **Never store plaintext mappings** - All mappings must be encrypted
2. **Access control mandatory** - RLS enforces access control (no redundant service-layer checks)
3. **Key management secure** - Keys stored in FlutterSecureStorage, never in database
4. **Audit logging required** - All mapping access must be logged (async, batched)
5. **RLS policies optimized** - Wrap `auth.uid()` and `auth.role()` in subqueries for performance
6. **Migration verified** - All existing mappings successfully encrypted
7. **Rollback tested** - Ability to rollback if issues occur
8. **Performance optimized** - Caching and batching for acceptable performance

---

## 📝 **NOTES**

- This is a **critical security fix** - must be completed before production
- Migration must be tested thoroughly in staging environment
- Consider phased rollout (migrate users in batches)
- Monitor for performance impact (encryption/decryption overhead)
- Keep old table for rollback period (e.g., 30 days) before deletion
- Uses `pointycastle` library (already in codebase) - production-ready implementation
- Cache TTL and batch sizes are configurable and can be tuned based on usage patterns

---

**Last Updated:** December 30, 2025  
**Status:** Ready for Implementation (with all compatibility fixes)
