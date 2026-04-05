import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';

void main() {
  group('WelcomePage', () {
    testWidgets(
        'shows core copy, hides skip by default, and calls continue when tapped',
        (WidgetTester tester) async {
      var continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            onContinue: () {
              continueTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Welcome to AVRAI'), findsWidgets);
      expect(
        find.text(
          'Set up a calm baseline so recommendations, planning, and AI guidance feel useful from the start.',
        ),
        findsOneWidget,
      );
      expect(find.text('What happens next'), findsOneWidget);
      expect(find.text('Ready to begin'), findsOneWidget);
      expect(find.widgetWithText(AppButtonPrimary, 'Continue'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.ensureVisible(
        find.widgetWithText(AppButtonPrimary, 'Continue'),
      );
      await tester.tap(find.widgetWithText(AppButtonPrimary, 'Continue'));
      await tester.pump();

      expect(continueTapped, isTrue);
    });

    testWidgets('shows skip only when a skip callback is provided',
        (WidgetTester tester) async {
      var skipTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            onSkip: () {
              skipTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
      expect(find.widgetWithText(AppButtonPrimary, 'Continue'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipTapped, isTrue);
    });
  });
}
