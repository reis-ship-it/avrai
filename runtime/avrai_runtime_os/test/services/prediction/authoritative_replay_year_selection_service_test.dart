import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the best authoritative replay year', () {
    const selectionService = AuthoritativeReplayYearSelectionService(
      completenessService: ReplayYearCompletenessService(),
    );

    final selection = selectionService.select(
      candidateYears: const <int>[2024, 2025, 2023],
      sources: const <ReplaySourceDescriptor>[
        ReplaySourceDescriptor(
          sourceName: 'City Events',
          sourceType: 'official_calendar',
          accessMethod: ReplaySourceAccessMethod.api,
          trustTier: ReplaySourceTrustTier.tier1,
          status: ReplaySourceStatus.ingested,
          entityCoverage: <String>['events', 'venues', 'communities'],
          temporalStartYear: 2024,
          temporalEndYear: 2025,
          replayRole: 'event_truth',
          legalStatus: 'allowed',
          updateCadence: 'daily',
          richestYear: 2025,
          structuredExportAvailable: true,
        ),
      ],
    );

    expect(selection.selectedScore.year, 2025);
    expect(selection.candidateScores.first.year, 2025);
  });
}
