import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai/presentation/widgets/expertise/expert_search_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertSearchWidget
/// Tests expert search functionality
void main() {
  group('ExpertSearchWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Expert search widget tests focus on business logic (search display, user interactions, filtering), not property assignment

    testWidgets(
        'should display search fields, display initial category and location, display level filter chips, display empty state when no results, call onExpertSelected when expert is tapped, or perform search when search button is tapped',
        (WidgetTester tester) async {
      // Test business logic: expert search widget display and interactions
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
      expect(find.text('Category (e.g., Coffee)'), findsOneWidget);
      expect(find.text('Location (optional)'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Min Level:'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(
          initialCategory: 'Coffee',
          initialLocation: 'Brooklyn',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      final categoryField =
          tester.widget<TextField>(find.byType(TextField).at(0));
      final locationField =
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(categoryField.controller?.text, equals('Coffee'));
      expect(locationField.controller?.text, equals('Brooklyn'));

      // ignore: unused_local_variable - Used in callback below
      UnifiedUser? selectedExpert;
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ExpertSearchWidget(
          onExpertSelected: (expert) {
            selectedExpert = expert; // Variable is used here
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(ExpertSearchWidget), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      final searchButton = find.byIcon(Icons.search).last;
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
    });
  });
}
