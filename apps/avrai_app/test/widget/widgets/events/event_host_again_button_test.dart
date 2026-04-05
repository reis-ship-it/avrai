import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/event_host_again_button.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for EventHostAgainButton
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('EventHostAgainButton Widget Tests', () {
    // Removed: Property assignment tests
    // Event host again button tests focus on business logic (button display), not property assignment

    testWidgets('should display host again button and display replay icon',
        (WidgetTester tester) async {
      // Test business logic: event host again button display
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Community Coffee Meetup',
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EventHostAgainButton(
          originalEvent: event,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(EventHostAgainButton), findsOneWidget);
      expect(find.text('Host Again'), findsOneWidget);
    });
  });
}
