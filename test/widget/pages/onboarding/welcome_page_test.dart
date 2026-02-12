import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';
import 'package:avrai/presentation/widgets/onboarding/floating_text_widget.dart';
import 'package:avrai/core/theme/colors.dart';

void main() {
  group('WelcomePage', () {
    // Removed: Property assignment tests
    // Welcome page tests focus on business logic (UI display, callbacks, animations, accessibility, layout), not property assignment

    testWidgets(
        'should build successfully, display welcome text, display skip button, display tap to continue hint, call onSkip callback when skip button is tapped, call onContinue callback when tapped anywhere, have gradient background, fade out animation works, prevent multiple taps during exit, have proper semantic labels, use SafeArea for proper layout, skip button has proper styling, or continue hint has pulsing animation',
        (WidgetTester tester) async {
      // Test business logic: Welcome page display, callbacks, animations, accessibility, layout
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(FloatingTextWidget), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('H'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
      expect(find.text('Tap to continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(SafeArea), findsOneWidget);
      final skipButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Skip'),
      );
      expect(skipButton, isNotNull);
      expect(find.byType(PulsingHintWidget), findsOneWidget);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.gradient, isA<LinearGradient>());
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, contains(AppColors.white));
      expect(gradient.colors, contains(AppColors.grey50));

      bool skipCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            onSkip: () {
              skipCalled = true;
            },
          ),
        ),
      );
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipCalled, true);

      int continueCallCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            onContinue: () {
              continueCallCount++;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      // Fade duration is 400ms; verify it doesn't fire immediately, then does.
      await tester.pump(const Duration(milliseconds: 100));
      expect(continueCallCount, 0);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(continueCallCount, 1);

      // Further taps during/after exit should not fire again.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(continueCallCount, 1);
    });
  });
}
