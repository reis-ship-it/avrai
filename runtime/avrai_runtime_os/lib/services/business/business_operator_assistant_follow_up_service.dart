import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class BusinessOperatorAssistantFollowUpOffer {
  const BusinessOperatorAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final BusinessOperatorFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class BusinessOperatorAssistantFollowUpService {
  final BusinessOperatorFollowUpPromptPlannerService _plannerService;

  BusinessOperatorAssistantFollowUpService({
    BusinessOperatorFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance.isRegistered<
                    BusinessOperatorFollowUpPromptPlannerService>()
                ? GetIt.instance<BusinessOperatorFollowUpPromptPlannerService>()
                : BusinessOperatorFollowUpPromptPlannerService());

  Future<BusinessOperatorFollowUpPromptResponse?>
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

  Future<BusinessOperatorAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return BusinessOperatorAssistantFollowUpOffer(
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
    return BusinessOperatorAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(BusinessOperatorFollowUpPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final where = plan.boundedContext['where']?.toString().trim() ?? '';
    final whySentence = why.isEmpty
        ? ''
        : ' This stays bounded to the earlier business change: $why.';
    final whereSentence = where.isEmpty
        ? ''
        : ' It is scoped to ${where == 'unknown' ? 'the current business context' : where}.';
    return 'Quick business follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
