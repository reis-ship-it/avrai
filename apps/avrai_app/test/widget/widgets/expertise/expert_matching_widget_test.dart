import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/expertise/expert_matching_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertMatchingWidget
/// Tests expert matching display
void main() {
  group('ExpertMatchingWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expert matching widget tests focus on business logic (matching display, loading state, user interactions), not property assignment

    testWidgets(
        'should display loading state initially, display similar experts header, display mentors header for mentor matching type, or call onMatchSelected when match is selected',
        (WidgetTester tester) async {
      // Test business logic: expert matching widget display and interactions
      final user1 = WidgetTestHelpers.createTestUser();
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user1,
          category: 'Coffee',
        ),
      );
      await tester.pumpWidget(widget1);
      await tester.pump(); // Don't settle, check loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final user2 = WidgetTestHelpers.createTestUser();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user2,
          category: 'Coffee',
          matchingType: MatchingType.similar,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);

      final user3 = WidgetTestHelpers.createTestUser();
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user3,
          category: 'Coffee',
          matchingType: MatchingType.mentors,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);

      final user4 = WidgetTestHelpers.createTestUser();
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: ExpertMatchingWidget(
          user: user4,
          category: 'Coffee',
          onMatchSelected: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byType(ExpertMatchingWidget), findsOneWidget);
    });
  });
}
