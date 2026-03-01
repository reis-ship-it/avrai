import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_core/models/misc/list.dart';

import 'create_list_usecase_test.mocks.dart';

@GenerateMocks([ListsRepository])
void main() {
  group('CreateListUseCase', () {
    late CreateListUseCase useCase;
    late MockListsRepository mockRepository;

    setUp(() {
      mockRepository = MockListsRepository();
      useCase = CreateListUseCase(mockRepository);
    });

    test('should create list via repository', () async {
      final list = SpotList(
        id: 'list-1',
        title: 'New List',
        description: 'New Description',
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createList(list)).thenAnswer((_) async => list);

      final result = await useCase(list);

      expect(result, isNotNull);
      expect(result.title, equals('New List'));
      verify(mockRepository.createList(list)).called(1);
    });
  });
}
