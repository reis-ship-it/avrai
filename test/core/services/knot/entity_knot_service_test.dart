// Unit tests for EntityKnotService
// 
// Tests knot generation for all entity types (person, event, place, company)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Mock Rust API for testing
class MockRustLibApi implements RustLibApi {
  @override
  Float64List crateApiCalculateAlexanderPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, 0.0, -1.0]);
  }

  @override
  Float64List crateApiCalculateBoltzmannDistribution(
      {required List<double> energies, required double temperature}) {
    final sum = energies.fold<double>(0.0, (a, b) => a + b);
    return Float64List.fromList(energies.map((e) => e / sum).toList());
  }

  @override
  BigInt crateApiCalculateCrossingNumberFromBraid(
      {required List<double> braidData}) {
    return BigInt.from((braidData.length - 1) ~/ 2);
  }

  @override
  double crateApiCalculateEntropy({required List<double> probabilities}) {
    return 1.0;
  }

  @override
  double crateApiCalculateFreeEnergy(
      {required double energy,
      required double entropy,
      required double temperature}) {
    return energy - temperature * entropy;
  }

  @override
  Float64List crateApiCalculateJonesPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, -1.0, 1.0]);
  }

  @override
  double crateApiCalculateKnotEnergyFromPoints(
      {required List<double> knotPoints}) {
    return 1.0;
  }

  @override
  double crateApiCalculateKnotStabilityFromPoints(
      {required List<double> knotPoints}) {
    return 0.8;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    final diff = (braidDataA.length - braidDataB.length).abs();
    return (1.0 - (diff / 10.0).clamp(0.0, 1.0));
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    return (braidData.length - 1) ~/ 2;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * (x * i);
    }
    return result;
  }

  @override
  KnotResult crateApiGenerateKnotFromBraid({required List<double> braidData}) {
    return KnotResult(
      knotData: Float64List.fromList([braidData[0]]),
      jonesPolynomial: Float64List.fromList([1.0, -1.0, 1.0]),
      alexanderPolynomial: Float64List.fromList([1.0, 0.0, -1.0]),
      crossingNumber: BigInt.from((braidData.length - 1) ~/ 2),
      writhe: (braidData.length - 1) ~/ 2,
      signature: 0,
      bridgeNumber: BigInt.from(1),
      braidIndex: BigInt.from(1),
      determinant: 1,
    );
  }

  @override
  double crateApiPolynomialDistance(
      {required List<double> coefficientsA,
      required List<double> coefficientsB}) {
    final maxLen = coefficientsA.length > coefficientsB.length
        ? coefficientsA.length
        : coefficientsB.length;
    double sumSq = 0.0;
    for (int i = 0; i < maxLen; i++) {
      final a = i < coefficientsA.length ? coefficientsA[i] : 0.0;
      final b = i < coefficientsB.length ? coefficientsB[i] : 0.0;
      sumSq += (a - b) * (a - b);
    }
    return sumSq;
  }
}

void main() {
  group('EntityKnotService Tests', () {
    late EntityKnotService service;
    bool rustLibInitialized = false;

    setUpAll(() {
      // Initialize Rust library for tests (mock mode)
      if (!rustLibInitialized) {
        RustLib.initMock(api: MockRustLibApi());
        rustLibInitialized = true;
      }
    });

    setUp(() {
      service = EntityKnotService();
    });

    group('Knot Generation for Person', () {
      test('should generate knot from personality profile', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_1',
          userId: 'test_user_1',
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        expect(entityKnot, isNotNull);
        expect(entityKnot.entityId, equals('test_agent_1'));
        expect(entityKnot.entityType, equals(EntityType.person));
        expect(entityKnot.knot, isNotNull);
        expect(entityKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(entityKnot.metadata, isNotEmpty);
        expect(entityKnot.metadata['archetype'], isNotNull);
      });

      test('should include personality metadata in entity knot', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_2',
          userId: 'test_user_2',
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        expect(entityKnot.metadata['archetype'], isNotNull);
        expect(entityKnot.metadata['authenticity'], isNotNull);
        expect(entityKnot.metadata['evolutionGeneration'], isNotNull);
      });
    });

    group('Knot Generation for Event', () {
      test('should generate knot from event characteristics', () async {
        final host = ModelFactories.createTestUser(id: 'host-1');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        expect(entityKnot, isNotNull);
        expect(entityKnot.entityId, equals(event.id));
        expect(entityKnot.entityType, equals(EntityType.event));
        expect(entityKnot.knot, isNotNull);
        expect(entityKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(entityKnot.metadata['category'], equals('Coffee'));
        expect(entityKnot.metadata['eventType'], isNotNull);
      });

      test('should extract event properties correctly', () async {
        final host = ModelFactories.createTestUser(id: 'host-2');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Bookstores',
          eventType: ExpertiseEventType.workshop,
          attendeeIds: ['attendee-1', 'attendee-2', 'attendee-3', 'attendee-4', 'attendee-5'],
          maxAttendees: 10,
          price: 25.0,
          isPaid: true,
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        expect(entityKnot.metadata['category'], equals('Bookstores'));
        expect(entityKnot.metadata['attendeeCount'], equals(5));
        expect(entityKnot.metadata['maxAttendees'], equals(10));
        expect(entityKnot.metadata['isPaid'], isTrue);
      });

      test('should handle events with location data', () async {
        final host = ModelFactories.createTestUser(id: 'host-3');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: 'Coffee',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        expect(entityKnot.metadata['latitude'], equals(40.7128));
        expect(entityKnot.metadata['longitude'], equals(-74.0060));
      });
    });

    group('Knot Generation for Place', () {
      test('should generate knot from place characteristics', () async {
        final spot = ModelFactories.createTestSpot(
          id: 'spot-1',
          name: 'Test Coffee Shop',
          category: 'Coffee',
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );

        expect(entityKnot, isNotNull);
        expect(entityKnot.entityId, equals('spot-1'));
        expect(entityKnot.entityType, equals(EntityType.place));
        expect(entityKnot.knot, isNotNull);
        expect(entityKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(entityKnot.metadata['category'], equals('Coffee'));
        expect(entityKnot.metadata['rating'], equals(4.5));
        expect(entityKnot.metadata['name'], equals('Test Coffee Shop'));
      });

      test('should extract place location data', () async {
        final spot = ModelFactories.createTestSpot(
          id: 'spot-2',
          name: 'Test Place',
          latitude: 40.7589,
          longitude: -73.9851,
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.place,
          entity: spot,
        );

        expect(entityKnot.metadata['latitude'], equals(40.7589));
        expect(entityKnot.metadata['longitude'], equals(-73.9851));
      });
    });

    group('Knot Generation for Company', () {
      test('should generate knot from company characteristics', () async {
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          name: 'Test Business',
          businessType: 'Coffee Shop',
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.company,
          entity: business,
        );

        expect(entityKnot, isNotNull);
        expect(entityKnot.entityId, equals('business-1'));
        expect(entityKnot.entityType, equals(EntityType.company));
        expect(entityKnot.knot, isNotNull);
        expect(entityKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(entityKnot.metadata['businessType'], equals('Coffee Shop'));
        expect(entityKnot.metadata['businessName'], equals('Test Business'));
      });

      test('should handle verified businesses', () async {
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-2',
          name: 'Verified Business',
          businessType: 'Restaurant',
        );

        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.company,
          entity: business,
        );

        expect(entityKnot.metadata['verificationStatus'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should throw error for unsupported entity type', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_error',
          userId: 'test_user_error',
        );

        // EntityType.brand is not yet implemented in generateKnotForEntity
        // This test verifies error handling
        await expectLater(
          () => service.generateKnotForEntity(
            entityType: EntityType.brand,
            entity: profile,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle invalid entity data gracefully', () async {
        // This test verifies that the service handles edge cases
        // For example, events with missing required fields
        final host = ModelFactories.createTestUser(id: 'host-error');
        final event = IntegrationTestHelpers.createTestEvent(
          host: host,
          category: '',
        );

        // Should still generate a knot (with default/empty values)
        final entityKnot = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event,
        );

        expect(entityKnot, isNotNull);
        expect(entityKnot.knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
      });
    });

    group('Knot Uniqueness', () {
      test('should generate different knots for different entities', () async {
        final host1 = ModelFactories.createTestUser(id: 'host-1');
        final host2 = ModelFactories.createTestUser(id: 'host-2');
        
        final event1 = IntegrationTestHelpers.createTestEvent(
          host: host1,
          id: 'event-1',
          category: 'Coffee',
        );
        final event2 = IntegrationTestHelpers.createTestEvent(
          host: host2,
          id: 'event-2',
          category: 'Bookstores',
        );

        final knot1 = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event1,
        );
        final knot2 = await service.generateKnotForEntity(
          entityType: EntityType.event,
          entity: event2,
        );

        // Different entities should produce different knots
        expect(knot1.entityId, isNot(equals(knot2.entityId)));
        // Knot invariants should differ for different categories
        expect(
          knot1.knot.invariants.jonesPolynomial,
          isNot(equals(knot2.knot.invariants.jonesPolynomial)),
        );
      });
    });
  });
}
