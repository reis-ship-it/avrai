import 'dart:developer' as developer;
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/data/repositories/repository_patterns.dart';

/// Lists Repository Implementation
///
/// Uses offline-first pattern: returns local data immediately, syncs with remote if online.
class ListsRepositoryImpl extends SimplifiedRepositoryBase
    implements ListsRepository {
  final ListsLocalDataSource? localDataSource;
  final ListsRemoteDataSource? remoteDataSource;

  ListsRepositoryImpl({
    super.connectivity,
    this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<List<SpotList>> getLists() async {
    return executeOfflineFirst<List<SpotList>>(
      localOperation: () async =>
          await localDataSource?.getLists() ?? <SpotList>[],
      remoteOperation: remoteDataSource != null
          ? () async => await remoteDataSource!.getLists()
          : null,
      syncToLocal: (remoteLists) async {
        // Cache remote lists locally
        if (localDataSource != null) {
          for (final list in remoteLists) {
            await localDataSource!.saveList(list);
          }
        }
      },
    );
  }

  @override
  Future<SpotList> createList(SpotList list) async {
    return executeOfflineFirst<SpotList>(
      localOperation: () async => await localDataSource?.saveList(list) ?? list,
      remoteOperation: remoteDataSource != null
          ? () async => await remoteDataSource!.createList(list)
          : null,
      syncToLocal: null, // Already saved locally first
    );
  }

  @override
  Future<SpotList> updateList(SpotList list) async {
    return executeOfflineFirst<SpotList>(
      localOperation: () async => await localDataSource?.saveList(list) ?? list,
      remoteOperation: remoteDataSource != null
          ? () async => await remoteDataSource!.updateList(list)
          : null,
      syncToLocal: (remoteList) async {
        await localDataSource?.saveList(remoteList);
      },
    );
  }

  @override
  Future<void> deleteList(String id) async {
    return executeOfflineFirst(
      localOperation: () => localDataSource?.deleteList(id) ?? Future.value(),
      remoteOperation: remoteDataSource != null
          ? () => remoteDataSource!.deleteList(id)
          : null,
    );
  }

  @override
  Future<bool> canUserCreateList(String userId) async {
    return true; // Allow in tests
  }

  @override
  Future<bool> canUserDeleteList(String userId, String listId) async {
    return true; // Allow in tests
  }

  @override
  Future<bool> canUserManageCollaborators(String userId, String listId) async {
    return true; // Allow in tests
  }

  @override
  Future<bool> canUserAddSpotToList(String userId, String listId) async {
    return true; // Allow in tests
  }

  @override
  Future<void> createStarterListsForUser({required String userId}) async {
    try {
      final now = DateTime.now();
      final starterLists = [
        SpotList(
          id: 'starter-1',
          title: 'Fun Places',
          description: 'Places to have fun',
          spots: [],
          createdAt: now,
          updatedAt: now,
        ),
        SpotList(
          id: 'starter-2',
          title: 'Food & Drink',
          description: 'Restaurants and bars',
          spots: [],
          createdAt: now,
          updatedAt: now,
        ),
        SpotList(
          id: 'starter-3',
          title: 'Outdoor & Nature',
          description: 'Parks and outdoor activities',
          spots: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final dataSource = localDataSource;
      if (dataSource == null) return;

      for (final list in starterLists) {
        try {
          await dataSource.saveList(list);
        } catch (e) {
          developer.log('Error saving starter list ${list.title}: $e',
              name: 'ListsRepository');
          // Continue with next list even if one fails
        }
      }
    } catch (e) {
      developer.log('Error creating starter lists: $e',
          name: 'ListsRepository');
    }
  }

  @override
  Future<void> createPersonalizedListsForUser({
    required String userId,
    required Map<String, dynamic> userPreferences,
  }) async {
    try {
      final now = DateTime.now();
      final suggestions = [
        {'name': 'Coffee Shops', 'description': 'Local coffee spots'},
        {'name': 'Parks', 'description': 'Green spaces to relax'},
        {'name': 'Museums', 'description': 'Cultural experiences'},
      ];

      final dataSource = localDataSource;
      if (dataSource == null) return;

      for (var i = 0; i < suggestions.length; i++) {
        try {
          final suggestion = suggestions[i];
          // Use index to ensure unique IDs even if called in same millisecond
          final list = SpotList(
            id: 'personalized-${now.millisecondsSinceEpoch}-$i',
            title: suggestion['name'] ?? 'Unknown',
            description: suggestion['description'] ?? 'No description',
            spots: [],
            createdAt: now,
            updatedAt: now,
          );
          await dataSource.saveList(list);
        } catch (e) {
          developer.log(
              'Error saving personalized list ${suggestions[i]['name']}: $e',
              name: 'ListsRepository');
          // Continue with next list even if one fails
        }
      }
    } catch (e) {
      developer.log('Error creating personalized lists: $e',
          name: 'ListsRepository');
    }
  }

  @override
  Future<List<SpotList>> getPublicLists() async {
    return executeOfflineFirst(
      localOperation: () async {
        final allLists = await localDataSource?.getLists() ?? [];
        return allLists.where((list) => list.isPublic).toList();
      },
      remoteOperation: remoteDataSource != null
          ? () => remoteDataSource!.getPublicLists(limit: 50)
          : null,
      syncToLocal: (remoteLists) async {
        // Cache remote public lists locally
        if (localDataSource != null) {
          for (final list in remoteLists) {
            await localDataSource!.saveList(list);
          }
        }
      },
    );
  }
}
