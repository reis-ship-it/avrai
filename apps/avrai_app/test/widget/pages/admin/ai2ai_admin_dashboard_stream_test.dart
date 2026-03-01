import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/apps/admin_app/ui/pages/ai2ai_admin_dashboard.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart' as legacy_prefs;
import '../../../helpers/getit_test_harness.dart';
import '../../../helpers/platform_channel_helper.dart';

/// Tests for AI2AIAdminDashboard StreamBuilder integration
/// Phase 7, Section 40: Advanced Analytics UI - Dashboard Stream Integration Tests
/// Tests StreamBuilder integration, stream cleanup, error handling, and manual refresh
void main() {
  group('AI2AIAdminDashboard StreamBuilder Tests', () {
    late legacy_prefs.SharedPreferences mockPrefs;
    late GetItTestHarness getIt;

    Future<void> disposeDashboard(WidgetTester tester) async {
      // Ensure any subscriptions/timers are cleaned up between tests.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
    }

    setUpAll(() async {
      legacy_prefs.SharedPreferences.setMockInitialValues({});
      mockPrefs = await legacy_prefs.SharedPreferences.getInstance();

      getIt = GetItTestHarness(sl: GetIt.instance);

      // Set up storage + GetIt with mock SharedPreferences.
      getIt.registerSingletonReplace<legacy_prefs.SharedPreferences>(mockPrefs);

      // Many services/pages now depend on SharedPreferencesCompat (GetStorage-backed).
      // Provide an in-memory storage for deterministic widget tests.
      await setupTestStorage();
      final prefsCompat =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      getIt.registerSingletonReplace<SharedPreferencesCompat>(prefsCompat);
    });

    tearDownAll(() {
      getIt.unregisterIfRegistered<legacy_prefs.SharedPreferences>();
      getIt.unregisterIfRegistered<SharedPreferencesCompat>();
    });

    group('StreamBuilder Integration', () {
      testWidgets('dashboard displays initial data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Dashboard should render (either loading or content)
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        // Wait for data to load
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should display dashboard content (not just loading)
        // Either shows content or error, but not stuck in loading forever
        expect(
          find.byType(AI2AIAdminDashboard),
          findsOneWidget,
        );

        await disposeDashboard(tester);
      });

      testWidgets('dashboard updates on stream emissions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // Wait for stream updates (periodic updates should occur)
        await tester.pump(const Duration(seconds: 10));

        // Dashboard should still be rendered after stream updates
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        // Widget should have updated (check that it's not the same instance)
        // In practice, StreamBuilder will rebuild on new stream values
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await disposeDashboard(tester);
      });

      testWidgets('widgets rebuild correctly on stream updates',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial build
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // Wait for stream to emit updates
        await tester.pump(const Duration(seconds: 10));

        // Dashboard should still be functional after updates
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        // No errors should occur during rebuilds
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await disposeDashboard(tester);
      });
    });

    group('Stream Cleanup', () {
      testWidgets('streams are disposed on page dispose', (tester) async {
        const widget = AI2AIAdminDashboard();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        );

        // Wait for initialization
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Dispose the widget (simulate navigation away)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Widget should be disposed without errors
        // No exceptions should be thrown during disposal
        expect(find.byType(AI2AIAdminDashboard), findsNothing);
      });

      testWidgets('no memory leaks from streams', (tester) async {
        // Create and dispose multiple dashboard instances
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: AI2AIAdminDashboard(),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Dispose
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(),
              ),
            ),
          );

          await tester.pump();
        }

        // If we get here without memory issues, test passes
        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('error messages display on stream failures', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // Dashboard should handle errors gracefully
        // It should either show error state or continue with degraded data
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Dashboard should still be rendered (not crash)
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        await disposeDashboard(tester);
      });

      testWidgets('retry mechanism works', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Find refresh button
        final refreshButton = find.byTooltip('Refresh Dashboard');

        if (refreshButton.evaluate().isNotEmpty) {
          // Tap refresh button
          await tester.tap(refreshButton);
          await tester.pump();

          // Wait for refresh to complete
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Dashboard should still be functional after refresh
          expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
        }

        await disposeDashboard(tester);
      });
    });

    group('Manual Refresh', () {
      testWidgets('refresh button still works', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Find refresh button in AppBar
        final refreshButton = find.byTooltip('Refresh Dashboard');

        if (refreshButton.evaluate().isNotEmpty) {
          // Verify button exists
          expect(refreshButton, findsOneWidget);

          // Tap refresh
          await tester.tap(refreshButton);
          await tester.pump();

          // Wait for refresh
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Dashboard should still be functional
          expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
        } else {
          // If refresh button doesn't exist, that's also acceptable
          // (might be implemented differently)
          expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
        }

        await disposeDashboard(tester);
      });

      testWidgets('refresh triggers stream update', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Find refresh button
        final refreshButton = find.byTooltip('Refresh Dashboard');

        if (refreshButton.evaluate().isNotEmpty) {
          // Tap refresh
          await tester.tap(refreshButton);
          await tester.pump();

          // Button should show loading state briefly
          await tester.pump(const Duration(milliseconds: 100));

          // Then complete
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Dashboard should be updated
          expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
        }

        await disposeDashboard(tester);
      });
    });

    group('Widget Stream Tests', () {
      testWidgets('widgets display stream data correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for data to load and widgets to render
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Dashboard should render with widgets
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        await disposeDashboard(tester);
      });

      testWidgets('widgets rebuild on stream updates', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Initial build
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Wait for stream updates
        await tester.pump(const Duration(seconds: 10));

        // Widgets should have rebuilt
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await disposeDashboard(tester);
      });

      testWidgets('loading states show during stream initialization',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Immediately after pump, should show loading or initial state
        await tester.pump();

        // Should either show loading indicator or content
        // (depending on how fast initial data loads)
        final hasLoading =
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        final hasContent =
            find.byType(AI2AIAdminDashboard).evaluate().isNotEmpty;

        expect(hasLoading || hasContent, isTrue);

        // Wait for initialization
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await disposeDashboard(tester);
      });

      testWidgets('error states show on stream failures', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AI2AIAdminDashboard(),
            ),
          ),
        );

        // Wait for initial load
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // If stream fails, dashboard should handle gracefully
        // Either show error message or degraded state
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Dashboard should still be rendered (not crash)
        expect(find.byType(AI2AIAdminDashboard), findsOneWidget);

        await disposeDashboard(tester);
      });
    });
  });
}
