import 'dart:async';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
import 'package:uuid/uuid.dart';

/// Partnership Service
///
/// Core service for managing event partnerships between users and businesses.
///
/// **Philosophy Alignment:**
/// - Opens doors to business partnerships
/// - Enables multi-party event hosting
/// - Supports revenue sharing agreements
/// - Creates pathways for business collaboration
///
/// **Partnership Workflow:**
/// 1. Discovery - AI suggests compatible partners (70%+ vibe match only)
/// 2. Proposal - One party proposes partnership with revenue split
/// 3. Negotiation - Revenue split discussion (can counter-propose)
/// 4. Agreement - ALL parties must approve and LOCK before event starts
/// 5. Execution - Event happens
/// 6. Payment - Automatic revenue distribution (2 days after event)
/// 7. Feedback - Mutual ratings (both can rate each other)
class PartnershipService {
  static const String _logName = 'PartnershipService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();

  final ExpertiseEventService _eventService;
  final BusinessService _businessService;
  final VibeCompatibilityService _vibeCompatibilityService;
  final EpisodicMemoryStore? _episodicMemoryStore;
  final OutcomeTaxonomy _outcomeTaxonomy;
  final LedgerRecorderServiceV0 _ledger;

  // In-memory storage for partnerships (in production, use database)
  final Map<String, EventPartnership> _partnerships = {};

  PartnershipService({
    required ExpertiseEventService eventService,
    required BusinessService businessService,
    required VibeCompatibilityService vibeCompatibilityService,
    EpisodicMemoryStore? episodicMemoryStore,
    OutcomeTaxonomy outcomeTaxonomy = const OutcomeTaxonomy(),
    LedgerRecorderServiceV0? ledgerRecorder,
  })  : _eventService = eventService,
        _businessService = businessService,
        _vibeCompatibilityService = vibeCompatibilityService,
        _episodicMemoryStore = episodicMemoryStore,
        _outcomeTaxonomy = outcomeTaxonomy,
        _ledger = ledgerRecorder ??
            LedgerRecorderServiceV0(
              supabaseService: SupabaseService(),
              agentIdService: AgentIdService(),
              storage: StorageService.instance,
            );

  Future<void> _tryLedgerAppendForUser({
    required String expectedOwnerUserId,
    required String eventType,
    required String entityType,
    required String entityId,
    String? category,
    String? cityCode,
    String? localityCode,
    required Map<String, Object?> payload,
  }) async {
    try {
      final currentUserId = SupabaseService().currentUser?.id;
      if (currentUserId == null || currentUserId != expectedOwnerUserId) {
        return;
      }

      await _ledger.append(
        domain: LedgerDomainV0.expertise,
        eventType: eventType,
        occurredAt: DateTime.now(),
        payload: payload,
        entityType: entityType,
        entityId: entityId,
        category: category,
        cityCode: cityCode,
        localityCode: localityCode,
        correlationId: entityId,
      );
    } catch (e) {
      _logger.warning(
        'Ledger write skipped/failed for $eventType: ${e.toString()}',
        tag: _logName,
      );
    }
  }

  /// Create a new partnership for an event
  ///
  /// **Flow:**
  /// 1. Validate event exists
  /// 2. Validate business exists
  /// 3. Check partnership eligibility
  /// 4. Calculate vibe compatibility (must be 70%+)
  /// 5. Create EventPartnership record
  /// 6. Update ExpertiseEvent with partnership reference
  /// 7. Return partnership
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID for the partnership
  /// - `userId`: User/Expert ID
  /// - `businessId`: Business ID
  /// - `agreement`: Partnership agreement terms
  ///
  /// **Returns:**
  /// EventPartnership with status `pending` or `proposed`
  ///
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if business not found
  /// - `Exception` if partnership not eligible
  /// - `Exception` if compatibility < 70%
  Future<EventPartnership> createPartnership({
    required String eventId,
    required String userId,
    required String businessId,
    PartnershipAgreement? agreement,
    PartnershipType type = PartnershipType.eventBased,
    List<String>? sharedResponsibilities,
    String? venueLocation,
    double? vibeCompatibilityScore,
  }) async {
    try {
      _logger.info(
          'Creating partnership: event=$eventId, user=$userId, business=$businessId',
          tag: _logName);

      // Step 1: Validate event exists
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }

      // Step 2: Validate business exists
      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        throw Exception('Business not found: $businessId');
      }

      // Step 3: Check partnership eligibility
      final isEligible = await checkPartnershipEligibility(
        userId: userId,
        businessId: businessId,
        eventId: eventId,
      );
      if (!isEligible) {
        throw Exception('Partnership not eligible');
      }

      // Step 4: Calculate vibe compatibility (if not provided)
      double compatibility = vibeCompatibilityScore ?? 0.0;
      if (compatibility == 0.0) {
        compatibility = await calculateVibeCompatibility(
          userId: userId,
          businessId: businessId,
        );
      }

      // Step 5: Validate compatibility threshold (70%+)
      if (compatibility < 0.70) {
        throw Exception(
            'Compatibility below 70% threshold: ${(compatibility * 100).toStringAsFixed(1)}%');
      }

      // Step 6: Create partnership
      final partnership = EventPartnership(
        id: _generatePartnershipId(),
        eventId: eventId,
        userId: userId,
        businessId: businessId,
        status: PartnershipStatus.proposed,
        agreement: agreement,
        type: type,
        sharedResponsibilities: sharedResponsibilities ?? [],
        venueLocation: venueLocation,
        vibeCompatibilityScore: compatibility,
        userApproved: false,
        businessApproved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Step 7: Save partnership
      await _savePartnership(partnership);
      await _recordPartnershipTuple(
        partnership: partnership,
        eventCategory: event.category,
      );
      await _recordChatToPartnershipTuple(
        partnership: partnership,
        eventCategory: event.category,
      );

      // Best-effort dual-write to ledger (must never block UX).
      unawaited(_tryLedgerAppendForUser(
        expectedOwnerUserId: userId,
        eventType: 'partnership_proposed',
        entityType: 'partnership',
        entityId: partnership.id,
        category: event.category,
        cityCode: event.cityCode,
        localityCode: event.localityCode,
        payload: <String, Object?>{
          'partnership_id': partnership.id,
          'event_id': partnership.eventId,
          'user_id': partnership.userId,
          'business_id': partnership.businessId,
          'status': partnership.status.name,
          'type': partnership.type.name,
          'vibe_compatibility_score': partnership.vibeCompatibilityScore,
          'venue_location': partnership.venueLocation,
          'shared_responsibilities_count':
              partnership.sharedResponsibilities.length,
          'has_agreement': partnership.agreement != null,
          if (partnership.agreement != null)
            'agreement': partnership.agreement!.toJson(),
        },
      ));

      _logger.info('Created partnership: ${partnership.id}', tag: _logName);
      return partnership;
    } catch (e) {
      _logger.error('Error creating partnership', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all partnerships for an event
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// List of EventPartnership records
  Future<List<EventPartnership>> getPartnershipsForEvent(String eventId) async {
    try {
      _logger.info('Getting partnerships for event: $eventId', tag: _logName);

      final allPartnerships = await _getAllPartnerships();
      return allPartnerships.where((p) => p.eventId == eventId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting partnerships for event',
          error: e, tag: _logName);
      return [];
    }
  }

  /// Get partnership by ID
  ///
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  ///
  /// **Returns:**
  /// EventPartnership if found, null otherwise
  Future<EventPartnership?> getPartnershipById(String partnershipId) async {
    try {
      _logger.info('Getting partnership by ID: $partnershipId', tag: _logName);

      final allPartnerships = await _getAllPartnerships();
      try {
        return allPartnerships.firstWhere(
          (p) => p.id == partnershipId,
        );
      } catch (e) {
        _logger.info('Partnership not found: $partnershipId', tag: _logName);
        return null;
      }
    } catch (e) {
      _logger.error('Error getting partnership by ID', error: e, tag: _logName);
      return null;
    }
  }

  /// Update partnership status
  ///
  /// **Flow:**
  /// 1. Get partnership by ID
  /// 2. Validate status transition
  /// 3. Update partnership status
  /// 4. If status is `approved` and all parties approved:
  ///    - Lock revenue split (pre-event)
  ///    - Update event status
  /// 5. Return updated partnership
  ///
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// - `status`: New partnership status
  ///
  /// **Returns:**
  /// Updated EventPartnership
  ///
  /// **Throws:**
  /// - `Exception` if partnership not found
  /// - `Exception` if status transition is invalid
  Future<EventPartnership> updatePartnershipStatus({
    required String partnershipId,
    required PartnershipStatus status,
  }) async {
    try {
      _logger.info(
          'Updating partnership status: $partnershipId -> ${status.name}',
          tag: _logName);

      final partnership = await getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }

      // Validate status transition
      if (!_isValidStatusTransition(partnership.status, status)) {
        throw Exception(
            'Invalid status transition: ${partnership.status.name} -> ${status.name}');
      }

      // Update partnership
      final updated = partnership.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      // If status is `approved` and all parties approved, lock the agreement
      if (status == PartnershipStatus.approved && partnership.isApproved) {
        final locked = updated.copyWith(
          status: PartnershipStatus.locked,
          updatedAt: DateTime.now(),
        );
        await _savePartnership(locked);
        _logger.info('Partnership locked: $partnershipId', tag: _logName);

        // Best-effort dual-write to ledger (must never block UX).
        unawaited(() async {
          try {
            final event = await _eventService.getEventById(locked.eventId);
            await _tryLedgerAppendForUser(
              expectedOwnerUserId: locked.userId,
              eventType: 'partnership_locked',
              entityType: 'partnership',
              entityId: locked.id,
              category: event?.category,
              cityCode: event?.cityCode,
              localityCode: event?.localityCode,
              payload: <String, Object?>{
                'partnership_id': locked.id,
                'event_id': locked.eventId,
                'user_id': locked.userId,
                'business_id': locked.businessId,
                'status': locked.status.name,
                'type': locked.type.name,
                'terms_version': locked.termsVersion,
                'vibe_compatibility_score': locked.vibeCompatibilityScore,
                'revenue_split_id': locked.revenueSplitId,
              },
            );
          } catch (e) {
            _logger.warning(
              'Ledger write skipped/failed for partnership_locked: ${e.toString()}',
              tag: _logName,
            );
          }
        }());

        return locked;
      }

      await _savePartnership(updated);
      _logger.info('Updated partnership status: $partnershipId', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating partnership status',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Approve partnership (user or business)
  ///
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// - `approvedBy`: User ID or Business ID who approved
  ///
  /// **Returns:**
  /// Updated EventPartnership
  Future<EventPartnership> approvePartnership({
    required String partnershipId,
    required String approvedBy,
  }) async {
    try {
      _logger.info('Approving partnership: $partnershipId by $approvedBy',
          tag: _logName);

      final partnership = await getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }

      // Determine if user or business approved
      final isUserApproval = approvedBy == partnership.userId;
      final isBusinessApproval = approvedBy == partnership.businessId;

      if (!isUserApproval && !isBusinessApproval) {
        throw Exception('Invalid approver: $approvedBy');
      }

      // Update approval flags
      final updated = partnership.copyWith(
        userApproved: isUserApproval ? true : partnership.userApproved,
        businessApproved:
            isBusinessApproval ? true : partnership.businessApproved,
        updatedAt: DateTime.now(),
      );

      // Save the updated approval flags first
      await _savePartnership(updated);

      // If both parties approved, update status to approved (which will lock it)
      if (updated.isApproved) {
        return await updatePartnershipStatus(
          partnershipId: partnershipId,
          status: PartnershipStatus.approved,
        );
      }

      return updated;
    } catch (e) {
      _logger.error('Error approving partnership', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check partnership eligibility
  ///
  /// **Flow:**
  /// 1. Check user has City-level expertise
  /// 2. Check business is verified
  /// 3. Check event exists and is upcoming
  /// 4. Check no existing partnership for this event
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `businessId`: Business ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// true if eligible, false otherwise
  Future<bool> checkPartnershipEligibility({
    required String userId,
    required String businessId,
    required String eventId,
  }) async {
    try {
      // Step 1: Check event exists
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return false;
      }

      // Step 2: Check event is upcoming
      if (event.hasStarted) {
        _logger.info('Event has already started: $eventId', tag: _logName);
        return false;
      }

      // Step 3: Check user has Local-level expertise or higher
      if (!event.host.canHostEvents()) {
        _logger.info('User cannot host events: $userId', tag: _logName);
        return false;
      }

      // Step 4: Check business is verified
      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        _logger.info('Business not found: $businessId', tag: _logName);
        return false;
      }

      if (!business.isVerified) {
        _logger.info('Business not verified: $businessId', tag: _logName);
        return false;
      }

      // Step 5: Check no existing partnership for this event
      final existingPartnerships = await getPartnershipsForEvent(eventId);
      if (existingPartnerships.isNotEmpty) {
        _logger.info('Partnership already exists for event: $eventId',
            tag: _logName);
        return false;
      }

      return true;
    } catch (e) {
      _logger.error('Error checking partnership eligibility',
          error: e, tag: _logName);
      return false;
    }
  }

  /// Calculate vibe compatibility between user and business
  ///
  /// **Flow:**
  /// 1. Get user personality/vibe data
  /// 2. Get business preferences/vibe data
  /// 3. Calculate compatibility score (0.0 to 1.0)
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `businessId`: Business ID
  ///
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  ///
  /// **Note:**
  /// This is a **truthful** implementation:
  /// - Quantum-inspired fidelity over the 12 SPOTS dimensions
  /// - Knot topology + weave similarity when knot runtime is available
  /// - Graceful degradation to quantum-only scoring when knot runtime isn’t available
  Future<double> calculateVibeCompatibility({
    required String userId,
    required String businessId,
  }) async {
    try {
      _logger.info(
          'Calculating vibe compatibility: user=$userId, business=$businessId',
          tag: _logName);

      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        return 0.0;
      }

      final score = await _vibeCompatibilityService.calculateUserBusinessVibe(
        userId: userId,
        business: business,
      );

      return score.combined;
    } catch (e) {
      _logger.error('Error calculating vibe compatibility',
          error: e, tag: _logName);
      return 0.0;
    }
  }

  /// Record partnership outcomes for training:
  /// longevity, co-hosted events, revenue, and mutual satisfaction.
  Future<void> recordPartnershipOutcome({
    required String partnershipId,
    required int activeDays,
    required int coHostedEventCount,
    required double revenueGenerated,
    required double businessSatisfactionRating,
    required double expertSatisfactionRating,
  }) async {
    try {
      final partnership = await getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }
      final event = await _eventService.getEventById(partnership.eventId);
      final eventCategory = event?.category ?? 'unknown';
      await _recordPartnershipTuple(
        partnership: partnership,
        eventCategory: eventCategory,
        partnershipOutcome: {
          'active_days': activeDays,
          'co_hosted_event_count': coHostedEventCount,
          'revenue_generated': revenueGenerated,
          'business_satisfaction_rating': businessSatisfactionRating,
          'expert_satisfaction_rating': expertSatisfactionRating,
          'mutual_satisfaction_rating':
              (businessSatisfactionRating + expertSatisfactionRating) / 2.0,
        },
      );
      await _recordCoHostedEventTuple(
        partnership: partnership,
        eventCategory: eventCategory,
        coHostedEventCount: coHostedEventCount,
        revenueGenerated: revenueGenerated,
        businessSatisfactionRating: businessSatisfactionRating,
        expertSatisfactionRating: expertSatisfactionRating,
      );
      _logger.info('Recorded partnership outcome: $partnershipId',
          tag: _logName);
    } catch (e) {
      _logger.error('Error recording partnership outcome',
          error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  String _generatePartnershipId() {
    return 'partnership_${_uuid.v4()}';
  }

  Future<void> _savePartnership(EventPartnership partnership) async {
    // In production, save to database
    _partnerships[partnership.id] = partnership;
  }

  Future<void> _recordPartnershipTuple({
    required EventPartnership partnership,
    required String eventCategory,
    Map<String, dynamic>? partnershipOutcome,
  }) async {
    final store = _episodicMemoryStore;
    if (store == null) return;
    try {
      final tuple = EpisodicTuple(
        agentId: partnership.businessId,
        stateBefore: {
          'phase_ref': '1.2.22',
          'business_id': partnership.businessId,
          'event_id': partnership.eventId,
          'partnership_id': partnership.id,
          'partnership_status': partnership.status.name,
        },
        actionType: 'form_partnership',
        actionPayload: {
          'expert_features': {
            'expert_id': partnership.userId,
            'vibe_compatibility_score': partnership.vibeCompatibilityScore,
            'shared_responsibilities_count':
                partnership.sharedResponsibilities.length,
          },
          'partnership_features': {
            'partnership_id': partnership.id,
            'type': partnership.type.name,
            'status': partnership.status.name,
            'event_id': partnership.eventId,
            'event_category': eventCategory,
          },
          if (partnershipOutcome != null)
            'partnership_outcome': partnershipOutcome,
        },
        nextState: {
          'partnership_outcome_recorded': partnershipOutcome != null,
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: partnershipOutcome == null
              ? 'form_partnership'
              : 'partnership_outcome_recorded',
          parameters: {
            'partnership_id': partnership.id,
            'status': partnership.status.name,
            if (partnershipOutcome != null) ...partnershipOutcome,
          },
        ),
        metadata: const {
          'phase_ref': '1.2.22',
          'pipeline': 'partnership_service',
        },
      );
      await store.writeTuple(tuple);
    } catch (e) {
      _logger.error('Error writing partnership tuple', error: e, tag: _logName);
    }
  }

  Future<void> _recordChatToPartnershipTuple({
    required EventPartnership partnership,
    required String eventCategory,
  }) async {
    final store = _episodicMemoryStore;
    if (store == null) return;
    try {
      final tuple = EpisodicTuple(
        agentId: partnership.businessId,
        stateBefore: {
          'phase_ref': '1.2.23',
          'chat_state': {
            'business_id': partnership.businessId,
            'expert_id': partnership.userId,
            'conversation_started': true,
          },
        },
        actionType: 'negotiate_terms',
        actionPayload: {
          'partnership_features': {
            'partnership_id': partnership.id,
            'event_id': partnership.eventId,
            'event_category': eventCategory,
            'status': partnership.status.name,
            'type': partnership.type.name,
            'vibe_compatibility_score': partnership.vibeCompatibilityScore,
          },
        },
        nextState: {
          'partnership_state': {
            'partnership_formed': true,
            'partnership_id': partnership.id,
            'status': partnership.status.name,
          },
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'partnership_formed',
          parameters: {
            'partnership_id': partnership.id,
            'event_id': partnership.eventId,
            'status': partnership.status.name,
          },
        ),
        metadata: const {
          'phase_ref': '1.2.23',
          'pipeline': 'partnership_service',
          'chain_stage': 'chat_to_partnership',
        },
      );
      await store.writeTuple(tuple);
    } catch (e) {
      _logger.error('Error writing chat->partnership tuple',
          error: e, tag: _logName);
    }
  }

  Future<void> _recordCoHostedEventTuple({
    required EventPartnership partnership,
    required String eventCategory,
    required int coHostedEventCount,
    required double revenueGenerated,
    required double businessSatisfactionRating,
    required double expertSatisfactionRating,
  }) async {
    final store = _episodicMemoryStore;
    if (store == null) return;
    try {
      final mutualSatisfaction =
          (businessSatisfactionRating + expertSatisfactionRating) / 2.0;
      final tuple = EpisodicTuple(
        agentId: partnership.businessId,
        stateBefore: {
          'phase_ref': '1.2.23',
          'partnership_state': {
            'partnership_id': partnership.id,
            'status': partnership.status.name,
          },
        },
        actionType: 'co_host_event',
        actionPayload: {
          'event_features': {
            'event_id': partnership.eventId,
            'event_category': eventCategory,
            'co_hosted_event_count': coHostedEventCount,
            'revenue_generated': revenueGenerated,
          },
        },
        nextState: {
          'event_outcome': {
            'mutual_satisfaction_rating': mutualSatisfaction,
            'business_satisfaction_rating': businessSatisfactionRating,
            'expert_satisfaction_rating': expertSatisfactionRating,
          },
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'event_outcome',
          parameters: {
            'partnership_id': partnership.id,
            'event_id': partnership.eventId,
            'overall_rating': mutualSatisfaction,
            'mutual_satisfaction_rating': mutualSatisfaction,
            'co_hosted_event_count': coHostedEventCount,
            'revenue_generated': revenueGenerated,
          },
        ),
        metadata: const {
          'phase_ref': '1.2.23',
          'pipeline': 'partnership_service',
          'chain_stage': 'partnership_to_event',
        },
      );
      await store.writeTuple(tuple);
    } catch (e) {
      _logger.error('Error writing co-host event tuple',
          error: e, tag: _logName);
    }
  }

  Future<List<EventPartnership>> _getAllPartnerships() async {
    // In production, query database
    return _partnerships.values.toList();
  }

  /// Validate status transition
  bool _isValidStatusTransition(
      PartnershipStatus current, PartnershipStatus next) {
    // Define valid transitions
    switch (current) {
      case PartnershipStatus.pending:
        return next == PartnershipStatus.proposed ||
            next == PartnershipStatus.cancelled;
      case PartnershipStatus.proposed:
        return next == PartnershipStatus.negotiating ||
            next == PartnershipStatus.approved ||
            next == PartnershipStatus.cancelled;
      case PartnershipStatus.negotiating:
        return next == PartnershipStatus.approved ||
            next == PartnershipStatus.cancelled;
      case PartnershipStatus.approved:
        return next == PartnershipStatus.locked ||
            next == PartnershipStatus.cancelled;
      case PartnershipStatus.locked:
        return next == PartnershipStatus.active ||
            next == PartnershipStatus.cancelled;
      case PartnershipStatus.active:
        return next == PartnershipStatus.completed ||
            next == PartnershipStatus.disputed;
      case PartnershipStatus.completed:
        return false; // Terminal state
      case PartnershipStatus.cancelled:
        return false; // Terminal state
      case PartnershipStatus.disputed:
        return next == PartnershipStatus.cancelled ||
            next == PartnershipStatus.completed;
    }
  }
}
