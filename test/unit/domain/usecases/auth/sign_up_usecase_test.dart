import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/core/models/user/user.dart';

import 'sign_up_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('SignUpUseCase', () {
    late SignUpUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignUpUseCase(mockRepository);
    });

    test('should sign up user via repository', () async {
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      final user = User(
        id: 'user-456',
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.signUp(email, password, name))
          .thenAnswer((_) async => user);

      final result = await useCase(email, password, name);

      expect(result, isNotNull);
      expect(result?.email, equals(email));
      expect(result?.name, equals(name));
      verify(mockRepository.signUp(email, password, name)).called(1);
    });

    test('should handle sign up failure', () async {
      const email = 'existing@example.com';
      const password = 'password123';
      const name = 'Existing User';

      when(mockRepository.signUp(email, password, name))
          .thenAnswer((_) async => null);

      final result = await useCase(email, password, name);

      expect(result, isNull);
      verify(mockRepository.signUp(email, password, name)).called(1);
    });
  });
}

