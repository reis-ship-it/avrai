import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:avrai_runtime_os/simulation/models/city_profile.dart';
import 'package:http/http.dart' as http;

class OpenStreetMapReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  OpenStreetMapReplaySourcePuller({
    http.Client? client,
    CityProfile? cityProfile,
  })  : _client = client ?? http.Client(),
        _cityProfile = cityProfile ?? CityProfile.birmingham();

  final http.Client _client;
  final CityProfile _cityProfile;

  static const Set<String> _communityAmenities = <String>{
    'library',
    'community_centre',
    'place_of_worship',
    'arts_centre',
    'social_facility',
    'coworking_space',
  };

  static const Set<String> _clubAmenities = <String>{
    'nightclub',
  };

  @override
  String get pullerId => 'open_street_map_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'OpenStreetMap POI Data';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoint = plan.endpointRef ?? plan.sourceUrl;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('OpenStreetMap pull plan requires an endpoint.');
    }

    final uri = Uri.parse(endpoint);
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'content-type': 'application/x-www-form-urlencoded',
        'accept': 'application/json',
      },
      body: <String, String>{
        'data': _buildOverpassQuery(plan.replayYear),
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'OpenStreetMap Overpass pull failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return ReplaySourceDataset(
        sourceName: plan.sourceName,
        metadata: <String, dynamic>{
          'pullerId': pullerId,
          'uri': uri.toString(),
          'recordCount': 0,
          'coverageStatus': 'baseline_current_snapshot',
        },
      );
    }

    final elements = (decoded['elements'] as List?)
            ?.whereType<Map>()
            .map(
              (entry) => Map<String, dynamic>.from(
                entry.map((key, value) => MapEntry('$key', value)),
              ),
            )
            .toList() ??
        const <Map<String, dynamic>>[];

    final records = <Map<String, dynamic>>[];
    for (final element in elements) {
      final tags = Map<String, dynamic>.from(
        element['tags'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      );
      final name = tags['name']?.toString().trim();
      final lat = (element['lat'] as num?)?.toDouble();
      final lng = (element['lon'] as num?)?.toDouble();
      if (name == null || name.isEmpty || lat == null || lng == null) {
        continue;
      }

      final primaryTag = _primaryTag(tags);
      final entityType = _entityTypeFor(tags);
      final osmId = '${element['type'] ?? 'node'}:${element['id'] ?? name}';
      final observedAt = DateTime.now().toUtc().toIso8601String();

      records.add(<String, dynamic>{
        'record_id': 'osm-${osmId.replaceAll(':', '-')}',
        'feature_id': osmId,
        'entity_id': 'osm:$osmId',
        'entity_type': entityType,
        'feature_type': entityType,
        'name': name,
        'locality': _localityHintFor(lat: lat, lng: lng),
        'lat': lat,
        'lng': lng,
        'geometry': <String, dynamic>{
          'type': 'point',
          'coordinates': <double>[lng, lat],
        },
        'poi_type': primaryTag,
        'address': _addressFor(tags),
        'hours': tags['opening_hours']?.toString(),
        'observed_at': observedAt,
        'published_at': observedAt,
        'osm_id': element['id'],
        'osm_kind': element['type'],
        'amenity': tags['amenity'],
        'tourism': tags['tourism'],
        'leisure': tags['leisure'],
        'shop': tags['shop'],
        'cuisine': tags['cuisine'],
        'brand': tags['brand'],
      });
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': uri.toString(),
        'recordCount': records.length,
        'coverageStatus': 'historical_replay_snapshot',
        'historicalReplayReady': true,
        'snapshotDateUtc': _snapshotDateFor(plan.replayYear).toIso8601String(),
        'bbox': <String, double>{
          'south': _cityProfile.bounds.southEast.latitude,
          'west': _cityProfile.bounds.northWest.longitude,
          'north': _cityProfile.bounds.northWest.latitude,
          'east': _cityProfile.bounds.southEast.longitude,
        },
      },
    );
  }

  String _buildOverpassQuery(int replayYear) {
    final south = _cityProfile.bounds.southEast.latitude;
    final west = _cityProfile.bounds.northWest.longitude;
    final north = _cityProfile.bounds.northWest.latitude;
    final east = _cityProfile.bounds.southEast.longitude;
    final bbox = '$south,$west,$north,$east';
    final snapshotDate = _snapshotDateFor(replayYear).toIso8601String();

    const venueQueries = <String>[
      'node["amenity"~"restaurant|cafe|bar|pub|fast_food|ice_cream|food_court|biergarten|nightclub|cinema|theatre|casino"]',
      'node["tourism"~"museum|gallery|attraction|viewpoint|artwork|zoo|aquarium|theme_park|hotel|hostel|guest_house|motel"]',
      'node["shop"~"clothes|boutique|books|gift|art|jewelry|antiques|music|vintage|department_store|mall"]',
      'node["leisure"~"park|fitness_centre|sports_centre|swimming_pool|bowling_alley|garden|nature_reserve|playground|stadium"]',
      'node["amenity"~"library|community_centre|place_of_worship|arts_centre|social_facility|coworking_space"]',
    ];

    final queryParts = venueQueries
        .map((query) => '  $query($bbox);')
        .join('\n');
    return '[out:json][timeout:120][date:"$snapshotDate"];\n(\n$queryParts\n);\nout body;';
  }

  DateTime _snapshotDateFor(int replayYear) {
    return DateTime.utc(replayYear, 12, 31, 23, 59, 59);
  }

  String _entityTypeFor(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString();
    if (amenity != null && _clubAmenities.contains(amenity)) {
      return 'club';
    }
    if (amenity != null && _communityAmenities.contains(amenity)) {
      return 'community';
    }
    return 'venue';
  }

  String _primaryTag(Map<String, dynamic> tags) {
    for (final key in <String>['amenity', 'tourism', 'leisure', 'shop']) {
      final value = tags[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return 'unknown';
  }

  String? _addressFor(Map<String, dynamic> tags) {
    final houseNumber = tags['addr:housenumber']?.toString().trim();
    final street = tags['addr:street']?.toString().trim();
    final city = tags['addr:city']?.toString().trim();
    final parts = <String>[
      if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
      if (street != null && street.isNotEmpty) street,
      if (city != null && city.isNotEmpty) city,
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }

  String _localityHintFor({
    required double lat,
    required double lng,
  }) {
    if (lat >= 33.515 && lat <= 33.535 && lng >= -86.83 && lng <= -86.79) {
      return 'bham_downtown';
    }
    if (lat >= 33.49 && lat <= 33.515 && lng >= -86.80 && lng <= -86.77) {
      return 'bham_southside';
    }
    if (lat >= 33.515 && lat <= 33.535 && lng >= -86.79 && lng <= -86.755) {
      return 'bham_avondale';
    }
    if (lat >= 33.48 && lat <= 33.505 && lng >= -86.785 && lng <= -86.755) {
      return 'bham_lakeview';
    }
    return 'bham_metro_regional';
  }
}
