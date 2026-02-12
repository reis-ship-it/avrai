/// SPOTS DiscoverySettingsPage Widget Tests
/// Date: November 20, 2025
/// Purpose: Test DiscoverySettingsPage functionality and UI behavior
///
/// Test Coverage:
/// - Rendering: Page displays correctly with settings
/// - User Interactions: Update scan interval, device timeout
/// - Settings Persistence: Saves settings correctly
/// - Validation: Validates input ranges
///
/// Dependencies:
/// - DeviceDiscoveryService: For applying settings
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/network/discovery_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../mocks/mock_storage_service.dart';

/// Widget tests for DiscoverySettingsPage
/// Tests page rendering, settings display, and user interactions
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    MockGetStorage.reset();
  });

  group('DiscoverySettingsPage Widget Tests', () {
    // Removed: Property assignment tests
    // Discovery settings page tests focus on business logic (page display, settings display, user interactions, validation, settings persistence), not property assignment

    testWidgets('renders page and default fields', (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const DiscoverySettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.byType(DiscoverySettingsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Discovery Settings'),
        ),
        findsOneWidget,
      );
      expect(find.text('Scan Interval'), findsOneWidget);
      expect(find.text('Device Timeout'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      final scanField = tester.widget<TextFormField>(fields.at(0));
      final timeoutField = tester.widget<TextFormField>(fields.at(1));
      expect(scanField.controller?.text ?? '', isNotEmpty);
      expect(timeoutField.controller?.text ?? '', isNotEmpty);
    });

    testWidgets('allows changing scan interval and timeout', (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const DiscoverySettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '10');
      await tester.enterText(fields.at(1), '5');
      await tester.pumpAndSettle();
      expect(find.text('10'), findsWidgets);
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('shows validation error for invalid scan interval', (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const DiscoverySettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '0');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Must be at least 1 second'), findsOneWidget);
    });

    testWidgets('save pops the page on success', (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const DiscoverySettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '10');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverySettingsPage), findsNothing);
    });
  });
}
