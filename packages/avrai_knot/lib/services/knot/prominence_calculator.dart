// Prominence Calculator Service
// 
// Calculates prominence scores for entities in fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/prominence_score.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Service for calculating prominence scores
/// 
/// Prominence is calculated from:
/// - Activity level (engagement, interactions)
/// - Status score (influence, centrality)
/// - Temporal relevance (recent activity, time-based)
/// - Connection strength (total/average connections)
class ProminenceCalculator {
  static const String _logName = 'ProminenceCalculator';
  
  // Component weights (sum to 1.0)
  static const double _activityWeight = 0.25;
  static const double _statusWeight = 0.25;
  static const double _temporalWeight = 0.25;
  static const double _connectionWeight = 0.25;
  
  // Temporal relevance parameters
  static const double _timeScale = 86400000.0; // 1 day in milliseconds
  static const double _recentRelevanceTau = 604800000.0; // 1 week in milliseconds

  final AtomicClockService _atomicClock;

  ProminenceCalculator({
    required AtomicClockService atomicClock,
  }) : _atomicClock = atomicClock;

  /// Calculate prominence score for an entity in fabric cluster
  Future<ProminenceScore> calculateProminenceScore({
    required EntityKnot entity,
    required List<EntityKnot> cluster,
    required KnotFabric fabric,
  }) async {
    developer.log(
      'Calculating prominence for entity: ${entity.entityId}',
      name: _logName,
    );

    // Calculate all components (all normalized to [0, 1])
    final activityLevel = await _calculateNormalizedActivityLevel(entity, cluster);
    final statusScore = await _calculateNormalizedStatusScore(entity, fabric);
    final temporalRelevance = await _calculateNormalizedTemporalRelevance(entity);
    final connectionStrength = await _calculateNormalizedConnectionStrength(
      entity,
      cluster,
    );

    // Weighted sum: α·activity + β·status + γ·temporal + δ·connection
    final score = (_activityWeight * activityLevel) +
        (_statusWeight * statusScore) +
        (_temporalWeight * temporalRelevance) +
        (_connectionWeight * connectionStrength);

    final components = ProminenceComponents(
      activityLevel: activityLevel,
      statusScore: statusScore,
      temporalRelevance: temporalRelevance,
      connectionStrength: connectionStrength,
    );

    return ProminenceScore(
      score: score.clamp(0.0, 1.0),
      components: components,
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate normalized activity level
  /// 
  /// Activity is based on:
  /// - Engagement metrics (if available in metadata)
  /// - Interaction frequency
  /// - Relative activity within cluster
  Future<double> _calculateNormalizedActivityLevel(
    EntityKnot entity,
    List<EntityKnot> cluster,
  ) async {
    // Extract activity metrics from metadata
    final engagementScore = entity.metadata['engagementScore'] as double? ?? 0.0;
    final interactionCount = entity.metadata['interactionCount'] as int? ?? 0;
    
    // Normalize interaction count (max 100 interactions = 1.0)
    final normalizedInteractions = (interactionCount / 100.0).clamp(0.0, 1.0);
    
    // Combine engagement and interactions (weighted)
    final activityScore = (0.6 * engagementScore) + (0.4 * normalizedInteractions);
    
    // Normalize relative to cluster
    if (cluster.isEmpty) {
      return activityScore;
    }
    
    final clusterActivities = cluster.map((e) {
      final eEngagement = e.metadata['engagementScore'] as double? ?? 0.0;
      final eInteractions = e.metadata['interactionCount'] as int? ?? 0;
      final eNormalized = (eInteractions / 100.0).clamp(0.0, 1.0);
      return (0.6 * eEngagement) + (0.4 * eNormalized);
    }).toList();
    
    final maxActivity = clusterActivities.isEmpty
        ? 1.0
        : clusterActivities.reduce(math.max);
    
    return maxActivity > 0.0 ? (activityScore / maxActivity).clamp(0.0, 1.0) : 0.0;
  }

  /// Calculate normalized status score
  /// 
  /// Status is based on:
  /// - Network centrality (position in fabric)
  /// - Influence metrics
  /// - Relative status within fabric
  Future<double> _calculateNormalizedStatusScore(
    EntityKnot entity,
    KnotFabric fabric,
  ) async {
    // Extract status metrics from metadata
    final influenceScore = entity.metadata['influenceScore'] as double? ?? 0.0;
    final centralityScore = entity.metadata['centralityScore'] as double? ?? 0.0;
    
    // Calculate fabric-based centrality
    final fabricCentrality = _calculateFabricCentrality(entity, fabric);
    
    // Combine metrics (weighted)
    final statusScore = (0.4 * influenceScore) +
        (0.3 * centralityScore) +
        (0.3 * fabricCentrality);
    
    return statusScore.clamp(0.0, 1.0);
  }

  /// Calculate fabric-based centrality
  double _calculateFabricCentrality(EntityKnot entity, KnotFabric fabric) {
    // Find entity's position in fabric
    final entityIndex = fabric.userKnots.indexWhere(
      (knot) => knot.agentId == entity.entityId,
    );
    
    if (entityIndex == -1) {
      return 0.0;
    }
    
    // Calculate centrality based on fabric invariants
    // Higher stability and density indicate better centrality
    final stability = fabric.invariants.stability;
    final density = fabric.invariants.density;
    
    // Entities in more stable, dense fabrics have higher centrality
    return ((stability + density) / 2.0).clamp(0.0, 1.0);
  }

  /// Calculate normalized temporal relevance
  /// 
  /// Temporal relevance uses atomic time:
  /// - time_prominence = exp(-|time_distance(current, peak_activity)| / time_scale)
  /// - recent_relevance = exp(-Δt_atomic / τ)
  Future<double> _calculateNormalizedTemporalRelevance(EntityKnot entity) async {
    final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
    
    // Get peak activity time from metadata
    final peakActivityTime = entity.metadata['peakActivityTime'] as String?;
    DateTime? peakTime;
    if (peakActivityTime != null) {
      try {
        peakTime = DateTime.parse(peakActivityTime);
      } catch (e) {
        developer.log(
          'Error parsing peakActivityTime: $e',
          name: _logName,
        );
      }
    }
    
    // Calculate time prominence
    double timeProminence = 0.5; // Default if no peak time
    if (peakTime != null) {
      final timeDistance = (atomicTimestamp.serverTime.millisecondsSinceEpoch -
              peakTime.millisecondsSinceEpoch)
          .abs();
      timeProminence = math.exp(-timeDistance / _timeScale);
    }
    
    // Calculate recent relevance
    final lastUpdated = entity.lastUpdated;
    final timeDelta = (atomicTimestamp.serverTime.millisecondsSinceEpoch -
            lastUpdated.millisecondsSinceEpoch)
        .abs();
    final recentRelevance = math.exp(-timeDelta / _recentRelevanceTau);
    
    // Combine (weighted)
    return ((0.5 * timeProminence) + (0.5 * recentRelevance)).clamp(0.0, 1.0);
  }

  /// Calculate normalized connection strength
  /// 
  /// Connection strength is based on:
  /// - Number of connections to other entities in cluster
  /// - Average connection strength
  /// - Relative connection strength within cluster
  Future<double> _calculateNormalizedConnectionStrength(
    EntityKnot entity,
    List<EntityKnot> cluster,
  ) async {
    // Extract connection metrics from metadata
    final connectionCount = entity.metadata['connectionCount'] as int? ?? 0;
    final avgConnectionStrength = entity.metadata['avgConnectionStrength'] as double? ?? 0.0;
    
    // Normalize connection count (max 50 connections = 1.0)
    final normalizedCount = (connectionCount / 50.0).clamp(0.0, 1.0);
    
    // Combine count and strength (weighted)
    final connectionScore = (0.5 * normalizedCount) + (0.5 * avgConnectionStrength);
    
    // Normalize relative to cluster
    if (cluster.isEmpty) {
      return connectionScore;
    }
    
    final clusterConnections = cluster.map((e) {
      final eCount = e.metadata['connectionCount'] as int? ?? 0;
      final eStrength = e.metadata['avgConnectionStrength'] as double? ?? 0.0;
      final eNormalized = (eCount / 50.0).clamp(0.0, 1.0);
      return (0.5 * eNormalized) + (0.5 * eStrength);
    }).toList();
    
    final maxConnection = clusterConnections.isEmpty
        ? 1.0
        : clusterConnections.reduce(math.max);
    
    return maxConnection > 0.0
        ? (connectionScore / maxConnection).clamp(0.0, 1.0)
        : 0.0;
  }
}
