import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';

class CreateSpotUseCase {
  final SpotsRepository repository;

  CreateSpotUseCase(this.repository);

  Future<Spot> call(Spot spot) async {
    return await repository.createSpot(spot);
  }
}
