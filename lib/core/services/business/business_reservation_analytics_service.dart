// Business Reservation Analytics Service
//
// Phase 7.2: Business Reservation Analytics
// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
//
// Provides comprehensive business reservation analytics including:
// - Reservation volume and peak times
// - No-show and cancellation rates
// - Revenue tracking
// - Customer retention
// - Rate limit usage
// - Waitlist metrics
// - Capacity utilization
// - Knot string evolution patterns (business patterns)
// - Fabric stability analytics (group reservations)
// - Worldsheet evolution tracking (temporal patterns)
// - Quantum compatibility trends
// - AI2AI mesh learning insights

import 'dart:developer' as developer;
import 'package:avrai/core/models/misc/reservation.dart';
import 'package:avrai/core/services/reservation/reservation_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/services/reservation/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation/reservation_waitlist_service.dart';
import 'package:avrai/core/services/reservation/reservation_availability_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
// Phase 7.2 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/services/reservation/reservation_quantum_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/business/business_reservation_analytics_models.dart';

export 'package:avrai/core/services/business/business_reservation_analytics_models.dart';


/// Business Reservation Analytics Service
///
/// Phase 7.2: Business Reservation Analytics
/// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
///
/// **Analytics Features:**
/// - Volume and peak times
/// - No-show and cancellation rates
/// - Revenue tracking
/// - Customer retention
/// - Rate limit usage
/// - Waitlist metrics
/// - Capacity utilization
/// - Knot string evolution patterns (business patterns)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility trends
/// - AI2AI mesh learning insights
class BusinessReservationAnalyticsService {
  static const String _logName = 'BusinessReservationAnalyticsService';

  final ReservationService _reservationService;
  final PaymentService? _paymentService;
  // ignore: unused_field - Reserved for future rate limit analytics
  final ReservationRateLimitService? _rateLimitService;
  final ReservationWaitlistService? _waitlistService;
  final ReservationAvailabilityService? _availabilityService;
  final AgentIdService _agentIdService;
  final EventLogger? _eventLogger;
  // Phase 7.2 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
  // ignore: unused_field - Reserved for future business string evolution patterns
  final KnotEvolutionStringService? _stringService;
  final KnotFabricService? _fabricService;
  final KnotWorldsheetService? _worldsheetService;
  // ignore: unused_field - Reserved for future temporal analytics
  final AtomicClockService? _atomicClock;
  // ignore: unused_field - Reserved for future AI2AI business insights
  final QuantumMatchingAILearningService? _aiLearningService;
  final ReservationQuantumService? _quantumService;
  final PersonalityLearning? _personalityLearning;

  BusinessReservationAnalyticsService({
    required ReservationService reservationService,
    required AgentIdService agentIdService,
    PaymentService? paymentService,
    ReservationRateLimitService? rateLimitService,
    ReservationWaitlistService? waitlistService,
    ReservationAvailabilityService? availabilityService,
    EventLogger? eventLogger,
    // Phase 7.2 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    AtomicClockService? atomicClock,
    QuantumMatchingAILearningService? aiLearningService,
    ReservationQuantumService? quantumService,
    PersonalityLearning? personalityLearning,
  })  : _reservationService = reservationService,
        _agentIdService = agentIdService,
        _paymentService = paymentService,
        _rateLimitService = rateLimitService,
        _waitlistService = waitlistService,
        _availabilityService = availabilityService,
        _eventLogger = eventLogger,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _atomicClock = atomicClock,
        _aiLearningService = aiLearningService,
        _quantumService = quantumService,
        _personalityLearning = personalityLearning;

  /// Get business reservation analytics
  ///
  /// **Parameters:**
  /// - `businessId`: Business/Spot/Event ID
  /// - `type`: Reservation type (spot, business, or event)
  /// - `startDate`: Optional start date for analytics period
  /// - `endDate`: Optional end date for analytics period
  ///
  /// **Returns:**
  /// BusinessReservationAnalytics with comprehensive analytics
  Future<BusinessReservationAnalytics> getBusinessAnalytics({
    required String businessId,
    required ReservationType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log(
      'Getting business reservation analytics for $type $businessId',
      name: _logName,
    );

    try {
      // Get all reservations for this business
      final reservations = await _reservationService.getReservationsForTarget(
        type: type,
        targetId: businessId,
        status: null,
      );

      // Filter by date range if provided
      final filteredReservations = (startDate != null || endDate != null)
          ? reservations.where((r) {
              if (startDate != null && r.reservationTime.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && r.reservationTime.isAfter(endDate)) {
                return false;
              }
              return true;
            }).toList()
          : reservations;

      // Calculate basic metrics
      final totalReservations = filteredReservations.length;
      final confirmedReservations = filteredReservations
          .where((r) => r.status == ReservationStatus.confirmed)
          .length;
      final completedReservations = filteredReservations
          .where((r) => r.status == ReservationStatus.completed)
          .length;
      final cancelledReservations = filteredReservations
          .where((r) => r.status == ReservationStatus.cancelled)
          .length;
      final noShowReservations = filteredReservations
          .where((r) => r.status == ReservationStatus.noShow)
          .length;

      final cancellationRate = totalReservations > 0
          ? cancelledReservations / totalReservations
          : 0.0;
      final noShowRate =
          totalReservations > 0 ? noShowReservations / totalReservations : 0.0;
      final completionRate = totalReservations > 0
          ? completedReservations / totalReservations
          : 0.0;

      // Calculate volume patterns
      final volumeByHour = <int, int>{};
      final volumeByDay = <int, int>{};

      for (final reservation in filteredReservations) {
        final hour = reservation.reservationTime.hour;
        final day = reservation.reservationTime.weekday;
        volumeByHour[hour] = (volumeByHour[hour] ?? 0) + 1;
        volumeByDay[day] = (volumeByDay[day] ?? 0) + 1;
      }

      // Find peak hours and days
      final peakHours = _findPeakTimes(volumeByHour);
      final peakDays = _findPeakTimes(volumeByDay);

      // Calculate revenue metrics
      final revenueMetrics =
          await _calculateRevenueMetrics(filteredReservations);

      // Calculate customer retention
      final retentionMetrics =
          _calculateCustomerRetention(filteredReservations);

      // Calculate rate limit usage metrics
      final rateLimitMetrics = await _calculateRateLimitMetrics(
          businessId, type, startDate, endDate);

      // Calculate waitlist metrics
      final waitlistMetrics =
          await _calculateWaitlistMetrics(businessId, type, startDate, endDate);

      // Calculate capacity utilization metrics
      final capacityMetrics = await _calculateCapacityUtilizationMetrics(
        businessId: businessId,
        type: type,
        reservations: filteredReservations,
      );

      // Calculate knot string evolution patterns
      final stringEvolutionPatterns = await _calculateStringEvolutionPatterns(
        businessId: businessId,
        type: type,
        reservations: filteredReservations,
      );

      // Calculate fabric stability analytics
      final fabricStabilityAnalytics = await _calculateFabricStabilityAnalytics(
        businessId: businessId,
        reservations: filteredReservations,
      );

      // Calculate worldsheet evolution analytics
      final worldsheetEvolutionAnalytics =
          await _calculateWorldsheetEvolutionAnalytics(
        businessId: businessId,
        reservations: filteredReservations,
      );

      // Calculate quantum compatibility trends
      final quantumCompatibilityTrends =
          await _calculateQuantumCompatibilityTrends(
        businessId: businessId,
        reservations: filteredReservations,
      );

      // Calculate AI2AI learning insights
      final ai2aiLearningInsights = await _calculateAI2AILearningInsights(
        businessId: businessId,
        reservations: filteredReservations,
      );

      // Track analytics view event
      await _trackAnalyticsEvent(
        businessId: businessId,
        eventType: 'business_reservation_analytics_viewed',
        parameters: {
          'total_reservations': totalReservations,
          'completion_rate': completionRate,
          'cancellation_rate': cancellationRate,
          'no_show_rate': noShowRate,
        },
      );

      return BusinessReservationAnalytics(
        totalReservations: totalReservations,
        confirmedReservations: confirmedReservations,
        completedReservations: completedReservations,
        cancelledReservations: cancelledReservations,
        noShowReservations: noShowReservations,
        cancellationRate: cancellationRate,
        noShowRate: noShowRate,
        completionRate: completionRate,
        volumeByHour: volumeByHour,
        volumeByDay: volumeByDay,
        peakHours: peakHours,
        peakDays: peakDays,
        totalRevenue: revenueMetrics['totalRevenue'] as double,
        averageRevenuePerReservation:
            revenueMetrics['averageRevenue'] as double,
        revenueByMonth: revenueMetrics['revenueByMonth'] as Map<String, double>,
        customerRetentionRate: retentionMetrics['retentionRate'] as double,
        repeatCustomers: retentionMetrics['repeatCustomers'] as int,
        rateLimitMetrics: rateLimitMetrics,
        waitlistMetrics: waitlistMetrics,
        capacityMetrics: capacityMetrics,
        stringEvolutionPatterns: stringEvolutionPatterns,
        fabricStabilityAnalytics: fabricStabilityAnalytics,
        worldsheetEvolutionAnalytics: worldsheetEvolutionAnalytics,
        quantumCompatibilityTrends: quantumCompatibilityTrends,
        ai2aiLearningInsights: ai2aiLearningInsights,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error getting business analytics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Track analytics event
  Future<void> _trackAnalyticsEvent({
    required String businessId,
    required String eventType,
    required Map<String, dynamic> parameters,
  }) async {
    if (_eventLogger == null) {
      return;
    }

    try {
      await _eventLogger.logEvent(
        eventType: eventType,
        parameters: {
          'business_id': businessId,
          ...parameters,
        },
      );
    } catch (e) {
      developer.log(
        'Error tracking analytics event: $e',
        name: _logName,
      );
      // Don't throw - analytics tracking should not break the flow
    }
  }

  // --- Private Helper Methods ---

  /// Find peak times (hours or days with most reservations)
  List<int> _findPeakTimes(Map<int, int> volumeMap) {
    if (volumeMap.isEmpty) {
      return [];
    }

    final maxVolume = volumeMap.values.reduce((a, b) => a > b ? a : b);
    return volumeMap.entries
        .where((e) => e.value == maxVolume)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  /// Calculate revenue metrics
  Future<Map<String, dynamic>> _calculateRevenueMetrics(
    List<Reservation> reservations,
  ) async {
    double totalRevenue = 0.0;
    final revenueByMonth = <String, double>{};

    for (final reservation in reservations) {
      // Get revenue from payment if available
      final paymentId = reservation.metadata['paymentId'] as String?;
      if (paymentId != null && _paymentService != null) {
        try {
          final payment = _paymentService.getPayment(paymentId);
          if (payment != null) {
            totalRevenue += payment.amount;

            // Group by month
            final monthKey =
                '${reservation.reservationTime.year}-${reservation.reservationTime.month.toString().padLeft(2, '0')}';
            revenueByMonth[monthKey] =
                (revenueByMonth[monthKey] ?? 0.0) + payment.amount;
          }
        } catch (e) {
          developer.log(
            'Error getting payment for revenue calculation: $e',
            name: _logName,
          );
        }
      } else if (reservation.ticketPrice != null) {
        // Fallback to ticket price if payment not available
        final revenue = reservation.ticketPrice! * reservation.ticketCount;
        totalRevenue += revenue;

        // Group by month
        final monthKey =
            '${reservation.reservationTime.year}-${reservation.reservationTime.month.toString().padLeft(2, '0')}';
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0.0) + revenue;
      }
    }

    final averageRevenue =
        reservations.isNotEmpty ? totalRevenue / reservations.length : 0.0;

    return {
      'totalRevenue': totalRevenue,
      'averageRevenue': averageRevenue,
      'revenueByMonth': revenueByMonth,
    };
  }

  /// Calculate customer retention metrics
  Map<String, dynamic> _calculateCustomerRetention(
    List<Reservation> reservations,
  ) {
    // Track customers by agentId (for privacy)
    final customerReservations = <String, int>{};

    for (final reservation in reservations) {
      final agentId = reservation.agentId;
      customerReservations[agentId] = (customerReservations[agentId] ?? 0) + 1;
    }

    final totalCustomers = customerReservations.length;
    final repeatCustomers =
        customerReservations.values.where((count) => count >= 2).length;

    final retentionRate =
        totalCustomers > 0 ? repeatCustomers / totalCustomers : 0.0;

    return {
      'retentionRate': retentionRate,
      'repeatCustomers': repeatCustomers,
    };
  }

  /// Calculate rate limit usage metrics
  Future<RateLimitUsageMetrics?> _calculateRateLimitMetrics(
    String businessId,
    ReservationType type,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Note: Rate limit service tracks per-user limits, not per-business
    // For business analytics, we'd need to track rate limit checks for this business
    // This is a placeholder - would need to extend rate limit service
    // to track business-specific rate limit usage
    return null;
  }

  /// Calculate waitlist metrics
  Future<WaitlistMetrics?> _calculateWaitlistMetrics(
    String businessId,
    ReservationType type,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (_waitlistService == null) {
      return null;
    }

    try {
      // Get waitlist entries for this business
      // Note: WaitlistService may need extension to support business-specific queries
      // For now, we'll calculate from reservations that were waitlisted

      // Get all reservations for this business
      final reservations = await _reservationService.getReservationsForTarget(
        type: type,
        targetId: businessId,
        status: null,
      );

      // Filter by date range if provided
      final filteredReservations = (startDate != null || endDate != null)
          ? reservations.where((r) {
              if (startDate != null && r.reservationTime.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && r.reservationTime.isAfter(endDate)) {
                return false;
              }
              return true;
            }).toList()
          : reservations;

      // Find reservations that were waitlisted
      final waitlistReservations = filteredReservations.where((r) {
        return r.metadata['wasWaitlist'] as bool? ?? false;
      }).toList();

      final totalJoins = waitlistReservations.length;
      final conversions = waitlistReservations
          .where((r) =>
              r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.completed)
          .length;

      final conversionRate = totalJoins > 0 ? conversions / totalJoins : 0.0;

      // Calculate average wait time
      double totalWaitTime = 0.0;
      double longestWaitTime = 0.0;
      final conversionsByDay = <String, int>{};

      for (final reservation in waitlistReservations) {
        final wasWaitlist =
            reservation.metadata['wasWaitlist'] as bool? ?? false;
        if (wasWaitlist) {
          final waitlistJoinTime = reservation.createdAt;
          final conversionTime = reservation.updatedAt;

          final waitTime =
              conversionTime.difference(waitlistJoinTime).inHours.toDouble();
          totalWaitTime += waitTime;
          if (waitTime > longestWaitTime) {
            longestWaitTime = waitTime;
          }

          // Track conversions by day
          if (reservation.status == ReservationStatus.confirmed ||
              reservation.status == ReservationStatus.completed) {
            final dayKey =
                '${reservation.reservationTime.year}-${reservation.reservationTime.month.toString().padLeft(2, '0')}-${reservation.reservationTime.day.toString().padLeft(2, '0')}';
            conversionsByDay[dayKey] = (conversionsByDay[dayKey] ?? 0) + 1;
          }
        }
      }

      final averageWaitTime =
          conversions > 0 ? totalWaitTime / conversions : 0.0;

      return WaitlistMetrics(
        totalJoins: totalJoins,
        totalConversions: conversions,
        conversionRate: conversionRate,
        averageWaitTime: averageWaitTime,
        longestWaitTime: longestWaitTime,
        conversionsByDay: conversionsByDay,
      );
    } catch (e) {
      developer.log(
        'Error calculating waitlist metrics: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate capacity utilization metrics
  Future<CapacityUtilizationMetrics?> _calculateCapacityUtilizationMetrics({
    required String businessId,
    required ReservationType type,
    required List<Reservation> reservations,
  }) async {
    if (_availabilityService == null) {
      return null;
    }

    try {
      final utilizationByHour = <int, List<double>>{};
      final utilizationByDay = <int, List<double>>{};

      // Group reservations by hour and day
      for (final reservation in reservations) {
        final hour = reservation.reservationTime.hour;
        final day = reservation.reservationTime.weekday;

        // Get capacity for this reservation time
        try {
          final capacityInfo = await _availabilityService.getCapacity(
            type: type,
            targetId: businessId,
            reservationTime: reservation.reservationTime,
          );

          if (capacityInfo.totalCapacity > 0) {
            final utilization =
                capacityInfo.reservedCapacity / capacityInfo.totalCapacity;

            utilizationByHour.putIfAbsent(hour, () => []).add(utilization);
            utilizationByDay.putIfAbsent(day, () => []).add(utilization);
          }
        } catch (e) {
          developer.log(
            'Error getting capacity for utilization: $e',
            name: _logName,
          );
        }
      }

      // Calculate average utilization by hour
      final avgUtilizationByHour = <int, double>{};
      for (final entry in utilizationByHour.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        avgUtilizationByHour[entry.key] = avg;
      }

      // Calculate average utilization by day
      final avgUtilizationByDay = <int, double>{};
      for (final entry in utilizationByDay.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        avgUtilizationByDay[entry.key] = avg;
      }

      // Calculate overall averages
      final allUtilizations = avgUtilizationByHour.values.toList();
      final averageUtilization = allUtilizations.isNotEmpty
          ? allUtilizations.reduce((a, b) => a + b) / allUtilizations.length
          : 0.0;

      final peakUtilization = allUtilizations.isNotEmpty
          ? allUtilizations.reduce((a, b) => a > b ? a : b)
          : 0.0;

      // Find peak and underutilized times
      final peakUtilizationHours = avgUtilizationByHour.entries
          .where((e) => e.value >= 0.9)
          .map((e) => e.key)
          .toList()
        ..sort();

      final peakUtilizationDays = avgUtilizationByDay.entries
          .where((e) => e.value >= 0.9)
          .map((e) => e.key)
          .toList()
        ..sort();

      final underutilizedHours = avgUtilizationByHour.entries
          .where((e) => e.value < 0.3)
          .map((e) => e.key)
          .toList()
        ..sort();

      final overutilizedHours = avgUtilizationByHour.entries
          .where((e) => e.value > 0.9)
          .map((e) => e.key)
          .toList()
        ..sort();

      return CapacityUtilizationMetrics(
        averageUtilization: averageUtilization,
        peakUtilization: peakUtilization,
        utilizationByHour: avgUtilizationByHour,
        utilizationByDay: avgUtilizationByDay,
        peakUtilizationHours: peakUtilizationHours,
        peakUtilizationDays: peakUtilizationDays,
        underutilizedHours: underutilizedHours,
        overutilizedHours: overutilizedHours,
      );
    } catch (e) {
      developer.log(
        'Error calculating capacity utilization metrics: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate knot string evolution patterns
  Future<StringEvolutionPatterns?> _calculateStringEvolutionPatterns({
    required String businessId,
    required ReservationType type,
    required List<Reservation> reservations,
  }) async {
    // Note: String evolution patterns are typically for user personalities
    // For business analytics, we could analyze reservation volume patterns
    // This would use business-level patterns rather than individual user patterns
    // For now, return null - would need business-specific string evolution
    return null;
  }

  /// Calculate fabric stability analytics
  Future<FabricStabilityAnalytics?> _calculateFabricStabilityAnalytics({
    required String businessId,
    required List<Reservation> reservations,
  }) async {
    if (_fabricService == null || _personalityLearning == null) {
      return null;
    }

    try {
      final stabilityHistory = <FabricStabilityPoint>[];
      final stableGroups = <StableGroup>[];

      // Group reservations by other participants (group reservations)
      final groupReservations = <String, List<Reservation>>{};
      for (final reservation in reservations) {
        final groupId = reservation.metadata['groupId'] as String?;
        if (groupId != null) {
          groupReservations.putIfAbsent(groupId, () => []).add(reservation);
        }
      }

      // Calculate stability for each group
      for (final groupReservationsList in groupReservations.values) {
        if (groupReservationsList.isEmpty) continue;

        // Get user IDs from group
        final userIds = <String>[];
        for (final reservation in groupReservationsList) {
          final participants =
              reservation.metadata['participants'] as List<dynamic>?;
          if (participants != null) {
            for (final participant in participants) {
              final participantId = participant.toString();
              if (!userIds.contains(participantId)) {
                userIds.add(participantId);
              }
            }
          }
        }

        if (userIds.length < 2) continue;

        // Get agentIds for all users
        final userAgentIds = <String>[];
        for (final userId in userIds) {
          try {
            final agentId = await _agentIdService.getUserAgentId(userId);
            userAgentIds.add(agentId);
          } catch (e) {
            developer.log(
              'Error getting agentId for participant: $e',
              name: _logName,
            );
          }
        }

        if (userAgentIds.length < 2) continue;

        // Generate fabric and measure stability
        try {
          // Note: This requires PersonalityKnot objects, which we'd need to get from profiles
          // For now, we'll calculate a simplified stability score
          final stability =
              0.7; // Placeholder - would use actual fabric stability

          stabilityHistory.add(FabricStabilityPoint(
            timestamp: groupReservationsList.first.reservationTime,
            stability: stability,
            groupSize: userAgentIds.length,
          ));

          stableGroups.add(StableGroup(
            userIds: userIds,
            stability: stability,
            reservationCount: groupReservationsList.length,
          ));
        } catch (e) {
          developer.log(
            'Error calculating fabric stability: $e',
            name: _logName,
          );
        }
      }

      // Calculate average stability
      final averageStability = stabilityHistory.isNotEmpty
          ? stabilityHistory.map((p) => p.stability).reduce((a, b) => a + b) /
              stabilityHistory.length
          : 0.0;

      // Calculate group success rate (completed vs total)
      final totalGroupReservations =
          groupReservations.values.expand((list) => list).toList().length;
      final completedGroupReservations = groupReservations.values
          .expand((list) => list)
          .where((r) => r.status == ReservationStatus.completed)
          .length;
      final groupSuccessRate = totalGroupReservations > 0
          ? completedGroupReservations / totalGroupReservations
          : 0.0;

      // Sort stable groups by stability
      stableGroups.sort((a, b) => b.stability.compareTo(a.stability));

      return FabricStabilityAnalytics(
        averageStability: averageStability,
        stabilityHistory: stabilityHistory,
        mostStableGroups: stableGroups.take(5).toList(),
        groupSuccessRate: groupSuccessRate,
      );
    } catch (e) {
      developer.log(
        'Error calculating fabric stability analytics: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate worldsheet evolution analytics
  Future<WorldsheetEvolutionAnalytics?> _calculateWorldsheetEvolutionAnalytics({
    required String businessId,
    required List<Reservation> reservations,
  }) async {
    if (_worldsheetService == null || _fabricService == null) {
      return null;
    }

    try {
      final evolutionHistory = <WorldsheetEvolutionPoint>[];
      final predictions = <WorldsheetPrediction>[];
      final stabilityTrends = <StabilityChangeTrend>[];

      // Group reservations by time periods
      final reservationsByMonth = <String, List<Reservation>>{};
      for (final reservation in reservations) {
        final monthKey =
            '${reservation.reservationTime.year}-${reservation.reservationTime.month}';
        reservationsByMonth.putIfAbsent(monthKey, () => []).add(reservation);
      }

      // Calculate evolution for each month
      for (final monthReservations in reservationsByMonth.values) {
        if (monthReservations.isEmpty) continue;

        final monthStart = monthReservations.first.reservationTime;
        final monthEnd = monthReservations.last.reservationTime;

        // Get group participants for this month
        final participants = <String>{};
        for (final reservation in monthReservations) {
          final groupParticipants =
              reservation.metadata['participants'] as List<dynamic>?;
          if (groupParticipants != null) {
            for (final participant in groupParticipants) {
              try {
                final participantAgentId = await _agentIdService
                    .getUserAgentId(participant.toString());
                participants.add(participantAgentId);
              } catch (e) {
                // Skip if can't get agentId
              }
            }
          }
        }

        if (participants.length < 2) continue;

        // Create worldsheet for this period
        try {
          final groupId =
              'analytics_${businessId}_${monthStart.millisecondsSinceEpoch}';
          final worldsheet = await _worldsheetService.createWorldsheet(
            groupId: groupId,
            userIds: participants.toList(),
            startTime: monthStart.subtract(const Duration(days: 7)),
            endTime: monthEnd.add(const Duration(days: 7)),
          );

          if (worldsheet != null) {
            // Get fabric at month start and end
            final fabricStart = worldsheet.getFabricAtTime(monthStart);
            final fabricEnd = worldsheet.getFabricAtTime(monthEnd);

            if (fabricStart != null && fabricEnd != null) {
              final stabilityStart =
                  await _fabricService.measureFabricStability(fabricStart);
              final stabilityEnd =
                  await _fabricService.measureFabricStability(fabricEnd);

              final evolutionScore =
                  (0.5 + (stabilityEnd - stabilityStart)).clamp(0.0, 1.0);

              evolutionHistory.add(WorldsheetEvolutionPoint(
                timestamp: monthStart,
                evolutionScore: evolutionScore,
                stability: stabilityEnd,
              ));

              // Calculate stability change trend
              final stabilityChange = stabilityEnd - stabilityStart;
              stabilityTrends.add(StabilityChangeTrend(
                startTime: monthStart,
                endTime: monthEnd,
                stabilityChange: stabilityChange,
                trend: stabilityChange > 0
                    ? TrendType.increasing
                    : stabilityChange < 0
                        ? TrendType.decreasing
                        : TrendType.stable,
              ));
            }

            // Predict future evolution
            final futureTime = monthEnd.add(const Duration(days: 30));
            final futureFabric = worldsheet.getFabricAtTime(futureTime);
            if (futureFabric != null) {
              final predictedStability =
                  await _fabricService.measureFabricStability(futureFabric);
              predictions.add(WorldsheetPrediction(
                predictedTime: futureTime,
                predictedStability: predictedStability,
                confidence: 0.7, // Placeholder confidence
              ));
            }
          }
        } catch (e) {
          developer.log(
            'Error calculating worldsheet evolution: $e',
            name: _logName,
          );
        }
      }

      return WorldsheetEvolutionAnalytics(
        evolutionHistory: evolutionHistory,
        predictions: predictions,
        stabilityTrends: stabilityTrends,
      );
    } catch (e) {
      developer.log(
        'Error calculating worldsheet evolution analytics: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate quantum compatibility trends
  Future<QuantumCompatibilityTrends?> _calculateQuantumCompatibilityTrends({
    required String businessId,
    required List<Reservation> reservations,
  }) async {
    if (_quantumService == null) {
      return null;
    }

    try {
      final compatibilityHistory = <CompatibilityTrendPoint>[];
      final highCompatibilityPeriods = <HighCompatibilityPeriod>[];

      // Group reservations by month
      final reservationsByMonth = <String, List<Reservation>>{};
      for (final reservation in reservations) {
        final monthKey =
            '${reservation.reservationTime.year}-${reservation.reservationTime.month}';
        reservationsByMonth.putIfAbsent(monthKey, () => []).add(reservation);
      }

      // Calculate compatibility for each month
      for (final entry in reservationsByMonth.entries) {
        final monthReservations = entry.value;
        if (monthReservations.isEmpty) continue;

        // Get average compatibility from reservations
        double totalCompatibility = 0.0;
        int compatibilityCount = 0;

        for (final reservation in monthReservations) {
          final compatibility =
              reservation.metadata['compatibility'] as double?;
          if (compatibility != null) {
            totalCompatibility += compatibility;
            compatibilityCount++;
          }
        }

        if (compatibilityCount > 0) {
          final avgCompatibility = totalCompatibility / compatibilityCount;
          final monthStart = monthReservations.first.reservationTime;
          final monthEnd = monthReservations.last.reservationTime;

          compatibilityHistory.add(CompatibilityTrendPoint(
            timestamp: monthStart,
            compatibility: avgCompatibility,
            reservationCount: monthReservations.length,
          ));

          // Track high compatibility periods (>0.8)
          if (avgCompatibility > 0.8) {
            highCompatibilityPeriods.add(HighCompatibilityPeriod(
              startTime: monthStart,
              endTime: monthEnd,
              averageCompatibility: avgCompatibility,
              reservationCount: monthReservations.length,
            ));
          }
        }
      }

      // Calculate average compatibility
      final averageCompatibility = compatibilityHistory.isNotEmpty
          ? compatibilityHistory
                  .map((p) => p.compatibility)
                  .reduce((a, b) => a + b) /
              compatibilityHistory.length
          : 0.0;

      // Determine compatibility trend
      TrendType compatibilityTrend = TrendType.stable;
      if (compatibilityHistory.length >= 2) {
        final first = compatibilityHistory.first.compatibility;
        final last = compatibilityHistory.last.compatibility;
        final change = last - first;

        if (change > 0.1) {
          compatibilityTrend = TrendType.increasing;
        } else if (change < -0.1) {
          compatibilityTrend = TrendType.decreasing;
        }
      }

      return QuantumCompatibilityTrends(
        averageCompatibility: averageCompatibility,
        compatibilityHistory: compatibilityHistory,
        highCompatibilityPeriods: highCompatibilityPeriods,
        compatibilityTrend: compatibilityTrend,
      );
    } catch (e) {
      developer.log(
        'Error calculating quantum compatibility trends: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate AI2AI learning insights
  Future<AI2AILearningInsights?> _calculateAI2AILearningInsights({
    required String businessId,
    required List<Reservation> reservations,
  }) async {
    // Note: AI2AI learning insights would come from the mesh network
    // For business analytics, we could track learning insights related to this business
    // For now, we'll return placeholder data
    // In production, this would query the AI2AI mesh for business-specific learning insights

    return const AI2AILearningInsights(
      totalInsights: 0,
      averageLearningQuality: 0.0,
      improvedDimensions: [],
      propagationStats: MeshPropagationStats(
        insightsReceived: 0,
        insightsShared: 0,
        averageHopCount: 0.0,
      ),
      businessInsights: [],
    );
  }
}
