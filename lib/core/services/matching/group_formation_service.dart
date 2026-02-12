// Group Formation Service
//
// Implements group formation with proximity detection and manual friend selection
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.2: Group Formation Service
// Patent #29: Multi-Entity Quantum Entanglement Matching System
// Patent #31: Topological Knot Theory for Personality Representation
//
// **Features:**
// - Proximity-based formation (device discovery)
// - Manual friend selection
// - Hybrid approach (proximity + manual)
// - Privacy-protected (agentId-only)
// - Atomic time synchronization
// - AI2AI mesh integration (optional)

import 'dart:developer' as developer;
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/social_media/social_media_discovery_service.dart';
import 'package:avrai/core/models/quantum/group_session.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart' show VibeConnectionOrchestrator;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';

/// Discovered user from proximity detection
class DiscoveredUser {
  /// Device ID from discovery
  final String deviceId;

  /// Agent ID (privacy-protected identifier)
  final String agentId;

  /// Device name
  final String deviceName;

  /// Anonymized vibe data (if available)
  final Map<String, double>? anonymizedVibe;

  /// Signal strength (for proximity estimation)
  final int? signalStrength;

  /// Discovered timestamp
  final DateTime discoveredAt;

  /// Compatibility score with current user (if calculated)
  final double? compatibilityScore;

  const DiscoveredUser({
    required this.deviceId,
    required this.agentId,
    required this.deviceName,
    this.anonymizedVibe,
    this.signalStrength,
    required this.discoveredAt,
    this.compatibilityScore,
  });
}

/// Group formation service
///
/// **Purpose:**
/// - Form groups via proximity detection (device discovery)
/// - Form groups via manual friend selection
/// - Support hybrid approach (proximity + manual)
/// - Privacy-protected (agentId-only)
/// - Atomic time synchronization
/// - AI2AI mesh integration (optional)
class GroupFormationService {
  static const String _logName = 'GroupFormationService';

  final DeviceDiscoveryService _deviceDiscovery;
  final AtomicClockService _atomicClock;
  final AgentIdService _agentIdService;
  final KnotStorageService _knotStorage;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  // ignore: unused_field
  final PersonalityLearning _personalityLearning;
  final SocialMediaDiscoveryService? _socialDiscovery;
  final VibeConnectionOrchestrator? _orchestrator;
  // ignore: unused_field
  final AdaptiveMeshNetworkingService? _meshService;

  GroupFormationService({
    required DeviceDiscoveryService deviceDiscovery,
    required AtomicClockService atomicClock,
    required AgentIdService agentIdService,
    required KnotStorageService knotStorage,
    CrossEntityCompatibilityService? knotCompatibilityService,
    required PersonalityLearning personalityLearning,
    SocialMediaDiscoveryService? socialDiscovery,
    VibeConnectionOrchestrator? orchestrator,
    AdaptiveMeshNetworkingService? meshService,
  })  : _deviceDiscovery = deviceDiscovery,
        _atomicClock = atomicClock,
        _agentIdService = agentIdService,
        _knotStorage = knotStorage,
        _knotCompatibilityService = knotCompatibilityService,
        _personalityLearning = personalityLearning,
        _socialDiscovery = socialDiscovery,
        _orchestrator = orchestrator,
        _meshService = meshService;

  /// Discover nearby users via device discovery
  ///
  /// **Flow:**
  /// 1. Get discovered devices from DeviceDiscoveryService
  /// 2. Extract agentIds (privacy protection)
  /// 3. Load personality knots for compatibility
  /// 4. Calculate compatibility scores
  /// 5. Return discovered users sorted by compatibility
  ///
  /// **Parameters:**
  /// - `currentUserId`: Current user's ID (for compatibility calculation)
  /// - `minCompatibility`: Minimum compatibility to include (default: 0.3)
  /// - `maxResults`: Maximum number of results (default: 10)
  ///
  /// **Returns:**
  /// List of DiscoveredUser sorted by compatibility (highest first)
  Future<List<DiscoveredUser>> discoverNearbyUsers({
    required String currentUserId,
    double minCompatibility = 0.3,
    int maxResults = 10,
  }) async {
    developer.log(
      'Discovering nearby users for user $currentUserId',
      name: _logName,
    );

    try {
      // Get discovered devices
      final devices = _deviceDiscovery.getDiscoveredDevices();
      if (devices.isEmpty) {
        developer.log('No nearby devices discovered', name: _logName);
        return [];
      }

      // Get current user's agentId
      final currentAgentId = await _agentIdService.getUserAgentId(currentUserId);

      // Get current user's knot for compatibility
      final currentKnot = await _knotStorage.loadKnot(currentAgentId);

      final discoveredUsers = <DiscoveredUser>[];

      for (final device in devices) {
        try {
          // Extract agentId from device
          // Note: deviceId might be agentId or we need to look it up
          // For now, we'll try to use deviceId as agentId (may need enhancement)
          final deviceAgentId = device.deviceId; // TODO: Map deviceId to agentId if needed

          // Extract anonymized vibe data
          final anonymizedVibe = device.personalityData?.noisyDimensions;

          // Calculate compatibility if knot services available
          double? compatibilityScore;
          if (_knotCompatibilityService != null && currentKnot != null) {
            try {
              final deviceKnot = await _knotStorage.loadKnot(deviceAgentId);
              if (deviceKnot != null) {
                // Calculate knot compatibility
                // Note: This requires EntityKnot, but we have PersonalityKnot
                // For now, skip knot compatibility for discovered devices
                // TODO: Enhance to support PersonalityKnot compatibility
                compatibilityScore = 0.5; // Neutral if knot compatibility unavailable
              }
            } catch (e) {
              developer.log(
                'Error calculating compatibility for device ${device.deviceId}: $e',
                name: _logName,
              );
            }
          }

          // Use anonymized vibe for compatibility estimation if available
          if (compatibilityScore == null && anonymizedVibe != null && currentKnot != null) {
            // Simple compatibility based on vibe similarity
            compatibilityScore = _estimateCompatibilityFromVibe(
              currentKnot: currentKnot,
              anonymizedVibe: anonymizedVibe,
            );
          }

          // Default compatibility if unavailable
          compatibilityScore ??= 0.5;

          if (compatibilityScore >= minCompatibility) {
            discoveredUsers.add(DiscoveredUser(
              deviceId: device.deviceId,
              agentId: deviceAgentId,
              deviceName: device.deviceName,
              anonymizedVibe: anonymizedVibe,
              signalStrength: device.signalStrength,
              discoveredAt: device.discoveredAt,
              compatibilityScore: compatibilityScore,
            ));
          }
        } catch (e) {
          developer.log(
            'Error processing device ${device.deviceId}: $e',
            name: _logName,
          );
          continue;
        }
      }

      // Sort by compatibility (highest first)
      discoveredUsers.sort((a, b) {
        final scoreA = a.compatibilityScore ?? 0.0;
        final scoreB = b.compatibilityScore ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

      // Limit results
      final results = discoveredUsers.take(maxResults).toList();

      developer.log(
        '✅ Discovered ${results.length} nearby users',
        name: _logName,
      );

      return results;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error discovering nearby users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Get friends list for manual selection
  ///
  /// **Flow:**
  /// 1. Get connected friends from SocialMediaDiscoveryService (if available)
  /// 2. Get friends from UnifiedUser (if available)
  /// 3. Convert userIds to agentIds (privacy protection)
  /// 4. Return list of friend agentIds
  ///
  /// **Parameters:**
  /// - `currentUserId`: Current user's ID
  ///
  /// **Returns:**
  /// List of friend agentIds
  Future<List<String>> getFriendsList(String currentUserId) async {
    developer.log(
      'Getting friends list for user $currentUserId',
      name: _logName,
    );

    try {
      final friendAgentIds = <String>[];

      // Get current user's agentId
      final currentAgentId = await _agentIdService.getUserAgentId(currentUserId);

      // Try SocialMediaDiscoveryService first
      if (_socialDiscovery != null) {
        try {
          final connectedFriends = await _socialDiscovery.getConnectedFriends(currentAgentId);
          friendAgentIds.addAll(connectedFriends);
        } catch (e) {
          developer.log(
            'Error getting friends from SocialMediaDiscoveryService: $e',
            name: _logName,
          );
        }
      }

      // TODO: Also check UnifiedUser.friends if available
      // This would require UserService to get UnifiedUser
      // For now, we rely on SocialMediaDiscoveryService

      developer.log(
        '✅ Found ${friendAgentIds.length} friends',
        name: _logName,
      );

      return friendAgentIds;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error getting friends list: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Form group from discovered users
  ///
  /// **Flow:**
  /// 1. Validate discovered users
  /// 2. Get agentIds for all members
  /// 3. Get atomic timestamp
  /// 4. Create group session
  /// 5. Optionally propagate via AI2AI mesh
  ///
  /// **Parameters:**
  /// - `currentUserId`: Current user's ID
  /// - `discoveredUsers`: List of discovered users to include
  /// - `sessionDuration`: Session expiration duration (default: 1 hour)
  ///
  /// **Returns:**
  /// GroupSession with proximity formation method
  Future<GroupSession> formGroupFromNearbyUsers({
    required String currentUserId,
    required List<DiscoveredUser> discoveredUsers,
    Duration sessionDuration = const Duration(hours: 1),
  }) async {
    developer.log(
      'Forming group from ${discoveredUsers.length} nearby users',
      name: _logName,
    );

    try {
      // Get current user's agentId
      final currentAgentId = await _agentIdService.getUserAgentId(currentUserId);

      // Collect all agentIds (current user + discovered users)
      final memberAgentIds = <String>[currentAgentId];
      for (final user in discoveredUsers) {
        if (!memberAgentIds.contains(user.agentId)) {
          memberAgentIds.add(user.agentId);
        }
      }

      if (memberAgentIds.length < 2) {
        throw ArgumentError('Group must have at least 2 members');
      }

      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create group session
      final sessionId = _generateSessionId();
      final groupId = sessionId; // Use sessionId as groupId for simplicity

      final session = GroupSession(
        sessionId: sessionId,
        groupId: groupId,
        memberAgentIds: memberAgentIds,
        formationMethod: GroupFormationMethod.proximity,
        formationTimestamp: tAtomic,
        expiresAt: DateTime.now().add(sessionDuration),
      );

      // Optionally propagate via AI2AI mesh
      if (_orchestrator != null) {
        try {
          await _propagateGroupFormationViaMesh(
            currentAgentId: currentAgentId,
            groupId: groupId,
            memberAgentIds: memberAgentIds,
          );
        } catch (e) {
          developer.log(
            'Error propagating group formation via mesh: $e (non-fatal)',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Formed group $sessionId with ${memberAgentIds.length} members',
        name: _logName,
      );

      return session;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error forming group from nearby users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Form group from selected friends
  ///
  /// **Flow:**
  /// 1. Validate friend agentIds
  /// 2. Get current user's agentId
  /// 3. Get atomic timestamp
  /// 4. Create group session
  /// 5. Optionally propagate via AI2AI mesh
  ///
  /// **Parameters:**
  /// - `currentUserId`: Current user's ID
  /// - `friendAgentIds`: List of friend agentIds to include
  /// - `sessionDuration`: Session expiration duration (default: 1 hour)
  ///
  /// **Returns:**
  /// GroupSession with manual formation method
  Future<GroupSession> formGroupFromFriends({
    required String currentUserId,
    required List<String> friendAgentIds,
    Duration sessionDuration = const Duration(hours: 1),
  }) async {
    developer.log(
      'Forming group from ${friendAgentIds.length} friends',
      name: _logName,
    );

    try {
      // Get current user's agentId
      final currentAgentId = await _agentIdService.getUserAgentId(currentUserId);

      // Collect all agentIds (current user + friends)
      final memberAgentIds = <String>[currentAgentId];
      for (final friendAgentId in friendAgentIds) {
        if (!memberAgentIds.contains(friendAgentId)) {
          memberAgentIds.add(friendAgentId);
        }
      }

      if (memberAgentIds.length < 2) {
        throw ArgumentError('Group must have at least 2 members');
      }

      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create group session
      final sessionId = _generateSessionId();
      final groupId = sessionId;

      final session = GroupSession(
        sessionId: sessionId,
        groupId: groupId,
        memberAgentIds: memberAgentIds,
        formationMethod: GroupFormationMethod.manual,
        formationTimestamp: tAtomic,
        expiresAt: DateTime.now().add(sessionDuration),
      );

      // Optionally propagate via AI2AI mesh
      if (_orchestrator != null) {
        try {
          await _propagateGroupFormationViaMesh(
            currentAgentId: currentAgentId,
            groupId: groupId,
            memberAgentIds: memberAgentIds,
          );
        } catch (e) {
          developer.log(
            'Error propagating group formation via mesh: $e (non-fatal)',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Formed group $sessionId with ${memberAgentIds.length} members',
        name: _logName,
      );

      return session;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error forming group from friends: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Form group using hybrid approach (proximity + manual)
  ///
  /// **Flow:**
  /// 1. Combine discovered users and selected friends
  /// 2. Get agentIds for all members
  /// 3. Get atomic timestamp
  /// 4. Create group session with hybrid method
  /// 5. Optionally propagate via AI2AI mesh
  ///
  /// **Parameters:**
  /// - `currentUserId`: Current user's ID
  /// - `discoveredUsers`: List of discovered users (optional)
  /// - `friendAgentIds`: List of friend agentIds (optional)
  /// - `sessionDuration`: Session expiration duration (default: 1 hour)
  ///
  /// **Returns:**
  /// GroupSession with hybrid formation method
  Future<GroupSession> formGroupHybrid({
    required String currentUserId,
    List<DiscoveredUser>? discoveredUsers,
    List<String>? friendAgentIds,
    Duration sessionDuration = const Duration(hours: 1),
  }) async {
    developer.log(
      'Forming hybrid group (${discoveredUsers?.length ?? 0} nearby, ${friendAgentIds?.length ?? 0} friends)',
      name: _logName,
    );

    try {
      // Get current user's agentId
      final currentAgentId = await _agentIdService.getUserAgentId(currentUserId);

      // Collect all agentIds
      final memberAgentIds = <String>[currentAgentId];

      // Add discovered users
      if (discoveredUsers != null) {
        for (final user in discoveredUsers) {
          if (!memberAgentIds.contains(user.agentId)) {
            memberAgentIds.add(user.agentId);
          }
        }
      }

      // Add friends
      if (friendAgentIds != null) {
        for (final friendAgentId in friendAgentIds) {
          if (!memberAgentIds.contains(friendAgentId)) {
            memberAgentIds.add(friendAgentId);
          }
        }
      }

      if (memberAgentIds.length < 2) {
        throw ArgumentError('Group must have at least 2 members');
      }

      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create group session
      final sessionId = _generateSessionId();
      final groupId = sessionId;

      final session = GroupSession(
        sessionId: sessionId,
        groupId: groupId,
        memberAgentIds: memberAgentIds,
        formationMethod: GroupFormationMethod.hybrid,
        formationTimestamp: tAtomic,
        expiresAt: DateTime.now().add(sessionDuration),
      );

      // Optionally propagate via AI2AI mesh
      if (_orchestrator != null) {
        try {
          await _propagateGroupFormationViaMesh(
            currentAgentId: currentAgentId,
            groupId: groupId,
            memberAgentIds: memberAgentIds,
          );
        } catch (e) {
          developer.log(
            'Error propagating group formation via mesh: $e (non-fatal)',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Formed hybrid group $sessionId with ${memberAgentIds.length} members',
        name: _logName,
      );

      return session;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error forming hybrid group: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Estimate compatibility from anonymized vibe data
  ///
  /// **Note:** This is a simplified compatibility estimation.
  /// Full compatibility would require full personality profiles and quantum states.
  double _estimateCompatibilityFromVibe({
    required PersonalityKnot currentKnot,
    required Map<String, double> anonymizedVibe,
  }) {
    try {
      // Simple compatibility: compare knot invariants with vibe dimensions
      // This is a placeholder - full implementation would use quantum states
      final currentInvariants = currentKnot.invariants;

      // Use Jones polynomial length as a proxy for compatibility
      // In production, use proper quantum compatibility calculation
      final currentJonesLength = currentInvariants.jonesPolynomial.length;
      final vibeDimensionsCount = anonymizedVibe.length;

      // Simple similarity: closer dimension counts = higher compatibility
      final dimensionDiff = (currentJonesLength - vibeDimensionsCount).abs();
      final maxDiff = currentJonesLength.clamp(1, 12);
      final similarity = 1.0 - (dimensionDiff / maxDiff);

      return similarity.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Neutral if calculation fails
    }
  }

  /// Propagate group formation via AI2AI mesh
  ///
  /// **Purpose:**
  /// - Share group formation insights with network
  /// - Learn from group formation patterns
  /// - Privacy-protected (agentId-only)
  Future<void> _propagateGroupFormationViaMesh({
    required String currentAgentId,
    required String groupId,
    required List<String> memberAgentIds,
  }) async {
    if (_orchestrator == null) return;

    try {
      // Determine mesh hop limit (optional)
      // Note: Hop limit calculation would be done via AdaptiveMeshHopPolicy
      // For now, use default
      const hopLimit = 3; // Default: 3 hops

      // Send via mesh (fire-and-forget)
      // Note: Mesh propagation would be implemented via VibeConnectionOrchestrator
      // For now, we log it
      developer.log(
        'Would propagate group formation via mesh (hopLimit: $hopLimit, groupId: $groupId, members: ${memberAgentIds.length})',
        name: _logName,
      );

      // TODO: Implement mesh propagation when VibeConnectionOrchestrator supports group formation insights
      // await _orchestrator!.sendLearningInsightToPeer(
      //   fromAgentId: currentAgentId,
      //   payload: {
      //     'type': 'group_formation',
      //     'groupId': groupId,
      //     'memberCount': memberAgentIds.length,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      //   hopLimit: hopLimit,
      // );
    } catch (e) {
      developer.log(
        'Error in mesh propagation: $e (non-fatal)',
        name: _logName,
      );
    }
  }

  /// Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'group_${timestamp}_$random';
  }
}
