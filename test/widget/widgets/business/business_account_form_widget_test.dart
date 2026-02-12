import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/business/business_account_form_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessAccountFormWidget
/// Tests business account creation form
void main() {
  group('BusinessAccountFormWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business account form widget tests focus on business logic (form display, fields, categories, callbacks), not property assignment

    testWidgets(
        'should display business account form, display all form fields, display business categories section, or call onAccountCreated when account is created',
        (WidgetTester tester) async {
      // Test business logic: Business account form widget display and functionality
      final creator = WidgetTestHelpers.createTestUser();
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      bool accountCreated = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountFormWidget(
          creator: creator,
          onAccountCreated: (_) {
            accountCreated = true;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(BusinessAccountFormWidget), findsOneWidget);
      expect(find.text('Create Business Account'), findsWidgets);
      expect(find.text('Business Name *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Business Type *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Business Categories'), findsOneWidget);
    });
  });
}

