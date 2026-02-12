import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';

class UpdateListUseCase {
  final ListsRepository repository;

  UpdateListUseCase(this.repository);

  Future<SpotList> call(SpotList list) async {
    return await repository.updateList(list);
  }
}
