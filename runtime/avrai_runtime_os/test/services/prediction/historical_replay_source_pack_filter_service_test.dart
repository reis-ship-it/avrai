import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/historical_replay_source_pack_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only historical-replay-ready datasets', () {
    final pack = ReplaySourcePack(
      packId: 'pack',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 12),
      datasets: const <ReplaySourceDataset>[
        ReplaySourceDataset(
          sourceName: 'Historical Source',
          metadata: <String, dynamic>{'historicalReplayReady': true},
        ),
        ReplaySourceDataset(
          sourceName: 'Calibration Source',
          metadata: <String, dynamic>{'historicalReplayReady': false},
        ),
      ],
    );

    final filtered =
        const HistoricalReplaySourcePackFilterService().filterHistoricalReady(pack);

    expect(filtered.datasets, hasLength(1));
    expect(filtered.datasets.single.sourceName, 'Historical Source');
    expect(filtered.metadata['originalDatasetCount'], 2);
    expect(filtered.metadata['historicalDatasetCount'], 1);
  });
}
