import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/open_street_map_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls OSM POI rows into replay source records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'overpass-api.de');
      expect(request.method, 'POST');
      final query = Uri.splitQueryString(request.body)['data'] ?? '';
      expect(query, contains('[date:"2023-12-31T23:59:59.000Z"]'));
      expect(
        query,
        contains('node["amenity"~"restaurant|cafe|bar|pub|fast_food|ice_cream|food_court|biergarten|nightclub|cinema|theatre|casino"]'),
      );
      return http.Response(
        '''
{
  "elements": [
    {
      "type": "node",
      "id": 1001,
      "lat": 33.5202,
      "lon": -86.8025,
      "tags": {
        "name": "Alabama Theatre",
        "tourism": "theatre"
      }
    },
    {
      "type": "node",
      "id": 1002,
      "lat": 33.5051,
      "lon": -86.7852,
      "tags": {
        "name": "Southside Branch Library",
        "amenity": "library"
      }
    },
    {
      "type": "node",
      "id": 1003,
      "lat": 33.4908,
      "lon": -86.7725,
      "tags": {
        "name": "Lakeview Club",
        "amenity": "nightclub"
      }
    }
  ]
}
''',
        200,
      );
    });

    final puller = OpenStreetMapReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'OpenStreetMap POI Data',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'openstreetmap_poi_data',
        sourceUrl: 'https://download.geofabrik.de/north-america/us/alabama.html',
        endpointRef: 'https://overpass-api.de/api/interpreter',
      ),
    );

    expect(dataset.sourceName, 'OpenStreetMap POI Data');
    expect(dataset.records.length, 3);
    expect(dataset.records[0]['entity_type'], 'venue');
    expect(dataset.records[1]['entity_type'], 'community');
    expect(dataset.records[2]['entity_type'], 'club');
    expect(dataset.metadata['coverageStatus'], 'historical_replay_snapshot');
    expect(dataset.metadata['historicalReplayReady'], isTrue);
    expect(dataset.metadata['snapshotDateUtc'], '2023-12-31T23:59:59.000Z');
  });
}
