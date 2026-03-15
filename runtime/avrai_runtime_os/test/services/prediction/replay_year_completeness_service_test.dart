import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayYearCompletenessService', () {
    const service = ReplayYearCompletenessService();

    final sources = <ReplaySourceDescriptor>[
      const ReplaySourceDescriptor(
        sourceName: 'City Events',
        sourceType: 'official_calendar',
        accessMethod: ReplaySourceAccessMethod.api,
        trustTier: ReplaySourceTrustTier.tier1,
        status: ReplaySourceStatus.approved,
        entityCoverage: <String>['events', 'venues'],
        temporalStartYear: 2024,
        temporalEndYear: 2026,
        replayRole: 'event_truth',
        legalStatus: 'allowed',
        updateCadence: 'daily',
        richestYear: 2025,
        structuredExportAvailable: true,
        seedingEligible: true,
      ),
      const ReplaySourceDescriptor(
        sourceName: 'Neighborhood Associations',
        sourceType: 'community_calendar',
        accessMethod: ReplaySourceAccessMethod.scrape,
        trustTier: ReplaySourceTrustTier.tier2,
        status: ReplaySourceStatus.approved,
        entityCoverage: <String>['communities', 'clubs', 'neighborhoods'],
        temporalStartYear: 2025,
        temporalEndYear: 2026,
        replayRole: 'community_truth',
        legalStatus: 'allowed',
        updateCadence: 'weekly',
        richestYear: 2025,
      ),
      const ReplaySourceDescriptor(
        sourceName: 'Legacy Venue Feed',
        sourceType: 'legacy_feed',
        accessMethod: ReplaySourceAccessMethod.rss,
        trustTier: ReplaySourceTrustTier.tier3,
        status: ReplaySourceStatus.candidate,
        entityCoverage: <String>['events', 'restaurants'],
        temporalStartYear: 2024,
        temporalEndYear: 2025,
        replayRole: 'demand_signal',
        legalStatus: 'review_required',
        updateCadence: 'daily',
        richestYear: 2025,
      ),
    ];

    test('scores a year from eligible sources', () {
      final score = service.scoreYear(year: 2025, sources: sources);

      expect(score.year, 2025);
      expect(score.overallScore, greaterThan(0.0));
      expect(score.sourceRefs, contains('City Events'));
      expect(score.notes, contains('candidate sources still influence score'));
    });

    test('uses 2025 as tie-breaker when scores are equal', () {
      final best = service.selectBestYear(
        candidateYears: const <int>[2024, 2025],
        sources: const <ReplaySourceDescriptor>[
          ReplaySourceDescriptor(
            sourceName: 'Equal Feed',
            sourceType: 'official_calendar',
            accessMethod: ReplaySourceAccessMethod.api,
            trustTier: ReplaySourceTrustTier.tier1,
            status: ReplaySourceStatus.approved,
            entityCoverage: <String>['events', 'venues', 'communities'],
            temporalStartYear: 2024,
            temporalEndYear: 2025,
            replayRole: 'event_truth',
            legalStatus: 'allowed',
            updateCadence: 'daily',
            structuredExportAvailable: true,
          ),
        ],
      );

      expect(best.year, 2025);
    });
  });
}
