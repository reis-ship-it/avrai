/// Tests for Discovered Devices Widget
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/presentation/widgets/network/discovered_devices_widget.dart';

void main() {
  setUpAll(() {});

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('DiscoveredDevicesWidget', () {
    // Removed: Property assignment tests
    // Discovered devices widget tests focus on business logic (device display, user interactions, connection), not property assignment

    testWidgets(
        'should display empty state when no devices, display device list when devices provided, display personality badge for AI-enabled devices, show proximity indicators correctly, trigger connection button callback, hide connection button when showConnectionButton is false, or call onDeviceTap when device card is tapped',
        (tester) async {
      // Test business logic: discovered devices widget display and interactions
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: [],
            ),
          ),
        ),
      );
      expect(find.text('No devices discovered'), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsOneWidget);

      final devices1 = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -50,
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices1,
            ),
          ),
        ),
      );
      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('WiFi'), findsOneWidget);

      final devices2 = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'AI Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          personalityData: AnonymizedVibeData(
            noisyDimensions: const {'adventure': 0.5},
            anonymizedMetrics: AnonymizedVibeMetrics(
              energy: 0.5,
              social: 0.5,
              exploration: 0.5,
            ),
            temporalContextHash: 'temporal_hash',
            vibeSignature: 'signature',
            privacyLevel: 'MAXIMUM_ANONYMIZATION',
            anonymizationQuality: 1.0,
            salt: 'salt',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices2,
            ),
          ),
        ),
      );
      expect(find.text('AI Enabled'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);

      final devices3 = [
        DiscoveredDevice(
          deviceId: 'close-device',
          deviceName: 'Close Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -30, // Strong signal = close
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices3,
            ),
          ),
        ),
      );
      expect(find.textContaining('Very Close'), findsOneWidget);
      expect(find.textContaining('-30 dBm'), findsOneWidget);

      final devices4 = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices4,
              showConnectionButton: true,
            ),
          ),
        ),
      );
      expect(find.text('Connect'), findsOneWidget);
      await tester.tap(find.text('Connect'));
      await tester.pump();
      expect(find.text('Connecting...'), findsOneWidget);

      final devices5 = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices5,
              showConnectionButton: false,
            ),
          ),
        ),
      );
      expect(find.text('Connect'), findsNothing);

      DiscoveredDevice? tappedDevice;
      final devices6 = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Tappable Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices6,
              onDeviceTap: (device) {
                tappedDevice = device;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tappable Device'));
      await tester.pumpAndSettle();
      expect(tappedDevice, isNotNull);
      expect(tappedDevice?.deviceName, equals('Tappable Device'));
    });
  });
}
