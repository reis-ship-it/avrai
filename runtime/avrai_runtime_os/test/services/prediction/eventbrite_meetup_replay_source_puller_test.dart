import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/eventbrite_meetup_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls Eventbrite and Meetup catalog rows into replay records', () async {
    final client = MockClient((http.Request request) async {
      if (request.url.host.contains('eventbrite')) {
        return http.Response(
          '''
          <html><body>
            <a href="https://www.eventbrite.com/e/sidewalk-sessions-birmingham">Sidewalk Sessions Birmingham</a>
            <a href="https://www.eventbrite.com/e/magic-city-design-meetup">Magic City Design Meetup</a>
          </body></html>
          ''',
          200,
        );
      }
      return http.Response(
        '''
        <html><body>
          <a href="https://www.meetup.com/birmingham-tech-group/">Birmingham Tech Group</a>
          <a href="https://www.meetup.com/avondale-runners-club/">Avondale Runners Club</a>
        </body></html>
        ''',
        200,
      );
    });

    final puller = EventbriteMeetupReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'Eventbrite / Meetup',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'eventbrite_meetup',
        sourceUrl: 'https://www.eventbrite.com/d/al--birmingham/events/',
      ),
    );

    expect(dataset.records, hasLength(4));
    expect(dataset.metadata['coverageStatus'], 'current_community_event_catalog');
    expect(dataset.metadata['historicalReplayReady'], isFalse);
    expect(dataset.records.map((row) => row['entity_type']), contains('event'));
    expect(dataset.records.map((row) => row['entity_type']), contains('community'));
    expect(dataset.records.map((row) => row['entity_type']), contains('club'));
  });
}
