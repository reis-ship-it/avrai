import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_core/models/misc/list.dart';

import 'update_list_usecase_test.mocks.dart';

@GenerateMocks([ListsRepository])
void main() {
  group('UpdateListUseCase', () {
    late UpdateListUseCase useCase;
    late MockListsRepository mockRepository;

    setUp(() {
      mockRepository = MockListsRepository();
      useCase = UpdateListUseCase(mockRepository);
    });

    test('should update list via repository', () async {
      final list = SpotList(
        id: 'list-1',
        title: 'Updated List',
        description: 'Updated Description',
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.updateList(list)).thenAnswer((_) async => list);

      final result = await useCase(list);

      expect(result, isNotNull);
      expect(result.title, equals('Updated List'));
      verify(mockRepository.updateList(list)).called(1);
    });
  });
}
