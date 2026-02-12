// Braided Knot Model
// 
// Represents two personality knots woven together into a braided structure
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'package:avrai_core/models/personality_knot.dart';

/// Relationship types for braided knots
enum RelationshipType {
  friendship,
  mentorship,
  romantic,
  collaborative,
  professional;

  /// Get string representation
  String get displayName {
    switch (this) {
      case RelationshipType.friendship:
        return 'Friendship';
      case RelationshipType.mentorship:
        return 'Mentorship';
      case RelationshipType.romantic:
        return 'Romantic';
      case RelationshipType.collaborative:
        return 'Collaborative';
      case RelationshipType.professional:
        return 'Professional';
    }
  }

  /// Create from string
  static RelationshipType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'friendship':
        return RelationshipType.friendship;
      case 'mentorship':
        return RelationshipType.mentorship;
      case 'romantic':
        return RelationshipType.romantic;
      case 'collaborative':
        return RelationshipType.collaborative;
      case 'professional':
        return RelationshipType.professional;
      default:
        return null;
    }
  }
}

/// Represents a braided knot created from two personality knots
/// 
/// **Structure:**
/// - Two personality knots (knotA, knotB)
/// - Combined braid sequence representing the interweaving
/// - Metrics: complexity, stability, harmony
/// - Relationship type (friendship, mentorship, etc.)
class BraidedKnot {
  /// Unique identifier for this braided knot
  final String id;

  /// First personality knot
  final PersonalityKnot knotA;

  /// Second personality knot
  final PersonalityKnot knotB;

  /// Combined braid sequence representing the interweaving
  /// Format: [strands, crossing1_strand, crossing1_over, ...]
  final List<double> braidSequence;

  /// Complexity score (0.0 to 1.0)
  /// Higher = more complex braiding pattern
  final double complexity;

  /// Stability score (0.0 to 1.0)
  /// Higher = more stable braided structure
  final double stability;

  /// Harmony score (0.0 to 1.0)
  /// Higher = more harmonious relationship structure
  final double harmonyScore;

  /// Type of relationship this braided knot represents
  final RelationshipType relationshipType;

  /// When this braided knot was created
  final DateTime createdAt;

  /// When this braided knot was last updated
  final DateTime? updatedAt;

  BraidedKnot({
    required this.id,
    required this.knotA,
    required this.knotB,
    required this.braidSequence,
    required this.complexity,
    required this.stability,
    required this.harmonyScore,
    required this.relationshipType,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory BraidedKnot.fromJson(Map<String, dynamic> json) {
    return BraidedKnot(
      id: json['id'] ?? '',
      knotA: PersonalityKnot.fromJson(json['knotA'] as Map<String, dynamic>),
      knotB: PersonalityKnot.fromJson(json['knotB'] as Map<String, dynamic>),
      braidSequence: List<double>.from(json['braidSequence'] ?? []),
      complexity: (json['complexity'] ?? 0.0).toDouble(),
      stability: (json['stability'] ?? 0.0).toDouble(),
      harmonyScore: (json['harmonyScore'] ?? 0.0).toDouble(),
      relationshipType: RelationshipType.fromString(
            json['relationshipType'] ?? 'friendship',
          ) ??
          RelationshipType.friendship,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'knotA': knotA.toJson(),
      'knotB': knotB.toJson(),
      'braidSequence': braidSequence,
      'complexity': complexity,
      'stability': stability,
      'harmonyScore': harmonyScore,
      'relationshipType': relationshipType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  BraidedKnot copyWith({
    String? id,
    PersonalityKnot? knotA,
    PersonalityKnot? knotB,
    List<double>? braidSequence,
    double? complexity,
    double? stability,
    double? harmonyScore,
    RelationshipType? relationshipType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BraidedKnot(
      id: id ?? this.id,
      knotA: knotA ?? this.knotA,
      knotB: knotB ?? this.knotB,
      braidSequence: braidSequence ?? this.braidSequence,
      complexity: complexity ?? this.complexity,
      stability: stability ?? this.stability,
      harmonyScore: harmonyScore ?? this.harmonyScore,
      relationshipType: relationshipType ?? this.relationshipType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BraidedKnot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          knotA == other.knotA &&
          knotB == other.knotB &&
          _listEquals(braidSequence, other.braidSequence) &&
          complexity == other.complexity &&
          stability == other.stability &&
          harmonyScore == other.harmonyScore &&
          relationshipType == other.relationshipType;

  @override
  int get hashCode =>
      id.hashCode ^
      knotA.hashCode ^
      knotB.hashCode ^
      braidSequence.hashCode ^
      complexity.hashCode ^
      stability.hashCode ^
      harmonyScore.hashCode ^
      relationshipType.hashCode;

  /// Helper to compare lists
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Preview of braiding before creating connection
/// 
/// Used to show users what the braided knot would look like
/// before they commit to creating a connection
class BraidingPreview {
  /// The preview braided knot
  final BraidedKnot braidedKnot;

  /// Complexity score
  final double complexity;

  /// Stability score
  final double stability;

  /// Harmony score
  final double harmony;

  /// Overall compatibility score (0.0 to 1.0)
  final double compatibility;

  /// Relationship type as string
  final String relationshipType;

  BraidingPreview({
    required this.braidedKnot,
    required this.complexity,
    required this.stability,
    required this.harmony,
    required this.compatibility,
    required this.relationshipType,
  });

  /// Create from JSON
  factory BraidingPreview.fromJson(Map<String, dynamic> json) {
    return BraidingPreview(
      braidedKnot: BraidedKnot.fromJson(json['braidedKnot'] as Map<String, dynamic>),
      complexity: (json['complexity'] ?? 0.0).toDouble(),
      stability: (json['stability'] ?? 0.0).toDouble(),
      harmony: (json['harmony'] ?? 0.0).toDouble(),
      compatibility: (json['compatibility'] ?? 0.0).toDouble(),
      relationshipType: json['relationshipType'] ?? 'friendship',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'braidedKnot': braidedKnot.toJson(),
      'complexity': complexity,
      'stability': stability,
      'harmony': harmony,
      'compatibility': compatibility,
      'relationshipType': relationshipType,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BraidingPreview &&
          runtimeType == other.runtimeType &&
          braidedKnot == other.braidedKnot &&
          complexity == other.complexity &&
          stability == other.stability &&
          harmony == other.harmony &&
          compatibility == other.compatibility &&
          relationshipType == other.relationshipType;

  @override
  int get hashCode =>
      braidedKnot.hashCode ^
      complexity.hashCode ^
      stability.hashCode ^
      harmony.hashCode ^
      compatibility.hashCode ^
      relationshipType.hashCode;
}
