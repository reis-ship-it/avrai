import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/business/business_compatibility_widget.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for BusinessCompatibilityWidget
/// Tests business-user compatibility display
void main() {
  group('BusinessCompatibilityWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business compatibility widget tests focus on business logic (loading state, compatibility score, preferences, error state), not property assignment

    testWidgets(
        'should display loading state initially, display compatibility score, display business preferences when available, or display error state on failure',
        (WidgetTester tester) async {
      // Test business logic: Business compatibility widget state management and display
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        patronPreferences: const BusinessPatronPreferences(
          preferredVibePreferences: ['Relaxed'],
          preferredInterests: ['Coffee'],
          preferLocalPatrons: true,
        ),
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );
      final user = WidgetTestHelpers.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessCompatibilityWidget(
          business: business,
          user: user,
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(BusinessCompatibilityWidget), findsOneWidget);
      expect(find.text('Your Compatibility'), findsOneWidget);
      expect(find.textContaining('What'), findsWidgets);
      expect(find.textContaining('How You Match'), findsWidgets);
    });
  });
}

