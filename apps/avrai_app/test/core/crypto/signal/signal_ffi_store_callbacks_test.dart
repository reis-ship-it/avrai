// Unit tests for Signal Protocol FFI Store Callbacks
// Phase 14: Signal Protocol Implementation - Option 1
//
// Tests store callback creation and basic functionality

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SignalFFIStoreCallbacks', () {
    late SignalFFIBindings ffiBindings;
    SignalFFIStoreCallbacks? storeCallbacks;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() async {
      // Set up mock FlutterSecureStorage to avoid MissingPluginException
      mockSecureStorage = MockFlutterSecureStorage();

      // In-memory storage to track keys
      final Map<String, String> keyStorage = {};

      // Set up read to return stored value or null
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return keyStorage[key];
      });

      // Set up write to store value
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        keyStorage[key] = value;
      });

      // Set up delete to remove key
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        keyStorage.remove(key);
      });

      // Don't load libraries in setUp - only load when individual tests need them
      // This prevents crashes in tests that don't need libraries
      ffiBindings = SignalFFIBindings();
      storeCallbacks = null;
    });

    /// Helper to initialize libraries for tests that need them
    Future<bool> initializeLibraries() async {
      try {
        await ffiBindings.initialize();
        if (!ffiBindings.isInitialized) {
          return false;
        }
      } catch (e) {
        // Libraries not available
        if (e is SignalProtocolException) {
          return false;
        }
        rethrow;
      }

      // Initialize key manager and session manager
      final km = SignalKeyManager(
        secureStorage: mockSecureStorage,
        ffiBindings: ffiBindings,
      );

      final sm = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: mockSecureStorage),
        ffiBindings: ffiBindings,
        keyManager: km,
      );

      // Try to initialize wrapper library (optional - may not be built yet)
      try {
        await ffiBindings.initializeWrapperLibrary();
      } catch (e) {
        // Wrapper library not available
        return false;
      }

      // Create required dependencies for store callbacks
      final rustWrapper = SignalRustWrapperBindings();
      final platformBridge = SignalPlatformBridgeBindings();

      // Try to initialize them (may fail if libraries not available)
      try {
        await rustWrapper.initialize();
        await platformBridge.initialize();
      } catch (e) {
        // Dependencies not available
        return false;
      }

      storeCallbacks = SignalFFIStoreCallbacks(
        keyManager: km,
        sessionManager: sm,
        ffiBindings: ffiBindings,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
      );

      await storeCallbacks!.initialize();

      return true;
    }

    tearDown(() async {
      // NOTE: We intentionally do NOT dispose native-backed Signal components in unit tests.
      //
      // Disposal paths that touch native libraries/callbacks can cause SIGABRT during
      // finalization even when tests pass. Unit tests should avoid native teardown for
      // reliability; the OS will reclaim resources when the test process exits.
    });

    test('should create session store struct', () async {
      // Load libraries only for this test
      if (!await initializeLibraries()) {
        return; // Libraries not available - skip test
      }

      final sessionStore = storeCallbacks!.createSessionStore();

      expect(sessionStore, isNotNull);
      expect(sessionStore.address, isNot(equals(0)));

      // Note: Callbacks are set to nullptr due to Dart FFI limitations
      // They will be implemented using C wrapper functions
      // See PHASE_14_STORE_CALLBACKS_LIMITATION.md

      // Clean up
      malloc.free(sessionStore);
    });

    test('should create identity key store struct', () async {
      // Load libraries only for this test
      if (!await initializeLibraries()) {
        return; // Libraries not available - skip test
      }

      final identityKeyStore = storeCallbacks!.createIdentityKeyStore();

      expect(identityKeyStore, isNotNull);
      expect(identityKeyStore.address, isNot(equals(0)));

      // Note: Callbacks are set to nullptr due to Dart FFI limitations
      // They will be implemented using C wrapper functions
      // See PHASE_14_STORE_CALLBACKS_LIMITATION.md

      // Clean up
      malloc.free(identityKeyStore);
    });

    test('should dispose resources correctly', () async {
      // Load libraries only for this test
      if (!await initializeLibraries()) {
        return; // Libraries not available - skip test
      }

      final sessionStore = storeCallbacks!.createSessionStore();
      final identityKeyStore = storeCallbacks!.createIdentityKeyStore();

      // Clean up allocated structs
      malloc.free(sessionStore);
      malloc.free(identityKeyStore);

      // Dispose should not throw
      expect(() => storeCallbacks!.dispose(), returnsNormally);
    });
  });
}
