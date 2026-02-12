// Knot Fabric Community Integration Tests
// 
// Integration tests for Phase 5: Knot Fabric Integration with CommunityService
// Part of Patent #31: Topological Knot Theory for Personality Representation
//
// Tests verify end-to-end workflow:
// 1. Knot fabric generation from community members
// 2. Community health metrics from fabric
// 3. Community discovery from fabric clusters
// 4. Fabric-based community insights

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai/core/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/fabric_evolution.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';
import 'package:avrai/injection_container.dart' as di;

import '../../helpers/platform_channel_helper.dart';
import '../../helpers/test_helpers.dart';

// Mock Rust API for testing
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
    return Float64List.fromList(
        energies.map((e) => e / sum).toList());
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
    return 0.5;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    return 0.5;
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    return 0;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * _power(x, i);
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
      writhe: 0,
      signature: 0,
      bridgeNumber: BigInt.from(1),
      braidIndex: BigInt.from(1),
      determinant: 1,
    );
  }

  @override
  double crateApiPolynomialDistance(
      {required List<double> coefficientsA, required List<double> coefficientsB}) {
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

  double _power(double base, int exponent) {
    if (exponent == 0) return 1.0;
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

/// Integration tests for knot fabric community features
void main() {
  group('Knot Fabric Community Integration Tests', () {
    late CommunityService communityService;
    late KnotFabricService knotFabricService;
    late KnotStorageService knotStorageService;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late PersonalityKnotService personalityKnotService;
    late GeographicExpansionService geographicExpansionService;

    setUpAll(() async {
      try {
        // Initialize Rust library for tests (mock mode)
        try {
          RustLib.initMock(api: MockRustLibApi());
        } catch (e) {
          // Already initialized, that's fine
        }

        // Avoid path_provider / GetStorage.init in tests.
        await setupTestStorage();
        
        // Initialize dependency injection
        await di.init();
        
        // Get services
        knotFabricService = di.sl<KnotFabricService>();
        knotStorageService = di.sl<KnotStorageService>();
        personalityKnotService = di.sl<PersonalityKnotService>();
        geographicExpansionService = GeographicExpansionService(); // Create directly
        
        // Create CommunityService with knot fabric integration
        communityService = CommunityService(
          expansionService: geographicExpansionService,
          knotFabricService: knotFabricService,
          knotStorageService: knotStorageService,
        );
      } catch (e) {
      // ignore: avoid_print
        // If initialization fails, log and rethrow
      // ignore: avoid_print
        print('Error in setUpAll: $e');
        rethrow;
      }
    });

    setUp(() async {
      // No-op: Sembast removed in Phase 26
    });

    tearDown(() async {
      // Clean up test data
      TestHelpers.teardownTestEnvironment();
    });

    group('Knot Fabric Generation from Community', () {
      test('should generate fabric from community member knots', () async {
        // Arrange: Create test knots for community members
        final memberKnots = await _createTestMemberKnots(5);
        
        // Store knots
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
      // ignore: unused_local_variable
        }

      // ignore: unused_local_variable - May be used in callback or assertion
        // Create a test community
      // ignore: unused_local_variable - May be used in callback or assertion
        final community = await _createTestCommunity(memberKnots.map((k) => k.agentId).toList());

        // Act: Generate fabric from community
        final fabric = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: memberKnots,
        );

        // Assert: Fabric generated successfully
        expect(fabric, isNotNull);
        expect(fabric.userKnots.length, equals(5));
        expect(fabric.braid.strandCount, equals(5));
        expect(fabric.invariants, isNotNull);
      });

      test('should calculate fabric invariants for community', () async {
        // Arrange: Create test knots
        final memberKnots = await _createTestMemberKnots(4);
        final fabric = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: memberKnots,
        );

        // Act: Calculate invariants
        final invariants = await knotFabricService.calculateFabricInvariants(fabric);

        // Assert: Invariants calculated
        expect(invariants.jonesPolynomial.coefficients, isNotEmpty);
        expect(invariants.alexanderPolynomial.coefficients, isNotEmpty);
        expect(invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(invariants.density, greaterThanOrEqualTo(0.0));
        expect(invariants.stability, greaterThanOrEqualTo(0.0));
        expect(invariants.stability, lessThanOrEqualTo(1.0));
      });
    });

    group('Community Health Metrics from Fabric', () {
      test('should get community health metrics from fabric', () async {
        // Arrange: Create test community with member knots
        final memberKnots = await _createTestMemberKnots(6);
        
        // Store knots
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community using CommunityService
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length, // Adjust to match actual member count
        );

        // Act: Get community health from fabric
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Health metrics returned
        expect(health, isNotNull);
        expect(health!.cohesion, greaterThanOrEqualTo(0.0));
        expect(health.cohesion, lessThanOrEqualTo(1.0));
        expect(health.density, greaterThanOrEqualTo(0.0));
        expect(health.clusters, isA<List>());
        expect(health.bridges, isA<List>());
        expect(health.diversity, isNotNull);
      });

      test('should identify fabric clusters as communities', () async {
        // Arrange: Create high-compatibility knots to form clusters
        final memberKnots = await _createTestMemberKnots(8);
        
        // Store knots
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length,
        );

        // Act: Get health metrics
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Clusters identified
        expect(health, isNotNull);
        if (health != null) {
          // Clusters may be empty depending on fabric structure
          for (final cluster in health.clusters) {
            expect(cluster.clusterId, isNotEmpty);
            expect(cluster.userKnots, isNotEmpty);
            expect(cluster.density, greaterThanOrEqualTo(0.0));
          }
        }
      });

      test('should identify bridge strands connecting communities', () async {
        // Arrange: Create knots that will form multiple clusters
        final memberKnots = await _createTestMemberKnots(10);
        
        // Store knots
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length,
        );

        // Act: Get health metrics
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Bridges may be identified (depending on fabric structure)
        expect(health, isNotNull);
        if (health != null) {
          expect(health.bridges, isA<List>());
          // Bridges are optional - fabric may or may not have them
          for (final bridge in health.bridges) {
            expect(bridge.userKnot, isNotNull);
            expect(bridge.connectedClusters.length, greaterThanOrEqualTo(2));
            expect(bridge.bridgeStrength, greaterThanOrEqualTo(0.0));
          }
        }
      });

      test('should generate insights from community health', () async {
        // Arrange: Create test community
        final memberKnots = await _createTestMemberKnots(5);
        
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length,
        );

        // Act: Get health and generate insights
        final health = await communityService.getCommunityHealth(createdCommunity.id);
        expect(health, isNotNull);
        final insights = health!.generateInsights();

        // Assert: Insights generated
        expect(insights, isNotEmpty);
        expect(insights, isA<List<String>>());
        // Insights should contain meaningful information
        for (final insight in insights) {
          expect(insight, isNotEmpty);
        }
      });
    });

    group('Community Discovery from Fabric', () {
      test('should discover communities from fabric clusters', () async {
        // Arrange: Create multiple user knots
        final allKnots = await _createTestMemberKnots(12);
        
        // Store all knots
        for (final knot in allKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Act: Discover communities from fabric
        final allUserIds = allKnots.map((k) => k.agentId).toList();
        final discoveredCommunities = await communityService.discoverCommunitiesFromFabric(
          allUserIds: allUserIds,
        );

        // Assert: Communities discovered
        expect(discoveredCommunities, isA<List<Community>>());
        // May discover 0 or more communities depending on fabric structure
        for (final community in discoveredCommunities) {
          expect(community.id, isNotEmpty);
          expect(community.name, isNotEmpty);
          expect(community.memberIds, isNotEmpty);
          expect(community.category, isNotEmpty); // Category may vary
        }
      });

      test('should create communities with knot-based metadata', () async {
        // Arrange: Create knots that will form a cluster
        final memberKnots = await _createTestMemberKnots(6);
        
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Act: Discover communities
        final allUserIds = memberKnots.map((k) => k.agentId).toList();
        final discoveredCommunities = await communityService.discoverCommunitiesFromFabric(
          allUserIds: allUserIds,
        );

        // Assert: Communities have knot-based metadata
        if (discoveredCommunities.isNotEmpty) {
          final community = discoveredCommunities.first;
          expect(community.originatingEventType, isNotNull);
          expect(community.founderId, isNotEmpty);
          expect(community.memberCount, greaterThan(0));
        }
      });
    });

    group('Fabric Evolution Tracking', () {
      test('should track fabric changes when community members change', () async {
        // Arrange: Create initial fabric
        final initialKnots = await _createTestMemberKnots(4);
        final initialFabric = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: initialKnots,
        );

        // Add new member
        final newKnot = await _createTestKnot('new_member');
        final updatedKnots = [...initialKnots, newKnot];
        final updatedFabric = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: updatedKnots,
        );

        // Act: Track evolution
        final evolution = await knotFabricService.trackFabricEvolution(
          currentFabric: updatedFabric,
          previousFabric: initialFabric,
          changes: [
            const FabricChange(
              type: FabricChangeType.newKnot,
              userKnotId: 'new_member',
            ),
          ],
        );

        // Assert: Evolution tracked
        expect(evolution, isNotNull);
        expect(evolution.currentFabric.userCount, equals(5));
        expect(evolution.previousFabric.userCount, equals(4));
        expect(evolution.changes.length, equals(1));
        expect(evolution.stabilityChange, isA<double>());
      });

      test('should detect stability changes in fabric evolution', () async {
        // Arrange: Create two fabrics with different compatibility
        final knots1 = await _createTestMemberKnots(4);
        final fabric1 = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: knots1,
        );

        // Create fabric with higher compatibility
        final knots2 = await _createTestMemberKnots(4);
        final compatibilityScores = <String, double>{};
        for (int i = 0; i < 4; i++) {
          for (int j = i + 1; j < 4; j++) {
            compatibilityScores['${i}_$j'] = 0.9; // High compatibility
          }
        }
        final fabric2 = await knotFabricService.generateMultiStrandBraidFabric(
          userKnots: knots2,
          compatibilityScores: compatibilityScores,
        );

        // Act: Track evolution
        final evolution = await knotFabricService.trackFabricEvolution(
          currentFabric: fabric2,
          previousFabric: fabric1,
          changes: [],
        );

        // Assert: Stability change calculated
        expect(evolution.stabilityChange, isA<double>());
        // Stability may improve or decline depending on algorithm
      });
    });

    group('Fabric-Based Community Insights', () {
      test('should provide diversity insights from fabric', () async {
        // Arrange: Create diverse knots
        final memberKnots = await _createTestMemberKnots(8);
        
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length,
        );

        // Act: Get health metrics
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Diversity information available
        expect(health, isNotNull);
        expect(health!.diversity, isNotNull);
        expect(health.diversity.primaryType, isNotEmpty);
        expect(health.diversity.typeCounts, isA<Map<String, int>>());
        expect(health.diversity.diversity, greaterThanOrEqualTo(0.0));
        expect(health.diversity.diversity, lessThanOrEqualTo(1.0));
        
        // Test diversity description
        final description = health.diversity.describe();
        expect(description, isNotEmpty);
      });

      test('should identify community cohesion from fabric stability', () async {
        // Arrange: Create cohesive community (high compatibility)
        final memberKnots = await _createTestMemberKnots(5);
        
        for (final knot in memberKnots) {
          await knotStorageService.saveKnot(knot.agentId, knot);
        }

        // Create and store community
        final event = _createTestEvent(memberKnots.map((k) => k.agentId).toList());
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: memberKnots.length,
        );

        // Act: Get health metrics
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Cohesion measured
        expect(health, isNotNull);
        expect(health!.cohesion, greaterThanOrEqualTo(0.0));
        expect(health.cohesion, lessThanOrEqualTo(1.0));
        
        // High cohesion indicates stable community
        if (health.cohesion > 0.7) {
          expect(health.clusters.length, greaterThanOrEqualTo(1));
        }
      });
    });

    group('Error Handling', () {
      test('should handle missing knots gracefully', () async {
        // Arrange: Create community with non-existent member IDs (need 5+ for validation)
        final nonExistentIds = List.generate(5, (i) => 'non_existent_$i');
        final event = _createTestEvent(nonExistentIds);
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: 5,
        );

        // Act: Get health (should not throw, returns null when no knots found)
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Returns null when no knots found
        expect(health, isNull);
      });

      test('should handle empty community gracefully', () async {
        // Arrange: Create community with attendees but no stored knots
        // Ensure IDs are at least 10 characters
        final testAttendees = List.generate(5, (i) => 'attendee_$i'.padRight(10, '_'));
        final event = _createTestEvent(testAttendees);
        final createdCommunity = await communityService.createCommunityFromEvent(
          event: event,
          minAttendees: 5,
        );

        // Act: Get health (community has members but no knots stored, so returns null)
        final health = await communityService.getCommunityHealth(createdCommunity.id);

        // Assert: Returns null when no knots found
        expect(health, isNull);
      });
    });
  });
}

// Helper functions

Future<List<PersonalityKnot>> _createTestMemberKnots(int count) async {
  final knots = <PersonalityKnot>[];
  for (int i = 0; i < count; i++) {
    final knot = await _createTestKnot('member_$i');
    knots.add(knot);
  }
  return knots;
}

Future<PersonalityKnot> _createTestKnot(String agentId) async {
  final now = DateTime.now();
  // Ensure agentId is at least 10 characters to avoid substring errors in KnotStorageService
  final paddedAgentId = agentId.padRight(10, '_');
  return PersonalityKnot(
    agentId: paddedAgentId,
    braidData: [
      8.0, // strands
      // Add some crossings
      (agentId.hashCode % 8).toDouble(),
      1.0, // is_over
      ((agentId.hashCode + 1) % 8).toDouble(),
      0.0, // is_over
    ],
    invariants: KnotInvariants(
      jonesPolynomial: [1.0, 0.5, 0.2],
      alexanderPolynomial: [1.0, -0.3, 0.1],
      crossingNumber: 2 + (agentId.hashCode % 5),
      writhe: agentId.hashCode % 3 - 1,
      signature: 0,
      bridgeNumber: ((2 + (agentId.hashCode % 5)) / 2).clamp(1, 10).round(),
      braidIndex: ((2 + (agentId.hashCode % 5)) / 3).clamp(1, 12).round(),
      determinant: 1,
    ),
    createdAt: now,
    lastUpdated: now,
  );
}

Future<Community> _createTestCommunity(List<String> memberIds) async {
  // Create a test community
  // Note: In a real implementation, this would use CommunityService.createCommunity
  // For testing, we'll create a minimal community object
  return Community(
    id: 'test_community_${DateTime.now().millisecondsSinceEpoch}',
    name: 'Test Community',
    description: 'Test community for knot fabric integration',
    category: 'Test',
    originatingEventId: 'test_event',
    originatingEventType: OriginatingEventType.communityEvent,
    memberIds: memberIds,
    memberCount: memberIds.length,
    founderId: memberIds.isNotEmpty ? memberIds.first : 'system',
    eventIds: const [],
    eventCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    originalLocality: 'Test Locality',
  );
}

ExpertiseEvent _createTestEvent(List<String> attendeeIds) {
  return ExpertiseEvent(
    id: 'test_event_${DateTime.now().millisecondsSinceEpoch}',
    title: 'Test Event',
    description: 'Test event for integration testing',
    category: 'Test',
    eventType: ExpertiseEventType.workshop,
    host: UnifiedUser(
      id: attendeeIds.isNotEmpty ? attendeeIds.first : 'test_host',
      displayName: 'Test Host',
      email: 'test@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    attendeeIds: attendeeIds,
    attendeeCount: attendeeIds.length,
    maxAttendees: 20,
    startTime: DateTime.now().add(const Duration(days: 1)),
    endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    spots: const [],
    location: 'Test Location',
    isPaid: false,
    isPublic: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: EventStatus.upcoming,
  );
}
