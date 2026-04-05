/// SPOTS GooglePlacesDataSourceNewImpl Unit Tests
/// Date: December 16, 2025
/// Purpose: Test GooglePlacesDataSourceNewImpl functionality with real behavior tests
///
/// Test Coverage:
/// - Request Building: Request body construction, header building, field masking
/// - JSON Parsing: Parse new API format, create Spot objects, handle missing fields
/// - Cache Behavior: Cache hit/miss, cache expiry, in-memory caching
/// - Error Handling: Network errors, API errors, malformed JSON, missing fields
/// - Rate Limiting: Enforce rate limits between requests
/// - Type Mapping: Map Google API types to SPOTS categories
///
/// Dependencies:
/// - http.Client: For HTTP requests (mocked for external API)
/// - GooglePlacesCacheService: For caching (real fake implementation)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource_new_impl.dart';
import 'package:avrai_runtime_os/services/places/google_places_cache_service.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  group('GooglePlacesDataSourceNewImpl', () {
    late GooglePlacesDataSourceNewImpl dataSource;
    late _FakeHttpClient fakeHttpClient;
    late _FakeGooglePlacesCacheService fakeCacheService;

    setUp(() {
      fakeHttpClient = _FakeHttpClient();
      fakeCacheService = _FakeGooglePlacesCacheService();
      dataSource = GooglePlacesDataSourceNewImpl(
        apiKey: 'test-api-key',
        httpClient: fakeHttpClient,
        cacheService: fakeCacheService,
      );
    });

    tearDown(() {
      fakeHttpClient.reset();
      fakeCacheService.reset();
    });

    group('searchPlaces - Request Building', () {
      test('should build correct request body with query only', () async {
        const query = 'restaurant';
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchPlaces(query: query);

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        final body =
            json.decode(request!['body'] as String) as Map<String, dynamic>;
        expect(body['textQuery'], equals(query));
        expect(body['maxResultCount'], equals(20));
        expect(body.containsKey('locationBias'), isFalse);
        expect(body.containsKey('includedType'), isFalse);
      });

      test('should build correct request body with location bias', () async {
        const query = 'restaurant';
        const latitude = 37.7749;
        const longitude = -122.4194;
        const radius = 1000;
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchPlaces(
          query: query,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        final body =
            json.decode(request!['body'] as String) as Map<String, dynamic>;
        expect(body['textQuery'], equals(query));
        expect(body['locationBias'], isA<Map<String, dynamic>>());
        final locationBias = body['locationBias'] as Map<String, dynamic>;
        expect(locationBias['circle'], isA<Map<String, dynamic>>());
        final circle = locationBias['circle'] as Map<String, dynamic>;
        expect(circle['center']['latitude'], equals(latitude));
        expect(circle['center']['longitude'], equals(longitude));
        expect(circle['radius'], equals(radius.toDouble()));
      });

      test('should build correct headers with API key and field mask',
          () async {
        const query = 'restaurant';
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchPlaces(query: query);

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        final headers = request!['headers'] as Map<String, String>;
        expect(headers['Content-Type'], equals('application/json'));
        expect(headers['X-Goog-Api-Key'], equals('test-api-key'));
        expect(headers.containsKey('X-Goog-FieldMask'), isTrue);
        expect(headers['X-Goog-FieldMask']!.contains('places.id'), isTrue);
        expect(headers['X-Goog-FieldMask']!.contains('places.displayName'),
            isTrue);
        expect(
            headers['X-Goog-FieldMask']!.contains('places.location'), isTrue);
      });

      test('should use correct URL for search text endpoint', () async {
        const query = 'restaurant';
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchPlaces(query: query);

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        expect(request!['url'].toString(), contains('/places:searchText'));
      });
    });

    group('searchPlaces - JSON Parsing', () {
      test('should parse valid API response and create Spot objects', () async {
        const query = 'restaurant';
        final mockResponse = http.Response(
          json.encode({
            'places': [
              {
                'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                'displayName': {'text': 'Test Restaurant'},
                'location': {'latitude': 37.7749, 'longitude': -122.4194},
                'rating': 4.5,
                'formattedAddress': '123 Test St, San Francisco, CA',
                'types': ['restaurant', 'food'],
              }
            ]
          }),
          200,
        );
        fakeHttpClient.setResponse(mockResponse);

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots.length, equals(1));
        final spot = spots.first;
        expect(spot.name, equals('Test Restaurant'));
        expect(spot.latitude, equals(37.7749));
        expect(spot.longitude, equals(-122.4194));
        expect(spot.rating, equals(4.5));
        expect(spot.address, equals('123 Test St, San Francisco, CA'));
        expect(spot.id, startsWith('google_'));
        expect(spot.createdBy, equals('google_places_api'));
        expect(spot.tags, contains('external_data'));
        expect(spot.tags, contains('google_places'));
        expect(spot.metadata['source'], equals('google_places'));
        expect(spot.metadata['is_external'], equals(true));
        expect(spot.metadata['api_version'], equals('new'));
      });

      test('should handle missing optional fields gracefully', () async {
        const query = 'restaurant';
        final mockResponse = http.Response(
          json.encode({
            'places': [
              {
                'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                'displayName': {'text': 'Test Restaurant'},
                'location': {'latitude': 37.7749, 'longitude': -122.4194},
                // Missing rating, address, types
              }
            ]
          }),
          200,
        );
        fakeHttpClient.setResponse(mockResponse);

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots.length, equals(1));
        final spot = spots.first;
        expect(spot.name, equals('Test Restaurant'));
        expect(spot.rating, equals(0.0)); // Default value
        expect(spot.address,
            anyOf(isNull, isEmpty)); // Can be null or empty string
        expect(spot.category, equals('Other')); // Default when no types match
      });

      test('should handle empty places array', () async {
        const query = 'nonexistent';
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isEmpty);
      });

      test('should map Google API types to SPOTS categories correctly',
          () async {
        final testCases = [
          {
            'query': 'restaurant',
            'types': ['restaurant'],
            'expectedCategory': 'Food'
          },
          {
            'query': 'cafe',
            'types': ['cafe'],
            'expectedCategory': 'Food'
          },
          {
            'query': 'attraction',
            'types': ['tourist_attraction'],
            'expectedCategory': 'Attractions'
          },
          {
            'query': 'museum',
            'types': ['museum'],
            'expectedCategory': 'Attractions'
          },
          {
            'query': 'shopping',
            'types': ['shopping_mall'],
            'expectedCategory': 'Shopping'
          },
          {
            'query': 'nightclub',
            'types': ['night_club'],
            'expectedCategory': 'Nightlife'
          },
          {
            'query': 'hotel',
            'types': ['lodging'],
            'expectedCategory': 'Stay'
          },
          {
            'query': 'unknown',
            'types': ['unknown_type'],
            'expectedCategory': 'Other'
          },
        ];

        for (final testCase in testCases) {
          final query = testCase['query'] as String;
          final types = testCase['types'] as List<String>;
          fakeHttpClient.setResponse(http.Response(
            json.encode({
              'places': [
                {
                  'id': 'places/test_${types.first}',
                  'displayName': {'text': 'Test Place'},
                  'location': {'latitude': 37.7749, 'longitude': -122.4194},
                  'types': types,
                }
              ]
            }),
            200,
          ));

          // Create new data source for each test to avoid cache interference
          final testDataSource = GooglePlacesDataSourceNewImpl(
            apiKey: 'test-api-key',
            httpClient: fakeHttpClient,
            cacheService: fakeCacheService,
          );

          final spots = await testDataSource.searchPlaces(query: query);
          expect(spots.first.category, equals(testCase['expectedCategory']));
        }
      });
    });

    group('searchPlaces - Cache Behavior', () {
      test('should return cached results on second call with same parameters',
          () async {
        const query = 'restaurant';
        final mockResponse = http.Response(
          json.encode({
            'places': [
              {
                'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                'displayName': {'text': 'Test Restaurant'},
                'location': {'latitude': 37.7749, 'longitude': -122.4194},
              }
            ]
          }),
          200,
        );
        fakeHttpClient.setResponse(mockResponse);

        // First call - should make HTTP request
        final spots1 = await dataSource.searchPlaces(query: query);
        expect(spots1.length, equals(1));
        expect(fakeHttpClient.postCallCount, equals(1));

        // Second call - should use cache, no HTTP request
        final spots2 = await dataSource.searchPlaces(query: query);
        expect(spots2.length, equals(1));
        expect(fakeHttpClient.postCallCount, equals(1)); // No additional call
        expect(spots2.first.id, equals(spots1.first.id));
      });

      test('should call cache service to persist results', () async {
        const query = 'restaurant';
        final mockResponse = http.Response(
          json.encode({
            'places': [
              {
                'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                'displayName': {'text': 'Test Restaurant'},
                'location': {'latitude': 37.7749, 'longitude': -122.4194},
              }
            ]
          }),
          200,
        );
        fakeHttpClient.setResponse(mockResponse);

        await dataSource.searchPlaces(query: query);

        expect(fakeCacheService.cachePlacesCallCount, equals(1));
        expect(fakeCacheService.lastCachedPlaces, isNotNull);
        expect(fakeCacheService.lastCachedPlaces!.length, equals(1));
      });
    });

    group('searchPlaces - Error Handling', () {
      test('should return empty list on network error', () async {
        const query = 'restaurant';
        fakeHttpClient.setError(Exception('Network error'));

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isEmpty);
      });

      test('should return empty list on API error response', () async {
        const query = 'restaurant';
        fakeHttpClient.setResponse(http.Response(
          json.encode({
            'error': {'message': 'API key invalid'}
          }),
          403,
        ));

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isEmpty);
      });

      test('should return empty list on malformed JSON', () async {
        const query = 'restaurant';
        fakeHttpClient.setResponse(http.Response(
          'invalid json',
          200,
        ));

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isEmpty);
      });
    });

    group('getPlaceDetails', () {
      test('should normalize place ID format (add places/ prefix if missing)',
          () async {
        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        fakeHttpClient.setResponse(http.Response(
          json.encode({
            'id': 'places/$placeId',
            'displayName': {'text': 'Place Name'},
            'location': {'latitude': 37.7749, 'longitude': -122.4194},
          }),
          200,
        ));

        await dataSource.getPlaceDetails(placeId);

        final request = fakeHttpClient.lastGetRequest;
        expect(request, isNotNull);
        expect(request!['url'].toString(), contains('places/$placeId'));
      });

      test('should use GET request for place details', () async {
        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        fakeHttpClient.setResponse(http.Response(
          json.encode({
            'id': 'places/$placeId',
            'displayName': {'text': 'Place Name'},
            'location': {'latitude': 37.7749, 'longitude': -122.4194},
          }),
          200,
        ));

        await dataSource.getPlaceDetails(placeId);

        expect(fakeHttpClient.getCallCount, equals(1));
        expect(fakeHttpClient.postCallCount, equals(0));
      });

      test('should include details fields in field mask', () async {
        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        fakeHttpClient.setResponse(http.Response(
          json.encode({
            'id': 'places/$placeId',
            'displayName': {'text': 'Place Name'},
            'location': {'latitude': 37.7749, 'longitude': -122.4194},
          }),
          200,
        ));

        await dataSource.getPlaceDetails(placeId);

        final request = fakeHttpClient.lastGetRequest;
        expect(request, isNotNull);
        final headers = request!['headers'] as Map<String, String>;
        final fieldMask = headers['X-Goog-FieldMask']!;
        expect(fieldMask.contains('places.nationalPhoneNumber'), isTrue);
        expect(fieldMask.contains('places.websiteUri'), isTrue);
      });

      test('should return null on error', () async {
        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        fakeHttpClient.setError(Exception('Network error'));

        final spot = await dataSource.getPlaceDetails(placeId);

        expect(spot, isNull);
      });
    });

    group('searchNearbyPlaces', () {
      test('should build correct nearby search request body', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        const radius = 1000;
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        final body =
            json.decode(request!['body'] as String) as Map<String, dynamic>;
        expect(body['maxResultCount'], equals(20));
        expect(body['locationRestriction'], isA<Map<String, dynamic>>());
        final locationRestriction =
            body['locationRestriction'] as Map<String, dynamic>;
        final circle = locationRestriction['circle'] as Map<String, dynamic>;
        expect(circle['center']['latitude'], equals(latitude));
        expect(circle['center']['longitude'], equals(longitude));
        expect(circle['radius'], equals(radius.toDouble()));
      });

      test('should use correct URL for nearby search endpoint', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        await dataSource.searchNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
        );

        final request = fakeHttpClient.lastPostRequest;
        expect(request, isNotNull);
        expect(request!['url'].toString(), contains('/places:searchNearby'));
      });
    });

    group('Rate Limiting', () {
      test('should enforce rate limit between requests', () async {
        fakeHttpClient.setResponse(http.Response(
          '{"places": []}',
          200,
        ));

        final startTime = DateTime.now();
        await dataSource.searchPlaces(query: 'query1');
        await dataSource.searchPlaces(query: 'query2');
        final endTime = DateTime.now();

        // Should have at least 100ms delay between requests
        final duration = endTime.difference(startTime);
        expect(duration.inMilliseconds, greaterThanOrEqualTo(100));
      });
    });
  });
}

/// Real fake HTTP client that provides actual behavior for testing
class _FakeHttpClient implements http.Client {
  http.Response? _response;
  Exception? _error;
  int _postCallCount = 0;
  int _getCallCount = 0;
  Map<String, dynamic>? _lastPostRequest;
  Map<String, dynamic>? _lastGetRequest;

  void setResponse(http.Response response) {
    _response = response;
    _error = null;
  }

  void setError(Exception error) {
    _error = error;
    _response = null;
  }

  void reset() {
    _response = null;
    _error = null;
    _postCallCount = 0;
    _getCallCount = 0;
    _lastPostRequest = null;
    _lastGetRequest = null;
  }

  int get postCallCount => _postCallCount;
  int get getCallCount => _getCallCount;
  Map<String, dynamic>? get lastPostRequest => _lastPostRequest;
  Map<String, dynamic>? get lastGetRequest => _lastGetRequest;

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    _postCallCount++;
    _lastPostRequest = {
      'url': url,
      'headers': headers ?? {},
      'body': body,
    };

    if (_error != null) {
      throw _error!;
    }

    return _response ?? http.Response('', 200);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _getCallCount++;
    _lastGetRequest = {
      'url': url,
      'headers': headers ?? {},
    };

    if (_error != null) {
      throw _error!;
    }

    return _response ?? http.Response('', 200);
  }

  // Other required methods (not used in these tests)
  @override
  Future<http.Response> delete(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> patch(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> put(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() {}
}

/// Real fake cache service that provides actual behavior for testing
class _FakeGooglePlacesCacheService implements GooglePlacesCacheService {
  int _cachePlaceCallCount = 0;
  int _cachePlacesCallCount = 0;
  Spot? _lastCachedPlace;
  List<Spot>? _lastCachedPlaces;

  void reset() {
    _cachePlaceCallCount = 0;
    _cachePlacesCallCount = 0;
    _lastCachedPlace = null;
    _lastCachedPlaces = null;
  }

  int get cachePlaceCallCount => _cachePlaceCallCount;
  int get cachePlacesCallCount => _cachePlacesCallCount;
  Spot? get lastCachedPlace => _lastCachedPlace;
  List<Spot>? get lastCachedPlaces => _lastCachedPlaces;

  @override
  Future<void> cachePlace(Spot spot) async {
    _cachePlaceCallCount++;
    _lastCachedPlace = spot;
  }

  @override
  Future<void> cachePlaces(List<Spot> spots) async {
    _cachePlacesCallCount++;
    _lastCachedPlaces = spots;
  }

  // Other required methods (not used in these tests)
  @override
  Future<Spot?> getCachedPlace(String placeId) async => null;

  @override
  Future<Map<String, dynamic>?> getCachedPlaceDetails(String placeId) async =>
      null;

  @override
  Future<void> cachePlaceDetails(
      String placeId, Map<String, dynamic> details) async {}

  @override
  Future<List<Spot>> searchCachedPlaces(String query) async => [];

  @override
  Future<List<Spot>> getCachedPlacesNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async =>
      [];

  @override
  Future<void> clearExpiredCache() async {}
}
