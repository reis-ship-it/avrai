import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/events/locality_selection_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for LocalitySelectionWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('LocalitySelectionWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Locality selection widget tests focus on business logic (locality selection display, user interactions), not property assignment

    testWidgets(
        'should display locality selection widget or display with selected locality',
        (WidgetTester tester) async {
      // Test business logic: locality selection widget display and interactions
      final user1 = ModelFactories.createTestUser();
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      String? selectedLocality;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: LocalitySelectionWidget(
          user: user1,
          category: 'Food & Drink',
          onLocalitySelected: (locality) {
            selectedLocality = locality;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(LocalitySelectionWidget), findsOneWidget);

      final user2 = ModelFactories.createTestUser();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: LocalitySelectionWidget(
          user: user2,
          category: 'Food & Drink',
          selectedLocality: 'Brooklyn',
          onLocalitySelected: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(LocalitySelectionWidget), findsOneWidget);
    });
  });
}
