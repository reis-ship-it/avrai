import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/device_discovery_android.dart';
import 'package:avrai_network/network/device_discovery_ios.dart';

import 'package:avrai_network/network/device_discovery_stub.dart' as stub;

/// Expose the stub implementation on IO platforms so that
/// `device_discovery_factory.dart` can compile (it references `StubDeviceDiscovery`
/// regardless of platform).
typedef StubDeviceDiscovery = stub.StubDeviceDiscovery;

/// Web discovery is not available on IO platforms, but the symbol must exist
/// for compilation because it is referenced by the factory.
DeviceDiscoveryPlatform createWebDeviceDiscovery() => stub.createWebDeviceDiscovery();

/// Create Android device discovery implementation
DeviceDiscoveryPlatform createAndroidDeviceDiscovery() {
  return AndroidDeviceDiscovery();
}

/// Create iOS device discovery implementation
DeviceDiscoveryPlatform createIOSDeviceDiscovery() {
  return IOSDeviceDiscovery();
}
