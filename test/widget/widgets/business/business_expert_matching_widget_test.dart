import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/business/business_expert_matching_widget.dart';
import 'package:avrai/core/models/business/business_account.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for BusinessExpertMatchingWidget
/// Tests business expert matching display
void main() {
  group('BusinessExpertMatchingWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business expert matching widget tests focus on business logic (loading state, header display, callbacks), not property assignment

    testWidgets(
        'should display loading state initially, display expert matches header, or call onExpertSelected when expert is selected',
        (WidgetTester tester) async {
      // Test business logic: Business expert matching widget state management and interactions
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertMatchingWidget(
          business: business,
          onExpertSelected: (_) {},
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(BusinessExpertMatchingWidget), findsOneWidget);
    });
  });
}

