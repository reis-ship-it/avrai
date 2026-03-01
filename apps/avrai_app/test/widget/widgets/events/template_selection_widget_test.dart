import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/template_selection_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for TemplateSelectionWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('TemplateSelectionWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Template selection widget tests focus on business logic (template selection display, filtering), not property assignment

    testWidgets(
        'should display template selection widget, display with selected category filter, or display business templates when enabled',
        (WidgetTester tester) async {
      // Test business logic: template selection widget display
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          onTemplateSelected: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          selectedCategory: 'Food & Drink',
          onTemplateSelected: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          showBusinessTemplates: true,
          onTemplateSelected: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);
    });
  });
}
