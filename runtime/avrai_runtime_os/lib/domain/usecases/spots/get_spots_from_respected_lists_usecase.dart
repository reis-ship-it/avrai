import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';

class GetSpotsFromRespectedListsUseCase {
  final SpotsRepository repository;

  GetSpotsFromRespectedListsUseCase(this.repository);

  Future<List<Spot>> call() async {
    return await repository.getSpotsFromRespectedLists();
  }
}
