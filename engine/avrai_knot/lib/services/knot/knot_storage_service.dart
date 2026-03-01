// Knot Storage Service
//
// Service for storing and retrieving personality knots
// Integrates with PersonalityProfile storage system

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_core/services/key_value_store.dart';

/// Service for storing and retrieving personality knots and braided knots
class KnotStorageService {
  static const String _logName = 'KnotStorageService';
  static const String _knotPrefix = 'personality_knot:';
  static const String _evolutionPrefix = 'knot_evolution:';
  static const String _braidedKnotPrefix = 'braided_knot:';
  static const String _fabricPrefix = 'knot_fabric:';
  static const String _fabricSnapshotPrefix = 'fabric_snapshot:';
  static const String _businessPlaceKnotPrefix = 'business_place_knot:';
  // ignore: unused_field - Reserved for future evolution snapshots
  static const String _businessPlaceEvolutionPrefix =
      'business_place_evolution:';

  final SpotsKeyValueStore _storageService;

  KnotStorageService({required SpotsKeyValueStore storageService})
    : _storageService = storageService;

  /// Save knot for an agent
  ///
  /// **Storage Key:** `personality_knot:{agentId}`
  Future<void> saveKnot(String agentId, PersonalityKnot knot) async {
    developer.log(
      'Saving knot for agentId: ${agentId.length > 10 ? agentId.substring(0, 10) : agentId}...',
      name: _logName,
    );

    try {
      final key = '$_knotPrefix$agentId';
      final json = knot.toJson();

      await _storageService.setObject(key, json);

      developer.log('✅ Knot saved successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to save knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Load knot for an agent
  ///
  /// Returns null if knot doesn't exist
  Future<PersonalityKnot?> loadKnot(String agentId) async {
    developer.log(
      'Loading knot for agentId: ${agentId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_knotPrefix$agentId';
      final json = _storageService.getObject<Map<String, dynamic>>(key);

      if (json == null) {
        developer.log('No knot found for agentId', name: _logName);
        return null;
      }

      final knot = PersonalityKnot.fromJson(json);

      developer.log('✅ Knot loaded successfully', name: _logName);
      return knot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Save knot evolution history
  ///
  /// **Storage Key:** `knot_evolution:{agentId}`
  Future<void> saveEvolutionHistory(
    String agentId,
    List<KnotSnapshot> history,
  ) async {
    developer.log(
      'Saving evolution history for agentId: ${agentId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_evolutionPrefix$agentId';
      final jsonList = history.map((snapshot) => snapshot.toJson()).toList();

      await _storageService.setObject(key, jsonList);

      developer.log(
        '✅ Evolution history saved: ${history.length} snapshots',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to save evolution history: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Save knot for a claimed business place.
  ///
  /// **Storage Key:** `business_place_knot:{businessId}:{googlePlaceId}`
  Future<void> saveBusinessPlaceKnot(
    String businessId,
    String googlePlaceId,
    PersonalityKnot knot,
  ) async {
    final key = '$_businessPlaceKnotPrefix$businessId:$googlePlaceId';
    try {
      await _storageService.setObject(key, knot.toJson());
      developer.log(
        'Saved business place knot: $businessId / $googlePlaceId',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to save business place knot: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Load knot for a claimed business place.
  Future<PersonalityKnot?> loadBusinessPlaceKnot(
    String businessId,
    String googlePlaceId,
  ) async {
    final key = '$_businessPlaceKnotPrefix$businessId:$googlePlaceId';
    try {
      final json = _storageService.getObject<Map<String, dynamic>>(key);
      if (json == null) return null;
      return PersonalityKnot.fromJson(json);
    } catch (e, st) {
      developer.log(
        'Failed to load business place knot: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return null;
    }
  }

  /// Load knot evolution history
  ///
  /// Returns empty list if history doesn't exist
  Future<List<KnotSnapshot>> loadEvolutionHistory(String agentId) async {
    developer.log(
      'Loading evolution history for agentId: ${agentId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_evolutionPrefix$agentId';
      final jsonList = _storageService.getObject<List<dynamic>>(key);

      if (jsonList == null) {
        developer.log('No evolution history found', name: _logName);
        return [];
      }

      final history = jsonList
          .map((json) => KnotSnapshot.fromJson(json as Map<String, dynamic>))
          .toList();

      developer.log(
        '✅ Evolution history loaded: ${history.length} snapshots',
        name: _logName,
      );
      return history;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load evolution history: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Add snapshot to evolution history
  ///
  /// Loads existing history, adds new snapshot, saves back
  Future<void> addSnapshot(String agentId, KnotSnapshot snapshot) async {
    final history = await loadEvolutionHistory(agentId);
    history.add(snapshot);
    await saveEvolutionHistory(agentId, history);
  }

  /// Delete knot and evolution history for an agent
  Future<void> deleteKnot(String agentId) async {
    developer.log(
      'Deleting knot for agentId: ${agentId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final knotKey = '$_knotPrefix$agentId';
      final evolutionKey = '$_evolutionPrefix$agentId';

      await _storageService.remove(knotKey);
      await _storageService.remove(evolutionKey);

      developer.log('✅ Knot deleted successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to delete knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Check if knot exists for an agent
  Future<bool> knotExists(String agentId) async {
    final key = '$_knotPrefix$agentId';
    final json = _storageService.getObject<Map<String, dynamic>>(key);
    return json != null;
  }

  /// Get all stored knots
  ///
  /// **Returns:** List of all personality knots in storage
  /// **Note:** This loads all knots, use with caution for large datasets
  Future<List<PersonalityKnot>> getAllKnots() async {
    developer.log('Loading all knots from storage', name: _logName);

    try {
      // Get all keys
      final allKeys = _storageService.getKeys();

      // Filter for knot keys
      final knotKeys = allKeys
          .where((key) => key.startsWith(_knotPrefix))
          .toList();

      developer.log('Found ${knotKeys.length} knot keys', name: _logName);

      // Load all knots
      final knots = <PersonalityKnot>[];
      for (final key in knotKeys) {
        try {
          final json = _storageService.getObject<Map<String, dynamic>>(key);
          if (json != null) {
            final knot = PersonalityKnot.fromJson(json);
            knots.add(knot);
          }
        } catch (e) {
          developer.log(
            '⚠️ Failed to load knot from key $key: $e',
            name: _logName,
          );
          // Continue loading other knots
        }
      }

      developer.log(
        '✅ Loaded ${knots.length} knots successfully',
        name: _logName,
      );

      return knots;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load all knots: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  // ========================================================================
  // Phase 2: Braided Knot Storage
  // ========================================================================

  /// Save braided knot for connection
  ///
  /// **Storage Key:** `braided_knot:{connectionId}`
  ///
  /// **Parameters:**
  /// - `connectionId`: Unique identifier for the connection
  /// - `braidedKnot`: The braided knot to store
  Future<void> saveBraidedKnot({
    required String connectionId,
    required BraidedKnot braidedKnot,
  }) async {
    developer.log(
      'Saving braided knot for connection: ${connectionId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_braidedKnotPrefix$connectionId';
      final json = braidedKnot.toJson();

      await _storageService.setObject(key, json);

      developer.log('✅ Braided knot saved successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to save braided knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get braided knot for connection
  ///
  /// **Storage Key:** `braided_knot:{connectionId}`
  ///
  /// **Parameters:**
  /// - `connectionId`: Unique identifier for the connection
  ///
  /// **Returns:**
  /// BraidedKnot if found, null otherwise
  Future<BraidedKnot?> getBraidedKnot(String connectionId) async {
    developer.log(
      'Loading braided knot for connection: ${connectionId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_braidedKnotPrefix$connectionId';
      final json = _storageService.getObject<Map<String, dynamic>>(key);

      if (json == null) {
        developer.log('No braided knot found for connectionId', name: _logName);
        return null;
      }

      final braidedKnot = BraidedKnot.fromJson(json);

      developer.log('✅ Braided knot loaded successfully', name: _logName);
      return braidedKnot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load braided knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Get all braided knots
  ///
  /// **Returns:** List of all braided knots in storage
  Future<List<BraidedKnot>> getAllBraidedKnots() async {
    developer.log('Loading all braided knots from storage', name: _logName);

    try {
      // Get all keys
      final allKeys = _storageService.getKeys();

      // Filter for braided knot keys
      final braidedKnotKeys = allKeys
          .where((key) => key.startsWith(_braidedKnotPrefix))
          .toList();

      developer.log(
        'Found ${braidedKnotKeys.length} braided knot keys',
        name: _logName,
      );

      // Load all braided knots
      final braidedKnots = <BraidedKnot>[];
      for (final key in braidedKnotKeys) {
        try {
          final json = _storageService.getObject<Map<String, dynamic>>(key);
          if (json != null) {
            final braidedKnot = BraidedKnot.fromJson(json);
            braidedKnots.add(braidedKnot);
          }
        } catch (e) {
          developer.log(
            '⚠️ Failed to load braided knot from key $key: $e',
            name: _logName,
          );
          // Continue loading other knots
        }
      }

      developer.log(
        '✅ Loaded ${braidedKnots.length} braided knots successfully',
        name: _logName,
      );

      return braidedKnots;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load all braided knots: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Get all braided knots for an agent
  ///
  /// Searches all braided knots where the agent is part of the connection
  ///
  /// **Parameters:**
  /// - `agentId`: Agent identifier
  ///
  /// **Returns:**
  /// List of braided knots involving this agent
  Future<List<BraidedKnot>> getBraidedKnotsForAgent(String agentId) async {
    developer.log(
      'Loading braided knots for agent: ${agentId.length > 10 ? '${agentId.substring(0, 10)}...' : agentId}',
      name: _logName,
    );

    try {
      // Get all braided knots
      final allBraidedKnots = await getAllBraidedKnots();

      // Filter for knots involving this agent
      final agentBraidedKnots = allBraidedKnots.where((braidedKnot) {
        return braidedKnot.knotA.agentId == agentId ||
            braidedKnot.knotB.agentId == agentId;
      }).toList();

      developer.log(
        '✅ Loaded ${agentBraidedKnots.length} braided knots for agent',
        name: _logName,
      );
      return agentBraidedKnots;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load braided knots for agent: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Delete braided knot (when connection deleted)
  ///
  /// **Storage Key:** `braided_knot:{connectionId}`
  ///
  /// **Parameters:**
  /// - `connectionId`: Unique identifier for the connection
  Future<void> deleteBraidedKnot(String connectionId) async {
    developer.log(
      'Deleting braided knot for connection: ${connectionId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_braidedKnotPrefix$connectionId';
      await _storageService.remove(key);

      developer.log('✅ Braided knot deleted successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to delete braided knot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  // ========================================================================
  // Phase 5: Fabric Storage
  // ========================================================================

  /// Save fabric for a group
  ///
  /// **Storage Key:** `knot_fabric:{groupId}`
  Future<void> saveFabric(String groupId, KnotFabric fabric) async {
    developer.log(
      'Saving fabric for group: ${groupId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_fabricPrefix$groupId';
      final json = fabric.toJson();

      await _storageService.setObject(key, json);

      developer.log('✅ Fabric saved successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to save fabric: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Load fabric for a group
  ///
  /// **Storage Key:** `knot_fabric:{groupId}`
  ///
  /// Returns null if fabric doesn't exist
  Future<KnotFabric?> loadFabric(String groupId) async {
    developer.log(
      'Loading fabric for group: ${groupId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final key = '$_fabricPrefix$groupId';
      final json = _storageService.getObject<Map<String, dynamic>>(key);

      if (json == null) {
        developer.log('No fabric found for groupId', name: _logName);
        return null;
      }

      final fabric = KnotFabric.fromJson(json);

      developer.log('✅ Fabric loaded successfully', name: _logName);
      return fabric;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load fabric: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Save fabric snapshot
  ///
  /// **Storage Key:** `fabric_snapshot:{groupId}:{timestamp}`
  Future<void> saveFabricSnapshot(
    String groupId,
    FabricSnapshot snapshot,
  ) async {
    developer.log(
      'Saving fabric snapshot for group: ${groupId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      final timestampKey = snapshot.timestamp.millisecondsSinceEpoch.toString();
      final key = '$_fabricSnapshotPrefix$groupId:$timestampKey';
      final json = snapshot.toJson();

      await _storageService.setObject(key, json);

      developer.log('✅ Fabric snapshot saved successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to save fabric snapshot: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Load fabric snapshots for a group
  ///
  /// **Storage Key Pattern:** `fabric_snapshot:{groupId}:{timestamp}`
  ///
  /// **Parameters:**
  /// - `groupId`: Group identifier
  /// - `startTime`: Optional start time filter
  /// - `endTime`: Optional end time filter
  ///
  /// **Returns:**
  /// List of fabric snapshots, sorted by timestamp
  Future<List<FabricSnapshot>> loadFabricSnapshots(
    String groupId, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    developer.log(
      'Loading fabric snapshots for group: ${groupId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      // Get all keys
      final allKeys = _storageService.getKeys();

      // Filter for this group's snapshot keys
      final snapshotKeys = allKeys
          .where((key) => key.startsWith('$_fabricSnapshotPrefix$groupId:'))
          .toList();

      developer.log(
        'Found ${snapshotKeys.length} snapshot keys',
        name: _logName,
      );

      // Load all snapshots
      final snapshots = <FabricSnapshot>[];
      for (final key in snapshotKeys) {
        try {
          final json = _storageService.getObject<Map<String, dynamic>>(key);
          if (json != null) {
            final snapshot = FabricSnapshot.fromJson(json);

            // Apply time filters
            if (startTime != null && snapshot.timestamp.isBefore(startTime)) {
              continue;
            }
            if (endTime != null && snapshot.timestamp.isAfter(endTime)) {
              continue;
            }

            snapshots.add(snapshot);
          }
        } catch (e) {
          developer.log(
            '⚠️ Failed to load snapshot from key $key: $e',
            name: _logName,
          );
          // Continue loading other snapshots
        }
      }

      // Sort by timestamp
      snapshots.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      developer.log(
        '✅ Loaded ${snapshots.length} fabric snapshots',
        name: _logName,
      );

      return snapshots;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load fabric snapshots: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Delete fabric and all snapshots for a group
  Future<void> deleteFabric(String groupId) async {
    developer.log(
      'Deleting fabric for group: ${groupId.substring(0, 10)}...',
      name: _logName,
    );

    try {
      // Delete fabric
      final fabricKey = '$_fabricPrefix$groupId';
      await _storageService.remove(fabricKey);

      // Delete all snapshots
      final allKeys = _storageService.getKeys();
      final snapshotKeys = allKeys
          .where((key) => key.startsWith('$_fabricSnapshotPrefix$groupId:'))
          .toList();

      for (final key in snapshotKeys) {
        await _storageService.remove(key);
      }

      developer.log(
        '✅ Fabric and ${snapshotKeys.length} snapshots deleted',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to delete fabric: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Check if fabric exists for a group
  Future<bool> fabricExists(String groupId) async {
    final key = '$_fabricPrefix$groupId';
    final json = _storageService.getObject<Map<String, dynamic>>(key);
    return json != null;
  }
}
