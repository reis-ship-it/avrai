import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/data/repositories/auth_repository_impl.dart';
import 'package:avrai/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai/data/datasources/remote/auth_remote_datasource.dart';
import 'package:avrai/core/models/user/user.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthLocalDataSource, AuthRemoteDataSource, Connectivity])
void main() {
  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl repository;
    late MockAuthLocalDataSource mockLocalDataSource;
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockLocalDataSource = MockAuthLocalDataSource();
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockConnectivity = MockConnectivity();
      
      repository = AuthRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
      );

      // Default to "online" unless a test overrides it.
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // executeOfflineFirst always consults the local cache first; default to empty.
      when(mockLocalDataSource.getCurrentUser()).thenAnswer((_) async => null);
    });

    group('signIn', () {
      test('should sign in via remote when online', () async {
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

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.signIn(email, password))
            .thenAnswer((_) async => user);
        when(mockLocalDataSource.saveUser(user))
            .thenAnswer((_) async => Future.value());

        final result = await repository.signIn(email, password);

        expect(result, isNotNull);
        expect(result?.email, equals(email));
        verify(mockRemoteDataSource.signIn(email, password)).called(1);
        verify(mockLocalDataSource.saveUser(user)).called(1);
      });

      test('should fallback to local sign in when offline', () async {
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

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        // AuthRepositoryImpl is online-first for sign-in and will attempt remote
        // even when offline checks indicate none; simulate offline by throwing.
        when(mockRemoteDataSource.signIn(email, password))
            .thenThrow(Exception('Offline'));
        when(mockLocalDataSource.signIn(email, password))
            .thenAnswer((_) async => user);

        final result = await repository.signIn(email, password);

        expect(result, isNotNull);
        expect(result?.email, equals(email));
        verify(mockLocalDataSource.signIn(email, password)).called(1);
        verify(mockRemoteDataSource.signIn(email, password)).called(1);
      });

      test('should fallback to local when remote fails', () async {
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

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.signIn(email, password))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.signIn(email, password))
            .thenAnswer((_) async => user);

        final result = await repository.signIn(email, password);

        expect(result, isNotNull);
        expect(result?.email, equals(email));
        verify(mockLocalDataSource.signIn(email, password)).called(1);
      });
    });

    group('signUp', () {
      test('should sign up via remote when online', () async {
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

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.signUp(email, password, name))
            .thenAnswer((_) async => user);
        when(mockLocalDataSource.saveUser(user))
            .thenAnswer((_) async => Future.value());

        final result = await repository.signUp(email, password, name);

        expect(result, isNotNull);
        expect(result?.email, equals(email));
        verify(mockRemoteDataSource.signUp(email, password, name)).called(1);
        verify(mockLocalDataSource.saveUser(user)).called(1);
      });

      test('should throw exception when offline', () async {
        const email = 'new@example.com';
        const password = 'password123';
        const name = 'New User';

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockRemoteDataSource.signUp(email, password, name))
            .thenThrow(Exception('Offline'));

        expect(
          () => repository.signUp(email, password, name),
          throwsA(isA<Exception>()),
        );

        verify(mockRemoteDataSource.signUp(email, password, name)).called(1);
      });
    });

    group('signOut', () {
      test('should sign out from remote and local', () async {
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.signOut())
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.clearUser())
            .thenAnswer((_) async => Future.value());

        await repository.signOut();

        verify(mockRemoteDataSource.signOut()).called(1);
        verify(mockLocalDataSource.clearUser()).called(1);
      });

      test('should clear local even if remote fails', () async {
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.signOut())
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.clearUser())
            .thenAnswer((_) async => Future.value());

        await repository.signOut();

        verify(mockLocalDataSource.clearUser()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should get user from remote when available', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getCurrentUser()).thenAnswer((_) async => null);
        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => user);
        when(mockLocalDataSource.saveUser(user))
            .thenAnswer((_) async => Future.value());

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        verify(mockRemoteDataSource.getCurrentUser()).called(1);
        verify(mockLocalDataSource.saveUser(user)).called(1);
      });

      test('should fallback to local when remote fails', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource.getCurrentUser())
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.getCurrentUser())
            .thenAnswer((_) async => user);

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        verify(mockLocalDataSource.getCurrentUser()).called(1);
      });
    });

    group('updateCurrentUser', () {
      test('should update user via remote and local', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Updated User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final updatedUser = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Updated User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.saveUser(user))
            .thenAnswer((_) async => Future.value());
        when(mockRemoteDataSource.updateUser(user))
            .thenAnswer((_) async => updatedUser);
        when(mockLocalDataSource.saveUser(updatedUser))
            .thenAnswer((_) async => Future.value());

        final result = await repository.updateCurrentUser(user);

        expect(result, isNotNull);
        verify(mockRemoteDataSource.updateUser(user)).called(1);
        verify(mockLocalDataSource.saveUser(updatedUser)).called(1);
      });
    });

    group('isOfflineMode', () {
      test('should return true when remote data source is null', () async {
        final offlineRepository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );

        final result = await offlineRepository.isOfflineMode();

        expect(result, isTrue);
      });

      test('should return false when remote data source exists', () async {
        final result = await repository.isOfflineMode();

        expect(result, isFalse);
      });
    });
  });
}

