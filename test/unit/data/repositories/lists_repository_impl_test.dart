import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/data/repositories/lists_repository_impl.dart';
import 'package:avrai/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai/core/models/misc/list.dart';

import 'lists_repository_impl_test.mocks.dart';

@GenerateMocks([ListsLocalDataSource, ListsRemoteDataSource, Connectivity])
void main() {
  group('ListsRepositoryImpl', () {
    late ListsRepositoryImpl repository;
    late MockListsLocalDataSource mockLocalDataSource;
    late MockListsRemoteDataSource mockRemoteDataSource;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockLocalDataSource = MockListsLocalDataSource();
      mockRemoteDataSource = MockListsRemoteDataSource();
      mockConnectivity = MockConnectivity();
      
      repository = ListsRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
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
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => <SpotList>[]);
        when(mockRemoteDataSource.getLists())
            .thenAnswer((_) async => lists);
        when(mockLocalDataSource.saveList(any))
            .thenAnswer((inv) async => inv.positionalArguments.first as SpotList);

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
        when(mockLocalDataSource.getLists())
            .thenAnswer((_) async => lists);

        final result = await repository.getLists();

        expect(result, isNotEmpty);
        verify(mockLocalDataSource.getLists()).called(1);
        verifyNever(mockRemoteDataSource.getLists());
      });
    });

    group('createList', () {
      test('should create list locally and sync to remote when online', () async {
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
        when(mockLocalDataSource.saveList(list))
            .thenAnswer((_) async => list);
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
        when(mockLocalDataSource.saveList(list))
            .thenAnswer((_) async => list);

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
        when(mockRemoteDataSource.updateList(list))
            .thenAnswer((_) async => list);
        when(mockLocalDataSource.saveList(list))
            .thenAnswer((_) async => list);

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

        when(mockRemoteDataSource.updateList(list))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.saveList(list))
            .thenAnswer((_) async => list);

        final result = await repository.updateList(list);

        expect(result, isNotNull);
        verify(mockLocalDataSource.saveList(list)).called(1);
      });
    });

    group('deleteList', () {
      test('should delete list from remote and local', () async {
        const listId = 'list-1';

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.deleteList(listId))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.deleteList(listId))
            .thenAnswer((_) async {});

        await repository.deleteList(listId);

        verify(mockRemoteDataSource.deleteList(listId)).called(1);
        verify(mockLocalDataSource.deleteList(listId)).called(1);
      });

      test('should delete locally even if remote fails', () async {
        const listId = 'list-1';

        when(mockRemoteDataSource.deleteList(listId))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.deleteList(listId))
            .thenAnswer((_) async {});

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
        when(mockLocalDataSource.getLists()).thenAnswer((_) async => <SpotList>[]);
        when(mockRemoteDataSource.getPublicLists(limit: 50))
            .thenAnswer((_) async => publicLists);
        when(mockLocalDataSource.saveList(any))
            .thenAnswer((inv) async => inv.positionalArguments.first as SpotList);

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
        when(mockLocalDataSource.getLists())
            .thenAnswer((_) async => allLists);

        final result = await repository.getPublicLists();

        expect(result.length, equals(1));
        expect(result.first.isPublic, isTrue);
      });
    });

    group('createStarterListsForUser', () {
      test('should create starter lists for user', () async {
        const userId = 'user-123';

        when(mockLocalDataSource.saveList(any))
            .thenAnswer((inv) async => inv.positionalArguments.first as SpotList);

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

        when(mockLocalDataSource.saveList(any))
            .thenAnswer((inv) async => inv.positionalArguments.first as SpotList);

        await repository.createPersonalizedListsForUser(
          userId: userId,
          userPreferences: preferences,
        );

        verify(mockLocalDataSource.saveList(any)).called(3);
      });
    });
  });
}

