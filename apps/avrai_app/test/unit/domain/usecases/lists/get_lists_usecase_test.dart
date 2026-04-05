import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_core/models/misc/list.dart';

import 'get_lists_usecase_test.mocks.dart';

@GenerateMocks([ListsRepository])
void main() {
  group('GetListsUseCase', () {
    late GetListsUseCase useCase;
    late MockListsRepository mockRepository;

    setUp(() {
      mockRepository = MockListsRepository();
      useCase = GetListsUseCase(mockRepository);
    });

    test('should get lists via repository', () async {
      final lists = [
        SpotList(
          id: 'list-1',
          title: 'List 1',
          description: 'Description 1',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SpotList(
          id: 'list-2',
          title: 'List 2',
          description: 'Description 2',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getLists()).thenAnswer((_) async => lists);

      final result = await useCase();

      expect(result, isNotEmpty);
      expect(result.length, equals(2));
      verify(mockRepository.getLists()).called(1);
    });

    test('should return empty list when no lists exist', () async {
      when(mockRepository.getLists()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
      verify(mockRepository.getLists()).called(1);
    });
  });
}
