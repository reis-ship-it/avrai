import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/config/ai2ai_retention_config.dart';
import 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/community/community_chat_service.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_sender_key_service.dart';
import 'package:avrai_runtime_os/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_planner.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/interfaces/realtime_backend.dart';
import '../../mocks/in_memory_flutter_secure_storage.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// In-memory realtime backend for unit tests.
///
/// Implements message fanout by channelId and provides a basic connection status stream.
class InMemoryRealtimeBackend implements RealtimeBackend {
  final Map<String, StreamController<RealtimeMessage>> _messageControllers = {};
  final StreamController<RealtimeConnectionStatus> _status =
      StreamController<RealtimeConnectionStatus>.broadcast();

  RealtimeConnectionStatus _currentStatus =
      RealtimeConnectionStatus.disconnected;

  StreamController<RealtimeMessage> _controllerForChannel(String channelId) {
    return _messageControllers.putIfAbsent(
      channelId,
      () => StreamController<RealtimeMessage>.broadcast(),
    );
  }

  @override
  Stream<RealtimeMessage> subscribeToMessages(String channelId) {
    return _controllerForChannel(channelId).stream;
  }

  @override
  Future<void> sendMessage(String channelId, RealtimeMessage message) async {
    _controllerForChannel(channelId).add(message);
  }

  @override
  Stream<RealtimeConnectionStatus> get connectionStatus => _status.stream;

  @override
  Future<void> connect() async {
    _currentStatus = RealtimeConnectionStatus.connected;
    _status.add(_currentStatus);
  }

  @override
  Future<void> disconnect() async {
    _currentStatus = RealtimeConnectionStatus.disconnected;
    _status.add(_currentStatus);
  }

  @override
  Future<void> joinChannel(String channelId) async {
    // No-op for in-memory backend; channels are created lazily on subscribe/send.
  }

  @override
  Future<void> leaveChannel(String channelId) async {
    // No-op for in-memory backend.
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    // No-op for in-memory backend (no explicit subscription IDs are allocated).
  }

  @override
  Future<void> unsubscribeAll() async {
    for (final c in _messageControllers.values) {
      await c.close();
    }
    _messageControllers.clear();
  }

  @override
  Future<void> trackRealtimeEvent(
      String eventName, Map<String, dynamic> data) async {
    // No-op for tests.
  }

  // Domain subscriptions are not required for chat transport contract tests.
  // Provide empty streams so the implementation remains deterministic.
  @override
  Stream<User?> subscribeToUser(String userId) => const Stream.empty();

  @override
  Stream<Spot?> subscribeToSpot(String spotId) => const Stream.empty();

  @override
  Stream<SpotList?> subscribeToSpotList(String listId) => const Stream.empty();

  @override
  Stream<List<Spot>> subscribeToSpotsInList(String listId) =>
      const Stream.empty();

  @override
  Stream<List<Spot>> subscribeToNearbySpots(
    double latitude,
    double longitude,
    double radiusKm,
  ) =>
      const Stream.empty();

  @override
  Stream<List<SpotList>> subscribeToUserLists(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Spot>> subscribeToUserRespectedSpots(String userId) =>
      const Stream.empty();

  @override
  Stream<List<T>> subscribeToCollection<T>(
    String collection,
    T Function(Map<String, dynamic> p1) fromJson, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? descending,
    int? limit,
  }) =>
      const Stream.empty();

  @override
  Stream<T?> subscribeToDocument<T>(
    String collection,
    String documentId,
    T Function(Map<String, dynamic> p1) fromJson,
  ) =>
      const Stream.empty();

  @override
  Stream<List<UserPresence>> subscribeToPresence(String channelId) =>
      const Stream.empty();

  @override
  Future<void> updatePresence(String channelId, UserPresence presence) async {}

  @override
  Future<void> removePresence(String channelId) async {}

  @override
  Stream<List<LiveCursor>> subscribeToLiveCursors(String documentId) =>
      const Stream.empty();

  @override
  Future<void> updateLiveCursor(String documentId, LiveCursor cursor) async {}
}

class FakeSignalEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(utf8.encode(plaintext)),
      encryptionType: EncryptionType.signalProtocol,
      metadata: <String, dynamic>{
        'recipient_id': recipientId,
      },
    );
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return utf8.decode(encrypted.encryptedContent);
  }
}

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
        safeForLearning: true,
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

TransportRouteReceipt? _routeReceiptFromMessage(FriendChatMessage message) {
  final raw = message.metadata?['transport_route_receipt'];
  if (raw is! Map) {
    return null;
  }
  return TransportRouteReceipt.fromJson(Map<String, dynamic>.from(raw));
}

void main() {
  late Directory storageRoot;

  setUpAll(() async {
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
    storageRoot =
        await Directory.systemTemp.createTemp('chat_transport_contract_');
    await GetStorage('friend_chat_messages', storageRoot.path).initStorage;
    await GetStorage('friend_chat_outbox', storageRoot.path).initStorage;
    await GetStorage('community_chat_messages', storageRoot.path).initStorage;
    await GetStorage('bham_route_learning', storageRoot.path).initStorage;
    await GetStorage('ai2ai_chat_contract_prefs', storageRoot.path).initStorage;
  });

  group('Signal transport contract (DM + community)', () {
    late InMemoryRealtimeBackend realtime;
    late AgentIdService agentIdService;
    late AtomicClockService atomicClock;
    late InMemoryDmMessageStore dmStore;
    late InMemoryCommunitySenderKeyService senderKeyService;
    late InMemoryCommunityMessageStore communityMessageStore;
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
      realtime = InMemoryRealtimeBackend();
      agentIdService = AgentIdService();
      atomicClock = AtomicClockService();
      dmStore = InMemoryDmMessageStore();
      senderKeyService = InMemoryCommunitySenderKeyService();
      communityMessageStore = InMemoryCommunityMessageStore();
      await GetStorage('friend_chat_messages').erase();
      await GetStorage('friend_chat_outbox').erase();
      await GetStorage('community_chat_messages').erase();
      await GetStorage('bham_route_learning').erase();
    });

    tearDown(() async {
      await realtime.unsubscribeAll();
    });

    test(
        'Friend DM: sendMessageOverNetwork stores locally and queues if transport is non-Signal',
        () async {
      final service = FriendChatService(
        encryptionService: AES256GCMEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      await service.sendMessageOverNetwork('userA', 'userB', 'hello');

      final history = await service.getConversationHistory('userA', 'userB');
      expect(history, hasLength(1));

      final plaintext =
          await service.getDecryptedMessage(history.single, 'userA', 'userB');
      expect(plaintext, equals('hello'));
    });

    test(
        'Friend DM: sender route receipt advances from custody to delivered to read',
        () async {
      final service = FriendChatService(
        encryptionService: FakeSignalEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        routePlanner: BhamRoutePlanner(),
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      final result = await service.sendMessageOverNetworkWithKernelContext(
        'userA',
        'userB',
        'hello with receipts',
      );

      expect(
        result.routeReceipt?.lifecycleStage,
        TransportReceiptLifecycleStage.custodyAccepted,
      );

      var history = await service.getConversationHistory('userA', 'userB');
      expect(history, hasLength(1));
      expect(
        _routeReceiptFromMessage(history.single)?.lifecycleStage,
        TransportReceiptLifecycleStage.custodyAccepted,
      );

      await realtime.sendMessage(
        'dm_receipts:userA',
        RealtimeMessage(
          id: result.message.messageId,
          senderId: 'userB',
          content: result.message.messageId,
          type: 'dm_receipt',
          timestamp: DateTime.now().toUtc(),
          metadata: <String, dynamic>{
            'kind': 'dm_delivery_receipt_v1',
            'message_id': result.message.messageId,
            'sender_user_id': 'userA',
            'recipient_user_id': 'userB',
            'receipt_by_user_id': 'userB',
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      history = await service.getConversationHistory('userA', 'userB');
      expect(
        _routeReceiptFromMessage(history.single)?.lifecycleStage,
        TransportReceiptLifecycleStage.delivered,
      );

      final marked = await service.markAsRead('userB', 'userA');
      expect(marked, 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      history = await service.getConversationHistory('userA', 'userB');
      final readReceipt = _routeReceiptFromMessage(history.single);
      expect(readReceipt?.lifecycleStage, TransportReceiptLifecycleStage.read);
      expect(readReceipt?.readBy, 'userB');
      expect(history.single.isRead, isTrue);
    });

    test(
        'Friend DM: successful network send stores learnable metadata and feeds analyzer',
        () async {
      final prefsStorage = GetStorage('ai2ai_chat_contract_prefs');
      await prefsStorage.erase();
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: prefsStorage);
      await prefs.setBool('user_runtime_learning_enabled', true);
      await prefs.setBool('ai2ai_learning_enabled', true);
      final analyzer = AI2AIChatAnalyzer(
        prefs: prefs,
        personalityLearning: PersonalityLearning.withPrefs(prefs),
      );
      final intake = Ai2AiChatEventIntakeService(
        chatAnalyzer: analyzer,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
        agentIdService: agentIdService,
      );
      final service = FriendChatService(
        encryptionService: FakeSignalEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        routePlanner: BhamRoutePlanner(),
        ai2aiChatEventIntakeService: intake,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      await service.sendMessageOverNetworkWithKernelContext(
        'userA',
        'userB',
        'I prefer collaborative planning and trying new local spots.',
      );

      final history = await service.getConversationHistory('userA', 'userB');
      expect(history, hasLength(1));
      expect(
        history
            .single.metadata?[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );

      final learningHistory = await analyzer.getChatHistoryForAdmin('userA');
      expect(learningHistory, hasLength(1));
      expect(
        learningHistory.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });

    test('Friend DM: inbound non-Signal payload is ignored (not stored)',
        () async {
      final service = FriendChatService(
        encryptionService: AES256GCMEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      const inboxChannel = 'dm_mailbox:userA';

      var received = false;
      final sub = service
          .subscribeToIncomingMessages(userId: 'userA', friendId: 'userB')
          .listen((_) => received = true);

      // Give the subscription a moment to start and attach to the inbox channel.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final payload = {
        'kind': 'friend_dm_v1',
        'messageId': 'msg1',
        'senderUserId': 'userB',
        'senderAgentId': await agentIdService.getUserAgentId('userB'),
        'recipientUserId': 'userA',
        'recipientAgentId': await agentIdService.getUserAgentId('userA'),
        'ciphertext':
            base64Encode(const [1, 2, 3]), // irrelevant; should be rejected
        'encryptionType': EncryptionType.aes256gcm.name,
        'sentAt': DateTime.now().toIso8601String(),
      };

      await realtime.sendMessage(
        inboxChannel,
        RealtimeMessage(
          id: 'msg1',
          senderId: payload['senderAgentId'] as String,
          content: jsonEncode(payload),
          type: 'friend_dm',
          timestamp: DateTime.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      unawaited(sub.cancel());

      expect(received, isFalse);
      final history = await service.getConversationHistory('userA', 'userB');
      expect(history, isEmpty);
    });

    test('Friend DM: inbound Signal payload is stored locally then consumed',
        () async {
      final encryption = FakeSignalEncryptionService();
      final service = FriendChatService(
        encryptionService: encryption,
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      final encrypted = await encryption.encrypt('hello inbound', 'userA');
      await dmStore.putDmBlob(
        messageId: 'msg-signal-inbound',
        fromUserId: 'userB',
        toUserId: 'userA',
        senderAgentId: await agentIdService.getUserAgentId('userB'),
        recipientAgentId: await agentIdService.getUserAgentId('userA'),
        encrypted: encrypted,
        sentAt: DateTime.utc(2026, 4, 5, 18, 0),
      );

      final receivedFuture = service
          .subscribeToIncomingMessages(userId: 'userA', friendId: 'userB')
          .first
          .timeout(const Duration(seconds: 1));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await realtime.sendMessage(
        'dm_mailbox:userA',
        RealtimeMessage(
          id: 'msg-signal-inbound',
          senderId: await agentIdService.getUserAgentId('userB'),
          content: 'msg-signal-inbound',
          type: 'dm_notification',
          timestamp: DateTime.now(),
        ),
      );

      final received = await receivedFuture;
      expect(
        await service.getDecryptedMessage(received, 'userA', 'userB'),
        'hello inbound',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(dmStore.containsBlob('msg-signal-inbound'), isFalse);
      expect(dmStore.consumeCallCount('msg-signal-inbound'), 1);
    });

    test(
        'Community: sendGroupMessageOverNetwork stores locally, but refuses non-Signal transport',
        () async {
      final service = CommunityChatService(
        encryptionService: AES256GCMEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        senderKeyService: senderKeyService,
        communityMessageStore: communityMessageStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      final community = Community(
        id: 'community1',
        name: 'Test Community',
        category: 'test',
        originatingEventId: 'event1',
        originatingEventType: OriginatingEventType.communityEvent,
        memberIds: const ['userA', 'userB'],
        memberCount: 2,
        founderId: 'userA',
        createdAt: DateTime.now(),
        originalLocality: 'Testville',
        updatedAt: DateTime.now(),
      );

      // For tests we provide a pre-established sender key, so transport does not
      // require Signal. The message is encrypted once with the sender key.
      senderKeyService.setKeyForCommunity(community.id, keyId: 'key1');

      await service.sendGroupMessageOverNetwork(
        userId: 'userA',
        communityId: community.id,
        message: 'hello group',
        community: community,
      );

      final history = await service.getGroupChatHistory(community.id);
      expect(history, hasLength(1));

      final plaintext =
          await service.getDecryptedMessage(history.single, community.id);
      expect(plaintext, equals('hello group'));
    });

    test('Community: inbound non-Signal payload is not emitted to stream',
        () async {
      final service = CommunityChatService(
        encryptionService: AES256GCMEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        senderKeyService: senderKeyService,
        communityMessageStore: communityMessageStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      const inboxChannel = 'community_stream:community1';

      var received = false;
      final sub = service
          .subscribeToIncomingCommunityMessages(
              userId: 'userA', communityId: 'community1')
          .listen((_) => received = true);

      // Give the subscription a moment to start and attach to the inbox channel.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final payload = {
        'kind': 'community_msg_v1',
        'messageId': 'msg2',
        'communityId': 'community1',
        'senderUserId': 'userB',
        'senderAgentId': await agentIdService.getUserAgentId('userB'),
        'recipientUserId': 'userA',
        'recipientAgentId': await agentIdService.getUserAgentId('userA'),
        'ciphertext':
            base64Encode(const [4, 5, 6]), // irrelevant; should be rejected
        'encryptionType': EncryptionType.aes256gcm.name,
        'sentAt': DateTime.now().toIso8601String(),
      };

      await realtime.sendMessage(
        inboxChannel,
        RealtimeMessage(
          id: 'msg2',
          senderId: payload['senderAgentId'] as String,
          content: jsonEncode(payload),
          type: 'community_msg',
          timestamp: DateTime.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      unawaited(sub.cancel());

      expect(received, isFalse);
    });

    test(
        'Community: inbound sender-key payload is stored locally then consumed',
        () async {
      final service = CommunityChatService(
        encryptionService: AES256GCMEncryptionService(),
        agentIdService: agentIdService,
        realtimeBackend: realtime,
        atomicClock: atomicClock,
        dmStore: dmStore,
        senderKeyService: senderKeyService,
        communityMessageStore: communityMessageStore,
        humanLanguageBoundaryReviewLane:
            _FixedHumanLanguageBoundaryReviewLane(allowedBoundaryDecision),
      );

      senderKeyService.setKeyForCommunity('community1', keyId: 'key1');
      await communityMessageStore.putMessageBlob(
        messageId: 'msg-community-inbound',
        communityId: 'community1',
        senderUserId: 'userB',
        senderAgentId: await agentIdService.getUserAgentId('userB'),
        keyId: 'key1',
        algorithm: 'aes256gcm_fixed_key',
        ciphertextBase64: Aes256GcmFixedKeyCodec.encryptStringToBase64(
          key32: Uint8List.fromList(List<int>.filled(32, 7)),
          plaintext: 'hello community inbound',
        ),
        sentAt: DateTime.utc(2026, 4, 5, 18, 5),
      );

      final receivedFuture = service
          .subscribeToIncomingCommunityMessages(
            userId: 'userA',
            communityId: 'community1',
          )
          .first
          .timeout(const Duration(seconds: 1));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await realtime.sendMessage(
        'community_stream:community1',
        RealtimeMessage(
          id: 'msg-community-inbound',
          senderId: await agentIdService.getUserAgentId('userB'),
          content: 'msg-community-inbound',
          type: 'community_msg',
          timestamp: DateTime.now(),
        ),
      );

      final received = await receivedFuture;
      expect(
        await service.getDecryptedMessage(received, 'community1'),
        'hello community inbound',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        communityMessageStore.containsBlob('msg-community-inbound'),
        isFalse,
      );
      expect(
        communityMessageStore.consumeCallCount('msg-community-inbound'),
        1,
      );
    });
  });

  tearDownAll(() async {
    if (storageRoot.existsSync()) {
      await storageRoot.delete(recursive: true);
    }
  });
}

class InMemoryDmMessageStore implements DmMessageStore {
  final Map<String, DmMessageBlob> _blobs = {};
  final Map<String, int> _consumeCalls = {};

  @override
  Ai2AiRetentionPolicy get blobRetentionPolicy =>
      Ai2AiRetentionConfig.dmTransportBlob;

  @override
  Future<void> enqueueDm({
    required String messageId,
    required String fromUserId,
    required String toUserId,
    required String senderAgentId,
    required String recipientAgentId,
    required EncryptedMessage encrypted,
    required DateTime sentAt,
    String recipientDeviceId = 'legacy',
  }) async {
    await putDmBlob(
      messageId: messageId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      senderAgentId: senderAgentId,
      recipientAgentId: recipientAgentId,
      encrypted: encrypted,
      sentAt: sentAt,
    );
  }

  @override
  Future<DmMessageBlob?> getDmBlob(String messageId) async {
    return _blobs[messageId];
  }

  @override
  Future<DmTransportConsumeResult> consumeDmBlob({
    required String messageId,
    required String toUserId,
    String? recipientDeviceId,
  }) async {
    _consumeCalls.update(messageId, (value) => value + 1, ifAbsent: () => 1);
    final removed = _blobs.remove(messageId) != null;
    return DmTransportConsumeResult(
      ok: true,
      deletedBlobCount: removed ? 1 : 0,
      deletedNotificationCount: removed ? 1 : 0,
      remainingBlobCount: 0,
    );
  }

  @override
  Future<void> putDmBlob({
    required String messageId,
    required String fromUserId,
    required String toUserId,
    required String senderAgentId,
    required String recipientAgentId,
    required EncryptedMessage encrypted,
    required DateTime sentAt,
  }) async {
    _blobs[messageId] = DmMessageBlob(
      messageId: messageId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      senderAgentId: senderAgentId,
      recipientAgentId: recipientAgentId,
      encryptionType: encrypted.encryptionType,
      ciphertextBase64: encrypted.toBase64(),
      sentAt: sentAt,
    );
  }

  bool containsBlob(String messageId) => _blobs.containsKey(messageId);

  int consumeCallCount(String messageId) => _consumeCalls[messageId] ?? 0;
}

class InMemoryCommunityMessageStore extends CommunityMessageStore {
  final Map<String, CommunityMessageBlob> _blobs = {};
  final Map<String, int> _consumeCalls = {};

  InMemoryCommunityMessageStore() : super(supabase: null);

  @override
  Future<void> putMessageBlob({
    required String messageId,
    required String communityId,
    required String senderUserId,
    required String senderAgentId,
    required String keyId,
    required String algorithm,
    required String ciphertextBase64,
    required DateTime sentAt,
  }) async {
    _blobs[messageId] = CommunityMessageBlob(
      messageId: messageId,
      communityId: communityId,
      senderUserId: senderUserId,
      senderAgentId: senderAgentId,
      keyId: keyId,
      algorithm: algorithm,
      ciphertextBase64: ciphertextBase64,
      sentAt: sentAt,
    );
  }

  @override
  Future<CommunityMessageBlob?> getMessageBlob(String messageId) async {
    return _blobs[messageId];
  }

  @override
  Future<CommunityMessageConsumeResult> consumeMessageBlob({
    required String messageId,
    required String recipientUserId,
  }) async {
    _consumeCalls.update(messageId, (value) => value + 1, ifAbsent: () => 1);
    final removed = _blobs.remove(messageId) != null;
    return CommunityMessageConsumeResult(
      ok: true,
      deletedNotificationCount: removed ? 1 : 0,
      deletedBlobCount: removed ? 1 : 0,
      remainingNotificationCount: 0,
    );
  }

  bool containsBlob(String messageId) => _blobs.containsKey(messageId);

  int consumeCallCount(String messageId) => _consumeCalls[messageId] ?? 0;
}

class InMemoryCommunitySenderKeyService extends CommunitySenderKeyService {
  CommunitySenderKey? _key;

  InMemoryCommunitySenderKeyService()
      : super(
          secureStorage: InMemoryFlutterSecureStorage(),
          supabase:
              SupabaseService(), // Not used (we override getOrEstablishKey)
          agentIdService: AgentIdService(), // Not used
          encryptionService: AES256GCMEncryptionService(),
        );

  void setKeyForCommunity(String communityId, {required String keyId}) {
    final bytes = Uint8List.fromList(List<int>.filled(32, 7));
    _key = CommunitySenderKey(
        communityId: communityId, keyId: keyId, keyBytes32: bytes);
  }

  @override
  Future<CommunitySenderKey> getOrEstablishKey({
    required String communityId,
    required String currentUserId,
    required List<String> memberUserIds,
  }) async {
    final k = _key;
    if (k != null && k.communityId == communityId) return k;
    throw Exception('No in-memory sender key set');
  }

  @override
  Future<CommunitySenderKey> ensureCurrentKeyAndMembership({
    required String communityId,
    required String currentUserId,
  }) async {
    return getOrEstablishKey(
      communityId: communityId,
      currentUserId: currentUserId,
      memberUserIds: const <String>[],
    );
  }

  @override
  Future<CommunitySenderKey> getKeyForMessage({
    required String communityId,
    required String currentUserId,
    required String keyId,
  }) async {
    final k = _key;
    if (k == null || k.communityId != communityId) {
      throw Exception('No in-memory sender key set');
    }
    if (k.keyId != keyId) {
      throw Exception('In-memory sender key id mismatch');
    }
    return k;
  }
}
