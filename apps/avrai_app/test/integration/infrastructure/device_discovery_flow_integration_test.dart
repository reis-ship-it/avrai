import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_runtime_os/ai/privacy_protection.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import '../../helpers/test_helpers.dart';

/// Device Discovery Flow Integration Tests
/// Tests device discovery and personality data extraction flow
void main() {
  group('Device Discovery Flow Integration', () {
    late DeviceDiscoveryService discoveryService;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      discoveryService = DeviceDiscoveryService();
    });

    tearDown(() {
      discoveryService.stopDiscovery();
      TestHelpers.teardownTestEnvironment();
    });

    group('Discovery Service', () {
      test('should initialize discovery service', () {
        expect(discoveryService.getDiscoveredDevices(), isEmpty);
      });

      test('should start and stop discovery', () async {
        await discoveryService.startDiscovery();

        // Discovery should be running
        final devices = discoveryService.getDiscoveredDevices();
        expect(devices, isA<List<DiscoveredDevice>>());

        discoveryService.stopDiscovery();
      });
    });

    group('Device Proximity', () {
      test('should calculate proximity from signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -50,
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, greaterThan(0.0));
        expect(proximity, lessThanOrEqualTo(1.0));
      });

      test('should handle devices with unknown signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, equals(0.5)); // Default for unknown
      });
    });

    group('Personality Data Extraction', () {
      test('should extract personality data from device', () async {
        // Create test vibe and anonymize it
        final vibe = UserVibe.fromPersonalityProfile('user1', {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.6,
        });
        final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(vibe);

        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          personalityData: anonymizedVibe,
          discoveredAt: DateTime.now(),
        );

        final extractedData =
            await discoveryService.extractPersonalityData(device);
        expect(extractedData, isNotNull);
        expect(extractedData!.noisyDimensions, isNotEmpty);
      });

      test('should return null for non-SPOTS devices', () async {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Other Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: false,
          discoveredAt: DateTime.now(),
        );

        final extractedData =
            await discoveryService.extractPersonalityData(device);
        expect(extractedData, isNull);
      });
    });

    group('Device Filtering', () {
      test('should filter SPOTS-enabled devices', () {
        final spotsDevice = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'SPOTS Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        );

        final otherDevice = DiscoveredDevice(
          deviceId: 'device2',
          deviceName: 'Other Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: false,
          discoveredAt: DateTime.now(),
        );

        expect(spotsDevice.isSpotsEnabled, isTrue);
        expect(otherDevice.isSpotsEnabled, isFalse);
      });
    });
  });
}
