import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';

/// Drift-based implementation of SpotsLocalDataSource
///
/// Phase 26: Replaces SpotsSembastDataSource after migration complete.
class SpotsDriftDataSource implements SpotsLocalDataSource {
  static const String _logName = 'SpotsDriftDataSource';
  static const _uuid = Uuid();

  AppDatabase? _database;

  AppDatabase get _db {
    _database ??= GetIt.I<AppDatabase>();
    return _database!;
  }

  @override
  Future<List<Spot>> getAllSpots() async {
    try {
      final spots = await _db.getAllSpots();
      return spots.map(_mapToSpot).toList();
    } catch (e, st) {
      developer.log(
        'Error getting all spots',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return [];
    }
  }

  @override
  Future<Spot?> getSpotById(String id) async {
    try {
      final spot = await _db.getSpotById(id);
      if (spot == null) return null;
      return _mapToSpot(spot);
    } catch (e, st) {
      developer.log(
        'Error getting spot by id',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return null;
    }
  }

  @override
  Future<String> createSpot(Spot spot) async {
    try {
      final id = spot.id.isEmpty ? _uuid.v4() : spot.id;
      await _db.upsertSpot(SpotsCompanion.insert(
        id: id,
        name: spot.name,
        description: Value(spot.description),
        latitude: spot.latitude,
        longitude: spot.longitude,
        address: Value(spot.address),
        category: Value(spot.category),
        createdBy: spot.createdBy,
        createdAt: spot.createdAt,
        updatedAt: spot.updatedAt,
      ));
      return id;
    } catch (e, st) {
      developer.log(
        'Error creating spot',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      rethrow;
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    try {
      await _db.upsertSpot(SpotsCompanion.insert(
        id: spot.id,
        name: spot.name,
        description: Value(spot.description),
        latitude: spot.latitude,
        longitude: spot.longitude,
        address: Value(spot.address),
        category: Value(spot.category),
        createdBy: spot.createdBy,
        createdAt: spot.createdAt,
        updatedAt: DateTime.now(),
      ));
      return spot.copyWith(updatedAt: DateTime.now());
    } catch (e, st) {
      developer.log(
        'Error updating spot',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteSpot(String id) async {
    try {
      // Mark as deleted by clearing from database
      await (_db.delete(_db.spots)..where((s) => s.id.equals(id))).go();
    } catch (e, st) {
      developer.log(
        'Error deleting spot',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  @override
  Future<List<Spot>> getSpotsByCategory(String category) async {
    try {
      final spots = await _db.getSpotsByCategory(category);
      return spots.map(_mapToSpot).toList();
    } catch (e, st) {
      developer.log(
        'Error getting spots by category',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return [];
    }
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    // This would require joining with respected lists
    // For now, return empty list - to be implemented with list integration
    return [];
  }

  @override
  Future<List<Spot>> searchSpots(String query) async {
    try {
      final spots = await _db.searchSpots(query);
      return spots.map(_mapToSpot).toList();
    } catch (e, st) {
      developer.log(
        'Error searching spots',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return [];
    }
  }

  /// Maps Drift SpotData to Spot model
  Spot _mapToSpot(SpotData s) {
    return Spot(
      id: s.id,
      name: s.name,
      description: s.description ?? '',
      latitude: s.latitude,
      longitude: s.longitude,
      address: s.address ?? '',
      category: s.category,
      rating: 0.0, // Default rating
      createdBy: s.createdBy,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }
}
