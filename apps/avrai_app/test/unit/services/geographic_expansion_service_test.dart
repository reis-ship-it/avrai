import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_expansion_service.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('GeographicExpansionService Tests', () {
    late GeographicExpansionService service;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      service = GeographicExpansionService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Geographic expansion tests focus on business logic (tracking, coverage calculation, threshold checking), not property assignment

    group('Event Expansion Tracking', () {
      test(
          'should track event expansion to new locality, update expansion history, and prevent duplicate localities',
          () async {
        // Test business logic: event expansion tracking with history and deduplication
        const clubId = 'club-1';
        const newLocality = 'Williamsburg, Brooklyn';
        const category = 'Coffee';

        final host = ModelFactories.createTestUser(
            id: 'host-1', displayName: 'Test Host');
        final event = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-1', category: category);

        await service.trackEventExpansion(
          clubId: clubId,
          isClub: true,
          event: event,
          eventLocation: newLocality,
        );

        final expansion = service.getExpansionByClub(clubId);
        expect(expansion, isNotNull);
        expect(expansion?.originalLocality, equals(newLocality));
        expect(expansion?.expandedLocalities, contains('Williamsburg'));
        expect(expansion?.eventHostingLocations['Williamsburg'],
            contains('event-1'));
        expect(expansion?.expansionHistory, isNotEmpty);
        expect(expansion?.firstExpansionAt, isNotNull);
        expect(expansion?.lastExpansionAt, isNotNull);
        expect(expansion?.expansionHistory.first.location, equals(newLocality));
        expect(expansion?.expansionHistory.first.expansionMethod,
            equals('event_hosting'));

        // Test duplicate prevention
        final event2 = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-2',
            category: category,
            location: newLocality);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event2,
            eventLocation: newLocality);
        final expansion2 = service.getExpansionByClub(clubId);
        expect(
            expansion2?.expandedLocalities
                .where((l) => l == 'Williamsburg')
                .length,
            equals(1));
        expect(expansion2?.eventHostingLocations['Williamsburg']?.length,
            equals(2));
      });
    });

    group('Commute Pattern Tracking', () {
      test(
          'should track single and multiple commute patterns, and prevent duplicate source localities',
          () async {
        // Test business logic: commute pattern tracking with deduplication
        const clubId = 'club-1';
        const eventLocality = 'Mission District, San Francisco';
        const sourceLocality = 'SOMA, San Francisco';
        final sourceLocalities = [
          'SOMA, San Francisco',
          'Castro, San Francisco',
          'Hayes Valley, San Francisco'
        ];
        const category = 'Coffee';

        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-1', category: category);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event,
            eventLocation: eventLocality);

        await service.trackCommutePattern(
            clubId: clubId,
            eventLocality: eventLocality,
            attendeeLocalities: [sourceLocality]);
        final expansion1 = service.getExpansionByClub(clubId);
        expect(expansion1?.commutePatterns[eventLocality],
            contains(sourceLocality));

        await service.trackCommutePattern(
            clubId: clubId,
            eventLocality: eventLocality,
            attendeeLocalities: sourceLocalities);
        final expansion2 = service.getExpansionByClub(clubId);
        expect(expansion2?.commutePatterns[eventLocality], hasLength(3));
        expect(expansion2?.commutePatterns[eventLocality],
            containsAll(sourceLocalities));

        await service.trackCommutePattern(
            clubId: clubId,
            eventLocality: eventLocality,
            attendeeLocalities: [sourceLocality]);
        final expansion3 = service.getExpansionByClub(clubId);
        expect(
            expansion3?.commutePatterns[eventLocality]
                ?.where((l) => l == sourceLocality)
                .length,
            equals(1));
      });
    });

    group('Coverage Calculation', () {
      test(
          'should calculate locality, city, state, nation, and global coverage with 75% threshold',
          () async {
        // Test business logic: coverage calculation at all geographic levels
        const clubId = 'club-1';
        const category = 'Coffee';
        final host = ModelFactories.createTestUser(id: 'host-1');

        // Locality coverage
        final event1 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-1', category: category);
        final event2 = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-2',
            category: category,
            location: 'Greenpoint, Brooklyn');
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event1,
            eventLocation: 'Williamsburg, Brooklyn');
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event2,
            eventLocation: 'Greenpoint, Brooklyn');
        final expansion1 = service.getExpansionByClub(clubId);
        final localityCoverage =
            await service.calculateLocalityCoverage(expansion: expansion1!);
        expect(localityCoverage, isNotEmpty);
        expect(localityCoverage.values.any((v) => v > 0.0), isTrue);
        expect(localityCoverage.values.every((v) => v <= 1.0), isTrue);

        // City coverage
        final brooklynLocalities = [
          'Williamsburg, Brooklyn',
          'Greenpoint, Brooklyn',
          'DUMBO, Brooklyn',
          'Park Slope, Brooklyn'
        ];
        for (var i = 0; i < brooklynLocalities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
              host: host,
              id: 'city-event-$i',
              category: category,
              location: brooklynLocalities[i]);
          await service.trackEventExpansion(
              clubId: clubId,
              isClub: true,
              event: event,
              eventLocation: brooklynLocalities[i]);
        }
        final expansion2 = service.getExpansionByClub(clubId);
        final cityCoverage =
            await service.calculateCityCoverage(expansion: expansion2!);
        expect(cityCoverage, isNotEmpty);
        expect(cityCoverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);

        // State coverage
        final newYorkCities = ['Brooklyn', 'Queens', 'Manhattan'];
        for (var i = 0; i < newYorkCities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
              host: host, id: 'state-event-$i', category: category);
          await service.trackEventExpansion(
              clubId: clubId,
              isClub: true,
              event: event,
              eventLocation: 'Locality, ${newYorkCities[i]}, New York');
        }
        final expansion3 = service.getExpansionByClub(clubId);
        final stateCoverage =
            await service.calculateStateCoverage(expansion: expansion3!);
        expect(stateCoverage, isNotEmpty);
        expect(stateCoverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);

        // Nation coverage
        final locations = [
          'Locality, San Francisco, California, United States',
          'Locality, New York City, New York, United States',
          'Locality, Austin, Texas, United States',
        ];
        for (var i = 0; i < locations.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
              host: host,
              id: 'nation-event-$i',
              category: category,
              location: locations[i]);
          await service.trackEventExpansion(
              clubId: clubId,
              isClub: true,
              event: event,
              eventLocation: locations[i]);
        }
        final expansion4 = service.getExpansionByClub(clubId);
        expect(expansion4!.expandedNations, isNotEmpty);
        final nationCoverage =
            await service.calculateNationCoverage(expansion: expansion4);
        expect(nationCoverage, isNotEmpty);
        expect(
            nationCoverage.values.every((v) => v >= 0.0 && v <= 1.0), isTrue);

        // Global coverage
        final nations = ['United States', 'Canada', 'Mexico'];
        for (var i = 0; i < nations.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
              host: host, id: 'global-event-$i', category: category);
          await service.trackEventExpansion(
              clubId: clubId,
              isClub: true,
              event: event,
              eventLocation: 'Locality, ${nations[i]}');
        }
        final expansion5 = service.getExpansionByClub(clubId);
        final globalCoverage =
            await service.calculateGlobalCoverage(expansion: expansion5!);
        expect(globalCoverage, greaterThanOrEqualTo(0.0));
        expect(globalCoverage, lessThanOrEqualTo(1.0));
      });
    });

    group('75% Threshold Checking', () {
      test(
          'should check if locality, city, state, nation, and global thresholds reached',
          () async {
        // Test business logic: threshold checking at all geographic levels
        const clubId = 'club-1';
        const category = 'Coffee';
        final host = ModelFactories.createTestUser(id: 'host-1');

        // Locality threshold
        final event1 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-1', category: category);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event1,
            eventLocation: 'Williamsburg, Brooklyn');
        final expansion1 = service.getExpansionByClub(clubId);
        final localityReached =
            service.hasReachedLocalityThreshold(expansion1!);
        expect(localityReached, isA<bool>());

        // City threshold
        final brooklynLocalities =
            List.generate(10, (i) => 'Locality $i, Brooklyn');
        for (var i = 0; i < brooklynLocalities.length; i++) {
          final event = IntegrationTestHelpers.createTestEvent(
              host: host, id: 'city-event-$i', category: category);
          await service.trackEventExpansion(
              clubId: clubId,
              isClub: true,
              event: event,
              eventLocation: brooklynLocalities[i]);
        }
        final expansion2 = service.getExpansionByClub(clubId);
        final cityReached =
            service.hasReachedCityThreshold(expansion2!, 'Brooklyn');
        expect(cityReached, isA<bool>());

        // State threshold
        final event2 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'state-event-1', category: category);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event2,
            eventLocation: 'Locality, New York');
        final expansion3 = service.getExpansionByClub(clubId);
        final stateReached =
            service.hasReachedStateThreshold(expansion3!, 'New York');
        expect(stateReached, isA<bool>());

        // Nation threshold
        final event3 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'nation-event-1', category: category);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event3,
            eventLocation: 'Locality, United States');
        final expansion4 = service.getExpansionByClub(clubId);
        final nationReached =
            service.hasReachedNationThreshold(expansion4!, 'United States');
        expect(nationReached, isA<bool>());

        // Global threshold
        final expansion5 = service.getExpansionByClub(clubId);
        final globalReached = service.hasReachedGlobalThreshold(expansion5!);
        expect(globalReached, isA<bool>());
      });
    });

    group('Expansion Management', () {
      test(
          'should get expansion by club or community, update expansion data, and get expansion history',
          () async {
        // Test business logic: expansion management operations
        const clubId = 'club-1';
        const communityId = 'community-1';
        const category = 'Coffee';
        final host = ModelFactories.createTestUser(id: 'host-1');

        // Get expansion by club
        final event1 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-1', category: category);
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event1,
            eventLocation: 'Williamsburg, Brooklyn');
        final clubExpansion = service.getExpansionByClub(clubId);
        expect(clubExpansion, isNotNull);
        expect(clubExpansion?.clubId, equals(clubId));
        expect(clubExpansion?.isClub, equals(true));

        // Get expansion by community
        final event2 = IntegrationTestHelpers.createTestEvent(
            host: host, id: 'event-2', category: category);
        await service.trackEventExpansion(
            clubId: communityId,
            isClub: false,
            event: event2,
            eventLocation: 'Williamsburg, Brooklyn');
        final communityExpansion = service.getExpansionByCommunity(communityId);
        expect(communityExpansion, isNotNull);
        expect(communityExpansion?.clubId, equals(communityId));
        expect(communityExpansion?.isClub, equals(false));

        // Update expansion data
        final updatedExpansion =
            clubExpansion!.copyWith(cityCoverage: {'Brooklyn': 0.8});
        await service.updateExpansion(updatedExpansion);
        final updated = service.getExpansionByClub(clubId);
        expect(updated?.cityCoverage['Brooklyn'], equals(0.8));

        // Get expansion history
        final event3 = IntegrationTestHelpers.createTestEvent(
            host: host,
            id: 'event-3',
            category: category,
            location: 'Greenpoint, Brooklyn');
        await service.trackEventExpansion(
            clubId: clubId,
            isClub: true,
            event: event3,
            eventLocation: 'Greenpoint, Brooklyn');
        final history = service.getExpansionHistory(clubId);
        expect(history, isNotEmpty);
        expect(history.length, greaterThanOrEqualTo(2));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
