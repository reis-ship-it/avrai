// Personality Knot Model
// 
// Represents a personality profile as a topological knot
// Part of Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;

/// Represents knot invariants - comprehensive set for complete knot classification
/// 
/// Includes all 10+ invariants for accurate knot classification:
/// 1. Jones polynomial
/// 2. Alexander polynomial
/// 3. Crossing number
/// 4. Writhe
/// 5. Signature
/// 6. Unknotting number (lower bound)
/// 7. Bridge number
/// 8. Braid index
/// 9. Determinant
/// 10. Arf invariant
/// 11. Hyperbolic volume (optional)
/// 12. HOMFLY-PT polynomial (optional)
class KnotInvariants {
  // Existing invariants (1-4)
  /// Jones polynomial coefficients (lowest degree first)
  final List<double> jonesPolynomial;
  
  /// Alexander polynomial coefficients (lowest degree first)
  final List<double> alexanderPolynomial;
  
  /// Crossing number (minimum crossings in any diagram)
  final int crossingNumber;
  
  /// Writhe (signed sum of crossing signs)
  final int writhe;
  
  // New invariants (5-12)
  /// Signature (from Seifert matrix)
  final int signature;
  
  /// Unknotting number (lower bound, exact is NP-hard)
  final int? unknottingNumber;
  
  /// Bridge number (minimum bridges in bridge presentation)
  final int bridgeNumber;
  
  /// Braid index (minimum strands for closed braid)
  final int braidIndex;
  
  /// Determinant (from Alexander polynomial: |Δ_K(-1)|)
  final int determinant;
  
  /// Arf invariant (mod 2)
  final int? arfInvariant;
  
  /// Hyperbolic volume (only for hyperbolic knots)
  final double? hyperbolicVolume;
  
  /// HOMFLY-PT polynomial (optional, computationally expensive)
  final List<double>? homflyPolynomial;
  
  KnotInvariants({
    required this.jonesPolynomial,
    required this.alexanderPolynomial,
    required this.crossingNumber,
    required this.writhe,
    required this.signature,
    this.unknottingNumber,
    required this.bridgeNumber,
    required this.braidIndex,
    required this.determinant,
    this.arfInvariant,
    this.hyperbolicVolume,
    this.homflyPolynomial,
  });
  
  /// Create from JSON (with backward compatibility for old format)
  factory KnotInvariants.fromJson(Map<String, dynamic> json) {
    // Check if this is the new format (has signature field)
    if (json.containsKey('signature')) {
      // New format with all invariants
      return KnotInvariants(
        jonesPolynomial: List<double>.from(json['jonesPolynomial'] ?? []),
        alexanderPolynomial: List<double>.from(json['alexanderPolynomial'] ?? []),
        crossingNumber: json['crossingNumber'] ?? 0,
        writhe: json['writhe'] ?? 0,
        signature: json['signature'] ?? 0,
        unknottingNumber: json['unknottingNumber'],
        bridgeNumber: json['bridgeNumber'] ?? 1,
        braidIndex: json['braidIndex'] ?? 1,
        determinant: json['determinant'] ?? 1,
        arfInvariant: json['arfInvariant'],
        hyperbolicVolume: json['hyperbolicVolume']?.toDouble(),
        homflyPolynomial: json['homflyPolynomial'] != null
            ? List<double>.from(json['homflyPolynomial'])
            : null,
      );
    } else {
      // Old format - use legacy factory
      return KnotInvariants.fromJsonLegacy(json);
    }
  }
  
  /// Create from JSON (legacy format - backward compatibility)
  /// 
  /// For knots created before all invariants were implemented.
  /// Missing invariants are set to safe defaults or computed if possible.
  factory KnotInvariants.fromJsonLegacy(Map<String, dynamic> json) {
    return KnotInvariants(
      jonesPolynomial: List<double>.from(json['jonesPolynomial'] ?? []),
      alexanderPolynomial: List<double>.from(json['alexanderPolynomial'] ?? []),
      crossingNumber: json['crossingNumber'] ?? 0,
      writhe: json['writhe'] ?? 0,
      // New invariants with defaults (will be computed on next knot regeneration)
      signature: 0, // Default, will be computed
      unknottingNumber: null, // Unknown for legacy knots
      bridgeNumber: 1, // Safe default
      braidIndex: json['crossingNumber'] != null && json['crossingNumber'] > 0
          ? (json['crossingNumber'] as int).clamp(1, 12)
          : 1, // Estimate from crossing number
      determinant: json['alexanderPolynomial'] != null
          ? _computeDeterminantFromAlexander(
              List<double>.from(json['alexanderPolynomial']))
          : 1, // Compute from Alexander polynomial if available
      arfInvariant: null, // Cannot compute without signature
      hyperbolicVolume: null, // Unknown for legacy knots
      homflyPolynomial: null, // Not computed for legacy knots
    );
  }
  
  /// Compute determinant from Alexander polynomial: |Δ_K(-1)|
  static int _computeDeterminantFromAlexander(List<double> alexander) {
    if (alexander.isEmpty) return 1;
    
    // Evaluate polynomial at -1
    double value = 0.0;
    for (int i = 0; i < alexander.length; i++) {
      value += alexander[i] * (i == 0 ? 1.0 : math.pow(-1.0, i));
    }
    
    return value.abs().round();
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'jonesPolynomial': jonesPolynomial,
      'alexanderPolynomial': alexanderPolynomial,
      'crossingNumber': crossingNumber,
      'writhe': writhe,
      'signature': signature,
      'unknottingNumber': unknottingNumber,
      'bridgeNumber': bridgeNumber,
      'braidIndex': braidIndex,
      'determinant': determinant,
      'arfInvariant': arfInvariant,
      'hyperbolicVolume': hyperbolicVolume,
      'homflyPolynomial': homflyPolynomial,
    };
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnotInvariants &&
          runtimeType == other.runtimeType &&
          jonesPolynomial == other.jonesPolynomial &&
          alexanderPolynomial == other.alexanderPolynomial &&
          crossingNumber == other.crossingNumber &&
          writhe == other.writhe &&
          signature == other.signature &&
          unknottingNumber == other.unknottingNumber &&
          bridgeNumber == other.bridgeNumber &&
          braidIndex == other.braidIndex &&
          determinant == other.determinant &&
          arfInvariant == other.arfInvariant &&
          hyperbolicVolume == other.hyperbolicVolume &&
          homflyPolynomial == other.homflyPolynomial;
  
  @override
  int get hashCode =>
      jonesPolynomial.hashCode ^
      alexanderPolynomial.hashCode ^
      crossingNumber.hashCode ^
      writhe.hashCode ^
      signature.hashCode ^
      (unknottingNumber?.hashCode ?? 0) ^
      bridgeNumber.hashCode ^
      braidIndex.hashCode ^
      determinant.hashCode ^
      (arfInvariant?.hashCode ?? 0) ^
      (hyperbolicVolume?.hashCode ?? 0) ^
      (homflyPolynomial?.hashCode ?? 0);
}

/// Represents physics-based knot properties
class KnotPhysics {
  /// Knot energy: E_K = ∫_K |κ(s)|² ds
  final double energy;
  
  /// Knot stability: -d²E_K/dK²
  final double stability;
  
  /// Knot length
  final double length;
  
  KnotPhysics({
    required this.energy,
    required this.stability,
    required this.length,
  });
  
  /// Create from JSON
  factory KnotPhysics.fromJson(Map<String, dynamic> json) {
    return KnotPhysics(
      energy: (json['energy'] ?? 0.0).toDouble(),
      stability: (json['stability'] ?? 0.0).toDouble(),
      length: (json['length'] ?? 0.0).toDouble(),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'stability': stability,
      'length': length,
    };
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnotPhysics &&
          runtimeType == other.runtimeType &&
          energy == other.energy &&
          stability == other.stability &&
          length == other.length;
  
  @override
  int get hashCode => energy.hashCode ^ stability.hashCode ^ length.hashCode;
}

/// Represents a personality knot
class PersonalityKnot {
  /// Associated agent ID (matches PersonalityProfile.agentId)
  final String agentId;
  
  /// Knot invariants (topological properties)
  final KnotInvariants invariants;
  
  /// Physics-based properties
  final KnotPhysics? physics;
  
  /// Braid data used to generate knot
  /// Format: [strands, crossing1_strand, crossing1_over, ...]
  final List<double> braidData;
  
  /// Timestamp when knot was generated
  final DateTime createdAt;
  
  /// Timestamp when knot was last updated
  final DateTime lastUpdated;
  
  PersonalityKnot({
    required this.agentId,
    required this.invariants,
    this.physics,
    required this.braidData,
    required this.createdAt,
    required this.lastUpdated,
  });
  
  /// Create from JSON
  factory PersonalityKnot.fromJson(Map<String, dynamic> json) {
    return PersonalityKnot(
      agentId: json['agentId'] ?? '',
      invariants: KnotInvariants.fromJson(json['invariants'] as Map<String, dynamic>? ?? {}),
      physics: json['physics'] != null
          ? KnotPhysics.fromJson(json['physics'] as Map<String, dynamic>)
          : null,
      braidData: List<double>.from(json['braidData'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'invariants': invariants.toJson(),
      'physics': physics?.toJson(),
      'braidData': braidData,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Create copy with updated fields
  PersonalityKnot copyWith({
    String? agentId,
    KnotInvariants? invariants,
    KnotPhysics? physics,
    List<double>? braidData,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PersonalityKnot(
      agentId: agentId ?? this.agentId,
      invariants: invariants ?? this.invariants,
      physics: physics ?? this.physics,
      braidData: braidData ?? this.braidData,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  String toString() {
    return 'PersonalityKnot(agentId: ${agentId.substring(0, 10)}..., '
        'crossings: ${invariants.crossingNumber}, writhe: ${invariants.writhe})';
  }
}

/// Represents a snapshot of knot at a point in time (for evolution tracking)
class KnotSnapshot {
  /// Timestamp of snapshot
  final DateTime timestamp;
  
  /// Knot at this time
  final PersonalityKnot knot;
  
  /// Reason for snapshot (milestone, evolution, etc.)
  final String? reason;
  
  KnotSnapshot({
    required this.timestamp,
    required this.knot,
    this.reason,
  });
  
  /// Create from JSON
  factory KnotSnapshot.fromJson(Map<String, dynamic> json) {
    return KnotSnapshot(
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      knot: PersonalityKnot.fromJson(json['knot'] ?? {}),
      reason: json['reason'],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'knot': knot.toJson(),
      'reason': reason,
    };
  }
}