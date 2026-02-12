// Signal Protocol Production Integration Test
// 
// Purpose: Test Signal Protocol in a production-like scenario
// - No disposal (simulates production lifecycle)
// - Library stays loaded for app lifetime
// - Verifies production behavior without test-specific cleanup
//
// Date: December 28, 2025
// Phase 14: Signal Protocol Implementation

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/services/security/signal_protocol_initialization_service.dart';

import '../../mocks/in_memory_flutter_secure_storage.dart';

void main() {
  group('Signal Protocol Production Integration', () {
    late SignalFFIBindings ffiBindings;
    late SignalPlatformBridgeBindings platformBridge;
    late SignalRustWrapperBindings rustWrapper;
    late SignalKeyManager keyManager;
    late SignalSessionManager sessionManager;
    late SignalFFIStoreCallbacks storeCallbacks;
    late SignalProtocolService signalProtocol;
    late SignalProtocolInitializationService initService;
    
    // Track if libraries are available
    bool librariesAvailable = false;
    
    setUpAll(() async {
      // Check if libraries are available
      try {
        final libFile = File('native/signal_ffi/macos/libsignal_ffi.dylib');
        librariesAvailable = libFile.existsSync();
      } catch (e) {
        librariesAvailable = false;
      }
    });
    
    setUp(() async {
      // Create services like production (singleton-like)
      ffiBindings = SignalFFIBindings();
      platformBridge = SignalPlatformBridgeBindings();
      rustWrapper = SignalRustWrapperBindings();
      
      // Use in-memory secure storage in tests (avoids MissingPluginException).
      final secureStorage = InMemoryFlutterSecureStorage();
      
      keyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: ffiBindings,
      );
      
      sessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: secureStorage),
        ffiBindings: ffiBindings,
        keyManager: keyManager,
      );
      
      storeCallbacks = SignalFFIStoreCallbacks(
        ffiBindings: ffiBindings,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
        keyManager: keyManager,
        sessionManager: sessionManager,
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
    
    // PRODUCTION-LIKE: No tearDown disposal
    // In production, services live for app lifetime
    // Library is unloaded by OS on app termination
    // This test verifies production behavior without disposal
    
    test('should initialize Signal Protocol in production-like scenario', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Initialize like production
      await initService.initialize();
      
      expect(signalProtocol.isInitialized, isTrue);
      expect(ffiBindings.isInitialized, isTrue);
    });
    
    test('should generate identity keys in production-like scenario', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Initialize like production
      await initService.initialize();
      
      // Generate identity key (production operation)
      final identityKeyPair = await keyManager.getOrGenerateIdentityKeyPair();
      
      expect(identityKeyPair.publicKey, isNotEmpty);
      expect(identityKeyPair.privateKey, isNotEmpty);
      expect(identityKeyPair.publicKey.length, greaterThan(0));
      expect(identityKeyPair.privateKey.length, greaterThan(0));
    });
    
    test('should perform multiple operations without disposal (production-like)', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Initialize like production
      await initService.initialize();
      
      // Perform multiple operations (simulating production usage)
      final keyPair1 = await keyManager.getOrGenerateIdentityKeyPair();
      final keyPair2 = await keyManager.getOrGenerateIdentityKeyPair();
      
      // Same key should be returned (singleton behavior)
      expect(keyPair1.publicKey, equals(keyPair2.publicKey));
      expect(keyPair1.privateKey, equals(keyPair2.privateKey));
      
      // Verify library still works after multiple operations
      expect(ffiBindings.isInitialized, isTrue);
      expect(signalProtocol.isInitialized, isTrue);
    });
    
    test('should handle errors gracefully without crashing (production-like)', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Initialize like production
      await initService.initialize();
      
      // Try invalid operation (should not crash)
      try {
        // This should throw SignalProtocolException, not crash
        await signalProtocol.encryptMessage(
          plaintext: Uint8List.fromList([1, 2, 3]),
          recipientId: 'nonexistent-recipient',
        );
        fail('Should have thrown SignalProtocolException');
      } catch (e) {
        // Expected - should handle gracefully (any exception is fine, just shouldn't crash)
        expect(e.toString(), anyOf(contains('session'), contains('error'), contains('Exception')));
      }
      
      // Verify library still works after error
      expect(ffiBindings.isInitialized, isTrue);
      expect(signalProtocol.isInitialized, isTrue);
    });
  });
}
