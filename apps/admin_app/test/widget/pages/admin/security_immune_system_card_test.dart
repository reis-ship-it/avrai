import 'package:avrai_admin_app/ui/widgets/security_immune_system_card.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/security_immune_system_admin_service.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSecurityImmuneSystemAdminService extends Mock
    implements SecurityImmuneSystemAdminService {}

void main() {
  group('SecurityImmuneSystemCard', () {
    late GetIt getIt;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    tearDown(() {
      getIt = GetIt.instance;
      if (getIt.isRegistered<SecurityImmuneSystemAdminService>()) {
        getIt.unregister<SecurityImmuneSystemAdminService>();
      }
    });

    testWidgets('renders unavailable state when service is absent', (
      tester,
    ) async {
      getIt = GetIt.instance;
      if (getIt.isRegistered<SecurityImmuneSystemAdminService>()) {
        getIt.unregister<SecurityImmuneSystemAdminService>();
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityImmuneSystemCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security Immune System'), findsOneWidget);
      expect(
        find.text('Security immune-system diagnostics are not registered.'),
        findsOneWidget,
      );
    });

    testWidgets('renders security immune snapshot details when registered', (
      tester,
    ) async {
      getIt = GetIt.instance;
      final service = MockSecurityImmuneSystemAdminService();
      if (getIt.isRegistered<SecurityImmuneSystemAdminService>()) {
        getIt.unregister<SecurityImmuneSystemAdminService>();
      }
      getIt.registerSingleton<SecurityImmuneSystemAdminService>(service);

      when(
        () => service.watchSnapshot(
          refreshInterval: any(named: 'refreshInterval'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot()));
      when(() => service.getSnapshot())
          .thenAnswer((_) async => _buildSnapshot());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityImmuneSystemCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security Immune System'), findsOneWidget);
      expect(find.textContaining('Campaigns: 1'), findsOneWidget);
      expect(find.textContaining('RT-004'), findsOneWidget);
      expect(
          find.textContaining('Harness coverage incomplete'), findsOneWidget);
    });
  });
}

SecurityImmuneSystemAdminSnapshot _buildSnapshot() {
  const scope = TruthScopeDescriptor.defaultSecurity(
    governanceStratum: GovernanceStratum.locality,
    sphereId: 'security_learning',
    familyId: 'federated_update_poisoning',
  );
  return SecurityImmuneSystemAdminSnapshot(
    generatedAt: DateTime.utc(2026, 3, 14, 12),
    campaignCount: 1,
    pendingReviewCount: 1,
    releaseBlockingFailureCount: 0,
    findingCount: 1,
    memoryCount: 0,
    learningMomentCount: 1,
    bundleCandidateCount: 1,
    propagationReceiptCount: 0,
    scoutCount: 1,
    blockingAutonomyExpansion: false,
    stratumCounts: const <String, int>{'locality': 1},
    dispositionCounts: const <String, int>{'observe': 1},
    readinessChecks: const <String, bool>{
      'critical_lanes_mapped': true,
      'no_missing_proof_coverage': false,
      'no_unsigned_active_bundles': true,
      'no_stale_active_rollouts': true,
      'no_critical_hard_stops': true,
      'release_gate_clear_or_approved': false,
    },
    recentRuns: <SecurityImmuneSystemAdminRunRow>[
      SecurityImmuneSystemAdminRunRow(
        runId: 'run-1',
        governedRunId: 'governed-run-1',
        laneId: 'RT-004',
        name: 'Federated Update Poisoning',
        ownerAlias: 'security_learning',
        ownershipArea: 'learning_and_model_integrity',
        truthScope: scope,
        status: SecurityCampaignStatus.review,
        trigger: SecurityCampaignTrigger.schedule,
        disposition: SecurityInterventionDisposition.observe,
        startedAt: DateTime.utc(2026, 3, 14, 12),
        completedAt: DateTime.utc(2026, 3, 14, 12, 1),
        findingCount: 1,
        highestSeverity: SecurityFindingSeverity.warning,
        proofCoverageScore: 0.4,
        autoClearEligible: false,
        missingScenarioIds: const <String>[
          'learningAppliedAfterGovernedIntake'
        ],
        missingProofKinds: const <SecurityProofKind>[
          SecurityProofKind.learningPath,
        ],
      ),
    ],
    recentFindings: <SecurityFinding>[
      SecurityFinding(
        id: 'finding-1',
        campaignRunId: 'run-1',
        truthScope: scope,
        severity: SecurityFindingSeverity.warning,
        title: 'Harness coverage incomplete',
        summary:
            'Campaign executed without a mapped deterministic replay harness.',
        disposition: SecurityInterventionDisposition.observe,
        confidence: 0.35,
        createdAt: DateTime.utc(2026, 3, 14, 12),
        recurrenceCount: 0,
        invariantBreach: false,
        evidenceTraceIds: const <String>['run-1'],
        blockedControls: const <String>[],
      ),
    ],
    recentMemory: const <ImmuneMemoryRecord>[],
    recentLearningMoments: const <SecurityLearningMoment>[],
    recentScouts: const <SecurityScoutStatus>[],
    recentBundles: const <CountermeasureBundleCandidate>[],
    recentPropagationReceipts: const <CountermeasurePropagationReceipt>[],
    recentGovernedRuns: const <GovernedRunRecord>[],
    releaseGate: SecurityKernelReleaseGateSnapshot(
      generatedAt: DateTime.utc(2026, 3, 14, 12),
      servingAllowed: false,
      degradedReleaseAllowed: false,
      reasonCodes: <String>['release_blocking_campaigns_red'],
      blockingCampaignIds: <String>['rt-004-federated-updates'],
      hardStopRunIds: <String>[],
      blockingBundleIds: <String>[],
    ),
  );
}
