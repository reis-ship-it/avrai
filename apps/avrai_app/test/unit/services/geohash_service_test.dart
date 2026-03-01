import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';

void main() {
  group('GeohashService', () {
    test('encode+decodeBoundingBox: bounding box contains original point', () {
      // Arrange: any real-world coordinate.
      const lat = 40.7128;
      const lon = -74.0060;

      // Act
      final gh = GeohashService.encode(
        latitude: lat,
        longitude: lon,
        precision: 7,
      );
      final bbox = GeohashService.decodeBoundingBox(gh);

      // Assert (behavior): decoding should produce a bounding box that contains
      // the encoded coordinate.
      expect(gh, hasLength(7));
      expect(bbox.contains(latitude: lat, longitude: lon), isTrue);
      expect(bbox.latSpan, greaterThan(0));
      expect(bbox.lonSpan, greaterThan(0));
    });

    test('neighbors returns 8 unique adjacent geohash prefixes', () {
      // Arrange
      final gh = GeohashService.encode(
        latitude: 40.7128,
        longitude: -74.0060,
        precision: 7,
      );

      // Act
      final neighbors = GeohashService.neighbors(geohash: gh);

      // Assert (behavior): exactly 8 distinct neighbor cells at same precision.
      expect(neighbors.length, equals(8));
      expect(neighbors.toSet().length, equals(8));
      for (final n in neighbors) {
        expect(n, hasLength(gh.length));
      }
    });
  });
}
