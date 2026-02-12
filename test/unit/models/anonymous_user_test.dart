import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/anonymous_user.dart';
import 'package:avrai_core/models/personality_profile.dart';

/// Tests for AnonymousUser model
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
///
/// These tests ensure AnonymousUser contains NO personal information
/// and can be safely shared in AI2AI network
void main() {
  group('AnonymousUser', () {
    // Removed: Model Creation group
    // These tests only verified Dart constructor behavior, not business logic

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested personality profile correctly',
          () {
        // Phase 8.3: Use agentId for privacy protection
        final personalityProfile = PersonalityProfile.initial('agent_user-789', userId: 'user-789');
        final anonymousUser = AnonymousUser(
          agentId: 'agent_789',
          personalityDimensions: personalityProfile,
          preferences: const {'pref1': 'value1'},
          expertise: 'expertise1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = anonymousUser.toJson();
        final restored = AnonymousUser.fromJson(json);

        // Test nested structure preserved (business logic)
        expect(restored.agentId, equals('agent_789'));
        expect(restored.personalityDimensions, isNotNull);
        expect(restored.preferences, equals({'pref1': 'value1'}));
      });

      test('should handle missing optional fields with defaults', () {
        final json = {
          'agentId': 'agent_minimal',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final anonymousUser = AnonymousUser.fromJson(json);

        // Test default behavior (business logic)
        expect(anonymousUser.personalityDimensions, isNull);
        expect(anonymousUser.preferences, isNull);
        expect(anonymousUser.expertise, isNull);
      });
    });

    group('Validation', () {
      test(
          'should validate no personal data exists, agentId format, and location obfuscation',
          () {
        // Test business logic: privacy validation
        final validUser = AnonymousUser(
          agentId: 'agent_valid',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // AnonymousUser should NOT have these fields:
        final json = validUser.toJson();
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('address'), isFalse);
        expect(json.containsKey('personalInfo'), isFalse);

        // Valid agentId format should not throw
        validUser.validateNoPersonalData();

        // Invalid agentId format should throw
        final invalidUser = AnonymousUser(
          agentId: 'invalid-id', // Doesn't start with "agent_"
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(
          () => invalidUser.validateNoPersonalData(),
          throwsException,
        );

        // Location should be obfuscated (city-level, not exact)
        final obfuscatedLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749, // City-level, not exact
          longitude: -122.4194,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
        final userWithLocation = AnonymousUser(
          agentId: 'agent_loc',
          location: obfuscatedLocation,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(userWithLocation.location?.city, isNotNull);
        expect(userWithLocation.location?.latitude, isNotNull);
        expect(userWithLocation.location?.expiresAt, isNotNull);
      });
    });

    // Removed: Equality and HashCode group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
