import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/profile/partnership_card.dart';
import 'package:avrai_core/models/user/user_partnership.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('ProfilePartnershipCard', () {
    // Removed: Property assignment tests
    // Partnership card tests focus on business logic (partnership card display, badges, user interactions), not property assignment

    testWidgets(
        'should display partnership information, display status badge, display type badge, or call onTap when tapped',
        (WidgetTester tester) async {
      // Test business logic: partnership card display and interactions
      final partnership1 = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.business,
        partnerId: 'b1',
        partnerName: 'Test Business',
        status: PartnershipStatus.active,
        eventCount: 5,
        startDate: DateTime(2024, 1, 1),
      );
      final widget1 = ProfilePartnershipCard(
        partnership: partnership1,
      );
      final testableWidget1 = WidgetTestHelpers.createTestableWidget(
        child: widget1,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget1);
      await tester.pumpAndSettle();
      expect(find.text('Test Business'), findsOneWidget);
      expect(find.text('5 events'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      const partnership2 = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.brand,
        partnerId: 'br1',
        partnerName: 'Test Brand',
        status: PartnershipStatus.active,
      );
      const widget2 = ProfilePartnershipCard(
        partnership: partnership2,
      );
      final testableWidget2 = WidgetTestHelpers.createTestableWidget(
        child: widget2,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget2);
      await tester.pumpAndSettle();
      expect(find.text('Brand Partnership'), findsOneWidget);

      var tapped = false;
      const partnership3 = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.business,
        partnerId: 'b1',
        partnerName: 'Test Business',
        status: PartnershipStatus.active,
      );
      final widget3 = ProfilePartnershipCard(
        partnership: partnership3,
        onTap: () {
          tapped = true;
        },
      );
      final testableWidget3 = WidgetTestHelpers.createTestableWidget(
        child: widget3,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget3);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfilePartnershipCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
