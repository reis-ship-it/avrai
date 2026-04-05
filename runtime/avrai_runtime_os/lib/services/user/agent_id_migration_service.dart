import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'dart:typed_data';

/// Agent ID Migration Service
///
/// Migrates plaintext userId ↔ agentId mappings from `user_agent_mappings`
/// to encrypted storage in `user_agent_mappings_secure`.
///
/// **Security:**
/// - All mappings encrypted using SecureMappingEncryptionService
/// - Keys stored in FlutterSecureStorage (not in database)
/// - RLS policies enforce access control
/// - Audit logs track all migrations
///
/// **Performance:**
/// - Batch processing for efficiency
/// - Idempotent (safe to run multiple times)
/// - Progress tracking
/// - Error recovery (continues on individual failures)
///
/// **Usage:**
/// ```dart
/// final migrationService = AgentIdMigrationService(
///   supabaseService: supabaseService,
///   encryptionService: encryptionService,
/// );
///
/// final result = await migrationService.migrateAllMappings(
///   batchSize: 100,
///   limit: 1000,
/// );
/// ```
class AgentIdMigrationService {
  static const String _logName = 'AgentIdMigrationService';

  final SupabaseService _supabaseService;
  final SecureMappingEncryptionService _encryptionService;

  AgentIdMigrationService({
    required SupabaseService supabaseService,
    required SecureMappingEncryptionService encryptionService,
  })  : _supabaseService = supabaseService,
        _encryptionService = encryptionService;

  /// Migrate all plaintext mappings to encrypted storage
  ///
  /// **Process:**
  /// 1. Read plaintext mappings from `user_agent_mappings`
  /// 2. Check if already migrated (skip if exists in secure table)
  /// 3. Encrypt each mapping
  /// 4. Write to `user_agent_mappings_secure`
  /// 5. Create audit log entries
  ///
  /// **Parameters:**
  /// - `batchSize`: Number of mappings to process per batch (default: 100)
  /// - `limit`: Maximum number of mappings to migrate (null = all)
  /// - `dryRun`: Preview migration without making changes (default: false)
  ///
  /// **Returns:**
  /// MigrationResult with statistics
  Future<MigrationResult> migrateAllMappings({
    int batchSize = 100,
    int? limit,
    bool dryRun = false,
  }) async {
    try {
      developer.log(
        '🚀 Starting migration (batchSize: $batchSize, limit: ${limit ?? 'unlimited'}, dryRun: $dryRun)',
        name: _logName,
      );

      if (!_supabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final client = _supabaseService.client;

      // Step 1: Get total count of plaintext mappings
      final totalCount = await _getPlaintextMappingCount(client);
      developer.log('📊 Found $totalCount plaintext mappings to migrate',
          name: _logName);

      if (totalCount == 0) {
        return MigrationResult(
          totalMappings: 0,
          migrated: 0,
          skipped: 0,
          errors: 0,
          dryRun: dryRun,
        );
      }

      // Step 2: Process in batches
      final effectiveLimit = limit ?? totalCount;
      final batches = (effectiveLimit / batchSize).ceil();

      int migrated = 0;
      int skipped = 0;
      int errors = 0;

      for (int batch = 0; batch < batches; batch++) {
        final offset = batch * batchSize;
        final batchLimit = (offset + batchSize > effectiveLimit)
            ? effectiveLimit - offset
            : batchSize;

        developer.log(
          '📦 Processing batch ${batch + 1}/$batches (offset: $offset, limit: $batchLimit)',
          name: _logName,
        );

        // Read batch of plaintext mappings
        final plaintextMappings = await _getPlaintextMappingsBatch(
          client,
          offset: offset,
          limit: batchLimit,
        );

        // Process each mapping
        for (final mapping in plaintextMappings) {
          try {
            final userId = mapping['user_id'] as String;
            final agentId = mapping['agent_id'] as String;

            // Check if already migrated
            final alreadyMigrated = await _isAlreadyMigrated(client, userId);
            if (alreadyMigrated) {
              skipped++;
              developer.log('⏭️  Skipping already migrated: $userId',
                  name: _logName);
              continue;
            }

            if (dryRun) {
              migrated++;
              developer.log('🔍 [DRY RUN] Would migrate: $userId',
                  name: _logName);
              continue;
            }

            // Encrypt mapping
            final encrypted = await _encryptionService.encryptMapping(
              userId: userId,
              agentId: agentId,
            );

            // Write to secure table
            await _writeEncryptedMapping(client, userId, encrypted);

            // Create audit log entry
            await _logMigration(client, userId, 'migrated');

            migrated++;

            if (migrated % 10 == 0) {
              developer.log(
                '✅ Progress: $migrated migrated, $skipped skipped, $errors errors',
                name: _logName,
              );
            }
          } catch (e, stackTrace) {
            errors++;
            developer.log(
              '❌ Error migrating mapping: $e',
              error: e,
              stackTrace: stackTrace,
              name: _logName,
            );
            // Continue with next mapping
          }
        }
      }

      developer.log(
        '✅ Migration complete: $migrated migrated, $skipped skipped, $errors errors',
        name: _logName,
      );

      return MigrationResult(
        totalMappings: totalCount,
        migrated: migrated,
        skipped: skipped,
        errors: errors,
        dryRun: dryRun,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Migration failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get count of plaintext mappings
  Future<int> _getPlaintextMappingCount(dynamic client) async {
    try {
      // Get all mappings and count (for small datasets)
      // For large datasets, use a count query or estimate
      final response =
          await client.from('user_agent_mappings').select('user_id');

      return (response as List).length;
    } catch (e) {
      developer.log('Error getting mapping count: $e', name: _logName);
      return 0;
    }
  }

  /// Get batch of plaintext mappings
  Future<List<Map<String, dynamic>>> _getPlaintextMappingsBatch(
    dynamic client, {
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await client
          .from('user_agent_mappings')
          .select('user_id, agent_id')
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      developer.log('Error getting mappings batch: $e', name: _logName);
      return [];
    }
  }

  /// Check if mapping already migrated
  Future<bool> _isAlreadyMigrated(dynamic client, String userId) async {
    try {
      final response = await client
          .from('user_agent_mappings_secure')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      developer.log('Error checking if migrated: $e', name: _logName);
      return false; // Assume not migrated if check fails
    }
  }

  /// Write encrypted mapping to secure table
  Future<void> _writeEncryptedMapping(
    dynamic client,
    String userId,
    EncryptedMapping encrypted,
  ) async {
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
      developer.log('Error writing encrypted mapping: $e', name: _logName);
      rethrow;
    }
  }

  /// Log migration to audit log
  Future<void> _logMigration(
    dynamic client,
    String userId,
    String action,
  ) async {
    try {
      await client.from('agent_mapping_audit_log').insert({
        'user_id': userId,
        'action': action,
        'accessed_by': 'migration_script',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error logging migration: $e', name: _logName);
      // Don't fail migration if audit logging fails
    }
  }

  /// Verify migration integrity
  ///
  /// Verifies that all plaintext mappings have been migrated correctly.
  ///
  /// **Returns:**
  /// VerificationResult with counts and any discrepancies
  Future<VerificationResult> verifyMigration() async {
    try {
      if (!_supabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final client = _supabaseService.client;

      // Get counts
      final plaintextCount = await _getPlaintextMappingCount(client);
      final secureCount = await _getSecureMappingCount(client);

      // Get list of user IDs from both tables
      final plaintextUserIds = await _getPlaintextUserIds(client);
      final secureUserIds = await _getSecureUserIds(client);

      // Find discrepancies
      final notMigrated =
          plaintextUserIds.where((id) => !secureUserIds.contains(id)).toList();

      final extraSecure =
          secureUserIds.where((id) => !plaintextUserIds.contains(id)).toList();

      // Verify decryption works for sample
      int decryptionErrors = 0;
      if (secureUserIds.isNotEmpty) {
        final sampleSize =
            secureUserIds.length > 10 ? 10 : secureUserIds.length;
        for (int i = 0; i < sampleSize; i++) {
          try {
            final userId = secureUserIds[i];
            final encrypted = await _getEncryptedMapping(client, userId);
            if (encrypted != null) {
              final decrypted = await _encryptionService.decryptMapping(
                userId: userId,
                encryptedBlob: encrypted.encryptedBlob,
                encryptionKeyId: encrypted.encryptionKeyId,
              );
              if (decrypted == null) {
                decryptionErrors++;
              }
            }
          } catch (e) {
            decryptionErrors++;
          }
        }
      }

      return VerificationResult(
        plaintextCount: plaintextCount,
        secureCount: secureCount,
        notMigrated: notMigrated,
        extraSecure: extraSecure,
        decryptionErrors: decryptionErrors,
        isComplete: notMigrated.isEmpty && decryptionErrors == 0,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error verifying migration: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get count of secure mappings
  Future<int> _getSecureMappingCount(dynamic client) async {
    try {
      // Get all mappings and count (for small datasets)
      // For large datasets, use a count query or estimate
      final response =
          await client.from('user_agent_mappings_secure').select('user_id');

      return (response as List).length;
    } catch (e) {
      developer.log('Error getting secure mapping count: $e', name: _logName);
      return 0;
    }
  }

  /// Get list of user IDs from plaintext table
  Future<List<String>> _getPlaintextUserIds(dynamic client) async {
    try {
      final response =
          await client.from('user_agent_mappings').select('user_id');

      return (response as List).map((e) => e['user_id'] as String).toList();
    } catch (e) {
      developer.log('Error getting plaintext user IDs: $e', name: _logName);
      return [];
    }
  }

  /// Get list of user IDs from secure table
  Future<List<String>> _getSecureUserIds(dynamic client) async {
    try {
      final response =
          await client.from('user_agent_mappings_secure').select('user_id');

      return (response as List).map((e) => e['user_id'] as String).toList();
    } catch (e) {
      developer.log('Error getting secure user IDs: $e', name: _logName);
      return [];
    }
  }

  /// Get encrypted mapping for a user
  Future<EncryptedMapping?> _getEncryptedMapping(
    dynamic client,
    String userId,
  ) async {
    try {
      final response = await client
          .from('user_agent_mappings_secure')
          .select('encrypted_mapping, encryption_key_id, encryption_algorithm')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return EncryptedMapping(
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
    } catch (e) {
      developer.log('Error getting encrypted mapping: $e', name: _logName);
      return null;
    }
  }
}

/// Migration result model
class MigrationResult {
  final int totalMappings;
  final int migrated;
  final int skipped;
  final int errors;
  final bool dryRun;

  const MigrationResult({
    required this.totalMappings,
    required this.migrated,
    required this.skipped,
    required this.errors,
    required this.dryRun,
  });

  @override
  String toString() {
    return 'MigrationResult(total: $totalMappings, migrated: $migrated, skipped: $skipped, errors: $errors, dryRun: $dryRun)';
  }
}

/// Verification result model
class VerificationResult {
  final int plaintextCount;
  final int secureCount;
  final List<String> notMigrated;
  final List<String> extraSecure;
  final int decryptionErrors;
  final bool isComplete;

  const VerificationResult({
    required this.plaintextCount,
    required this.secureCount,
    required this.notMigrated,
    required this.extraSecure,
    required this.decryptionErrors,
    required this.isComplete,
  });

  @override
  String toString() {
    return 'VerificationResult(plaintext: $plaintextCount, secure: $secureCount, notMigrated: ${notMigrated.length}, extraSecure: ${extraSecure.length}, decryptionErrors: $decryptionErrors, isComplete: $isComplete)';
  }
}
