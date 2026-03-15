import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class NoaaWeatherReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  NoaaWeatherReplaySourcePuller({
    http.Client? client,
    this.userAgent = 'AVRAI-BHAM-Replay/1.0 (admin@avrai.local)',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String userAgent;

  @override
  String get pullerId => 'noaa_weather_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'NWS / NOAA Weather API';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoint = plan.endpointRef ?? plan.sourceUrl;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('NOAA pull plan requires an endpoint.');
    }
    final uri = _buildUri(endpoint);
    final response = await _client.get(
      uri,
      headers: <String, String>{
        'accept': 'application/geo+json, application/json',
        'user-agent': userAgent,
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'NOAA weather pull failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return ReplaySourceDataset(
        sourceName: plan.sourceName,
        metadata: <String, dynamic>{
          'pullerId': pullerId,
          'uri': uri.toString(),
          'recordCount': 0,
        },
      );
    }

    final features = (decoded['features'] as List?)
            ?.whereType<Map>()
            .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
            .toList() ??
        const <Map<String, dynamic>>[];
    final records = <Map<String, dynamic>>[];

    for (final feature in features) {
      final properties = Map<String, dynamic>.from(
        feature['properties'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      );
      final alertId = feature['id']?.toString() ??
          properties['id']?.toString() ??
          'noaa-${records.length}';
      final locality = (properties['areaDesc']?.toString() ?? 'Birmingham Metro')
          .split(';')
          .first
          .trim();

      records.add(<String, dynamic>{
        'record_id': alertId,
        'event_id': alertId,
        'name': properties['headline']?.toString() ??
            properties['event']?.toString() ??
            'NOAA Alert',
        'entity_id': properties['affectedZones'] is List &&
                (properties['affectedZones'] as List).isNotEmpty
            ? '${(properties['affectedZones'] as List).first}'
            : alertId,
        'entity_type': 'environmental_signal',
        'locality': locality,
        'metric_value': properties['severity']?.toString() ?? 'unknown',
        'unit': 'alert',
        'observed_at': properties['onset']?.toString() ??
            properties['sent']?.toString(),
        'published_at': properties['sent']?.toString(),
        'valid_from': properties['effective']?.toString() ??
            properties['onset']?.toString(),
        'valid_to': properties['ends']?.toString() ??
            properties['expires']?.toString(),
        'urgency': properties['urgency'],
        'certainty': properties['certainty'],
        'severity': properties['severity'],
        'event': properties['event'],
      });
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': uri.toString(),
        'recordCount': records.length,
        'coverageStatus': 'current_state_calibration',
        'historicalReplayReady': false,
      },
    );
  }

  Uri _buildUri(String endpoint) {
    final baseUri = Uri.parse(endpoint);
    final path = baseUri.path.isEmpty
        ? '/alerts'
        : (baseUri.path.endsWith('/alerts') ? baseUri.path : '${baseUri.path}/alerts');
    final queryParameters = <String, String>{
      ...baseUri.queryParameters,
      if (!baseUri.queryParameters.containsKey('area')) 'area': 'AL',
    };
    return baseUri.replace(path: path, queryParameters: queryParameters);
  }
}
