// Knot Community Model
// 
// Model for wrapping Community with knot similarity metrics
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Knot Community
/// 
/// Wraps a Community with knot similarity metrics for finding "knot tribes"
/// during onboarding.
/// 
/// **Purpose:**
/// - Help users find communities with similar topological personality structures
/// - Enable knot-based community recommendations
/// - Support onboarding group formation based on knot compatibility
class KnotCommunity {
  /// The underlying community
  final Community community;
  
  /// Knot similarity score (0.0 to 1.0)
  /// Higher = more similar knot topology
  final double knotSimilarity;
  
  /// Average knot of community members (if available)
  /// Can be null if community doesn't have enough members with knots
  final PersonalityKnot? averageKnot;
  
  /// Number of members in the community
  final int memberCount;
  
  /// Number of members with knots (for similarity calculation)
  final int membersWithKnots;
  
  KnotCommunity({
    required this.community,
    required this.knotSimilarity,
    this.averageKnot,
    required this.memberCount,
    this.membersWithKnots = 0,
  });
  
  /// Create from community with calculated similarity
  factory KnotCommunity.fromCommunity({
    required Community community,
    required double knotSimilarity,
    PersonalityKnot? averageKnot,
    int membersWithKnots = 0,
  }) {
    return KnotCommunity(
      community: community,
      knotSimilarity: knotSimilarity,
      averageKnot: averageKnot,
      memberCount: community.memberCount,
      membersWithKnots: membersWithKnots,
    );
  }
  
  /// Check if similarity is high enough to be considered a "tribe"
  bool isKnotTribe({double threshold = 0.7}) {
    return knotSimilarity >= threshold;
  }
  
  @override
  String toString() {
    return 'KnotCommunity(community: ${community.name}, similarity: ${knotSimilarity.toStringAsFixed(2)}, members: $memberCount)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnotCommunity &&
        other.community.id == community.id &&
        other.knotSimilarity == knotSimilarity;
  }
  
  @override
  int get hashCode => community.id.hashCode ^ knotSimilarity.hashCode;
}
