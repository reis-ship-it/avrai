// Knot Evolution String Service
//
// Converts knot evolution history (discrete snapshots) into continuous string representation
// Enables temporal tracking, interpolation, and prediction of knot evolution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Evolution Tracking for String Generation

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/string_physics_service.dart';
import 'package:avrai_knot/utils/polynomial_interpolation.dart';

/// String representation of knot evolution
///
/// Represents continuous evolution: σ(τ, t) = K(t)
/// Where:
/// - τ = spatial parameter (0 to 1) - position along knot
/// - t = time parameter
/// - σ(τ, t) = knot configuration at time t
class KnotString {
  /// Initial knot (at t=0 or earliest snapshot)
  final PersonalityKnot initialKnot;

  /// Evolution snapshots (discrete points)
  final List<KnotSnapshot> snapshots;

  /// Evolution function parameters
  final EvolutionFunctionParams params;

  KnotString({
    required this.initialKnot,
    required this.snapshots,
    this.params = const EvolutionFunctionParams(),
  });

  /// Get knot at any time t (interpolated between snapshots)
  ///
  /// Uses linear interpolation between nearest snapshots
  /// If t is before first snapshot, returns initial knot
  /// If t is after last snapshot, extrapolates using evolution dynamics
  PersonalityKnot? getKnotAtTime(DateTime t) {
    if (snapshots.isEmpty) {
      return initialKnot;
    }

    // Sort snapshots by timestamp
    final sortedSnapshots = List<KnotSnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Check if before first snapshot
    if (t.isBefore(sortedSnapshots.first.timestamp)) {
      return initialKnot;
    }

    // Check if after last snapshot (extrapolate)
    if (t.isAfter(sortedSnapshots.last.timestamp)) {
      return _extrapolateFutureKnot(sortedSnapshots.last, t);
    }

    // Find surrounding snapshots
    KnotSnapshot? before;
    KnotSnapshot? after;

    for (int i = 0; i < sortedSnapshots.length; i++) {
      if (sortedSnapshots[i].timestamp.isAfter(t)) {
        after = sortedSnapshots[i];
        if (i > 0) {
          before = sortedSnapshots[i - 1];
        } else {
          before = null; // Before first snapshot
        }
        break;
      }
    }

    // If exactly on a snapshot
    if (before != null && before.timestamp == t) {
      return before.knot;
    }
    if (after != null && after.timestamp == t) {
      return after.knot;
    }

    // Interpolate between snapshots
    if (before != null && after != null) {
      return _interpolateKnots(before, after, t);
    } else if (after != null) {
      // Between initial and first snapshot
      return _interpolateKnots(
        KnotSnapshot(timestamp: initialKnot.createdAt, knot: initialKnot),
        after,
        t,
      );
    }

    return null;
  }

  /// Get evolution trajectory (smooth curve through time)
  ///
  /// Generates sequence of knots at regular intervals
  List<PersonalityKnot> getEvolutionTrajectory({
    required DateTime start,
    required DateTime end,
    required Duration step,
  }) {
    final trajectory = <PersonalityKnot>[];
    var currentTime = start;

    while (!currentTime.isAfter(end)) {
      final knot = getKnotAtTime(currentTime);
      if (knot != null) {
        trajectory.add(knot);
      }
      currentTime = currentTime.add(step);
    }

    return trajectory;
  }

  /// Interpolate between two knots
  PersonalityKnot _interpolateKnots(
    KnotSnapshot snapshot1,
    KnotSnapshot snapshot2,
    DateTime targetTime,
  ) {
    final knot1 = snapshot1.knot;
    final knot2 = snapshot2.knot;
    final t1 = snapshot1.timestamp;
    final t2 = snapshot2.timestamp;

    // Calculate interpolation factor (0.0 = knot1, 1.0 = knot2)
    final totalDuration = t2.difference(t1).inMilliseconds;
    final targetDuration = targetTime.difference(t1).inMilliseconds;
    final factor =
        (targetDuration / totalDuration.clamp(1, double.maxFinite.toInt()))
            .clamp(0.0, 1.0);

    // Interpolate invariants using cubic spline
    final jones1 = knot1.invariants.jonesPolynomial;
    final jones2 = knot2.invariants.jonesPolynomial;
    final interpolatedJones = cubicSplineInterpolateList(
      jones1,
      jones2,
      factor,
    );

    final alexander1 = knot1.invariants.alexanderPolynomial;
    final alexander2 = knot2.invariants.alexanderPolynomial;
    final interpolatedAlexander = cubicSplineInterpolateList(
      alexander1,
      alexander2,
      factor,
    );

    // Use cubic spline for scalar interpolation
    final interpolatedCrossings = cubicSplineInterpolateScalar([
      knot1.invariants.crossingNumber.toDouble(),
      knot2.invariants.crossingNumber.toDouble(),
    ], factor).round();

    final interpolatedWrithe = cubicSplineInterpolateScalar([
      knot1.invariants.writhe.toDouble(),
      knot2.invariants.writhe.toDouble(),
    ], factor).round();

    // Interpolate braid data (simplified - use weighted average)
    final braid1 = knot1.braidData;
    final braid2 = knot2.braidData;
    final interpolatedBraid = _interpolateBraidData(braid1, braid2, factor);

    // Interpolate all invariants using cubic spline
    final interpolatedSignature = cubicSplineInterpolateScalar([
      knot1.invariants.signature.toDouble(),
      knot2.invariants.signature.toDouble(),
    ], factor).round();

    final interpolatedBridgeNumber = cubicSplineInterpolateScalar([
      knot1.invariants.bridgeNumber.toDouble(),
      knot2.invariants.bridgeNumber.toDouble(),
    ], factor).round();

    final interpolatedBraidIndex = cubicSplineInterpolateScalar([
      knot1.invariants.braidIndex.toDouble(),
      knot2.invariants.braidIndex.toDouble(),
    ], factor).round();

    final interpolatedDeterminant = cubicSplineInterpolateScalar([
      knot1.invariants.determinant.toDouble(),
      knot2.invariants.determinant.toDouble(),
    ], factor).round();

    // For optional invariants, use first knot's value if both have it, otherwise null
    final interpolatedUnknottingNumber =
        knot1.invariants.unknottingNumber != null &&
            knot2.invariants.unknottingNumber != null
        ? ((knot1.invariants.unknottingNumber! * (1 - factor)) +
                  (knot2.invariants.unknottingNumber! * factor))
              .round()
        : null;

    final interpolatedArfInvariant =
        knot1.invariants.arfInvariant != null &&
            knot2.invariants.arfInvariant != null
        ? ((knot1.invariants.arfInvariant! * (1 - factor)) +
                  (knot2.invariants.arfInvariant! * factor))
              .round()
        : null;

    final interpolatedHyperbolicVolume =
        knot1.invariants.hyperbolicVolume != null &&
            knot2.invariants.hyperbolicVolume != null
        ? (knot1.invariants.hyperbolicVolume! * (1 - factor)) +
              (knot2.invariants.hyperbolicVolume! * factor)
        : null;

    // HOMFLY polynomial interpolation using cubic spline (if both have it)
    final interpolatedHomfly =
        knot1.invariants.homflyPolynomial != null &&
            knot2.invariants.homflyPolynomial != null
        ? cubicSplineInterpolateList(
            knot1.invariants.homflyPolynomial!,
            knot2.invariants.homflyPolynomial!,
            factor,
          )
        : null;

    return PersonalityKnot(
      agentId: knot1.agentId, // Use first knot's agentId
      invariants: KnotInvariants(
        jonesPolynomial: interpolatedJones,
        alexanderPolynomial: interpolatedAlexander,
        crossingNumber: interpolatedCrossings,
        writhe: interpolatedWrithe,
        signature: interpolatedSignature,
        unknottingNumber: interpolatedUnknottingNumber,
        bridgeNumber: interpolatedBridgeNumber,
        braidIndex: interpolatedBraidIndex,
        determinant: interpolatedDeterminant,
        arfInvariant: interpolatedArfInvariant,
        hyperbolicVolume: interpolatedHyperbolicVolume,
        homflyPolynomial: interpolatedHomfly,
      ),
      braidData: interpolatedBraid,
      createdAt: knot1.createdAt,
      lastUpdated: targetTime,
    );
  }

  /// Interpolate polynomial coefficients (deprecated - use cubicSplineInterpolateList)
  ///
  /// Kept for backward compatibility, but now uses cubic spline interpolation
  @Deprecated(
    'Use cubicSplineInterpolateList from polynomial_interpolation.dart',
  )
  // ignore: unused_element
  List<double> _interpolatePolynomials(
    List<double> poly1,
    List<double> poly2,
    double factor,
  ) {
    // Use cubic spline interpolation for smoother curves
    return cubicSplineInterpolateList(poly1, poly2, factor);
  }

  /// Interpolate braid data
  List<double> _interpolateBraidData(
    List<double> braid1,
    List<double> braid2,
    double factor,
  ) {
    // Braid data format: [strands, crossing1_strand, crossing1_over, ...]
    // Interpolate strand count (use weighted average, round to int)
    if (braid1.isEmpty || braid2.isEmpty) {
      return braid1.isNotEmpty ? braid1 : braid2;
    }

    final strands1 = braid1[0].toInt();
    final strands2 = braid2[0].toInt();
    final interpolatedStrands =
        ((strands1 * (1 - factor)) + (strands2 * factor)).round();

    final interpolated = <double>[interpolatedStrands.toDouble()];

    // Interpolate crossings (simplified - use longer braid as base)
    final baseBraid = braid1.length > braid2.length ? braid1 : braid2;
    final otherBraid = braid1.length > braid2.length ? braid2 : braid1;
    final useFactor = braid1.length > braid2.length ? (1 - factor) : factor;

    // Start from index 1 (skip strand count)
    for (int i = 1; i < baseBraid.length; i++) {
      if (i < otherBraid.length) {
        interpolated.add(
          baseBraid[i] * useFactor + otherBraid[i] * (1 - useFactor),
        );
      } else {
        interpolated.add(baseBraid[i] * useFactor);
      }
    }

    return interpolated;
  }

  /// Extrapolate future knot using evolution dynamics and string physics
  ///
  /// **Formula:**
  /// K(t_future) = K(t_last) + ∫[t_last to t_future] dK/dt dt
  ///
  /// Where dK/dt is calculated from string physics (tension, relaxation, etc.)
  PersonalityKnot _extrapolateFutureKnot(
    KnotSnapshot lastSnapshot,
    DateTime futureTime,
  ) {
    if (snapshots.length < 2) {
      // Not enough data for extrapolation, return last knot
      return lastSnapshot.knot;
    }

    // Calculate evolution rate from last two snapshots
    final sortedSnapshots = List<KnotSnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final last = sortedSnapshots.last;
    final secondLast = sortedSnapshots.length >= 2
        ? sortedSnapshots[sortedSnapshots.length - 2]
        : null;

    if (secondLast == null) {
      return last.knot;
    }

    // Calculate time delta
    final timeDelta = futureTime.difference(last.timestamp);
    final historyDelta = last.timestamp.difference(secondLast.timestamp);

    if (historyDelta.inMilliseconds == 0) {
      return last.knot; // No history to extrapolate from
    }

    // Use string physics for extrapolation
    final lastKnot = last.knot;
    final secondLastKnot = sortedSnapshots.length >= 3
        ? sortedSnapshots[sortedSnapshots.length - 3].knot
        : secondLast.knot;

    // Calculate evolution rate: how many "history periods" into the future we're predicting
    // If we're predicting 2 hours ahead and snapshots are 1 hour apart, rate = 2.0
    final evolutionRate = historyDelta.inMilliseconds > 0
        ? timeDelta.inMilliseconds / historyDelta.inMilliseconds
        : 1.0;

    final jonesDelta = _polynomialDifference(
      secondLastKnot.invariants.jonesPolynomial,
      lastKnot.invariants.jonesPolynomial,
    );
    final extrapolatedJones = _addPolynomials(
      lastKnot.invariants.jonesPolynomial,
      _scalePolynomial(jonesDelta, evolutionRate),
    );

    final alexanderDelta = _polynomialDifference(
      secondLastKnot.invariants.alexanderPolynomial,
      lastKnot.invariants.alexanderPolynomial,
    );
    final extrapolatedAlexander = _addPolynomials(
      lastKnot.invariants.alexanderPolynomial,
      _scalePolynomial(alexanderDelta, evolutionRate),
    );

    final crossingDelta =
        lastKnot.invariants.crossingNumber -
        secondLastKnot.invariants.crossingNumber;
    final extrapolatedCrossings =
        (lastKnot.invariants.crossingNumber + (crossingDelta * evolutionRate))
            .round()
            .clamp(0, 100);

    final writheDelta =
        lastKnot.invariants.writhe - secondLastKnot.invariants.writhe;
    final extrapolatedWrithe =
        (lastKnot.invariants.writhe + (writheDelta * evolutionRate)).round();

    // Extrapolate all other invariants
    final signatureDelta =
        lastKnot.invariants.signature - secondLastKnot.invariants.signature;
    final extrapolatedSignature =
        (lastKnot.invariants.signature + (signatureDelta * evolutionRate))
            .round();

    final bridgeDelta =
        lastKnot.invariants.bridgeNumber -
        secondLastKnot.invariants.bridgeNumber;
    final extrapolatedBridgeNumber =
        (lastKnot.invariants.bridgeNumber + (bridgeDelta * evolutionRate))
            .round()
            .clamp(1, 100);

    final braidIndexDelta =
        lastKnot.invariants.braidIndex - secondLastKnot.invariants.braidIndex;
    final extrapolatedBraidIndex =
        (lastKnot.invariants.braidIndex + (braidIndexDelta * evolutionRate))
            .round()
            .clamp(1, 12);

    final determinantDelta =
        lastKnot.invariants.determinant - secondLastKnot.invariants.determinant;
    final extrapolatedDeterminant =
        (lastKnot.invariants.determinant + (determinantDelta * evolutionRate))
            .round();

    // For optional invariants, extrapolate if both have values
    final extrapolatedUnknottingNumber =
        lastKnot.invariants.unknottingNumber != null &&
            secondLastKnot.invariants.unknottingNumber != null
        ? (lastKnot.invariants.unknottingNumber! +
                  ((lastKnot.invariants.unknottingNumber! -
                          secondLastKnot.invariants.unknottingNumber!) *
                      evolutionRate))
              .round()
              .clamp(0, lastKnot.invariants.crossingNumber)
        : null;

    final extrapolatedArfInvariant =
        lastKnot.invariants.arfInvariant != null &&
            secondLastKnot.invariants.arfInvariant != null
        ? (lastKnot.invariants.arfInvariant! +
                      ((lastKnot.invariants.arfInvariant! -
                              secondLastKnot.invariants.arfInvariant!) *
                          evolutionRate))
                  .round() %
              2
        : null;

    final extrapolatedHyperbolicVolume =
        lastKnot.invariants.hyperbolicVolume != null &&
            secondLastKnot.invariants.hyperbolicVolume != null
        ? (lastKnot.invariants.hyperbolicVolume! +
                  ((lastKnot.invariants.hyperbolicVolume! -
                          secondLastKnot.invariants.hyperbolicVolume!) *
                      evolutionRate))
              .clamp(0.0, double.infinity)
        : null;

    // HOMFLY polynomial extrapolation (if available)
    final extrapolatedHomfly =
        lastKnot.invariants.homflyPolynomial != null &&
            secondLastKnot.invariants.homflyPolynomial != null
        ? _addPolynomials(
            lastKnot.invariants.homflyPolynomial!,
            _scalePolynomial(
              _polynomialDifference(
                secondLastKnot.invariants.homflyPolynomial!,
                lastKnot.invariants.homflyPolynomial!,
              ),
              evolutionRate,
            ),
          )
        : null;

    return PersonalityKnot(
      agentId: lastKnot.agentId,
      invariants: KnotInvariants(
        jonesPolynomial: extrapolatedJones,
        alexanderPolynomial: extrapolatedAlexander,
        crossingNumber: extrapolatedCrossings,
        writhe: extrapolatedWrithe,
        signature: extrapolatedSignature,
        unknottingNumber: extrapolatedUnknottingNumber,
        bridgeNumber: extrapolatedBridgeNumber,
        braidIndex: extrapolatedBraidIndex,
        determinant: extrapolatedDeterminant,
        arfInvariant: extrapolatedArfInvariant,
        hyperbolicVolume: extrapolatedHyperbolicVolume,
        homflyPolynomial: extrapolatedHomfly,
      ),
      braidData: lastKnot.braidData, // Use last braid (simplified)
      createdAt: lastKnot.createdAt,
      lastUpdated: futureTime,
    );
  }

  /// Calculate difference between polynomials
  List<double> _polynomialDifference(List<double> poly1, List<double> poly2) {
    final maxLength = poly1.length > poly2.length ? poly1.length : poly2.length;
    final diff = <double>[];

    for (int i = 0; i < maxLength; i++) {
      final val1 = i < poly1.length ? poly1[i] : 0.0;
      final val2 = i < poly2.length ? poly2[i] : 0.0;
      diff.add(val1 - val2);
    }

    return diff;
  }

  /// Add two polynomials
  List<double> _addPolynomials(List<double> poly1, List<double> poly2) {
    final maxLength = poly1.length > poly2.length ? poly1.length : poly2.length;
    final sum = <double>[];

    for (int i = 0; i < maxLength; i++) {
      final val1 = i < poly1.length ? poly1[i] : 0.0;
      final val2 = i < poly2.length ? poly2[i] : 0.0;
      sum.add(val1 + val2);
    }

    return sum;
  }

  /// Scale polynomial by factor
  List<double> _scalePolynomial(List<double> poly, double factor) {
    return poly.map((coeff) => coeff * factor).toList();
  }
}

/// Evolution function parameters
class EvolutionFunctionParams {
  /// Time step for evolution (default: 1 hour)
  final Duration timeStep;

  /// Relaxation rate (α in dynamics equation)
  final double relaxationRate;

  /// External force strength (β in dynamics equation)
  final double externalForceStrength;

  const EvolutionFunctionParams({
    this.timeStep = const Duration(hours: 1),
    this.relaxationRate = 0.1,
    this.externalForceStrength = 0.05,
  });
}

/// Service for converting knot evolution history to string representation
///
/// **Responsibilities:**
/// - Load evolution history (snapshots)
/// - Convert snapshots to continuous string representation
/// - Interpolate knots at any time point
/// - Generate evolution trajectories
/// - Predict future evolution
class KnotEvolutionStringService {
  static const String _logName = 'KnotEvolutionStringService';

  final KnotStorageService _storageService;
  // TODO(Phase 5.3): Integrate physics service for evolution dynamics
  // ignore: unused_field
  final StringPhysicsService _physicsService;

  KnotEvolutionStringService({
    required KnotStorageService storageService,
    StringPhysicsService? physicsService,
  }) : _storageService = storageService,
       _physicsService = physicsService ?? StringPhysicsService();

  /// Create string representation from evolution history
  ///
  /// Loads snapshots and creates continuous string representation
  Future<KnotString?> createStringFromHistory(String agentId) async {
    try {
      developer.log(
        'Creating string from evolution history for agentId: ${agentId.substring(0, 10)}...',
        name: _logName,
      );

      // Load evolution history
      final snapshots = await _storageService.loadEvolutionHistory(agentId);

      if (snapshots.isEmpty) {
        // No history yet - get current knot as initial
        final currentKnot = await _storageService.loadKnot(agentId);
        if (currentKnot == null) {
          developer.log(
            'No knot found for agentId, cannot create string',
            name: _logName,
          );
          return null;
        }

        return KnotString(initialKnot: currentKnot, snapshots: []);
      }

      // Sort snapshots by timestamp
      final sortedSnapshots = List<KnotSnapshot>.from(snapshots)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Use first snapshot as initial knot
      final initialKnot = sortedSnapshots.first.knot;

      developer.log(
        '✅ String created: ${sortedSnapshots.length} snapshots, '
        'span: ${sortedSnapshots.first.timestamp} to ${sortedSnapshots.last.timestamp}',
        name: _logName,
      );

      return KnotString(initialKnot: initialKnot, snapshots: sortedSnapshots);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create string from history: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get knot at any time (interpolated from string)
  ///
  /// Uses string representation to interpolate between snapshots
  Future<PersonalityKnot?> getKnotAtTime(String agentId, DateTime t) async {
    try {
      final string = await createStringFromHistory(agentId);
      if (string == null) {
        return null;
      }

      return string.getKnotAtTime(t);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get knot at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get evolution trajectory (smooth curve through time)
  ///
  /// Generates sequence of knots at regular intervals
  Future<List<PersonalityKnot>> getEvolutionTrajectory({
    required String agentId,
    required DateTime start,
    required DateTime end,
    required Duration step,
  }) async {
    try {
      final string = await createStringFromHistory(agentId);
      if (string == null) {
        return [];
      }

      return string.getEvolutionTrajectory(start: start, end: end, step: step);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get evolution trajectory: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Predict future knot evolution
  ///
  /// Uses string dynamics to extrapolate future knot state
  Future<PersonalityKnot?> predictFutureKnot(
    String agentId,
    DateTime futureTime,
  ) async {
    try {
      final string = await createStringFromHistory(agentId);
      if (string == null) {
        return null;
      }

      // Use string's extrapolation method
      return string.getKnotAtTime(futureTime);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to predict future knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Analyze evolution patterns
  ///
  /// Detects patterns in knot evolution (cycles, trends, milestones)
  Future<EvolutionAnalysis> analyzeEvolutionPatterns(String agentId) async {
    try {
      final snapshots = await _storageService.loadEvolutionHistory(agentId);

      if (snapshots.length < 2) {
        return EvolutionAnalysis(
          hasPatterns: false,
          cycles: [],
          trends: [],
          milestones: [],
        );
      }

      final sortedSnapshots = List<KnotSnapshot>.from(snapshots)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Detect cycles (periodic patterns)
      final cycles = _detectCycles(sortedSnapshots);

      // Detect trends (directional changes)
      final trends = _detectTrends(sortedSnapshots);

      // Detect milestones (significant events)
      final milestones = _detectMilestones(sortedSnapshots);

      return EvolutionAnalysis(
        hasPatterns:
            cycles.isNotEmpty || trends.isNotEmpty || milestones.isNotEmpty,
        cycles: cycles,
        trends: trends,
        milestones: milestones,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to analyze evolution patterns: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return EvolutionAnalysis(
        hasPatterns: false,
        cycles: [],
        trends: [],
        milestones: [],
      );
    }
  }

  /// Detect cycles in evolution
  List<EvolutionCycle> _detectCycles(List<KnotSnapshot> snapshots) {
    // Simplified cycle detection: look for repeating patterns in complexity
    final cycles = <EvolutionCycle>[];

    if (snapshots.length < 4) {
      return cycles; // Need at least 4 points to detect a cycle
    }

    // Calculate complexity over time
    final complexities = snapshots.map((s) {
      return s.knot.invariants.crossingNumber * s.knot.invariants.writhe.abs();
    }).toList();

    // Look for periodic patterns (simplified - check for similar complexity values)
    // This is a placeholder - real cycle detection would use FFT or autocorrelation
    for (int period = 2; period <= snapshots.length ~/ 2; period++) {
      bool isCycle = true;
      for (int i = 0; i < snapshots.length - period; i++) {
        final diff = (complexities[i] - complexities[i + period]).abs();
        if (diff > 5.0) {
          // Too different to be a cycle
          isCycle = false;
          break;
        }
      }

      if (isCycle) {
        cycles.add(
          EvolutionCycle(
            period: Duration(
              milliseconds: snapshots[period].timestamp
                  .difference(snapshots[0].timestamp)
                  .inMilliseconds,
            ),
            startTime: snapshots[0].timestamp,
            endTime: snapshots.last.timestamp,
          ),
        );
        break; // Found one cycle, stop
      }
    }

    return cycles;
  }

  /// Detect trends in evolution
  List<EvolutionTrend> _detectTrends(List<KnotSnapshot> snapshots) {
    final trends = <EvolutionTrend>[];

    if (snapshots.length < 2) {
      return trends;
    }

    // Calculate complexity trend
    final complexities = snapshots.map((s) {
      return s.knot.invariants.crossingNumber * s.knot.invariants.writhe.abs();
    }).toList();

    // Simple linear trend detection
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;

    for (int i = 0; i < complexities.length; i++) {
      final x = i.toDouble();
      final y = complexities[i].toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final n = complexities.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope.abs() > 0.1) {
      trends.add(
        EvolutionTrend(
          type: slope > 0 ? TrendType.increasing : TrendType.decreasing,
          magnitude: slope.abs(),
          startTime: snapshots.first.timestamp,
          endTime: snapshots.last.timestamp,
        ),
      );
    }

    return trends;
  }

  /// Detect milestones in evolution
  List<EvolutionMilestone> _detectMilestones(List<KnotSnapshot> snapshots) {
    final milestones = <EvolutionMilestone>[];

    if (snapshots.length < 2) {
      return milestones;
    }

    for (int i = 1; i < snapshots.length; i++) {
      final current = snapshots[i];
      final previous = snapshots[i - 1];

      // Check for knot type change
      final jones1 = previous.knot.invariants.jonesPolynomial;
      final jones2 = current.knot.invariants.jonesPolynomial;

      if (jones1.length != jones2.length) {
        milestones.add(
          EvolutionMilestone(
            type: MilestoneType.knotTypeChange,
            timestamp: current.timestamp,
            description:
                'Knot type changed (polynomial length: ${jones1.length} → ${jones2.length})',
          ),
        );
      } else {
        // Check for significant coefficient changes
        bool significantChange = false;
        for (int j = 0; j < jones1.length; j++) {
          if ((jones1[j] - jones2[j]).abs() > 0.5) {
            significantChange = true;
            break;
          }
        }

        if (significantChange) {
          milestones.add(
            EvolutionMilestone(
              type: MilestoneType.significantChange,
              timestamp: current.timestamp,
              description: 'Significant knot invariant change',
            ),
          );
        }
      }

      // Check for complexity milestone
      final complexity1 =
          previous.knot.invariants.crossingNumber *
          previous.knot.invariants.writhe.abs();
      final complexity2 =
          current.knot.invariants.crossingNumber *
          current.knot.invariants.writhe.abs();

      final complexityChange =
          ((complexity2 - complexity1) / complexity1.clamp(1, 100)).abs();

      if (complexityChange > 0.3) {
        milestones.add(
          EvolutionMilestone(
            type: MilestoneType.complexityMilestone,
            timestamp: current.timestamp,
            description:
                'Complexity change: ${(complexityChange * 100).toStringAsFixed(1)}%',
          ),
        );
      }
    }

    return milestones;
  }
}

/// Evolution analysis results
class EvolutionAnalysis {
  final bool hasPatterns;
  final List<EvolutionCycle> cycles;
  final List<EvolutionTrend> trends;
  final List<EvolutionMilestone> milestones;

  EvolutionAnalysis({
    required this.hasPatterns,
    required this.cycles,
    required this.trends,
    required this.milestones,
  });
}

/// Evolution cycle (periodic pattern)
class EvolutionCycle {
  final Duration period;
  final DateTime startTime;
  final DateTime endTime;

  EvolutionCycle({
    required this.period,
    required this.startTime,
    required this.endTime,
  });
}

/// Evolution trend (directional change)
enum TrendType { increasing, decreasing, stable }

class EvolutionTrend {
  final TrendType type;
  final double magnitude;
  final DateTime startTime;
  final DateTime endTime;

  EvolutionTrend({
    required this.type,
    required this.magnitude,
    required this.startTime,
    required this.endTime,
  });
}

/// Evolution milestone (significant event)
enum MilestoneType { knotTypeChange, complexityMilestone, significantChange }

class EvolutionMilestone {
  final MilestoneType type;
  final DateTime timestamp;
  final String description;

  EvolutionMilestone({
    required this.type,
    required this.timestamp,
    required this.description,
  });
}
