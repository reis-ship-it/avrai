/// SPOTS FederatedParticipationHistoryWidget Widget Tests
/// Date: November 20, 2025
/// Purpose: Test FederatedParticipationHistoryWidget functionality and UI behavior
///
/// Test Coverage:
/// - Rendering: Participation history display
/// - Contribution Metrics: Rounds participated, contributions made
/// - Benefits Earned: Benefits received from participation
/// - Edge Cases: Empty history, error states
///
/// Dependencies:
/// - ParticipationHistory: For participation data
/// - FederatedLearningRound: For round information
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/p2p/federated_learning.dart';
import 'package:avrai/presentation/widgets/settings/federated_participation_history_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for FederatedParticipationHistoryWidget
/// Tests participation history, contributions, and benefits display
void main() {
  group('FederatedParticipationHistoryWidget Widget Tests', () {
    group('Rendering', () {
      // Removed: Property assignment tests
      // Rendering tests focus on business logic (widget display, participation history, empty state), not property assignment

      testWidgets(
          'should display widget with title, display participation history when available, or display empty state when no history',
          (WidgetTester tester) async {
        // Test business logic: Federated participation history widget rendering
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: const FederatedParticipationHistoryWidget(),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(
            find.byType(FederatedParticipationHistoryWidget), findsOneWidget);
        expect(find.textContaining('Participation History'), findsOneWidget);

        final history = ParticipationHistory(
          totalRoundsParticipated: 12,
          completedRounds: 10,
          totalContributions: 45,
          benefitsEarned: ['Improved Recommendations', 'Early Access Features'],
          lastParticipationDate:
              DateTime.now().subtract(const Duration(days: 2)),
          participationStreak: 5,
        );
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('12'), findsOneWidget);
        expect(find.textContaining('Total Rounds'), findsOneWidget);

        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: const FederatedParticipationHistoryWidget(
            participationHistory: null,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.textContaining('No participation'), findsOneWidget);
      });
    });

    group('Contribution Metrics', () {
      // Removed: Property assignment tests
      // Contribution metrics tests focus on business logic (total rounds, completed rounds, total contributions, participation streak), not property assignment

      testWidgets(
          'should display total rounds participated, display completed rounds count, display total contributions, or display participation streak',
          (WidgetTester tester) async {
        // Test business logic: Federated participation history widget contribution metrics
        final history1 = ParticipationHistory(
          totalRoundsParticipated: 25,
          completedRounds: 23,
          totalContributions: 100,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 10,
        );
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.textContaining('25'), findsOneWidget);
        expect(find.textContaining('Total Rounds'), findsOneWidget);

        final history2 = ParticipationHistory(
          totalRoundsParticipated: 20,
          completedRounds: 18,
          totalContributions: 80,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 8,
        );
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('18'), findsOneWidget);
        expect(find.textContaining('Completed'), findsOneWidget);

        final history3 = ParticipationHistory(
          totalRoundsParticipated: 15,
          completedRounds: 15,
          totalContributions: 67,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 5,
        );
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history3,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.textContaining('67'), findsOneWidget);
        expect(find.textContaining('Contributions'), findsOneWidget);

        final history4 = ParticipationHistory(
          totalRoundsParticipated: 10,
          completedRounds: 10,
          totalContributions: 40,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 7,
        );
        final widget4 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history4,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget4);
        expect(find.textContaining('7'), findsOneWidget);
        expect(find.textContaining('Streak'), findsOneWidget);
      });
    });

    group('Benefits Earned', () {
      // Removed: Property assignment tests
      // Benefits earned tests focus on business logic (benefits display, empty state), not property assignment

      testWidgets(
          'should display benefits earned or display no benefits message when empty',
          (WidgetTester tester) async {
        // Test business logic: Federated participation history widget benefits earned
        final history1 = ParticipationHistory(
          totalRoundsParticipated: 10,
          completedRounds: 10,
          totalContributions: 40,
          benefitsEarned: [
            'Improved Recommendations',
            'Early Access Features',
            'Priority Support',
          ],
          lastParticipationDate: DateTime.now(),
          participationStreak: 5,
        );
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.textContaining('Benefits'), findsOneWidget);
        expect(find.textContaining('Improved Recommendations'), findsOneWidget);
        expect(find.textContaining('Early Access'), findsOneWidget);

        final history2 = ParticipationHistory(
          totalRoundsParticipated: 5,
          completedRounds: 5,
          totalContributions: 20,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 2,
        );
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('No benefits'), findsOneWidget);
      });
    });

    group('Visual Indicators', () {
      // Removed: Property assignment tests
      // Visual indicators tests focus on business logic (progress indicators, completion rate), not property assignment

      testWidgets(
          'should display progress indicators or display completion rate',
          (WidgetTester tester) async {
        // Test business logic: Federated participation history widget visual indicators
        final history = ParticipationHistory(
          totalRoundsParticipated: 10,
          completedRounds: 8,
          totalContributions: 35,
          benefitsEarned: [],
          lastParticipationDate: DateTime.now(),
          participationStreak: 4,
        );
        final widget = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        expect(find.textContaining('80'), findsOneWidget);
        expect(find.textContaining('%'), findsWidgets);
      });
    });

    group('Edge Cases', () {
      // Removed: Property assignment tests
      // Edge cases tests focus on business logic (zero participation handling, last participation date), not property assignment

      testWidgets(
          'should handle zero participation gracefully or display last participation date when available',
          (WidgetTester tester) async {
        // Test business logic: Federated participation history widget edge cases
        final history1 = ParticipationHistory(
          totalRoundsParticipated: 0,
          completedRounds: 0,
          totalContributions: 0,
          benefitsEarned: [],
          lastParticipationDate: null,
          participationStreak: 0,
        );
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(
            find.byType(FederatedParticipationHistoryWidget), findsOneWidget);
        expect(find.textContaining('0'), findsWidgets);

        final lastDate = DateTime.now().subtract(const Duration(days: 3));
        final history2 = ParticipationHistory(
          totalRoundsParticipated: 5,
          completedRounds: 5,
          totalContributions: 20,
          benefitsEarned: [],
          lastParticipationDate: lastDate,
          participationStreak: 2,
        );
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedParticipationHistoryWidget(
            participationHistory: history2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('Last participation'), findsOneWidget);
      });
    });
  });
}
