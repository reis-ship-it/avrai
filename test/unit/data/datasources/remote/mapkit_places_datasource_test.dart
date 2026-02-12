/// MapKitPlacesDataSource unit tests.
///
/// Verifies Spot mapping from MapKit MKLocalSearch-like items:
/// metadata[source]=apple_places, createdBy=apple_places_api, tags, googlePlaceId=null.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/places/mapkit_search_channel.dart';
import 'package:avrai/data/datasources/remote/mapkit_places_datasource.dart';

/// Fake [MapKitSearchChannel] that returns canned results for testing
/// without invoking the platform method channel.
class _FakeMapKitSearchChannel extends MapKitSearchChannel {
  final List<Map<String, dynamic>> searchResult;
  final List<Map<String, dynamic>> searchNearbyResult;
  Object? searchError;
  Object? searchNearbyError;

  _FakeMapKitSearchChannel({
    this.searchResult = const [],
    this.searchNearbyResult = const [],
    this.searchError,
    this.searchNearbyError,
  });

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    double? lat,
    double? lon,
    double radius = 5000.0,
  }) async {
    if (searchError != null) throw searchError!;
    return List<Map<String, dynamic>>.from(searchResult);
  }

  @override
  Future<List<Map<String, dynamic>>> searchNearby(
    double lat,
    double lon, {
    double radius = 5000.0,
    String? type,
  }) async {
    if (searchNearbyError != null) throw searchNearbyError!;
    return List<Map<String, dynamic>>.from(searchNearbyResult);
  }
}

void main() {
  group('MapKitPlacesDataSource', () {
    test('searchPlaces maps MapKit items to Spot with apple_places source and null googlePlaceId', () async {
      final channel = _FakeMapKitSearchChannel(
        searchResult: [
          {
            'name': 'Test Cafe',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'address': '123 Main St',
            'identifier': 'mk_id_1',
          },
        ],
      );

      final ds = MapKitPlacesDataSource(channel: channel, cache: null);
      final spots = await ds.searchPlaces(query: 'cafe');

      expect(spots, hasLength(1));
      final s = spots.first;
      expect(s.name, 'Test Cafe');
      expect(s.latitude, 40.7128);
      expect(s.longitude, -74.0060);
      expect(s.metadata['source'], 'apple_places');
      expect(s.createdBy, 'apple_places_api');
      expect(s.tags, contains('apple_places'));
      expect(s.tags, contains('external_data'));
      expect(s.googlePlaceId, isNull);
      expect(s.id, startsWith('apple_'));
    });

    test('searchNearbyPlaces maps MapKit items to Spot with apple_places metadata', () async {
      final channel = _FakeMapKitSearchChannel(
        searchNearbyResult: [
          {
            'name': 'Nearby Restaurant',
            'latitude': 40.72,
            'longitude': -74.01,
            'address': '456 Oak Ave',
            'identifier': 'mk_nb_1',
          },
        ],
      );

      final ds = MapKitPlacesDataSource(channel: channel, cache: null);
      final spots = await ds.searchNearbyPlaces(latitude: 40.71, longitude: -74.0);

      expect(spots, hasLength(1));
      final s = spots.first;
      expect(s.name, 'Nearby Restaurant');
      expect(s.metadata['source'], 'apple_places');
      expect(s.createdBy, 'apple_places_api');
      expect(s.googlePlaceId, isNull);
    });

    test('searchPlaces returns empty list when channel throws', () async {
      final channel = _FakeMapKitSearchChannel(
        searchResult: [],
        searchError: Exception('Platform error'),
      );

      final ds = MapKitPlacesDataSource(channel: channel, cache: null);
      final spots = await ds.searchPlaces(query: 'fail');

      expect(spots, isEmpty);
    });

    test('searchNearbyPlaces returns empty list when channel throws', () async {
      final channel = _FakeMapKitSearchChannel(
        searchNearbyError: Exception('Platform error'),
      );

      final ds = MapKitPlacesDataSource(channel: channel, cache: null);
      final spots = await ds.searchNearbyPlaces(latitude: 40.0, longitude: -74.0);

      expect(spots, isEmpty);
    });

    test('item without identifier uses fallback id from lat_lon_name hash', () async {
      final channel = _FakeMapKitSearchChannel(
        searchResult: [
          {
            'name': 'No Id Place',
            'latitude': 40.0,
            'longitude': -74.0,
          },
        ],
      );

      final ds = MapKitPlacesDataSource(channel: channel, cache: null);
      final spots = await ds.searchPlaces(query: 'x');

      expect(spots, hasLength(1));
      expect(spots.first.id, startsWith('apple_'));
      expect(spots.first.metadata['source'], 'apple_places');
      expect(spots.first.googlePlaceId, isNull);
    });
  });
}
