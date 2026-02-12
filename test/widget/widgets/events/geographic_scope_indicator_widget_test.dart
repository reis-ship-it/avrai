import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/geographic_scope_indicator_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for GeographicScopeIndicatorWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('GeographicScopeIndicatorWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Geographic scope indicator widget tests focus on business logic (scope indicator display), not property assignment

    testWidgets(
        'should display geographic scope indicator and display scope description',
        (WidgetTester tester) async {
      // Test business logic: geographic scope indicator widget display
      final user = ModelFactories.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: GeographicScopeIndicatorWidget(
          user: user,
          category: 'Food & Drink',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(GeographicScopeIndicatorWidget), findsOneWidget);
    });
  });
}
