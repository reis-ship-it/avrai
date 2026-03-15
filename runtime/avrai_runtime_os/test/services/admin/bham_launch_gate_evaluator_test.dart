import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_launch_gate_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = BhamExpansionGateEvaluator();

  BhamLaunchEvidenceSnapshot buildEvidence({
    List<BhamManualEvidenceSlot> manualEvidence =
        const <BhamManualEvidenceSlot>[],
  }) {
    return BhamLaunchEvidenceSnapshot(
      generatedAtUtc: DateTime.utc(2026, 3, 9, 12),
      adminAvailability: true,
      ai2aiSuccessTimePercent: 85,
      routeDeliveryHealth: 0.85,
      moderationQueueHealth: 0,
      quarantineCount: 0,
      breakGlassCount: 0,
      platformHealth: const <String, int>{'ios': 5, 'android': 3},
      manualEvidenceSlots: manualEvidence,
    );
  }

  BhamManualEvidenceSlot launchSlot({
    required String id,
    required BhamManualEvidenceStatus status,
  }) {
    return BhamManualEvidenceSlot(
      slotId: id,
      label: id,
      status: status,
      requiredForLaunch: true,
      updatedAtUtc: DateTime.utc(2026, 3, 9, 11),
    );
  }

  test('returns blocked when a blocking fallback exists', () {
    final report = evaluator.evaluate(
      evidenceSnapshot: buildEvidence(
        manualEvidence: <BhamManualEvidenceSlot>[
          launchSlot(
              id: 'full_monorepo_validation',
              status: BhamManualEvidenceStatus.provided),
        ],
      ),
      fallbackStates: <BhamFallbackState>[
        BhamFallbackState(
          area: BhamFallbackArea.adminObservability,
          status: BhamFallbackStatus.blocked,
          summary: 'Admin availability failed.',
          updatedAtUtc: DateTime.utc(2026, 3, 9, 12),
          blocking: true,
        ),
      ],
      criticalFlowChecks: const <BhamCriticalFlowCheckResult>[
        BhamCriticalFlowCheckResult(
          flowId: 'admin',
          label: 'Admin surfaces',
          status: BhamFlowCheckStatus.pass,
          evidenceSummary: 'Available',
          blocking: true,
        ),
      ],
      manualEvidenceSlots: <BhamManualEvidenceSlot>[
        launchSlot(
          id: 'full_monorepo_validation',
          status: BhamManualEvidenceStatus.provided,
        ),
      ],
    );

    expect(report.status, BhamLaunchGateStatus.blocked);
    expect(report.unresolvedBlockers, contains('Admin availability failed.'));
  });

  test('returns manual review when launch evidence is missing', () {
    final report = evaluator.evaluate(
      evidenceSnapshot: buildEvidence(),
      fallbackStates: <BhamFallbackState>[
        BhamFallbackState(
          area: BhamFallbackArea.ai2aiLocalExchange,
          status: BhamFallbackStatus.healthy,
          summary: 'AI2AI healthy',
          updatedAtUtc: DateTime.utc(2026, 3, 9, 12),
        ),
      ],
      criticalFlowChecks: <BhamCriticalFlowCheckResult>[
        const BhamCriticalFlowCheckResult(
          flowId: 'onboarding',
          label: 'Onboarding',
          status: BhamFlowCheckStatus.pass,
          evidenceSummary: 'Validated',
          blocking: true,
        ),
      ],
      manualEvidenceSlots: <BhamManualEvidenceSlot>[
        launchSlot(
          id: 'heavy_integration_suite',
          status: BhamManualEvidenceStatus.missing,
        ),
      ],
    );

    expect(report.status, BhamLaunchGateStatus.manualReviewRequired);
  });

  test('returns pass with pause when only degraded fallbacks remain', () {
    final launchEvidence = <BhamManualEvidenceSlot>[
      launchSlot(
        id: 'heavy_integration_suite',
        status: BhamManualEvidenceStatus.provided,
      ),
      launchSlot(
        id: 'full_monorepo_validation',
        status: BhamManualEvidenceStatus.provided,
      ),
    ];
    final report = evaluator.evaluate(
      evidenceSnapshot: buildEvidence(manualEvidence: launchEvidence),
      fallbackStates: <BhamFallbackState>[
        BhamFallbackState(
          area: BhamFallbackArea.publicCreation,
          status: BhamFallbackStatus.degraded,
          summary: 'Creation is under watch.',
          updatedAtUtc: DateTime.utc(2026, 3, 9, 12),
        ),
      ],
      criticalFlowChecks: <BhamCriticalFlowCheckResult>[
        const BhamCriticalFlowCheckResult(
          flowId: 'route_planning',
          label: 'Route planning',
          status: BhamFlowCheckStatus.pass,
          evidenceSummary: 'Winning-route receipts recorded.',
          blocking: true,
        ),
      ],
      manualEvidenceSlots: launchEvidence,
    );

    expect(report.status, BhamLaunchGateStatus.passWithPause);
  });
}
