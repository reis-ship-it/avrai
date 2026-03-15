import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';

class BhamExpansionGateEvaluator {
  const BhamExpansionGateEvaluator();

  BhamLaunchGateReport evaluate({
    required BhamLaunchEvidenceSnapshot evidenceSnapshot,
    required List<BhamFallbackState> fallbackStates,
    required List<BhamCriticalFlowCheckResult> criticalFlowChecks,
    required List<BhamManualEvidenceSlot> manualEvidenceSlots,
  }) {
    final expansionGates = _buildExpansionGates(
      evidenceSnapshot: evidenceSnapshot,
      manualEvidenceSlots: manualEvidenceSlots,
    );
    final blockers = <String>[
      ..._launchEvidenceBlockers(manualEvidenceSlots),
      ...fallbackStates
          .where((state) => state.blocking)
          .map((state) => state.summary),
      ...criticalFlowChecks
          .where((check) =>
              check.blocking && check.status == BhamFlowCheckStatus.blocked)
          .map((check) => '${check.label}: ${check.evidenceSummary}'),
    ];

    final hasManualReview = manualEvidenceSlots.any(
          (slot) =>
              slot.requiredForLaunch &&
              slot.status != BhamManualEvidenceStatus.provided,
        ) ||
        criticalFlowChecks.any(
          (check) => check.status == BhamFlowCheckStatus.manualReviewRequired,
        ) ||
        fallbackStates.any(
          (state) => state.status == BhamFallbackStatus.manualReviewRequired,
        );

    final hasPause = fallbackStates.any(
      (state) =>
          state.status == BhamFallbackStatus.degraded ||
          state.status == BhamFallbackStatus.paused,
    );

    final status = blockers.isNotEmpty
        ? BhamLaunchGateStatus.blocked
        : hasManualReview
            ? BhamLaunchGateStatus.manualReviewRequired
            : hasPause
                ? BhamLaunchGateStatus.passWithPause
                : BhamLaunchGateStatus.pass;

    return BhamLaunchGateReport(
      generatedAtUtc: evidenceSnapshot.generatedAtUtc,
      status: status,
      evidenceSnapshot: evidenceSnapshot,
      fallbackStates: fallbackStates,
      criticalFlowChecks: criticalFlowChecks,
      expansionGates: expansionGates,
      unresolvedBlockers: blockers,
      signoffInputs: manualEvidenceSlots,
    );
  }

  List<String> _launchEvidenceBlockers(
    List<BhamManualEvidenceSlot> slots,
  ) {
    return slots
        .where(
          (slot) =>
              slot.requiredForLaunch &&
              slot.status == BhamManualEvidenceStatus.stale,
        )
        .map(
          (slot) =>
              '${slot.label} is stale and must be refreshed for launch review.',
        )
        .toList();
  }

  List<BhamExpansionGateResult> _buildExpansionGates({
    required BhamLaunchEvidenceSnapshot evidenceSnapshot,
    required List<BhamManualEvidenceSlot> manualEvidenceSlots,
  }) {
    BhamManualEvidenceSlot? slot(String id) {
      for (final item in manualEvidenceSlots) {
        if (item.slotId == id) {
          return item;
        }
      }
      return null;
    }

    BhamExpansionGateResult manualGate({
      required String gateId,
      required String description,
      required String slotId,
      String? thresholdDescription,
    }) {
      final evidence = slot(slotId);
      if (evidence == null ||
          evidence.status == BhamManualEvidenceStatus.missing) {
        return BhamExpansionGateResult(
          gateId: gateId,
          description: description,
          status: BhamLaunchGateStatus.manualReviewRequired,
          summary:
              'Manual evidence is missing${thresholdDescription == null ? '' : ' ($thresholdDescription)'}',
        );
      }
      if (evidence.status == BhamManualEvidenceStatus.stale) {
        return BhamExpansionGateResult(
          gateId: gateId,
          description: description,
          status: BhamLaunchGateStatus.blocked,
          summary: 'Manual evidence is stale and must be refreshed.',
        );
      }
      return BhamExpansionGateResult(
        gateId: gateId,
        description: description,
        status: BhamLaunchGateStatus.pass,
        summary: evidence.summary ?? 'Manual evidence provided.',
      );
    }

    final ai2aiStatus = evidenceSnapshot.ai2aiSuccessTimePercent == null
        ? BhamLaunchGateStatus.manualReviewRequired
        : evidenceSnapshot.ai2aiSuccessTimePercent! >= 80.0
            ? BhamLaunchGateStatus.pass
            : BhamLaunchGateStatus.blocked;
    final ai2aiSummary = evidenceSnapshot.ai2aiSuccessTimePercent == null
        ? 'AI2AI success-time evidence is missing.'
        : '${evidenceSnapshot.ai2aiSuccessTimePercent!.toStringAsFixed(1)}% observed; 80% required.';

    final adminStatus = manualGate(
      gateId: 'admin_views_continuous_14d',
      description:
          'All critical admin views work continuously for 14 days without breaking.',
      slotId: 'admin_views_continuous_14d',
      thresholdDescription: '14-day uptime confirmation',
    );

    final queueFreshness = manualGate(
      gateId: 'flagged_queue_under_24h',
      description:
          'No flagged-item queue is older than 24 hours for 14 straight days.',
      slotId: 'flagged_queue_under_24h',
      thresholdDescription: '14-day freshness confirmation',
    );

    return <BhamExpansionGateResult>[
      manualGate(
        gateId: 'sev1_free_14d',
        description: 'No Sev-1 incidents for 14 straight days.',
        slotId: 'sev1_free_14d',
        thresholdDescription: '14-day incident-free run',
      ),
      manualGate(
        gateId: 'zero_harmful_suggestions',
        description:
            'Zero confirmed harmful, illegal, or trust-breaking suggestions.',
        slotId: 'zero_harmful_suggestions',
      ),
      BhamExpansionGateResult(
        gateId: 'ai2ai_success_80',
        description:
            'AI2AI success-time is at least 80% and no cross-platform regression remains open.',
        status: ai2aiStatus,
        summary: ai2aiSummary,
      ),
      manualGate(
        gateId: 'recommendation_action_band',
        description:
            'Recommendation action rate stays in band and at least 50% of testers engage weekly.',
        slotId: 'recommendation_action_band',
      ),
      manualGate(
        gateId: 'personal_agent_coherence_80',
        description:
            'Personal agents are coherent for at least 80% of testers.',
        slotId: 'personal_agent_coherence_80',
      ),
      manualGate(
        gateId: 'birmingham_locality_correct_14d',
        description:
            'Birmingham locality outputs stay directionally correct for 14 days.',
        slotId: 'birmingham_locality_correct_14d',
      ),
      adminStatus,
      queueFreshness,
      manualGate(
        gateId: 'weekly_use_intent_70',
        description: 'At least 70% of testers would keep using the app weekly.',
        slotId: 'weekly_use_intent_70',
      ),
      manualGate(
        gateId: 'helps_find_better_60',
        description:
            'At least 60% of testers say AVRAI helps them find better places, people, or events.',
        slotId: 'helps_find_better_60',
      ),
      manualGate(
        gateId: 'meaningful_offline_flow_80',
        description:
            'At least 80% of testers complete a meaningful offline-first flow.',
        slotId: 'meaningful_offline_flow_80',
      ),
    ];
  }
}
