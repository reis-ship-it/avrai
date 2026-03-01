// Group Matching Input Model
//
// Input data for group matching controller
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.3: Group Matching Controller

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/quantum/group_session.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';

/// Input data for group matching
///
/// Contains group session and candidate spots to match against
class GroupMatchingInput extends Equatable {
  /// Current user (initiator of group matching)
  final UnifiedUser currentUser;

  /// Group session (contains member agentIds)
  final GroupSession session;

  /// Candidate spots to match against
  final List<Spot> candidateSpots;

  /// Optional search query (for filtering)
  final String? searchQuery;

  /// Optional location filter (latitude, longitude)
  final double? latitude;
  final double? longitude;

  /// Optional radius filter (in meters)
  final int? radius;

  /// Matching strategy (default: 'hybrid')
  final String matchingStrategy;

  const GroupMatchingInput({
    required this.currentUser,
    required this.session,
    required this.candidateSpots,
    this.searchQuery,
    this.latitude,
    this.longitude,
    this.radius,
    this.matchingStrategy = 'hybrid',
  });

  /// Check if input is valid
  bool get isValid {
    // Must have at least 2 members (current user + at least 1 other)
    if (session.memberCount < 2) return false;
    // Must have at least 1 candidate spot
    if (candidateSpots.isEmpty) return false;
    // Session must not be expired
    if (session.isExpired) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        currentUser,
        session,
        candidateSpots,
        searchQuery,
        latitude,
        longitude,
        radius,
        matchingStrategy,
      ];
}
