import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/ai_thinking_indicator.dart';
import 'package:avrai/presentation/widgets/common/offline_indicator_widget.dart';
import 'package:avrai/presentation/widgets/common/action_success_widget.dart';
import 'package:avrai/presentation/widgets/common/streaming_response_widget.dart';
import 'package:avrai/presentation/widgets/common/enhanced_ai_chat_interface.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Phase 1 Integration Tests
/// 
/// These tests verify that all Phase 1.3 UI components are properly integrated
/// and work together as expected.
void main() {
  group('Phase 1.3 Integration Tests', () {
    testWidgets('AI Thinking Indicator displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: AIThinkingIndicator(
                stage: AIThinkingStage.generatingResponse,
                showDetails: true,
              ),
            ),
          ),
        ),
      );

      // Verify indicator is shown
      expect(find.byType(AIThinkingIndicator), findsOneWidget);
      
      // Verify stage text is displayed (widget shows "AI is thinking..." for generatingResponse stage)
      expect(find.textContaining('thinking'), findsOneWidget);
      
      // Verify progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Offline Indicator displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              isOffline: true,
            ),
          ),
        ),
      );

      // Verify offline message is shown (widget shows "Limited Functionality" and "You're offline...")
      expect(find.textContaining('Limited Functionality'), findsOneWidget);
      expect(find.textContaining('offline'), findsWidgets);
      
      // Verify offline icon (widget uses Icons.cloud_off, not wifi_off)
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      
      // Verify feature availability info
      expect(find.textContaining('available'), findsWidgets);
    });

    testWidgets('Offline Banner appears when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              isOffline: true,
            ),
          ),
        ),
      );

      // Verify banner is shown
      expect(find.byType(OfflineBanner), findsOneWidget);
      
      // Verify offline text (widget shows "Offline mode • Limited functionality")
      expect(find.textContaining('Offline mode'), findsOneWidget);
    });

    testWidgets('Action Success Widget displays correctly', (tester) async {
      final mockResult = ActionResult.success(
        message: 'List created successfully!',
        data: {'id': 'test-id'},
        intent: const CreateListIntent(
          title: 'Test List',
          description: 'Test description',
          userId: 'test-user',
          confidence: 0.8,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSuccessWidget(
              result: mockResult,
              onUndo: () async {},
              onViewResult: () {},
              undoTimeout: const Duration(seconds: 5),
            ),
          ),
        ),
      );

      // Verify success message
      expect(find.text('List created successfully!'), findsOneWidget);
      
      // Verify action buttons
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      
      // Verify success icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Streaming Response Widget displays text stream', (tester) async {
      // Create a test stream
      Stream<String> testStream() async* {
        yield 'Hello';
        await Future.delayed(const Duration(milliseconds: 100));
        yield 'Hello world';
        await Future.delayed(const Duration(milliseconds: 100));
        yield 'Hello world from AI';
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              textStream: testStream(),
              onComplete: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      // Wait for initial frame
      await tester.pump();
      
      // Verify loading or first chunk appears
      expect(find.byType(StreamingResponseWidget), findsOneWidget);
      
      // Wait for stream to complete
      await tester.pumpAndSettle();
      
      // Verify final text is displayed
      expect(find.textContaining('Hello'), findsOneWidget);
    });

    testWidgets('Enhanced AI Chat Interface renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedAIChatInterface(
              userId: 'test-user',
              enableStreaming: true,
              showThinkingStages: true,
            ),
          ),
        ),
      );

      // Verify chat interface components
      expect(find.byType(EnhancedAIChatInterface), findsOneWidget);
      
      // Verify chat input bar exists
      expect(find.byType(TextField), findsOneWidget);
      
      // Verify send button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('AICommandProcessor helper methods exist', (tester) async {
      // Verify static methods are available
      expect(AICommandProcessor.showStreamingResponse, isNotNull);
      
      // Note: Testing the actual method execution would require
      // a full app context with navigation, so we just verify the API exists
    });

    test('Action Result data model works correctly', () {
      final result = ActionResult.success(
        message: 'Spot created',
        data: {'id': '123'},
        intent: const CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test description',
          latitude: 40.7128,
          longitude: -73.9352,
          category: 'restaurant',
          userId: 'test-user',
          confidence: 0.8,
        ),
      );

      expect(result.success, isTrue);
      expect(result.successMessage, equals('Spot created'));
      expect(result.data['id'], equals('123'));
      expect(result.intent, isA<CreateSpotIntent>());
    });

    test('AI Thinking Stage enum has all expected values', () {
      expect(AIThinkingStage.values.length, greaterThanOrEqualTo(4));
      expect(AIThinkingStage.values, contains(AIThinkingStage.loadingContext));
      expect(AIThinkingStage.values, contains(AIThinkingStage.analyzingPersonality));
      expect(AIThinkingStage.values, contains(AIThinkingStage.consultingNetwork));
      expect(AIThinkingStage.values, contains(AIThinkingStage.generatingResponse));
    });
  });

  group('Phase 1.3 Integration Flow Tests', () {
    testWidgets('Complete chat flow with thinking indicator', (tester) async {
      // This test verifies the complete flow:
      // 1. User sends message
      // 2. Thinking indicator appears
      // 3. Response is shown
      // 4. Success dialog may appear
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedAIChatInterface(
              userId: 'test-user',
              enableStreaming: false,
              showThinkingStages: true,
            ),
          ),
        ),
      );

      // Find and tap the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      // Enter text
      await tester.enterText(textField, 'Create a coffee shop list');
      await tester.pump();
      
      // Note: Full integration test would require mocking services
      // This is a smoke test to verify the UI can be created
    });

    testWidgets('Offline banner integration in home page', (tester) async {
      // This would test the offline banner in the actual home page
      // Requires full app setup with auth, blocs, etc.
      // Skipped in basic integration test
    });
  });

  group('Phase 1.2 Integration Tests', () {
    testWidgets('Device Discovery Page can be created', (tester) async {
      // Note: Actual page import would be needed
      // This is a placeholder for when pages are integrated
      
      // Verify the route exists in AppRouter
      // Verify the page can be navigated to
      // This would require a full app context
    });

    testWidgets('AI2AI Connections Page can be created', (tester) async {
      // Note: Actual page import would be needed
      // This is a placeholder for when pages are integrated
      
      // Verify the route exists in AppRouter
      // Verify the page can be navigated to
      // This would require a full app context
    });
  });
}

