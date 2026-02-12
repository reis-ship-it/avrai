// ignore: dangling_library_doc_comments
/// Temporal Quantum Compatibility Service
/// 
/// Service for calculating quantum compatibility over time.
/// Part of Predictive Proactive Outreach System - Phase 1.2
/// 
/// Uses quantum entanglement and knot evolution strings to predict
/// compatibility trajectories over time.

import 'dart:developer' as developer;
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

/// Quantum compatibility score at a point in time
class QuantumCompatibilityScore {
  /// Quantum fidelity score
  final double quantumFidelity;
  
  /// Location compatibility
  final double locationCompatibility;
  
  /// Timing compatibility
  final double timingCompatibility;
  
  /// Knot compatibility (if available)
  final double? knotCompatibility;
  
  /// Combined compatibility score
  final double combined;
  
  QuantumCompatibilityScore({
    required this.quantumFidelity,
    required this.locationCompatibility,
    required this.timingCompatibility,
    this.knotCompatibility,
    required this.combined,
  });
}

/// Temporal quantum compatibility trajectory
class TemporalQuantumCompatibility {
  /// Trajectory data: time -> compatibility score
  final Map<DateTime, QuantumCompatibilityScore> trajectory;
  
  /// Time when compatibility peaks
  final DateTime? peakTime;
  
  /// Peak compatibility score
  final double peakCompatibility;
  
  /// Average compatibility over trajectory
  final double averageCompatibility;
  
  /// Trend: improving, stable, declining
  final String trend;
  
  TemporalQuantumCompatibility({
    required this.trajectory,
    this.peakTime,
    required this.peakCompatibility,
    required this.averageCompatibility,
    required this.trend,
  });
  
  /// Empty trajectory
  factory TemporalQuantumCompatibility.empty() {
    return TemporalQuantumCompatibility(
      trajectory: {},
      peakCompatibility: 0.0,
      averageCompatibility: 0.0,
      trend: 'unknown',
    );
  }
  
  /// Check if trajectory is improving
  bool get isImproving => trend == 'improving';
}

/// Service for calculating quantum compatibility over time
class TemporalQuantumCompatibilityService {
  static const String _logName = 'TemporalQuantumCompatibilityService';
  
  final QuantumEntanglementService _entanglementService;
  final KnotEvolutionStringService _stringService;
  final PersonalityLearning _personalityLearning;
  final AtomicClockService _atomicClock;
  
  TemporalQuantumCompatibilityService({
    required QuantumEntanglementService entanglementService,
    required KnotEvolutionStringService stringService,
    required PersonalityLearning personalityLearning,
    required AtomicClockService atomicClock,
  })  : _entanglementService = entanglementService,
        _stringService = stringService,
        _personalityLearning = personalityLearning,
        _atomicClock = atomicClock;
  
  /// Calculate quantum compatibility trajectory
  /// 
  /// **Flow:**
  /// 1. Get personality profiles for both users
  /// 2. For each time point, predict future quantum states
  /// 3. Calculate quantum fidelity, location, timing compatibility
  /// 4. Get predicted knot compatibility (if available)
  /// 5. Combine all factors
  /// 
  /// **Parameters:**
  /// - `userAId`: First user's ID
  /// - `userBId`: Second user's ID
  /// - `startTime`: Start of trajectory
  /// - `endTime`: End of trajectory
  /// - `step`: Time step between calculations (default: 1 day)
  Future<TemporalQuantumCompatibility> calculateTemporalCompatibility({
    required String userAId,
    required String userBId,
    required DateTime startTime,
    required DateTime endTime,
    Duration step = const Duration(days: 1),
  }) async {
    try {
      developer.log(
        'Calculating temporal quantum compatibility: $userAId <-> $userBId '
        'from ${startTime.toIso8601String()} to ${endTime.toIso8601String()}',
        name: _logName,
      );
      
      // 1. Get personality profiles
      final profileA = await _personalityLearning.getCurrentPersonality(userAId);
      final profileB = await _personalityLearning.getCurrentPersonality(userBId);
      
      if (profileA == null || profileB == null) {
        developer.log(
          '⚠️ Could not load personality profiles',
          name: _logName,
        );
        return TemporalQuantumCompatibility.empty();
      }
      
      // 2. Calculate trajectory
      final trajectory = <DateTime, QuantumCompatibilityScore>{};
      DateTime currentTime = startTime;
      
      while (currentTime.isBefore(endTime) || currentTime.isAtSameMomentAs(endTime)) {
        try {
          // Get predicted knots for this time point
          final knotA = await _stringService.predictFutureKnot(
            profileA.agentId,
            currentTime,
          );
          final knotB = await _stringService.predictFutureKnot(
            profileB.agentId,
            currentTime,
          );
          
          // Create quantum states (adjusted by predicted knots if available)
          final stateA = await _createQuantumStateFromProfile(profileA, knotA);
          final stateB = await _createQuantumStateFromProfile(profileB, knotB);
          
          // 3. Calculate quantum fidelity
          final entangledA = await _entanglementService.createEntangledState(
            entityStates: [stateA],
          );
          final entangledB = await _entanglementService.createEntangledState(
            entityStates: [stateB],
          );
          
          final quantumFidelity = await _entanglementService.calculateFidelity(
            entangledA,
            entangledB,
          );
          
          // 4. Calculate location/timing compatibility
          final locationCompat = await _predictLocationCompatibility(
            stateA,
            stateB,
            currentTime,
          );
          final timingCompat = await _predictTimingCompatibility(
            stateA,
            stateB,
            currentTime,
          );
          
          // 5. Get predicted knot compatibility
          double? knotCompat;
          if (knotA != null && knotB != null) {
            knotCompat = calculateTopologicalCompatibility(
              braidDataA: knotA.braidData,
              braidDataB: knotB.braidData,
            );
          }
          
          // 6. Combine all factors
          final combined = _combineCompatibilityFactors(
            quantumFidelity: quantumFidelity,
            locationCompatibility: locationCompat,
            timingCompatibility: timingCompat,
            knotCompatibility: knotCompat,
          );
          
          trajectory[currentTime] = QuantumCompatibilityScore(
            quantumFidelity: quantumFidelity,
            locationCompatibility: locationCompat,
            timingCompatibility: timingCompat,
            knotCompatibility: knotCompat,
            combined: combined,
          );
        } catch (e) {
          developer.log(
            'Error calculating compatibility at ${currentTime.toIso8601String()}: $e',
            name: _logName,
          );
          // Continue with next time point
        }
        
        currentTime = currentTime.add(step);
      }
      
      if (trajectory.isEmpty) {
        return TemporalQuantumCompatibility.empty();
      }
      
      // 7. Find peak compatibility
      final peakEntry = trajectory.entries.reduce((a, b) => 
        a.value.combined > b.value.combined ? a : b
      );
      final peakTime = peakEntry.key;
      final peakCompatibility = peakEntry.value.combined;
      
      // 8. Calculate average
      final average = trajectory.values
          .map((s) => s.combined)
          .reduce((a, b) => a + b) / trajectory.length;
      
      // 9. Calculate trend
      final trend = _calculateTrend(trajectory);
      
      developer.log(
        '✅ Temporal quantum compatibility calculated: peak=${peakCompatibility.toStringAsFixed(2)}, '
        'average=${average.toStringAsFixed(2)}, trend=$trend',
        name: _logName,
      );
      
      return TemporalQuantumCompatibility(
        trajectory: trajectory,
        peakTime: peakTime,
        peakCompatibility: peakCompatibility,
        averageCompatibility: average,
        trend: trend,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate temporal quantum compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return TemporalQuantumCompatibility.empty();
    }
  }
  
  /// Create quantum state from personality profile
  Future<QuantumEntityState> _createQuantumStateFromProfile(
    PersonalityProfile profile,
    PersonalityKnot? knot,
  ) async {
    // Create quantum state from personality profile
    // This is a simplified version - would use QuantumVibeEngine in production
    final personalityState = Map<String, double>.from(profile.dimensions);
    
    // Adjust based on predicted knot if available
    if (knot != null) {
      // Knot adjustments would be applied here
      // For now, use personality dimensions as-is
    }
    
    return QuantumEntityState(
      entityId: profile.agentId,
      entityType: QuantumEntityType.user,
      personalityState: personalityState,
      quantumVibeAnalysis: personalityState, // Simplified
      entityCharacteristics: {},
      location: null,
      timing: null,
      tAtomic: await _atomicClock.getAtomicTimestamp(),
    );
  }
  
  /// Predict location compatibility at future time
  Future<double> _predictLocationCompatibility(
    QuantumEntityState stateA,
    QuantumEntityState stateB,
    DateTime time,
  ) async {
    // Simplified: would use location prediction service
    // For now, return neutral compatibility
    if (stateA.location == null || stateB.location == null) {
      return 0.5;
    }
    
    // Calculate location compatibility
    // This would use actual location prediction logic
    return 0.5; // Placeholder
  }
  
  /// Predict timing compatibility at future time
  Future<double> _predictTimingCompatibility(
    QuantumEntityState stateA,
    QuantumEntityState stateB,
    DateTime time,
  ) async {
    // Simplified: would use timing prediction service
    // For now, return neutral compatibility
    if (stateA.timing == null || stateB.timing == null) {
      return 0.5;
    }
    
    // Calculate timing compatibility
    // This would use actual timing prediction logic
    return 0.5; // Placeholder
  }
  
  /// Combine all compatibility factors
  double _combineCompatibilityFactors({
    required double quantumFidelity,
    required double locationCompatibility,
    required double timingCompatibility,
    double? knotCompatibility,
  }) {
    // Weighted combination:
    // - Quantum fidelity: 50% (or 40% if knot available)
    // - Location: 30% (or 25% if knot available)
    // - Timing: 20% (or 20% if knot available)
    // - Knot: 15% (if available)
    
    if (knotCompatibility != null) {
      return (
        0.40 * quantumFidelity +
        0.25 * locationCompatibility +
        0.20 * timingCompatibility +
        0.15 * knotCompatibility
      ).clamp(0.0, 1.0);
    } else {
      return (
        0.50 * quantumFidelity +
        0.30 * locationCompatibility +
        0.20 * timingCompatibility
      ).clamp(0.0, 1.0);
    }
  }
  
  /// Calculate trend from trajectory
  String _calculateTrend(Map<DateTime, QuantumCompatibilityScore> trajectory) {
    if (trajectory.length < 2) return 'unknown';
    
    final sorted = trajectory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final first = sorted.first.value.combined;
    final last = sorted.last.value.combined;
    final change = last - first;
    
    if (change > 0.1) return 'improving';
    if (change < -0.1) return 'declining';
    return 'stable';
  }
}
