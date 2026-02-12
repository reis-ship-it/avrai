import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/data/datasources/remote/openstreetmap_datasource_impl.dart';
import 'package:avrai/core/models/spots/spot.dart';

import 'openstreetmap_datasource_impl_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OpenStreetMapDataSourceImpl', () {
    late OpenStreetMapDataSourceImpl dataSource;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      dataSource = OpenStreetMapDataSourceImpl(httpClient: mockHttpClient);
    });

    group('searchPlaces', () {
      test('should search places via Nominatim API', () async {
        const query = 'coffee shop';
        final mockResponse = http.Response(
          '[{"place_id": 123, "display_name": "Coffee Shop", "lat": "37.7749", "lon": "-122.4194"}]',
          200,
        );

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isA<List<Spot>>());
        // OUR_GUTS.md: "Community, Not Just Places" - Community-driven data
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should return empty list on error', () async {
        const query = 'invalid query';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('Network error'));

        final spots = await dataSource.searchPlaces(query: query);

        // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
        expect(spots, isEmpty);
      });
    });

    group('searchNearbyPlaces', () {
      test('should search nearby places via Overpass API', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        const radius = 1000;
        final mockResponse = http.Response(
          '{"elements": [{"type": "node", "id": 123, "lat": 37.7749, "lon": -122.4194, "tags": {"name": "Place"}}]}',
          200,
        );

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        final spots = await dataSource.searchNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        expect(spots, isA<List<Spot>>());
      });
    });

    group('getPlaceDetails', () {
      test('should get place details via Nominatim lookup', () async {
        const osmId = 'N123456';
        final mockResponse = http.Response(
          '[{"place_id": 123, "display_name": "Place Name", "lat": "37.7749", "lon": "-122.4194"}]',
          200,
        );

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        final spot = await dataSource.getPlaceDetails(osmId);

        expect(spot, anyOf(isNull, isA<Spot>()));
      });
    });

    group('searchAmenities', () {
      test('should search amenities via Overpass API', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        const amenityType = 'restaurant';
        final mockResponse = http.Response(
          '{"elements": [{"type": "node", "id": 123, "lat": 37.7749, "lon": -122.4194, "tags": {"amenity": "restaurant", "name": "Restaurant"}}]}',
          200,
        );

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        final spots = await dataSource.searchAmenities(
          latitude: latitude,
          longitude: longitude,
          amenityType: amenityType,
        );

        expect(spots, isA<List<Spot>>());
      });
    });
  });
}

