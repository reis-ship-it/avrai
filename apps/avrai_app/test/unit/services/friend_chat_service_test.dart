/// SPOTS FriendChatService Tests
/// Date: December 2025
/// Purpose: Test FriendChatService functionality
///
/// Test Coverage:
/// - Initialization: Service setup
/// - Send Message: Encrypted message sending
/// - Conversation History: Message retrieval
/// - Friends Chat List: Chat previews with unread counts
/// - Mark as Read: Read status management
/// - Decryption: Message decryption for display
/// - Unread Count: Total unread message counting
/// - Error Handling: Invalid inputs, encryption errors
library;

import 'dart:io';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';

import '../../helpers/test_helpers.dart';

// Mock classes
class MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class _FixedHumanLanguageBoundaryReviewLane
    extends HumanLanguageBoundaryReviewLane {
  _FixedHumanLanguageBoundaryReviewLane(this._decision);

  final BoundaryDecision _decision;

  @override
  Future<HumanLanguageBoundaryReview> reviewOutboundText({
    required String actorAgentId,
    required String rawText,
    required BoundaryEgressPurpose egressPurpose,
    required bool egressRequested,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    Set<String>? consentScopes,
  }) async {
    return _buildBoundaryReview(
      rawText: rawText,
      decision: _decision,
      egressRequested: egressRequested,
      egressPurpose: egressPurpose,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
  }

  @override
  Future<HumanLanguageBoundaryReview> reviewLocalLearningText({
    required String actorAgentId,
    required String rawText,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.userRuntime,
    Set<String>? consentScopes,
  }) async {
    return _buildBoundaryReview(
      rawText: rawText,
      decision: _decision,
      egressRequested: false,
      egressPurpose: BoundaryEgressPurpose.none,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
  }
}

HumanLanguageBoundaryReview _buildBoundaryReview({
  required String rawText,
  required BoundaryDecision decision,
  bool egressRequested = false,
  BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.directMessage,
  String chatType = 'friend',
  String surface = 'chat',
  String channel = 'friend_chat',
}) {
  return HumanLanguageBoundaryReview(
    rawText: rawText,
    turn: HumanLanguageKernelTurn(
      interpretation: InterpretationResult(
        intent: InterpretationIntent.share,
        normalizedText: rawText,
        requestArtifact: InterpretationRequestArtifact(
          summary: rawText,
          asksForResponse: false,
          asksForRecommendation: false,
          asksForAction: false,
          asksForExplanation: false,
          referencedEntities: <String>[],
          questions: <String>[],
          preferenceSignals: <InterpretationPreferenceSignal>[],
          shareIntent: true,
        ),
        learningArtifact: const InterpretationLearningArtifact(
          vocabulary: <String>[],
          phrases: <String>[],
          toneMetrics: <String, double>{},
          directnessPreference: 0.5,
          brevityPreference: 0.5,
        ),
        privacySensitivity: InterpretationPrivacySensitivity.low,
        confidence: 0.9,
        ambiguityFlags: <String>[],
        needsClarification: false,
        safeForLearning: false,
      ),
      boundary: decision,
    ),
    egressRequested: egressRequested,
    egressPurpose: egressPurpose,
    chatType: chatType,
    surface: surface,
    channel: channel,
  );
}

void main() {
  late Directory storageRoot;
  late GetStorage friendChatMessagesStorage;
  late GetStorage friendChatOutboxStorage;

  // Register fallback values for mocktail
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    registerFallbackValue(
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
  });

  setUpAll(() async {
    storageRoot = await Directory.systemTemp.createTemp('friend_chat_test_');
    friendChatMessagesStorage = GetStorage(
      'friend_chat_messages',
      storageRoot.path,
    );
    friendChatOutboxStorage = GetStorage(
      'friend_chat_outbox',
      storageRoot.path,
    );
    await friendChatMessagesStorage.initStorage;
    await friendChatOutboxStorage.initStorage;
  });

  group('FriendChatService Tests', () {
    late FriendChatService service;
    late MockMessageEncryptionService mockEncryptionService;

    const String testUserId = 'user_123';
    const String testFriendId = 'friend_456';
    final sortedIds = [testUserId, testFriendId]..sort();
    final String testChatId = 'friend_chat_${sortedIds.join('_')}';
    const allowedBoundaryDecision = BoundaryDecision(
      accepted: true,
      disposition: BoundaryDisposition.userAuthorizedEgress,
      transcriptStorageAllowed: true,
      storageAllowed: true,
      learningAllowed: true,
      egressAllowed: true,
      airGapRequired: false,
      reasonCodes: <String>[],
      sanitizedArtifact: BoundarySanitizedArtifact(
        pseudonymousActorRef: 'anon_test',
        summary: 'allowed',
        safeClaims: <String>[],
        safeQuestions: <String>[],
        safePreferenceSignals: <InterpretationPreferenceSignal>[],
        learningVocabulary: <String>[],
        learningPhrases: <String>[],
        redactedText: '',
      ),
      egressPurpose: BoundaryEgressPurpose.directMessage,
    );

    setUp(() async {
      TestHelpers.setupTestEnvironment();
      await friendChatMessagesStorage.erase();
      await friendChatOutboxStorage.erase();
      await Future<void>.delayed(const Duration(milliseconds: 100));

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

      // Create service with mocks
      service = FriendChatService(
        encryptionService: mockEncryptionService,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );
    });

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (storageRoot.existsSync()) {
        for (var attempt = 0; attempt < 5; attempt++) {
          try {
            await storageRoot.delete(recursive: true);
            break;
          } on FileSystemException {
            if (attempt == 4) rethrow;
            await Future<void>.delayed(
              Duration(milliseconds: 100 * (attempt + 1)),
            );
          }
        }
      }
    });

    tearDown(() async {
      await friendChatMessagesStorage.erase();
      await friendChatOutboxStorage.erase();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      TestHelpers.teardownTestEnvironment();
    });

    group('Initialization', () {
      test('should initialize with encryption service', () {
        expect(service, isNotNull);
      });
    });

    group('Send Message', () {
      test('should send encrypted message to friend', () async {
        // Arrange
        const message = 'Hello friend!';

        // Act
        final chatMessage =
            await service.sendMessage(testUserId, testFriendId, message);

        // Assert
        expect(chatMessage, isNotNull);
        expect(chatMessage.senderId, equals(testUserId));
        expect(chatMessage.recipientId, equals(testFriendId));
        expect(chatMessage.isRead, isFalse);
        expect(chatMessage.metadata, isNotNull);
        expect(
          chatMessage.metadata![HumanLanguageBoundaryReview.metadataKey],
          isA<Map<String, dynamic>>(),
        );
        expect(
          chatMessage.metadata![HumanLanguageBoundaryReview.metadataKey]
              ['egress_purpose'],
          BoundaryEgressPurpose.directMessage.toWireValue(),
        );
        expect(
          chatMessage.metadata![HumanLanguageBoundaryReview.metadataKey]
              ['egress_requested'],
          isFalse,
        );

        // Verify encryption was called
        verify(() => mockEncryptionService.encrypt(message, testChatId))
            .called(1);
      });

      test('should fail closed when transcript storage is denied', () async {
        service = FriendChatService(
          encryptionService: mockEncryptionService,
          humanLanguageBoundaryReviewLane:
              _FixedHumanLanguageBoundaryReviewLane(
            const BoundaryDecision(
              accepted: false,
              disposition: BoundaryDisposition.block,
              transcriptStorageAllowed: false,
              storageAllowed: false,
              learningAllowed: false,
              egressAllowed: false,
              airGapRequired: false,
              reasonCodes: <String>['policy_blocked'],
              sanitizedArtifact: BoundarySanitizedArtifact(
                pseudonymousActorRef: 'anon_test',
                summary: 'blocked',
                safeClaims: <String>[],
                safeQuestions: <String>[],
                safePreferenceSignals: <InterpretationPreferenceSignal>[],
                learningVocabulary: <String>[],
                learningPhrases: <String>[],
                redactedText: 'blocked',
              ),
              egressPurpose: BoundaryEgressPurpose.directMessage,
            ),
          ),
        );

        await expectLater(
          () => service.sendMessage(testUserId, testFriendId, 'Blocked'),
          throwsA(isA<HumanLanguageBoundaryViolationException>()),
        );
        verifyNever(() => mockEncryptionService.encrypt(any(), any()));
      });

      test('should generate consistent chat ID regardless of user order',
          () async {
        // Arrange
        const message = 'Test message';

        // Act - send from user to friend
        final message1 =
            await service.sendMessage(testUserId, testFriendId, message);

        // Act - send from friend to user (reverse order)
        final message2 =
            await service.sendMessage(testFriendId, testUserId, message);

        // Assert - both should have same chatId
        expect(message1.chatId, equals(message2.chatId));
      });

      test('should create unique message IDs', () async {
        // Arrange
        const message = 'Test message';

        // Act
        final message1 =
            await service.sendMessage(testUserId, testFriendId, message);
        final message2 =
            await service.sendMessage(testUserId, testFriendId, message);

        // Assert
        expect(message1.messageId, isNot(equals(message2.messageId)));
      });

      test('should return kernel context when direct message uses OS host',
          () async {
        const message = 'OS-backed DM';
        service = FriendChatService(
          encryptionService: mockEncryptionService,
          headlessOsHost: _FakeFriendChatHeadlessHost(),
          humanLanguageBoundaryReviewLane:
              _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
        );

        final result = await service.sendMessageOverNetworkWithKernelContext(
          testUserId,
          testFriendId,
          message,
        );

        expect(result.message.senderId, testUserId);
        expect(result.modelTruthReady, isTrue);
        expect(result.localityContainedInWhere, isTrue);
        expect(result.kernelEventId, contains('friend_chat:'));
        expect(result.governanceSummary, isNotNull);
      });
    });

    group('Conversation History', () {
      test('should retrieve conversation history', () async {
        // Arrange
        await service.sendMessage(testUserId, testFriendId, 'First message');
        await service.sendMessage(testFriendId, testUserId, 'Second message');
        await service.sendMessage(testUserId, testFriendId, 'Third message');

        // Act
        final history =
            await service.getConversationHistory(testUserId, testFriendId);

        // Assert
        expect(history.length, equals(3));
        expect(history.first.senderId, equals(testUserId)); // Most recent first
      });

      test('should return empty list for non-existent conversation', () async {
        // Act
        final history = await service.getConversationHistory(
            testUserId, 'nonexistent_friend');

        // Assert
        expect(history, isEmpty);
      });

      test('should return messages in reverse chronological order', () async {
        // Arrange
        await service.sendMessage(testUserId, testFriendId, 'First');
        await Future.delayed(const Duration(milliseconds: 10));
        await service.sendMessage(testUserId, testFriendId, 'Second');
        await Future.delayed(const Duration(milliseconds: 10));
        await service.sendMessage(testUserId, testFriendId, 'Third');

        // Act
        final history =
            await service.getConversationHistory(testUserId, testFriendId);

        // Assert
        expect(history.length, equals(3));
        expect(history[0].timestamp.isAfter(history[1].timestamp), isTrue);
        expect(history[1].timestamp.isAfter(history[2].timestamp), isTrue);
      });
    });

    group('Friends Chat List', () {
      test('should get chat list with previews', () async {
        // Arrange
        await service.sendMessage(testUserId, testFriendId, 'Hello there!');
        final friendIds = [testFriendId];
        final friendNames = {testFriendId: 'Test Friend'};

        // Act
        final chatList = await service.getFriendsChatList(
          testUserId,
          friendIds,
          friendNames: friendNames,
        );

        // Assert
        expect(chatList.length, equals(1));
        expect(chatList.first.friendId, equals(testFriendId));
        expect(chatList.first.friendName, equals('Test Friend'));
        expect(chatList.first.lastMessagePreview, isNotNull);
      });

      test('should skip friends with no conversation', () async {
        // Arrange
        final friendIds = [testFriendId, 'friend_with_no_chat'];

        // Act
        final chatList =
            await service.getFriendsChatList(testUserId, friendIds);

        // Assert
        expect(chatList.length, equals(0)); // No conversations yet
      });

      test('should include unread count in preview', () async {
        // Arrange
        await service.sendMessage(testFriendId, testUserId, 'Unread message 1');
        await service.sendMessage(testFriendId, testUserId, 'Unread message 2');
        final friendIds = [testFriendId];

        // Act
        final chatList =
            await service.getFriendsChatList(testUserId, friendIds);

        // Assert
        expect(chatList.length, equals(1));
        expect(chatList.first.unreadCount, equals(2));
      });

      test('should sort by most recent message', () async {
        // Arrange
        const friend1 = 'friend_1';
        const friend2 = 'friend_2';

        await service.sendMessage(friend1, testUserId, 'Old message');
        await Future.delayed(const Duration(milliseconds: 10));
        await service.sendMessage(friend2, testUserId, 'Recent message');

        final friendIds = [friend1, friend2];

        // Act
        final chatList =
            await service.getFriendsChatList(testUserId, friendIds);

        // Assert
        expect(chatList.length, equals(2));
        expect(chatList.first.friendId, equals(friend2)); // Most recent first
      });
    });

    group('Mark as Read', () {
      test('should mark messages as read', () async {
        // Arrange
        await service.sendMessage(testFriendId, testUserId, 'Message 1');
        await service.sendMessage(testFriendId, testUserId, 'Message 2');

        // Act
        final markedCount = await service.markAsRead(testUserId, testFriendId);

        // Assert
        expect(markedCount, equals(2));

        // Verify messages are marked as read
        final history =
            await service.getConversationHistory(testUserId, testFriendId);
        final unreadMessages = history
            .where((msg) => !msg.isRead && msg.recipientId == testUserId);
        expect(unreadMessages, isEmpty);
      });

      test('should only mark messages from specific friend', () async {
        // Arrange
        const otherFriend = 'other_friend';
        await service.sendMessage(
            testFriendId, testUserId, 'Message from friend');
        await service.sendMessage(
            otherFriend, testUserId, 'Message from other');

        // Act
        await service.markAsRead(testUserId, testFriendId);

        // Assert
        final history1 =
            await service.getConversationHistory(testUserId, testFriendId);
        final history2 =
            await service.getConversationHistory(testUserId, otherFriend);

        expect(history1.first.isRead, isTrue);
        expect(history2.first.isRead,
            isFalse); // Other friend's message still unread
      });

      test('should return zero if no unread messages', () async {
        // Arrange
        await service.sendMessage(testFriendId, testUserId, 'Message');
        await service.markAsRead(testUserId, testFriendId);

        // Act
        final markedCount = await service.markAsRead(testUserId, testFriendId);

        // Assert
        expect(markedCount, equals(0));
      });
    });

    group('Decryption', () {
      test('should decrypt messages for display', () async {
        // Arrange
        const originalMessage = 'Secret message';
        await service.sendMessage(testUserId, testFriendId, originalMessage);
        final history =
            await service.getConversationHistory(testUserId, testFriendId);

        // Act
        final decrypted = await service.getDecryptedMessage(
          history.first,
          testUserId,
          testFriendId,
        );

        // Assert
        expect(decrypted, equals(originalMessage));
        verify(() => mockEncryptionService.decrypt(any(), any())).called(1);
      });

      test('should handle decryption errors gracefully', () async {
        // Arrange
        await service.sendMessage(testUserId, testFriendId, 'Test');
        final history =
            await service.getConversationHistory(testUserId, testFriendId);

        when(() => mockEncryptionService.decrypt(any(), any()))
            .thenThrow(Exception('Decryption failed'));

        // Act
        final decrypted = await service.getDecryptedMessage(
          history.first,
          testUserId,
          testFriendId,
        );

        // Assert
        expect(decrypted, contains('decryption failed'));
      });
    });

    group('Unread Count', () {
      test('should calculate total unread count across all friends', () async {
        // Arrange
        const friend1 = 'friend_1';
        const friend2 = 'friend_2';

        await service.sendMessage(friend1, testUserId, 'Unread 1');
        await service.sendMessage(friend1, testUserId, 'Unread 2');
        await service.sendMessage(friend2, testUserId, 'Unread 3');

        final friendIds = [friend1, friend2];

        // Act
        final totalUnread =
            await service.getTotalUnreadCount(testUserId, friendIds);

        // Assert
        expect(totalUnread, equals(3));
      });

      test('should return zero if no unread messages', () async {
        // Arrange
        await service.sendMessage(testFriendId, testUserId, 'Message');
        await service.markAsRead(testUserId, testFriendId);

        // Act
        final totalUnread =
            await service.getTotalUnreadCount(testUserId, [testFriendId]);

        // Assert
        expect(totalUnread, equals(0));
      });
    });

    group('Error Handling', () {
      test('should handle encryption errors gracefully', () async {
        // Arrange
        when(() => mockEncryptionService.encrypt(any(), any()))
            .thenThrow(Exception('Encryption failed'));

        // Act & Assert
        expect(
          () => service.sendMessage(testUserId, testFriendId, 'Test'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

class _FakeFriendChatHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'friend chat host ready',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      who: const WhoRealityProjection(summary: 'who', confidence: 0.8),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.8),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.9),
      where: const WhereRealityProjection(summary: 'where', confidence: 0.9),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.8),
      how: const HowRealityProjection(summary: 'how', confidence: 0.8),
      generatedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
    );
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async {
    return const <KernelHealthReport>[];
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.why,
          summary: 'direct message remained governed',
          confidence: 0.8,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7),
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    return const KernelContextBundle(
      who: null,
      what: null,
      when: null,
      where: null,
      how: null,
      why: null,
    );
  }
}
