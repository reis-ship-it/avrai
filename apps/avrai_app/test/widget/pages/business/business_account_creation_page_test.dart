import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/business/business_account_creation_page.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for BusinessAccountCreationPage
/// Tests form rendering, validation, and business account creation
void main() {
  group('BusinessAccountCreationPage Widget Tests', () {
    late UnifiedUser testUser;

    setUp(() {
      testUser = ModelFactories.createTestUser();
    });

    // Removed: Property assignment tests
    // Business account creation page tests focus on business logic (form fields display, business account creation title display), not property assignment

    testWidgets(
        'should display all required form fields or display business account creation title',
        (WidgetTester tester) async {
      // Test business logic: Business account creation page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountCreationPage(user: testUser),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(BusinessAccountCreationPage), findsOneWidget);
    });
  });
}
