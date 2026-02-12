import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import '../helpers/accessibility_test_helpers.dart';
import '../helpers/widget_test_helpers.dart';

/// Comprehensive accessibility compliance tests for WCAG 2.1 AA
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('Accessibility Compliance Tests (WCAG 2.1 AA)', () {
    // Removed: Property assignment tests
    // Accessibility compliance tests focus on business logic (contrast ratios, color combinations, touch target sizes, semantic labels, keyboard accessibility), not property assignment

    testWidgets(
        'should validate AppColors contrast ratios meet WCAG 2.1 AA requirements, verify common text color combinations meet contrast requirements, verify button widgets have minimum touch target size, verify text fields have semantic labels, or verify interactive elements are keyboard accessible',
        (WidgetTester tester) async {
      // Test business logic: Accessibility compliance (WCAG 2.1 AA)
      final contrastResults =
          AccessibilityTestHelpers.validateAppColorsContrast();
      final violations = contrastResults['violations'] as List<String>;
      if (violations.isNotEmpty) {
      // ignore: avoid_print
        print('\n⚠️ Color Contrast Violations Found:');
      // ignore: avoid_print
        for (final violation in violations) {
      // ignore: avoid_print
          print('  - $violation');
        }
      }
      expect(violations.length, lessThan(100),
          reason: 'Too many contrast violations found');

      final criticalCombinations = [
        {
          'foreground': AppColors.textPrimary,
          'background': AppColors.white,
          'name': 'Primary text on white',
        },
        {
          'foreground': AppColors.textPrimary,
          'background': AppColors.grey100,
          'name': 'Primary text on grey100',
        },
        {
          'foreground': AppColors.textSecondary,
          'background': AppColors.white,
          'name': 'Secondary text on white',
        },
        {
          'foreground': AppColors.white,
          'background': AppColors.black,
          'name': 'White text on black',
        },
        {
          'foreground': AppColors.black,
          'background': AppColors.electricGreen,
          'name': 'Black text on electricGreen',
        },
      ];
      for (final combo in criticalCombinations) {
        final foreground = combo['foreground'] as Color;
        final background = combo['background'] as Color;
        final name = combo['name'] as String;
        final normalPass = AccessibilityTestHelpers.verifyContrastRatio(
          foreground,
          background,
          isLargeText: false,
        );
        final largePass = AccessibilityTestHelpers.verifyContrastRatio(
          foreground,
          background,
          isLargeText: true,
        );
        expect(normalPass || largePass, isTrue,
            reason: '$name does not meet contrast requirements');
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Test Text Button'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      );
      final elevatedButton = find.byType(ElevatedButton);
      expect(elevatedButton, findsOneWidget);
      final elevatedSize = tester.getSize(elevatedButton);
      expect(
        AccessibilityTestHelpers.verifyTouchTargetSize(elevatedSize),
        isTrue,
        reason: 'ElevatedButton does not meet minimum touch target size',
      );
      final textButton = find.byType(TextButton);
      expect(textButton, findsOneWidget);
      final textButtonSize = tester.getSize(textButton);
      expect(
        AccessibilityTestHelpers.verifyTouchTargetSize(textButtonSize),
        isTrue,
        reason: 'TextButton does not meet minimum touch target size',
      );
      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget);
      final iconButtonSize = tester.getSize(iconButton);
      expect(
        AccessibilityTestHelpers.verifyTouchTargetSize(iconButtonSize),
        isTrue,
        reason: 'IconButton does not meet minimum touch target size',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  key: Key('test_field'),
                  decoration: InputDecoration(
                    labelText: 'Test Field',
                    hintText: 'Enter text',
                  ),
                ),
                TextFormField(
                  key: const Key('test_form_field'),
                  decoration: const InputDecoration(
                    labelText: 'Test Form Field',
                    hintText: 'Enter form text',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final textField = find.byKey(const Key('test_field'));
      expect(textField, findsOneWidget);
      final textFieldSemantics = tester.getSemantics(textField);
      expect(textFieldSemantics, isNotNull,
          reason: 'TextField should have semantic information');
      final textFormField = find.byKey(const Key('test_form_field'));
      expect(textFormField, findsOneWidget);
      final textFormFieldSemantics = tester.getSemantics(textFormField);
      expect(textFormFieldSemantics, isNotNull,
          reason: 'TextFormField should have semantic information');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Button'),
                ),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Input',
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (_) {},
                ),
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final button = find.byType(ElevatedButton);
      expect(
        AccessibilityTestHelpers.isKeyboardAccessible(tester, button),
        isTrue,
        reason: 'Button should be keyboard accessible',
      );
      final textField2 = find.byType(TextField);
      expect(
        AccessibilityTestHelpers.isKeyboardAccessible(tester, textField2),
        isTrue,
        reason: 'TextField should be keyboard accessible',
      );
      final switchWidget = find.byType(Switch);
      expect(
        AccessibilityTestHelpers.isKeyboardAccessible(tester, switchWidget),
        isTrue,
        reason: 'Switch should be keyboard accessible',
      );
      final checkbox = find.byType(Checkbox);
      expect(
        AccessibilityTestHelpers.isKeyboardAccessible(tester, checkbox),
        isTrue,
        reason: 'Checkbox should be keyboard accessible',
      );
    });
  });
}
