import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/event_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventChatService', () {
    late EventChatService service;

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
      await GetStorage.init('bham_event_chat');
      await GetStorage.init('bham_event_chat_memberships');
      await GetStorage.init('bham_route_learning');
    });

    setUp(() async {
      service = EventChatService();
      await GetStorage('bham_event_chat').erase();
      await GetStorage('bham_event_chat_memberships').erase();
      await GetStorage('bham_route_learning').erase();
    });

    test(
        'sends event messages with route receipt and wormhole-capable planning',
        () async {
      await service.joinEventThread(
        userId: 'user-a',
        eventId: 'event-1',
        title: 'Launch Event',
      );

      final message = await service.sendEventMessage(
        userId: 'user-a',
        eventId: 'event-1',
        body: 'On my way',
      );

      expect(message.routeReceipt, isNotNull);
      expect(message.routeReceipt!.plannedRoutes, isNotEmpty);
      expect(
        message.routeReceipt!.plannedRoutes
            .any((route) => route.mode == TransportMode.wormhole),
        isTrue,
      );
      expect(message.routeReceipt!.winningRoute, isNotNull);
    });
  });
}
