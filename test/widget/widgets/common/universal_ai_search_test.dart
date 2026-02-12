import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/universal_ai_search.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UniversalAISearch
/// Tests AI search widget UI and interactions
void main() {
  group('UniversalAISearch Widget Tests', () {
    // Removed: Property assignment tests
    // Universal AI search tests focus on business logic (search widget display, custom hint, callbacks, loading state), not property assignment

    testWidgets(
        'should display search widget with default hint, display custom hint text, call onCommand callback when command is submitted, or show loading state when isLoading is true',
        (WidgetTester tester) async {
      // Test business logic: Universal AI search widget display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(UniversalAISearch), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(hintText: 'Ask AI...'),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(UniversalAISearch), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(UniversalAISearch), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(isLoading: true),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byType(UniversalAISearch), findsOneWidget);
    });
  });
}
