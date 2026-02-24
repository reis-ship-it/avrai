import 'package:avrai/presentation/widgets/feedback/minimal_feedback_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinimalFeedbackPrompt', () {
    testWidgets('shows thumbs actions and details are collapsed by default',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          MinimalFeedbackPrompt(
            onQuickFeedback: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('feedback_thumbs_up')), findsOneWidget);
      expect(find.byKey(const Key('feedback_thumbs_down')), findsOneWidget);
      expect(find.byKey(const Key('feedback_rating_slider')), findsNothing);
      expect(find.byKey(const Key('feedback_notes_field')), findsNothing);
    });

    testWidgets('quick feedback callbacks fire from thumbs', (tester) async {
      bool? lastValue;
      await tester.pumpWidget(
        wrapWidget(
          MinimalFeedbackPrompt(
            onQuickFeedback: (value) {
              lastValue = value;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('feedback_thumbs_down')));
      await tester.pump();
      expect(lastValue, isFalse);

      await tester.tap(find.byKey(const Key('feedback_thumbs_up')));
      await tester.pump();
      expect(lastValue, isTrue);
    });

    testWidgets('optional details submit emits rating and note',
        (tester) async {
      MinimalFeedbackSubmission? submission;
      await tester.pumpWidget(
        wrapWidget(
          MinimalFeedbackPrompt(
            onQuickFeedback: (_) {},
            onDetailedFeedback: (value) {
              submission = value;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('feedback_thumbs_down')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('feedback_toggle_details')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback_rating_slider')), findsOneWidget);
      expect(find.byKey(const Key('feedback_notes_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('feedback_notes_field')),
        'Wanted a quieter place.',
      );
      await tester.tap(find.byKey(const Key('feedback_submit_detailed')));
      await tester.pump();

      expect(submission, isNotNull);
      expect(submission!.positive, isFalse);
      expect(submission!.rating, 3.0);
      expect(submission!.freeText, 'Wanted a quieter place.');
    });
  });
}
