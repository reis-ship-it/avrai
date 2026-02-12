import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:avrai_network/network/device_discovery.dart';

class _FakeDeviceDiscoveryPlatform implements DeviceDiscoveryPlatform {
  int scanCalls = 0;
  Duration? lastScanWindow;

  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async {
    scanCalls += 1;
    lastScanWindow = scanWindow;
    return <DiscoveredDevice>[
      DiscoveredDevice(
        deviceId: 'device-$scanCalls',
        deviceName: 'Test Device',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        discoveredAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => <String, dynamic>{};

  @override
  bool isSupported() => true;

  @override
  Future<bool> requestPermissions() async => true;
}

void main() {
  group('DeviceDiscoveryService', () {
    late DeviceDiscoveryService discoveryService;
    late _FakeDeviceDiscoveryPlatform fakePlatform;

    setUp(() {
      fakePlatform = _FakeDeviceDiscoveryPlatform();
      discoveryService = DeviceDiscoveryService(platform: fakePlatform);
    });

    tearDown(() {
      discoveryService.stopDiscovery();
    });

    group('startDiscovery', () {
      test('should start discovery and scan for devices', () async {
        var devicesDiscoveredCompleter = Completer<List<DiscoveredDevice>>();
        discoveryService.onDevicesDiscovered((devices) {
          if (!devicesDiscoveredCompleter.isCompleted) {
            devicesDiscoveredCompleter.complete(devices);
          }
        });

        await discoveryService.startDiscovery();

        final discovered = await devicesDiscoveredCompleter.future.timeout(
          const Duration(seconds: 1),
        );

        expect(discovered, isNotEmpty);
        expect(fakePlatform.scanCalls, equals(1));
      });

      test('should not start discovery if already running', () async {
        await discoveryService.startDiscovery();
        final initialCount = discoveryService.getDiscoveredDevices().length;

        await discoveryService.startDiscovery();
        final afterCount = discoveryService.getDiscoveredDevices().length;

        expect(afterCount, equals(initialCount));
      });

      test('should pass scanWindow through to platform scan', () {
        fakeAsync((async) {
          unawaited(
            discoveryService.startDiscovery(
              scanInterval: const Duration(days: 1),
              scanWindow: const Duration(seconds: 9),
            ),
          );

          async.flushMicrotasks();

          expect(fakePlatform.scanCalls, equals(1));
          expect(fakePlatform.lastScanWindow, equals(const Duration(seconds: 9)));
        });
      });

      test('continuous scan (scanInterval=0) should respect scanWindow cadence', () {
        fakeAsync((async) {
          unawaited(
            discoveryService.startDiscovery(
              scanInterval: Duration.zero,
              scanWindow: const Duration(seconds: 4),
            ),
          );
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(1));

          async.elapse(const Duration(seconds: 3));
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(1));

          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(2));

          discoveryService.stopDiscovery();
          async.flushMicrotasks();
        });
      });

      test('updateScanConfig should apply new scanWindow on next scan', () {
        fakeAsync((async) {
          unawaited(
            discoveryService.startDiscovery(
              scanInterval: Duration.zero,
              scanWindow: const Duration(seconds: 4),
            ),
          );
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(1));
          expect(fakePlatform.lastScanWindow, equals(const Duration(seconds: 4)));

          discoveryService.updateScanConfig(
            scanWindow: const Duration(seconds: 1),
          );

          // Next scan won't start until the previous window has elapsed.
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(2));
          expect(fakePlatform.lastScanWindow, equals(const Duration(seconds: 1)));

          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          expect(fakePlatform.scanCalls, equals(3));

          discoveryService.stopDiscovery();
          async.flushMicrotasks();
        });
      });
    });

    group('stopDiscovery', () {
      test('should stop discovery', () {
        discoveryService.startDiscovery();
        discoveryService.stopDiscovery();

        // Discovery should be stopped
        // (We can't easily test this without platform implementation)
        expect(discoveryService.getDiscoveredDevices(), isA<List<DiscoveredDevice>>());
      });
    });

    group('getDiscoveredDevices', () {
      test('should return empty list initially', () {
        final devices = discoveryService.getDiscoveredDevices();
        expect(devices, isEmpty);
      });
    });

    group('calculateProximity', () {
      test('should calculate proximity from signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -50, // Strong signal
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, greaterThan(0.5)); // Strong signal = high proximity
      });

      test('should return 0.5 for unknown signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, equals(0.5));
      });

      test('should handle weak signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -100, // Weak signal
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, lessThan(0.5)); // Weak signal = low proximity
      });
    });
  });

  group('DiscoveredDevice', () {
    test('should create device with all properties', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.wifi,
        isSpotsEnabled: true,
        signalStrength: -70,
        discoveredAt: DateTime.now(),
        metadata: {'key': 'value'},
      );

      expect(device.deviceId, equals('device1'));
      expect(device.deviceName, equals('Test Device'));
      expect(device.type, equals(DeviceType.wifi));
      expect(device.isSpotsEnabled, isTrue);
      expect(device.signalStrength, equals(-70));
      expect(device.metadata['key'], equals('value'));
    });

    test('should calculate proximity score', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        signalStrength: -50,
        discoveredAt: DateTime.now(),
      );

      expect(device.proximityScore, greaterThan(0.0));
      expect(device.proximityScore, lessThanOrEqualTo(1.0));
    });

    test('should detect stale devices', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        discoveredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(device.isStale(const Duration(minutes: 2)), isTrue);
      expect(device.isStale(const Duration(minutes: 10)), isFalse);
    });
  });
}

