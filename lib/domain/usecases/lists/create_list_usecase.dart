import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';

class CreateListUseCase {
  final ListsRepository repository;

  CreateListUseCase(this.repository);

  Future<SpotList> call(SpotList list) async {
    return await repository.createList(list);
  }
}
