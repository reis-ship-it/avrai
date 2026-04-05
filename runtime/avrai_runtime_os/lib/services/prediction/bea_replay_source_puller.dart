import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class BeaReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  BeaReplaySourcePuller({
    http.Client? client,
    this.apiKey,
    this.geoFips = '01073',
    this.tableName = 'CAINC1',
    this.lineCode = '3',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String? apiKey;
  final String geoFips;
  final String tableName;
  final String lineCode;

  @override
  String get pullerId => 'bea_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'BEA / U.S. Census Bureau Economic Series';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoint = plan.endpointRef ?? plan.sourceUrl;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('BEA pull plan requires an endpoint.');
    }
    final trimmedApiKey = apiKey?.trim();
    if (trimmedApiKey == null || trimmedApiKey.isEmpty) {
      throw StateError('BEA replay pull requires a BEA API key.');
    }

    final uri = _buildUri(
      endpoint: endpoint,
      replayYear: plan.replayYear,
      apiKey: trimmedApiKey,
    );
    final response = await _client.get(
      uri,
      headers: const <String, String>{'accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw StateError('BEA pull failed with status ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final dataRows = _extractDataRows(decoded);
    final records = <Map<String, dynamic>>[];

    for (final row in dataRows) {
      final dataValue = _parseNumeric(row['DataValue']);
      if (dataValue == null) {
        continue;
      }
      final replayYear = int.tryParse('${row['TimePeriod'] ?? plan.replayYear}') ??
          plan.replayYear;
      final sourceGeoFips = '${row['GeoFips'] ?? geoFips}'.trim();
      final geoName = '${row['GeoName'] ?? 'Jefferson County, Alabama'}'.trim();
      final description = '${row['Description'] ?? 'Personal income per capita'}'.trim();
      final countyFips = sourceGeoFips.length >= 5
          ? sourceGeoFips.substring(sourceGeoFips.length - 3)
          : sourceGeoFips;

      records.add(<String, dynamic>{
        'record_id': 'bea-$replayYear-$sourceGeoFips-$tableName-line-$lineCode',
        'series_id': '$tableName:$lineCode',
        'series_key': 'personal_income_per_capita',
        'name': '$geoName Personal Income Per Capita',
        'entity_id': 'county:$countyFips',
        'entity_type': 'economic_signal',
        'locality': _localityForGeoFips(sourceGeoFips, geoName),
        'metric_value': dataValue,
        'unit': 'usd_per_person',
        'observed_at': DateTime.utc(replayYear, 12, 31).toIso8601String(),
        'published_at': DateTime.utc(replayYear + 1, 3, 28).toIso8601String(),
        'geo_fips': sourceGeoFips,
        'county_fips': countyFips,
        'table_name': tableName,
        'line_code': lineCode,
        'description': description,
      });
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': _sanitizedUri(uri).toString(),
        'recordCount': records.length,
        'query': <String, dynamic>{
          'datasetname': 'Regional',
          'TableName': tableName,
          'LineCode': lineCode,
          'GeoFIPS': geoFips,
          'Year': plan.replayYear,
        },
        'coverageStatus': 'partial_operational',
        'historicalReplayReady': true,
        'implementedFields': <String>['personal_income_per_capita'],
      },
    );
  }

  Uri _buildUri({
    required String endpoint,
    required int replayYear,
    required String apiKey,
  }) {
    final baseUri = Uri.parse(endpoint);
    return baseUri.replace(
      queryParameters: <String, String>{
        ...baseUri.queryParameters,
        'UserID': apiKey,
        'method': 'GetData',
        'datasetname': 'Regional',
        'TableName': tableName,
        'LineCode': lineCode,
        'GeoFIPS': geoFips,
        'Year': '$replayYear',
        'ResultFormat': 'json',
      },
    );
  }

  Uri _sanitizedUri(Uri uri) {
    final sanitized = Map<String, String>.from(uri.queryParameters);
    if (sanitized.containsKey('UserID')) {
      sanitized['UserID'] = '[redacted]';
    }
    return uri.replace(queryParameters: sanitized);
  }

  List<Map<String, dynamic>> _extractDataRows(Object? decoded) {
    if (decoded is! Map) {
      return const <Map<String, dynamic>>[];
    }
    final beaApi = decoded['BEAAPI'];
    if (beaApi is! Map) {
      return const <Map<String, dynamic>>[];
    }
    final results = beaApi['Results'];
    if (results is! Map) {
      return const <Map<String, dynamic>>[];
    }
    final data = results['Data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }
    return data
        .whereType<Map>()
        .map(
          (entry) => Map<String, dynamic>.from(
            entry.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList(growable: false);
  }

  num? _parseNumeric(Object? raw) {
    if (raw == null) {
      return null;
    }
    final cleaned = raw.toString().replaceAll(',', '').trim();
    if (cleaned.isEmpty || cleaned == '(NA)') {
      return null;
    }
    return num.tryParse(cleaned);
  }

  String _localityForGeoFips(String sourceGeoFips, String geoName) {
    if (sourceGeoFips == '01073') {
      return 'Birmingham Metro';
    }
    return geoName;
  }
}
