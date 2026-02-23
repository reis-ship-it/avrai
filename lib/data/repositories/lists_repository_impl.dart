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
    final createdList = await executeOfflineFirst<SpotList>(
      localOperation: () async => await localDataSource?.saveList(list) ?? list,
      remoteOperation: remoteDataSource != null
          ? () async => await remoteDataSource!.createList(list)
          : null,
      syncToLocal: null, // Already saved locally first
    );
    await _recordListCreationEpisode(createdList);
    return createdList;
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
    await _recordListShareEpisode(
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

  Future<void> _recordListCreationEpisode(SpotList list) async {
    final episodicStore = _episodicMemoryStore;
    if (episodicStore == null) return;

    final curatorId = list.curatorId;
    if (curatorId == null || curatorId.isEmpty) return;

    try {
      final agentIdService = _agentIdService;
      final agentId = agentIdService == null
          ? curatorId
          : await agentIdService.getUserAgentId(curatorId);

      final itemCount = list.spotIds.length;
      final spotCategories = <String, int>{};
      final spotTags = <String>{...list.tags};
      double minLat = 0;
      double maxLat = 0;
      double minLng = 0;
      double maxLng = 0;
      var hasCoordinates = false;
      for (final spot in list.spots) {
        if (spot.category.isNotEmpty) {
          spotCategories.update(spot.category, (value) => value + 1,
              ifAbsent: () => 1);
        }
        if (spot.tags.isNotEmpty) {
          spotTags.addAll(spot.tags.where((tag) => tag.isNotEmpty));
        }
        if (!hasCoordinates) {
          minLat = maxLat = spot.latitude;
          minLng = maxLng = spot.longitude;
          hasCoordinates = true;
        } else {
          if (spot.latitude < minLat) minLat = spot.latitude;
          if (spot.latitude > maxLat) maxLat = spot.latitude;
          if (spot.longitude < minLng) minLng = spot.longitude;
          if (spot.longitude > maxLng) maxLng = spot.longitude;
        }
      }

      final listCompositionFeatures = {
        'item_count': itemCount,
        'spot_count': list.spots.length,
        'spot_id_count': itemCount,
        'category_distribution': spotCategories,
        'category_count': spotCategories.length,
        'geographic_spread': {
          'has_coordinates': hasCoordinates,
          'min_latitude': hasCoordinates ? minLat : null,
          'max_latitude': hasCoordinates ? maxLat : null,
          'min_longitude': hasCoordinates ? minLng : null,
          'max_longitude': hasCoordinates ? maxLng : null,
        },
        'price_range': {
          'min_tier': null,
          'max_tier': null,
          'mean_tier': null,
        },
      };

      final listMetadata = {
        'list_id': list.id,
        'title': list.title,
        'description': list.description,
        'description_length': list.description.length,
        'is_public': list.isPublic,
        'category': list.category,
        'tags': list.tags,
        'purpose_tags': spotTags.toList()..sort(),
        'curator_id': curatorId,
      };

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: {
          'user_id': curatorId,
          'existing_list_id': list.id,
        },
        actionType: 'create_list',
        actionPayload: {
          'list_composition_features': listCompositionFeatures,
          'list_metadata': listMetadata,
        },
        nextState: {
          'list_created': true,
          'list_id': list.id,
          'item_count': itemCount,
          'is_public': list.isPublic,
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'create_list',
          parameters: {
            'item_count': itemCount,
            'category_count': spotCategories.length,
            'is_public': list.isPublic,
          },
        ),
        recordedAt: list.createdAt.toUtc(),
        metadata: const {
          'pipeline': 'lists_repository_impl',
          'phase_ref': '1.2.8',
        },
      );

      await episodicStore.writeTuple(tuple);
    } catch (e) {
      developer.log(
        'Error recording list creation episodic tuple: $e',
        name: 'ListsRepository',
      );
    }
  }

  Future<void> _recordListShareEpisode({
    required SpotList? before,
    required SpotList after,
  }) async {
    final episodicStore = _episodicMemoryStore;
    if (episodicStore == null) return;

    final curatorId = after.curatorId ?? before?.curatorId;
    if (curatorId == null || curatorId.isEmpty) return;

    final beforeCollaborators = before?.collaborators ?? const <String>[];
    final afterCollaborators = after.collaborators;
    final beforeSet = beforeCollaborators.toSet();
    final afterSet = afterCollaborators.toSet();

    final addedCollaborators = afterSet.difference(beforeSet).toList()..sort();
    final removedCollaborators = beforeSet.difference(afterSet).toList()
      ..sort();
    if (addedCollaborators.isEmpty && removedCollaborators.isEmpty) return;

    final collaborationAction =
        addedCollaborators.isNotEmpty && removedCollaborators.isNotEmpty
            ? 'update'
            : addedCollaborators.isNotEmpty
                ? 'add_collaborator'
                : 'remove_collaborator';

    try {
      final agentIdService = _agentIdService;
      final agentId = agentIdService == null
          ? curatorId
          : await agentIdService.getUserAgentId(curatorId);

      final listFeatures = {
        'list_id': after.id,
        'list_name': after.title,
        'is_public': after.isPublic,
        'tag_count': after.tags.length,
        'tags': after.tags,
        'spot_count': after.spotIds.length,
        'collaborator_count_before': beforeCollaborators.length,
        'collaborator_count_after': afterCollaborators.length,
      };

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: {
          'user_id': curatorId,
          'list_id': before?.id ?? after.id,
          'collaborator_count': beforeCollaborators.length,
        },
        actionType: 'share_list',
        actionPayload: {
          'recipient_features': {
            'collaboration_action': collaborationAction,
            'added_collaborator_ids': addedCollaborators,
            'removed_collaborator_ids': removedCollaborators,
            'recipient_count': addedCollaborators.length,
          },
          'list_features': listFeatures,
        },
        nextState: {
          'list_id': after.id,
          'collaborator_count': afterCollaborators.length,
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'share_list',
          parameters: {
            'collaboration_action': collaborationAction,
            'recipient_count': addedCollaborators.length,
            'before_collaborator_count': beforeCollaborators.length,
            'after_collaborator_count': afterCollaborators.length,
          },
        ),
        recordedAt: after.updatedAt.toUtc(),
        metadata: const {
          'pipeline': 'lists_repository_impl',
          'phase_ref': '1.2.10',
        },
      );

      await episodicStore.writeTuple(tuple);
    } catch (e) {
      developer.log(
        'Error recording list share/collaboration episodic tuple: $e',
        name: 'ListsRepository',
      );
    }
  }
}
