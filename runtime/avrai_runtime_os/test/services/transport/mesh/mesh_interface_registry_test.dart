import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshInterfaceRegistry', () {
    test('maps discovery metadata into governed interface profiles', () {
      final registry = MeshInterfaceRegistry(cloudInterfaceAvailable: true);

      final bleProfile = registry.resolveForDevice(
        DiscoveredDevice(
          deviceId: 'peer-ble',
          deviceName: 'BLE peer',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -58,
          discoveredAt: DateTime.utc(2026, 3, 12, 12),
          metadata: const <String, dynamic>{'scan_transport': 'bluetooth'},
        ),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );
      expect(bleProfile.kind, MeshInterfaceKind.ble);
      expect(bleProfile.enabled, isTrue);
      expect(
        bleProfile.allowedPrivacyModes.contains(
          MeshTransportPrivacyMode.privateMesh,
        ),
        isTrue,
      );

      final cloudProfile = registry.cloudProfile(
        privacyMode: MeshTransportPrivacyMode.federatedCloud,
      );
      expect(cloudProfile.kind, MeshInterfaceKind.federatedCloud);
      expect(cloudProfile.enabled, isTrue);
      expect(cloudProfile.supportsCustody, isTrue);
    });

    test('disables cloud interfaces in private mesh mode', () {
      final registry = MeshInterfaceRegistry(cloudInterfaceAvailable: true);
      final cloudProfile = registry.cloudProfile(
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(cloudProfile.enabled, isFalse);
      expect(
        cloudProfile.allowsPrivacyMode(MeshTransportPrivacyMode.privateMesh),
        isFalse,
      );
    });
  });
}
