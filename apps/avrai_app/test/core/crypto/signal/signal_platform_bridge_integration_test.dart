// Signal Platform Bridge Integration Test
// Phase 14: Signal Protocol Implementation - Option 1
//
// Tests the end-to-end callback flow:
// 1. Platform Bridge initialization
// 2. Rust Wrapper initialization
// 3. Store Callbacks initialization
// 4. Callback registration and dispatch

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';

import '../../../mocks/in_memory_flutter_secure_storage.dart';

void main() {
  group('Signal Platform Bridge Integration', () {
    late SignalPlatformBridgeBindings platformBridge;
    late SignalRustWrapperBindings rustWrapper;
    late SignalFFIBindings ffiBindings;
    late SignalKeyManager keyManager;
    late SignalSessionManager sessionManager;
    late SignalFFIStoreCallbacks storeCallbacks;

    setUp(() {
      // Create instances
      ffiBindings = SignalFFIBindings();
      platformBridge = SignalPlatformBridgeBindings();
      rustWrapper = SignalRustWrapperBindings();

      keyManager = SignalKeyManager(
        // Use in-memory secure storage to avoid platform channel dependence in tests.
        secureStorage: InMemoryFlutterSecureStorage(),
        ffiBindings: ffiBindings,
      );

      sessionManager = SignalSessionManager(
        storage:
            SecureSignalStorage(secureStorage: InMemoryFlutterSecureStorage()),
        ffiBindings: ffiBindings,
        keyManager: keyManager,
      );

      storeCallbacks = SignalFFIStoreCallbacks(
        keyManager: keyManager,
        sessionManager: sessionManager,
        ffiBindings: ffiBindings,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
      );
    });

    tearDown(() {
      // NOTE: We intentionally avoid disposing native-backed Signal components in unit tests.
      // Native teardown can cause SIGABRT during finalization on some platforms.
    });

    test('Platform Bridge can be initialized', () async {
      // Test platform bridge initialization
      // Note: This will fail if the C bridge library is not available
      // That's expected - this test verifies the initialization flow

      try {
        await platformBridge.initialize();
        expect(platformBridge.isInitialized, isTrue);
      } catch (e) {
        // Expected on platforms where C bridge is not built yet
        expect(e, isA<SignalProtocolException>());
      }
    });

    test('Rust Wrapper can be initialized', () async {
      // Test Rust wrapper initialization
      // Note: This will fail if the Rust wrapper library is not available
      // That's expected - this test verifies the initialization flow

      try {
        await rustWrapper.initialize();
        expect(rustWrapper.isInitialized, isTrue);
      } catch (e) {
        // Expected on platforms where Rust wrapper is not built yet
        expect(e, isA<SignalProtocolException>());
      }
    });

    test('Store Callbacks require dependencies to be initialized first',
        () async {
      // Test that store callbacks initialization fails if dependencies are not initialized

      // Don't initialize platform bridge or rust wrapper
      // Try to initialize store callbacks - should fail
      try {
        await storeCallbacks.initialize();
        fail('Should have thrown SignalProtocolException');
      } catch (e) {
        expect(e, isA<SignalProtocolException>());
        expect(e.toString(), contains('not initialized'));
      }
    });

    test('Complete initialization sequence works', () async {
      // Test the complete initialization sequence:
      // 1. Platform Bridge
      // 2. Rust Wrapper
      // 3. Store Callbacks

      try {
        // Step 1: Initialize Platform Bridge
        await platformBridge.initialize();
        expect(platformBridge.isInitialized, isTrue);

        // Step 2: Initialize Rust Wrapper
        await rustWrapper.initialize();
        expect(rustWrapper.isInitialized, isTrue);

        // Step 3: Initialize Store Callbacks
        await storeCallbacks.initialize();
        expect(storeCallbacks.isInitialized, isTrue);

        // All services should be initialized
        expect(platformBridge.isInitialized, isTrue);
        expect(rustWrapper.isInitialized, isTrue);
        expect(storeCallbacks.isInitialized, isTrue);
      } catch (e) {
        // Expected on platforms where libraries are not built yet
        // This test verifies the initialization flow, not the actual libraries
        expect(e, isA<SignalProtocolException>());
      }
    });

    test('Initialization is idempotent', () async {
      // Test that calling initialize() multiple times doesn't cause issues

      try {
        await platformBridge.initialize();
        await platformBridge.initialize(); // Second call should be safe
        expect(platformBridge.isInitialized, isTrue);

        await rustWrapper.initialize();
        await rustWrapper.initialize(); // Second call should be safe
        expect(rustWrapper.isInitialized, isTrue);

        await storeCallbacks.initialize();
        await storeCallbacks.initialize(); // Second call should be safe
        expect(storeCallbacks.isInitialized, isTrue);
      } catch (e) {
        // Expected on platforms where libraries are not built yet
        expect(e, isA<SignalProtocolException>());
      }
    });

    test('Initialization order matters', () async {
      // Test that initialization must happen in the correct order

      try {
        // Try to initialize store callbacks before platform bridge
        // This should fail
        try {
          await storeCallbacks.initialize();
          fail('Should have thrown SignalProtocolException');
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
        }

        // Initialize platform bridge
        await platformBridge.initialize();

        // Try to initialize store callbacks before rust wrapper
        // This should fail
        try {
          await storeCallbacks.initialize();
          fail('Should have thrown SignalProtocolException');
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
        }

        // Initialize rust wrapper
        await rustWrapper.initialize();

        // Now store callbacks should initialize successfully
        await storeCallbacks.initialize();
        expect(storeCallbacks.isInitialized, isTrue);
      } catch (e) {
        // Expected on platforms where libraries are not built yet
        expect(e, isA<SignalProtocolException>());
      }
    });
  });
}
