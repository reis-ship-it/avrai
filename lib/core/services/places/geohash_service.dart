import 'dart:math' as math;

/// Geohash utilities (v1)
///
/// This is a small, dependency-free geohash implementation used for:
/// - stable LocalityAgent identity keys (geohash prefix @ precision)
/// - neighbor smoothing across surrounding areas
///
/// Notes:
/// - This is **not** a user-facing geocoding system.
/// - Precision typically used by locality packs is ~5–7; LocalityAgents default to 7.
class GeohashService {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode a latitude/longitude to a geohash string at [precision] characters.
  ///
  /// Throws [RangeError] if inputs are out of range.
  static String encode({
    required double latitude,
    required double longitude,
    required int precision,
  }) {
    if (precision <= 0) {
      throw ArgumentError.value(precision, 'precision', 'must be > 0');
    }
    if (latitude < -90 || latitude > 90) {
      throw RangeError.range(latitude, -90, 90, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw RangeError.range(longitude, -180, 180, 'longitude');
    }

    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;

    final buffer = StringBuffer();
    var isEvenBit = true;
    var bit = 0;
    var ch = 0;

    while (buffer.length < precision) {
      if (isEvenBit) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          ch |= 1 << (4 - bit);
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEvenBit = !isEvenBit;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Decode a geohash to its bounding box.
  static GeohashBoundingBox decodeBoundingBox(String geohash) {
    if (geohash.isEmpty) {
      throw ArgumentError.value(geohash, 'geohash', 'must be non-empty');
    }

    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;

    var isEvenBit = true;

    for (final c in geohash.codeUnits) {
      final ch = String.fromCharCode(c);
      final idx = _base32.indexOf(ch);
      if (idx < 0) {
        throw ArgumentError.value(geohash, 'geohash', 'contains invalid char: $ch');
      }

      for (var bit = 4; bit >= 0; bit--) {
        final mask = 1 << bit;
        final on = (idx & mask) != 0;
        if (isEvenBit) {
          final mid = (lonMin + lonMax) / 2;
          if (on) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (on) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isEvenBit = !isEvenBit;
      }
    }

    return GeohashBoundingBox(
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
    );
  }

  /// Compute the 8-neighborhood geohash prefixes at the same [precision].
  ///
  /// This is used for “surrounding areas” smoothing.
  static List<String> neighbors({
    required String geohash,
  }) {
    final bbox = decodeBoundingBox(geohash);
    final center = bbox.center;
    final dLat = bbox.latSpan;
    final dLon = bbox.lonSpan;

    // Neighbor centers (N, NE, E, SE, S, SW, W, NW)
    final offsets = <({int dLat, int dLon})>[
      (dLat: 1, dLon: 0),
      (dLat: 1, dLon: 1),
      (dLat: 0, dLon: 1),
      (dLat: -1, dLon: 1),
      (dLat: -1, dLon: 0),
      (dLat: -1, dLon: -1),
      (dLat: 0, dLon: -1),
      (dLat: 1, dLon: -1),
    ];

    final precision = geohash.length;
    final out = <String>{};
    for (final o in offsets) {
      final lat = _clamp(center.lat + o.dLat * dLat, -90.0, 90.0);
      final lon = _clamp(center.lon + o.dLon * dLon, -180.0, 180.0);
      out.add(
        encode(latitude: lat, longitude: lon, precision: precision),
      );
    }
    return out.toList(growable: false);
  }

  static double _clamp(double v, double min, double max) =>
      math.min(math.max(v, min), max);
}

class GeohashBoundingBox {
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;

  const GeohashBoundingBox({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
  });

  double get latSpan => latMax - latMin;
  double get lonSpan => lonMax - lonMin;

  ({double lat, double lon}) get center => (
        lat: (latMin + latMax) / 2,
        lon: (lonMin + lonMax) / 2,
      );

  bool contains({
    required double latitude,
    required double longitude,
  }) {
    return latitude >= latMin &&
        latitude <= latMax &&
        longitude >= lonMin &&
        longitude <= lonMax;
  }
}

