// Knot Orchestrator Service
//
// High-level orchestrator for all knot operations
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Orchestration & Worldsheet Generation
//
// This service coordinates:
// - Individual knot operations (generate, store, evolve)
// - Group/fabric operations (create fabric, track evolution)
// - String operations (create strings from history)
// - Worldsheet operations (create 2D planes for groups)

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_coordinator_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/string_export_service.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';

/// High-level orchestrator for all knot operations
///
/// **Responsibilities:**
/// - Coordinate individual knot operations
/// - Coordinate group/fabric operations
/// - Coordinate string operations
/// - Coordinate worldsheet operations
/// - Provide unified API for knot system
class KnotOrchestratorService {
  static const String _logName = 'KnotOrchestratorService';
  static String _safePrefix(String value, int length) =>
      value.length <= length ? value : value.substring(0, length);

  final PersonalityKnotService _knotService;
  final KnotStorageService _storageService;
  final KnotEvolutionCoordinatorService _coordinator;
  final KnotEvolutionStringService _stringService;
  final KnotFabricService _fabricService;
  final KnotWorldsheetService _worldsheetService;
  final StringExportService? _stringExportService;

  KnotOrchestratorService({
    required PersonalityKnotService knotService,
    required KnotStorageService storageService,
    required KnotEvolutionCoordinatorService coordinator,
    required KnotEvolutionStringService stringService,
    required KnotFabricService fabricService,
    required KnotWorldsheetService worldsheetService,
    StringExportService? stringExportService,
  }) : _knotService = knotService,
       _storageService = storageService,
       _coordinator = coordinator,
       _stringService = stringService,
       _fabricService = fabricService,
       _worldsheetService = worldsheetService,
       _stringExportService = stringExportService;

  // ========================================================================
  // Individual Knot Operations
  // ========================================================================

  /// Generate and save knot for a user
  ///
  /// **Flow:**
  /// 1. Generate knot from profile
  /// 2. Save knot to storage
  /// 3. Return knot
  Future<PersonalityKnot> generateAndSaveKnot(
    PersonalityProfile profile,
  ) async {
    try {
      developer.log(
        'Generating and saving knot for agent: ${profile.agentId}',
        name: _logName,
      );

      final knot = await _knotService.generateKnot(profile);
      await _storageService.saveKnot(profile.agentId, knot);

      developer.log('✅ Knot generated and saved', name: _logName);
      return knot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to generate and save knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get knot for a user (load from storage or generate if missing)
  Future<PersonalityKnot> getOrGenerateKnot(PersonalityProfile profile) async {
    try {
      final existingKnot = await _storageService.loadKnot(profile.agentId);
      if (existingKnot != null) {
        return existingKnot;
      }

      // Generate new knot if not found
      return await generateAndSaveKnot(profile);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get or generate knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Handle profile evolution (delegates to coordinator)
  Future<void> handleProfileEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    await _coordinator.handleProfileEvolution(userId, evolvedProfile);
  }

  // ========================================================================
  // String Operations
  // ========================================================================

  /// Create string representation for a user
  ///
  /// **Flow:**
  /// 1. Load evolution history
  /// 2. Create string from history
  /// 3. Phase 2: Optionally export string if export service available
  /// 4. Return string
  Future<KnotString?> createUserString(String agentId) async {
    try {
      developer.log(
        'Creating string for user: ${_safePrefix(agentId, 10)}...',
        name: _logName,
      );

      final string = await _stringService.createStringFromHistory(agentId);

      if (string != null) {
        developer.log('✅ String created', name: _logName);

        // Phase 2: Export string if export service available (for analytics/debugging)
        final exportService = _stringExportService;
        if (exportService != null) {
          try {
            await exportService.exportStringToJSON(string: string);
            developer.log(
              '✅ String exported to JSON for analytics',
              name: _logName,
            );
          } catch (e) {
            developer.log(
              '⚠️ Failed to export string (non-critical): $e',
              name: _logName,
            );
            // Continue - export failure shouldn't block string creation
          }
        }
      } else {
        developer.log('⚠️ No string created (no history)', name: _logName);
      }

      return string;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create user string: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Export string to JSON format
  ///
  /// **Phase 2:** Convenience method for exporting strings
  ///
  /// **Parameters:**
  /// - `agentId`: User agent ID
  /// - `filename`: Optional filename
  ///
  /// **Returns:**
  /// - File path of exported JSON file, or null if export failed
  Future<String?> exportUserStringToJSON({
    required String agentId,
    String? filename,
  }) async {
    final exportService = _stringExportService;
    if (exportService == null) {
      developer.log('⚠️ StringExportService not available', name: _logName);
      return null;
    }

    try {
      final string = await createUserString(agentId);
      if (string == null) {
        developer.log(
          '⚠️ No string to export for agentId: ${_safePrefix(agentId, 10)}...',
          name: _logName,
        );
        return null;
      }

      final filePath = await exportService.exportStringToJSON(
        string: string,
        filename: filename,
      );

      developer.log('✅ String exported to JSON: $filePath', name: _logName);

      return filePath;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export string: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Export string trajectory to CSV format
  ///
  /// **Phase 2:** Convenience method for exporting string trajectories
  ///
  /// **Parameters:**
  /// - `agentId`: User agent ID
  /// - `timeStep`: Time step for trajectory sampling
  /// - `filename`: Optional filename
  ///
  /// **Returns:**
  /// - File path of exported CSV file, or null if export failed
  Future<String?> exportUserStringToCSV({
    required String agentId,
    Duration timeStep = const Duration(hours: 1),
    String? filename,
  }) async {
    final exportService = _stringExportService;
    if (exportService == null) {
      developer.log('⚠️ StringExportService not available', name: _logName);
      return null;
    }

    try {
      final string = await createUserString(agentId);
      if (string == null) {
        developer.log(
          '⚠️ No string to export for agentId: ${_safePrefix(agentId, 10)}...',
          name: _logName,
        );
        return null;
      }

      final filePath = await exportService.exportStringToCSV(
        string: string,
        timeStep: timeStep,
        filename: filename,
      );

      developer.log('✅ String exported to CSV: $filePath', name: _logName);

      return filePath;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export string to CSV: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get knot at specific time for a user (from string)
  Future<PersonalityKnot?> getUserKnotAtTime(
    String agentId,
    DateTime time,
  ) async {
    try {
      final string = await createUserString(agentId);
      if (string == null) {
        return null;
      }

      return string.getKnotAtTime(time);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get user knot at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  // ========================================================================
  // Group/Fabric Operations
  // ========================================================================

  /// Create fabric for a group
  ///
  /// **Flow:**
  /// 1. Get knots for all users
  /// 2. Generate fabric from knots
  /// 3. Save fabric to storage
  /// 4. Return fabric
  Future<KnotFabric> createFabricForGroup({
    required String groupId,
    required List<String> userIds,
    Map<String, double>? compatibilityScores,
    Map<String, RelationshipType>? relationships,
  }) async {
    try {
      developer.log(
        'Creating fabric for group: $groupId (${userIds.length} users)',
        name: _logName,
      );

      // Step 1: Get knots for all users
      final userKnots = <PersonalityKnot>[];
      for (final userId in userIds) {
        final knot = await _storageService.loadKnot(userId);
        if (knot != null) {
          userKnots.add(knot);
        } else {
          developer.log(
            '⚠️ No knot found for user: ${_safePrefix(userId, 10)}...',
            name: _logName,
          );
        }
      }

      if (userKnots.isEmpty) {
        throw ArgumentError('Cannot create fabric: no knots found for users');
      }

      // Step 2: Generate fabric from knots
      final fabric = await _fabricService.generateMultiStrandBraidFabric(
        userKnots: userKnots,
        compatibilityScores: compatibilityScores,
        relationships: relationships,
      );

      // Step 3: Save fabric to storage
      await _storageService.saveFabric(groupId, fabric);

      developer.log('✅ Fabric created and saved', name: _logName);
      return fabric;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create fabric for group: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get fabric for a group (load from storage or create if missing)
  Future<KnotFabric?> getOrCreateFabricForGroup({
    required String groupId,
    required List<String> userIds,
    Map<String, double>? compatibilityScores,
    Map<String, RelationshipType>? relationships,
  }) async {
    try {
      final existingFabric = await _storageService.loadFabric(groupId);
      if (existingFabric != null) {
        return existingFabric;
      }

      // Create new fabric if not found
      return await createFabricForGroup(
        groupId: groupId,
        userIds: userIds,
        compatibilityScores: compatibilityScores,
        relationships: relationships,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get or create fabric: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Create fabric snapshot
  ///
  /// **Flow:**
  /// 1. Get current fabric
  /// 2. Create snapshot
  /// 3. Save snapshot
  Future<void> createFabricSnapshot({
    required String groupId,
    String? reason,
  }) async {
    try {
      developer.log(
        'Creating fabric snapshot for group: $groupId',
        name: _logName,
      );

      final fabric = await _storageService.loadFabric(groupId);
      if (fabric == null) {
        throw ArgumentError('Cannot create snapshot: fabric not found');
      }

      final snapshot = FabricSnapshot(
        timestamp: DateTime.now(),
        fabric: fabric,
        reason: reason,
      );

      await _storageService.saveFabricSnapshot(groupId, snapshot);

      developer.log('✅ Fabric snapshot created', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create fabric snapshot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  // ========================================================================
  // Worldsheet Operations
  // ========================================================================

  /// Create worldsheet for a group
  ///
  /// **Flow:**
  /// 1. Get all user strings
  /// 2. Get fabric snapshots
  /// 3. Create worldsheet
  /// 4. Return worldsheet
  Future<KnotWorldsheet?> createWorldsheetForGroup({
    required String groupId,
    required List<String> userIds,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      developer.log('Creating worldsheet for group: $groupId', name: _logName);

      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: groupId,
        userIds: userIds,
        startTime: startTime,
        endTime: endTime,
      );

      if (worldsheet != null) {
        developer.log('✅ Worldsheet created', name: _logName);
      } else {
        developer.log('⚠️ No worldsheet created', name: _logName);
      }

      return worldsheet;
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

  /// Get fabric at specific time for a group (from worldsheet)
  Future<KnotFabric?> getGroupFabricAtTime({
    required String groupId,
    required DateTime time,
  }) async {
    try {
      return await _worldsheetService.getFabricAtTime(
        groupId: groupId,
        time: time,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get group fabric at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get cross-section at time t (all users at that moment)
  Future<List<PersonalityKnot>> getGroupCrossSectionAtTime({
    required String groupId,
    required DateTime time,
  }) async {
    try {
      return await _worldsheetService.getCrossSectionAtTime(
        groupId: groupId,
        time: time,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get group cross-section: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  // ========================================================================
  // Unified Operations
  // ========================================================================

  /// Complete setup for a new user
  ///
  /// **Flow:**
  /// 1. Generate knot from profile
  /// 2. Save knot
  /// 3. Create initial snapshot
  Future<void> setupNewUser(PersonalityProfile profile) async {
    try {
      developer.log('Setting up new user: ${profile.agentId}', name: _logName);

      await generateAndSaveKnot(profile);

      // Create initial snapshot
      final knot = await _storageService.loadKnot(profile.agentId);
      if (knot != null) {
        await _storageService.addSnapshot(
          profile.agentId,
          KnotSnapshot(
            timestamp: DateTime.now(),
            knot: knot,
            reason: 'Initial knot creation',
          ),
        );
      }

      developer.log('✅ New user setup complete', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to setup new user: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Complete setup for a new group
  ///
  /// **Flow:**
  /// 1. Get or generate knots for all users
  /// 2. Create fabric
  /// 3. Save fabric
  /// 4. Create initial snapshot
  Future<KnotFabric> setupNewGroup({
    required String groupId,
    required List<String> userIds,
    required List<PersonalityProfile> profiles,
    Map<String, double>? compatibilityScores,
    Map<String, RelationshipType>? relationships,
  }) async {
    try {
      developer.log(
        'Setting up new group: $groupId (${userIds.length} users)',
        name: _logName,
      );

      // Step 1: Get or generate knots for all users
      for (final profile in profiles) {
        await getOrGenerateKnot(profile);
      }

      // Step 2 & 3: Create and save fabric
      final fabric = await createFabricForGroup(
        groupId: groupId,
        userIds: userIds,
        compatibilityScores: compatibilityScores,
        relationships: relationships,
      );

      // Step 4: Create initial snapshot
      await createFabricSnapshot(
        groupId: groupId,
        reason: 'Initial group creation',
      );

      developer.log('✅ New group setup complete', name: _logName);
      return fabric;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to setup new group: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
}
