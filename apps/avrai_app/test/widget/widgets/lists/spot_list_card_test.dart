import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/lists/spot_list_card.dart';
import 'package:avrai_core/models/misc/list.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for SpotListCard
/// Tests list card display and interactions
void main() {
  group('SpotListCard Widget Tests', () {
    // Removed: Property assignment tests
    // Spot list card tests focus on business logic (list card display, user interactions), not property assignment

    testWidgets(
        'should display list information correctly (title, description, spot count), display category when available, call onTap callback when tapped, or display custom trailing widget',
        (WidgetTester tester) async {
      // Test business logic: list card display and interactions
      final testList1 = SpotList(
        id: 'list-123',
        title: 'Test List',
        description: 'Test description',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        spotIds: const ['spot-1', 'spot-2'],
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SpotListCard(list: testList1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Test List'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('2 spots'), findsOneWidget);

      final testList2 = SpotList(
        id: 'list-124',
        title: 'Test List 2',
        description: 'Test description 2',
        category: 'Food & Dining',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        spotIds: const [],
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: SpotListCard(list: testList2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Food & Dining'), findsOneWidget);

      bool wasTapped = false;
      final testList3 = SpotList(
        id: 'list-125',
        title: 'Test List 3',
        description: 'Test description 3',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        spotIds: const [],
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: SpotListCard(
          list: testList3,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      await tester.tap(find.byType(SpotListCard));
      await tester.pump();
      expect(wasTapped, isTrue);

      final testList4 = SpotList(
        id: 'list-126',
        title: 'Test List 4',
        description: 'Test description 4',
        spots: const [],
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        spotIds: const [],
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: SpotListCard(
          list: testList4,
          trailing: const Icon(Icons.more_vert),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}
