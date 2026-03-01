import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/places/large_city_detection_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Large City Detection Service Tests
/// Tests large city detection and neighborhood handling
void main() {
  group('LargeCityDetectionService Tests', () {
    late LargeCityDetectionService service;

    setUp(() {
      service = LargeCityDetectionService();
    });

    // Removed: Property assignment tests
    // City detection tests focus on business logic (detection rules, case insensitivity), not individual city property checks

    group('isLargeCity', () {
      test(
          'should detect large cities with case-insensitive matching and reject small cities',
          () {
        // Test business logic: large city detection with case insensitivity
        // Test multiple large cities
        expect(service.isLargeCity('Brooklyn'), isTrue);
        expect(service.isLargeCity('brooklyn'), isTrue); // Case insensitive
        expect(service.isLargeCity('BROOKLYN'), isTrue);
        expect(service.isLargeCity('Los Angeles'), isTrue);
        expect(service.isLargeCity('los angeles'), isTrue);
        expect(service.isLargeCity('Chicago'), isTrue);
        expect(service.isLargeCity('Tokyo'), isTrue);
        expect(service.isLargeCity('Seoul'), isTrue);
        expect(service.isLargeCity('Paris'), isTrue);
        expect(service.isLargeCity('Madrid'), isTrue);
        expect(service.isLargeCity('Lagos'), isTrue);

        // Test rejection of small cities
        expect(service.isLargeCity('Smalltown'), isFalse);
        expect(service.isLargeCity(''), isFalse);
      });
    });

    group('getNeighborhoods', () {
      test(
          'should return neighborhoods for large cities or empty list for non-large cities',
          () {
        // Test business logic: neighborhood retrieval with empty case handling
        final brooklynNeighborhoods = service.getNeighborhoods('Brooklyn');
        expect(brooklynNeighborhoods, isNotEmpty);
        expect(brooklynNeighborhoods, contains('Greenpoint'));
        expect(brooklynNeighborhoods, contains('Williamsburg'));

        final laNeighborhoods = service.getNeighborhoods('Los Angeles');
        expect(laNeighborhoods, isNotEmpty);
        expect(laNeighborhoods, contains('Hollywood'));

        final tokyoNeighborhoods = service.getNeighborhoods('Tokyo');
        expect(tokyoNeighborhoods, isNotEmpty);
        expect(tokyoNeighborhoods, contains('Shibuya'));

        // Test empty cases
        expect(service.getNeighborhoods('Smalltown'), isEmpty);
        expect(service.getNeighborhoods(''), isEmpty);
      });
    });

    group('isNeighborhoodLocality', () {
      test(
          'should detect neighborhoods with case-insensitive matching and reject regular localities',
          () {
        // Test business logic: neighborhood detection with case insensitivity
        expect(service.isNeighborhoodLocality('Greenpoint'), isTrue);
        expect(service.isNeighborhoodLocality('greenpoint'), isTrue);
        expect(service.isNeighborhoodLocality('Williamsburg'), isTrue);
        expect(service.isNeighborhoodLocality('DUMBO'), isTrue);
        expect(service.isNeighborhoodLocality('Hollywood'), isTrue);
        expect(service.isNeighborhoodLocality('Shibuya'), isTrue);

        // Test rejection of non-neighborhoods
        expect(service.isNeighborhoodLocality('Smalltown'), isFalse);
        expect(service.isNeighborhoodLocality(''), isFalse);
      });
    });

    group('getParentCity', () {
      test(
          'should return correct parent city for neighborhoods or null for non-neighborhoods',
          () {
        // Test business logic: parent city lookup with null handling
        expect(service.getParentCity('Greenpoint'), equals('Brooklyn'));
        expect(service.getParentCity('Williamsburg'), equals('Brooklyn'));
        expect(service.getParentCity('DUMBO'), equals('Brooklyn'));
        expect(service.getParentCity('Hollywood'), equals('Los Angeles'));
        expect(service.getParentCity('Shibuya'), equals('Tokyo'));

        // Test null cases
        expect(service.getParentCity('Smalltown'), isNull);
        expect(service.getParentCity(''), isNull);
      });
    });

    group('getCityConfig', () {
      test(
          'should return config for large cities with correct properties or null for non-large cities',
          () {
        // Test business logic: city config retrieval with validation
        final brooklynConfig = service.getCityConfig('Brooklyn');
        expect(brooklynConfig, isNotNull);
        expect(brooklynConfig?.cityName, equals('Brooklyn'));
        expect(brooklynConfig?.neighborhoods, isNotEmpty);
        expect(brooklynConfig?.population, greaterThan(0));
        expect(brooklynConfig?.geographicSize, greaterThan(0));

        final laConfig = service.getCityConfig('Los Angeles');
        expect(laConfig, isNotNull);
        expect(laConfig?.cityName, equals('Los Angeles'));

        // Test null case
        expect(service.getCityConfig('Smalltown'), isNull);
      });
    });

    group('getAllLargeCities', () {
      test('should return list of all large cities', () {
        final cities = service.getAllLargeCities();

        expect(cities, isNotEmpty);
        expect(cities, contains('Brooklyn'));
        expect(cities, contains('Los Angeles'));
        expect(cities, contains('Chicago'));
        expect(cities, contains('Tokyo'));
        expect(cities, contains('Seoul'));
        expect(cities, contains('Paris'));
        expect(cities, contains('Madrid'));
        expect(cities, contains('Lagos'));
      });
    });

    group('LargeCityConfig', () {
      test('should meet large city criteria for all large cities', () {
        // Test business logic: criteria validation
        expect(
            service.getCityConfig('Brooklyn')?.meetsLargeCityCriteria, isTrue);
        expect(service.getCityConfig('Los Angeles')?.meetsLargeCityCriteria,
            isTrue);
        expect(service.getCityConfig('Tokyo')?.meetsLargeCityCriteria, isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
