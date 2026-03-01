import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';

class UpdateSpotUseCase {
  final SpotsRepository spotsRepository;

  UpdateSpotUseCase(this.spotsRepository);

  Future<Spot> call(Spot spot) async {
    return await spotsRepository.updateSpot(spot);
  }
}
