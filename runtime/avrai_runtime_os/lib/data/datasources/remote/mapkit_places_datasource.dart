import 'dart:developer' as developer;

import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/places/mapkit_search_channel.dart';
import 'package:avrai_runtime_os/data/datasources/remote/places_datasource.dart';

import 'package:avrai_runtime_os/services/places/mapkit_places_cache_service.dart';

/// MapKit MKLocalSearch implementation of [PlacesDataSource] for macOS.
///
/// Uses [MapKitSearchChannel] (MKLocalSearch) and [MapKitPlacesCacheService]
/// for offline. Spot mapping: [metadata][source]=apple_places, [createdBy]=
/// apple_places_api, [googlePlaceId]=null.
class MapKitPlacesDataSource implements PlacesDataSource {
  static const String _logName = 'MapKitPlacesDataSource';

  final MapKitSearchChannel _channel;
  final MapKitPlacesCacheService? _cache;

  MapKitPlacesDataSource({
    MapKitSearchChannel? channel,
    MapKitPlacesCacheService? cache,
  })  : _channel = channel ?? MapKitSearchChannel(),
        _cache = cache;

  @override
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      developer.log('Searching places (MapKit): $query', name: _logName);
      final q = type != null && type.isNotEmpty ? '$type $query' : query;
      final items = await _channel.search(
        q,
        lat: latitude,
        lon: longitude,
        radius: radius.toDouble(),
      );
      final spots = items.map(_itemToSpot).toList();
      if (_cache != null && spots.isNotEmpty) {
        await _cache.cachePlaces(spots);
      }
      developer.log('Found ${spots.length} places for: $query', name: _logName);
      return spots;
    } catch (e, st) {
      developer.log('Error searching places: $e',
          name: _logName, stackTrace: st);
      return [];
    }
  }

  @override
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      developer.log(
        'Searching nearby (MapKit): $latitude,$longitude',
        name: _logName,
      );
      final items = await _channel.searchNearby(
        latitude,
        longitude,
        radius: radius.toDouble(),
        type: type,
      );
      final spots = items.map(_itemToSpot).toList();
      if (_cache != null && spots.isNotEmpty) {
        await _cache.cachePlaces(spots);
      }
      developer.log('Found ${spots.length} nearby places', name: _logName);
      return spots;
    } catch (e, st) {
      developer.log(
        'Error searching nearby: $e',
        name: _logName,
        stackTrace: st,
      );
      return [];
    }
  }

  Spot _itemToSpot(Map<String, dynamic> item) {
    final name = (item['name'] as String?) ?? '';
    final lat = (item['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (item['longitude'] as num?)?.toDouble() ?? 0.0;
    final ident =
        (item['identifier'] as String?) ?? '${lat}_${lon}_${name.hashCode}';
    final id = 'apple_$ident';

    return Spot(
      id: id,
      name: name,
      description: (item['address'] as String?) ?? '',
      latitude: lat,
      longitude: lon,
      category: 'Other',
      rating: 0.0,
      createdBy: 'apple_places_api',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      address: item['address'] as String?,
      phoneNumber: item['phoneNumber'] as String?,
      website: item['url'] as String?,
      tags: const ['external_data', 'apple_places'],
      metadata: {
        'source': 'apple_places',
        'is_external': true,
        'apple_place_id': ident,
      },
      googlePlaceId: null,
      googlePlaceIdSyncedAt: null,
    );
  }
}
