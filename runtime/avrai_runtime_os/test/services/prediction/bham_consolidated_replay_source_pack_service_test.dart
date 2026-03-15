import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_consolidated_replay_source_pack_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges replay source packs by source name', () {
    final packA = ReplaySourcePack(
      packId: 'pack-a',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: const <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Source A',
          records: <Map<String, dynamic>>[
            <String, dynamic>{'record_id': 'a-1'},
          ],
        ),
      ],
    );
    final packB = ReplaySourcePack(
      packId: 'pack-b',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: const <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Source A',
          records: <Map<String, dynamic>>[
            <String, dynamic>{'record_id': 'a-2'},
          ],
        ),
        ReplaySourceDataset(
          sourceName: 'Source B',
          records: <Map<String, dynamic>>[
            <String, dynamic>{'record_id': 'b-1'},
          ],
        ),
      ],
    );

    final consolidated = const BhamConsolidatedReplaySourcePackService().mergePacks(
      replayYear: 2023,
      packs: <ReplaySourcePack>[packA, packB],
    );

    expect(consolidated.datasets.length, 2);
    final sourceA = consolidated.datasets.firstWhere(
      (dataset) => dataset.sourceName == 'Source A',
    );
    expect(sourceA.records.length, 2);
    expect(
      sourceA.metadata['mergedFromPackIds'],
      containsAll(<String>['pack-a', 'pack-b']),
    );
  });
}
