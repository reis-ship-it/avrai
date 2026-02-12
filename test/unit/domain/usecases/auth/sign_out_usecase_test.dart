import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';

import 'sign_out_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('SignOutUseCase', () {
    late SignOutUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignOutUseCase(mockRepository);
    });

    test('should sign out user via repository', () async {
      when(mockRepository.signOut())
          .thenAnswer((_) async => Future.value());

      await expectLater(
        useCase(),
        completes,
      );

      verify(mockRepository.signOut()).called(1);
    });
  });
}

