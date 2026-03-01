import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';

class CreateListUseCase {
  final ListsRepository repository;

  CreateListUseCase(this.repository);

  Future<SpotList> call(SpotList list) async {
    return await repository.createList(list);
  }
}
