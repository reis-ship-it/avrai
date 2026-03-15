import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';

class BhamReplayAutomatedPullBatchResult {
  const BhamReplayAutomatedPullBatchResult({
    required this.pack,
    required this.pulledSources,
    this.skippedSources = const <String>[],
    this.failedSources = const <String, String>{},
  });

  final ReplaySourcePack pack;
  final List<String> pulledSources;
  final List<String> skippedSources;
  final Map<String, String> failedSources;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pack': pack.toJson(),
      'pulledSources': pulledSources,
      'skippedSources': skippedSources,
      'failedSources': failedSources,
    };
  }
}

class BhamReplayAutomatedPullService {
  const BhamReplayAutomatedPullService({
    required this.pullers,
  });

  final List<BhamReplayAutomatedSourcePuller> pullers;

  Future<BhamReplayAutomatedPullBatchResult> pullPlans({
    required int replayYear,
    required List<ReplaySourcePullPlan> plans,
  }) async {
    final datasets = <ReplaySourceDataset>[];
    final pulledSources = <String>[];
    final skippedSources = <String>[];
    final failedSources = <String, String>{};

    for (final plan in plans) {
      if (plan.acquisitionMode == ReplaySourceAcquisitionMode.manualImport ||
          plan.acquisitionMode == ReplaySourceAcquisitionMode.partnerReview) {
        skippedSources.add(plan.sourceName);
        continue;
      }

      final puller = _findPuller(plan);
      if (puller == null) {
        skippedSources.add(plan.sourceName);
        continue;
      }

      try {
        final dataset = await puller.pull(plan: plan);
        datasets.add(dataset);
        pulledSources.add(plan.sourceName);
      } catch (error) {
        skippedSources.add(plan.sourceName);
        failedSources[plan.sourceName] = '$error';
      }
    }

    return BhamReplayAutomatedPullBatchResult(
      pack: ReplaySourcePack(
        packId: 'bham-automated-replay-pack-$replayYear',
        replayYear: replayYear,
        generatedAtUtc: DateTime.now().toUtc(),
        datasets: datasets,
        notes: const <String>[
          'Generated from automated/API-key replay pull plans.',
        ],
        metadata: <String, dynamic>{
          'datasetCount': datasets.length,
        },
      ),
      pulledSources: pulledSources,
      skippedSources: skippedSources,
      failedSources: failedSources,
    );
  }

  BhamReplayAutomatedSourcePuller? _findPuller(ReplaySourcePullPlan plan) {
    for (final puller in pullers) {
      if (puller.supports(plan)) {
        return puller;
      }
    }
    return null;
  }
}
