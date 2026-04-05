import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/places/neighborhood_boundary_service.dart';
import 'package:avrai_core/models/geographic/neighborhood_boundary.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Comprehensive tests for NeighborhoodBoundaryService
///
/// **Philosophy:** Neighborhood boundaries reflect actual community connections,
/// not just geographic lines. Borders evolve based on user behavior.
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });
  group('NeighborhoodBoundaryService Tests', () {
    late NeighborhoodBoundaryService service;
    late DateTime testDate;
    late List<CoordinatePoint> testCoordinates;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testCoordinates = [
        const CoordinatePoint(latitude: 40.7295, longitude: -73.9545),
        const CoordinatePoint(latitude: 40.7300, longitude: -73.9550),
        const CoordinatePoint(latitude: 40.7305, longitude: -73.9555),
      ];
      service = NeighborhoodBoundaryService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Boundary loading tests focus on business logic (loading, empty cases, error handling), not property assignment

    group('Boundary Loading', () {
      test(
          'should load boundaries from Google Maps for city, return empty list for cities with no boundaries, and handle errors',
          () async {
        // Test business logic: boundary loading with various scenarios
        final boundaries1 =
            await service.loadBoundariesFromGoogleMaps('Brooklyn');
        expect(boundaries1, isA<List<NeighborhoodBoundary>>());

        final boundaries2 =
            await service.loadBoundariesFromGoogleMaps('Smalltown');
        expect(boundaries2, isEmpty);

        // Test error handling for invalid city names or API failures
        expect(
          () => service.loadBoundariesFromGoogleMaps(''),
          returnsNormally,
        );
      });
    });

    group('Get Boundary', () {
      test(
          'should get boundary between two localities regardless of order, or return null if not found',
          () async {
        // Test business logic: boundary retrieval with order independence and existence checking
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        // Test order independence
        final retrieved1 =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        final retrieved2 =
            await service.getBoundary('Williamsburg', 'Greenpoint');
        expect(retrieved1, isNotNull);
        expect(retrieved2, isNotNull);
        expect(retrieved1?.id, equals(retrieved2?.id));

        // Test non-existent boundary
        final notFound =
            await service.getBoundary('NonExistent1', 'NonExistent2');
        expect(notFound, isNull);
      });
    });

    group('Get Boundaries for Locality', () {
      test(
          'should get all boundaries for a locality, or return empty list if none exist',
          () async {
        // Test business logic: boundary retrieval for locality with empty case handling
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'DUMBO',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary1);
        await service.saveBoundary(boundary2);

        final boundaries = await service.getBoundariesForLocality('Greenpoint');
        expect(boundaries, hasLength(2));
        expect(boundaries.any((b) => b.id == 'boundary-1'), isTrue);
        expect(boundaries.any((b) => b.id == 'boundary-2'), isTrue);

        final empty = await service.getBoundariesForLocality('NonExistent');
        expect(empty, isEmpty);
      });
    });

    group('Hard Border Detection', () {
      test(
          'should detect hard borders correctly, return false for soft borders, and get all hard borders for city',
          () async {
        // Test business logic: hard border detection and filtering
        final hardBorderTest = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final softBorderTest = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(hardBorderTest);
        await service.saveBoundary(softBorderTest);

        expect(await service.isHardBorder('NoHo', 'SoHo'), isTrue);
        expect(await service.isHardBorder('Nolita', 'East Village'), isFalse);

        // Test getting all hard borders
        final hardBorder1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final hardBorder2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final softBorder = NeighborhoodBoundary(
          id: 'boundary-3',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(hardBorder1);
        await service.saveBoundary(hardBorder2);
        await service.saveBoundary(softBorder);

        final hardBorders = await service.getHardBorders('Brooklyn');
        expect(hardBorders, hasLength(2));
        expect(
            hardBorders.every((b) => b.boundaryType == BoundaryType.hardBorder),
            isTrue);
      });
    });

    group('Soft Border Detection', () {
      test(
          'should detect soft borders correctly, return false for hard borders, and get all soft borders for city',
          () async {
        // Test business logic: soft border detection and filtering
        final softBorderTest = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final hardBorderTest = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(softBorderTest);
        await service.saveBoundary(hardBorderTest);

        expect(await service.isSoftBorder('Nolita', 'East Village'), isTrue);
        expect(await service.isSoftBorder('NoHo', 'SoHo'), isFalse);

        // Test getting all soft borders
        final softBorder1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final softBorder2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final hardBorderForFilter = NeighborhoodBoundary(
          id: 'boundary-3',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(softBorder1);
        await service.saveBoundary(softBorder2);
        await service.saveBoundary(hardBorderForFilter);

        final softBorders = await service.getSoftBorders('Brooklyn');

        expect(softBorders, hasLength(2));
        expect(
            softBorders.every((b) => b.boundaryType == BoundaryType.softBorder),
            isTrue);
      });
    });

    group('Soft Border Spot Tracking', () {
      test(
          'should add spot to soft border, get soft border spots, and check if spot is in soft border',
          () async {
        // Test business logic: soft border spot tracking operations
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary);
        await service.addSoftBorderSpot('spot-1', 'Nolita', 'East Village');
        final updated1 = await service.getBoundary('Nolita', 'East Village');
        expect(updated1?.softBorderSpots, contains('spot-1'));

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1', 'spot-2'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary2);
        final spots =
            await service.getSoftBorderSpots('Nolita', 'East Village');
        expect(spots, hasLength(2));
        expect(spots, contains('spot-1'));
        expect(spots, contains('spot-2'));

        // Both spots are in soft border (boundary2 includes both)
        expect(await service.isSpotInSoftBorder('spot-1'), isTrue);
        expect(await service.isSpotInSoftBorder('spot-2'), isTrue);
      });
    });

    group('User Visit Tracking', () {
      test(
          'should track user visit to spot, increment visit count for multiple visits, get visit counts for spot, and get dominant locality for spot',
          () async {
        // Test business logic: user visit tracking and analysis
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary1);
        await service.trackSpotVisit('spot-1', 'Nolita');
        final updated1 = await service.getBoundary('Nolita', 'East Village');
        expect(updated1?.userVisitCounts['spot-1']?['Nolita'], equals(1));

        await service.trackSpotVisit('spot-1', 'Nolita');
        await service.trackSpotVisit('spot-1', 'Nolita');
        await service.trackSpotVisit('spot-1', 'Nolita');
        final updated2 = await service.getBoundary('Nolita', 'East Village');
        expect(updated2?.userVisitCounts['spot-1']?['Nolita'], equals(4));

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 15, 'East Village': 8},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary2);
        final visitCounts = await service.getSpotVisitCounts('spot-1');
        expect(visitCounts['Nolita'], equals(15));
        expect(visitCounts['East Village'], equals(8));

        final dominant = await service.getDominantLocality('spot-1');
        expect(dominant, equals('Nolita'));
      });
    });

    group('Border Refinement', () {
      test(
          'should check if border should be refined, not refine border with insufficient data, calculate border refinement, and refine soft border',
          () async {
        // Test business logic: border refinement operations
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary1);
        final shouldRefine1 =
            await service.shouldRefineBorder('Nolita', 'East Village');
        expect(shouldRefine1, isTrue);

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 3, 'East Village': 2},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary2);
        final shouldRefine2 =
            await service.shouldRefineBorder('Nolita', 'East Village');
        expect(shouldRefine2, isFalse);

        final boundary3 = NeighborhoodBoundary(
          id: 'boundary-789',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1', 'spot-2'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 20, 'East Village': 5},
            'spot-2': {'Nolita': 3, 'East Village': 15},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary3);
        final refinement =
            await service.calculateBorderRefinement('Nolita', 'East Village');
        expect(refinement, isNotNull);
        expect(refinement, isA<Map<String, dynamic>>());
        expect(refinement.isNotEmpty, isTrue);

        await service.refineSoftBorder('Nolita', 'East Village');
        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
        expect(updated?.lastRefinedAt, isNotNull);
      });
    });

    group('Dynamic Border Updates', () {
      test(
          'should track user movement, get user movement patterns for locality, analyze movement patterns between localities, associate spot with locality, update spot locality association based on visits, update boundary from behavior, calculate boundary changes, and apply boundary refinement',
          () async {
        // Test business logic: dynamic border updates based on user behavior
        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');
        expect(await service.getUserMovementPatterns('Nolita'), isA<Map>());

        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-2', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-1', 'spot-2', 'Nolita');
        final patterns = await service.getUserMovementPatterns('Nolita');
        expect(patterns, isNotEmpty);

        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-2', 'spot-1', 'East Village');
        await service.trackUserMovement('user-3', 'spot-1', 'Nolita');
        final analysis =
            await service.analyzeMovementPatterns('Nolita', 'East Village');
        expect(analysis, isNotNull);

        await service.associateSpotWithLocality('spot-1', 'Nolita');
        final association1 = await service.getSpotLocalityAssociation('spot-1');
        expect(association1, equals('Nolita'));

        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary1);
        await service.updateSpotLocalityAssociation('spot-1');
        final association2 = await service.getSpotLocalityAssociation('spot-1');
        expect(association2, equals('Nolita'));

        await service.updateBoundaryFromBehavior('Nolita', 'East Village');
        final updated1 = await service.getBoundary('Nolita', 'East Village');
        expect(updated1?.refinementHistory, isNotEmpty);

        final changes =
            await service.calculateBoundaryChanges('Nolita', 'East Village');
        expect(changes, isNotNull);
        expect(changes.isNotEmpty, isTrue);

        final refinement =
            await service.calculateBorderRefinement('Nolita', 'East Village');
        await service.applyBoundaryRefinement(
            'Nolita', 'East Village', refinement);
        final updated2 = await service.getBoundary('Nolita', 'East Village');
        expect(updated2?.refinementHistory, isNotEmpty);
        expect(updated2?.lastRefinedAt, isNotNull);
      });
    });

    group('Geographic Hierarchy Integration', () {
      test(
          'should integrate with geographic hierarchy and update geographic hierarchy based on boundaries',
          () async {
        // Test business logic: geographic hierarchy integration
        await service.integrateWithGeographicHierarchy('Nolita');
        expect(await service.getBoundariesForLocality('Nolita'), isA<List>());

        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );
        await service.saveBoundary(boundary);
        await service.updateGeographicHierarchy('Nolita');
        expect(await service.getBoundariesForLocality('Nolita'), isNotEmpty);
      });
    });

    group('Save and Update Boundary', () {
      test('should save and update boundary correctly', () async {
        // Test business logic: boundary persistence and updates
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);
        final retrieved1 =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        expect(retrieved1, isNotNull);
        expect(retrieved1?.id, equals('boundary-123'));

        final updated = boundary.copyWith(
          boundaryType: BoundaryType.softBorder,
          softBorderSpots: ['spot-1'],
        );
        await service.updateBoundary(updated);

        final retrieved2 =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        expect(retrieved2?.boundaryType, equals(BoundaryType.softBorder));
        expect(retrieved2?.softBorderSpots, contains('spot-1'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
