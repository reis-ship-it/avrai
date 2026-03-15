import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bea_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls BEA economic rows into replay source records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'apps.bea.gov');
      expect(request.url.path, '/api/data');
      expect(request.url.queryParameters['UserID'], 'test-bea-key');
      expect(request.url.queryParameters['datasetname'], 'Regional');
      expect(request.url.queryParameters['TableName'], 'CAINC1');
      expect(request.url.queryParameters['LineCode'], '3');
      expect(request.url.queryParameters['GeoFIPS'], '01073');
      expect(request.url.queryParameters['Year'], '2023');
      expect(request.url.queryParameters['ResultFormat'], 'json');
      return http.Response(
        '''
{
  "BEAAPI": {
    "Results": {
      "Data": [
        {
          "GeoFips": "01073",
          "GeoName": "Jefferson, AL",
          "TimePeriod": "2023",
          "LineCode": "3",
          "Description": "Per capita personal income (dollars)",
          "DataValue": "60,210"
        }
      ]
    }
  }
}
''',
        200,
      );
    });

    final puller = BeaReplaySourcePuller(
      client: client,
      apiKey: 'test-bea-key',
    );
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'BEA / U.S. Census Bureau Economic Series',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.apiKeyRequired,
        rawOutputKey: 'bea_u_s_census_bureau_economic_series',
        sourceUrl: 'https://apps.bea.gov/api/data',
        endpointRef: 'https://apps.bea.gov/api/data',
      ),
    );

    expect(dataset.sourceName, 'BEA / U.S. Census Bureau Economic Series');
    expect(dataset.records.length, 1);
    expect(dataset.records.single['entity_type'], 'economic_signal');
    expect(dataset.records.single['series_key'], 'personal_income_per_capita');
    expect(dataset.records.single['metric_value'], 60210);
    expect(dataset.metadata['coverageStatus'], 'partial_operational');
  });

  test('requires BEA API key', () async {
    final puller = BeaReplaySourcePuller(apiKey: null);

    expect(
      () => puller.pull(
        plan: const ReplaySourcePullPlan(
          sourceName: 'BEA / U.S. Census Bureau Economic Series',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.apiKeyRequired,
          rawOutputKey: 'bea_u_s_census_bureau_economic_series',
          sourceUrl: 'https://apps.bea.gov/api/data',
          endpointRef: 'https://apps.bea.gov/api/data',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
