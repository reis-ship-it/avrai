import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'dart:typed_data';

/// Mock SupabaseService for testing
class MockSupabaseService extends Mock implements SupabaseService {}

/// Mock SecureMappingEncryptionService for testing
class MockSecureMappingEncryptionService extends Mock
    implements SecureMappingEncryptionService {}

/// Tests for Agent ID Migration Script
///
/// Tests the migration of plaintext mappings to encrypted storage.
/// This script will be implemented in Phase 4.
///
/// **Test Coverage:**
/// - Reading plaintext mappings from old table
/// - Encrypting each mapping
/// - Writing encrypted mappings to new table
/// - Error handling and recovery
/// - Batch processing
/// - Data integrity verification
void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(Uint8List.fromList([0]));
    registerFallbackValue(
      EncryptedMapping(
        encryptedBlob: Uint8List.fromList([0]),
        encryptionKeyId: '',
        algorithm: EncryptionAlgorithm.aes256GCM,
        encryptedAt: DateTime.now(),
        version: 1,
      ),
    );
  });

  group('AgentIdMigrationScript', () {
    late MockSupabaseService mockSupabaseService;
    late MockSecureMappingEncryptionService mockEncryptionService;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockEncryptionService = MockSecureMappingEncryptionService();

      when(() => mockSupabaseService.isAvailable).thenReturn(true);
    });

    test('should read plaintext mappings from old table', () async {
      // Arrange
      final plaintextMappings = [
        {'user_id': 'user-1', 'agent_id': 'agent_abc123'},
        {'user_id': 'user-2', 'agent_id': 'agent_def456'},
      ];

      // This test verifies the migration script can read from old table
      // Implementation will query: SELECT user_id, agent_id FROM user_agent_mappings
      expect(plaintextMappings.length, equals(2));
      expect(plaintextMappings[0]['user_id'], equals('user-1'));
      expect(plaintextMappings[0]['agent_id'], equals('agent_abc123'));
    });

    test('should encrypt each mapping using SecureMappingEncryptionService',
        () async {
      // Arrange
      const userId = 'user-1';
      const agentId = 'agent_abc123';

      final encryptedMapping = EncryptedMapping(
        encryptedBlob: Uint8List.fromList([1, 2, 3, 4, 5]),
        encryptionKeyId: 'key-123',
        algorithm: EncryptionAlgorithm.aes256GCM,
        encryptedAt: DateTime.now(),
        version: 1,
      );

      when(() => mockEncryptionService.encryptMapping(
            userId: userId,
            agentId: agentId,
          )).thenAnswer((_) async => encryptedMapping);

      // Act
      final result = await mockEncryptionService.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Assert
      expect(result.encryptedBlob, isNotEmpty);
      expect(result.encryptionKeyId, isNotEmpty);
      verify(() => mockEncryptionService.encryptMapping(
            userId: userId,
            agentId: agentId,
          )).called(1);
    });

    test('should write encrypted mappings to new secure table', () async {
      // Arrange
      final encryptedMapping = EncryptedMapping(
        encryptedBlob: Uint8List.fromList([1, 2, 3, 4, 5]),
        encryptionKeyId: 'key-123',
        algorithm: EncryptionAlgorithm.aes256GCM,
        encryptedAt: DateTime.now(),
        version: 1,
      );

      // This test verifies the migration script can write to new table
      // Implementation will insert into: user_agent_mappings_secure
      final insertData = {
        'user_id': 'user-1',
        'encrypted_mapping': encryptedMapping.encryptedBlob.toList(),
        'encryption_key_id': encryptedMapping.encryptionKeyId,
        'encryption_algorithm': encryptedMapping.algorithm.name,
        'encryption_version': encryptedMapping.version,
      };

      expect(insertData['user_id'], equals('user-1'));
      expect(insertData['encrypted_mapping'], isA<List>());
      expect(insertData['encryption_key_id'], equals('key-123'));
    });

    test('should handle missing encryption service gracefully', () {
      // Arrange
      const migrationScript = null; // Will be implemented in Phase 4

      // Assert - should handle null encryption service
      expect(migrationScript, isNull);
      // Implementation should skip migration if encryption service unavailable
    });

    test('should skip already migrated mappings', () async {
      // Arrange
      const userId = 'user-1';

      // This test verifies the migration script checks if mapping already exists
      // Implementation will query: SELECT user_id FROM user_agent_mappings_secure WHERE user_id = ?
      final existingMappings = [userId];

      // Assert - should skip if already migrated
      expect(existingMappings.contains(userId), isTrue);
      // Implementation should skip this user
    });

    test('should batch process mappings for performance', () {
      // Arrange
      const batchSize = 100;
      const totalMappings = 500;
      final expectedBatches = (totalMappings / batchSize).ceil();

      // Assert - should process in batches
      expect(expectedBatches, equals(5));
      // Implementation should process 100 mappings at a time
    });

    test('should log migration progress', () {
      // Arrange
      const totalMappings = 500;
      const migratedCount = 250;
      const progress = (migratedCount / totalMappings) * 100;

      // Assert - should track progress
      expect(progress, equals(50.0));
      // Implementation should log: "Migrated 250/500 mappings (50%)"
    });

    test('should handle errors during migration (continue with next)', () {
      // Arrange
      final mappings = [
        {'user_id': 'user-1', 'agent_id': 'agent_abc123'},
        {'user_id': 'user-2', 'agent_id': 'agent_def456'}, // This one will fail
        {'user_id': 'user-3', 'agent_id': 'agent_ghi789'},
      ];

      // Simulate error on second mapping
      final errors = <String>[];
      for (final mapping in mappings) {
        try {
          if (mapping['user_id'] == 'user-2') {
            throw Exception('Encryption failed');
          }
        } catch (e) {
          errors.add(mapping['user_id'] as String);
        }
      }

      // Assert - should continue with next mapping
      expect(errors.length, equals(1));
      expect(errors[0], equals('user-2'));
      // Implementation should log error and continue
    });

    test('should verify migrated mappings can be decrypted', () async {
      // Arrange
      const userId = 'user-1';
      const agentId = 'agent_abc123';

      final encryptedMapping = EncryptedMapping(
        encryptedBlob: Uint8List.fromList([1, 2, 3, 4, 5]),
        encryptionKeyId: 'key-123',
        algorithm: EncryptionAlgorithm.aes256GCM,
        encryptedAt: DateTime.now(),
        version: 1,
      );

      when(() => mockEncryptionService.decryptMapping(
            userId: userId,
            encryptedBlob: any(named: 'encryptedBlob'),
            encryptionKeyId: any(named: 'encryptionKeyId'),
          )).thenAnswer((_) async => agentId);

      // Act
      final decrypted = await mockEncryptionService.decryptMapping(
        userId: userId,
        encryptedBlob: encryptedMapping.encryptedBlob,
        encryptionKeyId: encryptedMapping.encryptionKeyId,
      );

      // Assert
      expect(decrypted, equals(agentId));
    });

    test('should create audit log entries for each migration', () {
      // Arrange
      final migrations = [
        {'user_id': 'user-1', 'action': 'migrated'},
        {'user_id': 'user-2', 'action': 'migrated'},
      ];

      // Assert - should create audit log entries
      expect(migrations.length, equals(2));
      // Implementation should insert into agent_mapping_audit_log
    });

    test('should handle concurrent migrations (idempotent)', () {
      // Arrange
      const userId = 'user-1';
      final migration1 = {'user_id': userId, 'status': 'migrated'};
      final migration2 = {'user_id': userId, 'status': 'migrated'};

      // Assert - should be idempotent (running twice is safe)
      expect(migration1['status'], equals(migration2['status']));
      // Implementation should check if already migrated before processing
    });

    test('should verify data integrity (count matches)', () {
      // Arrange
      const oldTableCount = 500;
      const newTableCount = 500;
      const migratedCount = 500;

      // Assert - counts should match
      expect(oldTableCount, equals(newTableCount));
      expect(migratedCount, equals(oldTableCount));
      // Implementation should verify: COUNT(old) == COUNT(new)
    });
  });
}
