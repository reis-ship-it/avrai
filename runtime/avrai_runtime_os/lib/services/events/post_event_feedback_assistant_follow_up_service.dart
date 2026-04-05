import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:get_it/get_it.dart';

class PostEventFeedbackAssistantFollowUpOffer {
  const PostEventFeedbackAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final PostEventFeedbackPromptPlan plan;
  final String assistantPrompt;
}

class PostEventFeedbackAssistantFollowUpService {
  final PostEventFeedbackPromptPlannerService _plannerService;

  PostEventFeedbackAssistantFollowUpService({
    PostEventFeedbackPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<PostEventFeedbackPromptPlannerService>()
                ? GetIt.instance<PostEventFeedbackPromptPlannerService>()
                : PostEventFeedbackPromptPlannerService());

  Future<PostEventFeedbackPromptResponse?>
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

  Future<PostEventFeedbackAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return PostEventFeedbackAssistantFollowUpOffer(
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
    return PostEventFeedbackAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(PostEventFeedbackPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final locality = plan.boundedContext['where']?.toString().trim() ?? '';
    final whySentence = why.isEmpty
        ? ''
        : ' This stays tied to the earlier event feedback context: $why.';
    final whereSentence = locality.isEmpty ||
            locality == 'unknown_event_locality' ||
            locality == 'unknown_locality'
        ? ''
        : ' It is scoped to $locality.';
    return 'Quick event follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
