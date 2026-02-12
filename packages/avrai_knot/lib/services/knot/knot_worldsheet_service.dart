// Knot Worldsheet Service
// 
// Service for creating and managing 2D worldsheet representations of group evolution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Orchestration & Worldsheet Generation
//
// Mathematical representation: Σ(σ, τ, t) = F(t)
// Where:
// - σ = spatial parameter (position along each individual string/user)
// - τ = group parameter (which user/strand in the fabric)
// - t = time parameter
// - Σ(σ, τ, t) = fabric configuration at time t
// - F(t) = the KnotFabric at time t

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';

/// Service for creating and managing worldsheet representations
/// 
/// A worldsheet is a 2D surface representing group evolution:
/// - Individual strings (σ dimension) - each user's evolution
/// - Group fabric (τ dimension) - which users are in the group
/// - Time (t dimension) - how the group evolves over time
class KnotWorldsheetService {
  static const String _logName = 'KnotWorldsheetService';

  final KnotStorageService _storageService;
  final KnotEvolutionStringService _stringService;
  final KnotFabricService _fabricService;

  KnotWorldsheetService({
    required KnotStorageService storageService,
    required KnotEvolutionStringService stringService,
    required KnotFabricService fabricService,
  })  : _storageService = storageService,
        _stringService = stringService,
        _fabricService = fabricService;

  /// Create worldsheet representation for a group
  /// 
  /// **Flow:**
  /// 1. Get all user strings for group members
  /// 2. Get fabric snapshots over time
  /// 3. Create worldsheet (2D plane)
  /// 4. Return worldsheet
  /// 
  /// **Parameters:**
  /// - `groupId`: Group identifier
  /// - `userIds`: List of user IDs in the group
  /// - `startTime`: Optional start time filter
  /// - `endTime`: Optional end time filter
  Future<KnotWorldsheet?> createWorldsheet({
    required String groupId,
    required List<String> userIds,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      developer.log(
        'Creating worldsheet for group: $groupId (${userIds.length} users)',
        name: _logName,
      );

      // Step 1: Get all user strings
      final userStrings = <String, KnotString>{};
      for (final userId in userIds) {
        final string = await _stringService.createStringFromHistory(userId);
        if (string != null) {
          userStrings[userId] = string;
        } else {
          developer.log(
            '⚠️ No string found for user: ${userId.substring(0, 10)}...',
            name: _logName,
          );
        }
      }

      if (userStrings.isEmpty) {
        developer.log(
          'No user strings found, cannot create worldsheet',
          name: _logName,
        );
        return null;
      }

      // Step 2: Get initial fabric (or generate on-the-fly if not found)
      var initialFabric = await _storageService.loadFabric(groupId);
      if (initialFabric == null) {
        developer.log(
          'No initial fabric found in storage, generating on-the-fly...',
          name: _logName,
        );
        
        // Load personality knots for all users
        final userKnots = <PersonalityKnot>[];
        for (final userId in userIds) {
          final knot = await _storageService.loadKnot(userId);
          if (knot != null) {
            userKnots.add(knot);
          }
        }
        
        if (userKnots.isEmpty) {
          developer.log(
            'No user knots found, cannot generate fabric',
            name: _logName,
          );
          return null;
        }
        
        // Generate fabric on-the-fly
        try {
          initialFabric = await _fabricService.generateMultiStrandBraidFabric(
            userKnots: userKnots,
          );
          developer.log(
            '✅ Generated fabric on-the-fly for ${userKnots.length} users',
            name: _logName,
          );
        } catch (e, stackTrace) {
          developer.log(
            '❌ Failed to generate fabric on-the-fly: $e',
            error: e,
            stackTrace: stackTrace,
            name: _logName,
          );
          return null;
        }
      }

      // Step 3: Get fabric snapshots
      final fabricSnapshots = await _storageService.loadFabricSnapshots(
        groupId,
        startTime: startTime,
        endTime: endTime,
      );

      developer.log(
        '✅ Worldsheet created: ${userStrings.length} user strings, '
        '${fabricSnapshots.length} fabric snapshots',
        name: _logName,
      );

      return KnotWorldsheet(
        groupId: groupId,
        initialFabric: initialFabric,
        snapshots: fabricSnapshots,
        userStrings: userStrings,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create worldsheet: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get fabric at specific time (interpolated from worldsheet)
  Future<KnotFabric?> getFabricAtTime({
    required String groupId,
    required DateTime time,
  }) async {
    try {
      final worldsheet = await createWorldsheet(
        groupId: groupId,
        userIds: [], // Will be loaded from fabric
        startTime: time.subtract(const Duration(days: 1)),
        endTime: time.add(const Duration(days: 1)),
      );

      if (worldsheet == null) {
        return null;
      }

      return worldsheet.getFabricAtTime(time);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get fabric at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get cross-section at time t (all users at that moment)
  Future<List<PersonalityKnot>> getCrossSectionAtTime({
    required String groupId,
    required DateTime time,
  }) async {
    try {
      final worldsheet = await createWorldsheet(
        groupId: groupId,
        userIds: [], // Will be loaded from fabric
      );

      if (worldsheet == null) {
        return [];
      }

      return worldsheet.getCrossSectionAtTime(time);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get cross-section at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Get individual user's string within the worldsheet
  Future<KnotString?> getUserString({
    required String groupId,
    required String userId,
  }) async {
    try {
      final worldsheet = await createWorldsheet(
        groupId: groupId,
        userIds: [userId],
      );

      if (worldsheet == null) {
        return null;
      }

      return worldsheet.getUserString(userId);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get user string: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }
}
