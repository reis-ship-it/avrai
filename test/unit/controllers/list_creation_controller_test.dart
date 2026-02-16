import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/controllers/list_creation_controller.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

import 'list_creation_controller_test.mocks.dart';

@GenerateMocks([
  ListsRepository,
  AtomicClockService,
])
void main() {
  group('ListCreationController', () {
    late ListCreationController controller;
    late MockListsRepository mockListsRepository;
    late MockAtomicClockService mockAtomicClock;
    late EpisodicMemoryStore episodicMemoryStore;
    late UnifiedUser testUser;
    final DateTime now = DateTime.now();

    setUp(() {
      mockListsRepository = MockListsRepository();
      mockAtomicClock = MockAtomicClockService();
      episodicMemoryStore = EpisodicMemoryStore();

      controller = ListCreationController(
        listsRepository: mockListsRepository,
        atomicClock: mockAtomicClock,
        episodicMemoryStore: episodicMemoryStore,
        agentIdService: _TestAgentIdService(),
      );

      testUser = UnifiedUser(
        id: 'user_123',
        email: 'user@test.com',
        displayName: 'Test User',
        createdAt: now,
        updatedAt: now,
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final data = ListFormData(
          title: 'My List',
          description: 'A test list',
          category: 'General',
          curator: testUser,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty title', () {
        // Arrange
        final data = ListFormData(
          title: '',
          description: 'A test list',
          curator: testUser,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['title'], isNotNull);
      });

      test('should return invalid result for title too short', () {
        // Arrange
        final data = ListFormData(
          title: 'AB',
          description: 'A test list',
          curator: testUser,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['title'], contains('at least 3 characters'));
      });

      test('should return invalid result for empty description', () {
        // Arrange
        final data = ListFormData(
          title: 'My List',
          description: '',
          curator: testUser,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['description'], isNotNull);
      });
    });

    group('createList', () {
      test('should successfully create list', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final createdList = SpotList(
          id: 'list_123',
          title: 'My List',
          description: 'A test list',
          category: 'General',
          isPublic: true,
          spots: const [],
          spotIds: const [],
          curatorId: testUser.id,
          createdAt: now,
          updatedAt: now,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenAnswer((_) async => createdList);

        // Act
        final result = await controller.createList(
          data: ListFormData(
            title: 'My List',
            description: 'A test list',
            category: 'General',
            curator: testUser,
          ),
          curator: testUser,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.list, isNotNull);
        expect(result.list?.title, equals('My List'));
        expect(result.spotsAdded, equals(0));

        verify(mockAtomicClock.getAtomicTimestamp()).called(1);
        verify(mockListsRepository.canUserCreateList(testUser.id)).called(1);
        verify(mockListsRepository.createList(any)).called(1);
      });

      test('should successfully create list with initial spots', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final createdList = SpotList(
          id: 'list_123',
          title: 'My List',
          description: 'A test list',
          spotIds: ['spot1', 'spot2'],
          spots: const [],
          curatorId: testUser.id,
          createdAt: now,
          updatedAt: now,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenAnswer((_) async => createdList);

        // Act
        final result = await controller.createList(
          data: ListFormData(
            title: 'My List',
            description: 'A test list',
            curator: testUser,
          ),
          curator: testUser,
          initialSpotIds: ['spot1', 'spot2'],
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.list, isNotNull);
        expect(result.list?.spotIds, containsAll(['spot1', 'spot2']));
        expect(result.spotsAdded, equals(2));

        // Verify list was created with spotIds included
        verify(mockListsRepository.createList(argThat(
          predicate<SpotList>((list) =>
              list.spotIds.length == 2 &&
              list.spotIds.contains('spot1') &&
              list.spotIds.contains('spot2')),
        ))).called(1);
      });

      test('should return failure when user does not have permission',
          () async {
        // Arrange
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.createList(
          data: ListFormData(
            title: 'My List',
            description: 'A test list',
            curator: testUser,
          ),
          curator: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('PERMISSION_DENIED'));
        verifyNever(mockListsRepository.createList(any));
      });

      test('should return failure when list creation fails', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await controller.createList(
          data: ListFormData(
            title: 'My List',
            description: 'A test list',
            curator: testUser,
          ),
          curator: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('UNEXPECTED_ERROR'));
        expect(result.error, contains('Database error'));
      });

      test('should use atomic timestamps for list creation', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2024, 1, 1, 12, 0, 0),
        );
        final createdList = SpotList(
          id: 'list_123',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          curatorId: testUser.id,
          createdAt: atomicTimestamp.serverTime,
          updatedAt: atomicTimestamp.serverTime,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenAnswer((_) async => createdList);

        // Act
        final result = await controller.createList(
          data: ListFormData(
            title: 'My List',
            description: 'A test list',
            curator: testUser,
          ),
          curator: testUser,
        );

        // Assert
        expect(result.success, isTrue);
        // Verify list was created with atomic timestamp
        verify(mockListsRepository.createList(argThat(
          predicate<SpotList>((list) =>
              list.createdAt == atomicTimestamp.serverTime &&
              list.updatedAt == atomicTimestamp.serverTime),
        ))).called(1);
      });

      test('records episodic tuple with list composition features', () async {
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2026, 2, 16, 15, 0, 0),
        );
        final createdList = SpotList(
          id: 'list_episodic',
          title: 'Jazz Night Ideas',
          description: 'Late night list',
          category: 'Nightlife',
          isPublic: true,
          spots: const [],
          spotIds: const ['spot-a', 'spot-b'],
          curatorId: testUser.id,
          tags: const ['jazz', 'late-night'],
          createdAt: atomicTimestamp.serverTime,
          updatedAt: atomicTimestamp.serverTime,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenAnswer((_) async => createdList);

        final result = await controller.createList(
          data: ListFormData(
            title: 'Jazz Night Ideas',
            description: 'Late night list',
            category: 'Nightlife',
            tags: const ['jazz', 'late-night'],
            curator: testUser,
          ),
          curator: testUser,
          initialSpotIds: const ['spot-a', 'spot-b'],
        );

        expect(result.success, isTrue);
        final tuples = await episodicMemoryStore.replay(agentId: 'agent_test');
        expect(tuples, hasLength(1));
        expect(tuples.first.actionType, 'create_list');
        expect(tuples.first.outcome.category.name, 'binary');
        expect(
          tuples.first.actionPayload['list_composition_features']['item_count'],
          2,
        );
        expect(
          tuples.first.actionPayload['list_composition_features']
              ['composition_data_quality'],
          'id_only',
        );
        expect(
          tuples.first.actionPayload['list_composition_features']
              ['category_distribution'],
          {'Nightlife': 1.0},
        );
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final createdList = SpotList(
          id: 'list_123',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          curatorId: testUser.id,
          createdAt: now,
          updatedAt: now,
        );

        final data = ListFormData(
          title: 'My List',
          description: 'A test list',
          curator: testUser,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockListsRepository.canUserCreateList(testUser.id))
            .thenAnswer((_) async => true);
        when(mockListsRepository.createList(any))
            .thenAnswer((_) async => createdList);

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isTrue);
        expect(result.list, isNotNull);
      });

      test('should return failure when curator is missing', () async {
        // Arrange
        final data = ListFormData(
          title: 'My List',
          description: 'A test list',
          // curator is null
        );

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('MISSING_CURATOR'));
      });
    });

    group('rollback', () {
      test('should delete list on rollback', () async {
        // Arrange
        final list = SpotList(
          id: 'list_123',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          createdAt: now,
          updatedAt: now,
        );

        final result = ListCreationResult.success(list: list);

        when(mockListsRepository.deleteList('list_123'))
            .thenAnswer((_) async => Future.value());

        // Act
        await controller.rollback(result);

        // Assert
        verify(mockListsRepository.deleteList('list_123')).called(1);
      });

      test('should not throw when rollback is called with failure result',
          () async {
        // Arrange
        final result = ListCreationResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
        verifyNever(mockListsRepository.deleteList(any));
      });
    });
  });
}

class _TestAgentIdService extends AgentIdService {
  @override
  Future<String> getUserAgentId(String userId) async => 'agent_test';
}
