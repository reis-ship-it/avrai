/// SPOTS CommunityChatService Tests
/// Date: December 2025
/// Purpose: Test CommunityChatService functionality
///
/// Test Coverage:
/// - Initialization: Service setup
/// - Send Group Message: Encrypted group message sending
/// - Group Chat History: Message retrieval
/// - User Communities Chat List: Chat previews
/// - Member Management: Add/remove members (placeholders)
/// - Decryption: Message decryption for display
/// - Membership Verification: Only members can send messages
/// - Error Handling: Invalid inputs, encryption errors
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/community/community_chat_service.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';

import '../../helpers/test_helpers.dart';

// Mock classes
class MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
  });

  group('CommunityChatService Tests', () {
    late CommunityChatService service;
    late MockMessageEncryptionService mockEncryptionService;

    const String testUserId = 'user_123';
    const String testCommunityId = 'community_456';
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    const String testChatId = 'community_chat_$testCommunityId';

    late Community testCommunity;

    setUp(() async {
      TestHelpers.setupTestEnvironment();

      // Initialize mocks
      mockEncryptionService = MockMessageEncryptionService();

      // Setup default mock behaviors
      when(() => mockEncryptionService.encryptionType)
          .thenReturn(EncryptionType.aes256gcm);

      when(() => mockEncryptionService.encrypt(any(), any()))
          .thenAnswer((invocation) async {
        final plaintext = invocation.positionalArguments[0] as String;
        return EncryptedMessage(
          encryptedContent: Uint8List.fromList(plaintext.codeUnits),
          encryptionType: EncryptionType.aes256gcm,
        );
      });

      when(() => mockEncryptionService.decrypt(any(), any()))
          .thenAnswer((invocation) async {
        final encrypted = invocation.positionalArguments[0] as EncryptedMessage;
        return String.fromCharCodes(encrypted.encryptedContent);
      });

      // Create test community
      testCommunity = Community(
        id: testCommunityId,
        name: 'Test Community',
        category: 'Social',
        originatingEventId: 'event_123',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: 'founder_123',
        memberIds: const [testUserId, 'member_2', 'member_3'],
        memberCount: 3,
        originalLocality: 'San Francisco, CA',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create service with mocks
      service = CommunityChatService(
        encryptionService: mockEncryptionService,
      );
    });

    tearDown(() async {
      TestHelpers.teardownTestEnvironment();
    });

    group('Initialization', () {
      test('should initialize with encryption service', () {
        expect(service, isNotNull);
      });
    });

    group('Send Group Message', () {
      test('should send encrypted group message', () async {
        // Arrange
        const message = 'Hello community!';

        // Act
        final chatMessage = await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          message,
          community: testCommunity,
        );

        // Assert
        expect(chatMessage, isNotNull);
        expect(chatMessage.senderId, equals(testUserId));
        expect(chatMessage.communityId, equals(testCommunityId));

        // Verify encryption was called with group identifier
        verify(() => mockEncryptionService.encrypt(
              message,
              'group_$testCommunityId',
            )).called(1);
      });

      test('should reject message from non-member', () async {
        // Arrange
        final nonMemberCommunity = Community(
          id: testCommunityId,
          name: 'Test Community',
          category: 'Social',
          originatingEventId: 'event_123',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'founder_123',
          memberIds: const ['member_1', 'member_2'], // testUserId not in list
          memberCount: 2,
          originalLocality: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => service.sendGroupMessage(
            testUserId,
            testCommunityId,
            'Test message',
            community: nonMemberCommunity,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should create unique message IDs', () async {
        // Arrange
        const message = 'Test message';

        // Act
        final message1 = await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          message,
          community: testCommunity,
        );
        final message2 = await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          message,
          community: testCommunity,
        );

        // Assert
        expect(message1.messageId, isNot(equals(message2.messageId)));
      });
    });

    group('Group Chat History', () {
      test('should retrieve group chat history', () async {
        // Arrange
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          'First message',
          community: testCommunity,
        );
        await service.sendGroupMessage(
          'member_2',
          testCommunityId,
          'Second message',
          community: testCommunity,
        );

        // Act
        final history = await service.getGroupChatHistory(testCommunityId);

        // Assert
        expect(history.length, equals(2));
        expect(history.first.senderId, equals('member_2')); // Most recent first
      });

      test('should return empty list for non-existent chat', () async {
        // Act
        final history =
            await service.getGroupChatHistory('nonexistent_community');

        // Assert
        expect(history, isEmpty);
      });

      test('should return messages in reverse chronological order', () async {
        // Arrange
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          'First',
          community: testCommunity,
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          'Second',
          community: testCommunity,
        );

        // Act
        final history = await service.getGroupChatHistory(testCommunityId);

        // Assert
        expect(history.length, equals(2));
        expect(history[0].timestamp.isAfter(history[1].timestamp), isTrue);
      });
    });

    group('User Communities Chat List', () {
      test('should get chat list with previews', () async {
        // Arrange
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          'Hello community!',
          community: testCommunity,
        );
        final communities = [testCommunity];

        // Act
        final chatList = await service.getUserCommunitiesChatList(
          testUserId,
          communities,
        );

        // Assert
        expect(chatList.length, equals(1));
        expect(chatList.first.communityId, equals(testCommunityId));
        expect(chatList.first.communityName, equals('Test Community'));
        expect(chatList.first.lastMessagePreview, isNotNull);
      });

      test('should include communities with no messages', () async {
        // Arrange
        final emptyCommunity = Community(
          id: 'empty_community',
          name: 'Empty Community',
          category: 'Social',
          originatingEventId: 'event_123',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'founder_123',
          memberIds: const [testUserId],
          memberCount: 1,
          originalLocality: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final communities = [emptyCommunity];

        // Act
        final chatList = await service.getUserCommunitiesChatList(
          testUserId,
          communities,
        );

        // Assert
        expect(chatList.length, equals(1));
        expect(chatList.first.lastMessagePreview, isNull);
      });

      test('should sort by most recent message', () async {
        // Arrange
        final community1 = Community(
          id: 'community_1',
          name: 'Community 1',
          category: 'Social',
          originatingEventId: 'event_1',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'founder_1',
          memberIds: const [testUserId],
          memberCount: 1,
          originalLocality: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final community2 = Community(
          id: 'community_2',
          name: 'Community 2',
          category: 'Social',
          originatingEventId: 'event_2',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'founder_2',
          memberIds: const [testUserId],
          memberCount: 1,
          originalLocality: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.sendGroupMessage(
          testUserId,
          'community_1',
          'Old message',
          community: community1,
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await service.sendGroupMessage(
          testUserId,
          'community_2',
          'Recent message',
          community: community2,
        );

        // Act
        final chatList = await service.getUserCommunitiesChatList(
          testUserId,
          [community1, community2],
        );

        // Assert
        expect(chatList.length, equals(2));
        expect(chatList.first.communityId,
            equals('community_2')); // Most recent first
      });
    });

    group('Member Management', () {
      test('should add member to chat', () async {
        // Test business logic: member management operations complete without error
        // Note: In Option A, all members have access via shared key
        // The method completes successfully and logs the operation

        // Act - should not throw
        await service.addMemberToChat(testCommunityId, 'new_member');

        // Assert - Operation completed without throwing (test passes if we reach here)
        // In Option A implementation, members automatically have access via shared key
      });

      test('should remove member from chat', () async {
        // Test business logic: member removal operations complete without error
        // Note: In Option A, removed members still have access via shared key
        // The method completes successfully and logs the operation

        // Act - should not throw
        await service.removeMemberFromChat(testCommunityId, testUserId);

        // Assert - Operation completed without throwing (test passes if we reach here)
        // In Option A implementation, members retain access via shared key
      });
    });

    group('Decryption', () {
      test('should decrypt messages for display', () async {
        // Arrange
        const originalMessage = 'Secret group message';
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          originalMessage,
          community: testCommunity,
        );
        final history = await service.getGroupChatHistory(testCommunityId);

        // Act
        final decrypted = await service.getDecryptedMessage(
          history.first,
          testCommunityId,
        );

        // Assert
        expect(decrypted, equals(originalMessage));
        verify(() => mockEncryptionService.decrypt(any(), any())).called(1);
      });

      test('should handle decryption errors gracefully', () async {
        // Arrange
        await service.sendGroupMessage(
          testUserId,
          testCommunityId,
          'Test',
          community: testCommunity,
        );
        final history = await service.getGroupChatHistory(testCommunityId);

        when(() => mockEncryptionService.decrypt(any(), any()))
            .thenThrow(Exception('Decryption failed'));

        // Act
        final decrypted = await service.getDecryptedMessage(
          history.first,
          testCommunityId,
        );

        // Assert
        expect(decrypted, contains('decryption failed'));
      });
    });

    group('Error Handling', () {
      test('should handle encryption errors gracefully', () async {
        // Arrange
        when(() => mockEncryptionService.encrypt(any(), any()))
            .thenThrow(Exception('Encryption failed'));

        // Act & Assert
        expect(
          () => service.sendGroupMessage(
            testUserId,
            testCommunityId,
            'Test',
            community: testCommunity,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
