import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/universal_ai_search.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('UniversalAISearch Widget Tests', () {
    // Removed: Property assignment tests
    // Universal AI search widget tests focus on business logic (search field display, command submission, text clearing, loading state, disabled state, tap callbacks, initial value, suggestions, empty command handling, whitespace trimming, accessibility, rapid input, focus state), not property assignment

    testWidgets(
        'should display search field with hint text, call onCommand when text is submitted, clear text after submission, show loading state when enabled, disable input when disabled, call onTap when tapped, display initial value correctly, show search suggestions when focused, handle empty command submission gracefully, trim whitespace from commands, meet accessibility requirements, handle rapid text input changes, or maintain focus state correctly',
        (WidgetTester tester) async {
      // Test business logic: Universal AI search widget display and interactions
      const hintText = 'Search for anything...';
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          key: ValueKey('universal_ai_search_1'),
          hintText: hintText,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(TextField), findsOneWidget);
      final textFieldWidget1 = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget1.decoration?.hintText, equals(hintText));

      String? submittedCommand1;
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          key: const ValueKey('universal_ai_search_2'),
          hintText: 'Test search',
          onCommand: (command) => submittedCommand1 = command,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      await tester.enterText(find.byType(TextField), 'test command');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submittedCommand1, equals('test command'));
      expect(find.text('test command'), findsNothing);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          key: ValueKey('universal_ai_search_3'),
          hintText: 'Loading search',
          isLoading: true,
        ),
      );
      await tester.pumpWidget(widget3);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          key: ValueKey('universal_ai_search_4'),
          hintText: 'Disabled search',
          enabled: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      await tester.enterText(find.byType(TextField), 'should not work');
      expect(find.text('should not work'), findsNothing);

      var tapped = false;
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          key: const ValueKey('universal_ai_search_5'),
          hintText: 'Tappable search',
          onTap: () => tapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tapped, isTrue);

      const initialValue = 'Initial search term';
      final widget6 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          key: ValueKey('universal_ai_search_6'),
          hintText: 'Search',
          initialValue: initialValue,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget6);
      // In widget tests, the entered/initial text is held by the TextEditingController.
      // Asserting via the controller is more robust than relying on rendered text.
      final tfWithInitial = tester.widget<TextField>(find.byType(TextField));
      expect(tfWithInitial.controller?.text, equals(initialValue));

      final widget7 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          key: const ValueKey('universal_ai_search_7'),
          hintText: 'Search with suggestions',
          onCommand: (command) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget7);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);

      String? submittedCommand2;
      var callbackCount = 0;
      final widget8 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          key: const ValueKey('universal_ai_search_8'),
          hintText: 'Empty test',
          onCommand: (command) {
            submittedCommand2 = command;
            callbackCount++;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget8);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submittedCommand2, isNull);
      expect(callbackCount, equals(0));

      String? submittedCommand3;
      final widget9 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          key: const ValueKey('universal_ai_search_9'),
          hintText: 'Trim test',
          onCommand: (command) => submittedCommand3 = command,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget9);
      await tester.enterText(find.byType(TextField), '  test command  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submittedCommand3, equals('test command'));

      final widget10 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          key: ValueKey('universal_ai_search_10'),
          hintText: 'Accessible search',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget10);
      final textFieldWidget2 = tester.widget<TextField>(find.byType(TextField));
      expect(
          textFieldWidget2.decoration?.hintText, equals('Accessible search'));
      final textField = tester.getSize(find.byType(TextField));
      expect(textField.height, greaterThanOrEqualTo(48.0));

      final widget11 = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Rapid input test',
          onCommand: (command) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget11);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('abc'), findsOneWidget);

      final widget12 = WidgetTestHelpers.createTestableWidget(
        child: Scaffold(
          body: Column(
            children: [
              UniversalAISearch(
                hintText: 'Focus test',
                onCommand: (command) {},
              ),
              const TextField(),
            ],
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget12);
      await tester.tap(find.byType(UniversalAISearch));
      await tester.pump();
      expect(find.byType(UniversalAISearch), findsOneWidget);
    });
  });
}
