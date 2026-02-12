import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/geographic/neighborhood_boundary.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for NeighborhoodBoundary model
///
/// **Philosophy:** Neighborhood boundaries reflect actual community connections,
/// not just geographic lines. Borders evolve based on user behavior.
void main() {
  group('NeighborhoodBoundary Model Tests', () {
    late DateTime testDate;
    late List<CoordinatePoint> testCoordinates;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testCoordinates = const [
        CoordinatePoint(latitude: 40.7295, longitude: -73.9545),
        CoordinatePoint(latitude: 40.7300, longitude: -73.9550),
        CoordinatePoint(latitude: 40.7305, longitude: -73.9555),
      ];
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Boundary Type', () {
      test('should correctly identify boundary type states', () {
        // Test business logic: type identification
        final hardBorder = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final softBorder = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(hardBorder.isHardBorder, isTrue);
        expect(hardBorder.isSoftBorder, isFalse);
        expect(softBorder.isSoftBorder, isTrue);
        expect(softBorder.isHardBorder, isFalse);
      });
    });

    // Removed: Coordinate Storage group
    // These tests only verified list storage, not business logic

    group('Soft Border Spot Tracking', () {
      test('should correctly identify spots in soft border areas', () {
        // Test business logic: spot identification
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1', 'spot-2'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.isSpotInSoftBorder('spot-1'), isTrue);
        expect(boundary.isSpotInSoftBorder('spot-2'), isTrue);
        expect(boundary.isSpotInSoftBorder('spot-3'), isFalse);
      });
    });

    group('User Visit Count Tracking', () {
      test(
          'should correctly determine dominant locality based on visit counts and handle ties by returning locality1',
          () {
        // Test business logic: dominant locality calculation and tie-breaking
        final boundaryWithWinner = NeighborhoodBoundary(
          id: 'boundary-1',
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
        final boundaryWithTie = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Nolita': 10, 'East Village': 10},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(
            boundaryWithWinner.getDominantLocality('spot-1'), equals('Nolita'));
        expect(boundaryWithTie.getDominantLocality('spot-1'),
            equals('Nolita')); // Tie breaks to locality1
      });
    });

    group('Refinement History', () {
      test('should track refinement history and timestamps correctly', () {
        // Test business logic: refinement tracking
        final refinement1 = RefinementEvent(
          timestamp: testDate,
          reason: 'User behavior analysis',
          method: 'Visit count analysis',
          changes: 'Moved spot-1 to Nolita',
        );
        final lastRefined =
            TestHelpers.createTimestampWithOffset(const Duration(days: 1));

        final refined = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          refinementHistory: [refinement1],
          lastRefinedAt: lastRefined,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final unrefined = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(refined.refinementHistory, hasLength(1));
        expect(refined.lastRefinedAt, isNotNull);
        expect(unrefined.lastRefinedAt, isNull);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested structures and handle missing optional fields with defaults',
          () {
        // Test business logic: JSON round-trip with nested structures and default handling
        final refinement = RefinementEvent(
          timestamp: testDate,
          reason: 'User behavior',
          method: 'Visit count analysis',
          changes: 'Moved spot-1',
        );

        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: const ['spot-1'],
          userVisitCounts: const {
            'spot-1': {'Greenpoint': 10, 'Williamsburg': 5},
          },
          refinementHistory: [refinement],
          lastRefinedAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = boundary.toJson();
        final restored = NeighborhoodBoundary.fromJson(json);

        expect(restored.boundaryType, equals(BoundaryType.hardBorder));
        expect(restored.softBorderSpots, equals(['spot-1']));
        expect(restored.userVisitCounts['spot-1']?['Greenpoint'], equals(10));
        expect(restored.refinementHistory, hasLength(1));

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'boundary-123',
          'locality1': 'Greenpoint',
          'locality2': 'Williamsburg',
          'boundaryType': 'hardBorder',
          'coordinates': testCoordinates,
          'source': 'Google Maps',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };
        final fromMinimal = NeighborhoodBoundary.fromJson(minimalJson);

        expect(fromMinimal.softBorderSpots, isEmpty);
        expect(fromMinimal.userVisitCounts, isEmpty);
        expect(fromMinimal.lastRefinedAt, isNull);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          boundaryType: BoundaryType.softBorder,
          softBorderSpots: ['spot-1'],
        );

        // Test immutability (business logic)
        expect(original.boundaryType, isNot(equals(BoundaryType.softBorder)));
        expect(updated.boundaryType, equals(BoundaryType.softBorder));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });

  // Removed: RefinementEvent Model Tests group
  // These tests only verified Dart constructor and JSON serialization behavior
  // RefinementEvent is tested through NeighborhoodBoundary JSON tests above
}
