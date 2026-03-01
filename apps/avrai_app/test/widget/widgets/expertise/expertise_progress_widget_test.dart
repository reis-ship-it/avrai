import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_progress_widget.dart';
import 'package:avrai_core/models/expertise/expertise_progress.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertiseProgressWidget
/// Tests expertise progress display
void main() {
  group('ExpertiseProgressWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expertise progress widget tests focus on business logic (progress display, level progression, user interactions), not property assignment

    testWidgets(
        'should display current level and category, display progress bar when next level exists, display highest level message when at max level, display/hide contribution summary based on showDetails, call onTap callback when tapped, or display compact version correctly',
        (WidgetTester tester) async {
      // Test business logic: expertise progress widget display and interactions
      final progress1 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: const {
          'spots': 5,
          'lists': 2,
          'reviews': 10,
        },
        totalContributions: 17,
        requiredContributions: 30,
        nextSteps: const ['Create 3 more spots', 'Write 5 more reviews'],
        lastUpdated: DateTime.now(),
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(ExpertiseProgressWidget), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Local Level'), findsOneWidget);
      expect(find.text('• Brooklyn'), findsOneWidget);

      final progress2 = ExpertiseProgress(
        category: 'Restaurants',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 75.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Manhattan',
        contributionBreakdown: const {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: const [],
        lastUpdated: DateTime.now(),
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('75'), findsOneWidget);

      final progress3 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.global,
        progressPercentage: 100.0,
        nextLevel: null,
        location: 'Global',
        contributionBreakdown: const {
          'spots': 100,
          'lists': 50,
          'reviews': 200,
        },
        totalContributions: 350,
        requiredContributions: 0,
        nextSteps: const [],
        lastUpdated: DateTime.now(),
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress3),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Highest level achieved!'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      final progress4 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: const {
          'spots': 5,
          'lists': 2,
          'reviews': 10,
        },
        totalContributions: 17,
        requiredContributions: 30,
        nextSteps: const ['Create 3 more spots'],
        lastUpdated: DateTime.now(),
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress4, showDetails: true),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.text('Your Contributions'), findsOneWidget);
      expect(find.text('Next Steps'), findsOneWidget);
      expect(find.text('Create 3 more spots'), findsOneWidget);

      final progress5 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: const {
          'spots': 5,
        },
        totalContributions: 5,
        requiredContributions: 30,
        nextSteps: const ['Create 3 more spots'],
        lastUpdated: DateTime.now(),
      );
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(progress: progress5, showDetails: false),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      expect(find.text('Your Contributions'), findsNothing);
      expect(find.text('Next Steps'), findsNothing);

      bool tapped = false;
      final progress6 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: const {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: const [],
        lastUpdated: DateTime.now(),
      );
      final widget6 = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseProgressWidget(
          progress: progress6,
          onTap: () {
            tapped = true;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget6);
      await tester.tap(find.byType(ExpertiseProgressWidget));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      final progress7 = ExpertiseProgress(
        category: 'Coffee',
        currentLevel: ExpertiseLevel.local,
        progressPercentage: 50.0,
        nextLevel: ExpertiseLevel.city,
        location: 'Brooklyn',
        contributionBreakdown: const {},
        totalContributions: 0,
        requiredContributions: 0,
        nextSteps: const [],
        lastUpdated: DateTime.now(),
      );
      final widget7 = WidgetTestHelpers.createTestableWidget(
        child: CompactExpertiseProgressWidget(progress: progress7),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget7);
      expect(find.byType(CompactExpertiseProgressWidget), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
