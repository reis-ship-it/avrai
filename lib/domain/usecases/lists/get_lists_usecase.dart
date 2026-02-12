import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';

class GetListsUseCase {
  final ListsRepository repository;

  GetListsUseCase(this.repository);

  Future<List<SpotList>> call() async {
    return await repository.getLists();
  }
}
