import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:get_it/get_it.dart';

class RecommendationFeedbackAssistantFollowUpOffer {
  const RecommendationFeedbackAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final RecommendationFeedbackPromptPlan plan;
  final String assistantPrompt;
}

class RecommendationFeedbackAssistantFollowUpService {
  final RecommendationFeedbackPromptPlannerService _plannerService;

  RecommendationFeedbackAssistantFollowUpService({
    RecommendationFeedbackPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<RecommendationFeedbackPromptPlannerService>()
                ? GetIt.instance<RecommendationFeedbackPromptPlannerService>()
                : RecommendationFeedbackPromptPlannerService());

  Future<RecommendationFeedbackPromptResponse?>
      captureActiveAssistantFollowUpResponse({
    required String ownerUserId,
    required String responseText,
  }) async {
    final plan = await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (plan == null || responseText.trim().isEmpty) {
      return null;
    }
    return _plannerService.completePlanWithResponse(
      ownerUserId: ownerUserId,
      planId: plan.planId,
      responseText: responseText,
      sourceSurface: 'assistant_follow_up_chat',
    );
  }

  Future<RecommendationFeedbackAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return RecommendationFeedbackAssistantFollowUpOffer(
        plan: active,
        assistantPrompt: _buildAssistantPrompt(active),
      );
    }

    final candidates = await _plannerService.listPendingPlans(
      ownerUserId,
      limit: 1,
    );
    final selected = candidates.isEmpty ? null : candidates.first;
    if (selected == null) {
      return null;
    }
    await _plannerService.markPlanOfferedForAssistant(
      ownerUserId: ownerUserId,
      planId: selected.planId,
    );
    final refreshed =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId) ??
            selected;
    return RecommendationFeedbackAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(RecommendationFeedbackPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final locality = plan.boundedContext['where']?.toString().trim() ?? '';
    final whySentence = why.isEmpty ||
            why == 'No explicit recommendation attribution was attached.'
        ? ''
        : ' This stays tied to the earlier recommendation context: $why.';
    final whereSentence = locality.isEmpty || locality == 'unknown_locality'
        ? ''
        : ' It is scoped to $locality.';
    return 'Quick follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
