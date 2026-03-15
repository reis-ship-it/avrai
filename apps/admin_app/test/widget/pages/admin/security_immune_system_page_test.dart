import 'package:avrai_admin_app/ui/pages/security_immune_system_page.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/admin/security_immune_system_admin_service.dart';
import 'package:avrai_runtime_os/services/security/countermeasure_propagation_service.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSecurityImmuneSystemAdminService extends Mock
    implements SecurityImmuneSystemAdminService {}

class MockCountermeasurePropagationService extends Mock
    implements CountermeasurePropagationService {}

class MockGovernedRunKernelService extends Mock
    implements GovernedRunKernelService {}

void main() {
  group('SecurityImmuneSystemPage', () {
    late GetIt getIt;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    tearDown(() {
      getIt = GetIt.instance;
      if (getIt.isRegistered<SecurityImmuneSystemAdminService>()) {
        getIt.unregister<SecurityImmuneSystemAdminService>();
      }
      if (getIt.isRegistered<CountermeasurePropagationService>()) {
        getIt.unregister<CountermeasurePropagationService>();
      }
      if (getIt.isRegistered<GovernedRunKernelService>()) {
        getIt.unregister<GovernedRunKernelService>();
      }
    });

    testWidgets('renders cockpit sections from admin snapshot', (tester) async {
      getIt = GetIt.instance;
      final service = MockSecurityImmuneSystemAdminService();
      getIt.registerSingleton<SecurityImmuneSystemAdminService>(service);

      when(
        () => service.watchSnapshot(
          refreshInterval: any(named: 'refreshInterval'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot()));
      when(() => service.getSnapshot(limit: any(named: 'limit')))
          .thenAnswer((_) async => _buildSnapshot());

      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityImmuneSystemPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security Immune System'), findsOneWidget);
      expect(find.textContaining('Release gate: block'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Live Campaign Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Live Campaign Queue'), findsOneWidget);
      expect(find.textContaining('RT-004'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Governed Run Oversight'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Governed Run Oversight'), findsOneWidget);
    });

    testWidgets('routes operator actions through propagation and run services',
        (tester) async {
      getIt = GetIt.instance;
      final adminService = MockSecurityImmuneSystemAdminService();
      final propagationService = MockCountermeasurePropagationService();
      final governedRunKernel = MockGovernedRunKernelService();
      getIt.registerSingleton<SecurityImmuneSystemAdminService>(adminService);
      getIt.registerSingleton<CountermeasurePropagationService>(
          propagationService);
      getIt.registerSingleton<GovernedRunKernelService>(governedRunKernel);

      when(
        () => adminService.watchSnapshot(
          refreshInterval: any(named: 'refreshInterval'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot()));
      when(() => adminService.getSnapshot(limit: any(named: 'limit')))
          .thenAnswer((_) async => _buildSnapshot());
      when(
        () => propagationService.acknowledgeReceipt(
          receiptId: any(named: 'receiptId'),
          actorAlias: any(named: 'actorAlias'),
        ),
      ).thenAnswer(
        (_) async => _buildSnapshot().recentPropagationReceipts.first,
      );
      when(
        () => governedRunKernel.getRun(any()),
      ).thenAnswer((_) async => _buildSnapshot().recentGovernedRuns.first);

      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityImmuneSystemPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Acknowledge'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Acknowledge').first);
      await tester.pumpAndSettle();
      verify(
        () => propagationService.acknowledgeReceipt(
          receiptId: 'receipt-1',
          actorAlias: 'admin_operator',
        ),
      ).called(1);

      await tester.scrollUntilVisible(
        find.text('Details'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      final detailsButton = find.widgetWithText(TextButton, 'Details').last;
      await tester.ensureVisible(detailsButton);
      final detailsWidget = tester.widget<TextButton>(detailsButton);
      expect(detailsWidget.onPressed, isNotNull);
      detailsWidget.onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      verify(() => governedRunKernel.getRun('self-heal-1')).called(1);
    });
  });
}

SecurityImmuneSystemAdminSnapshot _buildSnapshot() {
  const securityScope = TruthScopeDescriptor.defaultSecurity(
    governanceStratum: GovernanceStratum.locality,
    sphereId: 'security_learning',
    familyId: 'federated_update_poisoning',
  );
  const healingScope = TruthScopeDescriptor.defaultHealing(
    governanceStratum: GovernanceStratum.locality,
    sphereId: 'self_healing',
    familyId: 'self_heal_kernel',
  );
  return SecurityImmuneSystemAdminSnapshot(
    generatedAt: DateTime.utc(2026, 3, 14, 12),
    campaignCount: 1,
    pendingReviewCount: 1,
    releaseBlockingFailureCount: 1,
    findingCount: 1,
    memoryCount: 1,
    learningMomentCount: 1,
    bundleCandidateCount: 1,
    propagationReceiptCount: 1,
    scoutCount: 1,
    blockingAutonomyExpansion: true,
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
        truthScope: securityScope,
        status: SecurityCampaignStatus.review,
        trigger: SecurityCampaignTrigger.modelPromotion,
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
        truthScope: securityScope,
        severity: SecurityFindingSeverity.warning,
        title: 'Harness coverage incomplete',
        summary: 'Replay coverage is incomplete for RT-004.',
        disposition: SecurityInterventionDisposition.observe,
        confidence: 0.4,
        createdAt: DateTime.utc(2026, 3, 14, 12),
        recurrenceCount: 0,
        invariantBreach: false,
        evidenceTraceIds: const <String>['trace-1'],
        blockedControls: const <String>[],
      ),
    ],
    recentMemory: <ImmuneMemoryRecord>[
      ImmuneMemoryRecord(
        id: 'memory-1',
        truthScope: securityScope,
        createdAt: DateTime.utc(2026, 3, 14, 12),
        signature: 'security_learning:harness_gap',
        preconditions: const <String>['model_promotion'],
        affectedSurfaces: const <String>['security_learning'],
        containmentActions: const <String>['bounded_degrade'],
        falsePositive: false,
        recurrenceRiskTag: 'new',
        evidenceTraceIds: const <String>['trace-1'],
      ),
    ],
    recentLearningMoments: <SecurityLearningMoment>[
      SecurityLearningMoment(
        id: 'learn-1',
        truthScope: securityScope,
        runId: 'run-1',
        kind: SecurityLearningMomentKind.finding,
        disposition: SecurityInterventionDisposition.observe,
        summary: 'Replay coverage incomplete.',
        createdAt: DateTime.utc(2026, 3, 14, 12),
        evidenceTraceIds: const <String>['trace-1'],
        recurrenceCount: 0,
        falsePositive: false,
      ),
    ],
    recentScouts: <SecurityScoutStatus>[
      SecurityScoutStatus(
        scoutId: 'scout-1',
        alias: 'Edge Scout 1',
        truthScope: securityScope,
        lastSeenAt: DateTime.utc(2026, 3, 14, 12),
        activeCampaignCount: 1,
        probeOnly: true,
      ),
    ],
    recentBundles: <CountermeasureBundleCandidate>[
      CountermeasureBundleCandidate(
        candidateId: 'candidate-1',
        status: CountermeasureBundleCandidateStatus.shadowValidated,
        bundle: SecurityCountermeasureBundle(
          bundleId: 'bundle-1',
          targetScope: securityScope,
          allowedStrata: const <GovernanceStratum>[
            GovernanceStratum.locality,
          ],
          tenantScope: TruthTenantScope.avraiNative,
          evidenceEnvelopeTraceIds: const <String>['trace-1'],
          requiredApprovals: const <String>['security_lead'],
          signature: 'signed',
          signedBy: 'security_lead',
          signedAt: DateTime.utc(2026, 3, 14, 12),
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12),
        updatedAt: DateTime.utc(2026, 3, 14, 12),
        sourceFindingIds: const <String>['finding-1'],
        shadowValidationEvidenceTraceIds: const <String>['trace-1'],
        approvalActors: const <String>['security_lead'],
      ),
    ],
    recentPropagationReceipts: <CountermeasurePropagationReceipt>[
      CountermeasurePropagationReceipt(
        receiptId: 'receipt-1',
        bundleId: 'bundle-1',
        targetScope: securityScope,
        sourceStratum: GovernanceStratum.locality,
        targetStratum: GovernanceStratum.locality,
        activationStage: 'shadow',
        requiredAcknowledgements: 1,
        acknowledgedCount: 0,
        acknowledgedAt: DateTime.utc(2026, 3, 14, 12),
        driftDetected: false,
        staleNode: false,
        rolledBack: false,
      ),
    ],
    recentGovernedRuns: <GovernedRunRecord>[
      GovernedRunRecord(
        id: 'self-heal-1',
        title: 'Mesh recovery',
        hypothesis: 'Redirect the lane into shadow.',
        runKind: GovernedRunKind.selfHeal,
        ownerAgentAlias: 'self_heal',
        lifecycleState: GovernedRunLifecycleState.review,
        environment: GovernedRunEnvironment.shadow,
        disposition: GovernedRunDisposition.boundedDegrade,
        truthScope: healingScope,
        authorityToken: 'self_heal.bounded',
        charter: GovernedRunCharter(
          id: 'self-heal-charter',
          runKind: GovernedRunKind.selfHeal,
          title: 'Mesh recovery',
          objective: 'Redirect the lane into shadow.',
          hypothesis: 'Recover within scope.',
          truthScope: healingScope,
          authorityToken: 'self_heal.bounded',
          environment: GovernedRunEnvironment.shadow,
          allowedExperimentSurfaces: const <String>['self_healing'],
          successMetrics: const <String>['recovery_stable'],
          stopConditions: const <String>['security_hard_stop'],
          hardBans: const <String>['scope_expansion'],
          killConditions: const <String>['invariant_breach'],
          rollbackRefs: const <String>[],
          budget: const GovernedRunBudget(
            maxRuntime: Duration(minutes: 5),
            maxStepCount: 20,
            maxToolInvocations: 8,
            maxEgressRequests: 0,
            maxParallelWorkers: 1,
          ),
          createdAt: DateTime.utc(2026, 3, 14, 12),
          updatedAt: DateTime.utc(2026, 3, 14, 12),
          approvedBy: 'self_heal',
          approvedAt: DateTime.utc(2026, 3, 14, 12),
        ),
        requiresAdminApproval: false,
        sandboxOnly: true,
        modelVersion: 'self-heal-v1',
        policyVersion: 'immune-policy-v1',
        metrics: const <String, double>{'budget_multiplier': 0.5},
        tags: const <String>['self_heal'],
        directives: const <GovernedRunDirective>[],
        checkpoints: const <GovernedRunCheckpoint>[],
        createdAt: DateTime.utc(2026, 3, 14, 12),
        updatedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ],
    releaseGate: SecurityKernelReleaseGateSnapshot(
      generatedAt: DateTime.utc(2026, 3, 14, 12),
      servingAllowed: false,
      degradedReleaseAllowed: false,
      reasonCodes: const <String>['release_blocking_campaigns_red'],
      blockingCampaignIds: const <String>['rt-004-federated-updates'],
      hardStopRunIds: const <String>[],
      blockingBundleIds: const <String>[],
    ),
  );
}
