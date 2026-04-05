import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/replay_record_normalization_service.dart';

class BhamReplaySourceIngestionResult {
  const BhamReplaySourceIngestionResult({
    required this.sourcePlan,
    required this.adapterId,
    required this.records,
    required this.observations,
  });

  final ReplayIngestionSourcePlan sourcePlan;
  final String adapterId;
  final List<ReplaySourceRecord> records;
  final List<ReplayNormalizedObservation> observations;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourcePlan': sourcePlan.toJson(),
      'adapterId': adapterId,
      'records': records.map((record) => record.toJson()).toList(),
      'observations': observations
          .map((observation) => observation.toJson())
          .toList(),
    };
  }
}

class BhamReplayIngestionBatchResult {
  const BhamReplayIngestionBatchResult({
    required this.manifest,
    required this.results,
    this.skippedSources = const <String>[],
  });

  final ReplayIngestionManifest manifest;
  final List<BhamReplaySourceIngestionResult> results;
  final List<String> skippedSources;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'manifest': manifest.toJson(),
      'results': results.map((result) => result.toJson()).toList(),
      'skippedSources': skippedSources,
    };
  }
}

class BhamPriorityReplayIngestionService {
  const BhamPriorityReplayIngestionService({
    required this.adapters,
    required this.normalizationService,
    required this.temporalKernel,
  });

  final List<BhamReplaySourceAdapter> adapters;
  final ReplayRecordNormalizationService normalizationService;
  final TemporalKernel temporalKernel;

  Future<BhamReplayIngestionBatchResult> ingestManifest({
    required ReplayIngestionManifest manifest,
    required Map<String, List<Map<String, dynamic>>> rawRecordsBySourceName,
  }) async {
    final results = <BhamReplaySourceIngestionResult>[];
    final skippedSources = <String>[];

    for (final sourcePlan in manifest.sourcePlans) {
      if (sourcePlan.readiness != ReplayIngestionReadiness.ready) {
        skippedSources.add(sourcePlan.source.sourceName);
        continue;
      }

      final rawRecords = rawRecordsBySourceName[sourcePlan.source.sourceName];
      if (rawRecords == null || rawRecords.isEmpty) {
        skippedSources.add(sourcePlan.source.sourceName);
        continue;
      }

      final adapter = adapters.cast<BhamReplaySourceAdapter?>().firstWhere(
        (candidate) => candidate != null && candidate.supports(sourcePlan),
        orElse: () => null,
      );
      if (adapter == null) {
        skippedSources.add(sourcePlan.source.sourceName);
        continue;
      }

      final records = await adapter.adapt(
        plan: sourcePlan,
        rawRecords: rawRecords,
        temporalKernel: temporalKernel,
      );

      final observations = <ReplayNormalizedObservation>[];
      for (final record in records) {
        observations.add(
          await normalizationService.normalize(
            record: record,
            sourceDescriptor: sourcePlan.source,
          ),
        );
      }

      results.add(
        BhamReplaySourceIngestionResult(
          sourcePlan: sourcePlan,
          adapterId: adapter.adapterId,
          records: records,
          observations: observations,
        ),
      );
    }

    return BhamReplayIngestionBatchResult(
      manifest: manifest,
      results: results,
      skippedSources: skippedSources,
    );
  }
}
