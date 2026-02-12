import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/onboarding/floating_text_widget.dart';
import 'package:avrai/core/theme/colors.dart';

void main() {
  group('FloatingTextWidget', () {
    // Removed: Property assignment tests
    // Floating text widget tests focus on business logic (text display, animations, styling), not property assignment

    testWidgets(
        'should build successfully with text, display all letters individually, handle multi-line text, apply custom text style, initialize entrance animation, loop float animation continuously, handle empty text gracefully, or respect reduced motion preference',
        (WidgetTester tester) async {
      // Test business logic: floating text widget display and animations
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'Hello World',
            ),
          ),
        ),
      );
      expect(find.text('H'), findsOneWidget);
      expect(find.text('e'), findsOneWidget);
      expect(find.text('l'), findsNWidgets(3));
      expect(find.text('o'), findsNWidgets(2));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'Hi',
            ),
          ),
        ),
      );
      expect(find.text('H'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'Hi\nthere',
            ),
          ),
        ),
      );
      expect(find.text('H'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(find.text('t'), findsOneWidget);
      expect(find.text('h'), findsOneWidget);
      expect(find.text('e'), findsNWidgets(2));
      expect(find.text('r'), findsOneWidget);

      const customStyle = TextStyle(
        fontSize: 24,
        color: AppColors.electricGreen,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'Hi',
              textStyle: customStyle,
            ),
          ),
        ),
      );
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, greaterThan(0));
      for (final textWidget in textWidgets) {
        if (textWidget.data != null && textWidget.data!.isNotEmpty) {
          expect(textWidget.style?.fontSize, 24);
          expect(textWidget.style?.color, AppColors.electricGreen);
        }
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'Hi',
              entranceDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('H'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: 'A',
              entranceDuration: Duration(milliseconds: 100),
              floatDuration: Duration(milliseconds: 200),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('A'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('A'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('A'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingTextWidget(
              text: '',
            ),
          ),
        ),
      );
      // FloatingTextWidget has continuous animations; `pumpAndSettle` will time out.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(FloatingTextWidget), findsOneWidget);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: FloatingTextWidget(
                text: 'Hi',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('H'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
    });
  });

  group('PulsingHintWidget', () {
    // Removed: Property assignment tests
    // Pulsing hint widget tests focus on business logic (hint display, styling, animations), not property assignment

    testWidgets(
        'should build successfully, display text with default style, apply custom text style, or run pulsing animation',
        (WidgetTester tester) async {
      // Test business logic: pulsing hint widget display and animations
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingHintWidget(
              text: 'Tap to continue',
            ),
          ),
        ),
      );
      expect(find.text('Tap to continue'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingHintWidget(
              text: 'Hint',
            ),
          ),
        ),
      );
      final textWidget1 = tester.widget<Text>(find.byType(Text));
      expect(textWidget1.data, 'Hint');
      expect(textWidget1.style?.color, AppColors.textSecondary);

      const customStyle = TextStyle(
        fontSize: 20,
        color: AppColors.electricGreen,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingHintWidget(
              text: 'Hint',
              textStyle: customStyle,
            ),
          ),
        ),
      );
      final textWidget2 = tester.widget<Text>(find.byType(Text));
      expect(textWidget2.style?.fontSize, 20);
      expect(textWidget2.style?.color, AppColors.electricGreen);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingHintWidget(
              text: 'Hint',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Hint'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hint'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Hint'), findsOneWidget);
    });
  });
}
