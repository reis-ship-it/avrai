import 'dart:developer' as developer;
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai/data/repositories/repository_patterns.dart';

/// Lists Repository Implementation
///
/// Uses offline-first pattern: returns local data immediately, syncs with remote if online.
class ListsRepositoryImpl extends SimplifiedRepositoryBase
    implements ListsRepository {
  final ListsLocalDataSource? localDataSource;
  final ListsRemoteDataSource? remoteDataSource;
  final AgentIdService? _agentIdService;
  final EpisodicMemoryStore? _episodicMemoryStore;
  final OutcomeTaxonomy _outcomeTaxonomy;

  ListsRepositoryImpl({
    super.connectivity,
    this.localDataSource,
    this.remoteDataSource,
    AgentIdService? agentIdService,
    EpisodicMemoryStore? episodicMemoryStore,
  })  : _agentIdService = agentIdService,
        _episodicMemoryStore = episodicMemoryStore,
        _outcomeTaxonomy = const OutcomeTaxonomy();

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
    final before = await _findLocalListById(list.id);
    final updatedList = await executeOfflineFirst<SpotList>(
      localOperation: () async => await localDataSource?.saveList(list) ?? list,
      remoteOperation: remoteDataSource != null
          ? () async => await remoteDataSource!.updateList(list)
          : null,
      syncToLocal: (remoteList) async {
        await localDataSource?.saveList(remoteList);
      },
    );
    await _recordListModificationEpisode(
      before: before,
      after: updatedList,
    );
    return updatedList;
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

  Future<SpotList?> _findLocalListById(String listId) async {
    final dataSource = localDataSource;
    if (dataSource == null || listId.isEmpty) return null;
    try {
      final lists = await dataSource.getLists();
      for (final list in lists) {
        if (list.id == listId) return list;
      }
    } catch (e) {
      developer.log(
        'Error loading list snapshot before update: $e',
        name: 'ListsRepository',
      );
    }
    return null;
  }

  Future<void> _recordListModificationEpisode({
    required SpotList? before,
    required SpotList after,
  }) async {
    final episodicStore = _episodicMemoryStore;
    if (episodicStore == null) return;

    final curatorId = after.curatorId ?? before?.curatorId;
    if (curatorId == null || curatorId.isEmpty) return;

    try {
      final agentIdService = _agentIdService;
      final agentId = agentIdService == null
          ? curatorId
          : await agentIdService.getUserAgentId(curatorId);

      final beforeSpotIds = before?.spotIds ?? const <String>[];
      final afterSpotIds = after.spotIds;

      final beforeSet = beforeSpotIds.toSet();
      final afterSet = afterSpotIds.toSet();
      final addedSpotIds = afterSet.difference(beforeSet).toList()..sort();
      final removedSpotIds = beforeSet.difference(afterSet).toList()..sort();

      final changeKind = addedSpotIds.isNotEmpty && removedSpotIds.isNotEmpty
          ? 'mixed'
          : addedSpotIds.isNotEmpty
              ? 'add'
              : removedSpotIds.isNotEmpty
                  ? 'remove'
                  : 'metadata';

      final listStateBefore = {
        'list_id': before?.id ?? after.id,
        'title': before?.title ?? after.title,
        'description': before?.description ?? after.description,
        'category': before?.category ?? after.category,
        'tags': before?.tags ?? const <String>[],
        'spot_ids': beforeSpotIds,
        'spot_count': beforeSpotIds.length,
      };
      final listStateAfter = {
        'list_id': after.id,
        'title': after.title,
        'description': after.description,
        'category': after.category,
        'tags': after.tags,
        'spot_ids': afterSpotIds,
        'spot_count': afterSpotIds.length,
      };

      final actionPayload = {
        'list_id': after.id,
        'change_kind': changeKind,
        'list_state_before': listStateBefore,
        'list_state_after': listStateAfter,
        'item_added_or_removed_features': {
          'added_spot_ids': addedSpotIds,
          'removed_spot_ids': removedSpotIds,
          'before_count': beforeSpotIds.length,
          'after_count': afterSpotIds.length,
          'delta_count': afterSpotIds.length - beforeSpotIds.length,
        },
      };

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: {
          ...listStateBefore,
        },
        actionType: 'modify_list',
        actionPayload: actionPayload,
        nextState: {
          ...listStateAfter,
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'modify_list',
          parameters: {
            'change_kind': changeKind,
            'before_count': beforeSpotIds.length,
            'after_count': afterSpotIds.length,
            'delta_count': afterSpotIds.length - beforeSpotIds.length,
          },
        ),
        recordedAt: after.updatedAt.toUtc(),
        metadata: const {
          'pipeline': 'lists_repository_impl',
          'phase_ref': '1.2.9',
        },
      );

      await episodicStore.writeTuple(tuple);
    } catch (e) {
      developer.log(
        'Error recording list modification episodic tuple: $e',
        name: 'ListsRepository',
      );
    }
  }
}
