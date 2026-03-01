import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'dart:typed_data';

/// Mapping Key Rotation Service
///
/// Rotates encryption keys for userId ↔ agentId mappings in batches.
///
/// **Security:**
/// - Re-encrypts mappings with new keys
/// - Invalidates old keys (old mappings cannot be decrypted)
/// - Updates encryption_key_id and rotation metadata
/// - Logs all rotations to audit log
///
/// **Performance:**
/// - Batch processing for efficiency
/// - Rate limiting to prevent system overload
/// - Background processing support
///
/// **Usage:**
/// ```dart
/// final rotationService = MappingKeyRotationService(
///   supabaseService: supabaseService,
///   encryptionService: encryptionService,
///   agentIdService: agentIdService,
/// );
///
/// // Rotate single user
/// await rotationService.rotateUserKey(userId);
///
/// // Batch rotate
/// final result = await rotationService.rotateKeysBatch(
///   userIds: [userId1, userId2, userId3],
///   batchSize: 10,
/// );
/// ```
class MappingKeyRotationService {
  static const String _logName = 'MappingKeyRotationService';

  final SupabaseService _supabaseService;
  final SecureMappingEncryptionService _encryptionService;
  final AgentIdService _agentIdService;

  // Rate limiting
  static const int _maxRotationsPerHour = 100;
  static const Duration _rateLimitWindow = Duration(hours: 1);
  final Map<String, List<DateTime>> _rotationHistory = {};

  MappingKeyRotationService({
    required SupabaseService supabaseService,
    required SecureMappingEncryptionService encryptionService,
    required AgentIdService agentIdService,
  })  : _supabaseService = supabaseService,
        _encryptionService = encryptionService,
        _agentIdService = agentIdService;

  /// Rotate encryption key for a single user
  ///
  /// **Process:**
  /// 1. Get old encrypted mapping
  /// 2. Decrypt with old key
  /// 3. Generate new encryption key
  /// 4. Re-encrypt with new key
  /// 5. Update database
  /// 6. Clear cache
  /// 7. Log rotation
  ///
  /// **Parameters:**
  /// - `userId`: User ID to rotate key for
  ///
  /// **Throws:**
  /// - Exception if rotation fails
  /// - Exception if rate limit exceeded
  Future<void> rotateUserKey(String userId) async {
    try {
      // Check rate limit
      if (_isRateLimited(userId)) {
        throw Exception('Rate limit exceeded for user: $userId');
      }

      developer.log('🔄 Rotating encryption key for user: $userId',
          name: _logName);

      if (!_supabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final client = _supabaseService.client;

      // Get old encrypted mapping
      final response = await client
          .from('user_agent_mappings_secure')
          .select('encrypted_mapping, encryption_key_id, encryption_algorithm')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('No encrypted mapping found for user: $userId');
      }

      // Create EncryptedMapping from response
      final oldMapping = EncryptedMapping(
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

      // Rotate encryption key (re-encrypt with new key)
      final newEncrypted = await _encryptionService.rotateEncryptionKey(
        userId: userId,
        oldMapping: oldMapping,
      );

      // Update database with new encrypted mapping
      await client.from('user_agent_mappings_secure').update({
        'encrypted_mapping': newEncrypted.encryptedBlob.toList(),
        'encryption_key_id': newEncrypted.encryptionKeyId,
        'last_rotated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      // Increment rotation count (using database function)
      try {
        await client
            .rpc('increment_rotation_count', params: {'p_user_id': userId});
      } catch (e) {
        developer.log('Error incrementing rotation count: $e', name: _logName);
        // Don't fail rotation if count increment fails
      }

      // Clear cache (force re-fetch)
      _agentIdService.clearCache();

      // Log rotation
      await _logRotation(client, userId, 'rotated');

      // Update rate limit tracking
      _recordRotation(userId);

      developer.log('✅ Key rotation complete for user: $userId',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error rotating key for user $userId: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Rotate keys for multiple users in batch
  ///
  /// **Process:**
  /// - Processes users in batches
  /// - Continues on individual failures
  /// - Returns statistics
  ///
  /// **Parameters:**
  /// - `userIds`: List of user IDs to rotate keys for
  /// - `batchSize`: Number of users to process per batch (default: 10)
  ///
  /// **Returns:**
  /// RotationBatchResult with statistics
  Future<RotationBatchResult> rotateKeysBatch({
    required List<String> userIds,
    int batchSize = 10,
  }) async {
    try {
      developer.log(
        '🔄 Starting batch key rotation for ${userIds.length} users (batchSize: $batchSize)',
        name: _logName,
      );

      int rotated = 0;
      int skipped = 0;
      int errors = 0;
      final errorDetails = <String, String>{};

      // Process in batches
      final batches = (userIds.length / batchSize).ceil();

      for (int batch = 0; batch < batches; batch++) {
        final offset = batch * batchSize;
        final batchLimit = (offset + batchSize > userIds.length)
            ? userIds.length - offset
            : batchSize;

        final batchUserIds = userIds.sublist(offset, offset + batchLimit);

        developer.log(
          '📦 Processing batch ${batch + 1}/$batches (${batchUserIds.length} users)',
          name: _logName,
        );

        for (final userId in batchUserIds) {
          try {
            // Check rate limit
            if (_isRateLimited(userId)) {
              skipped++;
              developer.log('⏭️  Skipping $userId (rate limited)',
                  name: _logName);
              continue;
            }

            await rotateUserKey(userId);
            rotated++;

            if (rotated % 10 == 0) {
              developer.log(
                '✅ Progress: $rotated rotated, $skipped skipped, $errors errors',
                name: _logName,
              );
            }
          } catch (e) {
            errors++;
            errorDetails[userId] = e.toString();
            developer.log(
              '❌ Error rotating key for $userId: $e',
              name: _logName,
            );
            // Continue with next user
          }
        }
      }

      developer.log(
        '✅ Batch rotation complete: $rotated rotated, $skipped skipped, $errors errors',
        name: _logName,
      );

      return RotationBatchResult(
        total: userIds.length,
        rotated: rotated,
        skipped: skipped,
        errors: errors,
        errorDetails: errorDetails,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Batch rotation failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Rotate keys for all users (with rate limiting)
  ///
  /// **Process:**
  /// - Gets all users with encrypted mappings
  /// - Rotates keys in batches
  /// - Respects rate limits
  ///
  /// **Parameters:**
  /// - `batchSize`: Number of users to process per batch (default: 10)
  /// - `limit`: Maximum number of users to rotate (null = all)
  ///
  /// **Returns:**
  /// RotationBatchResult with statistics
  Future<RotationBatchResult> rotateAllKeys({
    int batchSize = 10,
    int? limit,
  }) async {
    try {
      if (!_supabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final client = _supabaseService.client;

      // Get all user IDs with encrypted mappings
      final response =
          await client.from('user_agent_mappings_secure').select('user_id');

      final allUserIds =
          (response as List).map((e) => e['user_id'] as String).toList();

      final effectiveUserIds =
          limit != null ? allUserIds.take(limit).toList() : allUserIds;

      developer.log(
        '🔄 Rotating keys for ${effectiveUserIds.length} users',
        name: _logName,
      );

      return await rotateKeysBatch(
        userIds: effectiveUserIds,
        batchSize: batchSize,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error rotating all keys: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Check if user is rate limited
  bool _isRateLimited(String userId) {
    final now = DateTime.now();
    final history = _rotationHistory[userId] ?? [];

    // Remove rotations outside rate limit window
    final recentRotations = history
        .where((timestamp) => now.difference(timestamp) < _rateLimitWindow)
        .toList();

    _rotationHistory[userId] = recentRotations;

    return recentRotations.length >= _maxRotationsPerHour;
  }

  /// Record rotation for rate limiting
  void _recordRotation(String userId) {
    final history = _rotationHistory[userId] ?? [];
    history.add(DateTime.now());
    _rotationHistory[userId] = history;
  }

  /// Log rotation to audit log
  Future<void> _logRotation(
    dynamic client,
    String userId,
    String action,
  ) async {
    try {
      await client.from('agent_mapping_audit_log').insert({
        'user_id': userId,
        'action': action,
        'accessed_by': 'key_rotation_service',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error logging rotation: $e', name: _logName);
      // Don't fail rotation if audit logging fails
    }
  }

  /// Get rotation statistics for a user
  ///
  /// **Returns:**
  /// Map with rotation count, last rotated timestamp, etc.
  Future<Map<String, dynamic>?> getRotationStats(String userId) async {
    try {
      if (!_supabaseService.isAvailable) {
        return null;
      }

      final client = _supabaseService.client;

      final response = await client
          .from('user_agent_mappings_secure')
          .select('rotation_count, last_rotated_at, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return {
        'rotation_count': response['rotation_count'] ?? 0,
        'last_rotated_at': response['last_rotated_at'],
        'created_at': response['created_at'],
      };
    } catch (e) {
      developer.log('Error getting rotation stats: $e', name: _logName);
      return null;
    }
  }
}

/// Rotation batch result model
class RotationBatchResult {
  final int total;
  final int rotated;
  final int skipped;
  final int errors;
  final Map<String, String> errorDetails;

  const RotationBatchResult({
    required this.total,
    required this.rotated,
    required this.skipped,
    required this.errors,
    this.errorDetails = const {},
  });

  @override
  String toString() {
    return 'RotationBatchResult(total: $total, rotated: $rotated, skipped: $skipped, errors: $errors)';
  }
}
