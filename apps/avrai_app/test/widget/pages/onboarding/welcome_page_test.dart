import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';

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

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Hi, tell me\nabout yourself'), findsOneWidget);
      expect(find.text('Tap to continue'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(find.byType(SafeArea), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
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

      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipTapped, isTrue);
    });
  });
}
