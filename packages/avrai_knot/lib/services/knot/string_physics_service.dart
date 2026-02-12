// String Physics Service
// 
// Models string dynamics for knot evolution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Polynomial String Interpolation

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';

/// Service for modeling string dynamics
/// 
/// Models:
/// - Tension: Pulls knot toward simpler state
/// - Relaxation: Natural evolution toward equilibrium
/// - External forces: Personality changes, life events
/// - Damping: Prevents oscillation
class StringPhysicsService {
  static const String _logName = 'StringPhysicsService';
  
  /// Tension coefficient (how strongly knot is pulled toward simpler state)
  final double tensionCoefficient;
  
  /// Relaxation rate (how quickly knot evolves toward equilibrium)
  final double relaxationRate;
  
  /// Damping coefficient (prevents oscillation)
  final double dampingCoefficient;
  
  StringPhysicsService({
    this.tensionCoefficient = 0.1,
    this.relaxationRate = 0.05,
    this.dampingCoefficient = 0.2,
  });
  
  /// Calculate string evolution rate
  /// 
  /// **Formula:**
  /// dK/dt = -α·tension - β·relaxation + γ·external_forces - δ·damping
  /// 
  /// Where:
  /// - α = tension coefficient
  /// - β = relaxation rate
  /// - γ = external force strength
  /// - δ = damping coefficient
  StringEvolutionRate calculateEvolutionRate({
    required PersonalityKnot currentKnot,
    PersonalityKnot? previousKnot,
    double? externalForce,
  }) {
    // Calculate tension (pulls toward simpler state)
    final complexity = currentKnot.invariants.crossingNumber.toDouble();
    final idealComplexity = 3.0; // Ideal: trefoil (simplest non-trivial knot)
    final tension = tensionCoefficient * (complexity - idealComplexity);
    
    // Calculate relaxation (natural evolution toward equilibrium)
    final relaxation = relaxationRate * _calculateEquilibriumDistance(currentKnot);
    
    // External forces (personality changes, life events)
    final external = externalForce ?? 0.0;
    
    // Damping (prevents oscillation)
    double damping = 0.0;
    if (previousKnot != null) {
      final velocity = _calculateKnotVelocity(previousKnot, currentKnot);
      damping = dampingCoefficient * velocity;
    }
    
    // Net evolution rate
    final netRate = -tension - relaxation + external - damping;
    
    return StringEvolutionRate(
      tension: tension,
      relaxation: relaxation,
      externalForce: external,
      damping: damping,
      netRate: netRate,
    );
  }
  
  /// Calculate distance from equilibrium state
  /// 
  /// Equilibrium = trefoil knot (simplest non-trivial knot)
  double _calculateEquilibriumDistance(PersonalityKnot knot) {
    final complexity = knot.invariants.crossingNumber.toDouble();
    final idealComplexity = 3.0;
    return (complexity - idealComplexity).abs();
  }
  
  /// Calculate knot velocity (rate of change)
  double _calculateKnotVelocity(PersonalityKnot knot1, PersonalityKnot knot2) {
    // Use crossing number as proxy for complexity/state
    final delta = (knot2.invariants.crossingNumber - 
                   knot1.invariants.crossingNumber).abs().toDouble();
    return delta;
  }
  
  /// Predict future knot state using string physics
  /// 
  /// **Formula:**
  /// K(t_future) = K(t_current) + ∫[t_current to t_future] dK/dt dt
  /// 
  /// Where dK/dt is calculated from string physics
  PersonalityKnot predictFutureKnot({
    required PersonalityKnot currentKnot,
    required DateTime currentTime,
    required DateTime futureTime,
    PersonalityKnot? previousKnot,
    double? externalForce,
  }) {
    final timeDelta = futureTime.difference(currentTime);
    final timeSeconds = timeDelta.inSeconds.toDouble();
    
    if (timeSeconds <= 0) {
      return currentKnot;
    }
    
    // Calculate evolution rate
    final evolutionRate = calculateEvolutionRate(
      currentKnot: currentKnot,
      previousKnot: previousKnot,
      externalForce: externalForce,
    );
    
    // Apply evolution
    final complexityChange = evolutionRate.netRate * timeSeconds;
    final newCrossingNumber = (currentKnot.invariants.crossingNumber + 
                               complexityChange.round())
        .clamp(3, 100); // Minimum: trefoil (3 crossings)
    
    // Evolve other invariants proportionally
    final complexityFactor = newCrossingNumber / 
        currentKnot.invariants.crossingNumber.clamp(1, 100);
    
    final newWrithe = (currentKnot.invariants.writhe * complexityFactor).round();
    final newSignature = (currentKnot.invariants.signature * complexityFactor).round();
    final newBridgeNumber = (currentKnot.invariants.bridgeNumber * complexityFactor)
        .round()
        .clamp(1, 100);
    final newBraidIndex = (currentKnot.invariants.braidIndex * complexityFactor)
        .round()
        .clamp(1, 12);
    
    // Evolve polynomials (simplified - scale by complexity factor)
    final newJones = currentKnot.invariants.jonesPolynomial
        .map((coeff) => coeff * complexityFactor)
        .toList();
    
    final newAlexander = currentKnot.invariants.alexanderPolynomial
        .map((coeff) => coeff * complexityFactor)
        .toList();
    
    return PersonalityKnot(
      agentId: currentKnot.agentId,
      invariants: KnotInvariants(
        jonesPolynomial: newJones,
        alexanderPolynomial: newAlexander,
        crossingNumber: newCrossingNumber,
        writhe: newWrithe,
        signature: newSignature,
        unknottingNumber: currentKnot.invariants.unknottingNumber,
        bridgeNumber: newBridgeNumber,
        braidIndex: newBraidIndex,
        determinant: currentKnot.invariants.determinant,
        arfInvariant: currentKnot.invariants.arfInvariant,
        hyperbolicVolume: currentKnot.invariants.hyperbolicVolume,
        homflyPolynomial: currentKnot.invariants.homflyPolynomial,
      ),
      braidData: currentKnot.braidData, // Simplified
      createdAt: currentKnot.createdAt,
      lastUpdated: futureTime,
    );
  }
  
  /// Apply external force to knot
  /// 
  /// External forces represent personality changes, life events, etc.
  PersonalityKnot applyExternalForce({
    required PersonalityKnot knot,
    required double forceMagnitude,
    required String forceType, // e.g., "personality_change", "life_event"
  }) {
    developer.log(
      'Applying external force: type=$forceType, magnitude=$forceMagnitude',
      name: _logName,
    );
    
    // Calculate force direction based on type
    final forceDirection = _getForceDirection(forceType);
    
    // Apply force to knot complexity
    final complexityChange = forceMagnitude * forceDirection;
    final newCrossingNumber = (knot.invariants.crossingNumber + 
                              complexityChange.round())
        .clamp(3, 100);
    
    // Apply proportional changes to other invariants
    final complexityFactor = newCrossingNumber / 
        knot.invariants.crossingNumber.clamp(1, 100);
    
    return knot.copyWith(
      invariants: KnotInvariants(
        jonesPolynomial: knot.invariants.jonesPolynomial,
        alexanderPolynomial: knot.invariants.alexanderPolynomial,
        crossingNumber: newCrossingNumber,
        writhe: (knot.invariants.writhe * complexityFactor).round(),
        signature: (knot.invariants.signature * complexityFactor).round(),
        unknottingNumber: knot.invariants.unknottingNumber,
        bridgeNumber: (knot.invariants.bridgeNumber * complexityFactor)
            .round()
            .clamp(1, 100),
        braidIndex: (knot.invariants.braidIndex * complexityFactor)
            .round()
            .clamp(1, 12),
        determinant: knot.invariants.determinant,
        arfInvariant: knot.invariants.arfInvariant,
        hyperbolicVolume: knot.invariants.hyperbolicVolume,
        homflyPolynomial: knot.invariants.homflyPolynomial,
      ),
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Get force direction based on force type
  /// 
  /// Returns: +1 (increases complexity), -1 (decreases complexity), 0 (neutral)
  int _getForceDirection(String forceType) {
    switch (forceType) {
      case 'personality_growth':
      case 'life_event_positive':
        return 1; // Increases complexity
      case 'personality_simplification':
      case 'life_event_negative':
        return -1; // Decreases complexity
      case 'personality_stable':
      default:
        return 0; // Neutral
    }
  }
}

/// String evolution rate (dK/dt)
/// 
/// Represents rate of change for knot properties
class StringEvolutionRate {
  /// Tension component
  final double tension;
  
  /// Relaxation component
  final double relaxation;
  
  /// External force component
  final double externalForce;
  
  /// Damping component
  final double damping;
  
  /// Net evolution rate
  final double netRate;
  
  StringEvolutionRate({
    required this.tension,
    required this.relaxation,
    required this.externalForce,
    required this.damping,
    required this.netRate,
  });
  
  /// Get magnitude of evolution rate
  double get magnitude => netRate.abs();
  
  /// Check if evolution is accelerating
  bool get isAccelerating => netRate > 0;
  
  /// Check if evolution is decelerating
  bool get isDecelerating => netRate < 0;
}
