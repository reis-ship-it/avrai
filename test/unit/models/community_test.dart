import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/community/community_event.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Community Model
/// Tests community creation, event linking, member tracking, growth metrics
///
/// **Philosophy Alignment:**
/// - Events naturally create communities (people who attend together)
/// - Communities are doors to finding your people
/// - Communities track growth and engagement organically
void main() {
  group('Community Model Tests', () {
    late UnifiedUser founder;
    late CommunityEvent originatingEvent;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();

      // Create founder (event host)
      founder = ModelFactories.createTestUser(
        id: 'founder-1',
      );

      // Create originating event
      originatingEvent = CommunityEvent(
        id: 'event-1',
        title: 'Coffee Meetup',
        description: 'Weekly coffee meetup',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: founder,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        attendeeIds: const ['user-1', 'user-2', 'user-3'],
        attendeeCount: 3,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Model Creation group
    // These tests only verified Dart constructor behavior, not business logic

    // Removed: Event Linking group
    // These tests only verified property assignment, not business logic

    // Removed: Member Tracking group
    // These tests only verified list/count storage, not business logic

    // Removed: Event Tracking group
    // These tests only verified list/count storage, not business logic

    // Removed: Growth Metrics group
    // These tests only verified property assignment, not business logic

    // Removed: Geographic Tracking group
    // These tests only verified list/string storage, not business logic

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle missing optional fields',
          () {
        // Test business logic: JSON round-trip with default handling
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          description: 'A community for coffee lovers',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: const ['user-1', 'user-2'],
          memberCount: 2,
          engagementScore: 0.75,
          activityLevel: ActivityLevel.active,
        );

        final json = community.toJson();
        final restored = Community.fromJson(json);

        expect(restored.originatingEventType,
            equals(OriginatingEventType.communityEvent));
        expect(restored.activityLevel, equals(ActivityLevel.active));
        expect(restored.engagementScore, equals(0.75));

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'community-1',
          'name': 'Test Community',
          'category': 'Coffee',
          'originatingEventId': originatingEvent.id,
          'originatingEventType': 'communityEvent',
          'founderId': founder.id,
          'originalLocality': 'Mission District, San Francisco',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };
        final fromMinimal = Community.fromJson(minimalJson);

        expect(fromMinimal.memberCount, equals(0));
        expect(
            fromMinimal.activityLevel, equals(ActivityLevel.active)); // Default
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          engagementScore: 0.85,
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('Updated Name')));
        expect(updated.name, equals('Updated Name'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });
  });
}
