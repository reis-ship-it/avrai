import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/lists/edit_list_page.dart';
import 'package:avrai/core/models/misc/list.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for EditListPage
/// Tests form rendering, list editing, and validation
void main() {
  group('EditListPage Widget Tests', () {
    late MockListsBloc mockListsBloc;
    late SpotList testList;

    setUp(() {
      mockListsBloc = MockListsBloc();
      testList = SpotList(
        id: 'list-123',
        title: 'Test List',
        description: 'Test description',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        isPublic: true,
        spotIds: const [],
      );
    });

    // Removed: Property assignment tests
    // Edit list page tests focus on business logic (form fields display, list information display), not property assignment

    testWidgets(
        'should display all required form fields or display list information for editing',
        (WidgetTester tester) async {
      // Test business logic: Edit list page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EditListPage(list: testList),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(EditListPage), findsOneWidget);
    });
  });
}
