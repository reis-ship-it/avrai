// Calling Score A/B Testing Service for Phase 12: Neural Network Implementation
// Section 2.3: A/B Testing Framework
// Manages A/B testing between formula-based and hybrid calling score systems

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/calling_score/formula_ab_testing_service.dart';

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
  final FormulaABTestingService _formulaABTestingService;

  // A/B test configuration
  static const double hybridGroupPercentage =
      0.5; // 50% hybrid, 50% formula-based

  CallingScoreABTestingService({
    required SupabaseClient supabase,
    required AgentIdService agentIdService,
    FormulaABTestingService formulaABTestingService =
        const FormulaABTestingService(),
  })  : _supabase = supabase,
        _agentIdService = agentIdService,
        _formulaABTestingService = formulaABTestingService;

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

      final isHybrid = _formulaABTestingService.isTreatmentGroup(
        stableSubjectId: agentId,
        treatmentPercentage: hybridGroupPercentage,
      );

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

      final formulaGeneric =
          _formulaABTestingService.calculateGroupMetrics(formulaList);
      final hybridGeneric =
          _formulaABTestingService.calculateGroupMetrics(hybridList);
      final comparison = _formulaABTestingService.compare(
        controlGroup: formulaGeneric,
        treatmentGroup: hybridGeneric,
      );
      final formulaMetrics = GroupMetrics(
        totalOutcomes: formulaGeneric.totalOutcomes,
        avgCallingScore: formulaGeneric.avgScore,
        callRate: formulaGeneric.actionRate,
        positiveOutcomeRate: formulaGeneric.positiveOutcomeRate,
        avgEngagement: formulaGeneric.avgOutcomeScore,
      );
      final hybridMetrics = GroupMetrics(
        totalOutcomes: hybridGeneric.totalOutcomes,
        avgCallingScore: hybridGeneric.avgScore,
        callRate: hybridGeneric.actionRate,
        positiveOutcomeRate: hybridGeneric.positiveOutcomeRate,
        avgEngagement: hybridGeneric.avgOutcomeScore,
      );

      return ABTestMetrics(
        formulaGroup: formulaMetrics,
        hybridGroup: hybridMetrics,
        callingScoreImprovement: comparison.scoreImprovement,
        outcomeRateImprovement: comparison.positiveOutcomeRateImprovement,
        engagementImprovement: comparison.outcomeScoreImprovement,
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
