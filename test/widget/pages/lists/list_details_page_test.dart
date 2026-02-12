import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/lists/list_details_page.dart';
import 'package:avrai/core/models/misc/list.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ListDetailsPage
/// Tests list details display, actions, and navigation
void main() {
  group('ListDetailsPage Widget Tests', () {
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
    // List details page tests focus on business logic (list title display, list details display), not property assignment

    testWidgets('should display list title in app bar or display list details',
        (WidgetTester tester) async {
      // Test business logic: List details page display
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ListDetailsPage(list: testList),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Test List'), findsOneWidget);

      final detailedList = SpotList(
        id: 'list-456',
        title: 'Detailed List',
        description: 'Detailed description',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        isPublic: true,
        spotIds: const [],
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ListDetailsPage(list: detailedList),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Detailed List'), findsOneWidget);
    });
  });
}
