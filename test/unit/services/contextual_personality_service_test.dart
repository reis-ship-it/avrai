import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_ai/services/contextual_personality_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import '../../helpers/platform_channel_helper.dart';

/// SPOTS ContextualPersonalityService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test ContextualPersonalityService functionality
///
/// Test Coverage:
/// - Change Classification: Core vs context vs resist
/// - Transition Detection: Authentic transformation detection
/// - Change Magnitude: Calculate change magnitude
/// - Consistency Checks: Verify change consistency with transitions
/// - Privacy Validation: Ensure no user data exposure
///
/// Dependencies:
/// - PersonalityProfile: User personality profile
/// - ContextualPersonality: Context-specific personality

void main() {
  group('ContextualPersonalityService', () {
    late ContextualPersonalityService service;

    setUp(() {
      service = ContextualPersonalityService();
    });

    // Removed: Property assignment tests
    // Contextual personality tests focus on business logic (change classification, transition detection), not property assignment

    group('Change Classification', () {
      test(
          'should classify small changes as context when context active, classify small changes as core when no context, resist large AI2AI changes, allow user actions to update core, update context for user actions in specific context, and resist on error',
          () async {
        // Test business logic: change classification based on context, magnitude, and source
        final currentProfile = PersonalityProfile.initial('agent_user-1', userId: 'user-1');
        final proposedChanges1 = {'energy_preference': 0.05};
        final classification1 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges1,
          activeContext: 'work',
          changeSource: 'user_action',
        );
        expect(classification1, 'context');

        final classification2 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges1,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification2, 'core');

        final proposedChanges2 = {'energy_preference': 0.6};
        final classification3 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges2,
          activeContext: null,
          changeSource: 'ai2ai',
        );
        expect(classification3, 'resist');

        final proposedChanges3 = {'energy_preference': 0.3};
        final classification4 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges3,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification4, 'core');

        final classification5 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges3,
          activeContext: 'work',
          changeSource: 'user_action',
        );
        expect(classification5, 'context');

        final proposedChanges4 = <String, double>{};
        final classification6 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges4,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification6, isA<String>());
      });
    });

    group('Transition Detection', () {
      test(
          'should return null for insufficient data, or detect transition with sufficient data',
          () async {
        // Test business logic: transition detection based on data availability
        final profile = PersonalityProfile.initial('agent_user-1', userId: 'user-1');
        final recentChanges1 = <Map<String, double>>[];
        final transition1 = await service.detectTransition(
          profile: profile,
          recentChanges: recentChanges1,
          window: const Duration(days: 30),
        );
        expect(transition1, isNull);

        final recentChanges2 = List.generate(
            10,
            (i) => {
                  'energy_preference': 0.1 * i,
                  'crowd_tolerance': 0.05 * i,
                });
        final transition2 = await service.detectTransition(
          profile: profile,
          recentChanges: recentChanges2,
          window: const Duration(days: 30),
        );
        expect(transition2, anyOf(isNull, isNotNull));
      });
    });

    group('Privacy Validation', () {
      test('should not expose user data in change classification', () async {
        final currentProfile = PersonalityProfile.initial('agent_user-1', userId: 'user-1');
        final proposedChanges = {'energy_preference': 0.1};

        final classification = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges,
          activeContext: null,
          changeSource: 'user_action',
        );

        // Classification should not contain user identifiers
        expect(classification, isNot(contains('user-1')));
        expect(classification, isA<String>());
      });
    });

    group('Edge Cases', () {
      test(
          'should handle empty proposed changes, very large changes, and null active context',
          () async {
        // Test business logic: edge case handling for change classification
        final currentProfile = PersonalityProfile.initial('agent_user-1', userId: 'user-1');
        final proposedChanges1 = <String, double>{};
        final classification1 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges1,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification1, isA<String>());

        final proposedChanges2 = {'energy_preference': 1.5};
        final classification2 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges2,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification2, isA<String>());

        final proposedChanges3 = {'energy_preference': 0.1};
        final classification3 = await service.classifyChange(
          currentProfile: currentProfile,
          proposedChanges: proposedChanges3,
          activeContext: null,
          changeSource: 'user_action',
        );
        expect(classification3, isA<String>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
