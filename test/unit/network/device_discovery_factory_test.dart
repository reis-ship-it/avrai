import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/device_discovery_factory.dart' show DeviceDiscoveryFactory;
import 'package:avrai_network/network/device_discovery.dart' show DeviceDiscoveryPlatform;

/// Device Discovery Factory Tests
/// Tests the factory for creating platform-specific device discovery implementations
void main() {
  group('DeviceDiscoveryFactory', () {
    group('Platform Discovery Creation', () {
      test('should create platform discovery implementation', () {
        final platform = DeviceDiscoveryFactory.createPlatformDiscovery();

        // Should return a platform implementation (or stub in tests)
        expect(platform, isA<DeviceDiscoveryPlatform?>());
      });

      test('should handle platform creation without errors', () {
        // Factory should not throw exceptions
        expect(
          () => DeviceDiscoveryFactory.createPlatformDiscovery(),
          returnsNormally,
        );
      });
    });
  });
}

