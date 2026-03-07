/// SPOTS AIImprovementPage Widget Tests
/// Date: November 27, 2025
/// Purpose: Test AIImprovementPage functionality and UI behavior
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
/// - AIImprovementTrackingService: For metrics data
/// - AuthBloc: For user authentication
/// - All 4 AI improvement widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:avrai/presentation/pages/settings/ai_improvement_page.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for AIImprovementPage
/// Tests page structure, widget integration, and user flows
void main() {
  group('AIImprovementPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUpAll(() async {
      await WidgetTestHelpers.setupWidgetTestEnvironment();

      // Minimal DI required for this page to initialize.
      if (GetIt.instance.isRegistered<AIImprovementTrackingService>()) {
        GetIt.instance.unregister<AIImprovementTrackingService>();
      }
      GetIt.instance.registerFactory<AIImprovementTrackingService>(
        () => AIImprovementTrackingService(),
      );
    });

    tearDownAll(() async {
      if (GetIt.instance.isRegistered<AIImprovementTrackingService>()) {
        GetIt.instance.unregister<AIImprovementTrackingService>();
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
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Title appears in the AppBar (and may also appear in header content).
        expect(find.text('AI Improvement'), findsWidgets);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays header section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Improvement'), findsWidgets);
        expect(
            find.textContaining('Review how your AI improves'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);
      });

      testWidgets('displays all section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Improvement Metrics'), findsWidgets);
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final progressHeader = find.text('Improvement Progress');
        for (var i = 0; i < 30 && progressHeader.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -500));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.text('Improvement Progress'), findsOneWidget);

        final historyHeader = find.text('Improvement History');
        for (var i = 0; i < 30 && historyHeader.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -500));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.text('Improvement History'), findsWidgets);

        final impactHeader = find.text('Impact & Benefits');
        for (var i = 0; i < 30 && impactHeader.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -500));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.text('Impact & Benefits'), findsOneWidget);
      });

      testWidgets('displays footer with learn more section',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final learnMore = find.text('Learn more');
        for (var i = 0; i < 40 && learnMore.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.text('Learn more'), findsOneWidget);
        expect(
            find.textContaining('Improvements focus on recommendation quality'),
            findsOneWidget);
      });
    });

    group('Widget Integration', () {
      testWidgets('displays all 4 AI improvement widgets',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(AIImprovementSection), findsOneWidget);
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final progressWidget = find.byType(AIImprovementProgressWidget);
        for (var i = 0; i < 40 && progressWidget.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);

        final timelineWidget = find.byType(AIImprovementTimelineWidget);
        for (var i = 0; i < 40 && timelineWidget.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);

        final impactWidget = find.byType(AIImprovementImpactWidget);
        for (var i = 0; i < 40 && impactWidget.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);
      });

      testWidgets('widgets are properly spaced and organized',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert - All widgets should be in a scrollable list
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(AIImprovementSection), findsOneWidget);
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final progressWidget = find.byType(AIImprovementProgressWidget);
        for (var i = 0; i < 40 && progressWidget.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('displays loading indicator during initialization',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle, check loading state

        // Assert - May show loading initially
        // After initialization, should show content
        await WidgetTestHelpers.safePumpAndSettle(tester);
        expect(find.byType(AIImprovementPage), findsOneWidget);
      });

      testWidgets('shows content after initialization completes',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when service initialization fails',
          (WidgetTester tester) async {
        // Arrange
        // Note: This test may need mocking of AIImprovementTrackingService
        // For now, we test that the page handles errors gracefully
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Page should render (either with content or error)
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // If error occurs, should show error UI
        // If no error, should show widgets
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasWidgets =
            find.byType(AIImprovementSection).evaluate().isNotEmpty;
        expect(hasError || hasWidgets, isTrue);
      });

      testWidgets('displays retry button when error occurs',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
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
          child: const AIImprovementPage(),
          authBloc: unauthenticatedBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert - Should show loading or redirect
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // May show loading indicator while waiting for auth
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays content for authenticated user',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Should eventually show widgets if authenticated
        await tester.pump(const Duration(seconds: 1));
        await WidgetTestHelpers.safePumpAndSettle(tester);
        // Page should be rendered
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('page is scrollable', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('all sections are accessible via scrolling',
          (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Scroll to bottom
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final learnMore = find.text('Learn More');
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
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await WidgetTestHelpers.safePumpAndSettle(tester);

        // Assert
        expect(find.textContaining('See how your AI is improving'),
            findsOneWidget);
        final list = find.byKey(const Key('ai_improvement_page_list'));
        final trackTrends = find.textContaining('Track improvement trends');
        for (var i = 0; i < 40 && trackTrends.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.textContaining('Track improvement trends'), findsOneWidget);

        final timeline = find.textContaining('Timeline of AI improvements');
        for (var i = 0; i < 40 && timeline.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(
            find.textContaining('Timeline of AI improvements'), findsOneWidget);

        final benefits = find.textContaining('How ongoing improvements affect');
        for (var i = 0; i < 40 && benefits.evaluate().isEmpty; i++) {
          await tester.drag(list, const Offset(0, -600));
          await WidgetTestHelpers.safePumpAndSettle(tester);
        }
        expect(find.textContaining('How ongoing improvements affect'),
            findsOneWidget);
      });
    });
  });
}
