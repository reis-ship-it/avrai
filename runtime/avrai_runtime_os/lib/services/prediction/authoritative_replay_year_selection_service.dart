import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';

class AuthoritativeReplayYearSelection {
  const AuthoritativeReplayYearSelection({
    required this.selectedScore,
    required this.candidateScores,
  });

  final ReplayYearCompletenessScore selectedScore;
  final List<ReplayYearCompletenessScore> candidateScores;
}

class AuthoritativeReplayYearSelectionService {
  const AuthoritativeReplayYearSelectionService({
    required this.completenessService,
  });

  final ReplayYearCompletenessService completenessService;

  AuthoritativeReplayYearSelection select({
    required List<int> candidateYears,
    required List<ReplaySourceDescriptor> sources,
  }) {
    final candidateScores = completenessService.scoreYears(
      candidateYears: candidateYears,
      sources: sources,
    )..sort((left, right) {
        final scoreCompare = right.overallScore.compareTo(left.overallScore);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        if (left.year == 2025 && right.year != 2025) {
          return -1;
        }
        if (right.year == 2025 && left.year != 2025) {
          return 1;
        }
        return right.year.compareTo(left.year);
      });

    return AuthoritativeReplayYearSelection(
      selectedScore: candidateScores.first,
      candidateScores: candidateScores,
    );
  }
}
