/// Tests for AI Thinking Indicator Widget
///
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/ai_thinking_indicator.dart';

void main() {
  group('AIThinkingIndicator', () {
    // Removed: Property assignment tests
    // AI thinking indicator tests focus on business logic (indicator display, stages, animations, timeout handling), not property assignment

    testWidgets(
        'should render full indicator with default stage, render different stages correctly, render compact indicator, show/hide progress bar based on showDetails, show timeout message after timeout duration, call onTimeout callback when timeout occurs, or run animation smoothly',
        (tester) async {
      // Test business logic: AI thinking indicator display and state management
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(key: ValueKey('ai_thinking_default')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Crafting a personalized response'), findsOneWidget);

      for (final stage in AIThinkingStage.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIThinkingIndicator(
                key: ValueKey('ai_thinking_stage_${stage.name}'),
                stage: stage,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(AIThinkingIndicator), findsOneWidget);
        expect(find.byIcon(_getIconForStage(stage)), findsOneWidget);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              key: ValueKey('ai_thinking_compact'),
              compact: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Crafting a personalized response'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              key: ValueKey('ai_thinking_details'),
              showDetails: true,
              stage: AIThinkingStage.analyzingPersonality,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Step 2 of 5'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              key: ValueKey('ai_thinking_no_details'),
              showDetails: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              key: ValueKey('ai_thinking_timeout_message'),
              timeout: Duration(milliseconds: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Taking longer than usual'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Taking longer than usual'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      bool callbackCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              key: const ValueKey('ai_thinking_timeout_callback'),
              timeout: const Duration(milliseconds: 100),
              onTimeout: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(callbackCalled, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(key: ValueKey('ai_thinking_animation')),
          ),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AIThinkingIndicator), findsOneWidget);
    });
  });

  group('AIThinkingDots', () {
    testWidgets('should render dots animation and run animation for dots',
        (tester) async {
      // Test business logic: AI thinking dots animation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIThinkingDots(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AIThinkingDots), findsOneWidget);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AIThinkingDots), findsOneWidget);
    });
  });
}

/// Helper to get icon for stage
IconData _getIconForStage(AIThinkingStage stage) {
  switch (stage) {
    case AIThinkingStage.loadingContext:
      return Icons.inventory_2_outlined;
    case AIThinkingStage.analyzingPersonality:
      return Icons.psychology;
    case AIThinkingStage.consultingNetwork:
      return Icons.share;
    case AIThinkingStage.generatingResponse:
      return Icons.auto_awesome;
    case AIThinkingStage.finalizing:
      return Icons.check_circle_outline;
  }
}
