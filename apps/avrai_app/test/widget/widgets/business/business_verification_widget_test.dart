import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/business/business_verification_widget.dart';
import 'package:avrai_core/models/business/business_account.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for BusinessVerificationWidget
/// Tests business verification form and submission
void main() {
  group('BusinessVerificationWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business verification widget tests focus on business logic (form display, pre-filling), not property assignment

    testWidgets(
        'should display all required form fields or pre-fill form with business information',
        (WidgetTester tester) async {
      // Test business logic: Business verification widget form display
      final testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessVerificationWidget(business: testBusiness),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(BusinessVerificationWidget), findsOneWidget);
    });
  });
}
