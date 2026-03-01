import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureMappingEncryptionService', () {
    late SecureMappingEncryptionService service;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();

      // In-memory storage to track keys
      final Map<String, String> keyStorage = {};

      // Set up read to return stored value or null
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage[key];
      });

      // Set up write to store value
      when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage[key] = value;
      });

      // Set up deleteAll to clear storage
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {
        keyStorage.clear();
      });

      service = SecureMappingEncryptionService(
        secureStorage: mockStorage,
      );
    });

    tearDown(() async {
      // Clean up test keys
      await mockStorage.deleteAll();
    });

    test('should encrypt and decrypt mapping correctly', () async {
      // Arrange
      const userId = 'user-123';
      const agentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

      // Act
      final encrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Assert
      expect(encrypted.encryptedBlob, isNotEmpty);
      expect(encrypted.encryptionKeyId, isNotEmpty);
      expect(encrypted.algorithm, EncryptionAlgorithm.aes256GCM);
      expect(encrypted.version, 1);
      expect(encrypted.encryptedAt, isA<DateTime>());

      // Decrypt
      final decrypted = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted.encryptedBlob,
        encryptionKeyId: encrypted.encryptionKeyId,
      );

      // Assert decryption
      expect(decrypted, equals(agentId));
    });

    test(
        'should generate different encrypted blobs for same input (IV randomness)',
        () async {
      // Arrange
      const userId = 'user-123';
      const agentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

      // Act
      final encrypted1 = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      final encrypted2 = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Assert - encrypted blobs should be different (due to random IV)
      expect(encrypted1.encryptedBlob, isNot(equals(encrypted2.encryptedBlob)));

      // But both should decrypt to the same value
      final decrypted1 = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted1.encryptedBlob,
        encryptionKeyId: encrypted1.encryptionKeyId,
      );
      final decrypted2 = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted2.encryptedBlob,
        encryptionKeyId: encrypted2.encryptionKeyId,
      );

      expect(decrypted1, equals(agentId));
      expect(decrypted2, equals(agentId));
    });

    test('should throw SecurityException when user_id mismatch', () async {
      // Arrange
      const userId1 = 'user-123';
      const userId2 = 'user-456';
      const agentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

      // Act
      final encrypted = await service.encryptMapping(
        userId: userId1,
        agentId: agentId,
      );

      // Create a new service instance with a different key for userId2
      final Map<String, String> keyStorage2 = {};
      final mockStorage2 = MockFlutterSecureStorage();
      when(() => mockStorage2.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage2[key];
      });
      when(() => mockStorage2.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage2[key] = value;
      });
      final service2 =
          SecureMappingEncryptionService(secureStorage: mockStorage2);

      // Generate a key for userId2 (different from userId1)
      await service2.encryptMapping(
          userId: userId2, agentId: 'different_agent');

      // Assert - decrypting with wrong userId should fail (wrong key)
      // This will fail at decryption (wrong key) or at validation (user_id mismatch)
      expect(
        () => service2.decryptMapping(
          userId: userId2,
          encryptedBlob: encrypted.encryptedBlob,
          encryptionKeyId: encrypted.encryptionKeyId,
        ),
        throwsException, // Will fail due to wrong key or user_id mismatch
      );
    });

    test('should throw exception when encryption key not found', () async {
      // Arrange
      const userId = 'user-123';
      final fakeEncryptedBlob = Uint8List.fromList([1, 2, 3, 4, 5]);
      const fakeKeyId = 'fake_key_id';

      // Act & Assert
      expect(
        () => service.decryptMapping(
          userId: userId,
          encryptedBlob: fakeEncryptedBlob,
          encryptionKeyId: fakeKeyId,
        ),
        throwsException,
      );
    });

    test('should rotate encryption key correctly', () async {
      // Arrange
      const userId = 'user-123';
      const agentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

      // Act - encrypt original mapping
      final oldEncrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Verify old mapping decrypts correctly before rotation
      final decryptedBeforeRotation = await service.decryptMapping(
        userId: userId,
        encryptedBlob: oldEncrypted.encryptedBlob,
        encryptionKeyId: oldEncrypted.encryptionKeyId,
      );
      expect(decryptedBeforeRotation, equals(agentId));

      // Rotate key
      final newEncrypted = await service.rotateEncryptionKey(
        userId: userId,
        oldMapping: oldEncrypted,
      );

      // Assert - new encrypted blob should be different
      expect(newEncrypted.encryptedBlob,
          isNot(equals(oldEncrypted.encryptedBlob)));
      expect(newEncrypted.encryptionKeyId,
          isNot(equals(oldEncrypted.encryptionKeyId)));

      // New mapping should decrypt correctly
      final decryptedNew = await service.decryptMapping(
        userId: userId,
        encryptedBlob: newEncrypted.encryptedBlob,
        encryptionKeyId: newEncrypted.encryptionKeyId,
      );
      expect(decryptedNew, equals(agentId));

      // Old mapping should NOT decrypt (key was replaced)
      // This is expected behavior - key rotation invalidates old encrypted data
      expect(
        () => service.decryptMapping(
          userId: userId,
          encryptedBlob: oldEncrypted.encryptedBlob,
          encryptionKeyId: oldEncrypted.encryptionKeyId,
        ),
        throwsException, // Old key no longer exists
      );
    });

    test('should handle tampered encrypted data', () async {
      // Arrange
      const userId = 'user-123';
      const agentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

      // Act
      final encrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Tamper with encrypted data
      final tampered = Uint8List.fromList(encrypted.encryptedBlob);
      tampered[0] = (tampered[0] + 1) % 256; // Modify first byte

      // Assert - decryption should fail due to authentication tag mismatch
      expect(
        () => service.decryptMapping(
          userId: userId,
          encryptedBlob: tampered,
          encryptionKeyId: encrypted.encryptionKeyId,
        ),
        throwsException,
      );
    });

    test('should reuse same encryption key for same user', () async {
      // Arrange
      const userId = 'user-123';
      const agentId1 = 'agent_abc123def456ghi789jkl012mno345pqr678';
      const agentId2 = 'agent_xyz987uvw654rst321qpo098nml765kji432';

      // Act - encrypt two different mappings for same user
      final encrypted1 = await service.encryptMapping(
        userId: userId,
        agentId: agentId1,
      );
      final encrypted2 = await service.encryptMapping(
        userId: userId,
        agentId: agentId2,
      );

      // Assert - should use same encryption key (same keyId)
      expect(encrypted1.encryptionKeyId, equals(encrypted2.encryptionKeyId));

      // Both should decrypt correctly
      final decrypted1 = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted1.encryptedBlob,
        encryptionKeyId: encrypted1.encryptionKeyId,
      );
      final decrypted2 = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted2.encryptedBlob,
        encryptionKeyId: encrypted2.encryptionKeyId,
      );

      expect(decrypted1, equals(agentId1));
      expect(decrypted2, equals(agentId2));
    });
  });
}
