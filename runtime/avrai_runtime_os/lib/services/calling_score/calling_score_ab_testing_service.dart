// Calling Score A/B Testing Service for Phase 12: Neural Network Implementation
// Section 2.3: A/B Testing Framework
// Manages A/B testing between formula-based and hybrid calling score systems

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Calling Score A/B Testing Service
///
/// Manages A/B testing between formula-based and hybrid calling score systems.
///
/// Phase 12 Section 2.3: A/B Testing Framework
/// - Splits users: 50% formula-based, 50% hybrid
/// - Tracks outcomes for both groups
/// - Measures improvement in outcome rates
class CallingScoreABTestingService {
  static const String _logName = 'CallingScoreABTestingService';

  final SupabaseClient _supabase;
  final AgentIdService _agentIdService;

  // A/B test configuration
  static const double hybridGroupPercentage =
      0.5; // 50% hybrid, 50% formula-based

  CallingScoreABTestingService({
    required SupabaseClient supabase,
    required AgentIdService agentIdService,
  })  : _supabase = supabase,
        _agentIdService = agentIdService;

  /// Determine which group a user belongs to (formula-based or hybrid)
  ///
  /// Uses consistent hashing based on agentId to ensure users stay in the same group
  ///
  /// **Parameters:**
  /// - `userId`: User ID (required)
  ///
  /// **Returns:**
  /// `ABTestGroup.formulaBased` or `ABTestGroup.hybrid`
  Future<ABTestGroup> getUserGroup({required String userId}) async {
    try {
      // Get agentId for consistent hashing
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Use consistent hashing to assign group
      final hash = sha256.convert(utf8.encode(agentId));
      final hashValue = hash.bytes.first;

      // Assign to hybrid group if hash value is in bottom 50%
      final isHybrid =
          hashValue < 128; // 0-127 = hybrid, 128-255 = formula-based

      final group = isHybrid ? ABTestGroup.hybrid : ABTestGroup.formulaBased;

      developer.log(
        'User assigned to A/B test group: $group (agentId: $agentId)',
        name: _logName,
      );

      return group;
    } catch (e, stackTrace) {
      developer.log(
        'Error determining user group, defaulting to formula-based: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Default to formula-based on error
      return ABTestGroup.formulaBased;
    }
  }

  /// Log A/B test outcome
  ///
  /// Records the outcome of a calling score calculation for A/B testing analysis
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `opportunityId`: Opportunity ID (spot/event/etc.)
  /// - `group`: A/B test group (formula-based or hybrid)
  /// - `callingScore`: Calculated calling score
  /// - `isCalled`: Whether user was "called" (score >= 0.70)
  /// - `outcome`: Outcome result (if available)
  Future<void> logABTestOutcome({
    required String userId,
    required String opportunityId,
    required ABTestGroup group,
    required double callingScore,
    required bool isCalled,
    OutcomeResult? outcome,
  }) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Log outcome to database
      await _supabase.from('calling_score_ab_test_outcomes').insert({
        'agent_id': agentId,
        'opportunity_id': opportunityId,
        'test_group': group.name,
        'calling_score': callingScore,
        'is_called': isCalled,
        'outcome_type': outcome?.type,
        'outcome_score': outcome?.score,
        'timestamp': DateTime.now().toIso8601String(),
      });

      developer.log(
        'A/B test outcome logged: group=$group, score=${(callingScore * 100).toStringAsFixed(1)}%, '
        'called=$isCalled, outcome=${outcome?.type ?? "none"}',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error logging A/B test outcome: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal error, don't throw
    }
  }

  /// Get A/B test metrics
  ///
  /// Returns aggregated metrics comparing formula-based vs hybrid groups
  ///
  /// **Returns:**
  /// A/B test metrics with comparison between groups
  Future<ABTestMetrics> getABTestMetrics() async {
    try {
      // Get outcomes for formula-based group
      final formulaOutcomes = await _supabase
          .from('calling_score_ab_test_outcomes')
          .select('*')
          .eq('test_group', 'formulaBased');

      // Get outcomes for hybrid group
      final hybridOutcomes = await _supabase
          .from('calling_score_ab_test_outcomes')
          .select('*')
          .eq('test_group', 'hybrid');

      final formulaList = List<Map<String, dynamic>>.from(formulaOutcomes);
      final hybridList = List<Map<String, dynamic>>.from(hybridOutcomes);

      // Calculate metrics for formula-based group
      final formulaMetrics = _calculateGroupMetrics(formulaList);

      // Calculate metrics for hybrid group
      final hybridMetrics = _calculateGroupMetrics(hybridList);

      // Calculate improvement
      final callingScoreImprovement =
          hybridMetrics.avgCallingScore - formulaMetrics.avgCallingScore;
      final outcomeRateImprovement = hybridMetrics.positiveOutcomeRate -
          formulaMetrics.positiveOutcomeRate;
      final engagementImprovement =
          hybridMetrics.avgEngagement - formulaMetrics.avgEngagement;

      return ABTestMetrics(
        formulaGroup: formulaMetrics,
        hybridGroup: hybridMetrics,
        callingScoreImprovement: callingScoreImprovement,
        outcomeRateImprovement: outcomeRateImprovement,
        engagementImprovement: engagementImprovement,
        calculatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error getting A/B test metrics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return ABTestMetrics.empty();
    }
  }

  /// Calculate metrics for a test group
  GroupMetrics _calculateGroupMetrics(List<Map<String, dynamic>> outcomes) {
    if (outcomes.isEmpty) {
      return GroupMetrics.empty();
    }

    // Calculate average calling score
    double totalScore = 0.0;
    int calledCount = 0;
    int positiveOutcomes = 0;
    int totalOutcomes = 0;
    double totalEngagement = 0.0;

    for (final outcome in outcomes) {
      final score = (outcome['calling_score'] as num).toDouble();
      totalScore += score;

      if (outcome['is_called'] == true) {
        calledCount++;
      }

      final outcomeType = outcome['outcome_type'] as String?;
      if (outcomeType != null) {
        totalOutcomes++;
        if (outcomeType == 'positive') {
          positiveOutcomes++;
        }

        final outcomeScore =
            (outcome['outcome_score'] as num?)?.toDouble() ?? 0.0;
        totalEngagement += outcomeScore;
      }
    }

    final avgCallingScore = totalScore / outcomes.length;
    final callRate = calledCount / outcomes.length;
    final positiveOutcomeRate =
        totalOutcomes > 0 ? positiveOutcomes / totalOutcomes : 0.0;
    final avgEngagement =
        totalOutcomes > 0 ? totalEngagement / totalOutcomes : 0.0;

    return GroupMetrics(
      totalOutcomes: outcomes.length,
      avgCallingScore: avgCallingScore,
      callRate: callRate,
      positiveOutcomeRate: positiveOutcomeRate,
      avgEngagement: avgEngagement,
    );
  }
}

/// A/B Test Group
enum ABTestGroup {
  formulaBased,
  hybrid;

  String get name {
    switch (this) {
      case ABTestGroup.formulaBased:
        return 'formulaBased';
      case ABTestGroup.hybrid:
        return 'hybrid';
    }
  }

  static ABTestGroup fromString(String name) {
    switch (name) {
      case 'formulaBased':
        return ABTestGroup.formulaBased;
      case 'hybrid':
        return ABTestGroup.hybrid;
      default:
        return ABTestGroup.formulaBased;
    }
  }
}

/// Outcome Result
///
/// Represents the outcome of a user action on a recommendation
class OutcomeResult {
  final String type; // 'positive', 'negative', 'neutral'
  final double score; // 0.0 to 1.0

  OutcomeResult({
    required this.type,
    required this.score,
  });
}

/// Group Metrics
///
/// Metrics for a single A/B test group
class GroupMetrics {
  final int totalOutcomes;
  final double avgCallingScore;
  final double callRate; // Percentage of outcomes where user was "called"
  final double positiveOutcomeRate; // Percentage of positive outcomes
  final double avgEngagement; // Average engagement score

  GroupMetrics({
    required this.totalOutcomes,
    required this.avgCallingScore,
    required this.callRate,
    required this.positiveOutcomeRate,
    required this.avgEngagement,
  });

  factory GroupMetrics.empty() {
    return GroupMetrics(
      totalOutcomes: 0,
      avgCallingScore: 0.0,
      callRate: 0.0,
      positiveOutcomeRate: 0.0,
      avgEngagement: 0.0,
    );
  }
}

/// A/B Test Metrics
///
/// Aggregated metrics comparing formula-based vs hybrid groups
class ABTestMetrics {
  final GroupMetrics formulaGroup;
  final GroupMetrics hybridGroup;
  final double callingScoreImprovement; // Hybrid - Formula
  final double outcomeRateImprovement; // Hybrid - Formula
  final double engagementImprovement; // Hybrid - Formula
  final DateTime calculatedAt;

  ABTestMetrics({
    required this.formulaGroup,
    required this.hybridGroup,
    required this.callingScoreImprovement,
    required this.outcomeRateImprovement,
    required this.engagementImprovement,
    required this.calculatedAt,
  });

  factory ABTestMetrics.empty() {
    return ABTestMetrics(
      formulaGroup: GroupMetrics.empty(),
      hybridGroup: GroupMetrics.empty(),
      callingScoreImprovement: 0.0,
      outcomeRateImprovement: 0.0,
      engagementImprovement: 0.0,
      calculatedAt: DateTime.now(),
    );
  }

  /// Check if hybrid group shows significant improvement
  bool get hasSignificantImprovement {
    return outcomeRateImprovement > 0.05 && // At least 5% improvement
        callingScoreImprovement > 0.0; // Positive improvement
  }
}
