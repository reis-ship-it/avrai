import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class CensusAcsReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  CensusAcsReplaySourcePuller({
    http.Client? client,
    this.apiKey,
    this.stateFips = '01',
    this.countyFips = '073',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? apiKey;
  final String stateFips;
  final String countyFips;

  @override
  String get pullerId => 'census_acs_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'U.S. Census ACS';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoint = plan.endpointRef ?? plan.sourceUrl;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('Census ACS pull plan requires an endpoint.');
    }

    final uri = _buildUri(endpoint);
    final response = await _client.get(
      uri,
      headers: const <String, String>{'accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Census ACS pull failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return ReplaySourceDataset(
        sourceName: plan.sourceName,
        metadata: <String, dynamic>{
          'pullerId': pullerId,
          'uri': uri.toString(),
          'recordCount': 0,
        },
      );
    }

    final headers = (decoded.first as List).map((entry) => '$entry').toList();
    final rows = decoded.skip(1).whereType<List>();
    final records = <Map<String, dynamic>>[];

    for (final row in rows) {
      final rowMap = <String, String>{};
      for (var index = 0; index < headers.length && index < row.length; index++) {
        rowMap[headers[index]] = '${row[index]}';
      }

      final tractId = rowMap['tract'];
      if (tractId == null || tractId.isEmpty) {
        continue;
      }
      final locality = rowMap['NAME'] ?? 'tract:$tractId';
      final observedAt = DateTime.utc(plan.replayYear, 7, 1).toIso8601String();
      final publishedAt = DateTime.utc(plan.replayYear + 1, 1, 15)
          .toIso8601String();

      final population = int.tryParse(rowMap['B01001_001E'] ?? '');
      if (population != null) {
        records.add(<String, dynamic>{
          'record_id': 'acs-${plan.replayYear}-$tractId-population',
          'series_key': 'population_total',
          'name': locality,
          'entity_id': 'tract:$tractId',
          'entity_type': 'population_cohort',
          'locality': locality,
          'metric_value': population,
          'unit': 'people',
          'observed_at': observedAt,
          'published_at': publishedAt,
          'state_fips': rowMap['state'],
          'county_fips': rowMap['county'],
          'tract_id': tractId,
        });
      }

      final housingUnits = int.tryParse(rowMap['B25001_001E'] ?? '');
      if (housingUnits != null) {
        records.add(<String, dynamic>{
          'record_id': 'acs-${plan.replayYear}-$tractId-housing',
          'series_key': 'housing_units',
          'name': locality,
          'entity_id': 'tract:$tractId',
          'entity_type': 'housing_signal',
          'locality': locality,
          'metric_value': housingUnits,
          'unit': 'units',
          'observed_at': observedAt,
          'published_at': publishedAt,
          'state_fips': rowMap['state'],
          'county_fips': rowMap['county'],
          'tract_id': tractId,
        });
      }
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': uri.toString(),
        'recordCount': records.length,
        'coverageStatus': 'historical_replay_series',
        'historicalReplayReady': true,
      },
    );
  }

  Uri _buildUri(String endpoint) {
    final baseUri = Uri.parse(endpoint);
    final queryParameters = <String, String>{
      ...baseUri.queryParameters,
      'get': 'NAME,B01001_001E,B25001_001E',
      'for': 'tract:*',
      'in': 'state:$stateFips county:$countyFips',
    };
    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      queryParameters['key'] = apiKey!.trim();
    }
    return baseUri.replace(queryParameters: queryParameters);
  }
}
