import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_geo_context_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../mocks/mock_storage_service.dart';

class _FakeGeoHierarchyService extends GeoHierarchyService {
  final ({String localityCode, String cityCode, String displayName})? result;

  _FakeGeoHierarchyService({required this.result}) : super();

  @override
  Future<({String localityCode, String cityCode, String displayName})?>
      lookupLocalityByPoint({
    required double lat,
    required double lon,
  }) async {
    return result;
  }
}

void main() {
  group('OnboardingGeoContextService', () {
    setUp(() {
      MockGetStorage.reset();
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    test(
        'resolves cached homebase coordinates and geo hierarchy locality codes (best-effort)',
        () async {
      // Arrange: cached lat/lon exist, and geo hierarchy can resolve a locality.
      final storage = MockGetStorage.getInstance(boxName: 'geo_context_box');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      await prefs.setDouble('cached_lat', 40.7128);
      await prefs.setDouble('cached_lng', -74.0060);

      final geo = _FakeGeoHierarchyService(
        result: (
          localityCode: 'nyc_manhattan',
          cityCode: 'nyc',
          displayName: 'Manhattan, NY',
        ),
      );

      final service = OnboardingGeoContextService(
        geoHierarchyService: geo,
        prefs: prefs,
      );

      // Act
      final ctx = await service.resolveHomebaseGeoContextBestEffort();

      // Assert: behavior-focused (geo context is usable + carries codes).
      expect(ctx.hasCoordinates, isTrue);
      expect(ctx.latitude, closeTo(40.7128, 1e-6));
      expect(ctx.longitude, closeTo(-74.0060, 1e-6));
      expect(ctx.cityCode, equals('nyc'));
      expect(ctx.localityCode, equals('nyc_manhattan'));
      expect(ctx.displayName, equals('Manhattan, NY'));
    });

    test('returns empty context when cached homebase coordinates are missing',
        () async {
      // Arrange: no cached_lat/cached_lng.
      final storage = MockGetStorage.getInstance(boxName: 'geo_context_box_2');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

      final geo = _FakeGeoHierarchyService(result: null);
      final service = OnboardingGeoContextService(
        geoHierarchyService: geo,
        prefs: prefs,
      );

      // Act
      final ctx = await service.resolveHomebaseGeoContextBestEffort();

      // Assert
      expect(ctx.hasCoordinates, isFalse);
      expect(ctx.toJson(), containsPair('homebaseLat', null));
      expect(ctx.toJson(), containsPair('homebaseLon', null));
    });
  });
}
