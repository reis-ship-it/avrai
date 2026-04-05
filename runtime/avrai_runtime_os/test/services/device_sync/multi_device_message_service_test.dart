import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/crypto/signal/device_registration_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/device_sync/multi_device_message_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;

  setUpAll(() async {
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
    storageRoot = await Directory.systemTemp.createTemp('multi_device_sync_');
    final defaultStorage = GetStorage('spots_default', storageRoot.path);
    final userStorage = GetStorage('spots_user', storageRoot.path);
    final aiStorage = GetStorage('spots_ai', storageRoot.path);
    final analyticsStorage = GetStorage('spots_analytics', storageRoot.path);
    await defaultStorage.initStorage;
    await userStorage.initStorage;
    await aiStorage.initStorage;
    await analyticsStorage.initStorage;
    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore temp cleanup failures in tests.
    }
  });

  setUp(() async {
    await StorageService.instance.clear(box: 'spots_ai');
  });

  test('fetch persists locally before consuming the device transport blob',
      () async {
    final dmStore = _InMemoryDmMessageStore(
      blob: DmMessageBlob(
        messageId: 'msg-1',
        fromUserId: 'user-a',
        toUserId: 'user-b',
        senderAgentId: 'agent-a',
        recipientAgentId: 'agent-b',
        encryptionType: EncryptionType.signalProtocol,
        ciphertextBase64: EncryptedMessage(
          encryptedContent: Uint8List.fromList('hello'.codeUnits),
          encryptionType: EncryptionType.signalProtocol,
        ).toBase64(),
        sentAt: DateTime.utc(2026, 4, 5, 21),
      ),
    );
    final registrationService = DeviceRegistrationService(
      keyManager: SignalKeyManager(
        secureStorage: const FlutterSecureStorage(),
        ffiBindings: SignalFFIBindings(),
      ),
    )..currentDevice = RegisteredDevice(
        deviceId: 7,
        deviceName: 'Test phone',
        registeredAt: DateTime.utc(2026, 4, 5, 20),
        lastSeenAt: DateTime.utc(2026, 4, 5, 20, 30),
        isActive: true,
        status: DeviceStatus.active,
        userId: 'user-b',
      );
    final service = MultiDeviceMessageService(
      deviceRegistrationService: registrationService,
      encryptionService: _PassthroughEncryptionService(),
      dmStore: dmStore,
      realtimeBackend: _NoopRealtimeBackend(),
      supabaseService: SupabaseService(),
      storageService: StorageService.instance,
    );

    final decrypted = await service.fetchAndDecryptForDevice(
      messageId: 'msg-1',
      currentUserId: 'user-b',
    );

    expect(decrypted, isNotNull);
    expect(decrypted!.content, 'hello');
    expect(dmStore.consumedMessageIds, contains('msg-1'));
    expect(dmStore.lastRecipientDeviceId, '7');
    final stored = StorageService.instance.getObject<dynamic>(
      'multi_device_inbox_v1:7:msg-1',
      box: 'spots_ai',
    ) as Map<dynamic, dynamic>?;
    expect(stored, isNotNull);
    expect(stored?['content'], 'hello');
  });
}

class _PassthroughEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return String.fromCharCodes(encrypted.encryptedContent);
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(plaintext.codeUnits),
      encryptionType: EncryptionType.signalProtocol,
    );
  }
}

class _InMemoryDmMessageStore extends DmMessageStore {
  _InMemoryDmMessageStore({this.blob});

  final DmMessageBlob? blob;
  final List<String> consumedMessageIds = <String>[];
  String? lastRecipientDeviceId;

  @override
  Future<DmMessageBlob?> getDmBlob(String messageId) async {
    if (blob?.messageId == messageId) {
      return blob;
    }
    return null;
  }

  @override
  Future<DmTransportConsumeResult> consumeDmBlob({
    required String messageId,
    required String toUserId,
    String? recipientDeviceId,
  }) async {
    consumedMessageIds.add(messageId);
    lastRecipientDeviceId = recipientDeviceId;
    return const DmTransportConsumeResult(
      ok: true,
      deletedBlobCount: 1,
      deletedNotificationCount: 1,
      remainingBlobCount: 0,
    );
  }
}

class _NoopRealtimeBackend implements RealtimeBackend {
  @override
  Stream<RealtimeConnectionStatus> get connectionStatus =>
      const Stream<RealtimeConnectionStatus>.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> joinChannel(String channelId) async {}

  @override
  Future<void> leaveChannel(String channelId) async {}

  @override
  Future<void> removePresence(String channelId) async {}

  @override
  Future<void> sendMessage(String channelId, RealtimeMessage message) async {}

  @override
  Stream<List<T>> subscribeToCollection<T>(
    String collection,
    T Function(Map<String, dynamic> p1) fromJson, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? descending,
    int? limit,
  }) {
    return Stream<List<T>>.empty();
  }

  @override
  Stream<T?> subscribeToDocument<T>(
    String collection,
    String documentId,
    T Function(Map<String, dynamic> p1) fromJson,
  ) {
    return Stream<T?>.empty();
  }

  @override
  Stream<List<LiveCursor>> subscribeToLiveCursors(String documentId) {
    return const Stream<List<LiveCursor>>.empty();
  }

  @override
  Stream<RealtimeMessage> subscribeToMessages(String channelId) {
    return const Stream<RealtimeMessage>.empty();
  }

  @override
  Stream<List<Spot>> subscribeToNearbySpots(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return const Stream<List<Spot>>.empty();
  }

  @override
  Stream<List<UserPresence>> subscribeToPresence(String channelId) {
    return const Stream<List<UserPresence>>.empty();
  }

  @override
  Stream<Spot?> subscribeToSpot(String spotId) {
    return const Stream<Spot?>.empty();
  }

  @override
  Stream<SpotList?> subscribeToSpotList(String listId) {
    return const Stream<SpotList?>.empty();
  }

  @override
  Stream<List<Spot>> subscribeToSpotsInList(String listId) {
    return const Stream<List<Spot>>.empty();
  }

  @override
  Stream<User?> subscribeToUser(String userId) {
    return const Stream<User?>.empty();
  }

  @override
  Stream<List<SpotList>> subscribeToUserLists(String userId) {
    return const Stream<List<SpotList>>.empty();
  }

  @override
  Stream<List<Spot>> subscribeToUserRespectedSpots(String userId) {
    return const Stream<List<Spot>>.empty();
  }

  @override
  Future<void> trackRealtimeEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {}

  @override
  Future<void> unsubscribe(String subscriptionId) async {}

  @override
  Future<void> unsubscribeAll() async {}

  @override
  Future<void> updateLiveCursor(String documentId, LiveCursor cursor) async {}

  @override
  Future<void> updatePresence(String channelId, UserPresence presence) async {}
}
