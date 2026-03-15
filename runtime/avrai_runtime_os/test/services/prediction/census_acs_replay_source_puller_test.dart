import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/census_acs_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls census ACS rows into replay source records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'api.census.gov');
      return http.Response(
        '''
[
  ["NAME","B01001_001E","B25001_001E","state","county","tract"],
  ["Census Tract 110100, Jefferson County, Alabama","12000","4210","01","073","110100"]
]
''',
        200,
      );
    });

    final puller = CensusAcsReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'U.S. Census ACS',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'u_s_census_acs',
        sourceUrl: 'https://api.census.gov/data/2023/acs/acs5',
        endpointRef: 'https://api.census.gov/data/2023/acs/acs5',
      ),
    );

    expect(dataset.sourceName, 'U.S. Census ACS');
    expect(dataset.records.length, 2);
    expect(dataset.records.first['entity_type'], 'population_cohort');
    expect(dataset.records.last['entity_type'], 'housing_signal');
  });
}
