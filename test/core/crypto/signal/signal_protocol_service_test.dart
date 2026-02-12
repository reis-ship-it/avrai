// Unit tests for Signal Protocol Service
// Phase 14: Signal Protocol Implementation - Option 1

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';

/// Mock FlutterSecureStorage for testing
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SignalProtocolService', () {
    late SignalFFIBindings ffiBindings;
    late SignalKeyManager keyManager;
    late SignalSessionManager sessionManager;
    late SignalProtocolService service;
    late SecureSignalStorage secureSignalStorage;
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
      
      // Initialize services
      ffiBindings = SignalFFIBindings();
      final platformBridge = SignalPlatformBridgeBindings();
      final rustWrapper = SignalRustWrapperBindings();
      
      keyManager = SignalKeyManager(
        secureStorage: mockSecureStorage, // Use mock instead of real FlutterSecureStorage
        ffiBindings: ffiBindings,
      );
      secureSignalStorage = SecureSignalStorage(secureStorage: mockSecureStorage);
      sessionManager = SignalSessionManager(
        storage: secureSignalStorage,
        ffiBindings: ffiBindings,
        keyManager: keyManager,
      );
      
      // Create store callbacks (required for SignalProtocolService)
      final storeCallbacks = SignalFFIStoreCallbacks(
        keyManager: keyManager,
        sessionManager: sessionManager,
        ffiBindings: ffiBindings,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
      );
      
      service = SignalProtocolService(
        ffiBindings: ffiBindings,
        storeCallbacks: storeCallbacks,
        keyManager: keyManager,
        sessionManager: sessionManager,
        atomicClock: AtomicClockService(),
      );
    });
    
    tearDown(() async {
      // NOTE: We intentionally avoid disposing native-backed Signal components in unit tests.
      // Native teardown can cause SIGABRT during finalization on some platforms.
    });
    
    test('service initializes correctly', () {
      expect(service, isNotNull);
      expect(service.isInitialized, isFalse);
    });
    
    test(
      'initialize() is exercised in native integration tests',
      () async {
        // NOTE:
        // SignalProtocolService.initialize() loads native libraries and can trigger
        // process teardown crashes (SIGABRT) under flutter_test depending on the
        // host/runtime loader behavior.
        //
        // We validate native initialization + encryption/decryption via the dedicated
        // Signal integration test suite instead of unit tests.
        //
        // This keeps unit tests deterministic while still enforcing behavior elsewhere.
        expect(service.isInitialized, isFalse);
      },
      skip: 'Requires native Signal runtime; verified by integration tests.',
    );
    
    // Note: Full integration tests will be added once FFI bindings are complete
    // These tests will verify:
    // - Identity key generation
    // - Prekey bundle generation
    // - X3DH key exchange
    // - Message encryption/decryption
    // - Session management
  });
}
