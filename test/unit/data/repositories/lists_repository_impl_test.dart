import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/data/repositories/lists_repository_impl.dart';
import 'package:avrai/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

import 'lists_repository_impl_test.mocks.dart';

@GenerateMocks([ListsLocalDataSource, ListsRemoteDataSource, Connectivity])
void main() {
  group('ListsRepositoryImpl', () {
    late ListsRepositoryImpl repository;
    late MockListsLocalDataSource mockLocalDataSource;
    late MockListsRemoteDataSource mockRemoteDataSource;
    late MockConnectivity mockConnectivity;
    late EpisodicMemoryStore episodicMemoryStore;

    setUp(() {
      mockLocalDataSource = MockListsLocalDataSource();
      mockRemoteDataSource = MockListsRemoteDataSource();
      mockConnectivity = MockConnectivity();
      episodicMemoryStore = EpisodicMemoryStore();

      repository = ListsRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
        episodicMemoryStore: episodicMemoryStore,
        agentIdService: _TestAgentIdService(),
      );
    });

    group('getLists', () {
      test('should get lists from remote when online', () async {
        final lists = [
          SpotList(
            id: 'list-1',
            title: 'Test List 1',
            description: 'Description 1',
            spots: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SpotList(
            id: 'list-2',
            title: 'Test List 2',
            description: 'Description 2',
            spots: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        // Offline-first repositories always perform the local read first.
        when(mockLocalDataSource.getLists())
            .thenAnswer((_) async => <SpotList>[]);
        when(mockRemoteDataSource.getLists()).thenAnswer((_) async => lists);
        when(mockLocalDataSource.saveList(any)).thenAnswer(
            (inv) async => inv.positionalArguments.first as SpotList);

        final result = await repository.getLists();

        expect(result, isNotEmpty);
        expect(result.length, equals(2));
        verify(mockRemoteDataSource.getLists()).called(1);
        verify(mockLocalDataSource.saveList(any)).called(2);
      });

      test('should fallback to local when offline', () async {
        final lists = [
          SpotList(
            id: 'list-1',
            title: 'Local List',
            description: 'Local Description',
            spots: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => lists);

        final result = await repository.getLists();

        expect(result, isNotEmpty);
        verify(mockLocalDataSource.getLists()).called(1);
        verifyNever(mockRemoteDataSource.getLists());
      });
    });

    group('createList', () {
      test('should create list locally and sync to remote when online',
          () async {
        final list = SpotList(
          id: 'new-list',
          title: 'New List',
          description: 'New Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.saveList(list)).thenAnswer((_) async => list);
        when(mockRemoteDataSource.createList(list))
            .thenAnswer((_) async => list);

        final result = await repository.createList(list);

        expect(result, isNotNull);
        verify(mockLocalDataSource.saveList(list)).called(1);
        verify(mockRemoteDataSource.createList(list)).called(1);
      });

      test('should create list locally when offline', () async {
        final list = SpotList(
          id: 'new-list',
          title: 'New List',
          description: 'New Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.saveList(list)).thenAnswer((_) async => list);

        final result = await repository.createList(list);

        expect(result, isNotNull);
        verify(mockLocalDataSource.saveList(list)).called(1);
        verifyNever(mockRemoteDataSource.createList(any));
      });
    });

    group('updateList', () {
      test('should update list via remote and local', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'Updated List',
          description: 'Updated Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => [list]);
        when(mockRemoteDataSource.updateList(list))
            .thenAnswer((_) async => list);
        when(mockLocalDataSource.saveList(list)).thenAnswer((_) async => list);

        final result = await repository.updateList(list);

        expect(result, isNotNull);
        verify(mockRemoteDataSource.updateList(list)).called(1);
        // Offline-first flow writes locally first, then syncs remote result back to local.
        verify(mockLocalDataSource.saveList(list)).called(2);
      });

      test('should fallback to local when remote fails', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'Updated List',
          description: 'Updated Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockLocalDataSource.getLists()).thenAnswer((_) async => [list]);
        when(mockRemoteDataSource.updateList(list))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.saveList(list)).thenAnswer((_) async => list);

        final result = await repository.updateList(list);

        expect(result, isNotNull);
        verify(mockLocalDataSource.saveList(list)).called(1);
      });

      test('records list modification tuple with add/remove deltas', () async {
        final before = SpotList(
          id: 'list-1',
          title: 'List',
          description: 'Before',
          spots: const [],
          spotIds: const ['spot-1', 'spot-2'],
          curatorId: 'user-123',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final after = before.copyWith(
          description: 'After',
          spotIds: const ['spot-2', 'spot-3'],
          updatedAt: DateTime.utc(2026, 2, 16, 16, 0, 0),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => [before]);
        when(mockLocalDataSource.saveList(after))
            .thenAnswer((_) async => after);
        when(mockRemoteDataSource.updateList(after))
            .thenAnswer((_) async => after);

        final result = await repository.updateList(after);
        expect(result.id, 'list-1');

        final tuples = await episodicMemoryStore.replay(agentId: 'agent_repo');
        expect(tuples, hasLength(1));
        expect(tuples.first.actionType, 'modify_list');
        expect(
          tuples.first.actionPayload['item_added_or_removed_features']
              ['added_spot_ids'],
          ['spot-3'],
        );
        expect(
          tuples.first.actionPayload['item_added_or_removed_features']
              ['removed_spot_ids'],
          ['spot-1'],
        );
        expect(
          tuples.first.actionPayload['list_state_before']['spot_count'],
          2,
        );
        expect(
          tuples.first.actionPayload['list_state_after']['spot_count'],
          2,
        );
        expect(
          tuples.first.actionPayload['list_state_after']['description'],
          'After',
        );
      });

      test('records share_list tuple when collaborators are added', () async {
        final before = SpotList(
          id: 'list-collab',
          title: 'Team List',
          description: 'Before collaborators',
          spots: const [],
          spotIds: const ['spot-1'],
          collaborators: const ['user-a'],
          curatorId: 'user-123',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final after = SpotList(
          id: before.id,
          title: before.title,
          description: 'After collaborators',
          spots: before.spots,
          spotIds: before.spotIds,
          collaborators: const ['user-a', 'user-b'],
          curatorId: before.curatorId,
          createdAt: before.createdAt,
          updatedAt: DateTime.utc(2026, 2, 16, 17, 30, 0),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => [before]);
        when(mockLocalDataSource.saveList(after))
            .thenAnswer((_) async => after);
        when(mockRemoteDataSource.updateList(after))
            .thenAnswer((_) async => after);

        await repository.updateList(after);

        final tuples = await episodicMemoryStore.replay(agentId: 'agent_repo');
        expect(tuples.length, 2);
        final shareTuple =
            tuples.firstWhere((t) => t.actionType == 'share_list');
        expect(
          shareTuple.actionPayload['recipient_features']
              ['added_collaborator_ids'],
          ['user-b'],
        );
        expect(
          shareTuple.actionPayload['list_features']['collaborator_count_after'],
          2,
        );
        expect(
          shareTuple.metadata['phase_ref'],
          '1.2.10',
        );
      });
    });

    group('deleteList', () {
      test('should delete list from remote and local', () async {
        const listId = 'list-1';

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.deleteList(listId)).thenAnswer((_) async {});
        when(mockLocalDataSource.deleteList(listId)).thenAnswer((_) async {});

        await repository.deleteList(listId);

        verify(mockRemoteDataSource.deleteList(listId)).called(1);
        verify(mockLocalDataSource.deleteList(listId)).called(1);
      });

      test('should delete locally even if remote fails', () async {
        const listId = 'list-1';

        when(mockRemoteDataSource.deleteList(listId))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.deleteList(listId)).thenAnswer((_) async {});

        await repository.deleteList(listId);

        verify(mockLocalDataSource.deleteList(listId)).called(1);
      });
    });

    group('getPublicLists', () {
      test('should get public lists from remote when online', () async {
        final publicLists = [
          SpotList(
            id: 'public-1',
            title: 'Public List',
            description: 'Public Description',
            spots: [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        // Offline-first repositories always perform the local read first.
        when(mockLocalDataSource.getLists())
            .thenAnswer((_) async => <SpotList>[]);
        when(mockRemoteDataSource.getPublicLists(limit: 50))
            .thenAnswer((_) async => publicLists);
        when(mockLocalDataSource.saveList(any)).thenAnswer(
            (inv) async => inv.positionalArguments.first as SpotList);

        final result = await repository.getPublicLists();

        expect(result, isNotEmpty);
        verify(mockRemoteDataSource.getPublicLists(limit: 50)).called(1);
      });

      test('should filter public lists from local when offline', () async {
        final allLists = [
          SpotList(
            id: 'public-1',
            title: 'Public List',
            description: 'Public Description',
            spots: [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SpotList(
            id: 'private-1',
            title: 'Private List',
            description: 'Private Description',
            spots: [],
            isPublic: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => allLists);

        final result = await repository.getPublicLists();

        expect(result.length, equals(1));
        expect(result.first.isPublic, isTrue);
      });
    });

    group('createStarterListsForUser', () {
      test('should create starter lists for user', () async {
        const userId = 'user-123';

        when(mockLocalDataSource.saveList(any)).thenAnswer(
            (inv) async => inv.positionalArguments.first as SpotList);

        await repository.createStarterListsForUser(userId: userId);

        verify(mockLocalDataSource.saveList(any)).called(3);
      });
    });

    group('createPersonalizedListsForUser', () {
      test('should create personalized lists based on preferences', () async {
        const userId = 'user-123';
        final preferences = {
          'interests': ['coffee', 'parks'],
        };

        when(mockLocalDataSource.saveList(any)).thenAnswer(
            (inv) async => inv.positionalArguments.first as SpotList);

        await repository.createPersonalizedListsForUser(
          userId: userId,
          userPreferences: preferences,
        );

        verify(mockLocalDataSource.saveList(any)).called(3);
      });
    });
  });
}

class _TestAgentIdService extends AgentIdService {
  @override
  Future<String> getUserAgentId(String userId) async => 'agent_repo';
}
