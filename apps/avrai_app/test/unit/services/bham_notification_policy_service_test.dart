import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_notification_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BhamNotificationPolicyService', () {
    late BhamNotificationPolicyService service;

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
      await GetStorage.init('bham_notification_policy');
    });

    setUp(() async {
      service = BhamNotificationPolicyService();
      await GetStorage('bham_notification_policy').erase();
    });

    test('caps daily-drop style notifications at 3 per day', () async {
      final midday = DateTime.utc(2026, 3, 8, 18);

      expect(
        await service.canSend(
          notificationClass: NotificationClass.dailyDrop,
          nowUtc: midday,
        ),
        isTrue,
      );

      await service.recordSent(
        notificationClass: NotificationClass.dailyDrop,
        nowUtc: midday,
      );
      await service.recordSent(
        notificationClass: NotificationClass.contextNudge,
        nowUtc: midday,
      );
      await service.recordSent(
        notificationClass: NotificationClass.ai2aiCompatibility,
        nowUtc: midday,
      );

      expect(
        await service.canSend(
          notificationClass: NotificationClass.dailyDrop,
          nowUtc: midday,
        ),
        isFalse,
      );
    });

    test(
        'blocks capped notifications during quiet hours but not human messages',
        () async {
      final quietHour = DateTime.utc(2026, 3, 8, 23);

      expect(
        await service.canSend(
          notificationClass: NotificationClass.contextNudge,
          nowUtc: quietHour,
        ),
        isFalse,
      );
      expect(
        await service.canSend(
          notificationClass: NotificationClass.humanMessage,
          nowUtc: quietHour,
        ),
        isTrue,
      );
    });
  });
}
