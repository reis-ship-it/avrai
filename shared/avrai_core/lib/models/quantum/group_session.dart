// Group Session Model
//
// Represents a group session for quantum group matching
// Part of Phase 19.18: Quantum Group Matching System

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Group session for quantum group matching
class GroupSession extends Equatable {
  /// Unique session ID
  final String sessionId;

  /// Group ID (can be same as sessionId or separate)
  final String groupId;

  /// List of group member agentIds (privacy-protected)
  /// NOTE: Uses agentId exclusively, never userId
  final List<String> memberAgentIds;

  /// Formation method: proximity, manual, or hybrid
  final GroupFormationMethod formationMethod;

  /// Atomic timestamp when group was formed
  final AtomicTimestamp formationTimestamp;

  /// Session expiration time
  final DateTime expiresAt;

  /// Optional fabric ID if fabric was generated
  final String? fabricId;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const GroupSession({
    required this.sessionId,
    required this.groupId,
    required this.memberAgentIds,
    required this.formationMethod,
    required this.formationTimestamp,
    required this.expiresAt,
    this.fabricId,
    this.metadata,
  });

  /// Check if session is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get number of members
  int get memberCount => memberAgentIds.length;

  @override
  List<Object?> get props => [
        sessionId,
        groupId,
        memberAgentIds,
        formationMethod,
        formationTimestamp,
        expiresAt,
        fabricId,
        metadata,
      ];
}

/// Group formation method
enum GroupFormationMethod {
  /// Proximity-based formation (device discovery)
  proximity,

  /// Manual friend selection
  manual,

  /// Hybrid (proximity + manual)
  hybrid,
}
