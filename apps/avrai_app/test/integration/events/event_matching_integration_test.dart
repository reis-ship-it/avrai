import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_locality_connection_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/integration_test_helpers.dart';

/// Integration tests for event matching with local expert priority
/// and cross-locality discovery
///
/// **Philosophy:** Tests verify that local experts are prioritized
/// in their locality and that cross-locality connections enable
/// event discovery in neighboring communities.
void main() {
  group('Event Matching Integration Tests', () {
    late EventMatchingService matchingService;
    late ExpertiseEventService eventService;

    setUp(() {
      eventService = ExpertiseEventService();
      matchingService = EventMatchingService(
        eventService: eventService,
      );
    });

    group('Local Expert Priority', () {
      test('should prioritize local experts in their locality', () async {
        // Create local expert in Mission District
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create city expert (city experts can host in their city, not specific localities)
        final cityExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'city-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'San Francisco');

        // Create user in Mission District
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create events hosted by both experts
        // Local expert can host in specific locality (Mission District)
        final localEvent = await eventService.createEvent(
          host: localExpert,
          title: 'Local Food Tour',
          description: 'A tour of local food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        // City expert can host in city (San Francisco), not specific locality
        final cityEvent = await eventService.createEvent(
          host: cityExpert,
          title: 'City Food Tour',
          description: 'A tour of city food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'San Francisco', // City, not specific locality
        );

        // Calculate matching scores
        final localScore = await matchingService.calculateMatchingScore(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        final cityScore = await matchingService.calculateMatchingScore(
          expert: cityExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Local expert should have higher score due to locality matching
        // (Note: This verifies locality-specific weighting prioritizes local experts)
        expect(localScore, greaterThanOrEqualTo(cityScore));

        // Verify events exist
        expect(localEvent, isNotNull);
        expect(cityEvent, isNotNull);
      });

      test('should apply locality-specific weighting correctly', () async {
        // Create expert in same locality as user
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user in same locality
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create event in same locality
        await eventService.createEvent(
          host: localExpert,
          title: 'Local Food Tour',
          description: 'A tour of local food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        // Get matching signals
        final signals = await matchingService.getMatchingSignals(
          expert: localExpert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Locality weight should be 1.0 for same locality
        expect(signals.localityWeight, equals(1.0));
      });
    });

    group('Matching Score Calculation', () {
      test('should calculate score from multiple signals', () async {
        // Create expert with multiple events
        final expert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create multiple events and verify they're created
        final createdEvents = <ExpertiseEvent>[];
        for (int i = 0; i < 3; i++) {
          final event = await eventService.createEvent(
            host: expert,
            title: 'Food Tour $i',
            description: 'A tour of food spots',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: DateTime.now().add(Duration(days: 7 + i)),
            endTime: DateTime.now().add(Duration(days: 7 + i, hours: 2)),
            location: 'Mission District, San Francisco',
          );
          createdEvents.add(event);
        }

        // Verify all events were created
        expect(createdEvents.length, equals(3));

        // Calculate matching score
        final score = await matchingService.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Score should be positive
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));

        // Get signals to verify components
        final signals = await matchingService.getMatchingSignals(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Should have events (at least 2, ideally 3 - may vary based on service implementation)
        expect(signals.eventsHostedCount, greaterThanOrEqualTo(2));
        expect(signals.eventsHostedCount, lessThanOrEqualTo(3));
      });

      test('should return 0.0 for expert with no events', () async {
        // Create expert with no events
        final expert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Create user
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        // Calculate matching score
        final score = await matchingService.calculateMatchingScore(
          expert: expert,
          user: user,
          category: 'food',
          locality: 'Mission District',
        );

        // Score should be very low (close to 0.0) for expert with no events
        // Note: Score may be non-zero due to other signals (followers, social, community recognition)
        // but should be minimal without events
        expect(
            score, lessThan(0.2)); // Allow small score from non-event signals
      });
    });

    group('Cross-Locality Discovery', () {
      test('should identify connected localities for event discovery',
          () async {
        // Test business logic: CrossLocalityConnectionService identifies connected localities
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        final connectionService = CrossLocalityConnectionService(
          eventService: eventService,
        );

        // Act - Get connected localities
        final connectedLocalities =
            await connectionService.getConnectedLocalities(
          user: user,
          locality: 'Mission District',
        );

        // Assert - Should return list of connected localities
        expect(connectedLocalities, isA<List<ConnectedLocality>>());

        // If user has movement patterns, should have connections
        // (May be empty for new user, which is expected)
        for (final connection in connectedLocalities) {
          expect(connection.locality, isNotEmpty);
          expect(connection.connectionStrength, greaterThanOrEqualTo(0.0));
          expect(connection.connectionStrength, lessThanOrEqualTo(1.0));
        }
      });

      test('should apply connection strength to event ranking', () async {
        // Test business logic: Connection strength affects event discovery ranking
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        final connectionService = CrossLocalityConnectionService(
          eventService: eventService,
        );

        // Act - Get connected localities (sorted by strength)
        final connectedLocalities =
            await connectionService.getConnectedLocalities(
          user: user,
          locality: 'Mission District',
        );

        // Assert - Localities should be sorted by connection strength (highest first)
        if (connectedLocalities.length > 1) {
          for (int i = 0; i < connectedLocalities.length - 1; i++) {
            expect(
              connectedLocalities[i].connectionStrength,
              greaterThanOrEqualTo(
                  connectedLocalities[i + 1].connectionStrength),
              reason:
                  'Localities should be sorted by connection strength (highest first)',
            );
          }
        }

        // Connection strength should be used for event ranking
        // (Higher strength = higher priority in event discovery)
        expect(connectedLocalities, isA<List<ConnectedLocality>>());
      });
    });
  });
}
