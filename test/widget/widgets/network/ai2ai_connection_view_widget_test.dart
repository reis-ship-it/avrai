/// Tests for AI2AI Connection View Widget
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/presentation/widgets/network/ai2ai_connection_view_widget.dart';

void main() {
  setUpAll(() {});

  group('AI2AIConnectionViewWidget', () {
    // Removed: Property assignment tests
    // AI2AI connection view widget tests focus on business logic (empty state, active connections, compatibility display, human connection button, compatibility explanation, fleeting connection notice, callbacks), not property assignment

    testWidgets(
        'should display empty state when no connections, display active connections, show compatibility bar and metrics, show human connection button at 100% compatibility, hide human connection button when below 100%, display compatibility explanation, show fleeting connection notice, or call callback when human connection enabled',
        (tester) async {
      // Test business logic: AI2AI connection view widget display and interactions
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: ValueKey('empty'),
              connections: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No Active AI Connections'), findsOneWidget);
      expect(find.textContaining('Enable device discovery'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('compat-85'),
              connections: [
                _createMockConnection(vibeAlignment: 0.85),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI Connection'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('High Compatibility'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('compat-75'),
              connections: [
                _createMockConnection(
                  vibeAlignment: 0.75,
                  sharedInsights: 12,
                  learningExchanges: 8,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compatibility Score'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('compat-100'),
              connections: [
                _createMockConnection(vibeAlignment: 1.0),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Perfect Match!'), findsOneWidget);
      expect(find.text('Enable Human Conversation'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('compat-95'),
              connections: [
                _createMockConnection(vibeAlignment: 0.95),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enable Human Conversation'), findsNothing);
      expect(find.text('95%'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('why-compatible'),
              connections: [
                _createMockConnection(vibeAlignment: 0.8),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Why They\'re Compatible'), findsOneWidget);
      expect(find.textContaining('vibe compatibility'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('fleeting-notice'),
              connections: [
                _createMockConnection(vibeAlignment: 0.7),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Fleeting connection'), findsOneWidget);
      expect(find.textContaining('Managed by AI'), findsOneWidget);

      ConnectionMetrics? enabledConnection;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              key: const ValueKey('human-cta'),
              connections: [
                _createMockConnection(vibeAlignment: 1.0),
              ],
              onEnableHumanConnection: (connection) {
                enabledConnection = connection;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Human Conversation'));
      await tester.pumpAndSettle();
      expect(enabledConnection, isNotNull);
      expect(find.text('Human connection enabled! You can now chat.'), findsOneWidget);
    });
  });
}

/// Helper function to create mock connection metrics
ConnectionMetrics _createMockConnection({
  double vibeAlignment = 0.8,
  int sharedInsights = 5,
  int learningExchanges = 3,
}) {
  final startTime = DateTime.now().subtract(const Duration(minutes: 10));
  return ConnectionMetrics(
    connectionId: 'test-connection-id',
    localAISignature: 'local-ai',
    remoteAISignature: 'remote-ai',
    initialCompatibility: vibeAlignment,
    currentCompatibility: vibeAlignment,
    learningEffectiveness: 0.7,
    aiPleasureScore: 0.6,
    connectionDuration: DateTime.now().difference(startTime),
    startTime: startTime,
    status: ConnectionStatus.active,
    learningOutcomes: {
      'insights_gained': sharedInsights,
    },
    interactionHistory: List.generate(
      learningExchanges,
      (_) => InteractionEvent.success(type: InteractionType.vibeExchange, data: const {}),
    ),
    dimensionEvolution: const {},
  );
}
