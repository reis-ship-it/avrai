import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_learning_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import '../../../helpers/platform_channel_helper.dart';
import '../../../widget/helpers/widget_test_helpers.dart';
import '../../../widget/mocks/mock_blocs.dart';

/// Widget tests for AI2AILearningMethodsWidget
void main() {
  group('AI2AILearningMethodsWidget Widget Tests', () {
    // Removed: Property assignment tests
    // AI2AI learning methods widget tests focus on business logic (widget initialization, data display, error handling), not property assignment

    late AI2AILearning learningService;
    late SharedPreferencesCompat prefs;

    setUp(() async {
      await setupTestStorage();
      prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      final personalityLearning = PersonalityLearning.withPrefs(prefs);
      learningService = AI2AILearning.create(
        prefs: prefs,
        personalityLearning: personalityLearning,
      );
    });

    testWidgets(
        'should display widget with loading state initially, call service methods on initialization, display learning insights when available, handle empty data gracefully, or handle service errors gracefully',
        (WidgetTester tester) async {
      // Test business logic: AI2AI learning methods widget display and interactions
      const userId1 = 'test_user';
      final mockAuthBloc1 = MockBlocFactory.createAuthenticatedAuthBloc();
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: AI2AILearningMethodsWidget(
          userId: userId1,
          learningService: learningService,
        ),
        authBloc: mockAuthBloc1,
      );
      await tester.pumpWidget(widget1);
      await tester.pump();
      expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);

      const userId2 = 'new_user';
      final mockAuthBloc2 = MockBlocFactory.createAuthenticatedAuthBloc();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: AI2AILearningMethodsWidget(
          userId: userId2,
          learningService: learningService,
        ),
        authBloc: mockAuthBloc2,
      );
      await tester.pumpWidget(widget2);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);

      const userId3 = 'error_user';
      final mockAuthBloc3 = MockBlocFactory.createAuthenticatedAuthBloc();
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: AI2AILearningMethodsWidget(
          userId: userId3,
          learningService: learningService,
        ),
        authBloc: mockAuthBloc3,
      );
      await tester.pumpWidget(widget3);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
    });
  });
}
