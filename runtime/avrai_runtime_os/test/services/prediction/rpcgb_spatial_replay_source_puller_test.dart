import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/rpcgb_spatial_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls RPCGB catalog rows into replay records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'www.rpcgb.org');
      return http.Response(
        '''
        <html><body>
          <a href="https://geospatial-rpcgb.opendata.arcgis.com/">Open Data Portal</a>
          <a href="/downloads/jefferson-county-parcels.zip">Jefferson County Parcels</a>
          <a href="/downloads/shelby-county-buildings.zip">Shelby County Buildings</a>
          <a href="/downloads/regional-housing-trends.pdf">Regional Housing Trends</a>
        </body></html>
        ''',
        200,
      );
    });

    final puller = RpcgbSpatialReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'Jefferson / Shelby / Regional GIS and Assessors',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'rpcgb_spatial',
        sourceUrl: 'https://www.rpcgb.org/data-and-maps-downloads',
      ),
    );

    expect(dataset.records, hasLength(4));
    expect(dataset.metadata['coverageStatus'], 'current_spatial_catalog');
    expect(dataset.metadata['historicalReplayReady'], isFalse);
    expect(dataset.records.map((row) => row['entity_type']), contains('locality'));
    expect(
      dataset.records.map((row) => row['entity_type']),
      contains('housing_signal'),
    );
  });
}
