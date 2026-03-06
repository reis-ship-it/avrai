import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/admin/permissions/admin_access_control.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/services/admin/admin_god_mode_service.dart'
    as admin_models show AIDataSnapshot, ActiveAIAgentData, PredictionAction;
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_transition_store.dart';

/// Cache entry for AI snapshot data
class _CachedAISnapshot {
  final admin_models.AIDataSnapshot snapshot;
  final DateTime timestamp;

  _CachedAISnapshot(this.snapshot, this.timestamp);
}

/// Admin System Monitoring Service
/// Handles system monitoring and real-time streams
/// Phase 1.6: Extracted from AdminGodModeService
class AdminSystemMonitoringService {
  static const String _logName = 'AdminSystemMonitoringService';
  static const Duration _aiSnapshotCacheTTL = Duration(seconds: 5);

  final AdminAccessControl _accessControl;
  final SupabaseService _supabaseService;
  final PredictiveAnalytics _predictiveAnalytics;

  // Cache for AI data snapshots (5 second TTL)
  final Map<String, _CachedAISnapshot> _aiSnapshotCache = {};

  AdminSystemMonitoringService({
    required AdminAccessControl accessControl,
    required SupabaseService supabaseService,
    required PredictiveAnalytics predictiveAnalytics,
  })  : _accessControl = accessControl,
        _supabaseService = supabaseService,
        _predictiveAnalytics = predictiveAnalytics;

  /// Safely get Supabase client, returns null if not available
  dynamic _getSupabaseClient() {
    if (!_supabaseService.isAvailable) {
      developer.log('Supabase not available', name: _logName);
      return null;
    }
    try {
      return _supabaseService.tryGetClient();
    } catch (e) {
      developer.log('Error getting Supabase client: $e', name: _logName);
      return null;
    }
  }

  /// Get real-time AI data stream
  Stream<admin_models.AIDataSnapshot> watchAIData(String aiSignature) {
    _accessControl.requireAuthorization();

    final controller =
        StreamController<admin_models.AIDataSnapshot>.broadcast();

    // Start periodic updates
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final snapshot = await _fetchAIDataSnapshot(aiSignature);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in AI data stream: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Fetch AI data snapshot
  Future<admin_models.AIDataSnapshot> _fetchAIDataSnapshot(
      String aiSignature) async {
    // Check cache first
    final cached = _aiSnapshotCache[aiSignature];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _aiSnapshotCacheTTL) {
      return cached.snapshot;
    }

    try {
      // Extract user ID from AI signature (reverse of _generateAISignature)
      // This is a simplified approach - in production, you'd have a proper mapping
      // For now, we'll search for users and match by signature
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get all active users and generate signatures to find match
      // This is inefficient but works for admin monitoring
      final usersResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .gte(
              'updated_at',
              DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String())
          .limit(1000);

      final users = (usersResponse as List).cast<Map<String, dynamic>>();
      String? matchedUserId;

      // Find user with matching AI signature
      for (final userData in users) {
        final userId = userData['id'] as String;
        final generatedSignature = _generateAISignature(userId);
        if (generatedSignature == aiSignature) {
          matchedUserId = userId;
          break;
        }
      }

      if (matchedUserId == null) {
        // No matching user found, return minimal snapshot
        final snapshot = admin_models.AIDataSnapshot(
          aiSignature: aiSignature,
          isActive: false,
          connections: 0,
          data: {},
        );
        _aiSnapshotCache[aiSignature] =
            _CachedAISnapshot(snapshot, DateTime.now());
        return snapshot;
      }

      // Get user's connection count (simplified - would use ConnectionMonitor in production)
      final connectionsResponse = await client
          .from('user_connections')
          .select('id')
          .or('user_id_1.eq.$matchedUserId,user_id_2.eq.$matchedUserId');
      final connections = (connectionsResponse as List).length;

      // Build AI data snapshot
      final snapshot = admin_models.AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: true,
        connections: connections,
        data: {
          'user_id': matchedUserId,
          'ai_status': 'active',
          'last_active': DateTime.now().toIso8601String(),
        },
      );

      // Cache snapshot
      _aiSnapshotCache[aiSignature] =
          _CachedAISnapshot(snapshot, DateTime.now());

      // Clean up stale cache entries periodically
      _cleanupAISnapshotCache();

      return snapshot;
    } catch (e) {
      developer.log('Error fetching AI data snapshot: $e', name: _logName);
      // Return minimal snapshot on error
      return admin_models.AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: false,
        connections: 0,
        data: {},
      );
    }
  }

  /// Clean up stale cache entries
  void _cleanupAISnapshotCache() {
    final now = DateTime.now();
    _aiSnapshotCache.removeWhere((key, cached) =>
        now.difference(cached.timestamp) > _aiSnapshotCacheTTL);
  }

  /// Generate AI signature from user ID (deterministic but anonymized)
  String _generateAISignature(String userId) {
    // Create a deterministic hash from user ID
    // This ensures the same user always gets the same signature
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16); // Use first 16 chars
    return 'ai_$hash';
  }

  /// Phase 1.5E.10 — Markov engagement predictor health metrics.
  ///
  /// Returns aggregate cold-start quality metrics across the provided agent IDs.
  /// These are the primary beta ML health metrics before Phase 5 replaces the
  /// Markov chain with the neural TransitionPredictor.
  ///
  /// **Metrics surfaced:**
  /// - Average real observations per agent (higher = more personalized matrix)
  /// - % of agents past the 20-observation threshold (where personal matrix
  ///   contributes more than the 100-count synthetic prior)
  /// - Distribution of agents across [UserEngagementPhase] states
  ///
  /// **Scope:** On-device SharedPreferences only. Each device only holds data
  /// for the agents who have run on that device. Fleet-wide aggregation requires
  /// server-side telemetry (post-beta, Phase 5 readiness gate).
  Future<MarkovHealthReport> getMarkovHealthReport({
    required List<String> agentIds,
  }) async {
    _accessControl.requireAuthorization();

    final sl = GetIt.instance;
    final hasStore = sl.isRegistered<MarkovTransitionStore>();
    final hasPredictor = sl.isRegistered<EngagementPhasePredictor>();

    if (!hasStore || !hasPredictor || agentIds.isEmpty) {
      developer.log(
        'Markov health report: predictor not registered or no agents provided',
        name: _logName,
      );
      return MarkovHealthReport.empty();
    }

    try {
      final store = sl<MarkovTransitionStore>();
      final predictor = sl<EngagementPhasePredictor>();

      final phaseCounts = <UserEngagementPhase, int>{
        for (final p in UserEngagementPhase.values) p: 0,
      };
      int totalObservations = 0;
      int agentsAboveThreshold = 0;
      final List<AgentMarkovSummary> agentSummaries = [];

      for (final agentId in agentIds) {
        try {
          final observations = await store.totalRealObservations(agentId);
          totalObservations += observations;
          if (observations >= MarkovHealthReport.personalMatrixThreshold) {
            agentsAboveThreshold++;
          }

          // Classify current phase from the Markov next-phase distribution
          // (uses quietPeriod row as the conservative churn estimate)
          final churnRisk = await predictor.predictChurnRisk(agentId);
          final matrix = await store.getTransitionMatrix(agentId);

          // Determine most-probable current phase by inspecting which phase's
          // own row shows the highest self-continuation probability — this is
          // a proxy for "where the agent likely is now".
          UserEngagementPhase estimatedPhase = UserEngagementPhase.exploring;
          double bestSelfProb = -1.0;
          for (final phase in UserEngagementPhase.values) {
            final selfProb = matrix[phase]?[phase] ?? 0.0;
            if (selfProb > bestSelfProb) {
              bestSelfProb = selfProb;
              estimatedPhase = phase;
            }
          }

          phaseCounts[estimatedPhase] = (phaseCounts[estimatedPhase] ?? 0) + 1;

          agentSummaries.add(AgentMarkovSummary(
            agentId: agentId,
            realObservations: observations,
            estimatedPhase: estimatedPhase,
            churnRisk: churnRisk,
          ));
        } catch (e) {
          developer.log(
            'Error computing Markov health for agent $agentId: $e',
            name: _logName,
          );
        }
      }

      final validAgents = agentIds.length;
      final avgObservations =
          validAgents > 0 ? totalObservations / validAgents : 0.0;
      final pctAboveThreshold =
          validAgents > 0 ? agentsAboveThreshold / validAgents : 0.0;

      final report = MarkovHealthReport(
        agentCount: validAgents,
        averageRealObservations: avgObservations,
        percentAbovePersonalMatrixThreshold: pctAboveThreshold,
        phaseDistribution: Map.unmodifiable(phaseCounts),
        agentSummaries: List.unmodifiable(agentSummaries),
        generatedAt: DateTime.now(),
      );

      developer.log(
        'Markov health report: ${report.agentCount} agents, '
        'avg obs=${report.averageRealObservations.toStringAsFixed(1)}, '
        '${(report.percentAbovePersonalMatrixThreshold * 100).toStringAsFixed(0)}% above threshold, '
        'phase dist=${phaseCounts.entries.map((e) => "${e.key.name}=${e.value}").join(", ")}',
        name: _logName,
      );

      return report;
    } catch (e, st) {
      developer.log(
        'Error generating Markov health report: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return MarkovHealthReport.empty();
    }
  }

  /// Get all active AI agents with location and predictions
  /// Privacy-preserving: Returns AI agent data with location and predicted actions
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<admin_models.ActiveAIAgentData>> getAllActiveAIAgents() async {
    _accessControl.requireAuthorization();

    try {
      developer.log('Fetching all active AI agents', name: _logName);

      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      // Get all users who are active (updated within last hour)
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final usersResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .gte('updated_at', oneHourAgo.toIso8601String())
          .limit(1000); // Limit for performance

      final users = (usersResponse as List).cast<Map<String, dynamic>>();

      final activeAgents = <admin_models.ActiveAIAgentData>[];

      // Process each user to get AI agent data
      for (final userData in users) {
        final userId = userData['id'] as String;
        final updatedAt = DateTime.parse(userData['updated_at'] as String);
        final isOnline = now.difference(updatedAt).inHours < 1;

        // Generate AI signature
        final aiSignature = _generateAISignature(userId);

        // Get location data (if available)
        double? latitude;
        double? longitude;
        if (userData['location'] != null) {
          // Location format may vary - this is simplified
          // In production, you'd parse the actual location format
          // For now, use placeholder coordinates
          // TODO: Parse actual location string or use geocoding service
          latitude = 40.7128; // Default to NYC coordinates
          longitude = -74.0060;
        }

        // Get AI connections count
        int aiConnections = 0;
        try {
          final connectionsResponse = await client
              .from('user_connections')
              .select('id')
              .or('user_id_1.eq.$userId,user_id_2.eq.$userId');
          aiConnections = (connectionsResponse as List).length;
        } catch (e) {
          developer.log('Error fetching connections for user $userId: $e',
              name: _logName);
        }

        // Get predictions (simplified - would use actual PredictiveAnalytics in production)
        final predictions = <admin_models.PredictionAction>[];
        try {
          // Create minimal user object for predictions
          final user = User(
            id: userId,
            email: '',
            name: '',
            role: UserRole.user,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final journey = await _predictiveAnalytics.predictUserJourney(user);
          predictions.addAll(journey.predictedNextActions
              .map((a) => admin_models.PredictionAction(
                    action: a.action,
                    probability: a.probability,
                    category: a.category,
                  )));
        } catch (e) {
          developer.log('Error getting predictions for user $userId: $e',
              name: _logName);
        }

        // Only add if we have location data
        if (latitude != null && longitude != null) {
          activeAgents.add(admin_models.ActiveAIAgentData(
            userId: userId,
            aiSignature: aiSignature,
            latitude: latitude,
            longitude: longitude,
            isOnline: isOnline,
            lastActive: updatedAt,
            aiConnections: aiConnections,
            aiStatus: isOnline ? 'active' : 'inactive',
            predictedActions: predictions,
            currentStage: 'explorer', // Simplified
            confidence:
                predictions.isNotEmpty ? predictions.first.probability : 0.5,
          ));
        }
      }

      developer.log('Fetched ${activeAgents.length} active AI agents',
          name: _logName);
      return activeAgents;
    } catch (e) {
      developer.log('Error fetching active AI agents: $e', name: _logName);
      return [];
    }
  }
}

// -----------------------------------------------------------------------------
// Phase 1.5E.10 — Markov health report models
// -----------------------------------------------------------------------------

/// Aggregate cold-start quality metrics for the Markov engagement predictor.
///
/// Used by admin tooling to assess beta ML health before Phase 5 replaces the
/// Markov chain with the neural TransitionPredictor.
///
/// **When `percentAbovePersonalMatrixThreshold` approaches 1.0**, the synthetic
/// prior has decayed enough that predictions reflect real user behavior —
/// this is the primary readiness gate for Phase 5 training data sufficiency.
class MarkovHealthReport {
  /// Minimum real observations before personal matrix dominates the synthetic
  /// prior (at 20 obs, personal data is ~17% of weight; at 100 obs, ~50%).
  static const int personalMatrixThreshold = 20;

  /// Number of agents included in this report.
  final int agentCount;

  /// Mean real observations across all agents.
  final double averageRealObservations;

  /// Fraction of agents with ≥ [personalMatrixThreshold] real observations.
  final double percentAbovePersonalMatrixThreshold;

  /// Count of agents estimated to be in each [UserEngagementPhase].
  final Map<UserEngagementPhase, int> phaseDistribution;

  /// Per-agent breakdown (ordered as passed to [AdminSystemMonitoringService.getMarkovHealthReport]).
  final List<AgentMarkovSummary> agentSummaries;

  /// When this report was generated.
  final DateTime generatedAt;

  const MarkovHealthReport({
    required this.agentCount,
    required this.averageRealObservations,
    required this.percentAbovePersonalMatrixThreshold,
    required this.phaseDistribution,
    required this.agentSummaries,
    required this.generatedAt,
  });

  /// Empty report returned when the predictor is not registered or no agents
  /// were provided. Safe to display in the admin UI without null guards.
  factory MarkovHealthReport.empty() => MarkovHealthReport(
        agentCount: 0,
        averageRealObservations: 0.0,
        percentAbovePersonalMatrixThreshold: 0.0,
        phaseDistribution: {
          for (final p in UserEngagementPhase.values) p: 0,
        },
        agentSummaries: const [],
        generatedAt: DateTime.now(),
      );
}

/// Per-agent Markov chain summary within a [MarkovHealthReport].
class AgentMarkovSummary {
  /// Privacy-protected agent identifier.
  final String agentId;

  /// Total real phase transitions observed for this agent.
  final int realObservations;

  /// Best-estimate current engagement phase from the transition matrix.
  final UserEngagementPhase estimatedPhase;

  /// Churn risk within 7 days (0.0–1.0). > 0.6 triggers re-engagement gate.
  final double churnRisk;

  const AgentMarkovSummary({
    required this.agentId,
    required this.realObservations,
    required this.estimatedPhase,
    required this.churnRisk,
  });
}
