// Knot Fabric Model
// 
// Represents a multi-strand braid fabric created from multiple user knots
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';

/// Multi-strand braid representation
/// 
/// Represents a braid with multiple strands (one per user knot)
class MultiStrandBraid extends Equatable {
  /// Number of strands in the braid
  final int strandCount;
  
  /// Braid data: [strands, crossing1_strand, crossing1_over, ...]
  /// This is the format expected by the Rust FFI
  final List<double> braidData;
  
  /// Mapping from user ID to strand index
  final Map<String, int> userToStrandIndex;
  
  const MultiStrandBraid({
    required this.strandCount,
    required this.braidData,
    required this.userToStrandIndex,
  });
  
  @override
  List<Object?> get props => [strandCount, braidData, userToStrandIndex];

  /// Create from JSON
  factory MultiStrandBraid.fromJson(Map<String, dynamic> json) {
    return MultiStrandBraid(
      strandCount: json['strandCount'] ?? 0,
      braidData: List<double>.from(json['braidData'] ?? []),
      userToStrandIndex: Map<String, int>.from(
        (json['userToStrandIndex'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
            {},
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'strandCount': strandCount,
      'braidData': braidData,
      'userToStrandIndex': userToStrandIndex,
    };
  }
}

/// Knot Fabric
/// 
/// Represents a unified community fabric created by weaving all user knots together
class KnotFabric extends Equatable {
  final String fabricId;
  final List<PersonalityKnot> userKnots;
  final MultiStrandBraid braid;
  final FabricInvariants invariants;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const KnotFabric({
    required this.fabricId,
    required this.userKnots,
    required this.braid,
    required this.invariants,
    required this.createdAt,
    this.updatedAt,
  });
  
  /// Get number of users in fabric
  int get userCount => userKnots.length;
  
  /// Get fabric density (crossings per strand)
  double get density => invariants.density;
  
  /// Get fabric stability (community cohesion)
  double get stability => invariants.stability;
  
  @override
  List<Object?> get props => [
    fabricId,
    userKnots,
    braid,
    invariants,
    createdAt,
    updatedAt,
  ];
  
  /// Create a copy with updated fields
  KnotFabric copyWith({
    String? fabricId,
    List<PersonalityKnot>? userKnots,
    MultiStrandBraid? braid,
    FabricInvariants? invariants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnotFabric(
      fabricId: fabricId ?? this.fabricId,
      userKnots: userKnots ?? this.userKnots,
      braid: braid ?? this.braid,
      invariants: invariants ?? this.invariants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create from JSON
  factory KnotFabric.fromJson(Map<String, dynamic> json) {
    return KnotFabric(
      fabricId: json['fabricId'] ?? '',
      userKnots: (json['userKnots'] as List<dynamic>?)
              ?.map((k) => PersonalityKnot.fromJson(k as Map<String, dynamic>))
              .toList() ??
          [],
      braid: MultiStrandBraid.fromJson(json['braid'] as Map<String, dynamic>),
      invariants: FabricInvariants.fromJson(
        json['invariants'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fabricId': fabricId,
      'userKnots': userKnots.map((k) => k.toJson()).toList(),
      'braid': braid.toJson(),
      'invariants': invariants.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
