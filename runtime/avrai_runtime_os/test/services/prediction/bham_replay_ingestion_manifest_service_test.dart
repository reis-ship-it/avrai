import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_ingestion_manifest_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a replay ingestion manifest with readiness and normalization targets', () {
    final registry = BhamReplaySourceRegistry(
      registryId: 'bham',
      registryVersion: 'test',
      generatedAtUtc: DateTime.utc(2026, 3, 10, 18),
      status: 'active',
      selectionCandidateYears: const <int>[2023],
      sources: const <ReplaySourceDescriptor>[
        ReplaySourceDescriptor(
          sourceName: 'City Events',
          sourceType: 'official_calendar',
          accessMethod: ReplaySourceAccessMethod.api,
          trustTier: ReplaySourceTrustTier.tier1,
          status: ReplaySourceStatus.approved,
          entityCoverage: <String>['events', 'venues', 'communities'],
          temporalStartYear: 2022,
          temporalEndYear: 2024,
          replayRole: 'event_truth',
          legalStatus: 'allowed',
          structuredExportAvailable: true,
          seedingEligible: true,
          metadata: <String, dynamic>{
            'ingestPriority': 2,
            'dedupeKeys': <String>['event_name', 'venue_name', 'event_start'],
          },
        ),
        ReplaySourceDescriptor(
          sourceName: 'Reservation Feed',
          sourceType: 'reservation_demand',
          accessMethod: ReplaySourceAccessMethod.partnerExport,
          trustTier: ReplaySourceTrustTier.tier3,
          status: ReplaySourceStatus.candidate,
          entityCoverage: <String>['venues', 'restaurants'],
          temporalStartYear: 2023,
          temporalEndYear: 2024,
          replayRole: 'demand_signal',
          legalStatus: 'review_required',
          metadata: <String, dynamic>{
            'ingestPriority': 3,
            'dedupeKeys': <String>['venue_name', 'service_date'],
          },
        ),
      ],
    );

    const service = BhamReplayIngestionManifestService();
    final manifest = service.buildManifest(
      registry: registry,
      selection: const AuthoritativeReplayYearSelection(
        selectedScore: ReplayYearCompletenessScore(
          year: 2023,
          eventCoverage: 0.7,
          venueCoverage: 0.6,
          communityCoverage: 0.65,
          recurrenceFidelity: 0.8,
          temporalCertainty: 0.79,
          trustQuality: 0.83,
          overallScore: 0.73,
        ),
        candidateScores: <ReplayYearCompletenessScore>[],
      ),
    );

    expect(manifest.replayYear, 2023);
    expect(manifest.sourcePlans.length, 2);
    expect(
      manifest.sourcePlans.firstWhere((plan) => plan.source.sourceName == 'City Events').readiness,
      ReplayIngestionReadiness.ready,
    );
    expect(
      manifest.sourcePlans.firstWhere((plan) => plan.source.sourceName == 'Reservation Feed').readiness,
      ReplayIngestionReadiness.pendingReview,
    );
    expect(manifest.canonicalEntityTypes, containsAll(<String>['event', 'venue', 'community']));
  });
}
