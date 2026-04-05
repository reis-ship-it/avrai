import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class CommunityAssistantFollowUpOffer {
  const CommunityAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final CommunityFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class CommunityAssistantFollowUpService {
  final CommunityFollowUpPromptPlannerService _plannerService;

  CommunityAssistantFollowUpService({
    CommunityFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<CommunityFollowUpPromptPlannerService>()
                ? GetIt.instance<CommunityFollowUpPromptPlannerService>()
                : CommunityFollowUpPromptPlannerService());

  Future<CommunityFollowUpPromptResponse?>
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

  Future<CommunityAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return CommunityAssistantFollowUpOffer(
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
    return CommunityAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(CommunityFollowUpPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final where = plan.boundedContext['where']?.toString().trim() ?? '';
    final whySentence =
        why.isEmpty ? '' : ' This stays bounded to the earlier signal: $why.';
    final whereSentence = where.isEmpty
        ? ''
        : ' It is scoped to ${where == 'unknown_locality' ? 'the current community context' : where}.';
    return 'Quick community follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
