import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class SavedDiscoveryAssistantFollowUpOffer {
  const SavedDiscoveryAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final SavedDiscoveryFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class SavedDiscoveryAssistantFollowUpService {
  final SavedDiscoveryFollowUpPromptPlannerService _plannerService;

  SavedDiscoveryAssistantFollowUpService({
    SavedDiscoveryFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<SavedDiscoveryFollowUpPromptPlannerService>()
                ? GetIt.instance<SavedDiscoveryFollowUpPromptPlannerService>()
                : SavedDiscoveryFollowUpPromptPlannerService());

  Future<SavedDiscoveryFollowUpPromptResponse?>
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

  Future<SavedDiscoveryAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return SavedDiscoveryAssistantFollowUpOffer(
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
    return SavedDiscoveryAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(SavedDiscoveryFollowUpPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final locality = plan.boundedContext['where']?.toString().trim() ?? '';
    final whySentence = why.isEmpty
        ? ''
        : ' This stays tied to the earlier save or unsave context: $why.';
    final whereSentence = locality.isEmpty || locality == 'unknown_locality'
        ? ''
        : ' It is scoped to $locality.';
    return 'Quick saved-item follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
