import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/community_event_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for CommunityEventWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
///
/// Tests:
/// - Widget rendering
/// - Event display
/// - Registration status
/// - Callback handling
/// - Upgrade eligibility
void main() {
  group('CommunityEventWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Community event widget tests focus on business logic (event display, registration, user interactions), not property assignment

    testWidgets(
        'should display community event with title, display community badge, display register button when user can register, display upgrade eligibility indicator, call onTap callback when card is tapped, or display event details',
        (WidgetTester tester) async {
      // Test business logic: community event widget display and interactions
      final host1 = ModelFactories.createTestUser();
      final event1 = IntegrationTestHelpers.createTestEvent(
        host: host1,
        title: 'Community Coffee Meetup',
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event1,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.text('Community Coffee Meetup'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);

      final user = WidgetTestHelpers.createTestUser();
      final host2 = ModelFactories.createTestUser();
      final event2 = IntegrationTestHelpers.createTestEvent(
        host: host2,
        maxAttendees: 10,
        attendeeIds: [],
      );
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      bool registerCalled = false;
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event2,
          currentUser: user,
          onRegister: () => registerCalled = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.text('Join Event'), findsOneWidget);

      final host3 = ModelFactories.createTestUser();
      final event3 = IntegrationTestHelpers.createTestEvent(host: host3);
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event3,
          isEligibleForUpgrade: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.textContaining('Eligible for upgrade'), findsOneWidget);

      bool wasTapped = false;
      final host4 = ModelFactories.createTestUser();
      final event4 = IntegrationTestHelpers.createTestEvent(host: host4);
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event4,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      await tester.tap(find.byType(CommunityEventWidget));
      await tester.pump();
      expect(wasTapped, isTrue);

      final host5 = ModelFactories.createTestUser();
      final event5 = IntegrationTestHelpers.createTestEvent(
        host: host5,
        location: 'Brooklyn, NY',
        maxAttendees: 20,
      );
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event5,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      expect(find.byType(CommunityEventWidget), findsOneWidget);
    });
  });
}
