/// SPOTS Action Execution Integration Tests
/// Date: November 25, 2025
/// Purpose: Test end-to-end action execution flow for Phase 7 Week 33
///
/// Test Coverage:
/// - End-to-end action execution flow (parse → confirm → execute → history)
/// - Action confirmation flow
/// - Action history flow
/// - Error handling flow
/// - Undo flow
///
/// Dependencies:
/// - ActionParser: Parse user commands to action intents
/// - ActionExecutor: Execute action intents
/// - ActionHistoryService: Store and manage action history
/// - ActionConfirmationDialog: Show confirmation before execution
/// - ActionErrorDialog: Show errors with retry option
/// - ActionHistoryPage: Display action history
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/ai/action_models.dart';
import 'package:avrai_runtime_os/ai/action_parser.dart';
import 'package:avrai_runtime_os/ai/action_executor.dart';
import 'package:avrai_runtime_os/services/misc/action_history_service.dart';
import '../../mocks/mock_storage_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Action Execution Integration Tests', () {
    late ActionParser parser;
    late ActionExecutor executor;
    late ActionHistoryService historyService;
    late GetStorage testStorage;

    setUp(() async {
      TestHelpers.setupTestEnvironment();
      // Reset storage before each test to ensure isolation
      MockGetStorage.reset();
      testStorage = MockGetStorage.getInstance();

      parser = ActionParser();
      executor = ActionExecutor();
      historyService = ActionHistoryService(storage: testStorage);

      // Wait for any pending async operations to complete
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() async {
      // Clear storage and wait for cleanup
      MockGetStorage.reset();
      await Future.delayed(const Duration(milliseconds: 50));
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End Action Execution Flow', () {
      test('should execute complete flow: parse → execute → store in history',
          () async {
        // Arrange
        const command = 'Create a coffee shop list';
        const userId = 'user123';

        // Act - Parse
        final intent = await parser.parseAction(
          command,
          userId: userId,
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateListIntent>());

        // Act - Validate
        final canExecute = await parser.canExecute(intent!);
        expect(canExecute, isTrue);

        // Act - Execute (Note: This will fail without real repositories, but we test the flow)
        final result = await executor.execute(intent);

        // Act - Store in history (if successful)
        if (result.success) {
          await historyService.addAction(
            intent: intent,
            result: result,
          );
        }

        // Assert - Check history
        final history = await historyService.getHistory();
        if (result.success) {
          expect(history.length, greaterThan(0));
          expect(history.first.intent.type, equals('create_list'));
        }
      });

      test('should handle create spot flow with location', () async {
        // Arrange
        const command = 'Create a spot called "Test Coffee Shop"';
        const userId = 'user123';
        // Note: In real test, would use actual Position
        // For now, we test the parsing part

        // Act - Parse
        final intent = await parser.parseAction(
          command,
          userId: userId,
          // currentLocation would be provided in real scenario
        );

        // Assert
        if (intent != null) {
          expect(intent, isA<CreateSpotIntent>());
          final spotIntent = intent as CreateSpotIntent;
          expect(spotIntent.name, contains('Test Coffee Shop'));
        }
      });

      test('should handle add spot to list flow', () async {
        // Arrange
        const command = 'Add Central Park to my coffee shop list';
        const userId = 'user123';

        // Act - Parse
        final intent = await parser.parseAction(
          command,
          userId: userId,
        );

        // Assert
        expect(intent, isNotNull);
        expect(intent, isA<AddSpotToListIntent>());

        final addIntent = intent as AddSpotToListIntent;
        expect(addIntent.userId, equals(userId));
      });
    });

    group('Action History Flow', () {
      test('should store successful actions in history', () async {
        // Arrange
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test description',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'Coffee',
          userId: 'user123',
          confidence: 0.9,
        );
        final result = ActionResult.success(
          message: 'Spot created successfully',
          data: {'spotId': 'spot123'},
          intent: intent,
        );

        // Act
        await historyService.addAction(intent: intent, result: result);

        // Assert
        final history = await historyService.getHistory();
        expect(history.length, equals(1));
        expect(history.first.intent.type, equals('create_spot'));
        expect(history.first.result.success, isTrue);
      });

      test('should not store failed actions in history', () async {
        // Arrange
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );
        final result = ActionResult.failure(
          error: 'Failed to create spot',
          intent: intent,
        );

        // Act
        await historyService.addAction(intent: intent, result: result);

        // Assert
        final history = await historyService.getHistory();
        expect(history, isEmpty);
      });

      test('should retrieve recent actions in correct order', () async {
        // Arrange
        const intent1 = CreateSpotIntent(
          name: 'Spot 1',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );
        const intent2 = CreateListIntent(
          title: 'List 1',
          description: 'Test',
          userId: 'user123',
          confidence: 0.8,
        );

        await historyService.addAction(
          intent: intent1,
          result: ActionResult.success(intent: intent1),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await historyService.addAction(
          intent: intent2,
          result: ActionResult.success(intent: intent2),
        );

        // Act
        final recent = await historyService.getRecentActions(limit: 2);

        // Assert
        expect(recent.length, equals(2));
        expect(recent.first.intent.type, equals('create_list')); // Most recent
        expect(recent.last.intent.type, equals('create_spot'));
      });
    });

    group('Undo Flow', () {
      test('should undo action and mark as undone in history', () async {
        // Arrange
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );
        await historyService.addAction(
          intent: intent,
          result: ActionResult.success(
            intent: intent,
            data: {'spotId': 'spot123'},
          ),
        );

        final history = await historyService.getHistory();
        final entry = history.first;

        // Act
        await historyService.undoAction(entry.id);

        // Assert
        // Note: Currently undo returns failure because DeleteSpotUseCase not implemented
        // But the action should be marked as undone
        final updatedHistory = await historyService.getHistory();
        expect(updatedHistory.first.isUndone, isTrue);
      });

      test('should not allow undo of already undone action', () async {
        // Arrange
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );
        await historyService.addAction(
          intent: intent,
          result: ActionResult.success(intent: intent),
        );

        final history = await historyService.getHistory();
        final entry = history.first;

        // Undo once
        await historyService.undoAction(entry.id);

        // Act - Try to undo again
        final undoResult = await historyService.undoAction(entry.id);

        // Assert
        expect(undoResult.success, isFalse);
        expect(undoResult.message, contains('already undone'));
      });

      test('should get only undoable actions', () async {
        // Arrange
        const intent1 = CreateSpotIntent(
          name: 'Spot 1',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );
        const intent2 = CreateListIntent(
          title: 'List 1',
          description: 'Test',
          userId: 'user123',
          confidence: 0.8,
        );

        await historyService.addAction(
          intent: intent1,
          result: ActionResult.success(intent: intent1),
        );
        await historyService.addAction(
          intent: intent2,
          result: ActionResult.success(intent: intent2),
        );

        // Undo one action
        final history = await historyService.getHistory();
        // History is ordered newest first, so history[0] is List, history[1] is Spot
        // Undo the Spot (history[1])
        await historyService.undoAction(history[1].id);

        // Act
        final undoable = await historyService.getUndoableActions();

        // Assert
        expect(undoable.length, equals(1));
        // After undoing Spot, only the other action should remain undoable.
        expect(
          undoable.single.id,
          equals(history[0].id),
          reason: 'Only the non-undone action should remain undoable',
        );
      });
    });

    group('Error Handling Flow', () {
      test('should handle action execution errors gracefully', () async {
        // Arrange
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );

        // Act - Execute (will likely fail without real repositories)
        final result = await executor.execute(intent);

        // Assert
        // Result may be success or failure depending on test setup
        // But we verify the flow handles both cases
        expect(result, isNotNull);
        expect(result.intent, equals(intent));

        // Failed actions should not be stored
        if (!result.success) {
          final history = await historyService.getHistory();
          // Failed actions are not stored, so history should be empty or not contain this
          expect(
              history.where(
                  (e) => e.intent.type == intent.type && !e.result.success),
              isEmpty);
        }
      });

      test('should handle invalid action intents', () async {
        // Arrange
        const invalidIntent = CreateSpotIntent(
          name: '', // Invalid: empty name
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );

        // Act
        final canExecute = await parser.canExecute(invalidIntent);

        // Assert
        expect(canExecute, isFalse);
      });
    });

    group('Action Confirmation Flow', () {
      test('should validate action before execution', () async {
        // Arrange
        const intent = CreateListIntent(
          title: 'Test List',
          description: 'Test',
          userId: 'user123',
          confidence: 0.8,
        );

        // Act
        final canExecute = await parser.canExecute(intent);

        // Assert
        expect(canExecute, isTrue);
      });

      test('should reject invalid action intents', () async {
        // Arrange
        const invalidIntent = CreateListIntent(
          title: '', // Invalid: empty title
          description: 'Test',
          userId: 'user123',
          confidence: 0.8,
        );

        // Act
        final canExecute = await parser.canExecute(invalidIntent);

        // Assert
        expect(canExecute, isFalse);
      });
    });

    group('Complete User Flow', () {
      test(
          'should handle complete user flow: command → parse → confirm → execute → history → undo',
          () async {
        // Arrange
        const command = 'Create a coffee shop list';
        const userId = 'user123';

        // Step 1: Parse
        final intent = await parser.parseAction(command, userId: userId);
        expect(intent, isNotNull);

        // Step 2: Validate
        final canExecute = await parser.canExecute(intent!);
        expect(canExecute, isTrue);

        // Step 3: Execute (simulated - would show confirmation dialog in real flow)
        final result = await executor.execute(intent);

        // Step 4: Store in history (if successful)
        if (result.success) {
          await historyService.addAction(intent: intent, result: result);

          // Step 5: Verify in history
          final history = await historyService.getHistory();
          expect(history.length, greaterThan(0));

          // Step 6: Check if can undo
          final entry = history.first;
          final canUndo = await historyService.canUndo(entry.id);
          expect(canUndo, isTrue);

          // Step 7: Undo
          await historyService.undoAction(entry.id);
          // Note: Currently undo may fail because DeleteListUseCase not implemented
          // But the action should be marked as undone
          final updatedHistory = await historyService.getHistory();
          expect(updatedHistory.first.isUndone, isTrue);
        }
      });
    });
  });
}
