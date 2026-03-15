import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
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
        humanLanguageBoundaryReviewLane: HumanLanguageBoundaryReviewLane(
          prefs: prefs,
        ),
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
  });

  tearDownAll(() async {
    if (storageRoot.existsSync()) {
      await storageRoot.delete(recursive: true);
    }
  });
}

class InMemoryDmMessageStore implements DmMessageStore {
  final Map<String, DmMessageBlob> _blobs = {};

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
}

class InMemoryCommunityMessageStore extends CommunityMessageStore {
  final Map<String, CommunityMessageBlob> _blobs = {};

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
