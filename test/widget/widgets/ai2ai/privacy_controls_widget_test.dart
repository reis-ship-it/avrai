import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/privacy_controls_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PrivacyControlsWidget
/// Tests privacy controls for AI2AI participation
void main() {
  group('PrivacyControlsWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Privacy controls widget tests focus on business logic (privacy controls display, switch toggles, dropdown, information message), not property assignment

    testWidgets(
        'should display all privacy controls, toggle AI2AI participation switch, display privacy level dropdown, display privacy information message, or toggle share learning insights switch',
        (WidgetTester tester) async {
      // Test business logic: Privacy controls widget display and interactions
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacyControlsWidget(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(PrivacyControlsWidget), findsOneWidget);
      expect(find.text('Privacy Controls'), findsOneWidget);
      expect(find.text('AI2AI Participation'), findsOneWidget);
      expect(find.text('Privacy Level'), findsOneWidget);
      expect(find.text('Share Learning Insights'), findsOneWidget);
      final ai2aiSwitchTile =
          find.widgetWithText(SwitchListTile, 'AI2AI Participation');
      expect(ai2aiSwitchTile, findsOneWidget);
      await tester.tap(ai2aiSwitchTile);
      await tester.pumpAndSettle();
      final switchWidget1 = tester.widget<SwitchListTile>(ai2aiSwitchTile);
      expect(switchWidget1.value, isFalse);
      // Default selected privacy level.
      expect(find.text('Maximum'), findsOneWidget);
      // Open dropdown to see available levels.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      // Close dropdown overlay.
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();
      expect(find.textContaining('All data is anonymized and privacy-preserving'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
      final shareInsightsSwitchTile =
          find.widgetWithText(SwitchListTile, 'Share Learning Insights');
      await tester.ensureVisible(shareInsightsSwitchTile);
      await tester.tap(shareInsightsSwitchTile);
      await tester.pumpAndSettle();
      final switchWidget2 =
          tester.widget<SwitchListTile>(shareInsightsSwitchTile);
      expect(switchWidget2.value, isFalse);
    });
  });
}

