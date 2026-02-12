/// Tests for Action Success Widget
///
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/presentation/widgets/common/action_success_widget.dart';

void main() {
  group('ActionSuccessWidget', () {
    // Removed: Property assignment tests
    // Action success widget tests focus on business logic (success dialog display, user interactions, intent handling), not property assignment

    testWidgets(
        'should display success dialog for CreateListIntent, display success dialog for CreateSpotIntent, show undo button with countdown, call onViewResult when View button tapped, close dialog when Done button tapped, or handle AddSpotToListIntent',
        (tester) async {
      // Test business logic: action success widget display and interactions
      const intent1 = CreateListIntent(
        title: 'Coffee Shops',
        description: 'Best coffee spots',
        userId: 'user-1',
        confidence: 0.9,
      );
      final result1 = ActionResult.success(
        intent: intent1,
        message: 'List created successfully',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_1'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result1),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('🎉 List Created!'), findsOneWidget);
      expect(find.text('Coffee Shops'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      const intent2 = CreateSpotIntent(
        name: 'Blue Bottle Coffee',
        description: 'Great coffee spot',
        category: 'cafe',
        latitude: 37.7749,
        longitude: -122.4194,
        userId: 'user-1',
        confidence: 0.85,
      );
      final result2 = ActionResult.success(
        intent: intent2,
        message: 'Spot created successfully',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_2'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result2),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('📍 Spot Created!'), findsOneWidget);
      expect(find.text('Blue Bottle Coffee'), findsOneWidget);

      bool undoCalled = false;
      const intent3 = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      final result3 = ActionResult.success(
        intent: intent3,
        message: 'Created',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_3'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(
                      result: result3,
                      onUndo: () {
                        undoCalled = true;
                      },
                      undoTimeout: const Duration(seconds: 5),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Can undo in'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undoCalled, isTrue);

      bool viewCalled = false;
      const intent4 = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      final result4 = ActionResult.success(
        intent: intent4,
        message: 'Created',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_4'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(
                      result: result4,
                      onViewResult: () {
                        viewCalled = true;
                      },
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('View'), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(viewCalled, isTrue);

      const intent5 = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      final result5 = ActionResult.success(
        intent: intent5,
        message: 'Created',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_5'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result5),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('🎉 List Created!'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('🎉 List Created!'), findsNothing);

      const intent6 = AddSpotToListIntent(
        spotId: 'spot-1',
        listId: 'list-1',
        userId: 'user-1',
        confidence: 0.8,
        metadata: {
          'spotName': 'Blue Bottle',
          'listName': 'Coffee Shops',
        },
      );
      final result6 = ActionResult.success(
        intent: intent6,
        message: 'Added to list',
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('action_success_app_6'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result6),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('✨ Added to List!'), findsOneWidget);
      expect(find.text('Blue Bottle'), findsOneWidget);
      expect(find.text('Coffee Shops'), findsOneWidget);
    });
  });

  group('ActionSuccessToast', () {
    testWidgets(
        'should render toast with message or render with custom icon and color',
        (tester) async {
      // Test business logic: action success toast display
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionSuccessToast(
              message: 'Action completed!',
            ),
          ),
        ),
      );
      expect(find.text('Action completed!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionSuccessToast(
              message: 'Deleted!',
              icon: Icons.delete,
            ),
          ),
        ),
      );
      expect(find.text('Deleted!'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
