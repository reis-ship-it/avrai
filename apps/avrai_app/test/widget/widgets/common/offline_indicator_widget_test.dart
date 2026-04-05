/// Tests for Offline Indicator Widget
///
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/offline_indicator_widget.dart';

void main() {
  group('OfflineIndicatorWidget', () {
    // Removed: Property assignment tests
    // Offline indicator widget tests focus on business logic (offline indicator display, user interactions), not property assignment

    testWidgets(
        'should show indicator when offline, hide indicator when online, expand to show feature details when tapped, show retry button when onRetry provided, be dismissed when showDismiss is true, or display custom features when provided',
        (tester) async {
      // Test business logic: offline indicator display and interactions
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: ValueKey('offline_indicator_1'),
              isOffline: true,
            ),
          ),
        ),
      );
      expect(find.text('Limited Functionality'), findsOneWidget);
      expect(find.text('You\'re offline. Some features are unavailable.'),
          findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: ValueKey('offline_indicator_2'),
              isOffline: false,
            ),
          ),
        ),
      );
      expect(find.text('Limited Functionality'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: ValueKey('offline_indicator_3'),
              isOffline: true,
            ),
          ),
        ),
      );
      expect(find.text('Not Available Offline'), findsNothing);
      await tester.tap(find.text('Limited Functionality'));
      await tester.pumpAndSettle();
      expect(find.text('Not Available Offline'), findsOneWidget);
      expect(find.text('Still Works Offline'), findsOneWidget);

      bool retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: const ValueKey('offline_indicator_4'),
              isOffline: true,
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(retryCalled, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: ValueKey('offline_indicator_5'),
              isOffline: true,
              showDismiss: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Limited Functionality'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              key: ValueKey('offline_indicator_6'),
              isOffline: true,
              limitedFeatures: ['Feature A', 'Feature B'],
              availableFeatures: ['Feature C'],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Limited Functionality'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Feature A'), findsOneWidget);
      expect(find.textContaining('Feature B'), findsOneWidget);
      expect(find.textContaining('Feature C'), findsOneWidget);
    });
  });

  group('OfflineBanner', () {
    testWidgets(
        'should show banner when offline, hide banner when online, or call onTap callback when tapped',
        (tester) async {
      // Test business logic: offline banner display and interactions
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              key: ValueKey('offline_banner_1'),
              isOffline: true,
            ),
          ),
        ),
      );
      expect(find.text('Offline mode • Limited functionality'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              key: ValueKey('offline_banner_2'),
              isOffline: false,
            ),
          ),
        ),
      );
      expect(find.text('Offline mode • Limited functionality'), findsNothing);

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              key: const ValueKey('offline_banner_3'),
              isOffline: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Offline mode • Limited functionality'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('AutoOfflineIndicator', () {
    testWidgets('should build with builder function', (tester) async {
      // Test business logic: auto offline indicator builder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoOfflineIndicator(
              builder: (context, isOffline) {
                return Text(isOffline ? 'Offline' : 'Online');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
