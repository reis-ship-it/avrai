import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/core/models/user/user.dart';

import 'get_current_user_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = GetCurrentUserUseCase(mockRepository);
    });

    test('should get current user via repository', () async {
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getCurrentUser())
          .thenAnswer((_) async => user);

      final result = await useCase();

      expect(result, isNotNull);
      expect(result?.email, equals('test@example.com'));
      verify(mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when no user is signed in', () async {
      when(mockRepository.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
      verify(mockRepository.getCurrentUser()).called(1);
    });
  });
}

