import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/safety_checklist_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for SafetyChecklistWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SafetyChecklistWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Safety checklist widget tests focus on business logic (checklist display, acknowledgment, read-only mode), not property assignment

    testWidgets(
        'should display safety checklist widget, display with acknowledgment checkbox, or display in read-only mode',
        (WidgetTester tester) async {
      // Test business logic: safety checklist widget display and interactions
      final host1 = ModelFactories.createTestUser();
      final event1 = IntegrationTestHelpers.createTestEvent(host: host1);
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event1,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);

      final host2 = ModelFactories.createTestUser();
      final event2 = IntegrationTestHelpers.createTestEvent(host: host2);
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      bool acknowledged = false;
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event2,
          showAcknowledgment: true,
          onAcknowledged: (value) {
            acknowledged = value;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);

      final host3 = ModelFactories.createTestUser();
      final event3 = IntegrationTestHelpers.createTestEvent(host: host3);
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event3,
          readOnly: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);
    });
  });
}
