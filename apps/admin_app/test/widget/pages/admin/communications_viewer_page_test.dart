import 'package:avrai_admin_app/ui/pages/communications_viewer_page.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockBhamAdminOperationsService extends Mock
    implements BhamAdminOperationsService {}

/// Widget tests for CommunicationsViewerPage
/// Tests communications viewer UI
void main() {
  group('CommunicationsViewerPage Widget Tests', () {
    late _MockBhamAdminOperationsService service;

    setUp(() {
      service = _MockBhamAdminOperationsService();
      if (GetIt.instance.isRegistered<BhamAdminOperationsService>()) {
        GetIt.instance.unregister<BhamAdminOperationsService>();
      }
      GetIt.instance.registerSingleton<BhamAdminOperationsService>(service);

      when(() => service.listCommunicationSummaries()).thenAnswer(
        (_) async => <AdminCommunicationReadModel>[
          AdminCommunicationReadModel(
            threadId: 'admin_support:user_1',
            threadKind: ChatThreadKind.admin,
            displayTitle: 'Admin support AG-123ABC',
            messageCount: 2,
            lastActivityAtUtc: DateTime.utc(2026, 3, 8, 12),
            lastMessagePreview: 'Need help with onboarding',
          ),
        ],
      );
      when(() => service.listDeliveryFailures()).thenAnswer(
        (_) async => <AdminDeliveryFailureReadModel>[
          AdminDeliveryFailureReadModel(
            messageId: 'msg-1',
            threadId: 'event:event-1',
            reason: 'Route failed',
            recordedAtUtc: DateTime.utc(2026, 3, 8, 13),
          ),
        ],
      );
      when(() => service.summarizeRoutes()).thenAnswer(
        (_) async => const <RouteDeliverySummary>[
          RouteDeliverySummary(
            mode: TransportMode.wormhole,
            attempts: 3,
            successes: 2,
            averageLatencyMs: 420,
          ),
        ],
      );
      when(() => service.listDirectMatchOutcomes()).thenAnswer(
        (_) async => <DirectMatchOutcomeView>[
          DirectMatchOutcomeView(
            invitationId: 'invite-1',
            participantA: AdminRedactedView(
              subjectId: 'user-a',
              displayLabel: 'AG-AAAAAA',
              initials: 'AG',
            ),
            participantB: AdminRedactedView(
              subjectId: 'user-b',
              displayLabel: 'AG-BBBBBB',
              initials: 'AG',
            ),
            compatibilityScore: 0.996,
            createdAtUtc: DateTime.utc(2026, 3, 8, 14),
            chatOpened: true,
          ),
        ],
      );
    });

    tearDown(() async {
      if (GetIt.instance.isRegistered<BhamAdminOperationsService>()) {
        GetIt.instance.unregister<BhamAdminOperationsService>();
      }
      await WidgetTestHelpers.cleanupWidgetTestEnvironment();
    });

    testWidgets('renders communication summaries and route outcomes',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CommunicationsViewerPage(),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Communications Oversight'), findsOneWidget);
      expect(find.textContaining('Wave 5 Runtime Contracts'), findsOneWidget);
      expect(find.text('Admin support AG-123ABC'), findsOneWidget);
      expect(find.text('wormhole'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Direct-match invitation outcomes'),
        250,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('AG-AAAAAA ↔ AG-BBBBBB'), findsOneWidget);
    });
  });
}
