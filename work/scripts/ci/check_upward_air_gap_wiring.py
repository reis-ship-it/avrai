#!/usr/bin/env python3
"""
Guard: mandatory upward-intake runtime callers must pass caller-issued air-gap artifacts.
"""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

CALL_RULES = {
    "runtime/avrai_runtime_os/lib/services/user/personality_agent_chat_service.dart": [
        "stagePersonalAgentHumanIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart": [
        "stageAi2AiIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/onboarding/onboarding_data_service.dart": [
        "stageOnboardingIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/onboarding/onboarding_follow_up_planner_service.dart": [
        "stageOnboardingFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/recommendations/recommendation_feedback_service.dart": [
        "stageRecommendationFeedbackIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/recommendations/recommendation_feedback_prompt_planner_service.dart": [
        "stageRecommendationFeedbackFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/recommendations/saved_discovery_service.dart": [
        "stageSavedDiscoveryCurationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/recommendations/saved_discovery_follow_up_planner_service.dart": [
        "stageSavedDiscoveryFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/reservation/automatic_check_in_service.dart": [
        "stageVisitObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/passive_collection/dwell_event_intake_adapter.dart": [
        "stageLocalityObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/passive_collection/visit_locality_follow_up_planner_service.dart": [
        "stageVisitLocalityFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/events/post_event_feedback_service.dart": [
        "stageEventFeedbackIntake(",
        "stagePartnerRatingIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/events/post_event_feedback_prompt_planner_service.dart": [
        "stageEventFeedbackFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/events/event_learning_signal_service.dart": [
        "stageEventOutcomeIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/business/business_account_service.dart": [
        "stageBusinessOperatorInputIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/business/business_operator_follow_up_planner_service.dart": [
        "stageBusinessOperatorFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/community/community_service.dart": [
        "stageCommunityCoordinationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/community/community_validation_service.dart": [
        "stageCommunityValidationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/community/community_follow_up_planner_service.dart": [
        "stageCommunityFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/user/user_governed_learning_correction_follow_up_planner_service.dart": [
        "stageExplicitCorrectionFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/reservation/reservation_sharing_service.dart": [
        "stageReservationSharingIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/reservation/reservation_calendar_service.dart": [
        "stageReservationCalendarIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/reservation/reservation_recurrence_service.dart": [
        "stageReservationRecurrenceIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/reservation/reservation_operational_follow_up_planner_service.dart": [
        "stageReservationOperationalFollowUpResponseIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/admin/signature_health_admin_service.dart": [
        "stageSupervisorAssistantObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/admin/replay_simulation_admin_service.dart": [
        "stageSupervisorAssistantObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/admin/reality_model_checkin_service.dart": [
        "stageSupervisorAssistantObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/admin/planning_truth_surface_admin_service.dart": [
        "stageSupervisorAssistantObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/services/admin/forecast_kernel_admin_service.dart": [
        "stageSupervisorAssistantObservationIntake(",
    ],
    "runtime/avrai_runtime_os/lib/kernel/service_contracts/urk_kernel_control_plane_service.dart": [
        "stageKernelOfflineEvidenceReceiptIntake(",
    ],
    "runtime/avrai_runtime_os/lib/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart": [
        "stageKernelOfflineEvidenceReceiptIntake(",
    ],
}

REQUIRED_SOURCE_PROVIDERS = {
    "personal_agent_human_intake",
    "explicit_correction_intake",
    "ai2ai_chat_intake",
    "onboarding_intake",
    "onboarding_follow_up_response_intake",
    "recommendation_feedback_intake",
    "recommendation_feedback_follow_up_response_intake",
    "event_feedback_follow_up_response_intake",
    "visit_locality_follow_up_response_intake",
    "community_follow_up_response_intake",
    "business_operator_follow_up_response_intake",
    "explicit_correction_follow_up_response_intake",
    "saved_discovery_curation_intake",
    "saved_discovery_follow_up_response_intake",
    "business_operator_input_intake",
    "community_coordination_intake",
    "community_validation_intake",
    "reservation_sharing_intake",
    "reservation_calendar_sync_intake",
    "reservation_recurrence_intake",
    "reservation_operational_follow_up_response_intake",
    "visit_observation_intake",
    "locality_observation_intake",
    "event_feedback_intake",
    "partner_rating_intake",
    "event_outcome_intake",
    "supervisor_bounded_observation_intake",
    "assistant_bounded_observation_intake",
    "kernel_offline_evidence_receipt_intake",
}


def _extract_call_block(content: str, needle: str) -> str:
    start = content.find(needle)
    if start == -1:
        raise ValueError(f"call_not_found:{needle}")
    depth = 0
    end = -1
    for idx in range(start, len(content)):
        char = content[idx]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                end = idx
                break
    if end == -1:
        raise ValueError(f"unterminated_call:{needle}")
    return content[start : end + 1]


def _extract_required_sources(content: str) -> set[str]:
    marker = "static const Set<String> callerIssuedAirGapSourceProviders"
    start = content.find(marker)
    if start == -1:
        raise ValueError("missing callerIssuedAirGapSourceProviders")
    brace_start = content.find("{", start)
    brace_end = content.find("};", brace_start)
    if brace_start == -1 or brace_end == -1:
        raise ValueError("unterminated callerIssuedAirGapSourceProviders")
    block = content[brace_start:brace_end]
    return {
        line.strip().strip(",").strip("'")
        for line in block.splitlines()
        if "'" in line
    }


def main() -> int:
    failures: list[str] = []

    intake_service_path = ROOT / "runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart"
    intake_service_content = intake_service_path.read_text(encoding="utf-8")
    try:
        declared_sources = _extract_required_sources(intake_service_content)
    except ValueError as exc:
        failures.append(f"governed_upward_learning_intake_service.dart:{exc}")
    else:
        if declared_sources != REQUIRED_SOURCE_PROVIDERS:
            failures.append(
                "governed_upward_learning_intake_service.dart:callerIssuedAirGapSourceProviders drifted from guardrail baseline"
            )

    for rel_path, calls in CALL_RULES.items():
        path = ROOT / rel_path
        if not path.exists():
            failures.append(f"missing_file:{rel_path}")
            continue
        content = path.read_text(encoding="utf-8")
        for call in calls:
            try:
                block = _extract_call_block(content, call)
            except ValueError as exc:
                failures.append(f"{rel_path}:{exc}")
                continue
            if "airGapArtifact:" not in block:
                failures.append(f"{rel_path}:{call}:missing airGapArtifact argument")

    if failures:
        print("Upward air-gap wiring check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Upward air-gap wiring check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
