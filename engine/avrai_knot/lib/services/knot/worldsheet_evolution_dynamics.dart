// Worldsheet Evolution Dynamics
//
// Models fabric evolution dynamics for worldsheet extrapolation
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Enhanced Worldsheet Interpolation

import 'dart:math' as math;
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';

/// Service for modeling fabric evolution dynamics
///
/// **Formula:**
/// F(t) = F(t₀) + ∫[t₀ to t] dF/dt dt
///
/// Where dF/dt = α·(F_ideal - F) + β·external_forces
///
/// Models:
/// - Relaxation: Natural evolution toward equilibrium
/// - Tension: Forces pulling fabric toward ideal state
/// - External forces: Member changes, events, etc.
class WorldsheetEvolutionDynamics {
  // TODO(Phase 5.3): Add logging for worldsheet evolution dynamics
  // ignore: unused_field
  static const String _logName = 'WorldsheetEvolutionDynamics';

  /// Relaxation rate (α) - how quickly fabric evolves toward ideal
  final double relaxationRate;

  /// External force strength (β) - influence of external events
  final double externalForceStrength;

  /// Ideal fabric state (target state)
  final KnotFabric? idealFabric;

  WorldsheetEvolutionDynamics({
    this.relaxationRate = 0.1,
    this.externalForceStrength = 0.05,
    this.idealFabric,
  });

  /// Calculate evolution rate from snapshots
  ///
  /// Returns rate of change: dF/dt
  EvolutionRate calculateEvolutionRate(
    FabricSnapshot snapshot1,
    FabricSnapshot snapshot2,
  ) {
    final timeDelta = snapshot2.timestamp.difference(snapshot1.timestamp);
    final timeSeconds = timeDelta.inSeconds.toDouble();

    if (timeSeconds <= 0) {
      return EvolutionRate(
        stabilityRate: 0.0,
        densityRate: 0.0,
        crossingRate: 0.0,
        jonesRate: <double>[],
        alexanderRate: <double>[],
      );
    }

    final fabric1 = snapshot1.fabric;
    final fabric2 = snapshot2.fabric;

    // Calculate rates of change
    final stabilityRate =
        (fabric2.invariants.stability - fabric1.invariants.stability) /
        timeSeconds;

    final densityRate =
        (fabric2.invariants.density - fabric1.invariants.density) / timeSeconds;

    final crossingRate =
        (fabric2.invariants.crossingNumber -
            fabric1.invariants.crossingNumber) /
        timeSeconds;

    // Calculate polynomial coefficient rates
    final jones1 = fabric1.invariants.jonesPolynomial.coefficients;
    final jones2 = fabric2.invariants.jonesPolynomial.coefficients;
    final jonesRate = _calculatePolynomialRate(jones1, jones2, timeSeconds);

    final alexander1 = fabric1.invariants.alexanderPolynomial.coefficients;
    final alexander2 = fabric2.invariants.alexanderPolynomial.coefficients;
    final alexanderRate = _calculatePolynomialRate(
      alexander1,
      alexander2,
      timeSeconds,
    );

    return EvolutionRate(
      stabilityRate: stabilityRate,
      densityRate: densityRate,
      crossingRate: crossingRate,
      jonesRate: jonesRate,
      alexanderRate: alexanderRate,
    );
  }

  /// Calculate rate of change for polynomial coefficients
  List<double> _calculatePolynomialRate(
    List<double> poly1,
    List<double> poly2,
    double timeSeconds,
  ) {
    final maxLength = poly1.length > poly2.length ? poly1.length : poly2.length;
    final rate = <double>[];

    for (int i = 0; i < maxLength; i++) {
      final val1 = i < poly1.length ? poly1[i] : 0.0;
      final val2 = i < poly2.length ? poly2[i] : 0.0;
      rate.add((val2 - val1) / timeSeconds);
    }

    return rate;
  }

  /// Predict fabric state using evolution dynamics
  ///
  /// **Formula:**
  /// F(t) = F(t₀) + ∫[t₀ to t] dF/dt dt
  ///
  /// Where dF/dt = α·(F_ideal - F) + β·external_forces
  KnotFabric predictFabricState({
    required KnotFabric currentFabric,
    required DateTime currentTime,
    required DateTime futureTime,
    EvolutionRate? evolutionRate,
    List<FabricSnapshot>? historySnapshots,
  }) {
    final timeDelta = futureTime.difference(currentTime);
    final timeSeconds = timeDelta.inSeconds.toDouble();

    if (timeSeconds <= 0) {
      return currentFabric;
    }

    // Calculate evolution rate if not provided
    EvolutionRate rate;
    if (evolutionRate != null) {
      rate = evolutionRate;
    } else if (historySnapshots != null && historySnapshots.length >= 2) {
      // Calculate from history
      final sorted = List<FabricSnapshot>.from(historySnapshots)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      rate = calculateEvolutionRate(sorted[sorted.length - 2], sorted.last);
    } else {
      // Use default rate (no change)
      rate = EvolutionRate(
        stabilityRate: 0.0,
        densityRate: 0.0,
        crossingRate: 0.0,
        jonesRate: <double>[],
        alexanderRate: <double>[],
      );
    }

    // Apply relaxation toward ideal state
    final idealStability =
        idealFabric?.invariants.stability ?? currentFabric.invariants.stability;
    final idealDensity =
        idealFabric?.invariants.density ?? currentFabric.invariants.density;

    // Evolution equation: dF/dt = α·(F_ideal - F) + rate
    final stabilityChange =
        relaxationRate *
            (idealStability - currentFabric.invariants.stability) *
            timeSeconds +
        rate.stabilityRate * timeSeconds;

    final densityChange =
        relaxationRate *
            (idealDensity - currentFabric.invariants.density) *
            timeSeconds +
        rate.densityRate * timeSeconds;

    final crossingChange = rate.crossingRate * timeSeconds;

    // Apply changes
    final newStability = (currentFabric.invariants.stability + stabilityChange)
        .clamp(0.0, 1.0);
    final newDensity = (currentFabric.invariants.density + densityChange).clamp(
      0.0,
      double.infinity,
    );
    final newCrossingNumber =
        (currentFabric.invariants.crossingNumber + crossingChange.round())
            .clamp(0, 100);

    // Evolve polynomial coefficients
    final currentJones = currentFabric.invariants.jonesPolynomial.coefficients;
    final newJones = _evolvePolynomial(
      currentJones,
      rate.jonesRate,
      timeSeconds,
    );

    final currentAlexander =
        currentFabric.invariants.alexanderPolynomial.coefficients;
    final newAlexander = _evolvePolynomial(
      currentAlexander,
      rate.alexanderRate,
      timeSeconds,
    );

    return currentFabric.copyWith(
      invariants: FabricInvariants(
        jonesPolynomial: Polynomial(newJones),
        alexanderPolynomial: Polynomial(newAlexander),
        crossingNumber: newCrossingNumber,
        density: newDensity,
        stability: newStability,
      ),
      updatedAt: futureTime,
    );
  }

  /// Evolve polynomial coefficients based on rate
  List<double> _evolvePolynomial(
    List<double> current,
    List<double> rate,
    double timeSeconds,
  ) {
    final maxLength = current.length > rate.length
        ? current.length
        : rate.length;
    final evolved = <double>[];

    for (int i = 0; i < maxLength; i++) {
      final val = i < current.length ? current[i] : 0.0;
      final rateVal = i < rate.length ? rate[i] : 0.0;
      evolved.add(val + rateVal * timeSeconds);
    }

    return evolved;
  }

  /// Calculate ideal fabric state from history
  ///
  /// Uses average of recent snapshots as ideal state
  KnotFabric? calculateIdealFabric(List<FabricSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return null;
    }

    // Use most recent snapshot as ideal (or average of recent ones)
    final sorted = List<FabricSnapshot>.from(snapshots)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Use most recent snapshot
    return sorted.first.fabric;
  }
}

/// Evolution rate (dF/dt)
///
/// Represents rate of change for fabric properties
class EvolutionRate {
  /// Rate of change for stability
  final double stabilityRate;

  /// Rate of change for density
  final double densityRate;

  /// Rate of change for crossing number
  final double crossingRate;

  /// Rate of change for Jones polynomial coefficients
  final List<double> jonesRate;

  /// Rate of change for Alexander polynomial coefficients
  final List<double> alexanderRate;

  EvolutionRate({
    required this.stabilityRate,
    required this.densityRate,
    required this.crossingRate,
    required this.jonesRate,
    required this.alexanderRate,
  });

  /// Get magnitude of evolution rate
  double get magnitude {
    return math.sqrt(
      stabilityRate * stabilityRate +
          densityRate * densityRate +
          crossingRate * crossingRate +
          jonesRate.fold(0.0, (sum, r) => sum + r * r) +
          alexanderRate.fold(0.0, (sum, r) => sum + r * r),
    );
  }
}
