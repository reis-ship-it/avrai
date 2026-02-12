/// SPOTS FederatedLearningStatusWidget Widget Tests
/// Date: November 20, 2025
/// Purpose: Test FederatedLearningStatusWidget functionality and UI behavior
///
/// Test Coverage:
/// - Rendering: Active learning rounds display
/// - Participation Status: User participation in rounds
/// - Round Progress: Progress indicators and status
/// - Edge Cases: No active rounds, error states
///
/// Dependencies:
/// - FederatedLearningSystem: For round data
/// - RoundStatus: For round status display
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:avrai/core/p2p/federated_learning.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for FederatedLearningStatusWidget
/// Tests round display, participation status, and progress indicators
void main() {
  group('FederatedLearningStatusWidget Widget Tests', () {
    group('Rendering', () {
      // Removed: Property assignment tests
      // Rendering tests focus on business logic (widget display, active rounds, empty state, multiple rounds), not property assignment

      testWidgets(
          'should display widget with title, display active rounds when available, display no active rounds message when empty, or display multiple active rounds',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget rendering
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);
        expect(find.textContaining('Learning Round'), findsWidgets);

        final activeRounds1 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            roundNumber: 1,
            participantNodeIds: List.generate(5, (i) => 'node_$i'),
          ),
        ];
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('Round 1'), findsOneWidget);
        expect(find.textContaining('Training'), findsOneWidget);
        expect(find.textContaining('Learning: Recommendation'), findsOneWidget);

        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(
            activeRounds: [],
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.textContaining('No active'), findsOneWidget);

        final activeRounds2 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            roundNumber: 1,
          ),
          _createMockRound(
            roundId: 'round_2',
            status: RoundStatus.aggregating,
            roundNumber: 2,
          ),
        ];
        final widget4 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget4);
        expect(find.textContaining('Round 1'), findsOneWidget);
        expect(find.textContaining('Round 2'), findsOneWidget);
      });
    });

    group('Participation Status', () {
      // Removed: Property assignment tests
      // Participation status tests focus on business logic (participation status display), not property assignment

      testWidgets(
          'should display participation status when user is participating or display not participating when user is not in round',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget participation status
        final activeRounds1 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            participantNodeIds: ['node_1', 'node_2', 'current_user_node'],
          ),
        ];
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds1,
            currentNodeId: 'current_user_node',
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.textContaining('Participating'), findsOneWidget);

        final activeRounds2 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            participantNodeIds: ['node_1', 'node_2'],
          ),
        ];
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds2,
            currentNodeId: 'current_user_node',
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('Not participating'), findsOneWidget);
      });
    });

    group('Round Progress', () {
      // Removed: Property assignment tests
      // Round progress tests focus on business logic (progress indicator, round number, participant count, model accuracy), not property assignment

      testWidgets(
          'should display round progress indicator, display round number correctly, display participant count, or display model accuracy when available',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget round progress
        final activeRounds1 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            roundNumber: 3,
            participantUpdates: {'node_1': _createMockUpdate()},
            participantNodeIds: ['node_1', 'node_2', 'node_3'],
          ),
        ];
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.byType(LinearProgressIndicator), findsWidgets);

        final activeRounds2 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            roundNumber: 5,
          ),
        ];
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('Round 5'), findsOneWidget);

        final activeRounds3 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            participantNodeIds: List.generate(8, (i) => 'node_$i'),
          ),
        ];
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds3,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.textContaining('8'), findsOneWidget);
        expect(find.textContaining('participant'), findsOneWidget);

        final activeRounds4 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            modelAccuracy: 0.85,
          ),
        ];
        final widget4 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds4,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget4);
        expect(find.textContaining('85'), findsOneWidget);
        expect(find.textContaining('%'), findsOneWidget);
      });
    });

    group('Status Display', () {
      // Removed: Property assignment tests
      // Status display tests focus on business logic (training/aggregating/initializing status display), not property assignment

      testWidgets(
          'should display training status correctly, display aggregating status correctly, or display initializing status correctly',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget status display
        final activeRounds1 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
          ),
        ];
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.textContaining('Training'), findsOneWidget);

        final activeRounds2 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.aggregating,
          ),
        ];
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.textContaining('Aggregating'), findsOneWidget);

        final activeRounds3 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.initializing,
          ),
        ];
        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds3,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget3);
        expect(find.textContaining('Initializing'), findsOneWidget);
      });
    });

    group('Learning Objective Display', () {
      // Removed: Property assignment tests
      // Learning objective display tests focus on business logic (learning objective name, learning types with icons), not property assignment

      testWidgets(
          'should display learning objective name or display different learning types with appropriate icons',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget learning objective display
        final activeRounds1 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            objectiveName: 'Spot Recommendations',
            objectiveDescription: 'Improving recommendation accuracy',
          ),
        ];
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds1,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.textContaining('Learning: Spot Recommendations'),
            findsOneWidget);
        expect(find.textContaining('Improving recommendation accuracy'),
            findsOneWidget);

        final activeRounds2 = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
            learningType: LearningType.recommendation,
          ),
        ];
        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds2,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        expect(find.byIcon(Icons.recommend), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      // Removed: Property assignment tests
      // Edge cases tests focus on business logic (null currentNodeId handling, info icon display), not property assignment

      testWidgets(
          'should handle null currentNodeId gracefully or display info icon for learning round explanation',
          (WidgetTester tester) async {
        // Test business logic: Federated learning status widget edge cases
        final activeRounds = [
          _createMockRound(
            roundId: 'round_1',
            status: RoundStatus.training,
          ),
        ];
        final widget1 = WidgetTestHelpers.createTestableWidget(
          child: FederatedLearningStatusWidget(
            activeRounds: activeRounds,
            currentNodeId: null,
          ),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget1);
        expect(find.byType(FederatedLearningStatusWidget), findsOneWidget);

        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: const FederatedLearningStatusWidget(),
        );
        await WidgetTestHelpers.pumpAndSettle(tester, widget2);
        final infoButtons = find.byIcon(Icons.info_outline);
        expect(infoButtons, findsWidgets);
        expect(find.textContaining('Learning Round Status'), findsOneWidget);
      });
    });
  });
}

/// Helper function to create a mock FederatedLearningRound for testing
FederatedLearningRound _createMockRound({
  required String roundId,
  required RoundStatus status,
  int roundNumber = 1,
  List<String>? participantNodeIds,
  Map<String, LocalModelUpdate>? participantUpdates,
  double? modelAccuracy,
  String? objectiveName,
  String? objectiveDescription,
  LearningType? learningType,
}) {
  final participants = participantNodeIds ?? ['node_1', 'node_2', 'node_3'];
  final updates = participantUpdates ?? {};

  return FederatedLearningRound(
    roundId: roundId,
    organizationId: 'test_org',
    objective: LearningObjective(
      name: objectiveName ?? 'Recommendation',
      description: objectiveDescription ?? 'Test objective',
      type: learningType ?? LearningType.recommendation,
      parameters: {},
    ),
    participantNodeIds: participants,
    status: status,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    roundNumber: roundNumber,
    globalModel: GlobalModel(
      modelId: 'model_1',
      objective: LearningObjective(
        name: 'Recommendation',
        description: 'Test',
        type: LearningType.recommendation,
        parameters: {},
      ),
      version: 1,
      parameters: {},
      loss: 0.5,
      accuracy: modelAccuracy ?? 0.75,
      updatedAt: DateTime.now(),
    ),
    participantUpdates: updates,
    privacyMetrics: PrivacyMetrics.initial(),
  );
}

/// Helper function to create a mock LocalModelUpdate for testing
LocalModelUpdate _createMockUpdate() {
  return LocalModelUpdate(
    nodeId: 'node_1',
    roundId: 'round_1',
    gradients: {},
    trainingMetrics: TrainingMetrics(
      samplesUsed: 100,
      trainingLoss: 0.5,
      accuracy: 0.75,
      privacyBudgetUsed: 0.1,
    ),
    timestamp: DateTime.now(),
    privacyCompliant: true,
  );
}
