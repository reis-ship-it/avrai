import 'dart:developer' as developer;

// Re-export types used in public method signatures.
export 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart'
    show EncryptedMapping;

import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Agent ID Service
///
/// Manages agent ID lookup and generation for users and businesses.
/// Agent IDs are used for ai2ai network routing.
///
/// **Security:**
/// - All mappings encrypted using SecureMappingEncryptionService
/// - Keys stored in FlutterSecureStorage (hardware-backed)
/// - RLS enforces access control at database level
///
/// **Performance:**
/// - In-memory cache (5 minute TTL) for fast lookups
/// - Async audit logging (batched) for minimal overhead
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
    SecureMappingEncryptionService? encryptionService,
    BusinessAccountService? businessService, // Reserved for future use
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _encryptionService =
            encryptionService ?? SecureMappingEncryptionService();

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
  ///
  /// **Security:**
  /// - All mappings stored encrypted in user_agent_mappings_secure table
  /// - No plaintext storage (migration complete)
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

      // Check secure encrypted table (encryption service is required)
      try {
        final response = await client
            .from('user_agent_mappings_secure')
            .select(
                'encrypted_mapping, encryption_key_id, encryption_algorithm')
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

          // agentId can be null if decryption fails, but we check it
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

      // Encrypt and store mapping (encryption service is required)
      try {
        // Encrypt mapping
        final encrypted = await _encryptionService.encryptMapping(
          userId: userId,
          agentId: agentId,
        );

        // Store encrypted mapping (RLS enforces user can only insert their own)
        await client.from('user_agent_mappings_secure').insert({
          'user_id': userId,
          'encrypted_mapping': encrypted.encryptedBlob.toList(),
          'encryption_key_id': encrypted.encryptionKeyId,
          'encryption_algorithm': encrypted.algorithm.name,
          'encryption_version': encrypted.version,
          'created_at': encrypted.encryptedAt.toIso8601String(),
        });

        // Log creation (async, batched)
        _logMappingAccess(userId, 'created').catchError((e) {
          developer.log('Error logging creation: $e', name: _logName);
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
      await client.from('user_agent_mappings_secure').update({
        'last_accessed_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      developer.log('Error updating last accessed: $e', name: _logName);
      // Don't fail if update fails
    }
  }

  /// Log mapping access (async, batched for performance)
  ///
  /// **Privacy:** Uses agentId instead of userId to prevent data leakage
  Future<void> _logMappingAccess(String userId, String action) async {
    // Get agentId for audit log (don't store userId for privacy)
    final agentId = await getUserAgentId(userId);

    _auditLogQueue.add({
      'agent_id': agentId, // Use agentId instead of userId for privacy
      'action': action,
      'accessed_by': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Flush queue if batch size reached or interval elapsed
    if (_auditLogQueue.length >= _auditLogBatchSize ||
        (_lastAuditLogFlush != null &&
            DateTime.now().difference(_lastAuditLogFlush!) >
                _auditLogFlushInterval)) {
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
  Future<void> rotateMappingEncryptionKey(
    String userId, {
    EncryptedMapping? existingEncryptedMapping,
  }) async {
    try {
      // Prefer safe client access to avoid hard failures in tests / when
      // Supabase isn't initialized.
      final client = _supabaseService.tryGetClient();

      // In offline / no-Supabase environments we don't have an encrypted mapping
      // record to rotate. Keep this operation as a safe no-op that still clears
      // the in-memory cache so callers can treat rotation as "completed".
      if (client == null && existingEncryptedMapping == null) {
        _agentIdCache.remove(userId);
        return;
      }

      // Get old encrypted mapping
      final EncryptedMapping oldMapping;
      if (existingEncryptedMapping != null) {
        oldMapping = existingEncryptedMapping;
      } else {
        final supabase = client!; // safe: handled by early return above
        final response = await supabase
            .from('user_agent_mappings_secure')
            .select(
                'encrypted_mapping, encryption_key_id, encryption_algorithm')
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) {
          throw Exception('No mapping found for user');
        }

        // Create EncryptedMapping from response
        oldMapping = EncryptedMapping(
          encryptedBlob: Uint8List.fromList(
            List<int>.from(response['encrypted_mapping'] as List),
          ),
          encryptionKeyId: response['encryption_key_id'] as String,
          algorithm: EncryptionAlgorithm.values.firstWhere(
            (e) => e.name == response['encryption_algorithm'],
            orElse: () => EncryptionAlgorithm.aes256GCM,
          ),
          encryptedAt: DateTime.now(), // Approximate
          version: 1,
        );
      }

      // Rotate encryption key (re-encrypt with new key)
      final newEncrypted = await _encryptionService.rotateEncryptionKey(
        userId: userId,
        oldMapping: oldMapping,
      );

      // Best-effort: update database with new encrypted mapping when possible.
      if (client != null) {
        await client.from('user_agent_mappings_secure').update({
          'encrypted_mapping': newEncrypted.encryptedBlob.toList(),
          'encryption_key_id': newEncrypted.encryptionKeyId,
          'last_rotated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      }

      // Clear cache (force re-fetch)
      _agentIdCache.remove(userId);

      // Log rotation
      if (client != null) {
        _logMappingAccess(userId, 'rotated').catchError((e) {
          developer.log('Error logging rotation: $e', name: _logName);
        });
      }
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

  /// Get agent ID for a business
  ///
  /// Uses business ID to generate/get agent ID.
  /// Businesses can have their own agent IDs for ai2ai routing.
  Future<String> getBusinessAgentId(String businessId) async {
    try {
      if (!_supabaseService.isAvailable) {
        // Fallback: Generate deterministic agent ID from business ID
        return _generateDeterministicAgentId('business_$businessId');
      }

      // Check for existing mapping in business_agent_mappings (if table exists)
      // For now, use deterministic generation based on business ID
      // TODO: Create business_agent_mappings table if needed

      // Generate deterministic agent ID for business
      // This ensures same business always gets same agent ID
      return _generateDeterministicAgentId('business_$businessId');
    } catch (e) {
      developer.log('Error getting business agent ID: $e', name: _logName);
      return _generateDeterministicAgentId('business_$businessId');
    }
  }

  /// Generate cryptographically secure agent ID
  ///
  /// Format: agent_[32+ character base64url string]
  String _generateSecureAgentId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    final base64 = base64Encode(hash.bytes);
    // Convert to base64url (replace + with -, / with _)
    final base64url =
        base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
    return 'agent_${base64url.substring(0, 32)}';
  }

  /// Generate deterministic agent ID from identifier
  ///
  /// Same identifier always produces same agent ID.
  /// Used for businesses and fallback scenarios.
  String _generateDeterministicAgentId(String identifier) {
    final bytes = utf8.encode(identifier);
    final hash = sha256.convert(bytes);
    final base64 = base64Encode(hash.bytes);
    final base64url =
        base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
    return 'agent_${base64url.substring(0, 32)}';
  }

  /// Get agent ID for expert (user)
  ///
  /// Alias for getUserAgentId for clarity.
  Future<String> getExpertAgentId(String expertId) async {
    return getUserAgentId(expertId);
  }
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
