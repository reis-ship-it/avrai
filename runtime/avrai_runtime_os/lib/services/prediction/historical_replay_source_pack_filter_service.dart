import 'package:avrai_core/avra_core.dart';

class HistoricalReplaySourcePackFilterService {
  const HistoricalReplaySourcePackFilterService();

  ReplaySourcePack filterHistoricalReady(ReplaySourcePack pack) {
    final datasets = pack.datasets.where(_isHistoricalReady).toList(growable: false);
    return ReplaySourcePack(
      packId: '${pack.packId}-historicalized',
      replayYear: pack.replayYear,
      generatedAtUtc: pack.generatedAtUtc,
      datasets: datasets,
      notes: <String>[
        ...pack.notes,
        'Filtered to historical-replay-admissible datasets only.',
      ],
      metadata: <String, dynamic>{
        ...pack.metadata,
        'originalDatasetCount': pack.datasets.length,
        'historicalDatasetCount': datasets.length,
      },
    );
  }

  bool _isHistoricalReady(ReplaySourceDataset dataset) {
    return dataset.metadata['historicalReplayReady'] == true;
  }
}
