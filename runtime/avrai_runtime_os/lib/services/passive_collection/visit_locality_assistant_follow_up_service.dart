import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class VisitLocalityAssistantFollowUpOffer {
  const VisitLocalityAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final VisitLocalityFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class VisitLocalityAssistantFollowUpService {
  VisitLocalityAssistantFollowUpService({
    VisitLocalityFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<VisitLocalityFollowUpPromptPlannerService>()
                ? GetIt.instance<VisitLocalityFollowUpPromptPlannerService>()
                : VisitLocalityFollowUpPromptPlannerService());

  final VisitLocalityFollowUpPromptPlannerService _plannerService;

  Future<VisitLocalityFollowUpPromptResponse?>
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

  Future<VisitLocalityAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return VisitLocalityAssistantFollowUpOffer(
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
    return VisitLocalityAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(VisitLocalityFollowUpPromptPlan plan) {
    final where = plan.boundedContext['where']?.toString().trim() ?? '';
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final whereSentence = where.isEmpty || where == 'unknown_locality'
        ? ''
        : ' It stays scoped to $where.';
    final whySentence = why.isEmpty ? '' : ' This reflects $why.';
    return 'Quick ${plan.observationKind} follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
