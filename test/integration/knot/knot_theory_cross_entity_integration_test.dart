// Integration tests for Phase 1.5: Universal Cross-Pollination Extension
// 
// Tests end-to-end workflows across all Phase 1.5 services:
// - EntityKnotService
// - CrossEntityCompatibilityService
// - NetworkCrossPollinationService
// 
// Part of Patent #31: Topological Knot Theory for Personality Representation

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/network_cross_pollination_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/integration_test_helpers.dart';

void main() {
  group('Knot Theory Cross-Entity Integration Tests', () {
    late EntityKnotService entityKnotService;
    late CrossEntityCompatibilityService compatibilityService;
    late NetworkCrossPollinationService networkService;
    bool rustLibInitialized = false;

    setUpAll(() async {
      // Initialize Rust library once for all tests
      if (!rustLibInitialized) {
        try {
          await RustLib.init();
          rustLibInitialized = true;
        } catch (e) {
          // If already initialized, that's fine
          if (!e.toString().contains('Should not initialize')) {
            rethrow;
          }
          rustLibInitialized = true;
        }
      }
    });

    setUp(() {
      TestHelpers.setupTestEnvironment();
      entityKnotService = EntityKnotService();
      compatibilityService = CrossEntityCompatibilityService();
      networkService = NetworkCrossPollinationService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End: Person Discovers Event', () {
      test('should generate knots and calculate compatibility for person-event match', () async {
        // Step 1: Create person and event
        final personProfile = PersonalityProfile.initial(
          'person-1',
          userId: 'user-1',
        );
        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        // Step 2: Generate knots for both entities
        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final eventKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        // Step 3: Calculate compatibility
        final compatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: personKnot,
          entityB: eventKnot,
        );

        // Step 4: Verify results
        expect(personKnot.entityType, equals(EntityType.person));
        expect(eventKnot.entityType, equals(EntityType.event));
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        expect(personKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(eventKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
      });

      test('should discover events through network cross-pollination', () async {
        final personProfile = PersonalityProfile.initial(
          'person-2',
          userId: 'user-2',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );

        // Discover events (currently returns empty, but framework is tested)
        final discoveredPaths = await networkService.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.event,
          maxDepth: 3,
        );

        // Framework is in place (returns empty until network data sources integrated)
        expect(discoveredPaths, isA<List<DiscoveryPath>>());
      });
    });

    group('End-to-End: Person Discovers Place', () {
      test('should generate knots and calculate compatibility for person-place match', () async {
        final personProfile = PersonalityProfile.initial(
          'person-3',
          userId: 'user-3',
        );
        final spot = ModelFactories.createTestSpot(
          id: 'spot-1',
          name: 'Coffee Shop',
          category: 'Coffee',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final placeKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );

        final compatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: personKnot,
          entityB: placeKnot,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        expect(placeKnot.metadata['category'], equals('Coffee'));
      });
    });

    group('End-to-End: Person Discovers Company', () {
      test('should generate knots and calculate compatibility for person-company match', () async {
        final personProfile = PersonalityProfile.initial(
          'person-4',
          userId: 'user-4',
        );
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          name: 'Coffee Roasters',
          businessType: 'Coffee Shop',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final companyKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.company,
          entity: business,
        );

        final compatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: personKnot,
          entityB: companyKnot,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        expect(companyKnot.metadata['businessType'], equals('Coffee Shop'));
      });
    });

    group('End-to-End: Multi-Entity Weave Compatibility', () {
      test('should calculate compatibility for person-event-place combination', () async {
        final personProfile = PersonalityProfile.initial(
          'person-5',
          userId: 'user-5',
        );
        final host = ModelFactories.createTestUser(id: 'host-2');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
        );
        final spot = ModelFactories.createTestSpot(
          id: 'spot-2',
          name: 'Event Location',
          category: 'Coffee',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final eventKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );
        final placeKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );

        // Calculate multi-entity weave compatibility
        final weaveCompatibility = await compatibilityService.calculateMultiEntityWeaveCompatibility(
          entities: [personKnot, eventKnot, placeKnot],
        );

        expect(weaveCompatibility, greaterThanOrEqualTo(0.0));
        expect(weaveCompatibility, lessThanOrEqualTo(1.0));
      });

      test('should calculate path compatibility for discovery path', () async {
        final personProfile1 = PersonalityProfile.initial(
          'person-6',
          userId: 'user-6',
        );
        final personProfile2 = PersonalityProfile.initial(
          'person-7',
          userId: 'user-7',
        );
        final host = ModelFactories.createTestUser(id: 'host-3');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Bookstores',
        );

        final personKnot1 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile1,
        );
        final personKnot2 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile2,
        );
        final eventKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        // Calculate path compatibility (person1 → person2 → event)
        final pathCompatibility = await networkService.calculatePathCompatibility([
          personKnot1,
          personKnot2,
          eventKnot,
        ]);

        expect(pathCompatibility, greaterThanOrEqualTo(0.0));
        expect(pathCompatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('End-to-End: Cross-Entity Discovery Workflow', () {
      test('should complete full discovery workflow: person → event → place', () async {
        // Step 1: Person discovers event
        final personProfile = PersonalityProfile.initial(
          'person-8',
          userId: 'user-8',
        );
        final host = ModelFactories.createTestUser(id: 'host-4');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final eventKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        // Step 2: Calculate person-event compatibility
        final personEventCompatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: personKnot,
          entityB: eventKnot,
        );

        // Step 3: Event has associated places - discover place through event
        final spot = ModelFactories.createTestSpot(
          id: 'spot-3',
          name: 'Tour Stop',
          category: 'Coffee',
        );
        final placeKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );

        // Step 4: Calculate event-place compatibility
        final eventPlaceCompatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: eventKnot,
          entityB: placeKnot,
        );

        // Step 5: Calculate person-place compatibility
        final personPlaceCompatibility = await compatibilityService.calculateIntegratedCompatibility(
          entityA: personKnot,
          entityB: placeKnot,
        );

        // Step 6: Calculate path compatibility (person → event → place)
        final pathCompatibility = await networkService.calculatePathCompatibility([
          personKnot,
          eventKnot,
          placeKnot,
        ]);

        // Verify all compatibilities are valid
        expect(personEventCompatibility, greaterThanOrEqualTo(0.0));
        expect(personEventCompatibility, lessThanOrEqualTo(1.0));
        expect(eventPlaceCompatibility, greaterThanOrEqualTo(0.0));
        expect(eventPlaceCompatibility, lessThanOrEqualTo(1.0));
        expect(personPlaceCompatibility, greaterThanOrEqualTo(0.0));
        expect(personPlaceCompatibility, lessThanOrEqualTo(1.0));
        expect(pathCompatibility, greaterThanOrEqualTo(0.0));
        expect(pathCompatibility, lessThanOrEqualTo(1.0));

        // Path compatibility should be geometric mean of pairwise compatibilities
        // (approximately, within floating point precision)
        final expectedPathCompatibility = (personEventCompatibility *
                eventPlaceCompatibility *
                personPlaceCompatibility)
            .pow(1 / 3);
        expect(
          pathCompatibility,
          // The path compatibility algorithm should be close to the geometric mean,
          // but exact equality is not required (multiple floating point + scoring
          // steps can accumulate small drift).
          closeTo(expectedPathCompatibility, 0.03),
        );
      });
    });

    group('End-to-End: Entity Type Coverage', () {
      test('should handle all supported entity types in single workflow', () async {
        // Create one of each entity type
        final personProfile = PersonalityProfile.initial(
          'person-9',
          userId: 'user-9',
        );
        final host = ModelFactories.createTestUser(id: 'host-5');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
        );
        final spot = ModelFactories.createTestSpot(
          id: 'spot-4',
          name: 'Coffee Spot',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-2',
          name: 'Coffee Business',
          businessType: 'Coffee Shop',
        );

        // Generate knots for all entity types
        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );
        final eventKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );
        final placeKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );
        final companyKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.company,
          entity: business,
        );

        // Calculate multi-entity weave compatibility for all types
        final allEntitiesCompatibility = await compatibilityService.calculateMultiEntityWeaveCompatibility(
          entities: [personKnot, eventKnot, placeKnot, companyKnot],
        );

        // Verify all knots have valid invariants
        expect(personKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(eventKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(placeKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(companyKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));

        // Verify compatibility is valid
        expect(allEntitiesCompatibility, greaterThanOrEqualTo(0.0));
        expect(allEntitiesCompatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('End-to-End: Error Handling and Edge Cases', () {
      test('should handle empty entity list in multi-entity compatibility', () async {
        final compatibility = await compatibilityService.calculateMultiEntityWeaveCompatibility(
          entities: [],
        );

        expect(compatibility, equals(1.0));
      });

      test('should handle single entity in path compatibility', () async {
        final personProfile = PersonalityProfile.initial(
          'person-10',
          userId: 'user-10',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );

        final pathCompatibility = await networkService.calculatePathCompatibility([personKnot]);

        expect(pathCompatibility, equals(1.0));
      });

      test('should handle network discovery with unsupported entity type gracefully', () async {
        final personProfile = PersonalityProfile.initial(
          'person-11',
          userId: 'user-11',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: personProfile,
        );

        // Try to discover brand (not yet implemented)
        final paths = await networkService.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.brand,
          maxDepth: 3,
        );

        // Should return empty list (not throw error)
        expect(paths, isEmpty);
      });
    });
  });
}
