import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';

class DeleteSpotUseCase {
  final SpotsRepository spotsRepository;

  DeleteSpotUseCase(this.spotsRepository);

  Future<void> call(String spotId) async {
    await spotsRepository.deleteSpot(spotId);
  }
}
