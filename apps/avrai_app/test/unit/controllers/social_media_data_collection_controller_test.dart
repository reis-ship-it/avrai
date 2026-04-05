import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/social_media_data_collection_controller.dart';
import 'package:avrai_core/models/social_media/social_media_connection.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'social_media_data_collection_controller_test.mocks.dart';

@GenerateMocks([
  SocialMediaConnectionService,
])
void main() {
  group('SocialMediaDataCollectionController', () {
    late SocialMediaDataCollectionController controller;
    late MockSocialMediaConnectionService mockSocialMediaService;

    setUp(() {
      mockSocialMediaService = MockSocialMediaConnectionService();

      controller = SocialMediaDataCollectionController(
        socialMediaService: mockSocialMediaService,
      );
    });

    group('validate', () {
      test('should return valid result for non-empty userId', () {
        // Act
        final result = controller.validate('user-123');

        // Assert
        expect(result.isValid, isTrue);
        expect(result.fieldErrors, isEmpty);
        expect(result.generalErrors, isEmpty);
      });

      test('should return invalid result for empty userId', () {
        // Act
        final result = controller.validate('');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors, contains('User ID cannot be empty'));
      });

      test('should return invalid result for whitespace-only userId', () {
        // Act
        final result = controller.validate('   ');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors, contains('User ID cannot be empty'));
      });
    });

    group('collectAllData', () {
      const String userId = 'test_user_id';
      const String agentId = 'agent_test_id';

      test('should successfully collect data from multiple platforms',
          () async {
        // Arrange
        final googleConnection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final instagramConnection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.getActiveConnections(userId))
            .thenAnswer((_) async => [googleConnection, instagramConnection]);

        when(mockSocialMediaService.fetchProfileData(googleConnection))
            .thenAnswer((_) async => {
                  'profile': {
                    'id': 'google-id',
                    'name': 'Test User',
                    'email': 'test@gmail.com',
                  },
                });

        when(mockSocialMediaService.fetchProfileData(instagramConnection))
            .thenAnswer((_) async => {
                  'profile': {
                    'id': 'instagram-id',
                    'username': 'test_user',
                  },
                });

        when(mockSocialMediaService.fetchGooglePlacesData(googleConnection))
            .thenAnswer((_) async => {
                  'places': [
                    {'name': 'Place 1', 'address': 'Address 1'},
                  ],
                  'reviews': [],
                  'photos': [],
                });

        when(mockSocialMediaService.fetchFollows(googleConnection))
            .thenAnswer((_) async => []);

        when(mockSocialMediaService.fetchFollows(instagramConnection))
            .thenAnswer((_) async => [
                  {'id': 'follow-1', 'username': 'friend1'},
                  {'id': 'follow-2', 'username': 'friend2'},
                ]);

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.profileData, isNotNull);
        expect(result.profileData!.length, equals(2));
        expect(result.profileData!['google'], isNotNull);
        expect(result.profileData!['instagram'], isNotNull);
        expect(result.follows, isNotNull);
        expect(result.follows!.length, equals(2));
        expect(result.primaryPlatform, isNotNull);
        verify(mockSocialMediaService.getActiveConnections(userId)).called(1);
        verify(mockSocialMediaService.fetchProfileData(googleConnection))
            .called(1);
        verify(mockSocialMediaService.fetchProfileData(instagramConnection))
            .called(1);
        verify(mockSocialMediaService.fetchGooglePlacesData(googleConnection))
            .called(1);
      });

      test('should return success with empty data when no connections exist',
          () async {
        // Arrange
        when(mockSocialMediaService.getActiveConnections(userId))
            .thenAnswer((_) async => []);

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.profileData, isEmpty);
        expect(result.follows, isEmpty);
        expect(result.primaryPlatform, isNull);
      });

      test('should continue on failure per platform', () async {
        // Arrange
        final googleConnection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final instagramConnection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.getActiveConnections(userId))
            .thenAnswer((_) async => [googleConnection, instagramConnection]);

        // Google succeeds
        when(mockSocialMediaService.fetchProfileData(googleConnection))
            .thenAnswer((_) async => {
                  'profile': {'id': 'google-id', 'name': 'Test User'},
                });

        when(mockSocialMediaService.fetchGooglePlacesData(googleConnection))
            .thenAnswer(
                (_) async => {'places': [], 'reviews': [], 'photos': []});

        when(mockSocialMediaService.fetchFollows(googleConnection))
            .thenAnswer((_) async => []);

        // Instagram fails
        when(mockSocialMediaService.fetchProfileData(instagramConnection))
            .thenThrow(Exception('API error'));

        when(mockSocialMediaService.fetchFollows(instagramConnection))
            .thenAnswer((_) async => []);

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess,
            isTrue); // Should succeed even if one platform fails
        expect(result.profileData, isNotNull);
        expect(result.profileData!.length, equals(1)); // Only Google data
        expect(result.profileData!.containsKey('google'), isTrue);
        expect(result.profileData!.containsKey('instagram'), isFalse);
        expect(result.platformErrors, isNotNull);
        expect(result.platformErrors!.containsKey('instagram'), isTrue);
      });

      test('should return failure when all platforms fail', () async {
        // Arrange
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.getActiveConnections(userId))
            .thenAnswer((_) async => [connection]);

        when(mockSocialMediaService.fetchProfileData(connection))
            .thenThrow(Exception('API error'));

        when(mockSocialMediaService.fetchFollows(connection))
            .thenAnswer((_) async => []);

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('ALL_PLATFORMS_FAILED'));
        expect(result.error, contains('All platforms failed'));
        expect(result.platformErrors, isNotNull);
      });

      test('should return failure when getActiveConnections fails', () async {
        // Arrange
        when(mockSocialMediaService.getActiveConnections(userId))
            .thenThrow(Exception('Connection service error'));

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('CONNECTION_ERROR'));
        expect(result.error, contains('Failed to get active connections'));
      });

      test('should merge Google Places data into profile', () async {
        // Arrange
        final googleConnection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.getActiveConnections(userId))
            .thenAnswer((_) async => [googleConnection]);

        when(mockSocialMediaService.fetchProfileData(googleConnection))
            .thenAnswer((_) async => {
                  'profile': {'id': 'google-id', 'name': 'Test User'},
                });

        when(mockSocialMediaService.fetchGooglePlacesData(googleConnection))
            .thenAnswer((_) async => {
                  'places': [
                    {'name': 'Coffee Shop', 'address': '123 Main St'},
                  ],
                  'reviews': [
                    {'place': 'Restaurant', 'rating': 5},
                  ],
                  'photos': [
                    {'url': 'photo1.jpg'},
                  ],
                });

        when(mockSocialMediaService.fetchFollows(googleConnection))
            .thenAnswer((_) async => []);

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.profileData, isNotNull);
        final googleProfile =
            result.profileData!['google'] as Map<String, dynamic>;
        expect(googleProfile['savedPlaces'], isNotNull);
        expect(googleProfile['reviews'], isNotNull);
        expect(googleProfile['photos'], isNotNull);
        expect((googleProfile['savedPlaces'] as List).length, equals(1));
      });
    });

    group('fetchPlatformProfile', () {
      test('should fetch profile data from service', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final expectedProfile = {
          'profile': {
            'id': 'insta-id',
            'username': 'test_user',
          },
        };

        when(mockSocialMediaService.fetchProfileData(connection))
            .thenAnswer((_) async => expectedProfile);

        // Act
        final result = await controller.fetchPlatformProfile(connection);

        // Assert
        expect(result, equals(expectedProfile));
        verify(mockSocialMediaService.fetchProfileData(connection)).called(1);
      });

      test('should rethrow errors from service', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.fetchProfileData(connection))
            .thenThrow(Exception('API error'));

        // Act & Assert
        expect(
          () => controller.fetchPlatformProfile(connection),
          throwsException,
        );
      });
    });

    group('fetchPlatformFollows', () {
      test('should fetch follows from service', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final expectedFollows = [
          {'id': 'follow-1', 'username': 'friend1'},
          {'id': 'follow-2', 'username': 'friend2'},
        ];

        when(mockSocialMediaService.fetchFollows(connection))
            .thenAnswer((_) async => expectedFollows);

        // Act
        final result = await controller.fetchPlatformFollows(connection);

        // Assert
        expect(result, equals(expectedFollows));
        verify(mockSocialMediaService.fetchFollows(connection)).called(1);
      });

      test('should rethrow errors from service', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.fetchFollows(connection))
            .thenThrow(Exception('API error'));

        // Act & Assert
        expect(
          () => controller.fetchPlatformFollows(connection),
          throwsException,
        );
      });
    });

    group('fetchPlatformSpecificData', () {
      test('should fetch Google Places data for Google platform', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final expectedData = {
          'places': [
            {'name': 'Place 1'}
          ],
          'reviews': [],
          'photos': [],
        };

        when(mockSocialMediaService.fetchGooglePlacesData(connection))
            .thenAnswer((_) async => expectedData);

        // Act
        final result = await controller.fetchPlatformSpecificData(connection);

        // Assert
        expect(result, equals(expectedData));
        verify(mockSocialMediaService.fetchGooglePlacesData(connection))
            .called(1);
      });

      test('should return empty map for non-Google platforms', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'instagram',
          platformUsername: 'test_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final result = await controller.fetchPlatformSpecificData(connection);

        // Assert
        expect(result, isEmpty);
        verifyNever(mockSocialMediaService.fetchGooglePlacesData(any));
      });

      test('should return empty map on error', () async {
        // Arrange
        const agentId = 'agent-123';
        final connection = SocialMediaConnection(
          agentId: agentId,
          platform: 'google',
          platformUsername: 'test@gmail.com',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        when(mockSocialMediaService.fetchGooglePlacesData(connection))
            .thenThrow(Exception('API error'));

        // Act
        final result = await controller.fetchPlatformSpecificData(connection);

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
