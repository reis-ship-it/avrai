import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_bundle_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds priority manual-import bundle for the four priority sources',
      () {
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
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'City of Birmingham OpenGov',
            sourceType: 'civic_geodata',
            accessMethod: ReplaySourceAccessMethod.openData,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['community'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'locality_truth',
            legalStatus: 'allowed',
            metadata: <String, dynamic>{
              'plannedIngestFields': <String>['neighborhood_polygons'],
            },
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['community', 'locality'],
          dedupeKeys: <String>['dataset_id'],
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
        ReplaySourcePullPlan(
          sourceName: 'City of Birmingham OpenGov',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.manualImport,
          rawOutputKey: 'city_of_birmingham_opengov',
        ),
      ],
    );

    final bundle =
        const BhamReplayManualImportBundleService().buildPriorityBundle(
      manifest: manifest,
      pullPlan: pullPlan,
    );

    expect(bundle.replayYear, 2023);
    expect(
        bundle.entries.map((entry) => entry.sourceName),
        containsAll(<String>[
          'ALDOT Traffic Data',
          'City of Birmingham OpenGov',
        ]));
    expect(
        bundle.entries
            .singleWhere((entry) => entry.sourceName == 'ALDOT Traffic Data')
            .records,
        isEmpty);
  });

  test('converts populated manual-import bundle into replay source pack', () {
    final bundle = ReplayManualImportBundle(
      bundleId: 'priority-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 10, 20),
      entries: const <ReplayManualImportEntry>[
        ReplayManualImportEntry(
          sourceName: 'ALDOT Traffic Data',
          rawOutputKey: 'aldot_traffic_data',
          requiredFields: <String>['record_id', 'entity_type'],
          dedupeKeys: <String>['segment_id', 'date'],
          normalizationTargets: <String>['movement_flow'],
          records: <Map<String, dynamic>>[
            <String, dynamic>{
              'record_id': 'traffic-1',
              'entity_type': 'movement_flow',
            },
          ],
          status: ReplayManualImportEntryStatus.populated,
        ),
      ],
    );

    final pack = const BhamReplayManualImportBundleService().toReplaySourcePack(
      bundle,
    );

    expect(pack.replayYear, 2023);
    expect(pack.datasets.length, 1);
    expect(pack.datasets.single.sourceName, 'ALDOT Traffic Data');
    expect(pack.datasets.single.records.single['record_id'], 'traffic-1');
  });

  test('flags missing required fields before conversion', () {
    final bundle = ReplayManualImportBundle(
      bundleId: 'priority-2023',
      replayYear: 2023,
      generatedAtUtc: DateTime.utc(2026, 3, 10, 20),
      entries: const <ReplayManualImportEntry>[
        ReplayManualImportEntry(
          sourceName: 'ALDOT Traffic Data',
          rawOutputKey: 'aldot_traffic_data',
          requiredFields: <String>['record_id', 'entity_type', 'observed_at'],
          dedupeKeys: <String>['segment_id', 'date'],
          normalizationTargets: <String>['movement_flow'],
          records: <Map<String, dynamic>>[
            <String, dynamic>{
              'record_id': 'traffic-1',
              'entity_type': 'movement_flow',
            },
          ],
          status: ReplayManualImportEntryStatus.populated,
        ),
      ],
    );

    final validation =
        const BhamReplayManualImportBundleService().validateBundle(bundle);

    expect(validation.isValid, isFalse);
    expect(validation.issues.single.missingFields, contains('observed_at'));
  });
}
