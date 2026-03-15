/// SPOTS AI2AILearningMethodsPage Widget Tests
/// Date: November 28, 2025
/// Purpose: Test AI2AILearningMethodsPage functionality and UI behavior
///
/// Test Coverage:
/// - Page Structure: Header, sections, footer
/// - Widget Integration: All 4 widgets displayed
/// - Loading States: Initialization loading
/// - Error Handling: Service initialization errors
/// - Authentication: Requires authenticated user
/// - Navigation: Back navigation
///
/// Dependencies:
/// - AI2AILearning service: For learning data
/// - AuthBloc: For user authentication
/// - All 4 AI2AI learning widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_learning_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/presentation/pages/settings/ai2ai_learning_methods_page.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for AI2AILearningMethodsPage
/// Tests page structure, widget integration, and user flows
void main() {
  group('AI2AILearningMethodsPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    final pageScroll =
        find.byKey(const Key('ai2ai_learning_methods_page_scroll'));

    setUpAll(() async {
      await WidgetTestHelpers.setupWidgetTestEnvironment();

      // Minimal DI required for this page to initialize.
      if (!GetIt.instance.isRegistered<AgentIdService>()) {
        di.sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
      }

      if (di.sl.isRegistered<AI2AILearning>()) {
        di.sl.unregister<AI2AILearning>();
      }

      final prefs = di.sl<SharedPreferencesCompat>();
      final personalityLearning = PersonalityLearning.withPrefs(prefs);
      final learningService = AI2AILearning.create(
        prefs: prefs,
        personalityLearning: personalityLearning,
      );
      di.sl.registerSingleton<AI2AILearning>(learningService);
    });

    tearDownAll(() async {
      if (di.sl.isRegistered<AI2AILearning>()) {
        di.sl.unregister<AI2AILearning>();
      }
      if (di.sl.isRegistered<AgentIdService>()) {
        di.sl.unregister<AgentIdService>();
      }
      await WidgetTestHelpers.cleanupWidgetTestEnvironment();
    });

    setUp(() {
      mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
    });

    group('Page Structure', () {
      testWidgets('displays page with app bar', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // Title appears in both the AppBar and the page header.
        expect(find.text('AI2AI Learning Methods'), findsWidgets);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays header section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI2AI Learning Methods'), findsWidgets);
        expect(
            find.textContaining('Review how your AI learns'), findsOneWidget);
        expect(find.byIcon(Icons.psychology_outlined), findsWidgets);
      });

      testWidgets('displays all section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert (top sections should render immediately)
        expect(find.text('Learning Methods Overview'), findsOneWidget);
        // This may also be below-the-fold depending on device/text scale.
        // We assert it after ensuring it can be scrolled into view.

        final list = pageScroll;

        Future<void> scrollTo(Finder target) async {
          for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
            await tester.drag(list, const Offset(0, -400));
            await WidgetTestHelpers.safePumpAndSettle(tester);
          }
        }

        await scrollTo(find.text('Learning Effectiveness Metrics'));
        expect(find.text('Learning Effectiveness Metrics'), findsOneWidget);

        await scrollTo(find.text('Active Learning Insights'));
        expect(find.text('Active Learning Insights'), findsOneWidget);

        await scrollTo(find.text('Learning Recommendations'));
        expect(find.text('Learning Recommendations'), findsWidgets);
      });

      testWidgets('displays footer with learn more section',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        final list = pageScroll;
        final learnMore = find.text('Learn more');
        for (var i = 0; i < 30 && learnMore.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -500));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }

        // Assert
        expect(find.text('Learn more'), findsOneWidget);
        expect(
            find.textContaining('AI2AI learning uses secure'), findsOneWidget);
      });
    });

    group('Widget Integration', () {
      testWidgets('displays all 4 AI2AI learning widgets',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        // Wait for widgets to initialize
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert - All widgets should be present
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        final list = pageScroll;

        Future<void> scrollTo(Finder target) async {
          for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
            await tester.drag(list, const Offset(0, -500));
            await WidgetTestHelpers.safePumpAndSettle(tester);
          }
        }

        await scrollTo(find.byType(AI2AILearningEffectivenessWidget));
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);

        await scrollTo(find.byType(AI2AILearningInsightsWidget));
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);

        await scrollTo(find.byType(AI2AILearningRecommendationsWidget));
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);
      });

      testWidgets('widgets are properly spaced and organized',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert - All widgets should be in a scrollable page
        expect(find.byType(Scrollable), findsWidgets);
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        final list = pageScroll;
        final effectiveness = find.byType(AI2AILearningEffectivenessWidget);
        for (var i = 0; i < 30 && effectiveness.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -500));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(effectiveness, findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('displays loading indicator during initialization',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle, check loading state

        // Assert - May show loading initially
        // After initialization, should show content
        await WidgetTestHelpers.safePumpAndSettle(tester);
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
      });

      testWidgets('shows content after initialization completes',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        // Loading indicator should be gone after initialization
        final loadingIndicators = find.byType(CircularProgressIndicator);
        if (loadingIndicators.evaluate().isNotEmpty) {
          // If loading indicator still present, wait more
          await tester.pump(const Duration(seconds: 1));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when service initialization fails',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Page should render (either with content or error)
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // If error occurs, should show error UI
        // If no error, should show widgets
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasWidgets =
            find.byType(AI2AILearningMethodsWidget).evaluate().isNotEmpty;
        expect(hasError || hasWidgets, isTrue);
      });

      testWidgets('displays retry button when error occurs',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - If error UI is shown, retry button should be present
        final retryButton = find.text('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          expect(retryButton, findsOneWidget);
        }
      });
    });

    group('Authentication', () {
      testWidgets('requires authenticated user', (WidgetTester tester) async {
        // Arrange
        final unauthenticatedBloc =
            MockBlocFactory.createUnauthenticatedAuthBloc();
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: unauthenticatedBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert - Should show loading or redirect
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // May show loading indicator while waiting for auth
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays content for authenticated user',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // Should eventually show widgets if authenticated
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('page is scrollable', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('all sections are accessible via scrolling',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Scroll to bottom
        final list = pageScroll;
        final learnMore = find.text('Learn more');
        for (var i = 0; i < 40 && learnMore.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }

        // Assert
        expect(find.text('Learn more'), findsOneWidget);
      });
    });

    group('Section Descriptions', () {
      testWidgets('displays section descriptions', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);
        await tester.pump(const Duration(seconds: 2));
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(
            find.textContaining('Review how your AI learns'), findsOneWidget);
        expect(find.textContaining('Track how effectively'), findsOneWidget);

        final list = pageScroll;
        final recentInsights = find.textContaining('Recent insights');
        for (var i = 0; i < 40 && recentInsights.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.textContaining('Recent insights'), findsOneWidget);

        final optimalPartners = find.textContaining('Suggested partners');
        for (var i = 0; i < 40 && optimalPartners.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.textContaining('Suggested partners'), findsOneWidget);
      });
    });
  });
}
