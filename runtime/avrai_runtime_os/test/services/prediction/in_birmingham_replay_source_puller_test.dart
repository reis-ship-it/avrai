import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/in_birmingham_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls IN Birmingham catalog rows into replay records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'inbirmingham.com');
      if (request.url.path.contains('festivals-and-events')) {
        return http.Response(
          '''
          <html><body>
            <a href="https://inbirmingham.com/event/sidewalk-film-festival/">Sidewalk Film Festival</a>
            <a href="https://inbirmingham.com/event/magic-city-classic/">Magic City Classic</a>
          </body></html>
          ''',
          200,
        );
      }
      return http.Response(
        '''
        <html><body>
          <a href="https://inbirmingham.com/community-guides/avondale/">Avondale Community Guide</a>
          <a href="https://inbirmingham.com/community-guides/downtown-birmingham/">Downtown Birmingham Guide</a>
        </body></html>
        ''',
        200,
      );
    });

    final puller = InBirminghamReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'IN Birmingham (CVB Calendar)',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'in_birmingham',
        sourceUrl: 'https://inbirmingham.com/festivals-and-events/',
      ),
    );

    expect(dataset.records, hasLength(4));
    expect(dataset.metadata['coverageStatus'], 'current_tourism_catalog');
    expect(dataset.metadata['historicalReplayReady'], isFalse);
    expect(dataset.records.map((row) => row['entity_type']), contains('event'));
    expect(
      dataset.records.map((row) => row['entity_type']),
      contains('community'),
    );
  });
}
