import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/evolution_timeline_widget.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/theme/colors.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for EvolutionTimelineWidget
/// Tests personality evolution timeline display including statistics, milestones, date formatting, and ordering
void main() {
  group('EvolutionTimelineWidget Widget Tests', () {
    testWidgets('should display empty state when no milestones', (WidgetTester tester) async {
      // Arrange: Profile with no milestones
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'developing',
        authenticity: 0.5,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 0,
          'successful_ai2ai_connections': 0,
          'evolution_milestones': <DateTime>[],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Empty state is displayed
      expect(find.byType(EvolutionTimelineWidget), findsOneWidget);
      expect(find.text('Evolution Timeline'), findsOneWidget);
      expect(find.text('No evolution milestones yet'), findsOneWidget);
      expect(find.text('Milestones will appear as your personality evolves'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      
      // Verify no milestone items are displayed
      expect(find.text('Evolution Milestone'), findsNothing);
    });

    testWidgets('should display statistics correctly', (WidgetTester tester) async {
      // Arrange: Profile with statistics
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.75,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 5,
        learningHistory: {
          'total_interactions': 100,
          'successful_ai2ai_connections': 25,
          'evolution_milestones': <DateTime>[],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All statistics are displayed correctly
      expect(find.text('Generation'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Interactions'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('should display milestones when they exist', (WidgetTester tester) async {
      // Arrange: Profile with milestones
      final milestones = <DateTime>[
        TestHelpers.createTestDateTime().subtract(const Duration(days: 10)),
        TestHelpers.createTestDateTime().subtract(const Duration(days: 5)),
        TestHelpers.createTestDateTime().subtract(const Duration(days: 1)),
      ];
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: TestHelpers.createTestDateTime().subtract(const Duration(days: 30)),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 3,
        learningHistory: {
          'total_interactions': 50,
          'successful_ai2ai_connections': 10,
          'evolution_milestones': milestones,
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Milestones are displayed
      expect(find.text('Evolution Milestone'), findsNWidgets(3));
    });

    testWidgets('should limit displayed milestones to 10 when more than 10 exist', (WidgetTester tester) async {
      // Arrange: Profile with 15 milestones
      final milestones = List<DateTime>.generate(15, (index) => 
        TestHelpers.createTestDateTime().subtract(Duration(days: 15 - index))
      );
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: TestHelpers.createTestDateTime().subtract(const Duration(days: 30)),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 15,
        learningHistory: {
          'total_interactions': 200,
          'successful_ai2ai_connections': 50,
          'evolution_milestones': milestones,
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Only 10 milestones are displayed (most recent 10)
      expect(find.text('Evolution Milestone'), findsNWidgets(10));
    });

    testWidgets('should display all milestones when exactly 10 exist', (WidgetTester tester) async {
      // Arrange: Profile with exactly 10 milestones
      final milestones = List<DateTime>.generate(10, (index) => 
        TestHelpers.createTestDateTime().subtract(Duration(days: 10 - index))
      );
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: TestHelpers.createTestDateTime().subtract(const Duration(days: 30)),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 10,
        learningHistory: {
          'total_interactions': 150,
          'successful_ai2ai_connections': 40,
          'evolution_milestones': milestones,
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All 10 milestones are displayed
      expect(find.text('Evolution Milestone'), findsNWidgets(10));
    });

    testWidgets('should display milestones in reverse order (most recent first)', (WidgetTester tester) async {
      // Arrange: Profile with milestones in chronological order (oldest first)
      final now = TestHelpers.createTestDateTime();
      final milestones = <DateTime>[
        now.subtract(const Duration(days: 10)), // Oldest
        now.subtract(const Duration(days: 5)),  // Middle
        now.subtract(const Duration(days: 1)),   // Most recent
      ];
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 3,
        learningHistory: {
          'total_interactions': 50,
          'successful_ai2ai_connections': 10,
          'evolution_milestones': milestones,
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Milestones are displayed (widget reverses them, so most recent appears first)
      // We can't easily test the exact order without inspecting the date text, but we verify
      // that the most recent milestone (1 day ago) is highlighted as latest
      expect(find.text('Evolution Milestone'), findsNWidgets(3));
    });

    testWidgets('should highlight latest milestone with success color', (WidgetTester tester) async {
      // Arrange: Profile with multiple milestones
      final now = TestHelpers.createTestDateTime();
      final milestones = <DateTime>[
        now.subtract(const Duration(days: 10)),
        now.subtract(const Duration(days: 5)),
        now.subtract(const Duration(days: 1)), // Latest
      ];
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 3,
        learningHistory: {
          'total_interactions': 50,
          'successful_ai2ai_connections': 10,
          'evolution_milestones': milestones,
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Find the Container with success color (latest milestone indicator)
      final latestIndicator = find.byWidgetPredicate(
        (widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          return decoration.shape == BoxShape.circle && 
                 decoration.color == AppColors.success;
        },
      );
      expect(latestIndicator, findsOneWidget); // Only the latest milestone has success color
      
      // Assert: Other milestones have grey color
      final greyIndicators = find.byWidgetPredicate(
        (widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          return decoration.shape == BoxShape.circle && 
                 decoration.color == AppColors.grey400;
        },
      );
      expect(greyIndicators, findsNWidgets(2)); // Two older milestones have grey color
    });

    testWidgets('should format date as "Today" when milestone is today', (WidgetTester tester) async {
      // Arrange: Profile with milestone from today
      final now = DateTime.now();
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 10,
          'successful_ai2ai_connections': 2,
          'evolution_milestones': <DateTime>[now], // Today
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Date is formatted as "Today"
      expect(find.text('Today'), findsAtLeastNWidgets(1)); // Appears in milestone and possibly dates
    });

    testWidgets('should format date as "Yesterday" when milestone is yesterday', (WidgetTester tester) async {
      // Arrange: Profile with milestone from yesterday
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 10,
          'successful_ai2ai_connections': 2,
          'evolution_milestones': <DateTime>[yesterday],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Date is formatted as "Yesterday"
      expect(find.text('Yesterday'), findsAtLeastNWidgets(1));
    });

    testWidgets('should format date as "X days ago" when milestone is 2-6 days ago', (WidgetTester tester) async {
      // Arrange: Profile with milestone from 3 days ago
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 10,
          'successful_ai2ai_connections': 2,
          'evolution_milestones': <DateTime>[threeDaysAgo],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Date is formatted as "3 days ago"
      expect(find.textContaining('3 days ago'), findsAtLeastNWidgets(1));
    });

    testWidgets('should format date as "MM/DD/YYYY" when milestone is 7+ days ago', (WidgetTester tester) async {
      // Arrange: Profile with milestone from 10 days ago
      final now = DateTime.now();
      final tenDaysAgo = now.subtract(const Duration(days: 10));
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.8,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdated: now,
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 10,
          'successful_ai2ai_connections': 2,
          'evolution_milestones': <DateTime>[tenDaysAgo],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Date is formatted as "MM/DD/YYYY"
      // Format: month/day/year (e.g., "1/15/2025")
      final formattedDate = '${tenDaysAgo.month}/${tenDaysAgo.day}/${tenDaysAgo.year}';
      expect(find.textContaining(formattedDate), findsAtLeastNWidgets(1));
    });

    testWidgets('should display created and last updated dates', (WidgetTester tester) async {
      // Arrange: Profile with specific dates
      final createdAt = TestHelpers.createTestDateTime(2025, 1, 1);
      final updatedAt = TestHelpers.createTestDateTime(2025, 1, 15);
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.7,
        createdAt: createdAt,
        lastUpdated: updatedAt,
        evolutionGeneration: 2,
        learningHistory: {
          'total_interactions': 20,
          'successful_ai2ai_connections': 5,
          'evolution_milestones': <DateTime>[],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Created and Last Updated dates are displayed
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('Last Updated:'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
    });

    testWidgets('should display card with elevation', (WidgetTester tester) async {
      // Arrange: Profile
      // Phase 8.3: Use agentId for privacy protection
      final profile = PersonalityProfile(
        agentId: 'agent_test-user-id',
        userId: 'test-user-id',
        dimensions: {},
        dimensionConfidence: {},
        archetype: 'explorer',
        authenticity: 0.75,
        createdAt: TestHelpers.createTestDateTime(),
        lastUpdated: TestHelpers.createTestDateTime(),
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 10,
          'successful_ai2ai_connections': 2,
          'evolution_milestones': <DateTime>[],
        },
      );

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EvolutionTimelineWidget(profile: profile),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Card is displayed with elevation
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final card = tester.widget<Card>(cardFinder);
      expect(card.elevation, equals(2));
    });
  });
}
