import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/business_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_integration_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';

/// Partnership Matching Service
///
/// Vibe-based partnership matching and suggestions.
///
/// **Philosophy Alignment:**
/// - Only suggests partnerships with 70%+ compatibility
/// - Reduces spam and mismatches
/// - Higher acceptance rates
/// - Both parties can still decline (but rarely need to)
///
/// **Responsibilities:**
/// - Vibe-based matching algorithm
/// - Compatibility scoring
/// - Partnership suggestions
class PartnershipMatchingService {
  static const String _logName = 'PartnershipMatchingService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  final PartnershipService _partnershipService;
  final BusinessService _businessService;
  final ExpertiseEventService _eventService;
  final QuantumMatchingIntegrationService? _quantumIntegrationService;
  final FeatureFlagService? _featureFlags;

  // Feature flag name for quantum partnership matching
  static const String _quantumPartnershipMatchingFlag =
      'phase19_quantum_partnership_matching';

  PartnershipMatchingService({
    required PartnershipService partnershipService,
    required BusinessService businessService,
    required ExpertiseEventService eventService,
    QuantumMatchingIntegrationService? quantumIntegrationService,
    FeatureFlagService? featureFlags,
  })  : _partnershipService = partnershipService,
        _businessService = businessService,
        _eventService = eventService,
        _quantumIntegrationService = quantumIntegrationService,
        _featureFlags = featureFlags;

  /// Find matching partners for an event
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get user personality/vibe data
  /// 3. Find businesses in same category/location
  /// 4. Calculate compatibility for each business
  /// 5. Filter by minCompatibility (70%+)
  /// 6. Return suggestions sorted by compatibility
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// - `minCompatibility`: Minimum compatibility threshold (default: 0.70 = 70%)
  ///
  /// **Returns:**
  /// List of PartnershipSuggestion sorted by compatibility (highest first)
  Future<List<PartnershipSuggestion>> findMatchingPartners({
    required String userId,
    required String eventId,
    double minCompatibility = 0.70, // 70% threshold
  }) async {
    try {
      _logger.info('Finding matching partners: user=$userId, event=$eventId',
          tag: _logName);

      // Step 1: Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return [];
      }

      // Step 2: Find businesses in same category/location
      final businesses = await _businessService.findBusinesses(
        category: event.category,
        location: event.location,
        verifiedOnly: true, // Only verified businesses
        maxResults: 50, // Get more candidates for filtering
      );

      // Step 3: Calculate compatibility for each business
      final suggestions = <PartnershipSuggestion>[];

      for (final business in businesses) {
        // Check if business is eligible
        final isEligible =
            await _businessService.checkBusinessEligibility(business.id);
        if (!isEligible) {
          continue;
        }

        // Calculate compatibility (with event context for quantum matching)
        final compatibility = await calculateCompatibility(
          userId: userId,
          businessId: business.id,
          event: event, // Pass event context for quantum matching
        );

        // Filter by minCompatibility (70%+)
        if (compatibility >= minCompatibility) {
          suggestions.add(PartnershipSuggestion(
            businessId: business.id,
            business: business,
            compatibility: compatibility,
            eventId: eventId,
            reason: _getCompatibilityReason(compatibility),
          ));
        }
      }

      // Step 4: Sort by compatibility (highest first)
      suggestions.sort((a, b) => b.compatibility.compareTo(a.compatibility));

      _logger.info(
          'Found ${suggestions.length} matching partners (>=${(minCompatibility * 100).toStringAsFixed(0)}% compatibility)',
          tag: _logName);
      return suggestions;
    } catch (e) {
      _logger.error('Error finding matching partners', error: e, tag: _logName);
      return [];
    }
  }

  /// Calculate compatibility score between user and business
  ///
  /// **Flow:**
  /// 1. Try quantum matching (if enabled and event context available)
  /// 2. Fall back to classical vibe-based matching
  /// 3. Add knot compatibility bonus (if enabled)
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `businessId`: Business ID
  /// - `event`: Optional event context (enables quantum matching)
  ///
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  ///
  /// **Phase 19.15 Integration:**
  /// - Uses quantum entanglement matching if enabled via feature flag and event context available
  /// - Falls back to classical vibe-based matching if quantum matching is disabled or fails
  /// - Maintains backward compatibility (70%+ threshold)
  ///
  /// **Compatibility Formula (Classical):**
  /// ```
  /// compatibility = (
  ///   valueAlignment * 0.25 +
  ///   qualityFocus * 0.25 +
  ///   communityOrientation * 0.20 +
  ///   eventStyleMatch * 0.20 +
  ///   authenticityMatch * 0.10
  /// )
  /// ```
  Future<double> calculateCompatibility({
    required String userId,
    required String businessId,
    ExpertiseEvent? event,
  }) async {
    try {
      _logger.info(
        'Calculating compatibility: user=$userId, business=$businessId, event=${event?.id ?? "none"}',
        tag: _logName,
      );

      // Phase 19.15: Try quantum matching first (if enabled and event context available)
      if (_quantumIntegrationService != null &&
          _featureFlags != null &&
          event != null) {
        final isQuantumEnabled = await _featureFlags.isEnabled(
          _quantumPartnershipMatchingFlag,
          userId: userId,
          defaultValue: false,
        );

        if (isQuantumEnabled) {
          try {
            // Get user and business objects for quantum matching
            final business = await _businessService.getBusinessById(businessId);
            if (business != null) {
              // Get user object (we'll need to create a minimal UnifiedUser from userId)
              // For now, we'll use the event host as the user context
              final user = event.host;

              final quantumResult = await _quantumIntegrationService
                  .calculateMultiEntityCompatibility(
                user: user,
                event: event,
                business: business,
              );

              if (quantumResult != null) {
                // Quantum matching successful - use it as base score
                // Combine with classical method for hybrid approach
                final classicalCompatibility =
                    await _partnershipService.calculateVibeCompatibility(
                  userId: userId,
                  businessId: businessId,
                );

                // Hybrid approach: 70% quantum, 30% classical (quantum is primary)
                final hybridScore = 0.7 * quantumResult.compatibility +
                    0.3 * classicalCompatibility;

                // Add knot compatibility bonus if enabled
                final knotBonus = await _calculateKnotCompatibilityBonus(
                  quantumResult: quantumResult,
                );
                final finalScore =
                    (hybridScore + knotBonus * 0.15).clamp(0.0, 1.0);

                _logger.info(
                  'Quantum matching used: quantum=${quantumResult.compatibility.toStringAsFixed(3)}, classical=${classicalCompatibility.toStringAsFixed(3)}, hybrid=${finalScore.toStringAsFixed(3)}',
                  tag: _logName,
                );

                return finalScore;
              }
            }
          } catch (e) {
            _logger.warn(
              'Quantum matching failed, falling back to classical: $e',
              tag: _logName,
            );
            // Fall through to classical method
          }
        }
      }

      // Classical method (backward compatibility)
      final compatibility =
          await _partnershipService.calculateVibeCompatibility(
        userId: userId,
        businessId: businessId,
      );

      return compatibility;
    } catch (e) {
      _logger.error('Error calculating compatibility', error: e, tag: _logName);
      return 0.0;
    }
  }

  /// Calculate knot compatibility bonus (if enabled)
  ///
  /// **Phase 19.15:** Adds knot compatibility bonus when quantum matching is used
  Future<double> _calculateKnotCompatibilityBonus({
    required MatchingResult quantumResult,
  }) async {
    if (_quantumIntegrationService == null || _featureFlags == null) {
      return 0.0;
    }

    try {
      final isKnotEnabled =
          await _quantumIntegrationService.isKnotIntegrationEnabled();
      if (isKnotEnabled && quantumResult.knotCompatibility != null) {
        return quantumResult.knotCompatibility!;
      }
    } catch (e) {
      _logger.warn('Error calculating knot bonus: $e', tag: _logName);
    }

    return 0.0;
  }

  /// Get partnership suggestions for an event
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get event host (user)
  /// 3. Find matching partners
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// List of PartnershipSuggestion
  Future<List<PartnershipSuggestion>> getSuggestions({
    required String eventId,
  }) async {
    try {
      _logger.info('Getting partnership suggestions for event: $eventId',
          tag: _logName);

      // Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return [];
      }

      // Get event host (user)
      final userId = event.host.id;

      // Find matching partners
      return await findMatchingPartners(
        userId: userId,
        eventId: eventId,
      );
    } catch (e) {
      _logger.error('Error getting suggestions', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  String _getCompatibilityReason(double compatibility) {
    if (compatibility >= 0.90) {
      return 'Excellent match - High compatibility';
    } else if (compatibility >= 0.80) {
      return 'Great match - Strong compatibility';
    } else if (compatibility >= 0.70) {
      return 'Good match - Compatible partnership';
    } else {
      return 'Moderate match';
    }
  }
}

/// Partnership Suggestion
///
/// Represents a suggested partnership match.
class PartnershipSuggestion {
  final String businessId;
  final BusinessAccount? business;
  final double compatibility; // 0.0 to 1.0
  final String eventId;
  final String reason; // Why this is a good match

  PartnershipSuggestion({
    required this.businessId,
    this.business,
    required this.compatibility,
    required this.eventId,
    required this.reason,
  });

  /// Get compatibility percentage
  int get compatibilityPercentage => (compatibility * 100).round();

  /// Check if suggestion meets minimum threshold (70%+)
  bool get meetsThreshold => compatibility >= 0.70;

  @override
  String toString() {
    return 'PartnershipSuggestion(business: $businessId, compatibility: $compatibilityPercentage%, reason: $reason)';
  }
}
