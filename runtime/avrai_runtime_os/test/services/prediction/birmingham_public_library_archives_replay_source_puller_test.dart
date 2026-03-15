import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/birmingham_public_library_archives_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls archive discovery rows into replay source records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'www.cobpl.org');
      return http.Response(
        '''
<html>
  <body>
    <main>
      <a href="/digital/collections/industrial-history">Industrial History Collection</a>
      <a href="/resources/archives/birmingham-neighborhood-archive">Birmingham Neighborhood Archive</a>
      <a href="/events/history-of-magic-city-classic">History of Magic City Classic</a>
    </main>
  </body>
</html>
''',
        200,
      );
    });

    final puller = BirminghamPublicLibraryArchivesReplaySourcePuller(
      client: client,
    );
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'Birmingham Public Library Archives',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'birmingham_public_library_archives',
        sourceUrl: 'https://www.cobpl.org/resources/archives/collections.aspx',
        endpointRef: 'https://www.cobpl.org/resources/archives/collections.aspx',
      ),
    );

    expect(dataset.sourceName, 'Birmingham Public Library Archives');
    expect(dataset.records, hasLength(3));
    expect(dataset.records[0]['historical_admissibility'], 'deep_context_archive');
    expect(dataset.metadata['coverageStatus'], 'archive_index_discovery');
    expect(dataset.metadata['historicalReplayReady'], isTrue);
  });

  test('falls through official endpoints until one returns archive candidates', () async {
    final requested = <Uri>[];
    final client = MockClient((http.Request request) async {
      requested.add(request.url);
      if (request.url.toString() ==
          'https://www.cobpl.org/resources/archives/collections.aspx') {
        return http.Response('<html><body>no matching archive links</body></html>', 200);
      }
      if (request.url.toString() == 'https://www.cobpl.org/resources/archives/') {
        return http.Response(
          '''
<html>
  <body>
    <a href="/digital/collections/civil-rights">Civil Rights Collection</a>
  </body>
</html>
''',
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final puller = BirminghamPublicLibraryArchivesReplaySourcePuller(
      client: client,
    );
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'Birmingham Public Library Archives',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'birmingham_public_library_archives',
        sourceUrl: 'https://www.cobpl.org/resources/archives/collections.aspx',
        endpointRef: 'https://www.cobpl.org/resources/archives/collections.aspx',
      ),
    );

    expect(requested, hasLength(2));
    expect(dataset.records, hasLength(1));
    expect(
      dataset.metadata['uri'],
      'https://www.cobpl.org/resources/archives/',
    );
    expect((dataset.metadata['attemptedEndpoints'] as List).isNotEmpty, isTrue);
  });
}
