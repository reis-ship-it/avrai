import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/profile/partnership_display_widget.dart';
import 'package:avrai_core/models/user/user_partnership.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('PartnershipDisplayWidget', () {
    // Removed: Property assignment tests
    // Partnership display widget tests focus on business logic (partnership display, filtering, user interactions), not property assignment

    testWidgets(
        'should display empty state when no partnerships, display partnerships list, show view all link when partnerships exceed max count, or filter partnerships by type',
        (WidgetTester tester) async {
      // Test business logic: partnership display widget display and interactions
      const widget1 = PartnershipDisplayWidget(
        partnerships: [],
      );
      final testableWidget1 = WidgetTestHelpers.createTestableWidget(
        child: widget1,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget1);
      await tester.pumpAndSettle();
      expect(find.text('No partnerships yet'), findsOneWidget);

      final partnerships1 = [
        const UserPartnership(
          id: '1',
          type: ProfilePartnershipType.business,
          partnerId: 'b1',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
          eventCount: 5,
        ),
      ];
      final widget2 = PartnershipDisplayWidget(
        partnerships: partnerships1,
      );
      final testableWidget2 = WidgetTestHelpers.createTestableWidget(
        child: widget2,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget2);
      await tester.pumpAndSettle();
      expect(find.text('Partnerships'), findsOneWidget);
      expect(find.text('Test Business'), findsOneWidget);

      final partnerships2 = List.generate(
          5,
          (i) => UserPartnership(
                id: '$i',
                type: ProfilePartnershipType.business,
                partnerId: 'b$i',
                partnerName: 'Business $i',
                status: PartnershipStatus.active,
              ));
      final widget3 = PartnershipDisplayWidget(
        partnerships: partnerships2,
        maxDisplayCount: 3,
        onViewAllTap: (_) {},
      );
      final testableWidget3 = WidgetTestHelpers.createTestableWidget(
        child: widget3,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget3);
      await tester.pumpAndSettle();
      expect(find.textContaining('View All'), findsOneWidget);

      final partnerships3 = [
        const UserPartnership(
          id: '1',
          type: ProfilePartnershipType.business,
          partnerId: 'b1',
          partnerName: 'Business',
          status: PartnershipStatus.active,
        ),
        const UserPartnership(
          id: '2',
          type: ProfilePartnershipType.brand,
          partnerId: 'br1',
          partnerName: 'Brand',
          status: PartnershipStatus.active,
        ),
      ];
      final widget4 = PartnershipDisplayWidget(
        partnerships: partnerships3,
        showFilters: true,
      );
      final testableWidget4 = WidgetTestHelpers.createTestableWidget(
        child: widget4,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget4);
      await tester.pumpAndSettle();
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });
  });
}
