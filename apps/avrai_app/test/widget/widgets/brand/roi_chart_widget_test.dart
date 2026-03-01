import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/brand/roi_chart_widget.dart';
import 'package:avrai/presentation/pages/brand/brand_analytics_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ROICartWidget
///
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('ROICartWidget Widget Tests', () {
    // Removed: Property assignment tests
    // ROI chart widget tests focus on business logic (ROI chart display), not property assignment

    testWidgets('should display ROI chart widget and display ROI percentage',
        (WidgetTester tester) async {
      // Test business logic: ROI chart display
      const analytics = BrandAnalytics(
        totalInvestment: 10000.0,
        cashInvestment: 5000.0,
        productInvestment: 5000.0,
        totalReturns: 15000.0,
        directRevenue: 12000.0,
        estimatedBrandValue: 3000.0,
        roiPercentage: 50.0,
        topPerformingEvents: [],
        exposureMetrics: BrandExposureMetrics(
          totalReach: 5000,
          totalImpressions: 10000,
          productSampling: 200,
          emailSignups: 150,
          websiteVisits: 300,
        ),
        performanceMetrics: PerformanceMetrics(
          totalEvents: 10,
          activeSponsorships: 5,
          averageROI: 50.0,
          totalBrandValue: 3000.0,
        ),
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ROICartWidget(analytics: analytics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(ROICartWidget), findsOneWidget);
      expect(find.text('ROI Trend'), findsOneWidget);
      expect(find.textContaining('50% ROI'), findsOneWidget);
    });
  });
}
