import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_template_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds manual import templates from manifest and pull plan', () {
    final manifest = ReplayIngestionManifest(
      manifestId: 'manifest-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 10, 18),
      selectedScore: const ReplayYearCompletenessScore(
        year: 2023,
        eventCoverage: 0.7,
        venueCoverage: 0.6,
        communityCoverage: 0.65,
        recurrenceFidelity: 0.8,
        temporalCertainty: 0.79,
        trustQuality: 0.83,
        overallScore: 0.73,
      ),
      sourcePlans: const <ReplayIngestionSourcePlan>[
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'ALDOT Traffic Data',
            sourceType: 'traffic_flow',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['movement'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'movement_truth',
            legalStatus: 'allowed',
            metadata: <String, dynamic>{
              'plannedIngestFields': <String>['counts', 'travel_speed'],
            },
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['movement_flow'],
          dedupeKeys: <String>['segment_id', 'date'],
        ),
      ],
    );

    final pullPlan = BhamReplayPullPlanBatch(
      replayYear: 2023,
      plans: const <ReplaySourcePullPlan>[
        ReplaySourcePullPlan(
          sourceName: 'ALDOT Traffic Data',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.manualImport,
          rawOutputKey: 'aldot_traffic_data',
        ),
      ],
    );

    final batch = const BhamReplayManualImportTemplateService().buildTemplates(
      manifest: manifest,
      pullPlan: pullPlan,
    );

    expect(batch.templates.length, 1);
    expect(batch.templates.single.requiredFields, containsAll(<String>[
      'record_id',
      'entity_type',
      'entity_id',
      'observed_at',
      'published_at',
      'counts',
      'travel_speed',
    ]));
  });
}
