import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/profile_update_controller.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

import 'profile_update_controller_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  AtomicClockService,
])
void main() {
  group('ProfileUpdateController', () {
    late ProfileUpdateController controller;
    late MockAuthRepository mockAuthRepository;
    late MockAtomicClockService mockAtomicClock;
    final DateTime now = DateTime.now();
    late User testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockAtomicClock = MockAtomicClockService();

      controller = ProfileUpdateController(
        authRepository: mockAuthRepository,
        atomicClock: mockAtomicClock,
      );

      testUser = User(
        id: 'user_123',
        email: 'user@test.com',
        name: 'Test User',
        displayName: 'Test Display',
        role: UserRole.user,
        createdAt: now,
        updatedAt: now,
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final data = ProfileUpdateData(
          displayName: 'New Name',
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty displayName', () {
        // Arrange
        final data = ProfileUpdateData(
          displayName: '',
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['displayName'], isNotNull);
      });
    });

    group('updateProfile', () {
      test('should successfully update profile', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );
        final updatedUser = testUser.copyWith(
          displayName: 'Updated Name',
          updatedAt: atomicTimestamp.serverTime,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(mockAuthRepository.updateCurrentUser(any))
            .thenAnswer((_) async => updatedUser);

        // Act
        final result = await controller.updateProfile(
          userId: 'user_123',
          data: ProfileUpdateData(
            displayName: 'Updated Name',
          ),
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user?.displayName, equals('Updated Name'));

        verify(mockAtomicClock.getAtomicTimestamp()).called(1);
        verify(mockAuthRepository.getCurrentUser()).called(1);
        verify(mockAuthRepository.updateCurrentUser(any)).called(1);
      });

      test('should return failure when user not found', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.updateProfile(
          userId: 'user_123',
          data: ProfileUpdateData(
            displayName: 'Updated Name',
          ),
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('USER_NOT_FOUND'));
        verifyNever(mockAuthRepository.updateCurrentUser(any));
      });

      test('should return failure when user ID mismatch', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await controller.updateProfile(
          userId: 'different_user',
          data: ProfileUpdateData(
            displayName: 'Updated Name',
          ),
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('USER_NOT_FOUND'));
        verifyNever(mockAuthRepository.updateCurrentUser(any));
      });

      test('should return failure when update fails', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(mockAuthRepository.updateCurrentUser(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.updateProfile(
          userId: 'user_123',
          data: ProfileUpdateData(
            displayName: 'Updated Name',
          ),
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('UPDATE_FAILED'));
      });

      test('should use atomic timestamps for profile update', () async {
        // Arrange
        final atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime(2024, 1, 1, 12, 0, 0),
        );
        final updatedUser = testUser.copyWith(
          displayName: 'Updated Name',
          updatedAt: atomicTimestamp.serverTime,
        );

        when(mockAtomicClock.getAtomicTimestamp())
            .thenAnswer((_) async => atomicTimestamp);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(mockAuthRepository.updateCurrentUser(any))
            .thenAnswer((_) async => updatedUser);

        // Act
        final result = await controller.updateProfile(
          userId: 'user_123',
          data: ProfileUpdateData(
            displayName: 'Updated Name',
          ),
        );

        // Assert
        expect(result.success, isTrue);
        // Verify user was updated with atomic timestamp
        verify(mockAuthRepository.updateCurrentUser(argThat(
          predicate<User>((user) =>
              user.updatedAt == atomicTimestamp.serverTime &&
              user.displayName == 'Updated Name'),
        ))).called(1);
      });
    });

    group('rollback', () {
      test('should restore previous user on rollback', () async {
        // Arrange
        final updatedUser = testUser.copyWith(
          displayName: 'Updated Name',
          updatedAt: now.add(const Duration(hours: 1)),
        );

        final result = ProfileUpdateResult.success(
          user: updatedUser,
          previousUser: testUser,
        );

        when(mockAuthRepository.updateCurrentUser(testUser))
            .thenAnswer((_) async => testUser);

        // Act
        await controller.rollback(result);

        // Assert
        verify(mockAuthRepository.updateCurrentUser(testUser)).called(1);
      });

      test('should not throw when rollback is called with failure result', () async {
        // Arrange
        final result = ProfileUpdateResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
        verifyNever(mockAuthRepository.updateCurrentUser(any));
      });
    });
  });
}

