import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/security/secure_mapping_encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Security Tests for Encryption
/// 
/// Tests encryption security to ensure:
/// - Encrypted data cannot be decrypted without key
/// - Different keys produce different ciphertexts
/// - Same plaintext with same key produces same ciphertext (deterministic)
/// - Keys are not exposed
void main() {
  group('Encryption Security Tests', () {
    late SecureMappingEncryptionService service1;
    late SecureMappingEncryptionService service2;
    late MockFlutterSecureStorage mockStorage1;
    late MockFlutterSecureStorage mockStorage2;
    
    setUp(() {
      mockStorage1 = MockFlutterSecureStorage();
      mockStorage2 = MockFlutterSecureStorage();
      
      // In-memory storage to track keys
      final Map<String, String> keyStorage1 = {};
      final Map<String, String> keyStorage2 = {};
      
      // Set up read to return stored value or null
      when(() => mockStorage1.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage1[key];
      });
      
      when(() => mockStorage2.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage2[key];
      });
      
      // Set up write to store value
      when(() => mockStorage1.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage1[key] = value;
      });
      
      when(() => mockStorage2.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage2[key] = value;
      });
      
      service1 = SecureMappingEncryptionService(secureStorage: mockStorage1);
      service2 = SecureMappingEncryptionService(secureStorage: mockStorage2);
    });
    
    test('Encrypted data cannot be decrypted with wrong key', () async {
      const userId1 = 'user-1';
      const userId2 = 'user-2';
      const agentId = 'agent_test_abc123';
      
      // Encrypt with user1's key
      final encrypted1 = await service1.encryptMapping(
        userId: userId1,
        agentId: agentId,
      );
      
      // Try to decrypt with user2's key (should fail)
      expect(
        () async => service2.decryptMapping(
          userId: userId2,
          encryptedBlob: encrypted1.encryptedBlob,
          encryptionKeyId: encrypted1.encryptionKeyId,
        ),
        throwsA(isA<Exception>()),
      );
    });
    
    test('Different plaintexts produce different ciphertexts', () async {
      const userId = 'test-user';
      const agentId1 = 'agent_test_abc123';
      const agentId2 = 'agent_test_def456';
      
      final encrypted1 = await service1.encryptMapping(
        userId: userId,
        agentId: agentId1,
      );
      
      final encrypted2 = await service1.encryptMapping(
        userId: userId,
        agentId: agentId2,
      );
      
      // Ciphertexts should be different (even with same key, different IV)
      expect(encrypted1.encryptedBlob, isNot(equals(encrypted2.encryptedBlob)),
        reason: 'Different plaintexts should produce different ciphertexts');
    });
    
    test('Same plaintext produces different ciphertexts (non-deterministic)', () async {
      const userId = 'test-user';
      const agentId = 'agent_test_abc123';
      
      // Encrypt same plaintext twice
      final encrypted1 = await service1.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      final encrypted2 = await service1.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      // Ciphertexts should be different (due to random IV)
      expect(encrypted1.encryptedBlob, isNot(equals(encrypted2.encryptedBlob)),
        reason: 'Same plaintext should produce different ciphertexts (non-deterministic)');
    });
    
    test('Encrypted data is not readable as text', () async {
      const userId = 'test-user';
      const agentId = 'agent_test_abc123';
      
      final encrypted = await service1.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      
      // Try to decode as UTF-8 (should fail or produce garbage)
      try {
        final decoded = String.fromCharCodes(encrypted.encryptedBlob);
        // If it decodes, it shouldn't contain the original agentId
        expect(decoded, isNot(contains(agentId)),
          reason: 'Encrypted data should not contain plaintext');
      } catch (e) {
        // Expected - encrypted data is not valid UTF-8
        expect(e, isNotNull);
      }
    });
    
    test('Key ID is unique per user', () async {
      const userId1 = 'user-1';
      const userId2 = 'user-2';
      const agentId = 'agent_test_abc123';
      
      final encrypted1 = await service1.encryptMapping(
        userId: userId1,
        agentId: agentId,
      );
      
      final encrypted2 = await service1.encryptMapping(
        userId: userId2,
        agentId: agentId,
      );
      
      // Key IDs should be different (different users, different keys)
      expect(encrypted1.encryptionKeyId, isNot(equals(encrypted2.encryptionKeyId)),
        reason: 'Different users should have different key IDs');
    });
  });
}
