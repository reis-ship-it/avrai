import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:avrai_runtime_os/services/security/field_encryption_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Tests for FieldEncryptionService
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
///
/// These tests ensure personal data fields are encrypted at rest
/// using AES-256-GCM encryption
void main() {
  // Initialize Flutter binding for platform channel access
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldEncryptionService', () {
    late FieldEncryptionService service;
    late MockFlutterSecureStorage mockStorage;
    const userId = 'user-123';

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

      // Set up delete to remove key
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        keyStorage.remove(key);
      });

      service = FieldEncryptionService(storage: mockStorage);
    });

    // Removed: Property assignment tests
    // Encryption tests focus on business logic (encryption/decryption correctness, format handling), not property assignment

    group('Email Encryption/Decryption', () {
      test(
          'should encrypt and decrypt email addresses correctly, handle various formats, and produce decryptable values',
          () async {
        // Test business logic: email encryption/decryption with format handling
        const email = 'user@example.com';
        final encrypted = await service.encryptField('email', email, userId);
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(email)));
        expect(encrypted, startsWith('encrypted:'));

        final decrypted =
            await service.decryptField('email', encrypted, userId);
        expect(decrypted, equals(email));

        // Test various email formats
        final emailFormats = [
          'user@example.com',
          'user.name@example.co.uk',
          'user+tag@example.org',
          'user123@test-domain.com',
        ];
        for (final emailFormat in emailFormats) {
          final enc = await service.encryptField('email', emailFormat, userId);
          final dec = await service.decryptField('email', enc, userId);
          expect(dec, equals(emailFormat));
        }
      });
    });

    group('Name Encryption/Decryption', () {
      test(
          'should encrypt and decrypt names correctly, including unicode names',
          () async {
        // Test business logic: name encryption/decryption with unicode support
        const name = 'John Doe';
        final encrypted = await service.encryptField('name', name, userId);
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(name)));
        expect(encrypted, startsWith('encrypted:'));

        final decrypted = await service.decryptField('name', encrypted, userId);
        expect(decrypted, equals(name));

        // Test unicode names
        final unicodeNames = ['José García', '李小明', 'Иван Петров'];
        for (final unicodeName in unicodeNames) {
          final enc = await service.encryptField('name', unicodeName, userId);
          final dec = await service.decryptField('name', enc, userId);
          expect(dec, equals(unicodeName));
        }
      });
    });

    group('Location Encryption/Decryption', () {
      test('should encrypt and decrypt location strings correctly', () async {
        // Test business logic: location encryption/decryption
        const location = 'San Francisco, CA';
        final encrypted =
            await service.encryptField('location', location, userId);
        expect(encrypted, isNotEmpty);
        expect(encrypted, startsWith('encrypted:'));

        final decrypted =
            await service.decryptField('location', encrypted, userId);
        expect(decrypted, equals(location));
      });
    });

    group('Phone Encryption/Decryption', () {
      test(
          'should encrypt and decrypt phone numbers correctly, handle empty values, and support various formats',
          () async {
        // Test business logic: phone encryption/decryption with format and empty handling
        const phone = '+1-555-123-4567';
        final encrypted = await service.encryptField('phone', phone, userId);
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(phone)));
        expect(encrypted, startsWith('encrypted:'));

        final decrypted =
            await service.decryptField('phone', encrypted, userId);
        expect(decrypted, equals(phone));

        // Test empty phone (not encrypted)
        expect(await service.encryptField('phone', '', userId), equals(''));

        // Test various phone formats
        final phoneFormats = [
          '(555) 123-4567',
          '555-123-4567',
          '5551234567',
          '+1-555-123-4567',
          '+44 20 7946 0958',
        ];
        for (final phoneFormat in phoneFormats) {
          final enc = await service.encryptField('phone', phoneFormat, userId);
          final dec = await service.decryptField('phone', enc, userId);
          expect(dec, equals(phoneFormat));
        }
      });
    });

    group('Key Management', () {
      test(
          'should check if field should be encrypted and use different keys for different users and fields',
          () async {
        // Test business logic: field encryption eligibility and key isolation
        expect(service.shouldEncryptField('email'), isTrue);
        expect(service.shouldEncryptField('name'), isTrue);
        expect(service.shouldEncryptField('phone'), isTrue);
        expect(service.shouldEncryptField('location'), isTrue);
        expect(service.shouldEncryptField('address'), isTrue);
        expect(service.shouldEncryptField('safeField'), isFalse);

        // Test different keys for different users
        const email = 'user@example.com';
        final encrypted1 = await service.encryptField('email', email, 'user-1');
        final encrypted2 = await service.encryptField('email', email, 'user-2');
        expect(await service.decryptField('email', encrypted1, 'user-1'),
            equals(email));
        expect(await service.decryptField('email', encrypted2, 'user-2'),
            equals(email));

        // Test different keys for different fields
        const value = 'test';
        final field1Enc = await service.encryptField('email', value, userId);
        final field2Enc = await service.encryptField('name', value, userId);
        expect(await service.decryptField('email', field1Enc, userId),
            equals(value));
        expect(await service.decryptField('name', field2Enc, userId),
            equals(value));
      });
    });

    group('Key Rotation', () {
      test('should rotate encryption key and delete key correctly', () async {
        // Test business logic: key rotation and deletion
        const email = 'user@example.com';

        // Test key rotation
        final encryptedOld = await service.encryptField('email', email, userId);
        await service.rotateKey('email', userId);
        final encryptedNew = await service.encryptField('email', email, userId);
        expect(await service.decryptField('email', encryptedNew, userId),
            equals(email));
        // After rotation, old ciphertext should be unrecoverable with the new key.
        await expectLater(
          service.decryptField('email', encryptedOld, userId),
          throwsA(isA<Exception>()),
        );

        // Test key deletion
        final encrypted = await service.encryptField('email', email, userId);
        await service.deleteKey('email', userId);
        // Deleting a key should make prior ciphertext unrecoverable.
        await expectLater(
          service.decryptField('email', encrypted, userId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test(
          'should handle decryption errors, corrupted data, invalid formats, and empty input correctly',
          () async {
        // Test business logic: error handling for various invalid inputs
        expect(
          () => service.decryptField('email', 'encrypted:invalid_data', userId),
          throwsException,
        );

        expect(
          () => service.decryptField(
              'email', 'encrypted:corrupted_data_12345', userId),
          throwsException,
        );

        expect(
          () => service.decryptField('email', 'not_encrypted_data', userId),
          throwsException,
        );

        // Empty values are not encrypted
        expect(await service.encryptField('email', '', userId), equals(''));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
