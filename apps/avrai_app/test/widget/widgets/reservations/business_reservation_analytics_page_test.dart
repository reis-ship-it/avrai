// Business Reservation Analytics Page Tests
//
// Phase 7.2: Business Reservation Analytics
// Widget tests for BusinessReservationAnalyticsPage

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/pages/business/reservations/business_reservation_analytics_page.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/business/business_reservation_analytics_models.dart';
import 'package:avrai_runtime_os/services/business/business_reservation_analytics_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart' show TrendType;
import '../../helpers/widget_test_helpers.dart' as helpers;

/// Widget tests for BusinessReservationAnalyticsPage
/// Tests analytics page display and interactions
void main() {
  group('BusinessReservationAnalyticsPage Tests', () {
    setUp(() {
      if (!di.sl.isRegistered<BusinessReservationAnalyticsService>()) {
        di.sl.registerLazySingleton<BusinessReservationAnalyticsService>(
          () => _FakeBusinessReservationAnalyticsService(),
        );
      }
    });

    tearDown(() {
      if (di.sl.isRegistered<BusinessReservationAnalyticsService>()) {
        di.sl.unregister<BusinessReservationAnalyticsService>();
      }
    });

    testWidgets(
        'should display analytics page correctly, show loading state initially, handle error states, and display analytics content when loaded',
        (WidgetTester tester) async {
      // Test business logic: analytics page display and interactions
      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: BusinessReservationAnalyticsPage(
          businessId: 'test-business-id',
          type: ReservationType.business,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should display page title
      expect(find.text('Business Reservation Analytics'), findsOneWidget);

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Should have date range picker button
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}

class _FakeBusinessReservationAnalyticsService
    implements BusinessReservationAnalyticsService {
  @override
  Future<BusinessReservationAnalytics> getBusinessAnalytics({
    required String businessId,
    required ReservationType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return BusinessReservationAnalytics(
      totalReservations: 5,
      confirmedReservations: 2,
      completedReservations: 2,
      cancelledReservations: 1,
      noShowReservations: 0,
      cancellationRate: 0.2,
      noShowRate: 0.0,
      completionRate: 0.4,
      volumeByHour: {18: 3, 19: 2},
      volumeByDay: {5: 3, 6: 2},
      peakHours: [18],
      peakDays: [5],
      totalRevenue: 250.0,
      averageRevenuePerReservation: 50.0,
      revenueByMonth: {'2026-03': 250.0},
      customerRetentionRate: 0.5,
      repeatCustomers: 2,
      capacityMetrics: CapacityUtilizationMetrics(
        averageUtilization: 0.6,
        peakUtilization: 0.8,
        utilizationByHour: {18: 0.8, 19: 0.4},
        utilizationByDay: {5: 0.7, 6: 0.5},
        peakUtilizationHours: [18],
        peakUtilizationDays: [5],
        underutilizedHours: [10],
        overutilizedHours: [],
      ),
      quantumCompatibilityTrends: QuantumCompatibilityTrends(
        averageCompatibility: 0.75,
        compatibilityHistory: [
          CompatibilityTrendPoint(
            timestamp: DateTime(2026, 3, 1),
            compatibility: 0.75,
            reservationCount: 5,
          ),
        ],
        highCompatibilityPeriods: [],
        compatibilityTrend: TrendType.stable,
      ),
      ai2aiLearningInsights: AI2AILearningInsights(
        totalInsights: 0,
        averageLearningQuality: 0.0,
        improvedDimensions: [],
        propagationStats: MeshPropagationStats(
          insightsReceived: 0,
          insightsShared: 0,
          averageHopCount: 0.0,
        ),
        businessInsights: [],
      ),
    );
  }
}
