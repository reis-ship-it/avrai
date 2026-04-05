import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class ReservationOperationalAssistantFollowUpOffer {
  const ReservationOperationalAssistantFollowUpOffer({
    required this.plan,
    required this.assistantPrompt,
  });

  final ReservationOperationalFollowUpPromptPlan plan;
  final String assistantPrompt;
}

class ReservationOperationalAssistantFollowUpService {
  final ReservationOperationalFollowUpPromptPlannerService _plannerService;

  ReservationOperationalAssistantFollowUpService({
    ReservationOperationalFollowUpPromptPlannerService? plannerService,
  }) : _plannerService = plannerService ??
            (GetIt.instance.isRegistered<
                    ReservationOperationalFollowUpPromptPlannerService>()
                ? GetIt.instance<
                    ReservationOperationalFollowUpPromptPlannerService>()
                : ReservationOperationalFollowUpPromptPlannerService());

  Future<ReservationOperationalFollowUpPromptResponse?>
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

  Future<ReservationOperationalAssistantFollowUpOffer?> maybeOfferFollowUp({
    required String ownerUserId,
  }) async {
    final active =
        await _plannerService.activeAssistantFollowUpPlan(ownerUserId);
    if (active != null) {
      return ReservationOperationalAssistantFollowUpOffer(
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
    return ReservationOperationalAssistantFollowUpOffer(
      plan: refreshed,
      assistantPrompt: _buildAssistantPrompt(refreshed),
    );
  }

  String _buildAssistantPrompt(
    ReservationOperationalFollowUpPromptPlan plan,
  ) {
    final why = plan.boundedContext['why']?.toString().trim() ?? '';
    final target =
        plan.targetLabel.trim().isEmpty ? 'this reservation' : plan.targetLabel;
    final whySentence =
        why.isEmpty ? '' : ' This stays bounded to the earlier signal: $why.';
    return 'Quick reservation follow-up about $target: ${plan.promptQuestion}$whySentence';
  }
}
