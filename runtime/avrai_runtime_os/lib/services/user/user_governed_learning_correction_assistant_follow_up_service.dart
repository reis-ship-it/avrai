import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class UserGovernedLearningCorrectionAssistantFollowUpOffer {
  const UserGovernedLearningCorrectionAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final UserGovernedLearningCorrectionFollowUpPlan plan;
  final String assistantPrompt;
}

class UserGovernedLearningCorrectionAssistantFollowUpService {
  final UserGovernedLearningCorrectionFollowUpPromptPlannerService
      _plannerService;

  UserGovernedLearningCorrectionAssistantFollowUpService({
    UserGovernedLearningCorrectionFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance.isRegistered<
                    UserGovernedLearningCorrectionFollowUpPromptPlannerService>()
                ? GetIt.instance<
                    UserGovernedLearningCorrectionFollowUpPromptPlannerService>()
                : UserGovernedLearningCorrectionFollowUpPromptPlannerService());

  Future<UserGovernedLearningCorrectionFollowUpResponse?>
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

  Future<UserGovernedLearningCorrectionAssistantFollowUpOffer?>
      maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return UserGovernedLearningCorrectionAssistantFollowUpOffer(
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
    return UserGovernedLearningCorrectionAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) {
    final targetSummary = plan.targetSummary.trim();
    final correctionText = plan.correctionText.trim();
    final where = plan.boundedContext['where']?.toString().trim() ?? '';
    final whereSentence = where.isEmpty || where == 'unknown_locality'
        ? ''
        : ' It is scoped to $where.';
    return 'Quick correction follow-up: ${plan.promptQuestion} This stays bounded to your earlier correction about "$targetSummary": "$correctionText".$whereSentence';
  }
}
