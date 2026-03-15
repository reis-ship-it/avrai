import 'package:avrai_admin_app/ui/pages/ai2ai_admin_dashboard.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AI2AIAdminDashboard
/// Tests AI2AI admin dashboard UI
void main() {
  group('AI2AIAdminDashboard Widget Tests', () {
    tearDown(() async {
      if (GetIt.instance.isRegistered<HeadlessAvraiOsHost>()) {
        await GetIt.instance.unregister<HeadlessAvraiOsHost>();
      }
    });

    testWidgets('displays all required UI elements',
        (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AI2AIAdminDashboard(useThreeJsVisualizations: false),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify dashboard UI is present
      expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
    });

    testWidgets('renders headless OS kernel health when host is registered',
        (WidgetTester tester) async {
      GetIt.instance.registerSingleton<HeadlessAvraiOsHost>(
        _FakeDashboardHeadlessOsHost(),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AI2AIAdminDashboard(useThreeJsVisualizations: false),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Headless OS Kernel Health'), findsOneWidget);
      expect(
        find.textContaining('locality inside where for dashboard health'),
        findsOneWidget,
      );
      expect(find.text('started'), findsOneWidget);
      expect(find.text('when'), findsOneWidget);
      expect(find.text('authoritative'), findsOneWidget);
    });
  });
}

class _FakeDashboardHeadlessOsHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7, 12),
      localityContainedInWhere: true,
      summary: 'locality inside where for dashboard health',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async {
    return const <KernelHealthReport>[
      KernelHealthReport(
        domain: KernelDomain.when,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'temporal authority ready',
      ),
    ];
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) {
    throw UnimplementedError();
  }
}
