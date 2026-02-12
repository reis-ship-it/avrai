import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/ai/action_executor.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/domain/usecases/spots/create_spot_usecase.dart';
import 'package:avrai/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai/domain/repositories/spots_repository.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';

import 'action_executor_test.mocks.dart';

@GenerateMocks([
  CreateSpotUseCase,
  CreateListUseCase,
  UpdateListUseCase,
  SpotsRepository,
  ListsRepository,
])
void main() {
  group('ActionExecutor', () {
    late ActionExecutor executor;
    late MockCreateSpotUseCase mockCreateSpotUseCase;
    late MockCreateListUseCase mockCreateListUseCase;
    late MockUpdateListUseCase mockUpdateListUseCase;
    late MockSpotsRepository mockSpotsRepository;
    late MockListsRepository mockListsRepository;

    setUp(() {
      mockCreateSpotUseCase = MockCreateSpotUseCase();
      mockCreateListUseCase = MockCreateListUseCase();
      mockUpdateListUseCase = MockUpdateListUseCase();
      mockSpotsRepository = MockSpotsRepository();
      mockListsRepository = MockListsRepository();

      executor = ActionExecutor(
        createSpotUseCase: mockCreateSpotUseCase,
        createListUseCase: mockCreateListUseCase,
        updateListUseCase: mockUpdateListUseCase,
        spotsRepository: mockSpotsRepository,
        listsRepository: mockListsRepository,
      );
    });

    group('executeCreateSpot', () {
      test('should successfully create a spot', () async {
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final createdSpot = Spot(
          id: 'spot123',
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'user123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCreateSpotUseCase.call(any)).thenAnswer((_) async => createdSpot);

        final result = await executor.executeCreateSpot(intent);

        expect(result.success, isTrue);
        expect(result.successMessage, contains('Test Spot'));
        expect(result.data['spotId'], equals('spot123'));
        verify(mockCreateSpotUseCase.call(any)).called(1);
      });

      test('should handle create spot failure', () async {
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        when(mockCreateSpotUseCase.call(any)).thenThrow(Exception('Database error'));

        final result = await executor.executeCreateSpot(intent);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Failed to create spot'));
      });

      test('should return failure when use case is not available', () async {
        final executorWithoutUseCase = ActionExecutor();
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final result = await executorWithoutUseCase.executeCreateSpot(intent);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('CreateSpotUseCase not available'));
      });
    });

    group('executeCreateList', () {
      test('should successfully create a list', () async {
        const intent = CreateListIntent(
          title: 'My List',
          description: 'A test list',
          userId: 'user123',
          confidence: 0.8,
        );

        final createdList = SpotList(
          id: 'list123',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          curatorId: 'user123',
        );

        when(mockCreateListUseCase.call(any)).thenAnswer((_) async => createdList);

        final result = await executor.executeCreateList(intent);

        expect(result.success, isTrue);
        expect(result.successMessage, contains('My List'));
        expect(result.data['listId'], equals('list123'));
        verify(mockCreateListUseCase.call(any)).called(1);
      });

      test('should handle create list failure', () async {
        const intent = CreateListIntent(
          title: 'My List',
          description: 'A test list',
          userId: 'user123',
          confidence: 0.8,
        );

        when(mockCreateListUseCase.call(any)).thenThrow(Exception('Database error'));

        final result = await executor.executeCreateList(intent);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Failed to create list'));
      });
    });

    group('executeAddSpotToList', () {
      test('should successfully add spot to list', () async {
        const intent = AddSpotToListIntent(
          spotId: 'spot123',
          listId: 'list456',
          userId: 'user123',
          confidence: 0.8,
        );

        final existingList = SpotList(
          id: 'list456',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          spotIds: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          curatorId: 'user123',
        );

        when(mockListsRepository.getLists()).thenAnswer((_) async => [existingList]);
        when(mockUpdateListUseCase.call(any)).thenAnswer((_) async => existingList.copyWith(
          spotIds: ['spot123'],
          updatedAt: DateTime.now(),
        ));

        final result = await executor.executeAddSpotToList(intent);

        expect(result.success, isTrue);
        expect(result.successMessage, contains('Successfully added'));
        verify(mockUpdateListUseCase.call(any)).called(1);
      });

      test('should handle spot already in list', () async {
        const intent = AddSpotToListIntent(
          spotId: 'spot123',
          listId: 'list456',
          userId: 'user123',
          confidence: 0.8,
        );

        final existingList = SpotList(
          id: 'list456',
          title: 'My List',
          description: 'A test list',
          spots: const [],
          spotIds: const ['spot123'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          curatorId: 'user123',
        );

        when(mockListsRepository.getLists()).thenAnswer((_) async => [existingList]);

        final result = await executor.executeAddSpotToList(intent);

        expect(result.success, isTrue);
        expect(result.successMessage, contains('already in the list'));
        verifyNever(mockUpdateListUseCase.call(any));
      });

      test('should handle list not found', () async {
        const intent = AddSpotToListIntent(
          spotId: 'spot123',
          listId: 'list456',
          userId: 'user123',
          confidence: 0.8,
        );

        when(mockListsRepository.getLists()).thenAnswer((_) async => []);

        final result = await executor.executeAddSpotToList(intent);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('List not found'));
      });
    });

    group('execute', () {
      test('should execute create spot intent', () async {
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final createdSpot = Spot(
          id: 'spot123',
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'user123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCreateSpotUseCase.call(any)).thenAnswer((_) async => createdSpot);

        final result = await executor.execute(intent);

        expect(result.success, isTrue);
      });

      test('should return failure for unknown action type', () async {
        const intent = SearchSpotsIntent(
          query: 'coffee',
          confidence: 0.8,
        );

        final result = await executor.execute(intent);

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Unknown action type'));
      });
    });
  });
}

