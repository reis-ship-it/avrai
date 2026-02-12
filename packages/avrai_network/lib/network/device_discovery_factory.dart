import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:avrai_network/network/device_discovery.dart';

// Platform selection via conditional import.
// - Web: device_discovery_web.dart
// - Mobile/desktop (dart.library.io): device_discovery_io.dart
// - Fallback: device_discovery_stub.dart
import 'device_discovery_stub.dart'
    if (dart.library.io) 'device_discovery_io.dart'
    if (dart.library.html) 'device_discovery_web.dart';

/// Factory for creating platform-specific device discovery implementations
class DeviceDiscoveryFactory {
  /// Creates the appropriate platform-specific device discovery implementation
  ///
  /// In test environments (no dart.library.io or dart.library.html), this will
  /// use the stub implementation from device_discovery_stub.dart.
  ///
  /// On mobile platforms (dart.library.io available), platform-specific
  /// implementations should be instantiated directly or via dependency injection.
  ///
  /// On web (dart.library.html available), WebDeviceDiscovery should be instantiated
  /// directly or via dependency injection.
  ///
  /// Note: This factory always returns StubDeviceDiscovery to ensure testability.
  /// Production code should use platform-specific implementations via dependency
  /// injection or direct instantiation where appropriate.
  static DeviceDiscoveryPlatform? createPlatformDiscovery({
    bool allowStubFallback = true,
  }) {
    // Web path (conditional import provides createWebDeviceDiscovery()).
    if (kIsWeb) {
      return createWebDeviceDiscovery();
    }

    // IO path (conditional import provides createAndroidDeviceDiscovery/createIOSDeviceDiscovery()).
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return createAndroidDeviceDiscovery();
      case TargetPlatform.iOS:
        return createIOSDeviceDiscovery();
      default:
        // Desktop/unsupported platforms: return stub unless explicitly disabled.
        return allowStubFallback ? StubDeviceDiscovery() : null;
    }
  }

  /// Checks if device discovery is supported on the current platform
  static bool isPlatformSupported() {
    final platform = createPlatformDiscovery();
    return platform != null && platform.isSupported();
  }
}
