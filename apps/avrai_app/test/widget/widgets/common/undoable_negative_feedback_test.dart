import 'package:avrai/presentation/widgets/common/undoable_negative_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showUndoableNegativeFeedback', () {
    testWidgets('runs optimistic update immediately and skips commit on undo', (
      tester,
    ) async {
      var optimisticCount = 0;
      var undoCount = 0;
      var commitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () {
                      showUndoableNegativeFeedback(
                        context: context,
                        message: 'List hidden for now.',
                        duration: const Duration(milliseconds: 200),
                        onOptimisticUpdate: () {
                          optimisticCount++;
                        },
                        onUndo: () {
                          undoCount++;
                        },
                        onCommit: () async {
                          commitCount++;
                        },
                      );
                    },
                    child: const Text('Dismiss'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(optimisticCount, 1);
      expect(commitCount, 0);
      expect(find.text('List hidden for now.'), findsOneWidget);

      final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      action.onPressed();
      await tester.pumpAndSettle();

      expect(undoCount, 1);
      expect(commitCount, 0);
    });

    testWidgets('commits when snackbar closes without undo', (tester) async {
      var commitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () {
                      showUndoableNegativeFeedback(
                        context: context,
                        message: 'List dismissed.',
                        duration: const Duration(milliseconds: 200),
                        onCommit: () async {
                          commitCount++;
                        },
                      );
                    },
                    child: const Text('Dismiss'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(commitCount, 0);
      expect(find.text('List dismissed.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(commitCount, 1);
    });
  });
}
