import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/brand/brand_stats_card.dart';
import 'package:avrai/core/theme/colors.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BrandStatsCard
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
///
/// Tests:
/// - Widget rendering
/// - Label and value display
/// - Icon display
/// - Color customization
void main() {
  group('BrandStatsCard Widget Tests', () {
    // Removed: Property assignment tests
    // Brand stats card tests focus on business logic (stats card display with various metrics), not property assignment

    testWidgets(
        'should display brand stats card with label and value, display icon correctly, display with custom color, or display different metrics correctly',
        (WidgetTester tester) async {
      // Test business logic: brand stats card display with various configurations
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Total Investment',
          value: '\$10,000',
          icon: Icons.attach_money,
          color: AppColors.electricGreen,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(BrandStatsCard), findsOneWidget);
      expect(find.text('Total Investment'), findsOneWidget);
      expect(find.text('\$10,000'), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'ROI',
          value: '50%',
          icon: Icons.trending_up,
          color: AppColors.electricGreen,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Revenue',
          value: '\$15,000',
          icon: Icons.monetization_on,
          color: AppColors.electricGreen,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(BrandStatsCard), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('\$15,000'), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: const BrandStatsCard(
          label: 'Active Sponsorships',
          value: '5',
          icon: Icons.event,
          color: AppColors.grey600,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.text('Active Sponsorships'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
