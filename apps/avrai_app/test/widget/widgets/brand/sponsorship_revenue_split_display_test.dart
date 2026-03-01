import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/brand/sponsorship_revenue_split_display.dart';
import 'package:avrai_core/models/payment/revenue_split.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for SponsorshipRevenueSplitDisplay
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SponsorshipRevenueSplitDisplay Widget Tests', () {
    // Removed: Property assignment tests
    // Sponsorship revenue split display tests focus on business logic (revenue split display with sponsorship), not property assignment

    testWidgets(
        'should display revenue split with sponsorship, display total revenue, or display sponsorship contribution',
        (WidgetTester tester) async {
      // Test business logic: revenue split display with sponsorship
      final revenueSplit = RevenueSplit(
        id: 'split-123',
        eventId: 'event-456',
        totalAmount: 1000.0,
        platformFee: 100.0,
        processingFee: 30.0,
        hostPayout: 870.0,
        parties: const [],
        isLocked: false,
        calculatedAt: DateTime.now(),
        ticketsSold: 20,
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: SponsorshipRevenueSplitDisplay(
          split: revenueSplit,
          sponsorshipContribution: 200.0,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(SponsorshipRevenueSplitDisplay), findsOneWidget);
      expect(find.text('Revenue Breakdown (with Sponsorship)'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
    });
  });
}
