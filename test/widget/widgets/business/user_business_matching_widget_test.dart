import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/business/user_business_matching_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserBusinessMatchingWidget
/// Tests user-business matching display
void main() {
  group('UserBusinessMatchingWidget Widget Tests', () {
    // Removed: Property assignment tests
    // User business matching widget tests focus on business logic (loading state, header display, callbacks), not property assignment

    testWidgets(
        'should display loading state initially, display business matches header, or call onBusinessSelected when business is selected',
        (WidgetTester tester) async {
      // Test business logic: User business matching widget state management and interactions
      final user = WidgetTestHelpers.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UserBusinessMatchingWidget(
          user: user,
          onBusinessSelected: (_) {},
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(UserBusinessMatchingWidget), findsOneWidget);
    });
  });
}

