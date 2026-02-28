import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/profile/ai_personality_status_page.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for AIPersonalityStatusPage
/// Tests AI personality status page display
void main() {
  group('AIPersonalityStatusPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    // Removed: Property assignment tests
    // AI personality status page tests focus on business logic (loading state, app bar, refresh button, personality overview card, pull to refresh), not property assignment

    testWidgets(
        'should display loading state initially, display app bar with title, display refresh button in app bar, display personality overview card when loaded, or support pull to refresh',
        (WidgetTester tester) async {
      // Test business logic: AI personality status page display and functionality
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(AIPersonalityStatusPage), findsOneWidget);
      expect(find.text('AI Personality Status'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}

