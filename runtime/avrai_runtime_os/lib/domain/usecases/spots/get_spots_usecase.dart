import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';

class GetSpotsUseCase {
  final SpotsRepository repository;

  GetSpotsUseCase(this.repository);

  Future<List<Spot>> call() async {
    return await repository.getSpots();
  }
}
