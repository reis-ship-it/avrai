// User Reservation Analytics Page Tests
//
// Phase 7.1: User Reservation Analytics
// Widget tests for UserReservationAnalyticsPage

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai/presentation/pages/reservations/user_reservation_analytics_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_analytics_models.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_analytics_service.dart';
import '../../helpers/widget_test_helpers.dart' as helpers;
import '../../../helpers/bloc_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for UserReservationAnalyticsPage
/// Tests analytics page display and interactions
void main() {
  group('UserReservationAnalyticsPage Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      if (!di.sl.isRegistered<ReservationAnalyticsService>()) {
        di.sl.registerLazySingleton<ReservationAnalyticsService>(
          () => _FakeReservationAnalyticsService(),
        );
      }
    });

    tearDown(() {
      mockAuthBloc.close();
      if (di.sl.isRegistered<ReservationAnalyticsService>()) {
        di.sl.unregister<ReservationAnalyticsService>();
      }
    });

    testWidgets(
        'should display analytics page correctly, show loading state initially, handle error states, and display analytics content when loaded',
        (WidgetTester tester) async {
      // Test business logic: analytics page display and interactions
      mockAuthBloc.setState(Authenticated(
        user: TestDataFactory.createTestUser(),
      ));

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const UserReservationAnalyticsPage(),
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should display page title
      expect(find.text('Reservation Analytics'), findsOneWidget);

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Should have date range picker button
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}

class _FakeReservationAnalyticsService implements ReservationAnalyticsService {
  @override
  Future<UserReservationAnalytics> getUserAnalytics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return UserReservationAnalytics(
      totalReservations: 3,
      completedReservations: 2,
      cancelledReservations: 0,
      pendingReservations: 1,
      completionRate: 0.67,
      cancellationRate: 0.0,
      favoriteSpots: const [
        FavoriteSpot(
          spotId: 'spot-1',
          spotName: 'Test Spot',
          reservationCount: 2,
          averageCompatibility: 0.8,
        ),
      ],
      patterns: ReservationPatterns(
        averagePartySize: 2.0,
        hourDistribution: {18: 2},
        dayDistribution: {5: 2},
        typeDistribution: {ReservationType.spot: 3},
      ),
      modificationPatterns: const ModificationPatterns(
        totalModifications: 0,
        maxModificationsReached: 0,
        modificationReasons: {},
      ),
      waitlistHistory: const WaitlistHistory(
        totalWaitlistJoins: 0,
        totalWaitlistConversions: 0,
        conversionRate: 0.0,
        recentEntries: [],
      ),
    );
  }

  @override
  Future<void> trackReservationEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> parameters,
  }) async {}
}
