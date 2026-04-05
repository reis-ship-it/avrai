import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/pages/profile/beta_feedback_page.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/user/user.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('BetaFeedbackPage', () {
    testWidgets('renders OS context and submits feedback payload',
        (tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'beta_feedback_page_restored_os',
        ),
      );
      final seedingBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeBetaFeedbackHeadlessHost(),
        prefs: prefs,
      );
      await seedingBootstrap.initialize();
      final restoredBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeBetaFeedbackHeadlessHost(),
        prefs: prefs,
      );
      await restoredBootstrap.restorePersistedSnapshot();
      final availabilityService = HeadlessAvraiOsAvailabilityService(
        bootstrapService: restoredBootstrap,
      );
      final authBloc = MockBlocFactory.createAuthenticatedAuthBloc(
        role: UserRole.user,
      );
      Map<String, dynamic>? submittedPayload;

      await WidgetTestHelpers.pumpAndSettle(
        tester,
        WidgetTestHelpers.createTestableWidget(
          authBloc: authBloc,
          child: BetaFeedbackPage(
            headlessOsAvailabilityService: availabilityService,
            feedbackSubmitter: (payload) async {
              submittedPayload = payload;
            },
          ),
        ),
      );

      expect(find.byKey(const Key('beta_feedback_os_context_card')),
          findsOneWidget);
      expect(find.text('Headless AVRAI OS restored'), findsWidgets);
      expect(
          find.textContaining('locality contained in where'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'The beta feels sharper with AVRAI OS visible.',
      );
      await tester.ensureVisible(find.text('Send to Team'));
      await tester.tap(find.text('Send to Team'));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(submittedPayload, isNotNull);
      expect(submittedPayload!['type'], 'general');
      expect(
        submittedPayload!['content'],
        'The beta feels sharper with AVRAI OS visible.',
      );
      expect(submittedPayload!['status'], 'new');
    });
  });
}

class _FakeBetaFeedbackHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'beta feedback host ready',
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
        summary: 'when ready',
      ),
      KernelHealthReport(
        domain: KernelDomain.where,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'where ready',
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
