// Signal Protocol Initialization Service
// Phase 14: Signal Protocol Implementation - Option 1
//
// Handles initialization of Signal Protocol services at app startup

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';

/// Signal Protocol Initialization Service
///
/// Handles initialization of Signal Protocol at app startup.
/// Should be called during app initialization to ensure Signal Protocol is ready.
///
/// Phase 14: Signal Protocol Implementation - Option 1
class SignalProtocolInitializationService {
  static const String _logName = 'SignalProtocolInitializationService';

  final SignalProtocolService _signalProtocol;
  final SignalPlatformBridgeBindings? _platformBridge;
  final SignalRustWrapperBindings? _rustWrapper;
  final SignalFFIStoreCallbacks? _storeCallbacks;
  final bool _skipProductionVerification;

  bool _initialized = false;

  SignalProtocolInitializationService({
    required SignalProtocolService signalProtocol,
    SignalPlatformBridgeBindings? platformBridge,
    SignalRustWrapperBindings? rustWrapper,
    SignalFFIStoreCallbacks? storeCallbacks,
    bool skipProductionVerification = false,
  })  : _signalProtocol = signalProtocol,
        _platformBridge = platformBridge,
        _rustWrapper = rustWrapper,
        _storeCallbacks = storeCallbacks,
        _skipProductionVerification = skipProductionVerification;

  /// Initialize Signal Protocol
  ///
  /// Should be called during app startup to:
  /// - Initialize platform bridge (C bridge for callbacks)
  /// - Initialize Rust wrapper bindings
  /// - Initialize store callbacks
  /// - Initialize FFI bindings
  /// - Generate/load identity keys
  /// - Upload prekey bundles to key server
  ///
  /// **Note:** This is a non-blocking operation. Signal Protocol will
  /// work with fallback to AES-256-GCM if initialization fails.
  ///
  /// **Initialization Order (CRITICAL):**
  /// 1. Signal Protocol Service (loads libsignal_ffi.dylib - BASE LIBRARY FIRST)
  /// 2. Platform Bridge (loads callback_bridge.dylib)
  /// 3. Rust Wrapper (loads wrapper.dylib - may depend on libsignal_ffi.dylib)
  /// 4. Store Callbacks (registers callbacks with platform bridge and Rust wrapper)
  ///
  /// **Why this order matters:**
  /// - Base library (libsignal_ffi.dylib) must be loaded first
  /// - Dependent libraries (wrapper.dylib) can then resolve @loader_path dependencies
  /// - During unload, libraries are unloaded in reverse order (prevents SIGABRT)
  Future<void> initialize() async {
    if (_initialized) {
      developer.log('Signal Protocol already initialized', name: _logName);
      return;
    }

    try {
      developer.log('Initializing Signal Protocol...', name: _logName);

      // Step 1: Initialize Signal Protocol service FIRST (loads libsignal_ffi.dylib)
      // This MUST be first because other libraries may depend on it
      // The base library must be loaded before dependent libraries
      developer.log(
          'Initializing Signal Protocol FFI bindings (base library)...',
          name: _logName);
      await _signalProtocol.initialize();
      developer.log('✅ Signal Protocol FFI bindings initialized',
          name: _logName);

      // Step 2: Initialize Platform Bridge (loads callback_bridge.dylib)
      // This loads the C bridge library that creates function pointers
      if (_platformBridge != null) {
        try {
          if (!_platformBridge.isInitialized) {
            developer.log('Initializing platform bridge...', name: _logName);
            await _platformBridge.initialize();
            developer.log('✅ Platform bridge initialized', name: _logName);
          }
        } catch (e, st) {
          developer.log(
            '⚠️ Platform bridge initialization failed: $e',
            name: _logName,
            error: e,
            stackTrace: st,
          );
          // Continue - might not be needed on all platforms
        }
      }

      // Step 3: Initialize Rust Wrapper (loads wrapper.dylib)
      // This loads the Rust wrapper library (may depend on libsignal_ffi.dylib)
      if (_rustWrapper != null) {
        try {
          if (!_rustWrapper.isInitialized) {
            developer.log('Initializing Rust wrapper...', name: _logName);
            await _rustWrapper.initialize();
            developer.log('✅ Rust wrapper initialized', name: _logName);
          }
        } catch (e, st) {
          developer.log(
            '⚠️ Rust wrapper initialization failed: $e',
            name: _logName,
            error: e,
            stackTrace: st,
          );
          // Continue - might not be needed on all platforms
        }
      }

      // Step 4: Initialize Store Callbacks (must be after platform bridge and Rust wrapper)
      // This registers callbacks with the platform bridge and Rust wrapper
      if (_storeCallbacks != null) {
        try {
          if (!_storeCallbacks.isInitialized) {
            developer.log('Initializing store callbacks...', name: _logName);
            await _storeCallbacks.initialize();
            developer.log('✅ Store callbacks initialized', name: _logName);
          }
        } catch (e, st) {
          developer.log(
            '⚠️ Store callbacks initialization failed: $e',
            name: _logName,
            error: e,
            stackTrace: st,
          );
          // Continue - might not be needed on all platforms
        }
      }

      // Note: Prekey bundle upload will be handled on-demand when encryptMessage
      // is called for the first time with a recipient. No need to upload here
      // since we don't have a user context yet.

      _initialized = true;
      developer.log('✅ Signal Protocol initialized successfully',
          name: _logName);

      // Production verification: Quick smoke test to verify library works
      // Skip in tests to avoid triggering crashes during verification
      if (!_skipProductionVerification) {
        await _verifyProductionReadiness();
      } else {
        developer.log('Skipping production verification (test mode)',
            name: _logName);
      }
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ Signal Protocol initialization failed, will use AES-256-GCM fallback: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Continue without Signal Protocol (fallback to AES-256-GCM)
      // This is expected if FFI bindings are not yet implemented
      _initialized = false;
    }
  }

  /// Check if Signal Protocol is initialized and ready
  bool get isInitialized => _initialized && _signalProtocol.isInitialized;

  /// Re-initialize Signal Protocol (for recovery scenarios)
  Future<void> reinitialize() async {
    _initialized = false;
    await initialize();
  }

  /// Verify Signal Protocol production readiness
  ///
  /// Performs a quick smoke test to ensure the library works correctly
  /// in production. This helps catch issues early at app startup.
  Future<void> _verifyProductionReadiness() async {
    try {
      developer.log('Verifying Signal Protocol production readiness...',
          name: _logName);

      // Quick smoke test: Try to encrypt a message to verify library works
      // This exercises the full stack: FFI bindings, key management, session management
      final testMessage = [72, 101, 108, 108, 111]; // "Hello"
      try {
        // Try to encrypt (will fail if library is broken, but won't crash)
        await _signalProtocol.encryptMessage(
          plaintext: Uint8List.fromList(testMessage),
          recipientId: 'production-verification-test',
        );
        developer.log(
          '✅ Signal Protocol production verification passed (encryption works)',
          name: _logName,
        );
      } catch (e) {
        // Encryption might fail due to missing session (expected), but library should still work
        // The fact that we got here means the library loaded and initialized correctly
        if (e.toString().contains('session') ||
            e.toString().contains('prekey')) {
          // Expected error - library works, just no session established
          developer.log(
            '✅ Signal Protocol production verification passed (library works, session not established)',
            name: _logName,
          );
        } else {
          // Unexpected error - log but don't fail
          developer.log(
            '⚠️ Signal Protocol production verification: Unexpected error: $e',
            name: _logName,
          );
        }
      }
    } catch (e, stackTrace) {
      // Non-fatal: Log but don't throw - app can continue with fallback encryption
      developer.log(
        '⚠️ Signal Protocol production verification failed: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      developer.log(
        'Signal Protocol will use fallback encryption (AES-256-GCM)',
        name: _logName,
      );
    }
  }
}
