import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/community/community_event_upgrade_service.dart';
import 'package:avrai_runtime_os/services/community/community_event_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/models/community/community_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Manual mocks for services
class MockCommunityEventService extends Mock implements CommunityEventService {}

class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Comprehensive tests for CommunityEventUpgradeService
/// Tests upgrade criteria evaluation, eligibility calculation, and upgrade flow
///
/// **Philosophy Alignment:**
/// - Opens doors for community events to upgrade to expert events
/// - Rewards successful community building
/// - Creates natural progression path
void main() {
  group('CommunityEventUpgradeService Tests', () {
    late CommunityEventUpgradeService service;
    late MockCommunityEventService mockCommunityEventService;
    late MockExpertiseEventService mockExpertiseEventService;
    late UnifiedUser host;
    late CommunityEvent event;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      mockCommunityEventService = MockCommunityEventService();
      mockExpertiseEventService = MockExpertiseEventService();

      // Register fallback values for mocktail
      registerFallbackValue(CommunityEvent(
        id: 'fallback',
        title: 'Fallback',
        description: 'Fallback',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: ModelFactories.createTestUser(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      service = CommunityEventUpgradeService(
        communityEventService: mockCommunityEventService,
        expertiseEventService: mockExpertiseEventService,
      );

      // Create host
      host = ModelFactories.createTestUser(
        id: 'host-1',
      ).copyWith();

      // Create test event
      event = CommunityEvent(
        id: 'event-1',
        title: 'Community Event',
        description: 'Test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() {
      reset(mockCommunityEventService);
      reset(mockExpertiseEventService);
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Community event upgrade tests focus on business logic (criteria evaluation, eligibility, upgrade flow), not property assignment

    group('Upgrade Criteria Evaluation', () {
      test(
          'should evaluate all upgrade criteria (frequency hosting, active returns, growth in size, diversity, high engagement, positive feedback, community building)',
          () async {
        // Test business logic: comprehensive criteria evaluation
        final eventWithTimesHosted = event.copyWith(timesHosted: 5);
        final criteria1 =
            await service.getUpgradeCriteria(eventWithTimesHosted);
        expect(criteria1, isNotEmpty);
        expect(criteria1.any((c) => c.contains('Frequency hosting')), isTrue);

        final eventWithReturns = event.copyWith(
          attendeeIds: ['user-1', 'user-2', 'user-3', 'user-1', 'user-2'],
          attendeeCount: 5,
          repeatAttendeesCount: 2,
        );
        final criteria2 = await service.getUpgradeCriteria(eventWithReturns);
        expect(criteria2.any((c) => c.contains('Active returns')), isTrue);

        final eventWithGrowth =
            event.copyWith(attendeeCount: 20, growthMetrics: 0.25);
        final criteria3 = await service.getUpgradeCriteria(eventWithGrowth);
        expect(criteria3.any((c) => c.contains('Growth in size')), isTrue);

        final eventWithDiversity = event.copyWith(diversityMetrics: 0.75);
        final criteria4 = await service.getUpgradeCriteria(eventWithDiversity);
        expect(criteria4.any((c) => c.contains('Diversity')), isTrue);

        final eventWithEngagement = event.copyWith(engagementScore: 0.85);
        final criteria5 = await service.getUpgradeCriteria(eventWithEngagement);
        expect(criteria5.any((c) => c.contains('High engagement')), isTrue);

        final eventWithFeedback = event.copyWith(averageRating: 4.5);
        final criteria6 = await service.getUpgradeCriteria(eventWithFeedback);
        expect(criteria6.any((c) => c.contains('Positive feedback')), isTrue);

        final eventWithCommunity = event.copyWith(
          attendeeCount: 30,
          engagementScore: 0.80,
          diversityMetrics: 0.70,
          communityBuildingIndicators: ['community_formed'],
        );
        final criteria7 = await service.getUpgradeCriteria(eventWithCommunity);
        expect(criteria7.any((c) => c.contains('Community building')), isTrue);
      });
    });

    group('Upgrade Eligibility Calculation', () {
      test(
          'should check eligibility, calculate upgrade score for eligible/ineligible/highly eligible events, and get which criteria are met',
          () async {
        // Test business logic: eligibility checking and score calculation
        final eligibleEvent = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          growthMetrics: 0.20,
          diversityMetrics: 0.70,
          timesHosted: 5,
        );
        final isEligible = await service.checkUpgradeEligibility(eligibleEvent);
        expect(isEligible, isTrue);

        final ineligibleEvent = event.copyWith(
          attendeeCount: 5,
          engagementScore: 0.30,
          growthMetrics: 0.0,
          diversityMetrics: 0.20,
          timesHosted: 1,
        );
        final isIneligible =
            await service.checkUpgradeEligibility(ineligibleEvent);
        expect(isIneligible, isFalse);

        final eventWithMetrics = event.copyWith(
          attendeeCount: 20,
          engagementScore: 0.75,
          growthMetrics: 0.15,
          diversityMetrics: 0.65,
          timesHosted: 4,
        );
        final score1 = await service.calculateUpgradeScore(eventWithMetrics);
        expect(score1, greaterThanOrEqualTo(0.0));
        expect(score1, lessThanOrEqualTo(1.0));

        final lowScoreEvent = event.copyWith(
            attendeeCount: 2, engagementScore: 0.10, timesHosted: 1);
        final score2 = await service.calculateUpgradeScore(lowScoreEvent);
        expect(score2, greaterThanOrEqualTo(0.0));
        expect(score2, lessThan(0.1));

        final highlyEligibleEvent = event.copyWith(
          attendeeCount: 50,
          engagementScore: 0.95,
          growthMetrics: 0.50,
          diversityMetrics: 0.90,
          averageRating: 4.9,
          timesHosted: 10,
        );
        final score3 = await service.calculateUpgradeScore(highlyEligibleEvent);
        expect(score3, greaterThanOrEqualTo(0.8));
        expect(score3, lessThanOrEqualTo(1.0));

        final criteria = await service.getUpgradeCriteria(eventWithMetrics);
        expect(criteria, isA<List<String>>());
        expect(criteria.length, greaterThan(0));
      });
    });

    group('Upgrade Flow', () {
      ExpertiseEvent createMockExpertiseEvent(
          CommunityEvent sourceEvent, UnifiedUser sourceHost) {
        return ExpertiseEvent(
          id: 'expert-event-1',
          title: sourceEvent.title,
          description: sourceEvent.description,
          category: sourceEvent.category,
          eventType: sourceEvent.eventType,
          host: sourceHost,
          startTime: sourceEvent.startTime,
          endTime: sourceEvent.endTime,
          createdAt: sourceEvent.createdAt,
          updatedAt: sourceEvent.updatedAt,
          attendeeCount: sourceEvent.attendeeCount,
        );
      }

      test(
          'should upgrade community event to local expert event, update event type, preserve event history and metrics, or throw error when event is not eligible',
          () async {
        // Test business logic: upgrade flow with validation and history preservation
        final eligibleEvent = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          isEligibleForUpgrade: true,
          upgradeEligibilityScore: 0.85,
          timesHosted: 5,
          growthMetrics: 0.25,
          diversityMetrics: 0.60,
          averageRating: 4.5,
        );
        final hostWithExpertise =
            host.copyWith(expertiseMap: {'Coffee': 'local'});

        when(() => mockCommunityEventService.cancelCommunityEvent(any()))
            .thenAnswer((invocation) async =>
                invocation.positionalArguments[0] as CommunityEvent);
        final mockExpertiseEvent =
            createMockExpertiseEvent(eligibleEvent, hostWithExpertise);
        when(() => mockExpertiseEventService.createEvent(
              host: hostWithExpertise,
              title: eligibleEvent.title,
              description: eligibleEvent.description,
              category: eligibleEvent.category,
              eventType: eligibleEvent.eventType,
              startTime: eligibleEvent.startTime,
              endTime: eligibleEvent.endTime,
              spots: eligibleEvent.spots,
              location: eligibleEvent.location,
              latitude: eligibleEvent.latitude,
              longitude: eligibleEvent.longitude,
              maxAttendees: eligibleEvent.maxAttendees,
              price: eligibleEvent.price,
              isPublic: eligibleEvent.isPublic,
            )).thenAnswer((_) async => mockExpertiseEvent);

        final upgradedEvent =
            await service.upgradeToLocalEvent(eligibleEvent, hostWithExpertise);
        expect(upgradedEvent, isA<ExpertiseEvent>());
        expect(upgradedEvent, isNot(isA<CommunityEvent>()));
        expect(upgradedEvent.title, equals(eligibleEvent.title));
        expect(upgradedEvent.category, equals(eligibleEvent.category));
        expect(
            upgradedEvent.attendeeCount, equals(eligibleEvent.attendeeCount));
        expect(upgradedEvent.createdAt, equals(eligibleEvent.createdAt));

        final ineligibleEvent = event.copyWith(
          isEligibleForUpgrade: false,
          upgradeEligibilityScore: 0.30,
          timesHosted: 1,
          engagementScore: 0.30,
        );
        expect(
          () => service.upgradeToLocalEvent(ineligibleEvent, hostWithExpertise),
          throwsA(isA<Exception>()),
        );
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
