import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalization_candidate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters non-historical catalog datasets into historicalization candidates',
      () {
    final pack = ReplaySourcePack(
      packId: 'pack-1',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'IN Birmingham (CVB Calendar)',
          records: <Map<String, dynamic>>[
            <String, dynamic>{
              'record_id': 'a',
              'name': 'Avondale Guide',
              'entity_type': 'community',
              'locality': 'bham_avondale',
            },
          ],
          metadata: <String, dynamic>{
            'coverageStatus': 'current_tourism_catalog',
            'historicalReplayReady': false,
            'uri': 'https://inbirmingham.com/festivals-and-events/',
          },
        ),
        ReplaySourceDataset(
          sourceName: 'OpenStreetMap POI Data',
          records: const <Map<String, dynamic>>[],
          metadata: <String, dynamic>{
            'coverageStatus': 'historical_replay_snapshot',
            'historicalReplayReady': true,
          },
        ),
      ],
    );

    final candidates =
        const BhamPublicCatalogHistoricalizationCandidateService().buildCandidates(
      pack,
    );

    expect(candidates, hasLength(1));
    expect(candidates.first['sourceName'], 'IN Birmingham (CVB Calendar)');
    expect(candidates.first['recordCount'], 1);
  });
}
