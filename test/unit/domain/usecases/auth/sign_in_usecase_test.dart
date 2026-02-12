import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/core/models/user/user.dart';

import 'sign_in_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('SignInUseCase', () {
    late SignInUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignInUseCase(mockRepository);
    });

    test('should sign in user via repository', () async {
      const email = 'test@example.com';
      const password = 'password123';
      final user = User(
        id: 'user-123',
        email: email,
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.signIn(email, password))
          .thenAnswer((_) async => user);

      final result = await useCase(email, password);

      expect(result, isNotNull);
      expect(result?.email, equals(email));
      verify(mockRepository.signIn(email, password)).called(1);
    });

    test('should return null when sign in fails', () async {
      const email = 'invalid@example.com';
      const password = 'wrongpassword';

      when(mockRepository.signIn(email, password))
          .thenAnswer((_) async => null);

      final result = await useCase(email, password);

      expect(result, isNull);
      verify(mockRepository.signIn(email, password)).called(1);
    });
  });
}

