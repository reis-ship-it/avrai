import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// Method channel for MapKit MKLocalSearch on Apple platforms (iOS and macOS).
///
/// Used by [MapKitPlacesDataSource] for [search] and [searchNearby].
/// Only functional on Apple platforms; calling on other platforms will throw.
const String _channelName = 'avrai/mapkit_search';

class MapKitSearchChannel {
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// Search for places by natural language query.
  ///
  /// [query] – e.g. "coffee", "restaurant in Brooklyn".
  /// [lat], [lon], [radius] – optional region to bias results (meters).
  ///
  /// Returns a list of map items with: name, latitude, longitude, address?,
  /// phoneNumber?, url?, identifier.
  Future<List<Map<String, dynamic>>> search(
    String query, {
    double? lat,
    double? lon,
    double radius = 5000.0,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError(
          'MapKit search is only supported on Apple platforms');
    }
    final args = <String, dynamic>{
      'query': query,
      'radius': radius,
    };
    if (lat != null) args['lat'] = lat;
    if (lon != null) args['lon'] = lon;

    final dynamic raw = await _channel.invokeMethod<dynamic>('search', args);
    if (raw == null) return [];
    final list = raw as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<dynamic, dynamic>).map(
              (k, v) => MapEntry(k as String, v),
            ))
        .toList();
  }

  /// Search for places near a point (e.g. "restaurant", "cafe").
  ///
  /// [type] – naturalLanguageQuery, e.g. "restaurant", "point of interest".
  Future<List<Map<String, dynamic>>> searchNearby(
    double lat,
    double lon, {
    double radius = 5000.0,
    String? type,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError(
          'MapKit search is only supported on Apple platforms');
    }
    final args = <String, dynamic>{
      'lat': lat,
      'lon': lon,
      'radius': radius,
    };
    if (type != null && type.isNotEmpty) args['type'] = type;

    final dynamic raw =
        await _channel.invokeMethod<dynamic>('searchNearby', args);
    if (raw == null) return [];
    final list = raw as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<dynamic, dynamic>).map(
              (k, v) => MapEntry(k as String, v),
            ))
        .toList();
  }
}
