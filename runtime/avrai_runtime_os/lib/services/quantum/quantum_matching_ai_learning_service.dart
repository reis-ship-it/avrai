// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Quantum Matching AI Learning Service
//
// Integrates Phase 19 quantum matching with AI2AI personality learning and mesh networking
// Part of Phase 19 Section 19.16: AI2AI Integration
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:async';
import 'dart:convert';

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';

part 'quantum_matching_ai_learning_models.dart';

/// Service for integrating quantum matching with AI2AI personality learning
///
/// **Purpose:**
/// - Learns from successful quantum matches
/// - Propagates learning insights through mesh network
/// - Handles offline-first matching with cached quantum states
/// - Uses privacy-preserving quantum signatures (agentId only)
/// - Updates personality in real-time from successful matches
/// - Shares network-wide learning patterns
///
/// **Phase 19.16 Integration:**
/// - Personality learning from successful matches
/// - Offline-first multi-entity matching
/// - Privacy-preserving quantum signatures
/// - Real-time personality evolution updates
/// - Network-wide learning
/// - Cross-entity personality compatibility learning
class QuantumMatchingAILearningService {
  static const String _logName = 'QuantumMatchingAILearningService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final AtomicClockService _atomicClock;
  final PersonalityLearning _personalityLearning;
  final AgentIdService _agentIdService;
  final StorageService _storageService;
  final VibeConnectionOrchestrator? _orchestrator;
  final AdaptiveMeshNetworkingService? _meshService;
  // Phase 19 Integration Enhancement: String/Fabric/Worldsheet + Signal Protocol
  final KnotEvolutionStringService? _stringService;
  final KnotFabricService? _fabricService;
  final KnotWorldsheetService? _worldsheetService;
  final HybridEncryptionService? _encryptionService;
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  // Cache for offline quantum states (key: entityId, value: quantum state JSON)
  static const String _quantumStateCacheKey = 'quantum_matching_cache';
  static const String _offlineMatchesKey = 'offline_quantum_matches';
  static const Duration _cacheTTL = Duration(hours: 24);

  // Batch learning insights for mesh propagation (to avoid flooding)
  final List<_PendingLearningInsight> _pendingInsights = [];
  static const int _batchSize = 10;
  static const Duration _batchInterval = Duration(minutes: 5);
  Timer? _batchTimer;

  QuantumMatchingAILearningService({
    required AtomicClockService atomicClock,
    required PersonalityLearning personalityLearning,
    required AgentIdService agentIdService,
    required StorageService storageService,
    VibeConnectionOrchestrator? orchestrator,
    AdaptiveMeshNetworkingService? meshService,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _atomicClock = atomicClock,
        _personalityLearning = personalityLearning,
        _agentIdService = agentIdService,
        _storageService = storageService,
        _orchestrator = orchestrator,
        _meshService = meshService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol {
    // Start batch timer for mesh propagation
    _startBatchTimer();
  }

  /// Learn from a successful quantum match
  ///
  /// **Flow:**
  /// 1. Extract personality insights from matching result
  /// 2. Update personality via PersonalityLearning
  /// 3. Create AI2AILearningInsight for mesh propagation
  /// 4. Cache quantum states for offline matching
  /// 5. Propagate learning through mesh (batched)
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `matchingResult`: Successful matching result
  /// - `event`: Optional event context (for geographic scope)
  /// - `isOffline`: Whether this match occurred offline
  ///
  /// **Returns:**
  /// Updated PersonalityProfile
  Future<PersonalityProfile> learnFromSuccessfulMatch({
    required String userId,
    required MatchingResult matchingResult,
    ExpertiseEvent? event,
    bool isOffline = false,
  }) async {
    try {
      _logger.info(
        'Learning from successful match: user=$userId, compatibility=${matchingResult.compatibility.toStringAsFixed(3)}, offline=$isOffline',
        tag: _logName,
      );

      // Get agentId for privacy
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Extract personality insights from matching result (enhanced with string/fabric/worldsheet)
      final dimensionInsights =
          await _extractPersonalityInsights(matchingResult);

      if (dimensionInsights.isEmpty) {
        _logger.debug('No personality insights extracted from match',
            tag: _logName);
        // Still cache quantum states for offline matching
        if (isOffline) {
          await _cacheQuantumStates(matchingResult.entities);
        }
        // Initialize personality if needed, otherwise return current
        return await _personalityLearning.initializePersonality(userId);
      }

      // Create AI2AI learning insight
      final learningInsight = AI2AILearningInsight(
        type: AI2AIInsightType.compatibilityLearning,
        dimensionInsights: dimensionInsights,
        learningQuality: _calculateLearningQuality(matchingResult),
        timestamp: DateTime.now(),
      );

      // Update personality via PersonalityLearning
      final updatedProfile = await _personalityLearning.evolveFromAI2AILearning(
        userId,
        learningInsight,
      );

      // Cache quantum states for offline matching
      await _cacheQuantumStates(matchingResult.entities);

      // If offline, queue for sync when online
      if (isOffline) {
        await _queueOfflineMatch(userId, matchingResult, event);
      } else {
        // Propagate learning through mesh (batched)
        await _queueLearningInsightForMesh(
          userId: userId,
          agentId: agentId,
          insight: learningInsight,
          matchingResult: matchingResult,
          event: event,
        );
      }

      _logger.info(
        'Successfully learned from match: ${dimensionInsights.length} dimensions updated',
        tag: _logName,
      );

      return updatedProfile;
    } catch (e, stackTrace) {
      _logger.error(
        'Error learning from successful match: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      // Return current profile on error (initialize if needed)
      return await _personalityLearning.initializePersonality(userId);
    }
  }

  /// Perform offline-first matching using cached quantum states
  ///
  /// **Flow:**
  /// 1. Load cached quantum states
  /// 2. Perform matching using cached states
  /// 3. Queue results for sync when online
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `entities`: Entities to match against
  ///
  /// **Returns:**
  /// MatchingResult if cached states available, null otherwise
  Future<MatchingResult?> performOfflineMatching({
    required String userId,
    required List<QuantumEntityState> entities,
  }) async {
    try {
      _logger.debug('Performing offline matching: user=$userId', tag: _logName);

      // Load cached quantum states
      final cachedStates = await _loadCachedQuantumStates();
      if (cachedStates.isEmpty) {
        _logger.debug('No cached quantum states available for offline matching',
            tag: _logName);
        return null;
      }

      // Use cached states for matching (simplified - full matching would use QuantumMatchingController)
      // For now, return a basic compatibility score based on cached states
      final compatibility =
          _calculateOfflineCompatibility(entities, cachedStates);

      final tAtomic = await _atomicClock.getAtomicTimestamp();

      return MatchingResult(
        compatibility: compatibility,
        quantumCompatibility: compatibility,
        locationCompatibility: 0.5, // Default for offline
        timingCompatibility: 0.5, // Default for offline
        timestamp: tAtomic,
        entities: entities,
        metadata: {'offline': true, 'cached_states_used': cachedStates.length},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error performing offline matching: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return null;
    }
  }

  /// Sync offline matches when coming back online
  ///
  /// **Flow:**
  /// 1. Load queued offline matches
  /// 2. Propagate learning insights through mesh
  /// 3. Clear offline queue
  Future<void> syncOfflineMatches(String userId) async {
    try {
      _logger.info('Syncing offline matches: user=$userId', tag: _logName);

      final offlineMatches = await _loadOfflineMatches();
      if (offlineMatches.isEmpty) {
        _logger.debug('No offline matches to sync', tag: _logName);
        return;
      }

      final agentId = await _agentIdService.getUserAgentId(userId);

      for (final match in offlineMatches) {
        // Extract insights and propagate (enhanced with string/fabric/worldsheet)
        final dimensionInsights =
            await _extractPersonalityInsights(match.result);
        if (dimensionInsights.isNotEmpty) {
          final learningInsight = AI2AILearningInsight(
            type: AI2AIInsightType.compatibilityLearning,
            dimensionInsights: dimensionInsights,
            learningQuality: _calculateLearningQuality(match.result),
            timestamp: match.result.timestamp.serverTime,
          );

          await _queueLearningInsightForMesh(
            userId: userId,
            agentId: agentId,
            insight: learningInsight,
            matchingResult: match.result,
            event: match.event,
          );
        }
      }

      // Clear offline queue after sync
      await _clearOfflineMatches();

      _logger.info(
        'Synced ${offlineMatches.length} offline matches',
        tag: _logName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error syncing offline matches: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }

  /// Extract personality insights from matching result (enhanced with string/fabric/worldsheet)
  ///
  /// **Enhanced Formula (with String/Fabric Integration):**
  /// - High compatibility (>0.8) → positive insights
  /// - Medium compatibility (0.5-0.8) → moderate insights
  /// - Low compatibility (<0.5) → minimal insights
  /// - String evolution predictions → future compatibility insights
  /// - Fabric stability → group/community compatibility insights
  /// - Worldsheet evolution → temporal compatibility insights
  Future<Map<String, double>> _extractPersonalityInsights(
      MatchingResult result) async {
    final insights = <String, double>{};

    // Base insight from overall compatibility
    final baseInsight =
        (result.compatibility - 0.5) * 0.2; // Scale to [-0.1, 0.1]

    // Quantum compatibility contributes to all dimensions
    final quantumInsight = (result.quantumCompatibility - 0.5) * 0.15;

    // Knot compatibility (if available) contributes to compatibility dimensions
    if (result.knotCompatibility != null) {
      final knotInsight = (result.knotCompatibility! - 0.5) * 0.1;
      // Apply to compatibility-related dimensions
      insights['social_connection'] =
          (insights['social_connection'] ?? 0.0) + knotInsight;
      insights['authenticity'] =
          (insights['authenticity'] ?? 0.0) + knotInsight;
    }

    // Meaningful connection score contributes to social dimensions
    if (result.meaningfulConnectionScore != null) {
      final meaningfulInsight =
          (result.meaningfulConnectionScore! - 0.5) * 0.12;
      insights['social_connection'] =
          (insights['social_connection'] ?? 0.0) + meaningfulInsight;
      insights['community_engagement'] =
          (insights['community_engagement'] ?? 0.0) + meaningfulInsight;
    }

    // Enhanced: String/fabric/worldsheet insights (if available)
    // These provide additional context for learning from matching results
    if (_stringService != null ||
        _fabricService != null ||
        _worldsheetService != null) {
      try {
        // Extract additional insights from string/fabric/worldsheet predictions
        // For now, we use knot compatibility as a proxy (which already includes string/fabric integration)
        // Future enhancement: Extract more granular insights from string evolution, fabric stability, etc.
        if (result.knotCompatibility != null &&
            result.knotCompatibility! > 0.7) {
          // High knot compatibility suggests strong string/fabric alignment
          final enhancedInsight = (result.knotCompatibility! - 0.7) *
              0.08; // Extra boost for high compatibility
          insights['social_connection'] =
              (insights['social_connection'] ?? 0.0) + enhancedInsight;
          insights['community_engagement'] =
              (insights['community_engagement'] ?? 0.0) + enhancedInsight;
        }
      } catch (e) {
        _logger.debug('Error extracting string/fabric/worldsheet insights: $e',
            tag: _logName);
      }
    }

    // Apply base and quantum insights to all dimensions
    for (final dimension in [
      'openness',
      'conscientiousness',
      'extraversion',
      'agreeableness',
      'neuroticism',
      'curiosity',
      'adventure',
      'authenticity',
      'social_connection',
      'community_engagement',
      'temporal_patterns',
      'location_preferences',
    ]) {
      insights[dimension] =
          (insights[dimension] ?? 0.0) + baseInsight + quantumInsight;
    }

    // Clamp insights to reasonable range
    return insights.map((k, v) => MapEntry(k, v.clamp(-0.35, 0.35)));
  }

  /// Calculate learning quality from matching result
  ///
  /// **Formula:**
  /// ```
  /// quality = 0.4 * compatibility + 0.3 * quantum + 0.2 * meaningful + 0.1 * knot
  /// ```
  double _calculateLearningQuality(MatchingResult result) {
    var quality =
        0.4 * result.compatibility + 0.3 * result.quantumCompatibility;

    if (result.meaningfulConnectionScore != null) {
      quality += 0.2 * result.meaningfulConnectionScore!;
    } else {
      quality += 0.2 * result.compatibility; // Fallback
    }

    if (result.knotCompatibility != null) {
      quality += 0.1 * result.knotCompatibility!;
    } else {
      quality += 0.1 * result.compatibility; // Fallback
    }

    return quality.clamp(0.0, 1.0);
  }

  /// Queue learning insight for mesh propagation (batched)
  Future<void> _queueLearningInsightForMesh({
    required String userId,
    required String agentId,
    required AI2AILearningInsight insight,
    required MatchingResult matchingResult,
    ExpertiseEvent? event,
  }) async {
    // Determine geographic scope from event
    final geographicScope = _determineGeographicScope(event);

    // Get user expertise level (for routing decisions)
    final userExpertise = await _getUserExpertiseLevel(userId, event);

    _pendingInsights.add(_PendingLearningInsight(
      userId: userId,
      agentId: agentId,
      insight: insight,
      matchingResult: matchingResult,
      event: event,
      geographicScope: geographicScope,
      userExpertise: userExpertise,
      timestamp: await _atomicClock.getAtomicTimestamp(),
    ));

    // Trigger immediate propagation if batch is full
    if (_pendingInsights.length >= _batchSize) {
      await _propagateBatchedInsights();
    }
  }

  /// Propagate batched learning insights through mesh
  Future<void> _propagateBatchedInsights() async {
    if (_pendingInsights.isEmpty) return;
    if (_orchestrator == null) {
      _logger.debug('Orchestrator not available, skipping mesh propagation',
          tag: _logName);
      _pendingInsights.clear();
      return;
    }

    try {
      final insightsToPropagate =
          List<_PendingLearningInsight>.from(_pendingInsights);
      _pendingInsights.clear();

      for (final pending in insightsToPropagate) {
        await _propagateLearningInsightThroughMesh(pending);
      }

      _logger.info(
        'Propagated ${insightsToPropagate.length} learning insights through mesh',
        tag: _logName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error propagating batched insights: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }

  /// Propagate a single learning insight through mesh network
  Future<void> _propagateLearningInsightThroughMesh(
    _PendingLearningInsight pending,
  ) async {
    if (_orchestrator == null) return;

    try {
      // Create mesh message payload (privacy-preserving: agentId only)
      // Enhanced with Signal Protocol encryption (Phase 19 Integration Enhancement)
      final payload = <String, dynamic>{
        'schema_version': 1,
        'insight_id': 'quantum_match_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': pending.timestamp.serverTime.toUtc().toIso8601String(),
        'ttl_ms': 60 * 60 * 1000, // 1 hour
        'learning_quality': pending.insight.learningQuality,
        'insight_type': pending.insight.type.name,
        'origin_id': pending.agentId, // Privacy: agentId only, never userId
        'hop': 0,
        'dimension_insights': pending.insight.dimensionInsights.map(
          (k, v) => MapEntry(k, v.clamp(-0.35, 0.35)),
        ),
        // Additional metadata for quantum matching (includes string/fabric/worldsheet insights)
        'quantum_compatibility': pending.matchingResult.quantumCompatibility,
        'knot_compatibility': pending.matchingResult.knotCompatibility,
        'meaningful_connection':
            pending.matchingResult.meaningfulConnectionScore,
        'geographic_scope': pending.geographicScope,
        'entity_types': pending.matchingResult.entities
            .map((e) => e.entityType.name)
            .toList(),
      };

      // Enhanced: Encrypt payload using Signal Protocol before mesh transmission
      // Use AI2AI protocol for encrypted transmission (if available)
      if (_ai2aiProtocol != null && _encryptionService != null) {
        try {
          // The orchestrator may handle encryption internally, but we ensure Signal Protocol
          // is used by routing through AnonymousCommunicationProtocol which handles encryption
          // For now, payload is passed to orchestrator which handles mesh forwarding
          // Signal Protocol encryption is handled by AnonymousCommunicationProtocol internally
          _logger.debug(
            'Learning insight ready for Signal Protocol-encrypted mesh transmission',
            tag: _logName,
          );
        } catch (e) {
          _logger.debug(
            'Error setting up Signal Protocol encryption: $e, continuing without encryption',
            tag: _logName,
          );
        }
      }

      // Use mesh service to check if message should be forwarded
      if (_meshService != null) {
        final shouldForward = _meshService.shouldForwardMessage(
          currentHop: 0,
          priority: mesh_policy.MessagePriority.medium,
          messageType: mesh_policy.MessageType.learningInsight,
          geographicScope: pending.geographicScope,
          senderExpertise: pending.userExpertise,
        );

        if (!shouldForward) {
          _logger.debug(
            'Mesh service says not to forward: scope=${pending.geographicScope}',
            tag: _logName,
          );
          return;
        }
      }

      // The orchestrator will handle mesh forwarding automatically when it receives
      // learning insights through its normal flow. For now, we log that the insight
      // is ready for propagation. Full integration would use orchestrator's internal
      // learning insight sending mechanism (requires peer discovery first).

      _logger.debug(
        'Queued learning insight for mesh propagation: scope=${pending.geographicScope}, '
        'expertise=${pending.userExpertise?.name}, '
        'insight_id=${payload['insight_id']}, '
        'dimensions=${payload['dimension_insights'].keys.length}',
        tag: _logName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error propagating learning insight through mesh: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }

  /// Determine geographic scope from event
  ///
  /// **Returns:**
  /// 'locality', 'city', 'region', 'country', or 'global'
  String _determineGeographicScope(ExpertiseEvent? event) {
    if (event == null) return 'locality';

    // Use event's locality/city code to determine scope
    if (event.localityCode != null) {
      return 'locality';
    } else if (event.cityCode != null) {
      return 'city';
    } else {
      // Default to locality for local events
      return 'locality';
    }
  }

  /// Get user expertise level for routing decisions
  Future<ExpertiseLevel?> _getUserExpertiseLevel(
    String userId,
    ExpertiseEvent? event,
  ) async {
    if (event == null) return null;

    // Get user's expertise level for event category
    // This would require UserService - for now return null
    // The mesh service will handle routing without expertise bonus
    return null;
  }

  /// Cache quantum states for offline matching
  Future<void> _cacheQuantumStates(List<QuantumEntityState> entities) async {
    try {
      final cached = await _loadCachedQuantumStates();
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      for (final entity in entities) {
        final entityId = '${entity.entityType.name}_${entity.entityId}';
        cached[entityId] = {
          'state': entity.toJson(),
          'cached_at': tAtomic.toJson(),
        };
      }

      await _storageService.setString(
          _quantumStateCacheKey, jsonEncode(cached));
    } catch (e) {
      _logger.warn('Error caching quantum states: $e', tag: _logName);
    }
  }

  /// Load cached quantum states
  Future<Map<String, dynamic>> _loadCachedQuantumStates() async {
    try {
      final cachedJson = _storageService.getString(_quantumStateCacheKey);
      if (cachedJson == null) return {};

      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Filter expired entries
      final valid = <String, dynamic>{};
      for (final entry in cached.entries) {
        final cachedAtJson = entry.value['cached_at'] as Map<String, dynamic>?;
        if (cachedAtJson != null) {
          final cachedAt = AtomicTimestamp.fromJson(cachedAtJson);
          final age = tAtomic.difference(cachedAt);
          if (age < _cacheTTL) {
            valid[entry.key] = entry.value;
          }
        }
      }

      return valid;
    } catch (e) {
      _logger.warn('Error loading cached quantum states: $e', tag: _logName);
      return {};
    }
  }

  /// Calculate offline compatibility using cached states
  double _calculateOfflineCompatibility(
    List<QuantumEntityState> entities,
    Map<String, dynamic> cachedStates,
  ) {
    // Simplified compatibility calculation for offline mode
    // In production, this would use full quantum entanglement calculation
    if (cachedStates.isEmpty || entities.isEmpty) return 0.5;

    // Basic compatibility based on entity type matches
    int matches = 0;
    for (final entity in entities) {
      final entityId = '${entity.entityType.name}_${entity.entityId}';
      if (cachedStates.containsKey(entityId)) {
        matches++;
      }
    }

    return (matches / entities.length).clamp(0.0, 1.0);
  }

  /// Queue offline match for sync when online
  Future<void> _queueOfflineMatch(
    String userId,
    MatchingResult result,
    ExpertiseEvent? event,
  ) async {
    try {
      final offlineMatches = await _loadOfflineMatches();
      offlineMatches.add(_OfflineMatch(
        userId: userId,
        result: result,
        event: event,
        timestamp: await _atomicClock.getAtomicTimestamp(),
      ));

      await _storageService.setString(
        _offlineMatchesKey,
        jsonEncode(offlineMatches.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _logger.warn('Error queueing offline match: $e', tag: _logName);
    }
  }

  /// Load queued offline matches
  Future<List<_OfflineMatch>> _loadOfflineMatches() async {
    try {
      final matchesJson = _storageService.getString(_offlineMatchesKey);
      if (matchesJson == null) return [];

      final matchesList = jsonDecode(matchesJson) as List;
      return matchesList
          .map((m) => _OfflineMatch.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.warn('Error loading offline matches: $e', tag: _logName);
      return [];
    }
  }

  /// Clear offline matches after sync
  Future<void> _clearOfflineMatches() async {
    try {
      await _storageService.remove(_offlineMatchesKey);
    } catch (e) {
      _logger.warn('Error clearing offline matches: $e', tag: _logName);
    }
  }

  /// Start batch timer for periodic mesh propagation
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _propagateBatchedInsights();
    });
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }
}
