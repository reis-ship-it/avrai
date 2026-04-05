import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class OnboardingAssistantFollowUpOffer {
  const OnboardingAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final OnboardingFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class OnboardingAssistantFollowUpService {
  final OnboardingFollowUpPromptPlannerService _plannerService;

  OnboardingAssistantFollowUpService({
    OnboardingFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance
                    .isRegistered<OnboardingFollowUpPromptPlannerService>()
                ? GetIt.instance<OnboardingFollowUpPromptPlannerService>()
                : OnboardingFollowUpPromptPlannerService());

  Future<OnboardingFollowUpPromptResponse?>
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

  Future<OnboardingAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return OnboardingAssistantFollowUpOffer(
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
    return OnboardingAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(OnboardingFollowUpPromptPlan plan) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final where = plan.homebase?.trim() ?? '';
    final whySentence = why.isEmpty
        ? ''
        : ' This stays bounded to your original onboarding signal: $why.';
    final whereSentence = where.isEmpty
        ? ''
        : ' It is scoped to what you first told AVRAI about $where.';
    return 'Quick onboarding follow-up: ${plan.promptQuestion}$whySentence$whereSentence';
  }
}
