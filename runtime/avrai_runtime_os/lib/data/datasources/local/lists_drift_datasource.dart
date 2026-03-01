import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';

/// Drift-based implementation of ListsLocalDataSource
///
/// Phase 26: Replaces ListsSembastDataSource after migration complete.
class ListsDriftDataSource implements ListsLocalDataSource {
  static const String _logName = 'ListsDriftDataSource';

  AppDatabase? _database;

  AppDatabase get _db {
    _database ??= GetIt.I<AppDatabase>();
    return _database!;
  }

  @override
  Future<List<SpotList>> getLists() async {
    try {
      final lists = await _db.getAllLists();
      return lists.map(_mapToSpotList).toList();
    } catch (e, st) {
      developer.log(
        'Error getting lists',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return [];
    }
  }

  @override
  Future<SpotList?> saveList(SpotList list) async {
    try {
      await _db.upsertList(SpotListsCompanion.insert(
        id: list.id,
        name: list.title,
        description: Value(list.description),
        ownerId: list.curatorId ?? '',
        createdAt: list.createdAt,
        updatedAt: list.updatedAt,
        isPublic: Value(list.isPublic),
      ));
      return list;
    } catch (e, st) {
      developer.log(
        'Error saving list',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return null;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    try {
      await (_db.delete(_db.spotLists)..where((l) => l.id.equals(id))).go();
    } catch (e, st) {
      developer.log(
        'Error deleting list',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Maps Drift SpotListData to SpotList model
  SpotList _mapToSpotList(SpotListData l) {
    return SpotList(
      id: l.id,
      title: l.name,
      description: l.description ?? '',
      spots: const [], // Spots loaded separately
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
      isPublic: l.isPublic,
      curatorId: l.ownerId,
    );
  }
}
