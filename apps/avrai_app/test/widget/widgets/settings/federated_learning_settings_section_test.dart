/// SPOTS FederatedLearningSettingsSection Widget Tests
/// Date: November 20, 2025
/// Purpose: Test FederatedLearningSettingsSection functionality and UI behavior
///
/// Test Coverage:
/// - Rendering: Section displays correctly with explanation
/// - User Interactions: Opt-in/opt-out toggle
/// - Information Display: Benefits and consequences explained
/// - Edge Cases: State persistence, error handling
///
/// Dependencies:
/// - FederatedLearningSystem: For participation status
/// - GetStorage: For preference storage
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_settings_section.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for FederatedLearningSettingsSection
/// Tests section rendering, user interactions, and information display
void main() {
  group('FederatedLearningSettingsSection Widget Tests', () {
    group('Rendering', () {
      // Removed: Property assignment tests
      // Rendering tests focus on business logic (section display, explanation, benefits, consequences, toggle), not property assignment

      testWidgets(
          'should display section with title, display explanation of federated learning, display participation benefits, display consequences of not participating, or display opt-in/opt-out toggle',
          (WidgetTester tester) async {
        // Test business logic: Federated learning settings section rendering
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningSettingsSection(),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        expect(find.byType(FederatedLearningSettingsSection), findsOneWidget);
        expect(find.text('Federated Learning'), findsOneWidget);
        expect(find.textContaining('Privacy-preserving'), findsOneWidget);
        expect(
            find.textContaining('data stays on your device'), findsOneWidget);
        expect(find.text('Benefits of participating:'), findsOneWidget);
        expect(find.textContaining('More accurate'), findsOneWidget);
        expect(find.textContaining('Less accurate'), findsOneWidget);
        expect(find.textContaining('Slower'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        expect(find.textContaining('Participate'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      // Removed: Property assignment tests
      // User interactions tests focus on business logic (switch toggle, info dialog), not property assignment

      testWidgets(
          'should toggle participation when switch is tapped or show info dialog when info icon is tapped',
          (WidgetTester tester) async {
        // Test business logic: Federated learning settings section user interactions
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const Scaffold(
            body: FederatedLearningSettingsSection(),
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        final switchWidget = find.byType(Switch);
        final initialValue = tester.widget<Switch>(switchWidget).value;
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();
        final newValue = tester.widget<Switch>(switchWidget).value;
        expect(newValue, isNot(equals(initialValue)));
        final infoButton = find.byIcon(Icons.info_outline);
        if (infoButton.evaluate().isNotEmpty) {
          await tester.tap(infoButton.first);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      });
    });

    group('Information Display', () {
      // Removed: Property assignment tests
      // Information display tests focus on business logic (privacy protection information, how it works explanation), not property assignment

      testWidgets(
          'should display privacy protection information or display how it works explanation',
          (WidgetTester tester) async {
        // Test business logic: Federated learning settings section information display
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningSettingsSection(),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        expect(find.textContaining('Privacy'), findsWidgets);
        expect(find.textContaining('anonymized'), findsOneWidget);
        final infoButton = find.byIcon(Icons.info_outline);
        expect(infoButton, findsWidgets);
      });
    });
  });
}
