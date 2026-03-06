/// Tests for Discovery Settings Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai/presentation/pages/settings/discovery_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('DiscoverySettingsPage', () {
    setUp(() async {
      // Ensure tests don't leak persisted state via StorageService
      await StorageService.instance.setBool('discovery_enabled', false);
    });

    // Removed: Property assignment tests
    // Discovery settings page tests focus on business logic (page rendering, discovery methods, privacy settings, advanced settings, info section, dialog interactions, toggle state), not property assignment

    testWidgets(
        'should render page with all sections, show discovery methods when enabled, show privacy settings when enabled, show advanced settings when enabled, show info section at bottom, open privacy info dialog, or persist discovery toggle state',
        (tester) async {
      // Test business logic: Discovery settings page display and interactions
      await tester.pumpWidget(
        const MaterialApp(
          home: DiscoverySettingsPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Discovery Settings'), findsWidgets);
      expect(find.text('Enable Discovery'), findsOneWidget);
      expect(find.text('Device Discovery'), findsOneWidget);
      expect(find.textContaining('Find nearby AVRAI-enabled devices'),
          findsOneWidget);

      final mainToggleFinder = find.byType(SwitchListTile).first;
      final mainToggle = tester.widget<SwitchListTile>(mainToggleFinder);
      if (mainToggle.value == false) {
        await tester.tap(mainToggleFinder);
        await tester.pumpAndSettle();
      }
      expect(find.text('Discovery Methods'), findsOneWidget);
      expect(find.text('Wi-Fi Direct'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('Multipeer'), findsOneWidget);

      for (var i = 0;
          i < 6 && find.text('Privacy Settings').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -250));
        await tester.pumpAndSettle();
      }
      expect(find.text('Privacy Settings'), findsOneWidget);
      expect(find.text('Share Personality Data'), findsOneWidget);
      expect(find.text('Privacy Information'), findsOneWidget);

      for (var i = 0; i < 6 && find.text('Advanced').evaluate().isEmpty; i++) {
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -250));
        await tester.pumpAndSettle();
      }
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Auto-Discovery'), findsOneWidget);

      for (var i = 0;
          i < 10 && find.text('About Discovery').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(find.text('About Discovery'), findsOneWidget);
      expect(
          find.textContaining('Discovery uses device radios'), findsOneWidget);

      final privacyInfoFinder = find.text('Privacy Information');
      await tester.ensureVisible(privacyInfoFinder);
      await tester.pumpAndSettle();
      final privacyInfoTile = find.ancestor(
        of: privacyInfoFinder,
        matching: find.byType(ListTile),
      );
      await tester.tap(privacyInfoTile, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Anonymization'), findsOneWidget);
      expect(find.text('Encryption'), findsOneWidget);
      // Close dialog before interacting with underlying page widgets.
      await tester.tap(find.text('Got it'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final mainToggle2 = find.byType(SwitchListTile).first;
      SwitchListTile toggle = tester.widget(mainToggle2);
      final wasEnabled = toggle.value;
      await tester.ensureVisible(mainToggle2);
      await tester.tap(mainToggle2);
      await tester.pumpAndSettle();
      toggle = tester.widget(mainToggle2);
      expect(toggle.value, equals(!wasEnabled));
    });
  });
}
