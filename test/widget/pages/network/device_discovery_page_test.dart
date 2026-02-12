/// Tests for Device Discovery Status Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/presentation/pages/network/device_discovery_page.dart';

void main() {
  setUpAll(() {});

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('DeviceDiscoveryPage', () {
    // Removed: Property assignment tests (data models instantiate correctly - property checks)
    // Device discovery page tests focus on business logic (page rendering, discovered devices display, info dialog), not property assignment

    testWidgets(
        'should render page with discovery inactive state, display discovered devices when scanning, or show info dialog when info button tapped',
        (tester) async {
      // Test business logic: Device discovery page display and interactions
      final mockService = MockDeviceDiscoveryService();
      GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockService);

      await tester.pumpWidget(const MaterialApp(home: DeviceDiscoveryPage()));
      await tester.pumpAndSettle();
      expect(find.text('Device Discovery'), findsOneWidget);
      expect(find.text('Discovery Inactive'), findsOneWidget);
      expect(find.text('Start Discovery'), findsOneWidget);

      // Simulate devices being discovered when scanning starts.
      mockService.setDevices([
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device 1',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -50,
          discoveredAt: DateTime.now(),
        ),
      ]);
      await tester.tap(find.text('Start Discovery'));
      await tester.pumpAndSettle();
      expect(find.text('Discovery Active'), findsOneWidget);
      expect(find.textContaining('1 device found'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text('About Device Discovery'), findsOneWidget);
      expect(find.textContaining('Privacy:'), findsOneWidget);
    });
  });
}

/// Mock implementation of DeviceDiscoveryService for testing
class MockDeviceDiscoveryService extends DeviceDiscoveryService {
  List<DiscoveredDevice> _devices = [];

  MockDeviceDiscoveryService() : super(platform: null);

  void setDevices(List<DiscoveredDevice> devices) {
    _devices = devices;
  }

  @override
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration scanWindow = const Duration(seconds: 4),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
  }

  @override
  void stopDiscovery() {
  }

  @override
  List<DiscoveredDevice> getDiscoveredDevices() {
    return _devices;
  }

  @override
  DiscoveredDevice? getDevice(String deviceId) {
    return _devices.where((d) => d.deviceId == deviceId).firstOrNull;
  }
}
