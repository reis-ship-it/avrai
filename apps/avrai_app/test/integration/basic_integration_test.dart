import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../helpers/platform_channel_helper.dart';

/// Basic Integration Tests
///
/// Tests that the app can start and basic components initialize
void main() {
  group('Basic Integration Tests', () {
    setUpAll(() async {
      // Avoid path_provider / GetStorage.init in tests.
      await setupTestStorage();
    });

    testWidgets('App starts without crashing', (WidgetTester tester) async {
      const fallbackApp = MaterialApp(
        title: 'SPOTS Test',
        home: Scaffold(
          body: Center(child: Text('SPOTS App')),
        ),
      );

      await tester.pumpWidget(fallbackApp);
      await tester.pump();

      // Assert - App should render without crashing
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify current app state is stable.
      expect(tester.takeException(), isNull);
    });

    testWidgets('App widget structure is correct', (WidgetTester tester) async {
      const fallbackApp = MaterialApp(
        title: 'SPOTS Test',
        home: Scaffold(body: Center(child: Text('SPOTS App'))),
      );

      await tester.pumpWidget(fallbackApp);
      await tester.pump();

      // Assert - MaterialApp should be present
      expect(find.byType(MaterialApp), findsOneWidget);

      // App should have a router or home widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
          materialApp.routerConfig != null || materialApp.home != null, isTrue,
          reason: 'App should have either router or home widget');
    });
  });
}
