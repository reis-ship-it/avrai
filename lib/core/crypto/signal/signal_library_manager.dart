// Signal Protocol Library Manager
// Phase 14: Unified Library Management with Process-Level Loading for iOS/macOS
//
// Centralizes all native library loading and lifecycle management.
// Uses process-level loading (DynamicLibrary.process()) for iOS/macOS
// to reduce SIGABRT crashes during test finalization.

import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';
import 'package:avrai/core/crypto/signal/signal_types.dart';

/// Signal Protocol Library Manager
/// 
/// Centralized manager for all Signal Protocol native libraries.
/// Provides process-level loading for iOS/macOS to reduce SIGABRT crashes.
/// 
/// **Benefits:**
/// - Single point of control for library lifecycle
/// - Process-level loading on iOS/macOS (OS manages lifecycle)
/// - Shared library instances across all services
/// - Better debugging and monitoring
/// 
/// **Production Lifecycle:**
/// - Registered as singleton in dependency injection
/// - Lives for app's lifetime
/// - Never disposed in production
/// - Library unloaded by OS on app termination
/// 
/// **Test Lifecycle:**
/// - Created per test
/// - May be disposed in tearDown
/// - SIGABRT during finalization is expected (OS-level cleanup)
class SignalLibraryManager {
  static const String _logName = 'SignalLibraryManager';
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  
  // Singleton instance
  static final SignalLibraryManager _instance = SignalLibraryManager._internal();
  factory SignalLibraryManager() => _instance;
  SignalLibraryManager._internal();
  
  // Shared library instances (loaded once, shared across all services)
  DynamicLibrary? _mainLib;
  DynamicLibrary? _wrapperLib;
  DynamicLibrary? _bridgeLib;
  
  // Static references to prevent GC during test finalization
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticMainLib;
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticWrapperLib;
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticBridgeLib;
  
  /// Get the main Signal Protocol library (libsignal_ffi)
  /// 
  /// Uses process-level loading for iOS/macOS to reduce SIGABRT crashes.
  /// 
  /// **iOS/macOS:** Uses `DynamicLibrary.process()` (framework embedded)
  /// **Other platforms:** Uses `DynamicLibrary.open()` (explicit loading)
  DynamicLibrary getMainLibrary() {
    if (_mainLib != null) {
      return _mainLib!;
    }
    
    try {
      if (Platform.isIOS) {
        // iOS: vendored via SignalNative CocoaPod.
        // Prefer explicit framework loading so symbols are available even if
        // dyld hasn't already loaded it into the global namespace.
        developer.log('Loading main library (iOS)', name: _logName);
        try {
          _mainLib = DynamicLibrary.open('SignalFfi.framework/SignalFfi');
        } catch (e) {
          developer.log(
            'Could not open SignalFfi.framework directly, falling back to process(): $e',
            name: _logName,
          );
          _mainLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        // macOS:
        // - In production apps, we may have a dylib alongside the executable (explicit open)
        //   OR an embedded framework (process-level).
        // - In Flutter test subprocesses, explicit dylib loading has proven to cause
        //   flaky SIGABRT crashes during teardown/finalization, so we avoid it.
        developer.log(
          'Loading main library (macOS)${_isFlutterTest ? " [flutter_test]" : ""}',
          name: _logName,
        );
        if (_isFlutterTest) {
          _mainLib = DynamicLibrary.process();
        } else {
          try {
            final currentDir = Directory.current.path;
            final libPath = '$currentDir/native/signal_ffi/macos/libsignal_ffi.dylib';
            final libFile = File(libPath);
            if (libFile.existsSync()) {
              _mainLib = DynamicLibrary.open(libPath);
            } else {
              _mainLib = DynamicLibrary.process();
            }
          } catch (e) {
            developer.log(
              'Could not load main library from project path, using process-level loading: $e',
              name: _logName,
            );
            _mainLib = DynamicLibrary.process();
          }
        }
      } else if (Platform.isAndroid) {
        // Android must load the C-FFI shared library (not the JNI shim).
        _mainLib = DynamicLibrary.open('libsignal_ffi.so');
      } else if (Platform.isLinux) {
        _mainLib = DynamicLibrary.open('libsignal_ffi.so');
      } else if (Platform.isWindows) {
        _mainLib = DynamicLibrary.open('signal_ffi.dll');
      } else {
        throw SignalProtocolException('Unsupported platform: ${Platform.operatingSystem}');
      }
      
      // Keep static reference to prevent GC
      _staticMainLib = _mainLib;
      
      developer.log('✅ Main library loaded successfully', name: _logName);
      return _mainLib!;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load main library: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw SignalProtocolException('Failed to load main Signal Protocol library: $e');
    }
  }
  
  /// Get the wrapper library (libsignal_ffi_wrapper)
  /// 
  /// Uses process-level loading for iOS/macOS.
  /// 
  /// **Note:** For macOS, wrapper is still loaded as dylib (not framework yet).
  /// This can be migrated to framework later if needed.
  DynamicLibrary getWrapperLibrary() {
    if (_wrapperLib != null) {
      return _wrapperLib!;
    }
    
    try {
      if (Platform.isIOS) {
        // iOS: vendored via SignalNative CocoaPod.
        developer.log('Loading wrapper library (iOS)', name: _logName);
        try {
          _wrapperLib =
              DynamicLibrary.open('SignalFfiWrapper.framework/SignalFfiWrapper');
        } catch (e) {
          developer.log(
            'Could not open SignalFfiWrapper.framework directly, falling back to process(): $e',
            name: _logName,
          );
          _wrapperLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        // macOS:
        // - Prefer explicit dylib loading in apps/dev.
        // - Avoid explicit loading in Flutter tests to reduce SIGABRT teardown crashes.
        developer.log(
          'Loading wrapper library (macOS)${_isFlutterTest ? " [flutter_test]" : ""}',
          name: _logName,
        );
        if (_isFlutterTest) {
          _wrapperLib = DynamicLibrary.process();
        } else {
          try {
            final currentDir = Directory.current.path;
            final libPath = '$currentDir/native/signal_ffi/macos/libsignal_ffi_wrapper.dylib';
            final libFile = File(libPath);
            if (libFile.existsSync()) {
              _wrapperLib = DynamicLibrary.open(libPath);
            } else {
              _wrapperLib = DynamicLibrary.open('libsignal_ffi_wrapper.dylib');
            }
          } catch (e) {
            developer.log(
              'Could not load wrapper from project path, trying system path: $e',
              name: _logName,
            );
            _wrapperLib = DynamicLibrary.open('libsignal_ffi_wrapper.dylib');
          }
        }
      } else if (Platform.isAndroid) {
        _wrapperLib = DynamicLibrary.open('libsignal_ffi_wrapper.so');
      } else if (Platform.isLinux) {
        _wrapperLib = DynamicLibrary.open('libsignal_ffi_wrapper.so');
      } else if (Platform.isWindows) {
        _wrapperLib = DynamicLibrary.open('signal_ffi_wrapper.dll');
      } else {
        throw SignalProtocolException('Unsupported platform: ${Platform.operatingSystem}');
      }
      
      // Keep static reference to prevent GC
      _staticWrapperLib = _wrapperLib;
      
      developer.log('✅ Wrapper library loaded successfully', name: _logName);
      return _wrapperLib!;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load wrapper library: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw SignalProtocolException('Failed to load wrapper library: $e');
    }
  }
  
  /// Get the bridge library (libsignal_callback_bridge)
  /// 
  /// Uses process-level loading for iOS/macOS.
  /// 
  /// **Note:** For macOS, bridge is still loaded as dylib (not framework yet).
  /// This can be migrated to framework later if needed.
  DynamicLibrary getBridgeLibrary() {
    if (_bridgeLib != null) {
      return _bridgeLib!;
    }
    
    try {
      if (Platform.isIOS) {
        // Same rationale as wrapper library: symbols are linked into SignalNative.
        developer.log('Loading bridge library (iOS)', name: _logName);
        try {
          _bridgeLib =
              DynamicLibrary.open('SignalNative.framework/SignalNative');
        } catch (e) {
          developer.log(
            'Could not open SignalNative.framework directly, falling back to process(): $e',
            name: _logName,
          );
          _bridgeLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        // macOS:
        // - Prefer explicit dylib loading in apps/dev.
        // - Avoid explicit loading in Flutter tests to reduce SIGABRT teardown crashes.
        developer.log(
          'Loading bridge library (macOS)${_isFlutterTest ? " [flutter_test]" : ""}',
          name: _logName,
        );
        if (_isFlutterTest) {
          _bridgeLib = DynamicLibrary.process();
        } else {
          try {
            final currentDir = Directory.current.path;
            final libPath = '$currentDir/native/signal_ffi/macos/libsignal_callback_bridge.dylib';
            final libFile = File(libPath);
            if (libFile.existsSync()) {
              _bridgeLib = DynamicLibrary.open(libPath);
            } else {
              _bridgeLib = DynamicLibrary.open('libsignal_callback_bridge.dylib');
            }
          } catch (e) {
            developer.log(
              'Could not load bridge from project path, trying system path: $e',
              name: _logName,
            );
            _bridgeLib = DynamicLibrary.open('libsignal_callback_bridge.dylib');
          }
        }
      } else if (Platform.isAndroid) {
        _bridgeLib = DynamicLibrary.open('libsignal_callback_bridge.so');
      } else if (Platform.isLinux) {
        _bridgeLib = DynamicLibrary.open('libsignal_callback_bridge.so');
      } else if (Platform.isWindows) {
        _bridgeLib = DynamicLibrary.open('signal_callback_bridge.dll');
      } else {
        throw SignalProtocolException('Unsupported platform: ${Platform.operatingSystem}');
      }
      
      // Keep static reference to prevent GC
      _staticBridgeLib = _bridgeLib;
      
      developer.log('✅ Bridge library loaded successfully', name: _logName);
      return _bridgeLib!;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load bridge library: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw SignalProtocolException('Failed to load bridge library: $e');
    }
  }
  
  /// Check if all libraries are loaded
  bool get areLibrariesLoaded => 
      _mainLib != null && _wrapperLib != null && _bridgeLib != null;
  
  /// Dispose all libraries (test-only, production never calls this)
  /// 
  /// **Note:** In production, libraries live for app lifetime.
  /// This is only for test cleanup.
  void dispose() {
    developer.log('Disposing Signal Library Manager', name: _logName);
    _mainLib = null;
    _wrapperLib = null;
    _bridgeLib = null;
    // Note: Static references remain to prevent GC during test finalization
  }
}
