import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses replay source pack and maps datasets by source name', () {
    const rawJson = '''
{
  "packId": "seed-pack",
  "replayYear": 2023,
  "generatedAtUtc": "2026-03-10T18:00:00Z",
  "datasets": [
    {
      "sourceName": "U.S. Census ACS",
      "records": [
        {"record_id": "acs-1", "entity_type": "population_cohort"}
      ]
    },
    {
      "sourceName": "City of Birmingham OpenGov",
      "records": [
        {"record_id": "opengov-1", "entity_type": "locality"}
      ]
    }
  ]
}
''';

    final pack = const BhamReplaySourcePackService().parsePackJson(rawJson);
    final rawRecords = const BhamReplaySourcePackService()
        .toRawRecordsBySourceName(pack);

    expect(pack.packId, 'seed-pack');
    expect(pack.replayYear, 2023);
    expect(pack.datasets.length, 2);
    expect(rawRecords['U.S. Census ACS']?.single['record_id'], 'acs-1');
    expect(
      rawRecords['City of Birmingham OpenGov']?.single['entity_type'],
      'locality',
    );
  });
}
