// ignore: dangling_library_doc_comments
/// Future Compatibility Prediction Service
/// 
/// Service for predicting future compatibility using knot evolution strings.
/// Part of Predictive Proactive Outreach System - Phase 1.1
/// 
/// Uses knot evolution string predictions to calculate compatibility trajectories
/// and find users whose compatibility is improving over time.

import 'dart:developer' as developer;
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

/// Compatibility trajectory over time
class CompatibilityTrajectory {
  /// Trajectory data: time -> compatibility score
  final Map<DateTime, double> trajectory;
  
  /// Time when compatibility peaks
  final DateTime? peakTime;
  
  /// Current compatibility (at trajectory start)
  final double currentCompatibility;
  
  /// Predicted compatibility (at peak or target time)
  final double predictedCompatibility;
  
  /// Trend: improving, stable, declining
  final String trend;
  
  /// Improvement rate (compatibility change per day)
  final double improvementRate;
  
  CompatibilityTrajectory({
    required this.trajectory,
    this.peakTime,
    required this.currentCompatibility,
    required this.predictedCompatibility,
    required this.trend,
    required this.improvementRate,
  });
  
  /// Empty trajectory
  factory CompatibilityTrajectory.empty() {
    return CompatibilityTrajectory(
      trajectory: {},
      currentCompatibility: 0.0,
      predictedCompatibility: 0.0,
      trend: 'unknown',
      improvementRate: 0.0,
    );
  }
  
  /// Check if trajectory is improving
  bool get isImproving => trend == 'improving';
  
  /// Check if trajectory is stable
  bool get isStable => trend == 'stable';
  
  /// Check if trajectory is declining
  bool get isDeclining => trend == 'declining';
}

/// Improving compatibility match
class ImprovingCompatibilityMatch {
  /// User ID
  final String userId;
  
  /// Current compatibility score
  final double currentCompatibility;
  
  /// Predicted compatibility score
  final double predictedCompatibility;
  
  /// Improvement rate (compatibility change per day)
  final double improvementRate;
  
  /// Optimal time to reach out
  final DateTime? optimalOutreachTime;
  
  /// Confidence in prediction
  final double confidence;
  
  /// Reasoning for match
  final String? reasoning;
  
  ImprovingCompatibilityMatch({
    required this.userId,
    required this.currentCompatibility,
    required this.predictedCompatibility,
    required this.improvementRate,
    this.optimalOutreachTime,
    this.confidence = 0.5,
    this.reasoning,
  });
}

/// Service for predicting future compatibility using knot evolution strings
class FutureCompatibilityPredictionService {
  static const String _logName = 'FutureCompatibilityPredictionService';
  
  final KnotEvolutionStringService _stringService;
  final KnotStorageService _knotStorage;
  
  FutureCompatibilityPredictionService({
    required KnotEvolutionStringService stringService,
    required KnotStorageService knotStorage,
  })  : _stringService = stringService,
        _knotStorage = knotStorage;
  
  /// Predict compatibility at future time points
  /// 
  /// **Flow:**
  /// 1. Get predicted future knots for both users
  /// 2. Calculate compatibility at multiple time points
  /// 3. Find peak compatibility time
  /// 4. Calculate trend
  /// 
  /// **Parameters:**
  /// - `userAId`: First user's agent ID
  /// - `userBId`: Second user's agent ID
  /// - `targetTime`: Target time for prediction
  /// - `predictionPoints`: Number of points to calculate (default: 10)
  Future<CompatibilityTrajectory> predictFutureCompatibility({
    required String userAId,
    required String userBId,
    required DateTime targetTime,
    int predictionPoints = 10,
  }) async {
    try {
      developer.log(
        'Predicting future compatibility: $userAId <-> $userBId at ${targetTime.toIso8601String()}',
        name: _logName,
      );
      
      // 1. Get predicted future knots for both users
      final futureKnotA = await _stringService.predictFutureKnot(
        userAId,
        targetTime,
      );
      final futureKnotB = await _stringService.predictFutureKnot(
        userBId,
        targetTime,
      );
      
      if (futureKnotA == null || futureKnotB == null) {
        developer.log(
          '⚠️ Could not predict future knots for one or both users',
          name: _logName,
        );
        return CompatibilityTrajectory.empty();
      }
      
      // 2. Get current knots for baseline
      final currentKnotA = await _knotStorage.loadKnot(userAId);
      final currentKnotB = await _knotStorage.loadKnot(userBId);
      
      if (currentKnotA == null || currentKnotB == null) {
        developer.log(
          '⚠️ Could not load current knots for one or both users',
          name: _logName,
        );
        return CompatibilityTrajectory.empty();
      }
      
      // 3. Calculate compatibility trajectory
      final trajectory = <DateTime, double>{};
      final now = DateTime.now();
      final timeSpan = targetTime.difference(now);
      final stepSize = timeSpan.inDays / predictionPoints;
      
      for (int i = 0; i <= predictionPoints; i++) {
        final time = now.add(Duration(days: (stepSize * i).round()));
        
        // Get knots at this time point
        final knotA = i == 0
            ? currentKnotA
            : await _stringService.predictFutureKnot(userAId, time);
        final knotB = i == 0
            ? currentKnotB
            : await _stringService.predictFutureKnot(userBId, time);
        
        if (knotA != null && knotB != null) {
          // Calculate topological compatibility
          final compatibility = calculateTopologicalCompatibility(
            braidDataA: knotA.braidData,
            braidDataB: knotB.braidData,
          );
          trajectory[time] = compatibility;
        }
      }
      
      if (trajectory.isEmpty) {
        return CompatibilityTrajectory.empty();
      }
      
      // 4. Find peak compatibility time
      final peakEntry = trajectory.entries.reduce((a, b) => 
        a.value > b.value ? a : b
      );
      final peakTime = peakEntry.key;
      final peakCompatibility = peakEntry.value;
      
      // 5. Calculate current compatibility
      final currentCompatibility = trajectory[now] ?? trajectory.values.first;
      
      // 6. Calculate trend
      final trend = _calculateTrend(trajectory);
      
      // 7. Calculate improvement rate
      final improvementRate = trajectory.length > 1
          ? (peakCompatibility - currentCompatibility) / 
            peakTime.difference(now).inDays.clamp(1, 365)
          : 0.0;
      
      developer.log(
        '✅ Future compatibility predicted: current=${currentCompatibility.toStringAsFixed(2)}, '
        'predicted=${peakCompatibility.toStringAsFixed(2)}, trend=$trend',
        name: _logName,
      );
      
      return CompatibilityTrajectory(
        trajectory: trajectory,
        peakTime: peakTime,
        currentCompatibility: currentCompatibility,
        predictedCompatibility: peakCompatibility,
        trend: trend,
        improvementRate: improvementRate,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to predict future compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return CompatibilityTrajectory.empty();
    }
  }
  
  /// Find users whose compatibility is improving
  /// 
  /// **Flow:**
  /// 1. Get user's predicted future knot
  /// 2. Get all candidate users
  /// 3. For each candidate, calculate current vs future compatibility
  /// 4. Return matches where compatibility is improving
  /// 
  /// **Parameters:**
  /// - `userId`: User's agent ID
  /// - `lookahead`: How far ahead to look (default: 90 days)
  Future<List<ImprovingCompatibilityMatch>> findImprovingMatches({
    required String userId,
    Duration lookahead = const Duration(days: 90),
  }) async {
    try {
      developer.log(
        'Finding improving matches for user: ${userId.substring(0, 10)}...',
        name: _logName,
      );
      
      final now = DateTime.now();
      final targetTime = now.add(lookahead);
      
      // 1. Get user's predicted future knot
      final futureUserKnot = await _stringService.predictFutureKnot(
        userId,
        targetTime,
      );
      
      if (futureUserKnot == null) {
        developer.log(
          '⚠️ Could not predict future knot for user',
          name: _logName,
        );
        return [];
      }
      
      // 2. Get user's current knot
      final currentUserKnot = await _knotStorage.loadKnot(userId);
      if (currentUserKnot == null) {
        developer.log(
          '⚠️ Could not load current knot for user',
          name: _logName,
        );
        return [];
      }
      
      // 3. Get candidate users (placeholder - would query database)
      final candidates = await _getCandidateUsers(userId);
      final improvingMatches = <ImprovingCompatibilityMatch>[];
      
      // 4. For each candidate, calculate compatibility trajectory
      for (final candidate in candidates) {
        try {
          final candidateKnot = await _knotStorage.loadKnot(candidate.agentId);
          if (candidateKnot == null) continue;
          
          // Calculate current compatibility
          final currentCompat = calculateTopologicalCompatibility(
            braidDataA: currentUserKnot.braidData,
            braidDataB: candidateKnot.braidData,
          );
          
          // Get candidate's predicted future knot
          final futureCandidateKnot = await _stringService.predictFutureKnot(
            candidate.agentId,
            targetTime,
          );
          
          if (futureCandidateKnot == null) continue;
          
          // Calculate future compatibility
          final futureCompat = calculateTopologicalCompatibility(
            braidDataA: futureUserKnot.braidData,
            braidDataB: futureCandidateKnot.braidData,
          );
          
          // If improving and above threshold
          if (futureCompat > currentCompat && futureCompat >= 0.7) {
            final improvementRate = (futureCompat - currentCompat) / 
                lookahead.inDays;
            
            final optimalTime = _calculateOptimalOutreachTime(
              currentCompat,
              futureCompat,
              lookahead,
            );
            
            improvingMatches.add(ImprovingCompatibilityMatch(
              userId: candidate.userId ?? candidate.agentId,
              currentCompatibility: currentCompat,
              predictedCompatibility: futureCompat,
              improvementRate: improvementRate,
              optimalOutreachTime: optimalTime,
              confidence: _calculateConfidence(
                currentCompat,
                futureCompat,
                lookahead,
              ),
              reasoning: _generateReasoning(
                currentCompat,
                futureCompat,
                improvementRate,
              ),
            ));
          }
        } catch (e) {
          developer.log(
            'Error processing candidate ${candidate.agentId}: $e',
            name: _logName,
          );
          continue;
        }
      }
      
      // 5. Sort by predicted compatibility
      improvingMatches.sort((a, b) => 
        b.predictedCompatibility.compareTo(a.predictedCompatibility)
      );
      
      developer.log(
        '✅ Found ${improvingMatches.length} improving matches',
        name: _logName,
      );
      
      return improvingMatches;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to find improving matches: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }
  
  /// Calculate trend from trajectory
  String _calculateTrend(Map<DateTime, double> trajectory) {
    if (trajectory.length < 2) return 'unknown';
    
    final sorted = trajectory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final first = sorted.first.value;
    final last = sorted.last.value;
    final change = last - first;
    
    if (change > 0.1) return 'improving';
    if (change < -0.1) return 'declining';
    return 'stable';
  }
  
  /// Calculate optimal outreach time
  DateTime? _calculateOptimalOutreachTime(
    double currentCompat,
    double futureCompat,
    Duration lookahead,
  ) {
    // Optimal time is when compatibility reaches 80% of improvement
    final targetCompat = currentCompat + (futureCompat - currentCompat) * 0.8;
    
    // Linear interpolation to find time
    final improvementRate = (futureCompat - currentCompat) / lookahead.inDays;
    if (improvementRate <= 0) return null;
    
    final daysToTarget = (targetCompat - currentCompat) / improvementRate;
    return DateTime.now().add(Duration(days: daysToTarget.round().clamp(0, lookahead.inDays)));
  }
  
  /// Calculate confidence in prediction
  double _calculateConfidence(
    double currentCompat,
    double futureCompat,
    Duration lookahead,
  ) {
    // Confidence based on:
    // 1. Improvement magnitude (larger = more confident)
    // 2. Lookahead distance (shorter = more confident)
    // 3. Current compatibility (higher = more confident)
    
    final improvement = futureCompat - currentCompat;
    final lookaheadDays = lookahead.inDays.clamp(1, 365);
    
    var confidence = 0.5; // Base confidence
    
    // Improvement magnitude (0-0.5 boost)
    confidence += (improvement * 0.5).clamp(0.0, 0.5);
    
    // Lookahead distance (shorter = more confident)
    confidence += (1.0 - (lookaheadDays / 365.0)) * 0.2;
    
    // Current compatibility (higher = more confident)
    confidence += currentCompat * 0.3;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Generate reasoning for match
  String _generateReasoning(
    double currentCompat,
    double futureCompat,
    double improvementRate,
  ) {
    final improvement = futureCompat - currentCompat;
    final improvementPercent = (improvement * 100).toStringAsFixed(1);
    
    if (improvementRate > 0.001) {
      return 'Compatibility improving by $improvementPercent% over time. '
          'Predicted to reach ${(futureCompat * 100).toStringAsFixed(0)}% compatibility.';
    } else {
      return 'Compatibility stable at ${(currentCompat * 100).toStringAsFixed(0)}% compatibility.';
    }
  }
  
  /// Get candidate users (placeholder - would query database)
  /// TODO: Implement actual database query
  Future<List<CandidateUser>> _getCandidateUsers(String excludeUserId) async {
    // Placeholder - would query database for active users
    // Excluding excludeUserId and filtering by relevant criteria
    return [];
  }
}

/// Candidate user for matching
class CandidateUser {
  final String agentId;
  final String? userId;
  
  CandidateUser({
    required this.agentId,
    this.userId,
  });
}
