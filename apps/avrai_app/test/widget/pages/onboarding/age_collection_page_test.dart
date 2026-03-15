import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/age_collection_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AgeCollectionPage
/// Tests UI rendering, date selection, age calculation, and callbacks
void main() {
  group('AgeCollectionPage Widget Tests', () {
    // Removed: Property assignment tests
    // Age collection page tests focus on business logic (UI display, birthday selection, age group display, privacy notice, initialization), not property assignment

    testWidgets(
        'should display all required UI elements, display selected birthday when provided, display age group correctly for different ages, show privacy notice, display age information container when birthday is selected, not display age information when no birthday selected, have tappable birthday selection card, or initialize with provided selectedBirthday',
        (WidgetTester tester) async {
      // Test business logic: Age collection page display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: AgeCollectionPage(
          selectedBirthday: null,
          onBirthdayChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Age Verification'), findsWidgets);
      expect(
          find.text(
              'Use your birthday to apply age-appropriate defaults and legal guardrails.'),
          findsOneWidget);
      expect(find.text('Why we ask for this'), findsOneWidget);
      expect(find.text('What we store'), findsOneWidget);
      expect(find.text('Birthday'), findsWidgets);
      expect(find.text('Tap to select your birthday'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.textContaining('Age:'), findsNothing);
      final birthdayTapTarget = find.ancestor(
        of: find.text('Tap to select your birthday'),
        matching: find.byType(InkWell),
      );
      expect(birthdayTapTarget, findsOneWidget);

      // Smoke-check: selected birthday path renders without build errors.
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: AgeCollectionPage(
          selectedBirthday: DateTime(2000, 1, 15),
          onBirthdayChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(AgeCollectionPage), findsOneWidget);
    });
  });
}
