import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replay ingestion manifest preserves source acquisition fields on round-trip', () {
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
            sourceName: 'NOAA',
            sourceType: 'environmental_truth',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['weather'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'weather_truth',
            legalStatus: 'allowed',
            sourceUrl: 'https://api.weather.gov',
            metadata: <String, dynamic>{'endpointRef': 'https://api.weather.gov'},
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['environmental_signal'],
        ),
      ],
    );

    final roundTripped = ReplayIngestionManifest.fromJson(manifest.toJson());
    final source = roundTripped.sourcePlans.single.source;
    expect(source.sourceUrl, 'https://api.weather.gov');
    expect(source.metadata['endpointRef'], 'https://api.weather.gov');
  });

  test('builds acquisition modes from manifest source metadata', () {
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
            sourceName: 'NOAA',
            sourceType: 'environmental_truth',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['weather'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'weather_truth',
            legalStatus: 'allowed',
            sourceUrl: 'https://api.weather.gov',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['environmental_signal'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'BEA',
            sourceType: 'economic_reality',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['economics'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'economic_truth',
            legalStatus: 'allowed',
            sourceUrl: 'https://apps.bea.gov/api/data',
            metadata: <String, dynamic>{'apiKeyRequired': true},
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['economic_signal'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'Partner Export',
            sourceType: 'reservation_demand',
            accessMethod: ReplaySourceAccessMethod.partnerExport,
            trustTier: ReplaySourceTrustTier.tier3,
            status: ReplaySourceStatus.candidate,
            entityCoverage: <String>['venues'],
            temporalStartYear: 2023,
            temporalEndYear: 2026,
            replayRole: 'demand_signal',
            legalStatus: 'review_required',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.pendingReview,
          ingestPriority: 3,
          normalizationTargetTypes: <String>['venue'],
        ),
        ReplayIngestionSourcePlan(
          source: ReplaySourceDescriptor(
            sourceName: 'OpenGov',
            sourceType: 'civic_spatial_truth',
            accessMethod: ReplaySourceAccessMethod.openData,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['localities'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'locality_truth',
            legalStatus: 'allowed',
            metadata: <String, dynamic>{'manualImportRequired': true},
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['locality'],
        ),
      ],
    );

    final batch = const BhamReplayPullPlanService().buildPullPlan(
      manifest: manifest,
    );

    expect(batch.plans.length, 4);
    expect(
      batch.plans.firstWhere((plan) => plan.sourceName == 'NOAA').acquisitionMode,
      ReplaySourceAcquisitionMode.automated,
    );
    expect(
      batch.plans.firstWhere((plan) => plan.sourceName == 'BEA').acquisitionMode,
      ReplaySourceAcquisitionMode.apiKeyRequired,
    );
    expect(
      batch.plans.firstWhere((plan) => plan.sourceName == 'Partner Export').acquisitionMode,
      ReplaySourceAcquisitionMode.partnerReview,
    );
    expect(
      batch.plans.firstWhere((plan) => plan.sourceName == 'OpenGov').acquisitionMode,
      ReplaySourceAcquisitionMode.manualImport,
    );
  });

  test('registry overlay can upgrade manifest acquisition authority', () {
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
            sourceName: 'NOAA',
            sourceType: 'environmental_truth',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['weather'],
            temporalStartYear: 2020,
            temporalEndYear: 2026,
            replayRole: 'weather_truth',
            legalStatus: 'allowed',
          ),
          replayYear: 2023,
          readiness: ReplayIngestionReadiness.ready,
          ingestPriority: 1,
          normalizationTargetTypes: <String>['environmental_signal'],
        ),
      ],
    );

    final registry = BhamReplaySourceRegistry(
      registryId: 'bham',
      registryVersion: 'test',
      generatedAtUtc: DateTime.utc(2026, 3, 10, 18),
      status: 'active',
      selectionCandidateYears: const <int>[2023],
      sources: const <ReplaySourceDescriptor>[
        ReplaySourceDescriptor(
          sourceName: 'NOAA',
          sourceType: 'environmental_truth',
          accessMethod: ReplaySourceAccessMethod.api,
          trustTier: ReplaySourceTrustTier.tier1,
          status: ReplaySourceStatus.approved,
          entityCoverage: <String>['weather'],
          temporalStartYear: 2020,
          temporalEndYear: 2026,
          replayRole: 'weather_truth',
          legalStatus: 'allowed',
          sourceUrl: 'https://api.weather.gov',
          metadata: <String, dynamic>{'endpointRef': 'https://api.weather.gov'},
        ),
      ],
    );

    final batch = const BhamReplayPullPlanService().buildPullPlan(
      manifest: manifest,
      registry: registry,
    );
    final plan = batch.plans.single;
    expect(plan.acquisitionMode, ReplaySourceAcquisitionMode.automated);
    expect(plan.sourceUrl, 'https://api.weather.gov');
    expect(plan.endpointRef, 'https://api.weather.gov');
  });
}
