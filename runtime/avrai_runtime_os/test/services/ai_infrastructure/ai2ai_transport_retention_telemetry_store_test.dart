import 'dart:io';

import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
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
    storageRoot =
        await Directory.systemTemp.createTemp('ai2ai_transport_retention_');
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

  test('records consume successes and failures in a single snapshot', () async {
    final store = Ai2AiTransportRetentionTelemetryStore(
      nowUtc: () => DateTime.utc(2026, 4, 5, 20, 30),
    );

    await store.recordDmConsumeSuccess(
      messageId: 'dm-1',
      recipientUserId: 'user-b',
      recipientDeviceId: '7',
      deletedTransportCount: 2,
      remainingTransportCount: 0,
    );
    await store.recordCommunityConsumeFailure(
      messageId: 'community-1',
      recipientUserId: 'user-c',
      errorSummary: 'rpc_missing',
    );

    final snapshot = store.snapshot(
      capturedAtUtc: DateTime.utc(2026, 4, 5, 20, 31),
    );

    expect(snapshot.dmConsumedCount, 1);
    expect(snapshot.dmFailureCount, 0);
    expect(snapshot.communityConsumedCount, 0);
    expect(snapshot.communityFailureCount, 1);
    expect(snapshot.latestFailureSummary, 'rpc_missing');
    expect(snapshot.recentEvents, hasLength(2));
    expect(snapshot.recentEvents.first.messageId, 'community-1');
    expect(snapshot.recentEvents.last.recipientDeviceId, '7');
  });
}
