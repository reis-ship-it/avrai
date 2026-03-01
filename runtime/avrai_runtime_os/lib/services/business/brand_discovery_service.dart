import 'package:avrai_core/models/business/brand_discovery.dart';
import 'package:avrai_core/models/business/brand_account.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_integration_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:uuid/uuid.dart';

/// Brand Discovery Service
///
/// Service for brand discovery and event-brand matching.
///
/// **Philosophy Alignment:**
/// - Opens doors to brand discovery
/// - Enables vibe-based brand matching
/// - Supports compatibility scoring
/// - Creates pathways for brand-event connections
///
/// **Responsibilities:**
/// - Brand search for events
/// - Event search for brands
/// - Vibe-based matching algorithm
/// - Compatibility scoring
/// - Sponsorship suggestions
class BrandDiscoveryService {
  static const String _logName = 'BrandDiscoveryService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();

  final ExpertiseEventService _eventService;
  final SponsorshipService _sponsorshipService;
  final QuantumMatchingIntegrationService? _quantumIntegrationService;
  final FeatureFlagService? _featureFlags;

  // Feature flag name for quantum brand discovery matching
  static const String _quantumBrandDiscoveryFlag =
      'phase19_quantum_brand_discovery';

  // In-memory storage for brand discoveries (in production, use database)
  final Map<String, BrandDiscovery> _discoveries = {};

  // In-memory storage for brand accounts (in production, use BrandService)
  final Map<String, BrandAccount> _brandAccounts = {};

  BrandDiscoveryService({
    required ExpertiseEventService eventService,
    required SponsorshipService sponsorshipService,
    QuantumMatchingIntegrationService? quantumIntegrationService,
    FeatureFlagService? featureFlags,
  })  : _eventService = eventService,
        _sponsorshipService = sponsorshipService,
        _quantumIntegrationService = quantumIntegrationService,
        _featureFlags = featureFlags;

  /// Find brands for an event
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get all verified brands
  /// 3. Calculate compatibility for each brand
  /// 4. Filter by minCompatibility (70%+)
  /// 5. Return BrandMatch results sorted by compatibility
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `searchCriteria`: Optional search criteria (category, minContribution, etc.)
  /// - `minCompatibility`: Minimum compatibility threshold (default: 0.70 = 70%)
  ///
  /// **Returns:**
  /// List of BrandMatch sorted by compatibility (highest first)
  Future<List<BrandMatch>> findBrandsForEvent({
    required String eventId,
    Map<String, dynamic>? searchCriteria,
    double minCompatibility = 0.70, // 70% threshold
  }) async {
    try {
      _logger.info('Finding brands for event: $eventId', tag: _logName);

      // Step 1: Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return [];
      }

      // Step 2: Get all verified brands
      final brands = await _getAllVerifiedBrands();

      // Step 3: Calculate compatibility for each brand
      final matches = <BrandMatch>[];

      for (final brand in brands) {
        // Check if brand is eligible
        final isEligible =
            await _sponsorshipService.checkSponsorshipEligibility(
          eventId: eventId,
          brandId: brand.id,
        );
        if (!isEligible) {
          continue;
        }

        // Apply search criteria filters
        if (searchCriteria != null) {
          if (!_matchesSearchCriteria(brand, searchCriteria)) {
            continue;
          }
        }

        // Calculate compatibility
        final compatibility = await calculateBrandEventCompatibility(
          brandId: brand.id,
          eventId: eventId,
        );

        // Filter by minCompatibility (70%+)
        if (compatibility >= minCompatibility) {
          final vibeCompatibility = await _calculateVibeCompatibility(
            brandId: brand.id,
            eventId: eventId,
          );

          matches.add(BrandMatch(
            brandId: brand.id,
            brandName: brand.name,
            compatibilityScore: compatibility * 100, // Convert to 0-100 scale
            vibeCompatibility: vibeCompatibility,
            matchReasons: _getMatchReasons(brand, event, compatibility),
            brandType: brand.brandType,
            brandCategories: brand.categories,
            estimatedContribution: _estimateContribution(brand),
          ));
        }
      }

      // Step 4: Sort by compatibility (highest first)
      matches
          .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      _logger.info(
          'Found ${matches.length} matching brands (>=${(minCompatibility * 100).toStringAsFixed(0)}% compatibility)',
          tag: _logName);
      return matches;
    } catch (e) {
      _logger.error('Error finding brands for event', error: e, tag: _logName);
      return [];
    }
  }

  /// Find events for a brand
  ///
  /// **Flow:**
  /// 1. Get brand details
  /// 2. Get all upcoming events
  /// 3. Calculate compatibility for each event
  /// 4. Filter by minCompatibility (70%+)
  /// 5. Return EventMatch results sorted by compatibility
  ///
  /// **Parameters:**
  /// - `brandId`: Brand ID
  /// - `searchCriteria`: Optional search criteria (category, location, etc.)
  /// - `minCompatibility`: Minimum compatibility threshold (default: 0.70 = 70%)
  ///
  /// **Returns:**
  /// List of EventMatch sorted by compatibility (highest first)
  Future<List<EventMatch>> findEventsForBrand({
    required String brandId,
    Map<String, dynamic>? searchCriteria,
    double minCompatibility = 0.70, // 70% threshold
  }) async {
    try {
      _logger.info('Finding events for brand: $brandId', tag: _logName);

      // Step 1: Get brand details
      final brand = await _getBrandById(brandId);
      if (brand == null) {
        _logger.info('Brand not found: $brandId', tag: _logName);
        return [];
      }

      if (!brand.isVerified) {
        _logger.info('Brand not verified: $brandId', tag: _logName);
        return [];
      }

      // Step 2: Get all upcoming events (in production, use event service search)
      final events = await _getAllUpcomingEvents();

      // Step 3: Calculate compatibility for each event
      final matches = <EventMatch>[];

      for (final event in events) {
        // Apply search criteria filters
        if (searchCriteria != null) {
          if (!_matchesEventSearchCriteria(event, searchCriteria)) {
            continue;
          }
        }

        // Check if brand is eligible
        final isEligible =
            await _sponsorshipService.checkSponsorshipEligibility(
          eventId: event.id,
          brandId: brandId,
        );
        if (!isEligible) {
          continue;
        }

        // Calculate compatibility
        final compatibility = await calculateBrandEventCompatibility(
          brandId: brandId,
          eventId: event.id,
        );

        // Filter by minCompatibility (70%+)
        if (compatibility >= minCompatibility) {
          final vibeCompatibility = await _calculateVibeCompatibility(
            brandId: brandId,
            eventId: event.id,
          );

          matches.add(EventMatch(
            eventId: event.id,
            eventName: event.title,
            compatibilityScore: compatibility * 100, // Convert to 0-100 scale
            vibeCompatibility: vibeCompatibility,
            matchReasons: _getEventMatchReasons(brand, event, compatibility),
            eventCategory: event.category,
            eventLocation: event.location,
            eventDate: event.startTime,
          ));
        }
      }

      // Step 4: Sort by compatibility (highest first)
      matches
          .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      _logger.info(
          'Found ${matches.length} matching events (>=${(minCompatibility * 100).toStringAsFixed(0)}% compatibility)',
          tag: _logName);
      return matches;
    } catch (e) {
      _logger.error('Error finding events for brand', error: e, tag: _logName);
      return [];
    }
  }

  /// Calculate compatibility between brand and event
  ///
  /// **Flow:**
  /// 1. Try quantum matching (if enabled)
  /// 2. Fall back to classical SponsorshipService compatibility
  /// 3. Add knot compatibility bonus (if enabled)
  ///
  /// **Parameters:**
  /// - `brandId`: Brand ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  ///
  /// **Phase 19.15 Integration:**
  /// - Uses quantum entanglement matching if enabled via feature flag
  /// - Falls back to classical SponsorshipService compatibility if quantum matching is disabled or fails
  /// - Maintains backward compatibility (70%+ threshold)
  ///
  /// **Note:**
  /// Classical method reuses the SponsorshipService compatibility calculation for consistency
  Future<double> calculateBrandEventCompatibility({
    required String brandId,
    required String eventId,
  }) async {
    try {
      _logger.info(
          'Calculating brand-event compatibility: brand=$brandId, event=$eventId',
          tag: _logName);

      // Phase 19.15: Try quantum matching first (if enabled)
      if (_quantumIntegrationService != null && _featureFlags != null) {
        final isQuantumEnabled = await _featureFlags.isEnabled(
          _quantumBrandDiscoveryFlag,
          userId: null, // Brand matching doesn't have user context
          defaultValue: false,
        );

        if (isQuantumEnabled) {
          try {
            // Get brand and event objects for quantum matching
            final brand = await _getBrandById(brandId);
            final event = await _eventService.getEventById(eventId);

            if (brand != null && event != null) {
              // Use event host as user context for quantum matching
              final user = event.host;

              final quantumResult = await _quantumIntegrationService
                  .calculateMultiEntityCompatibility(
                user: user,
                event: event,
                brand: brand,
              );

              if (quantumResult != null) {
                // Quantum matching successful - use it as base score
                // Combine with classical method for hybrid approach
                final classicalCompatibility =
                    await _sponsorshipService.calculateCompatibility(
                  eventId: eventId,
                  brandId: brandId,
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
      return await _sponsorshipService.calculateCompatibility(
        eventId: eventId,
        brandId: brandId,
      );
    } catch (e) {
      _logger.error('Error calculating brand-event compatibility',
          error: e, tag: _logName);
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

  /// Get sponsorship suggestions for an event
  ///
  /// **Flow:**
  /// 1. Find brands for event
  /// 2. Create BrandDiscovery record
  /// 3. Return sponsorship suggestions
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `searchCriteria`: Optional search criteria
  ///
  /// **Returns:**
  /// BrandDiscovery with matching results
  Future<BrandDiscovery> getSponsorshipSuggestions({
    required String eventId,
    Map<String, dynamic>? searchCriteria,
  }) async {
    try {
      _logger.info('Getting sponsorship suggestions for event: $eventId',
          tag: _logName);

      // Find brands for event
      final matches = await findBrandsForEvent(
        eventId: eventId,
        searchCriteria: searchCriteria,
      );

      // Create BrandDiscovery record
      final discovery = BrandDiscovery(
        id: _generateDiscoveryId(),
        eventId: eventId,
        searchCriteria: searchCriteria ?? {},
        matchingResults: matches,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save discovery
      await _saveDiscovery(discovery);

      _logger.info('Created discovery with ${matches.length} matches',
          tag: _logName);
      return discovery;
    } catch (e) {
      _logger.error('Error getting sponsorship suggestions',
          error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  Future<List<BrandAccount>> _getAllVerifiedBrands() async {
    // In production, query BrandService for verified brands
    return _brandAccounts.values.where((brand) => brand.isVerified).toList();
  }

  Future<BrandAccount?> _getBrandById(String brandId) async {
    // In production, use BrandService
    return _brandAccounts[brandId];
  }

  Future<List<ExpertiseEvent>> _getAllUpcomingEvents() async {
    // In production, use ExpertiseEventService search
    // For now, return empty list (to be implemented)
    return [];
  }

  bool _matchesSearchCriteria(
      BrandAccount brand, Map<String, dynamic> criteria) {
    // Check category match
    if (criteria.containsKey('category')) {
      final category = criteria['category'] as String?;
      if (category != null && !brand.categories.contains(category)) {
        return false;
      }
    }

    // Check minContribution
    // TODO: Implement minContribution filtering when brand contribution history is available
    if (criteria.containsKey('minContribution')) {
      // Would need brand contribution history to check
      // For now, skip this check
    }

    return true;
  }

  bool _matchesEventSearchCriteria(
      ExpertiseEvent event, Map<String, dynamic> criteria) {
    // Check category match
    if (criteria.containsKey('category')) {
      final category = criteria['category'] as String?;
      if (category != null && event.category != category) {
        return false;
      }
    }

    // Check location match
    if (criteria.containsKey('location')) {
      final location = criteria['location'] as String?;
      if (location != null && event.location != location) {
        return false;
      }
    }

    return true;
  }

  Future<VibeCompatibility> _calculateVibeCompatibility({
    required String brandId,
    required String eventId,
  }) async {
    final score = await _sponsorshipService.calculateVibeScore(
      eventId: eventId,
      brandId: brandId,
    );

    // Map the truthful quantum+knot breakdown into the legacy UI fields.
    // These fields are display-only; the canonical matching threshold uses overallScore.
    final overallScore = score.combined * 100;

    return VibeCompatibility(
      overallScore: overallScore,
      valueAlignment: score.knotTopological * 100,
      styleCompatibility: score.quantum * 100,
      qualityFocus: score.knotWeave * 100,
      audienceAlignment:
          ((score.quantum * 0.6) + (score.knotTopological * 0.4)) * 100,
      breakdown: {
        'quantum': score.quantum,
        'knot_topological': score.knotTopological,
        'knot_weave': score.knotWeave,
        'combined': score.combined,
      },
    );
  }

  List<String> _getMatchReasons(
      BrandAccount brand, ExpertiseEvent event, double compatibility) {
    final reasons = <String>[];

    // Category match
    if (brand.categories.any((cat) => event.category == cat)) {
      reasons.add('Category match: ${event.category}');
    }

    // Compatibility score
    if (compatibility >= 0.80) {
      reasons.add(
          'High compatibility (${(compatibility * 100).toStringAsFixed(0)}%)');
    } else if (compatibility >= 0.70) {
      reasons.add(
          'Good compatibility (${(compatibility * 100).toStringAsFixed(0)}%)');
    }

    return reasons;
  }

  List<String> _getEventMatchReasons(
      BrandAccount brand, ExpertiseEvent event, double compatibility) {
    final reasons = <String>[];

    // Category match
    if (brand.categories.any((cat) => event.category == cat)) {
      reasons.add('Category match: ${event.category}');
    }

    // Compatibility score
    if (compatibility >= 0.80) {
      reasons.add(
          'High compatibility (${(compatibility * 100).toStringAsFixed(0)}%)');
    } else if (compatibility >= 0.70) {
      reasons.add(
          'Good compatibility (${(compatibility * 100).toStringAsFixed(0)}%)');
    }

    return reasons;
  }

  ContributionRange? _estimateContribution(BrandAccount brand) {
    // TODO: In production, use brand contribution history
    // For now, return null (no estimate)
    return null;
  }

  String _generateDiscoveryId() {
    return 'discovery_${_uuid.v4()}';
  }

  Future<void> _saveDiscovery(BrandDiscovery discovery) async {
    // In production, save to database
    _discoveries[discovery.id] = discovery;
  }

  /// Register brand account (helper method for testing)
  ///
  /// **Note:** In production, this would be handled by BrandService
  Future<void> registerBrand(BrandAccount brand) async {
    try {
      _brandAccounts[brand.id] = brand;
      _logger.info('Registered brand: ${brand.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error registering brand', error: e, tag: _logName);
      rethrow;
    }
  }
}

/// Event Match
///
/// Represents a single event match result with compatibility scoring.
class EventMatch {
  final String eventId;
  final String eventName;
  final double compatibilityScore;
  final VibeCompatibility vibeCompatibility;
  final List<String> matchReasons;
  final String? eventCategory;
  final String? eventLocation;
  final DateTime? eventDate;

  const EventMatch({
    required this.eventId,
    required this.eventName,
    required this.compatibilityScore,
    required this.vibeCompatibility,
    this.matchReasons = const [],
    this.eventCategory,
    this.eventLocation,
    this.eventDate,
  });
}
