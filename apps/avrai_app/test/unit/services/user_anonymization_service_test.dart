import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });
  group('UserAnonymizationService', () {
    late UserAnonymizationService service;

    setUp(() {
      service = UserAnonymizationService();
    });

    test('should create AnonymousUser from UnifiedUser', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'John Doe',
        location: 'Austin, TX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Phase 8.3: Use agentId for privacy protection
      final personality =
          PersonalityProfile.initial('agent_123', userId: 'user_123');

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent_123',
        personality,
      );

      expect(anonymousUser.agentId, 'agent_123');
      expect(anonymousUser.personalityDimensions, personality);
      // Should not contain personal data
      expect(anonymousUser.toJson().containsKey('email'), false);
      expect(anonymousUser.toJson().containsKey('name'), false);
      expect(anonymousUser.toJson().containsKey('userId'), false);
    });

    test('should throw if agentId is invalid', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => service.anonymizeUser(user, 'invalid-id', null),
        throwsException,
      );
    });

    test('should validate AnonymousUser has no personal data', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent_123',
        null,
      );

      // Should not throw
      anonymousUser.validateNoPersonalData();
    });

    test('should handle location obfuscation', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        location: 'Austin, TX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent_123',
        null,
      );

      // Location should be obfuscated (city-level only)
      expect(anonymousUser.location, isNotNull);
      expect(anonymousUser.location!.city, isNotEmpty);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
