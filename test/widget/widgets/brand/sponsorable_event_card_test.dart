import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/brand/sponsorable_event_card.dart';
import 'package:avrai/core/models/business/brand_discovery.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for SponsorableEventCard
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SponsorableEventCard Widget Tests', () {
    // Removed: Property assignment tests
    // Sponsorable event card tests focus on business logic (card display, user interactions), not property assignment

    testWidgets(
        'should display sponsorable event card, display recommended badge when meets threshold, or call onTap callback when card is tapped',
        (WidgetTester tester) async {
      // Test business logic: sponsorable event card display and interactions
      const brandMatch1 = BrandMatch(
        brandId: 'brand-123',
        brandName: 'Test Brand',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
          'eventDate': '2025-12-15',
        },
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const SponsorableEventCard(brandMatch: brandMatch1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(SponsorableEventCard), findsOneWidget);

      const brandMatch2 = BrandMatch(
        brandId: 'brand-124',
        brandName: 'Test Brand 2',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
        },
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const SponsorableEventCard(brandMatch: brandMatch2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Recommended'), findsOneWidget);

      bool wasTapped = false;
      const brandMatch3 = BrandMatch(
        brandId: 'brand-125',
        brandName: 'Test Brand 3',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85,
          valueAlignment: 85.0,
          styleCompatibility: 85.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
        matchReasons: ['High compatibility'],
        metadata: {
          'eventTitle': 'Community Coffee Meetup',
        },
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: SponsorableEventCard(
          brandMatch: brandMatch3,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      await tester.tap(find.byType(SponsorableEventCard));
      await tester.pump();
      expect(wasTapped, isTrue);
    });
  });
}
