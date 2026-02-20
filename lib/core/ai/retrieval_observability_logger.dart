import 'package:avrai/core/ai/unified_retrieval_contract.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';

/// Logs retrieval lane diagnostics and final outcomes into tracking storage.
class RetrievalObservabilityLogger {
  const RetrievalObservabilityLogger({required this.trackingService});

  final AIImprovementTrackingService trackingService;

  Future<void> logRetrievalSession({
    required String userId,
    required UnifiedRetrievalQuery query,
    required Map<String, List<UnifiedRetrievedItem>> laneCandidates,
    required UnifiedRetrievalResponse fusedResponse,
    required int latencyBudgetMs,
    required String finalUserOutcome,
  }) {
    final laneCandidateSets = <String, List<String>>{};
    laneCandidates.forEach((lane, items) {
      laneCandidateSets[lane] =
          items.map((item) => item.itemId).toList(growable: false);
    });

    final scoreContributionsByItem = <String, Map<String, double>>{};
    for (final item in fusedResponse.items) {
      scoreContributionsByItem[item.itemId] =
          Map<String, double>.from(item.rankingTrace.scoreContributions);
    }

    return trackingService.recordRetrievalObservability(
      userId: userId,
      queryId: query.queryId,
      queryText: query.queryText,
      laneCandidateSets: laneCandidateSets,
      scoreContributionsByItem: scoreContributionsByItem,
      selectedTopK: fusedResponse.items
          .map((item) => item.itemId)
          .toList(growable: false),
      latencyBudgetMs: latencyBudgetMs,
      actualLatencyMs: fusedResponse.latencyMs,
      finalOutcome: finalUserOutcome,
    );
  }
}
