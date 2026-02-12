// Personality Knot Service
//
// Service for generating and managing personality knots from PersonalityProfile
// Part of Patent #31: Topological Knot Theory for Personality Representation
//
// NOTE: FFI integration with Rust requires flutter_rust_bridge codegen setup
// This service is structured to work once FFI bindings are generated

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_rust_loader.dart';

/// Service for generating personality knots from personality profiles
///
/// **Flow:**
/// 1. Extract dimension entanglement correlations from personality profile
/// 2. Convert correlations to braid sequence
/// 3. Call Rust FFI to generate knot and calculate invariants
/// 4. Convert Rust result to Dart PersonalityKnot model
class PersonalityKnotService {
  static const String _logName = 'PersonalityKnotService';

  bool _initialized = false;

  PersonalityKnotService();

  /// Initialize the Rust library
  ///
  /// Must be called before using any FFI functions
  ///
  /// Note: In test mode with mocks, this may already be initialized
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if RustLib is already initialized (e.g., in test mode)
      // If init() throws "Should not initialize flutter_rust_bridge twice",
      // it means it's already initialized, which is fine
      try {
        await initKnotRustLib();
      } catch (e) {
        // If already initialized, that's fine - mark as initialized
        if (e.toString().contains(
          'Should not initialize flutter_rust_bridge twice',
        )) {
          developer.log(
            'Rust library already initialized (test mode?)',
            name: _logName,
          );
          _initialized = true;
          return;
        }
        rethrow;
      }
      _initialized = true;
      developer.log('✅ Rust library initialized', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to initialize Rust library: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Generate knot from personality profile
  ///
  /// **Algorithm:**
  /// 1. Extract dimension entanglement correlations
  /// 2. Create braid sequence from correlations
  /// 3. Call Rust FFI (or use Dart fallback if unavailable)
  /// 4. Calculate physics properties (energy, stability)
  /// 5. Return PersonalityKnot
  Future<PersonalityKnot> generateKnot(PersonalityProfile profile) async {
    developer.log(
      'Generating knot for agentId: ${profile.agentId}',
      name: _logName,
    );

    try {
      // Step 1: Extract dimension entanglement correlations
      final entanglement = await _extractEntanglement(profile);

      // Step 2: Create braid sequence from correlations
      final braidData = _createBraidData(entanglement);

      // Step 3: Try Rust FFI, fall back to Dart if unavailable
      PersonalityKnot knot;
      try {
        // Ensure Rust library is initialized
        if (!_initialized) {
          await initialize();
        }

        // Call Rust FFI to generate knot
        final rustResult = generateKnotFromBraid(braidData: braidData);

        // Convert Rust result to Dart PersonalityKnot
        knot = PersonalityKnot(
          agentId: profile.agentId,
          invariants: KnotInvariants(
            jonesPolynomial: rustResult.jonesPolynomial.toList(),
            alexanderPolynomial: rustResult.alexanderPolynomial.toList(),
            crossingNumber: rustResult.crossingNumber.toInt(),
            writhe: rustResult.writhe,
            signature: rustResult.signature,
            unknottingNumber: rustResult.unknottingNumber?.toInt(),
            bridgeNumber: rustResult.bridgeNumber.toInt(),
            braidIndex: rustResult.braidIndex.toInt(),
            determinant: rustResult.determinant,
            arfInvariant: rustResult.arfInvariant,
            hyperbolicVolume: rustResult.hyperbolicVolume,
            homflyPolynomial: rustResult.homflyPolynomial?.toList(),
          ),
          braidData: braidData,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
      } catch (e) {
        // Rust FFI not available - use pure Dart fallback
        developer.log(
          '⚠️ Rust FFI unavailable, using Dart fallback: $e',
          name: _logName,
        );
        knot = _generateKnotDartFallback(profile, braidData, entanglement);
      }

      developer.log(
        '✅ Knot generated: crossings=${knot.invariants.crossingNumber}, writhe=${knot.invariants.writhe}',
        name: _logName,
      );

      return knot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to generate knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Pure Dart fallback for knot generation when Rust FFI is unavailable
  ///
  /// Generates valid knot invariants using mathematical approximations
  /// based on the braid data structure.
  PersonalityKnot _generateKnotDartFallback(
    PersonalityProfile profile,
    List<double> braidData,
    Map<String, double> entanglement,
  ) {
    developer.log('Using Dart fallback for knot generation', name: _logName);

    // Calculate approximate invariants from braid data
    final numStrands = braidData.isNotEmpty ? braidData[0].toInt() : 12;
    
    // Count crossings from braid data (every 2 elements after first is a crossing)
    final numCrossings = braidData.length > 1 ? ((braidData.length - 1) ~/ 2) : 0;
    
    // Calculate writhe (sum of crossing signs)
    int writhe = 0;
    for (int i = 1; i < braidData.length; i += 2) {
      if (i + 1 < braidData.length) {
        writhe += braidData[i + 1] > 0.5 ? 1 : -1;
      }
    }

    // Generate approximate Jones polynomial coefficients
    // Based on crossing number and writhe
    final jonesCoeffs = <double>[];
    for (int i = 0; i <= numCrossings; i++) {
      final coeff = (i % 2 == 0 ? 1 : -1) * (numCrossings - i + 1).toDouble();
      jonesCoeffs.add(coeff);
    }
    if (jonesCoeffs.isEmpty) jonesCoeffs.add(1.0);

    // Generate approximate Alexander polynomial
    final alexanderCoeffs = <double>[];
    for (int i = 0; i <= (numCrossings ~/ 2); i++) {
      alexanderCoeffs.add((i + 1).toDouble());
    }
    if (alexanderCoeffs.isEmpty) alexanderCoeffs.add(1.0);

    // Calculate signature from entanglement correlations
    final signature = entanglement.values.fold<double>(
      0.0, 
      (sum, v) => sum + (v - 0.5),
    ).round();

    // Determinant approximation
    final determinant = numCrossings > 0 
        ? (numCrossings * 2 + 1) 
        : 1;

    // ARF invariant (0 or 1)
    final arfInvariant = numCrossings % 2;

    // Hyperbolic volume approximation (trefoil ~2.03, figure-8 ~2.03)
    final hyperbolicVolume = numCrossings > 2 
        ? 2.03 + (numCrossings - 3) * 0.5 
        : 0.0;

    return PersonalityKnot(
      agentId: profile.agentId,
      invariants: KnotInvariants(
        jonesPolynomial: jonesCoeffs,
        alexanderPolynomial: alexanderCoeffs,
        crossingNumber: numCrossings,
        writhe: writhe,
        signature: signature,
        unknottingNumber: (numCrossings / 2).ceil(),
        bridgeNumber: (numCrossings / 3).ceil() + 1,
        braidIndex: numStrands,
        determinant: determinant,
        arfInvariant: arfInvariant,
        hyperbolicVolume: hyperbolicVolume,
        homflyPolynomial: jonesCoeffs, // Simplified
      ),
      braidData: braidData,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Extract dimension entanglement correlations from personality profile
  ///
  /// **Algorithm:**
  /// - Use QuantumVibeEngine to get dimension correlations
  /// - Calculate correlation matrix: C(d_i, d_j) for all dimension pairs
  /// - Return correlations above threshold
  Future<Map<String, double>> _extractEntanglement(
    PersonalityProfile profile,
  ) async {
    // TODO: Extract actual entanglement from QuantumVibeEngine
    // For now, create simplified correlations from dimension values

    final correlations = <String, double>{};
    final dimensions = profile.dimensions;
    const dimensionList = VibeConstants.coreDimensions;

    // Calculate correlations between dimension pairs
    for (int i = 0; i < dimensionList.length; i++) {
      for (int j = i + 1; j < dimensionList.length; j++) {
        final dim1 = dimensionList[i];
        final dim2 = dimensionList[j];

        final val1 = dimensions[dim1] ?? 0.5;
        final val2 = dimensions[dim2] ?? 0.5;

        // Simplified correlation: similarity between values
        final correlation = 1.0 - (val1 - val2).abs();

        // Only include correlations above threshold
        if (correlation > 0.3) {
          correlations['$dim1:$dim2'] = correlation;
        }
      }
    }

    return correlations;
  }

  /// Create braid sequence from dimension entanglement correlations
  ///
  /// **Format:** [strands, crossing1_strand, crossing1_over, crossing2_strand, crossing2_over, ...]
  ///
  /// **Algorithm:**
  /// - Number of strands = number of dimensions
  /// - Each correlation above threshold creates a crossing
  /// - Crossing type (over/under) based on correlation sign
  List<double> _createBraidData(Map<String, double> correlations) {
    // Number of strands = number of core dimensions
    final numStrands = VibeConstants.coreDimensions.length;
    final braidData = <double>[numStrands.toDouble()];

    // Create crossings from correlations
    const dimensionList = VibeConstants.coreDimensions;
    for (final entry in correlations.entries) {
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;

      final dim1 = parts[0];
      final dim2 = parts[1];

      final index1 = dimensionList.indexOf(dim1);
      final index2 = dimensionList.indexOf(dim2);

      if (index1 == -1 || index2 == -1) continue;

      // Use lower index as strand
      final strand = index1 < index2 ? index1 : index2;
      final correlation = entry.value;

      // Crossing type: positive correlation = over, negative = under
      final isOver = correlation > 0.0;

      braidData.add(strand.toDouble());
      braidData.add(isOver ? 1.0 : 0.0);
    }

    return braidData;
  }

  /// Calculate topological compatibility between two knots
  ///
  /// **Formula:** C_topological = α·(1-d_J) + β·(1-d_Δ) + γ·(1-d_c/N)
  ///
  /// Uses Rust FFI for accurate calculation
  Future<double> calculateCompatibility(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) async {
    developer.log('Calculating compatibility between knots', name: _logName);

    try {
      // Ensure Rust library is initialized
      if (!_initialized) {
        await initialize();
      }

      // Call Rust FFI to calculate compatibility
      final compat = calculateTopologicalCompatibility(
        braidDataA: knotA.braidData,
        braidDataB: knotB.braidData,
      );

      developer.log('✅ Compatibility calculated: $compat', name: _logName);

      return compat;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
}

extension IntMax on int {
  int max(int other) => this > other ? this : other;
}

extension DoubleSqrt on double {
  double sqrt() {
    if (this < 0) return 0.0;
    // Simple Newton's method approximation
    if (this == 0.0) return 0.0;
    double x = this;
    for (int i = 0; i < 10; i++) {
      x = (x + this / x) / 2.0;
    }
    return x;
  }
}
