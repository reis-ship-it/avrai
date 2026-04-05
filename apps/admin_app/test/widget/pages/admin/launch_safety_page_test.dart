import 'package:avrai_admin_app/ui/pages/launch_safety_page.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockBhamAdminOperationsService extends Mock
    implements BhamAdminOperationsService {}

class _MockAdminRuntimeGovernanceService extends Mock
    implements AdminRuntimeGovernanceService {}

void main() {
  group('LaunchSafetyPage Widget Tests', () {
    late _MockBhamAdminOperationsService opsService;
    late _MockAdminRuntimeGovernanceService governanceService;

    setUp(() {
      opsService = _MockBhamAdminOperationsService();
      governanceService = _MockAdminRuntimeGovernanceService();
      if (GetIt.instance.isRegistered<BhamAdminOperationsService>()) {
        GetIt.instance.unregister<BhamAdminOperationsService>();
      }
      if (GetIt.instance.isRegistered<AdminRuntimeGovernanceService>()) {
        GetIt.instance.unregister<AdminRuntimeGovernanceService>();
      }
      GetIt.instance.registerSingleton<BhamAdminOperationsService>(opsService);
      GetIt.instance
          .registerSingleton<AdminRuntimeGovernanceService>(governanceService);

      final dashboard = GodModeDashboardData(
        totalUsers: 20,
        activeUsers: 8,
        totalBusinessAccounts: 0,
        activeConnections: 5,
        totalCommunications: 12,
        systemHealth: 0.92,
        aggregatePrivacyMetrics: AggregatePrivacyMetrics(
          meanOverallPrivacyScore: 0.98,
          meanAnonymizationLevel: 0.98,
          meanDataSecurityScore: 0.98,
          meanEncryptionStrength: 0.98,
          meanComplianceRate: 0.98,
          totalPrivacyViolations: 0,
          userCount: 8,
          lastUpdated: DateTime.utc(2026, 3, 8, 12),
        ),
        authMix: AuthMixSummary(
          signupProviderCounts: const <String, int>{},
          lastSignInProviderCounts: AuthMixBucket(
              totalCounts: const <String, int>{},
              recentCounts: const <String, int>{}),
          lastSignInPlatformCounts: AuthMixBucket(
            totalCounts: const <String, int>{'ios': 5, 'android': 3},
            recentCounts: const <String, int>{'ios': 2, 'android': 1},
          ),
        ),
        lastUpdated: DateTime.utc(2026, 3, 8, 12),
      );

      when(() => governanceService.getDashboardData())
          .thenAnswer((_) async => dashboard);
      when(() => opsService.getHealthSnapshot(
          platformHealth: any(named: 'platformHealth'))).thenAnswer(
        (_) async => const AdminHealthSnapshot(
          adminAvailable: true,
          sessionValid: true,
          deviceApproved: true,
          internalUseAgreementVerified: true,
          openBreakGlassCount: 0,
          moderationQueueCount: 2,
          quarantinedCount: 1,
          failedDeliveryCount: 0,
          pendingFeedbackCount: 1,
          routeDeliveryHealth: 0.75,
          platformHealth: <String, int>{'ios': 5, 'android': 3},
          deviceStatusLabel: 'Approved desktop admin device',
        ),
      );
      when(() => opsService.getLaunchGateMetrics(
          platformHealth: any(named: 'platformHealth'))).thenAnswer(
        (_) async => const LaunchGateAdminMetrics(
          availability: true,
          moderationQueueHealth: 2,
          quarantineCount: 1,
          falsityResetCount: 0,
          breakGlassCount: 0,
          routeDeliveryHealth: 0.75,
          platformHealth: <String, int>{'ios': 5, 'android': 3},
        ),
      );
      when(() => opsService.buildLaunchGateReport(
          platformHealth: any(named: 'platformHealth'))).thenAnswer(
        (_) async => BhamLaunchGateReport(
          generatedAtUtc: DateTime.utc(2026, 3, 9, 12),
          status: BhamLaunchGateStatus.passWithPause,
          evidenceSnapshot: BhamLaunchEvidenceSnapshot(
            generatedAtUtc: DateTime.utc(2026, 3, 9, 12),
            adminAvailability: true,
            ai2aiSuccessTimePercent: 81,
            routeDeliveryHealth: 0.75,
            moderationQueueHealth: 2,
            quarantineCount: 1,
            breakGlassCount: 0,
            platformHealth: <String, int>{'ios': 5, 'android': 3},
            manualEvidenceSlots: <BhamManualEvidenceSlot>[
              BhamManualEvidenceSlot(
                slotId: 'full_monorepo_validation',
                label: 'Full monorepo validation signoff',
                status: BhamManualEvidenceStatus.provided,
                requiredForLaunch: true,
              ),
            ],
          ),
          fallbackStates: <BhamFallbackState>[
            BhamFallbackState(
              area: BhamFallbackArea.ai2aiLocalExchange,
              status: BhamFallbackStatus.degraded,
              summary: 'AI2AI is degraded but usable.',
              updatedAtUtc: DateTime.utc(2026, 3, 9, 12),
            ),
          ],
          criticalFlowChecks: <BhamCriticalFlowCheckResult>[
            const BhamCriticalFlowCheckResult(
              flowId: 'admin_surfaces',
              label: 'Admin surfaces',
              status: BhamFlowCheckStatus.pass,
              evidenceSummary: 'Admin surfaces are available.',
              blocking: true,
            ),
          ],
          expansionGates: const <BhamExpansionGateResult>[
            BhamExpansionGateResult(
              gateId: 'sev1_free_14d',
              description: 'No Sev-1 incidents for 14 straight days.',
              status: BhamLaunchGateStatus.manualReviewRequired,
              summary: 'Manual evidence is still pending.',
            ),
          ],
          unresolvedBlockers: const <String>[
            'BHAM heavy consumer suite signoff is still required.',
          ],
          signoffInputs: <BhamManualEvidenceSlot>[
            const BhamManualEvidenceSlot(
              slotId: 'heavy_integration_suite',
              label: 'BHAM heavy consumer suite signoff',
              status: BhamManualEvidenceStatus.missing,
              requiredForLaunch: true,
            ),
          ],
        ),
      );
    });

    tearDown(() async {
      if (GetIt.instance.isRegistered<BhamAdminOperationsService>()) {
        GetIt.instance.unregister<BhamAdminOperationsService>();
      }
      if (GetIt.instance.isRegistered<AdminRuntimeGovernanceService>()) {
        GetIt.instance.unregister<AdminRuntimeGovernanceService>();
      }
      await WidgetTestHelpers.cleanupWidgetTestEnvironment();
    });

    testWidgets('renders launch safety metrics and carry note',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LaunchSafetyPage(),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Launch Safety'), findsOneWidget);
      expect(find.textContaining('Wave 6 admin availability is passing'),
          findsOneWidget);
      expect(find.textContaining('Wave 7 launch gate: Pass with pause'),
          findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('iOS sign-ins'),
        250,
      );
      await tester.pumpAndSettle();
      expect(find.text('iOS sign-ins'), findsOneWidget);
      expect(find.text('Android sign-ins'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Fallback and pause state'),
        250,
      );
      await tester.pumpAndSettle();
      expect(
          find.textContaining('AI2AI is degraded but usable.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Launch blockers'),
        250,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Launch blockers'), findsOneWidget);
    });

    testWidgets('renders command-center handoff context when provided',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LaunchSafetyPage(
          initialFocus: 'launch_gate',
          initialAttention: 'launch_safety_blocked',
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Command Center handoff'), findsOneWidget);
      expect(find.text('Focus: launch_gate'), findsOneWidget);
      expect(find.text('Attention: launch_safety_blocked'), findsOneWidget);
    });
  });
}
