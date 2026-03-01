import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai_runtime_os/controllers/sync_controller.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_profile.dart';

import 'sync_controller_test.mocks.dart';

@GenerateMocks([
  EnhancedConnectivityService,
  PersonalitySyncService,
  PersonalityLearning,
])
void main() {
  group('SyncController', () {
    late SyncController controller;
    late MockEnhancedConnectivityService mockConnectivityService;
    late MockPersonalitySyncService mockPersonalitySyncService;
    late MockPersonalityLearning mockPersonalityLearning;

    late PersonalityProfile testPersonalityProfile;

    setUp(() {
      mockConnectivityService = MockEnhancedConnectivityService();
      mockPersonalitySyncService = MockPersonalitySyncService();
      mockPersonalityLearning = MockPersonalityLearning();

      controller = SyncController(
        connectivityService: mockConnectivityService,
        personalitySyncService: mockPersonalitySyncService,
        personalityLearning: mockPersonalityLearning,
      );

      testPersonalityProfile = PersonalityProfile.initial(
        'agent_123',
        userId: 'user_123',
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        const input = SyncInput(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty userId', () {
        // Arrange
        const input = SyncInput(
          userId: '',
          password: 'password123',
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['userId'], equals('User ID is required'));
      });

      test('should return invalid result for empty password', () {
        // Arrange
        const input = SyncInput(
          userId: 'user_123',
          password: '',
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['password'], equals('Password is required'));
      });
    });

    group('syncUserData', () {
      test('should successfully sync personality profile', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).thenAnswer((_) async => true);

        // Act
        final result = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedItems['personality'], equals('synced'));
        expect(result.syncTimestamp, isNotNull);
        verify(mockConnectivityService.hasInternetAccess()).called(1);
        verify(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .called(1);
        verify(mockPersonalityLearning.initializePersonality('user_123'))
            .called(1);
        verify(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).called(1);
      });

      test('should return failure when no connectivity', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('NO_CONNECTIVITY'));
        expect(result.error, contains('No internet connectivity'));
        verify(mockConnectivityService.hasInternetAccess()).called(1);
        verifyNever(mockPersonalitySyncService.isCloudSyncEnabled(any));
      });

      test('should return failure when sync is disabled', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('SYNC_DISABLED'));
        expect(result.error, contains('Cloud sync is disabled'));
        verify(mockConnectivityService.hasInternetAccess()).called(1);
        verify(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .called(1);
        verifyNever(mockPersonalityLearning.initializePersonality(any));
      });

      test('should continue even if personality sync fails', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).thenThrow(Exception('Sync failed'));

        // Act
        final result = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(result.success, isTrue); // Still succeeds, but notes the failure
        expect(result.syncedItems['personality'], contains('failed'));
        verify(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).called(1);
      });

      test('should handle sync scope correctly', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).thenAnswer((_) async => true);

        // Act - Test with SyncScope.all
        final resultAll = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.all,
        );

        // Assert
        expect(resultAll.success, isTrue);
        expect(resultAll.syncedItems['personality'], equals('synced'));

        // Act - Test with SyncScope.personality
        final resultPersonality = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(resultPersonality.success, isTrue);
        expect(resultPersonality.syncedItems['personality'], equals('synced'));
      });

      test('should return failure on unexpected error', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenThrow(Exception('Connectivity service failed'));

        // Act
        final result = await controller.syncUserData(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('SYNC_FAILED'));
        expect(result.error, contains('Sync failed'));
      });
    });

    group('loadFromCloud', () {
      test('should successfully load personality profile from cloud', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.loadFromCloud(
          'user_123',
          'password123',
        )).thenAnswer((_) async => testPersonalityProfile);

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.personalityProfile, equals(testPersonalityProfile));
        expect(
            result.syncedItems['personality'], equals(testPersonalityProfile));
        verify(mockConnectivityService.hasInternetAccess()).called(1);
        verify(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .called(1);
        verify(mockPersonalitySyncService.loadFromCloud(
          'user_123',
          'password123',
        )).called(1);
      });

      test('should return failure when no connectivity', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('NO_CONNECTIVITY'));
        verify(mockConnectivityService.hasInternetAccess()).called(1);
        verifyNever(mockPersonalitySyncService.loadFromCloud(any, any));
      });

      test('should return failure when sync is disabled', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('SYNC_DISABLED'));
        verifyNever(mockPersonalitySyncService.loadFromCloud(any, any));
      });

      test('should handle null profile from cloud', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.loadFromCloud(
          'user_123',
          'password123',
        )).thenAnswer((_) async => null);

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.personalityProfile, isNull);
        expect(result.syncedItems['personality'], equals('not_found'));
      });

      test('should continue even if load fails', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.loadFromCloud(
          'user_123',
          'password123',
        )).thenThrow(Exception('Load failed'));

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.personality,
        );

        // Assert
        expect(result.success, isTrue); // Still succeeds, but notes the failure
        expect(result.syncedItems['personality'], contains('failed'));
      });

      test('should return failure on unexpected error', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenThrow(Exception('Connectivity service failed'));

        // Act
        final result = await controller.loadFromCloud(
          userId: 'user_123',
          password: 'password123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('LOAD_FAILED'));
        expect(result.error, contains('Load failed'));
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        when(mockConnectivityService.hasInternetAccess())
            .thenAnswer((_) async => true);
        when(mockPersonalitySyncService.isCloudSyncEnabled('user_123'))
            .thenAnswer((_) async => true);
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPersonalitySyncService.syncToCloud(
          'user_123',
          testPersonalityProfile,
          'password123',
        )).thenAnswer((_) async => true);

        const input = SyncInput(
          userId: 'user_123',
          password: 'password123',
          scope: SyncScope.all,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedItems['personality'], equals('synced'));
      });
    });

    group('rollback (WorkflowController interface)', () {
      test('should handle rollback gracefully (sync operations are idempotent)',
          () async {
        // Arrange
        const result = SyncResult.success(
          syncedItems: {'personality': 'synced'},
        );

        // Act & Assert - should not throw
        await controller.rollback(result);
      });
    });
  });
}
