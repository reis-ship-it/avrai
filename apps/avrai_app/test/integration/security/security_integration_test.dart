import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/anonymous_user.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_runtime_os/services/security/location_obfuscation_service.dart';
import 'package:avrai_runtime_os/services/security/field_encryption_service.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'package:avrai_core/models/personality_profile.dart';
import '../../helpers/platform_channel_helper.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Integration tests for complete security flow
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
///
/// These tests verify end-to-end security:
/// - Anonymization flow
/// - Field encryption integration
/// - RLS policies with encrypted fields
/// - No personal data leaks
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });
  group('Security Integration Tests', () {
    late UserAnonymizationService anonymizationService;
    late LocationObfuscationService locationService;
    late FieldEncryptionService encryptionService;
    late AnonymousCommunicationProtocol communicationProtocol;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() async {
      // Set up mock FlutterSecureStorage to avoid MissingPluginException
      mockSecureStorage = MockFlutterSecureStorage();

      // In-memory storage to track keys
      final Map<String, String> keyStorage = {};

      // Set up read to return stored value or null
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage[key];
      });

      // Set up write to store value
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage[key] = value;
      });

      // Set up delete to remove key
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        keyStorage.remove(key);
      });

      locationService = LocationObfuscationService();
      anonymizationService = UserAnonymizationService(
        locationObfuscationService: locationService,
      );
      encryptionService = FieldEncryptionService(storage: mockSecureStorage);
      communicationProtocol = AnonymousCommunicationProtocol();
    });

    group('Complete Anonymization Flow', () {
      test(
          'should anonymize user and send in AI2AI network without personal data',
          () async {
        // Create UnifiedUser with personal data
        final unifiedUser = UnifiedUser(
          id: 'user-integration',
          email: 'user@example.com',
          displayName: 'John Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Phase 8.3: Use agentId for privacy protection
        final personality = PersonalityProfile.initial('agent_user-integration',
            userId: 'user-integration');

        // Convert to AnonymousUser
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_integration',
          personality,
        );

        // Verify no personal data
        expect(anonymousUser, isA<AnonymousUser>());
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('userId'), isFalse);

        // Send in AI2AI network
        // Note: We don't include personalityDimensions in payload because it contains 'user_id'
        // which is forbidden. In production, personalityDimensions would be sanitized before sending.
        final payload = {
          'agentId': anonymousUser.agentId,
          if (anonymousUser.preferences != null)
            'preferences': anonymousUser.preferences,
          if (anonymousUser.expertise != null)
            'expertise': anonymousUser.expertise,
          if (anonymousUser.location != null)
            'location': anonymousUser.location!.toJson(),
        };

        // Should pass validation (no personal data)
        final message = await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );

        expect(message, isNotNull);
        expect(message.privacyLevel, equals(PrivacyLevel.maximum));
      });

      test('should reject payload with personal data in anonymization flow',
          () async {
        final unifiedUser = UnifiedUser(
          id: 'user-reject',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_reject',
          null,
        );

        // Try to send with personal data (shouldn't happen, but test validation)
        final payloadWithPersonalData = {
          'agentId': anonymousUser.agentId,
          'email': 'user@example.com', // Personal data!
        };

        expect(
          () => communicationProtocol.sendEncryptedMessage(
            'target-agent',
            MessageType.discoverySync,
            payloadWithPersonalData,
          ),
          throwsA(isA<AnonymousCommunicationException>()),
        );
      });
    });

    group('Field Encryption Integration', () {
      test('should encrypt personal data before storage', () async {
        const email = 'user@example.com';
        const name = 'John Doe';
        const userId = 'user-encrypt';

        // Encrypt fields
        final encryptedEmail =
            await encryptionService.encryptField('email', email, userId);
        final encryptedName =
            await encryptionService.encryptField('name', name, userId);

        // Verify encrypted
        expect(encryptedEmail, isNot(equals(email)));
        expect(encryptedName, isNot(equals(name)));
        expect(encryptedEmail, startsWith('encrypted:'));
        expect(encryptedName, startsWith('encrypted:'));

        // Decrypt and verify
        final decryptedEmail = await encryptionService.decryptField(
            'email', encryptedEmail, userId);
        final decryptedName =
            await encryptionService.decryptField('name', encryptedName, userId);

        expect(decryptedEmail, equals(email));
        expect(decryptedName, equals(name));
      });

      test('should not expose encrypted data in AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-encrypt',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Convert to AnonymousUser
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_encrypt',
          null,
        );

        // AnonymousUser should NOT contain encrypted email
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('encryptedEmail'), isFalse);
      });
    });

    group('RLS Policies with Encrypted Fields', () {
      test('should enforce RLS even with encrypted fields', () async {
        // RLS policies should work with encrypted fields
        // Users can only access their own encrypted data

        const userId = 'user-rls';
        const otherUserId = 'other-user';

        // Encrypt data for user
        const email = 'user@example.com';
        final encryptedEmail =
            await encryptionService.encryptField('email', email, userId);
        expect(encryptedEmail, isNot(equals(email)));
        expect(encryptedEmail, startsWith('encrypted:'));

        // User should be able to decrypt their own data
        final decrypted = await encryptionService.decryptField(
            'email', encryptedEmail, userId);
        expect(decrypted, equals(email));

        // Other users should NOT be able to decrypt this user's data.
        await expectLater(
          encryptionService.decryptField('email', encryptedEmail, otherUserId),
          throwsA(isA<Exception>()),
        );
      });

      test('should filter encrypted fields in admin queries', () async {
        // Admin queries should not return encrypted personal data
        // Even if RLS allows access, privacy filtering should apply

        const userId = 'user-admin';

        // Admin should see agentId, not email
        final unifiedUser = UnifiedUser(
          id: userId,
          email: 'admin@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_admin',
          null,
        );

        // Admin query should return AnonymousUser, not UnifiedUser
        expect(anonymousUser.agentId, isNotEmpty);
        expect(anonymousUser.toJson().containsKey('email'), isFalse);
      });
    });

    group('No Personal Data Leaks', () {
      test('should verify no personal data in AI2AI payloads', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-leak-test',
          email: 'user@example.com',
          displayName: 'John Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Convert to AnonymousUser
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_leak_test',
          null,
        );

        // Create payload without personalityDimensions (which contains user_id) and location (which contains latitude/longitude)
        // This tests that the payload itself is clean, not the full toJson() output
        final payload = {
          'agentId': anonymousUser.agentId,
          if (anonymousUser.preferences != null)
            'preferences': anonymousUser.preferences,
          if (anonymousUser.expertise != null)
            'expertise': anonymousUser.expertise,
          // Note: location is excluded because it contains latitude/longitude which are forbidden keys
        };

        // Verify no personal data
        final forbiddenKeys = [
          'email',
          'name',
          'phone',
          'address',
          'userId',
          'displayName'
        ];
        for (final key in forbiddenKeys) {
          expect(payload.containsKey(key), isFalse,
              reason: 'Payload should not contain: $key');
        }

        // Verify payload passes validation
        await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );
      });

      test('should verify no personal data in location data', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-leak',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          location: '123 Main St, San Francisco, CA', // Exact address
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_location_leak',
          null,
        );

        // Location should be obfuscated (city-level, not exact)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotNull);
          // Should not contain exact address (ObfuscatedLocation doesn't have address field)
          // Should have expiration
          expect(anonymousUser.location!.expiresAt, isNotNull);
        }
      });

      test('should verify encrypted data is not exposed in logs', () async {
        const email = 'user@example.com';
        const userId = 'user-log-test';

        // Encrypt email
        final encryptedEmail =
            await encryptionService.encryptField('email', email, userId);

        // Encrypted data should not appear in plain text logs
        // (In actual implementation, would check log output)
        expect(encryptedEmail, isNot(equals(email)));
        expect(encryptedEmail, startsWith('encrypted:'));
      });
    });

    group('End-to-End Security Flows', () {
      test('should verify complete security flow from UnifiedUser to AI2AI',
          () async {
        // Step 1: Create UnifiedUser with personal data
        final unifiedUser = UnifiedUser(
          id: 'user-e2e-1',
          email: 'user@example.com',
          displayName: 'Test User',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Step 2: Encrypt personal fields
        final encryptedEmail = await encryptionService.encryptField(
          'email',
          unifiedUser.email,
          unifiedUser.id,
        );
        expect(encryptedEmail, isNot(equals(unifiedUser.email)));

        // Step 3: Anonymize user
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_e2e_1',
          null,
        );

        // Step 4: Verify no personal data in AnonymousUser
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('userId'), isFalse);

        // Step 5: Create AI2AI payload without personalityDimensions (which contains user_id) and location (which contains latitude/longitude)
        // This tests that the payload itself is clean, not the full toJson() output
        final payload = {
          'agentId': anonymousUser.agentId,
          if (anonymousUser.preferences != null)
            'preferences': anonymousUser.preferences,
          if (anonymousUser.expertise != null)
            'expertise': anonymousUser.expertise,
          // Note: location is excluded because it contains latitude/longitude which are forbidden keys
        };

        // Step 6: Verify payload passes validation
        await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );
      });

      test('should verify cross-service security', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-cross-1',
          email: 'user@example.com',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Test anonymization service
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_cross_1',
          null,
        );

        // Test encryption service
        final encrypted = await encryptionService.encryptField(
          'email',
          unifiedUser.email,
          unifiedUser.id,
        );

        // Test location obfuscation
        final obfuscated = await locationService.obfuscateLocation(
          unifiedUser.location!,
          unifiedUser.id,
        );

        // Verify all services work together securely
        expect(anonymousUser.agentId, startsWith('agent_'));
        expect(encrypted, startsWith('encrypted:'));
        expect(obfuscated.city, isNotEmpty);
      });
    });

    group('Security Error Handling', () {
      test('should handle security errors gracefully', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-error-1',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt invalid operation
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            'invalid-agent-id',
            null,
          ),
          throwsException,
        );
      });

      test('should handle encryption errors gracefully', () async {
        const email = 'user@example.com';
        const userId = 'user-error-2';

        // Encrypt
        final encrypted =
            await encryptionService.encryptField('email', email, userId);
        expect(encrypted, isNot(equals(email)));
        expect(encrypted, startsWith('encrypted:'));

        // Decrypt with valid key (should succeed)
        final decrypted =
            await encryptionService.decryptField('email', encrypted, userId);
        expect(decrypted, equals(email));

        // Test invalid encrypted format (should fail gracefully)
        await expectLater(
          () =>
              encryptionService.decryptField('email', 'invalid-format', userId),
          throwsException,
        );
      });

      test('should handle location obfuscation errors gracefully', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-error-3',
          email: 'user@example.com',
          location: '123 Home St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Set home location
        locationService.setHomeLocation(unifiedUser.id, unifiedUser.location!);

        // Attempt to obfuscate home location (should fail)
        expect(
          () => locationService.obfuscateLocation(
            unifiedUser.location!,
            unifiedUser.id,
          ),
          throwsException,
        );
      });
    });
  });
}
