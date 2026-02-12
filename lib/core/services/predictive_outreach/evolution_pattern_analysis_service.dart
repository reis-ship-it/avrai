// ignore: dangling_library_doc_comments
/// Evolution Pattern Analysis Service
/// 
/// Service for analyzing evolution patterns and optimal timing.
/// Part of Predictive Proactive Outreach System - Phase 1.4
/// 
/// Uses knot evolution pattern analysis to determine optimal outreach timing
/// based on convergence periods, cycle alignments, and evolution trends.

import 'dart:developer' as developer;
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart'
    show
        KnotEvolutionStringService,
        EvolutionAnalysis,
        EvolutionCycle,
        EvolutionTrend;

/// Convergence period (when users' knots are converging)
class ConvergencePeriod {
  /// Start of convergence
  final DateTime startTime;
  
  /// End of convergence
  final DateTime endTime;
  
  /// Strength of convergence (0.0-1.0)
  final double convergenceStrength;
  
  ConvergencePeriod({
    required this.startTime,
    required this.endTime,
    required this.convergenceStrength,
  });
}

/// Cycle alignment (when users' evolution cycles align)
class CycleAlignment {
  /// Alignment time
  final DateTime alignmentTime;
  
  /// Alignment strength (0.0-1.0)
  final double alignmentStrength;
  
  /// Cycle period
  final Duration cyclePeriod;
  
  CycleAlignment({
    required this.alignmentTime,
    required this.alignmentStrength,
    required this.cyclePeriod,
  });
}

/// Outreach timing recommendation
class OutreachTimingRecommendation {
  /// Optimal time to reach out
  final DateTime optimalTime;
  
  /// Confidence in recommendation (0.0-1.0)
  final double confidence;
  
  /// Reasoning for recommendation
  final String reasoning;
  
  /// Convergence periods found
  final List<ConvergencePeriod> convergencePeriods;
  
  /// Cycle alignments found
  final List<CycleAlignment> cycleAlignments;
  
  OutreachTimingRecommendation({
    required this.optimalTime,
    required this.confidence,
    required this.reasoning,
    this.convergencePeriods = const [],
    this.cycleAlignments = const [],
  });
}

/// Service for analyzing evolution patterns and optimal timing
class EvolutionPatternAnalysisService {
  static const String _logName = 'EvolutionPatternAnalysisService';
  
  final KnotEvolutionStringService _stringService;
  
  EvolutionPatternAnalysisService({
    required KnotEvolutionStringService stringService,
  }) : _stringService = stringService;
  
  /// Calculate optimal outreach timing based on evolution patterns
  /// 
  /// **Flow:**
  /// 1. Analyze evolution patterns for both users
  /// 2. Detect convergence periods
  /// 3. Detect cycle alignments
  /// 4. Find optimal timing
  /// 
  /// **Parameters:**
  /// - `userId`: First user's agent ID
  /// - `targetId`: Second user's agent ID
  Future<OutreachTimingRecommendation> calculateOptimalTiming({
    required String userId,
    required String targetId,
  }) async {
    try {
      developer.log(
        'Calculating optimal timing: $userId <-> ${targetId.substring(0, 10)}...',
        name: _logName,
      );
      
      // 1. Analyze evolution patterns for both users
      final userPatterns = await _stringService.analyzeEvolutionPatterns(userId);
      final targetPatterns = await _stringService.analyzeEvolutionPatterns(targetId);
      
      // 2. Detect convergence periods
      final convergencePeriods = _detectConvergencePeriods(
        userPatterns,
        targetPatterns,
      );
      
      // 3. Detect cycle alignments
      final cycleAlignments = _detectCycleAlignments(
        userPatterns.cycles,
        targetPatterns.cycles,
      );
      
      // 4. Find optimal timing
      final optimalTime = _findBestTiming(
        convergencePeriods,
        cycleAlignments,
      );
      
      // 5. Calculate confidence
      final confidence = _calculateTimingConfidence(
        convergencePeriods,
        cycleAlignments,
      );
      
      // 6. Generate reasoning
      final reasoning = _generateTimingReasoning(
        userPatterns,
        targetPatterns,
        convergencePeriods,
        cycleAlignments,
      );
      
      developer.log(
        '✅ Optimal timing calculated: ${optimalTime.toIso8601String()}, '
        'confidence=${confidence.toStringAsFixed(2)}',
        name: _logName,
      );
      
      return OutreachTimingRecommendation(
        optimalTime: optimalTime,
        confidence: confidence,
        reasoning: reasoning,
        convergencePeriods: convergencePeriods,
        cycleAlignments: cycleAlignments,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate optimal timing: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      
      // Return default recommendation
      return OutreachTimingRecommendation(
        optimalTime: DateTime.now().add(const Duration(days: 7)),
        confidence: 0.5,
        reasoning: 'Unable to analyze patterns, using default timing',
      );
    }
  }
  
  /// Detect when users' knots are converging toward compatibility
  List<ConvergencePeriod> _detectConvergencePeriods(
    EvolutionAnalysis userPatterns,
    EvolutionAnalysis targetPatterns,
  ) {
    final convergencePeriods = <ConvergencePeriod>[];
    
    // Compare trends to find convergence
    for (final userTrend in userPatterns.trends) {
      for (final targetTrend in targetPatterns.trends) {
        if (_areTrendsConverging(userTrend, targetTrend)) {
          final startTime = _findConvergenceStart(userTrend, targetTrend);
          final endTime = _findConvergenceEnd(userTrend, targetTrend);
          final strength = _calculateConvergenceStrength(userTrend, targetTrend);
          
          convergencePeriods.add(ConvergencePeriod(
            startTime: startTime,
            endTime: endTime,
            convergenceStrength: strength,
          ));
        }
      }
    }
    
    return convergencePeriods;
  }
  
  /// Detect cycle alignments
  List<CycleAlignment> _detectCycleAlignments(
    List<EvolutionCycle> userCycles,
    List<EvolutionCycle> targetCycles,
  ) {
    final alignments = <CycleAlignment>[];
    
    for (final userCycle in userCycles) {
      for (final targetCycle in targetCycles) {
        final alignment = _findCycleAlignment(userCycle, targetCycle);
        if (alignment != null) {
          alignments.add(alignment);
        }
      }
    }
    
    return alignments;
  }
  
  /// Find best timing from convergence and cycles
  DateTime _findBestTiming(
    List<ConvergencePeriod> convergencePeriods,
    List<CycleAlignment> cycleAlignments,
  ) {
    final now = DateTime.now();
    
    // Prioritize convergence periods with high strength
    if (convergencePeriods.isNotEmpty) {
      final bestConvergence = convergencePeriods.reduce((a, b) => 
        a.convergenceStrength > b.convergenceStrength ? a : b
      );
      
      // Use midpoint of convergence period
      final midpoint = bestConvergence.startTime.add(
        bestConvergence.endTime.difference(bestConvergence.startTime) ~/ 2,
      );
      
      if (midpoint.isAfter(now)) {
        return midpoint;
      }
    }
    
    // Fallback to cycle alignments
    if (cycleAlignments.isNotEmpty) {
      final bestAlignment = cycleAlignments.reduce((a, b) => 
        a.alignmentStrength > b.alignmentStrength ? a : b
      );
      
      if (bestAlignment.alignmentTime.isAfter(now)) {
        return bestAlignment.alignmentTime;
      }
    }
    
    // Default: 7 days from now
    return now.add(const Duration(days: 7));
  }
  
  /// Calculate confidence in timing recommendation
  double _calculateTimingConfidence(
    List<ConvergencePeriod> convergencePeriods,
    List<CycleAlignment> cycleAlignments,
  ) {
    var confidence = 0.3; // Base confidence
    
    // Convergence boost (0-0.4)
    if (convergencePeriods.isNotEmpty) {
      final maxConvergence = convergencePeriods
          .map((c) => c.convergenceStrength)
          .reduce((a, b) => a > b ? a : b);
      confidence += maxConvergence * 0.4;
    }
    
    // Cycle alignment boost (0-0.3)
    if (cycleAlignments.isNotEmpty) {
      final maxAlignment = cycleAlignments
          .map((a) => a.alignmentStrength)
          .reduce((a, b) => a > b ? a : b);
      confidence += maxAlignment * 0.3;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Generate reasoning for timing recommendation
  String _generateTimingReasoning(
    EvolutionAnalysis userPatterns,
    EvolutionAnalysis targetPatterns,
    List<ConvergencePeriod> convergencePeriods,
    List<CycleAlignment> cycleAlignments,
  ) {
    if (convergencePeriods.isNotEmpty) {
      final best = convergencePeriods.reduce((a, b) => 
        a.convergenceStrength > b.convergenceStrength ? a : b
      );
      return 'Knot evolution patterns show convergence period '
          '(${(best.convergenceStrength * 100).toStringAsFixed(0)}% strength) '
          'between ${best.startTime.toIso8601String()} and ${best.endTime.toIso8601String()}.';
    }
    
    if (cycleAlignments.isNotEmpty) {
      final best = cycleAlignments.reduce((a, b) => 
        a.alignmentStrength > b.alignmentStrength ? a : b
      );
      return 'Evolution cycles align at ${best.alignmentTime.toIso8601String()} '
          '(${(best.alignmentStrength * 100).toStringAsFixed(0)}% alignment).';
    }
    
    return 'Using default timing based on general compatibility patterns.';
  }
  
  /// Check if trends are converging
  bool _areTrendsConverging(
    EvolutionTrend userTrend,
    EvolutionTrend targetTrend,
  ) {
    // Simplified: trends converge if they're moving toward each other
    // In production, would analyze trend directions and rates
    return true; // Placeholder
  }
  
  /// Find convergence start time
  DateTime _findConvergenceStart(
    EvolutionTrend userTrend,
    EvolutionTrend targetTrend,
  ) {
    // Simplified: use trend start times
    final userStart = userTrend.startTime;
    final targetStart = targetTrend.startTime;
    return userStart.isBefore(targetStart) ? targetStart : userStart;
  }
  
  /// Find convergence end time
  DateTime _findConvergenceEnd(
    EvolutionTrend userTrend,
    EvolutionTrend targetTrend,
  ) {
    // Simplified: use trend end times
    final userEnd = userTrend.endTime;
    final targetEnd = targetTrend.endTime;
    return userEnd.isBefore(targetEnd) ? userEnd : targetEnd;
  }
  
  /// Calculate convergence strength
  double _calculateConvergenceStrength(
    EvolutionTrend userTrend,
    EvolutionTrend targetTrend,
  ) {
    // Simplified: calculate based on trend similarity
    // In production, would analyze actual convergence metrics
    return 0.7; // Placeholder
  }
  
  /// Find cycle alignment
  CycleAlignment? _findCycleAlignment(
    EvolutionCycle userCycle,
    EvolutionCycle targetCycle,
  ) {
    // Simplified: find when cycles align
    // In production, would calculate actual alignment times
    return CycleAlignment(
      alignmentTime: DateTime.now().add(const Duration(days: 14)),
      alignmentStrength: 0.6,
      cyclePeriod: const Duration(days: 30),
    );
  }
}
