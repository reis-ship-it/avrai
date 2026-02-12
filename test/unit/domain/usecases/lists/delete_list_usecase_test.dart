import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';

import 'delete_list_usecase_test.mocks.dart';

@GenerateMocks([ListsRepository])
void main() {
  group('DeleteListUseCase', () {
    late DeleteListUseCase useCase;
    late MockListsRepository mockRepository;

    setUp(() {
      mockRepository = MockListsRepository();
      useCase = DeleteListUseCase(mockRepository);
    });

    test('should delete list via repository', () async {
      const listId = 'list-1';

      when(mockRepository.deleteList(listId))
          .thenAnswer((_) async => Future.value());

      await expectLater(
        useCase(listId),
        completes,
      );

      verify(mockRepository.deleteList(listId)).called(1);
    });
  });
}

