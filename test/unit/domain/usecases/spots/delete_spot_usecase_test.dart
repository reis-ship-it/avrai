import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/spots/delete_spot_usecase.dart';
import 'package:avrai/domain/repositories/spots_repository.dart';

import 'delete_spot_usecase_test.mocks.dart';

@GenerateMocks([SpotsRepository])
void main() {
  group('DeleteSpotUseCase', () {
    late DeleteSpotUseCase useCase;
    late MockSpotsRepository mockRepository;

    setUp(() {
      mockRepository = MockSpotsRepository();
      useCase = DeleteSpotUseCase(mockRepository);
    });

    test('should delete spot via repository', () async {
      const spotId = 'spot-1';

      when(mockRepository.deleteSpot(spotId))
          .thenAnswer((_) async => Future.value());

      await expectLater(
        useCase(spotId),
        completes,
      );

      verify(mockRepository.deleteSpot(spotId)).called(1);
    });
  });
}

