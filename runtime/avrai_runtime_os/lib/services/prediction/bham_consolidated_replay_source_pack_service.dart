import 'package:avrai_core/avra_core.dart';

class BhamConsolidatedReplaySourcePackService {
  const BhamConsolidatedReplaySourcePackService();

  ReplaySourcePack mergePacks({
    required int replayYear,
    required List<ReplaySourcePack> packs,
  }) {
    final datasetsBySource = <String, List<Map<String, dynamic>>>{};
    final metadataBySource = <String, Map<String, dynamic>>{};

    for (final pack in packs) {
      for (final dataset in pack.datasets) {
        datasetsBySource.putIfAbsent(dataset.sourceName, () => <Map<String, dynamic>>[]);
        datasetsBySource[dataset.sourceName]!.addAll(dataset.records);
        metadataBySource.update(
          dataset.sourceName,
          (existing) {
            final mergedFromPackIds = <String>{
              ...((existing['mergedFromPackIds'] as List?)?.map((e) => e.toString()) ??
                  const <String>[]),
              pack.packId,
            }.toList();
            return <String, dynamic>{
              ...existing,
              ...dataset.metadata,
              'mergedFromPackIds': mergedFromPackIds,
            };
          },
          ifAbsent: () => <String, dynamic>{
            ...dataset.metadata,
            'mergedFromPackIds': [pack.packId],
          },
        );
      }
    }

    final mergedDatasets = datasetsBySource.entries
        .map(
          (entry) => ReplaySourceDataset(
            sourceName: entry.key,
            records: entry.value,
            metadata: metadataBySource[entry.key] ?? const <String, dynamic>{},
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.sourceName.compareTo(b.sourceName));

    return ReplaySourcePack(
      packId: 'bham-consolidated-replay-$replayYear',
      replayYear: replayYear,
      generatedAtUtc: DateTime.now().toUtc(),
      datasets: mergedDatasets,
      notes: <String>[
        'This pack consolidates the currently governed BHAM 2023 replay-safe source packs into one replay-year input.',
        'It remains a partial truth year and should be regenerated as additional lanes become historicalized.',
      ],
      metadata: <String, dynamic>{
        'mergedPackIds': packs.map((pack) => pack.packId).toList(growable: false),
        'sourceCount': mergedDatasets.length,
      },
    );
  }
}
