import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_eventbrite_meetup_historicalized_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('promotes persistent meetup group pages into replay-safe anchors', () {
    final automatedPack = ReplaySourcePack(
      packId: 'automated',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Eventbrite / Meetup',
          records: const <Map<String, dynamic>>[
            <String, dynamic>{
              'record_id': 'meetup-1',
              'name': 'Birmingham Dining Experience Group',
              'source_url':
                  '/birmingham-dining-experience-group/?eventOrigin=city_popular_groups',
            },
            <String, dynamic>{
              'record_id': 'meetup-2',
              'name': 'Bham Security Book Club',
              'source_url':
                  '/bham-security-book-club/?eventOrigin=city_popular_groups',
            },
            <String, dynamic>{
              'record_id': 'meetup-3',
              'name': 'Future Dated Event',
              'source_url': 'https://www.eventbrite.com/e/future-dated-event',
            },
          ],
        ),
      ],
    );

    final pack = const BhamEventbriteMeetupHistoricalizedSourcePackService()
        .buildPack(automatedPack: automatedPack);

    expect(pack.replayYear, 2023);
    expect(pack.datasets, hasLength(1));
    final dataset = pack.datasets.single;
    expect(dataset.records, hasLength(2));
    expect(
      dataset.records.map((row) => row['entity_type']).toSet(),
      containsAll(<String>['community', 'club']),
    );
    expect(
      dataset.records.every(
        (row) =>
            row['historical_admissibility'] ==
            'governed_group_anchor_reconstruction',
      ),
      isTrue,
    );
  });
}
