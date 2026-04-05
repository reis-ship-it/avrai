import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/search_bar.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for CustomSearchBar
/// Tests search bar UI, interactions, and callbacks
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('CustomSearchBar Widget Tests', () {
    // Removed: Property assignment tests
    // Search bar tests focus on business logic (search bar display, user interactions, state management), not property assignment

    testWidgets(
        'should display search bar with default hint, display custom hint text, display initial value, call onChanged callback when text changes, show clear button when text is entered, or respect enabled state',
        (WidgetTester tester) async {
      // Test business logic: search bar display and interactions
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(key: ValueKey('custom_search_bar_1')),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Search...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(
          key: ValueKey('custom_search_bar_2'),
          hintText: 'Search spots...',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Search spots...'), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(
          key: ValueKey('custom_search_bar_3'),
          initialValue: 'test query',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      final tfWithInitial = tester.widget<TextField>(find.byType(TextField));
      expect(tfWithInitial.controller?.text, equals('test query'));

      String? changedValue;
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: CustomSearchBar(
          key: const ValueKey('custom_search_bar_4'),
          onChanged: (value) => changedValue = value,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      await tester.enterText(find.byType(TextField), 'new query');
      await tester.pump();
      expect(changedValue, equals('new query'));

      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(
          key: ValueKey('custom_search_bar_5'),
          showClearButton: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      final widget6 = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(
          key: ValueKey('custom_search_bar_6'),
          enabled: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget6);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });
  });
}
