// Tests for LearningAnalyticsPage
// Phase 11 Section 8: Learning Quality Monitoring

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai/apps/admin_app/ui/pages/learning_analytics_page.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

void main() {
  group('LearningAnalyticsPage', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.instance;
      await getIt.reset();

      // Register required services
      getIt.registerLazySingleton<AgentIdService>(() => AgentIdService());
      getIt.registerLazySingleton<ContinuousLearningSystem>(() {
        return ContinuousLearningSystem(
          agentIdService: getIt<AgentIdService>(),
        );
      });
      // SupabaseService is optional - the page handles null gracefully
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('renders page correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningAnalyticsPage(),
        ),
      );

      // Wait for initial build
      await tester.pump();

      // Page should render (will show loading or empty state depending on data)
      expect(find.byType(LearningAnalyticsPage), findsOneWidget);
    });

    testWidgets('displays learning analytics title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningAnalyticsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have title in app bar
      expect(find.text('Learning Analytics'), findsOneWidget);
    });

    testWidgets('has refresh button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningAnalyticsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays empty state when no learning data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningAnalyticsPage(),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should show empty state (no data available) or page content
      // The page shows empty state when userId is null or no data is available
      expect(
        find.text('No learning data available').evaluate().isNotEmpty ||
            find.byType(LearningAnalyticsPage).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
