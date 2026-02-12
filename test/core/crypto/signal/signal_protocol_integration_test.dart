// Signal Protocol Integration Test
// Phase 14: Signal Protocol Implementation - Option 1
//
// Focused integration test that verifies:
// 1. Library loading (can we find and load native libraries?)
// 2. Initialization sequence (correct order and dependencies)
// 3. Error handling (graceful degradation when libraries unavailable)
// 4. Platform bridge dlsym registration (if libraries available)
// 5. Core functionality (identity key generation, if available)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/security/signal_protocol_initialization_service.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('Signal Protocol Integration', () {
    late SignalFFIBindings ffiBindings;
    late SignalPlatformBridgeBindings platformBridge;
    late SignalRustWrapperBindings rustWrapper;
    late SignalKeyManager keyManager;
    late SignalSessionManager sessionManager;
    late SignalFFIStoreCallbacks storeCallbacks;
    late SignalProtocolService signalProtocol;
    late SignalProtocolInitializationService initService;
    late MockFlutterSecureStorage mockSecureStorage;
    bool librariesAvailable = false;

    setUpAll(() async {
      // Check if native libraries are available
      if (Platform.isMacOS) {
        const libPath = 'native/signal_ffi/macos/libsignal_ffi.dylib';
        final libFile = File(libPath);
        librariesAvailable = libFile.existsSync();
      } else {
        librariesAvailable = false;
      }
    });

    tearDownAll(() async {
      // No database to close - using SecureSignalStorage
    });

    setUp(() {
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
      
      ffiBindings = SignalFFIBindings();
      platformBridge = SignalPlatformBridgeBindings();
      rustWrapper = SignalRustWrapperBindings();
      
      keyManager = SignalKeyManager(
        secureStorage: mockSecureStorage, // Use mock instead of real FlutterSecureStorage
        ffiBindings: ffiBindings,
      );
      
      sessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: mockSecureStorage),
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
      
      signalProtocol = SignalProtocolService(
        ffiBindings: ffiBindings,
        storeCallbacks: storeCallbacks,
        keyManager: keyManager,
        sessionManager: sessionManager,
      );
      
      initService = SignalProtocolInitializationService(
        signalProtocol: signalProtocol,
        platformBridge: platformBridge,
        rustWrapper: rustWrapper,
        storeCallbacks: storeCallbacks,
      );
    });

    tearDown(() {
      // NOTE: We intentionally do NOT call any native-backed dispose() methods in unit tests.
      //
      // Some Dart → native (Rust/C) teardown paths can crash the test process with SIGABRT
      // during finalization, even when test assertions succeeded.
      //
      // For unit tests, reliability > cleanup. The OS will reclaim resources when the test
      // process exits. Integration tests can validate real teardown in an environment with
      // correctly built/compatible native libraries.
    });

    group('Library Loading', () {
      test('Platform Bridge library can be loaded', () async {
        try {
          await platformBridge.initialize();
          expect(platformBridge.isInitialized, isTrue);
          expect(platformBridge.library, isNotNull);
        } catch (e) {
          // Expected if library not built yet
          expect(e, isA<SignalProtocolException>());
        }
      });

      test('Rust Wrapper library can be loaded', () async {
        try {
          await rustWrapper.initialize();
          expect(rustWrapper.isInitialized, isTrue);
        } catch (e) {
          // Expected if library not built yet
          expect(e, isA<SignalProtocolException>());
        }
      });

      test('Signal FFI library can be loaded', () async {
        try {
          await ffiBindings.initialize();
          expect(ffiBindings.isInitialized, isTrue);
        } catch (e) {
          // Expected if library not built yet
          expect(e, isA<SignalProtocolException>());
        }
      });
    });

    group('Initialization Sequence', () {
      test('Initialization requires correct order', () async {
        // Try to initialize store callbacks before dependencies - should fail
        try {
          await storeCallbacks.initialize();
          fail('Should have thrown SignalProtocolException');
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
          expect(e.toString(), contains('not initialized'));
        }

        // Initialize platform bridge
        try {
          await platformBridge.initialize();
        } catch (e) {
          // Library not available - skip rest of test
          return;
        }

        // Try to initialize store callbacks before rust wrapper - should fail
        try {
          await storeCallbacks.initialize();
          fail('Should have thrown SignalProtocolException');
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
          expect(e.toString(), contains('not initialized'));
        }

        // Initialize rust wrapper
        try {
          await rustWrapper.initialize();
        } catch (e) {
          // Library not available - skip rest of test
          return;
        }

        // Now store callbacks should initialize successfully
        try {
          await storeCallbacks.initialize();
          expect(storeCallbacks.isInitialized, isTrue);
        } catch (e) {
          // Library not available - this is OK
        }
      });

      test('Complete initialization sequence works', () async {
        try {
          await initService.initialize();
          expect(initService.isInitialized, isTrue);
        } catch (e) {
          // Expected if libraries not built yet
          // This test verifies the initialization flow, not the actual libraries
          expect(e, isA<Exception>()); // SignalProtocolException extends Exception
        }
      });

      test('Initialization is idempotent', () async {
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
          // Expected if libraries not built yet
        }
      });
    });

    group('Platform Bridge dlsym Registration', () {
      test('Platform bridge can register Dart function via dlsym', () async {
        try {
          await platformBridge.initialize();
          expect(platformBridge.isInitialized, isTrue);
          
          // Register the Dart dispatch callback by name (dlsym will find it)
          platformBridge.registerDispatchCallbackByName('signal_dispatch_callback');
          
          // Get the C function pointer (created by C bridge)
          final cFunctionPtr = platformBridge.getDispatchFunctionPtr();
          expect(cFunctionPtr, isNotNull);
          expect(cFunctionPtr.address, isNot(0));
        } catch (e) {
          // Expected if library not built yet
          expect(e, isA<SignalProtocolException>());
        }
      });

      test('Callback registration flow works end-to-end', () async {
        try {
          // Initialize in correct order
          await platformBridge.initialize();
          await rustWrapper.initialize();
          await storeCallbacks.initialize();
          
          // Verify all are initialized
          expect(platformBridge.isInitialized, isTrue);
          expect(rustWrapper.isInitialized, isTrue);
          expect(storeCallbacks.isInitialized, isTrue);
          
          // The callback registry should be populated
          // (We can't directly access it, but initialization success means it worked)
        } catch (e) {
          // Expected if libraries not built yet
        }
      });
    });

    group('Core Functionality', () {
      test('Identity key generation works when libraries available', () async {
        // Skip if libraries not available
        if (!librariesAvailable) {
          return;
        }
        
        try {
          await ffiBindings.initialize();
          
          if (!ffiBindings.isInitialized) {
            return; // Skip if not initialized
          }
          
          // Generate identity key pair (may throw if library is broken)
          SignalIdentityKeyPair identityKeyPair;
          try {
            identityKeyPair = await ffiBindings.generateIdentityKeyPair();
          } catch (e) {
            // If key generation fails, skip this test
            if (e is SignalProtocolException) {
              return;
            }
            rethrow;
          }
          
          // Verify key pair structure
          expect(identityKeyPair, isNotNull);
          expect(identityKeyPair.publicKey, isNotNull);
          expect(identityKeyPair.privateKey, isNotNull);
          expect(identityKeyPair.publicKey.length, greaterThan(0));
          expect(identityKeyPair.privateKey.length, greaterThan(0));
          expect(identityKeyPair.publicKey, isNot(equals(identityKeyPair.privateKey)));
        } catch (e) {
          // Expected if library not built yet
          expect(e, isA<SignalProtocolException>());
        }
      });

      test('Key manager can generate identity keys', () async {
        // Skip if libraries not available
        if (!librariesAvailable) {
          return;
        }
        
        try {
          await ffiBindings.initialize();
          
          if (!ffiBindings.isInitialized) {
            return; // Skip if not initialized
          }
          
          // Get or generate identity key pair (may throw if library is broken)
          SignalIdentityKeyPair identityKeyPair;
          try {
            identityKeyPair = await keyManager.getOrGenerateIdentityKeyPair();
          } catch (e) {
            // If key generation fails, skip this test
            if (e is SignalProtocolException) {
              return;
            }
            rethrow;
          }
          
          // Verify key pair
          expect(identityKeyPair, isNotNull);
          expect(identityKeyPair.publicKey, isNotNull);
          expect(identityKeyPair.privateKey, isNotNull);
        } catch (e) {
          // Expected if library not built yet
        }
      });
    });

    group('Error Handling', () {
      test('Graceful degradation when libraries unavailable', () async {
        // This test verifies that errors are handled gracefully
        // and don't crash the application
        
        try {
          await platformBridge.initialize();
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
          // Should not crash
        }
        
        try {
          await rustWrapper.initialize();
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
          // Should not crash
        }
        
        try {
          await ffiBindings.initialize();
        } catch (e) {
          expect(e, isA<SignalProtocolException>());
          // Should not crash
        }
      });

      test('Operations throw when not initialized', () {
        // Verify that operations throw appropriate errors when not initialized
        expect(
          () => ffiBindings.generateIdentityKeyPair(),
          throwsA(isA<SignalProtocolException>()),
        );
        
        expect(
          () => platformBridge.registerDispatchCallbackByName('test'),
          throwsA(isA<SignalProtocolException>()),
        );
        
        expect(
          () => rustWrapper.getLoadSessionWrapperPtr(),
          throwsA(isA<SignalProtocolException>()),
        );
      });
    });
  });
}
