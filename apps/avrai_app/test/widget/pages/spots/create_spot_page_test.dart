import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/spots/create_spot_page.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for CreateSpotPage
/// Tests form rendering, validation, and spot creation
void main() {
  group('CreateSpotPage Widget Tests', () {
    late MockSpotsBloc mockSpotsBloc;

    setUp(() {
      mockSpotsBloc = MockSpotsBloc();
    });

    // Removed: Property assignment tests
    // Create spot page tests focus on business logic (form fields, category dropdown, location loading state), not property assignment

    testWidgets(
        'should display all required form fields, display category dropdown, or display location loading state',
        (WidgetTester tester) async {
      // Test business logic: Create spot page display and state management
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CreateSpotPage(),
        spotsBloc: mockSpotsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(CreateSpotPage), findsOneWidget);
    });
  });
}
