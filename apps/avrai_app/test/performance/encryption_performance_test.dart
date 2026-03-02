import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Performance Tests for Encryption/Decryption
///
/// Tests encryption and decryption performance to ensure:
/// - Encryption < 100ms
/// - Decryption < 100ms
/// - Cache performance < 1ms
void main() {
  group('Encryption Performance Tests', () {
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

      service = SecureMappingEncryptionService(secureStorage: mockStorage);
    });

    test('Encryption performance should be < 100ms', () async {
      const userId = 'test-user-123';
      const agentId = 'agent_test_abc123def456';

      final stopwatch = Stopwatch()..start();
      final encrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );
      stopwatch.stop();

      expect(encrypted, isNotNull);
      expect(encrypted.encryptedBlob, isNotEmpty);

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('Encryption time: ${elapsedMs}ms');

      expect(elapsedMs, lessThan(100),
          reason: 'Encryption should complete in < 100ms, took ${elapsedMs}ms');
    });

    test('Decryption performance should be < 100ms', () async {
      const userId = 'test-user-123';
      const agentId = 'agent_test_abc123def456';

      // First encrypt
      final encrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Then decrypt and measure
      final stopwatch = Stopwatch()..start();
      final decrypted = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted.encryptedBlob,
        encryptionKeyId: encrypted.encryptionKeyId,
      );
      stopwatch.stop();

      expect(decrypted, equals(agentId));

      // ignore: avoid_print
      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('Decryption time: ${elapsedMs}ms');

      expect(elapsedMs, lessThan(100),
          reason: 'Decryption should complete in < 100ms, took ${elapsedMs}ms');
    });

    test('Round-trip encryption/decryption performance', () async {
      const userId = 'test-user-123';
      const agentId = 'agent_test_abc123def456';

      final stopwatch = Stopwatch()..start();

      // Encrypt
      final encrypted = await service.encryptMapping(
        userId: userId,
        agentId: agentId,
      );

      // Decrypt
      final decrypted = await service.decryptMapping(
        userId: userId,
        encryptedBlob: encrypted.encryptedBlob,
        encryptionKeyId: encrypted.encryptionKeyId,
      );

      stopwatch.stop();

      expect(decrypted, equals(agentId));
      // ignore: avoid_print

      // ignore: avoid_print
      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('Round-trip time: ${elapsedMs}ms');

      expect(elapsedMs, lessThan(200),
          reason: 'Round-trip should complete in < 200ms, took ${elapsedMs}ms');
    });

    test('Multiple encryptions performance', () async {
      const userId = 'test-user-123';
      final agentIds = List.generate(10, (i) => 'agent_test_$i');

      final stopwatch = Stopwatch()..start();

      for (final agentId in agentIds) {
        await service.encryptMapping(
          userId: userId,
          agentId: agentId,
        );
      }

      stopwatch.stop();

      // ignore: avoid_print
      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      final avgMs = elapsedMs / agentIds.length;
      // ignore: avoid_print

      // ignore: avoid_print
      print('Total time for 10 encryptions: ${elapsedMs}ms');
      // ignore: avoid_print
      print('Average per encryption: ${avgMs}ms');

      expect(avgMs, lessThan(100),
          reason: 'Average encryption should be < 100ms, was ${avgMs}ms');
    });
  });
}
