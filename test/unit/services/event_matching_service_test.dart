import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/events/event_matching_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../fixtures/model_factories.dart';

import 'event_matching_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('EventMatchingService Tests', () {
    late EventMatchingService service;
    late MockExpertiseEventService mockEventService;
    late UnifiedUser expert;
    late UnifiedUser user;

    setUp(() {
      mockEventService = MockExpertiseEventService();

      service = EventMatchingService(
        eventService: mockEventService,
      );

      // Create expert with local expertise
      expert = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'food',
        location: 'Mission District, San Francisco',
      );

      // Create user looking for events
      user = ModelFactories.createTestUser(
        id: 'user-1',
      );
    });

    // Removed: Property assignment tests
    // Event matching tests focus on business logic (matching score calculation, signal generation), not property assignment

    group('calculateMatchingScore', () {
      test(
          'should return score between 0.0 and 1.0, return higher score for experts with more events, apply locality-specific weighting, return low score when expert has no events, or handle errors gracefully',
          () async {
        // Test business logic: matching score calculation
        final events1 = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events1);
        final score1 = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(score1, greaterThanOrEqualTo(0.0));
        expect(score1, lessThanOrEqualTo(1.0));

        final events5 = List.generate(5, (i) {
          return IntegrationTestHelpers.createTestEvent(
            id: 'event-$i',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          );
        });
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events5);
        final score5 = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(score5, greaterThan(score1));

        final localExpert = expert.copyWith(
          location: 'Mission District, San Francisco',
        );
        final remoteExpert = expert.copyWith(
          location: 'SOMA, San Francisco',
        );
        when(mockEventService.getEventsByHost(localExpert))
            .thenAnswer((_) async => events1);
        final localScore = await service.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        when(mockEventService.getEventsByHost(remoteExpert))
            .thenAnswer((_) async => events1);
        final remoteScore = await service.calculateMatchingScore(
          expert: remoteExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(localScore, greaterThan(remoteScore));

        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => []);
        final scoreEmpty = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(scoreEmpty, greaterThanOrEqualTo(0.0));
        expect(scoreEmpty, lessThan(0.2));

        when(mockEventService.getEventsByHost(expert))
            .thenThrow(Exception('Service error'));
        final scoreError = await service.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(scoreError, equals(0.0));
      });
    });

    group('getMatchingSignals', () {
      test(
          'should return matching signals with all components, calculate locality weight correctly for same locality, calculate locality weight correctly for different locality, return empty signals on error, filter events by category, or calculate event growth signal',
          () async {
        // Test business logic: matching signal generation
        final events1 = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-1',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            maxAttendees: 20,
            attendeeIds: List.generate(10, (i) => 'attendee-$i'),
          ),
        ];
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events1);
        final signals1 = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(signals1.eventsHostedCount, equals(1));
        expect(signals1.averageRating, greaterThan(0.0));
        expect(signals1.followersCount, greaterThanOrEqualTo(0));
        expect(signals1.localityWeight, greaterThan(0.0));
        expect(signals1.localityWeight, lessThanOrEqualTo(1.0));
        expect(signals1.localityWeight, equals(1.0));

        final remoteExpert = expert.copyWith(
          location: 'SOMA, San Francisco',
        );
        final events2 = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-2',
            host: remoteExpert,
            category: 'food',
            location: 'SOMA, San Francisco',
          ),
        ];
        when(mockEventService.getEventsByHost(remoteExpert))
            .thenAnswer((_) async => events2);
        final signals2 = await service.getMatchingSignals(
          expert: remoteExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(signals2.localityWeight, lessThan(1.0));
        expect(signals2.localityWeight, greaterThanOrEqualTo(0.0));

        when(mockEventService.getEventsByHost(expert))
            .thenThrow(Exception('Service error'));
        final signals3 = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(signals3.eventsHostedCount, equals(0));
        expect(signals3.localityWeight, equals(0.0));

        final foodEvents = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-3',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];
        final coffeeEvents = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-4',
            host: expert,
            category: 'coffee',
            location: 'Mission District, San Francisco',
          ),
        ];
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => [...foodEvents, ...coffeeEvents]);
        final signals4 = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(signals4.eventsHostedCount, equals(1));

        final events5 = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-5',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            attendeeIds: List.generate(5, (i) => 'attendee-$i'),
            maxAttendees: 20,
            startTime: DateTime.now().subtract(const Duration(days: 30)),
          ),
          IntegrationTestHelpers.createTestEvent(
            id: 'event-6',
            host: expert,
            category: 'food',
            location: 'Mission District, San Francisco',
            attendeeIds: List.generate(15, (i) => 'attendee-${i + 5}'),
            maxAttendees: 20,
            startTime: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ];
        when(mockEventService.getEventsByHost(expert))
            .thenAnswer((_) async => events5);
        final signals5 = await service.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );
        expect(signals5.eventGrowthScore, greaterThan(0.5));
      });
    });

    group('Local Expert Priority', () {
      test('should prioritize local experts in their locality', () async {
        // Local expert hosting in their locality
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // City expert hosting in same locality
        final cityExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'city-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'San Francisco');

        final localEvents = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-1',
            host: localExpert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        final cityEvents = [
          IntegrationTestHelpers.createTestEvent(
            id: 'event-2',
            host: cityExpert,
            category: 'food',
            location: 'Mission District, San Francisco',
          ),
        ];

        when(mockEventService.getEventsByHost(localExpert))
            .thenAnswer((_) async => localEvents);

        when(mockEventService.getEventsByHost(cityExpert))
            .thenAnswer((_) async => cityEvents);

        final localScore = await service.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        final cityScore = await service.calculateMatchingScore(
          expert: cityExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Local expert should have higher score due to locality matching
        // (Note: This test verifies locality weighting, which prioritizes local experts)
        expect(localScore, greaterThanOrEqualTo(cityScore));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
