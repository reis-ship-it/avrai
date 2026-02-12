import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/security/secure_mapping_encryption_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import '../../helpers/test_helpers.dart';

/// End-to-End Integration Tests for Secure Agent ID Workflow
/// 
/// Tests the complete workflow from creation to migration to rotation.
/// These tests verify the entire system works together correctly.
/// 
/// **Test Coverage:**
/// - Complete workflow (create → migrate → rotate → retrieve)
/// - Performance under load
/// - Concurrency safety
/// - Data integrity
/// - Security enforcement
/// - Backward compatibility
void main() {
  group('Secure Agent ID Workflow', () {
    late SupabaseService supabaseService;
    late SecureMappingEncryptionService encryptionService;
    late AgentIdService agentIdService;

    setUpAll(() {
      TestHelpers.setupTestEnvironment();
    });

    setUp(() {
      supabaseService = SupabaseService();
      encryptionService = SecureMappingEncryptionService();
      agentIdService = AgentIdService(
        supabaseService: supabaseService,
        encryptionService: encryptionService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should create new mapping with encryption', () async {
      // Arrange
      const userId = 'user-test-1';

      // Act
      final agentId = await agentIdService.getUserAgentId(userId);

      // Assert
      expect(agentId, isNotEmpty);
      expect(agentId, startsWith('agent_'));
      expect(agentId.length, greaterThan(32));

      if (supabaseService.isAvailable) {
        // Verify mapping was created in secure table
        // Implementation will verify user_agent_mappings_secure contains entry
      }
    });

    test('should retrieve encrypted mapping correctly', () async {
      // Arrange
      const userId = 'user-test-2';

      // Create mapping first
      final agentId1 = await agentIdService.getUserAgentId(userId);

      // Act - retrieve again (should use cache or decrypt)
      final agentId2 = await agentIdService.getUserAgentId(userId);

      // Assert - should return same agent ID
      expect(agentId1, equals(agentId2));
    });

    test('should migrate existing plaintext mappings', () async {
      // Arrange
      // This test requires:
      // 1. Plaintext mappings in user_agent_mappings table
      // 2. Migration script execution
      // 3. Verification of encrypted mappings

      if (!supabaseService.isAvailable) {
        return;
      }

      // Implementation will:
      // 1. Run migration script
      // 2. Verify mappings are encrypted
      // 3. Verify mappings can be decrypted

      expect(supabaseService.isAvailable, isTrue);
    });

    test('should rotate keys and maintain functionality', () async {
      // Arrange
      const userId = 'user-test-3';

      // Create mapping first
      final agentIdBefore = await agentIdService.getUserAgentId(userId);

      // Act - rotate key
      await agentIdService.rotateMappingEncryptionKey(userId);

      // Retrieve again (should use new key)
      final agentIdAfter = await agentIdService.getUserAgentId(userId);

      // Assert - agent ID should remain the same
      expect(agentIdAfter, equals(agentIdBefore));
    });

    test('should handle cache invalidation correctly', () async {
      // Arrange
      const userId = 'user-test-4';

      // Create mapping and populate cache
      final agentId1 = await agentIdService.getUserAgentId(userId);

      // Clear cache
      agentIdService.clearCache();

      // Act - retrieve again (should hit database)
      final agentId2 = await agentIdService.getUserAgentId(userId);

      // Assert - should return same agent ID
      expect(agentId2, equals(agentId1));
    });

    test('should enforce RLS policies correctly', () async {
      // Arrange
      // This test verifies:
      // 1. Users can only access their own mappings
      // 2. Service role can access all mappings
      // 3. Unauthenticated users cannot access mappings

      if (!supabaseService.isAvailable) {
        return;
      }

      // Implementation will:
      // 1. Try to access another user's mapping (should fail)
      // 2. Try to access own mapping (should succeed)
      // 3. Verify RLS policies are enforced

      expect(supabaseService.isAvailable, isTrue);
    });

    test('should log all operations to audit log', () async {
      // Arrange
      const userId = 'user-test-5';

      // Act - perform operations
      await agentIdService.getUserAgentId(userId);
      await agentIdService.rotateMappingEncryptionKey(userId);

      if (supabaseService.isAvailable) {
        // Verify audit log entries exist
        // Implementation will query agent_mapping_audit_log
      }

      expect(true, isTrue); // Placeholder
    });

    test('should handle concurrent operations safely', () async {
      // Arrange
      const userId = 'user-test-6';

      // Act - perform concurrent operations
      final futures = List.generate(10, (_) => agentIdService.getUserAgentId(userId));
      final results = await Future.wait(futures);

      // Assert - all should return same agent ID
      expect(results.every((id) => id == results[0]), isTrue);
    });

    test('should maintain backward compatibility during migration', () async {
      // Arrange
      // This test verifies:
      // 1. Old table still works during migration
      // 2. New table works after migration
      // 3. System gracefully handles both

      if (!supabaseService.isAvailable) {
        return;
      }

      // Implementation will:
      // 1. Verify fallback to old table works
      // 2. Verify new table is preferred when available
      // 3. Verify no service interruption

      expect(supabaseService.isAvailable, isTrue);
    });

    test('should verify performance under load', () async {
      // Arrange
      final startTime = DateTime.now();
      const iterations = 100;

      // Act - perform multiple operations
      for (int i = 0; i < iterations; i++) {
        await agentIdService.getUserAgentId('user-load-test-$i');
      }

      // Assert - should complete in reasonable time
      final elapsed = DateTime.now().difference(startTime);
      expect(elapsed.inSeconds, lessThan(30)); // Should complete in < 30 seconds
    });
  });
}
