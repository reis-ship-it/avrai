import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_platform_wake_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('avra/background_runtime');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('consumes pending wake reasons from the native bridge', () async {
    var scheduledIntervalSeconds = 0;
    var cancelCalled = false;
    var headlessCompletionPayload = <String, Object?>{};
    var platformCapabilities = <String, Object?>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'consumePendingWakeInvocations':
          return <Map<String, Object?>>[
            <String, Object?>{
              'reason': 'boot_completed',
              'platform_source': 'android_boot_receiver',
              'wake_timestamp_utc': '2026-03-13T18:00:00.000Z',
            },
            <String, Object?>{
              'reason': 'trusted_announce_refresh',
              'platform_source': 'android_alarm_receiver',
              'wake_timestamp_utc': '2026-03-13T18:05:00.000Z',
              'is_wifi_available': true,
            },
            <String, Object?>{
              'reason': 'unknown_reason',
              'platform_source': 'android_unknown',
              'wake_timestamp_utc': '2026-03-13T18:10:00.000Z',
            },
          ];
        case 'notifyForegroundReady':
          return null;
        case 'scheduleBackgroundTaskWindow':
          scheduledIntervalSeconds =
              (call.arguments as Map)['intervalSeconds'] as int;
          return true;
        case 'cancelBackgroundTaskWindow':
          cancelCalled = true;
          return true;
        case 'notifyHeadlessExecutionComplete':
          headlessCompletionPayload =
              Map<String, Object?>.from(call.arguments as Map);
          return true;
        case 'getPlatformWakeCapabilities':
          platformCapabilities = <String, Object?>{
            'platform': 'android',
            'supports_boot_restore': true,
            'supports_background_task_window': true,
            'supports_connectivity_wifi': true,
            'supports_ble_encounter': true,
            'supports_significant_location': true,
            'supports_headless_execution': true,
          };
          return platformCapabilities;
        default:
          return null;
      }
    });

    final bridge = MethodChannelBackgroundPlatformWakeBridge(channel: channel);
    await bridge.notifyForegroundReady();
    await bridge.scheduleBackgroundTaskWindow(
      interval: const Duration(minutes: 30),
    );
    await bridge.cancelBackgroundTaskWindow();
    await bridge.notifyHeadlessExecutionComplete(
      success: true,
      handledInvocationCount: 2,
    );
    final capabilities = await bridge.getPlatformWakeCapabilities();
    final invocations = await bridge.consumePendingWakeInvocations();

    expect(scheduledIntervalSeconds, 1800);
    expect(cancelCalled, isTrue);
    expect(headlessCompletionPayload['success'], isTrue);
    expect(headlessCompletionPayload['handledInvocationCount'], 2);
    expect(capabilities['supports_connectivity_wifi'], isTrue);
    expect(capabilities['supports_significant_location'], isTrue);
    expect(platformCapabilities['platform'], 'android');
    expect(
      invocations.map((entry) => entry.reason).toList(growable: false),
      equals(
        <BackgroundWakeReason>[
          BackgroundWakeReason.bootCompleted,
          BackgroundWakeReason.trustedAnnounceRefresh,
        ],
      ),
    );
    expect(invocations.first.platformSource, 'android_boot_receiver');
    expect(invocations[1].isWifiAvailable, isTrue);
  });
}
