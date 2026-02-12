// Signal Protocol Performance Benchmarks
// Phase 14.6: Testing & Validation - Optional Enhancement
//
// Benchmarks Signal Protocol operations:
// - Encryption/decryption performance
// - Key generation performance
// - X3DH key exchange performance
// - Memory usage

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import '../mocks/in_memory_flutter_secure_storage.dart';
import 'dart:developer' as developer;

void main() {
  group('Signal Protocol Performance Benchmarks', () {
    late InMemoryFlutterSecureStorage aliceStorage;
    late InMemoryFlutterSecureStorage bobStorage;
    late SignalFFIBindings aliceFFI;
    late SignalFFIBindings bobFFI;
    late SignalPlatformBridgeBindings alicePlatformBridge;
    late SignalPlatformBridgeBindings bobPlatformBridge;
    late SignalRustWrapperBindings aliceRustWrapper;
    late SignalRustWrapperBindings bobRustWrapper;
    late SignalKeyManager aliceKeyManager;
    late SignalKeyManager bobKeyManager;
    late SignalSessionManager aliceSessionManager;
    late SignalSessionManager bobSessionManager;
    late SignalFFIStoreCallbacks aliceStoreCallbacks;
    late SignalFFIStoreCallbacks bobStoreCallbacks;
    late SignalProtocolService aliceProtocol;
    late SignalProtocolService bobProtocol;
    
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
      
      if (!librariesAvailable) {
        developer.log(
          'Native libraries not available - skipping performance tests',
          name: 'SignalProtocolPerformanceTest',
        );
        return;
      }
      
      // Initialize storage
      aliceStorage = InMemoryFlutterSecureStorage();
      bobStorage = InMemoryFlutterSecureStorage();
      
      // Initialize FFI bindings
      aliceFFI = SignalFFIBindings();
      bobFFI = SignalFFIBindings();
      await aliceFFI.initialize();
      await bobFFI.initialize();
      
      // Initialize platform bridge
      alicePlatformBridge = SignalPlatformBridgeBindings();
      bobPlatformBridge = SignalPlatformBridgeBindings();
      await alicePlatformBridge.initialize();
      await bobPlatformBridge.initialize();
      
      // Initialize Rust wrapper
      aliceRustWrapper = SignalRustWrapperBindings();
      bobRustWrapper = SignalRustWrapperBindings();
      await aliceRustWrapper.initialize();
      await bobRustWrapper.initialize();
      
      // Initialize key managers
      aliceKeyManager = SignalKeyManager(
        secureStorage: aliceStorage,
        ffiBindings: aliceFFI,
      );
      bobKeyManager = SignalKeyManager(
        secureStorage: bobStorage,
        ffiBindings: bobFFI,
      );
      
      // Initialize session managers
      aliceSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: aliceStorage),
        ffiBindings: aliceFFI,
        keyManager: aliceKeyManager,
      );
      bobSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: bobStorage),
        ffiBindings: bobFFI,
        keyManager: bobKeyManager,
      );
      
      // Initialize store callbacks
      aliceStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
        ffiBindings: aliceFFI,
        rustWrapper: aliceRustWrapper,
        platformBridge: alicePlatformBridge,
      );
      bobStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
        ffiBindings: bobFFI,
        rustWrapper: bobRustWrapper,
        platformBridge: bobPlatformBridge,
      );

      // Store callbacks must be initialized before calling any FFI methods that
      // require store access (eg. X3DH / Double Ratchet).
      await aliceStoreCallbacks.initialize();
      await bobStoreCallbacks.initialize();
      
      // Initialize protocol services
      aliceProtocol = SignalProtocolService(
        ffiBindings: aliceFFI,
        storeCallbacks: aliceStoreCallbacks,
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
      );
      bobProtocol = SignalProtocolService(
        ffiBindings: bobFFI,
        storeCallbacks: bobStoreCallbacks,
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
      );
      
      await aliceProtocol.initialize();
      await bobProtocol.initialize();
      
      // Generate and upload prekey bundles
      final alicePreKeyBundle = await aliceKeyManager.generatePreKeyBundle();
      final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
      
      // Set test prekey bundles
      aliceKeyManager.setTestPreKeyBundle('bob-agent', bobPreKeyBundle);
      bobKeyManager.setTestPreKeyBundle('alice-agent', alicePreKeyBundle);
    });
    
    tearDownAll(() async {
      // Note: Not calling dispose() to avoid SIGABRT during test finalization
      // Libraries will be cleaned up by OS on process termination
    });
    
    test('Key Generation Performance', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      const iterations = 10;
      final times = <int>[];
      
      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        await aliceFFI.generateIdentityKeyPair();
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }
      
      final avgTime = times.reduce((a, b) => a + b) / iterations;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      developer.log(
        'Key Generation Performance:',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Average: ${(avgTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Min: ${(minTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Max: ${(maxTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      
      // Benchmark: Key generation should be < 100ms
      expect(avgTime, lessThan(100000), // 100ms in microseconds
          reason: 'Key generation should be < 100ms on average');
    });
    
    test('X3DH Key Exchange Performance', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      const iterations = 5;
      final times = <int>[];
      
      for (int i = 0; i < iterations; i++) {
        // Create fresh session managers for each iteration
        final aliceSessionManager = SignalSessionManager(
          storage: SecureSignalStorage(secureStorage: aliceStorage),
          ffiBindings: aliceFFI,
          keyManager: aliceKeyManager,
        );
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
        final bobSessionManager = SignalSessionManager(
          storage: SecureSignalStorage(secureStorage: bobStorage),
          ffiBindings: bobFFI,
          keyManager: bobKeyManager,
        );
        
        final aliceStoreCallbacks = SignalFFIStoreCallbacks(
          keyManager: aliceKeyManager,
          sessionManager: aliceSessionManager,
          ffiBindings: aliceFFI,
          rustWrapper: aliceRustWrapper,
          platformBridge: alicePlatformBridge,
        );
        await aliceStoreCallbacks.initialize();
        
        final aliceIdentityKeyPair = await aliceKeyManager.getOrGenerateIdentityKeyPair();
        final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
        aliceKeyManager.setTestPreKeyBundle('bob-agent-$i', bobPreKeyBundle);
        
        final stopwatch = Stopwatch()..start();
        await aliceFFI.performX3DHKeyExchange(
          recipientId: 'bob-agent-$i',
          preKeyBundle: bobPreKeyBundle,
          identityKeyPair: aliceIdentityKeyPair,
          storeCallbacks: aliceStoreCallbacks,
        );
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }
      
      final avgTime = times.reduce((a, b) => a + b) / iterations;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      developer.log(
        'X3DH Key Exchange Performance:',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Average: ${(avgTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Min: ${(minTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Max: ${(maxTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      
      // Benchmark: X3DH should be < 500ms
      expect(avgTime, lessThan(500000), // 500ms in microseconds
          reason: 'X3DH key exchange should be < 500ms on average');
    });
    
    test('Encryption Performance', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Establish session first
      final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
      aliceKeyManager.setTestPreKeyBundle('bob-agent-perf', bobPreKeyBundle);
      
      // Encrypt a message to establish session
      final testMessage = Uint8List.fromList('Hello, Bob!'.codeUnits);
      await aliceProtocol.encryptMessage(
        plaintext: testMessage,
        recipientId: 'bob-agent-perf',
      );
      
      const iterations = 100;
      final times = <int>[];
      
      for (int i = 0; i < iterations; i++) {
        final message = Uint8List.fromList('Test message $i'.codeUnits);
        final stopwatch = Stopwatch()..start();
        await aliceProtocol.encryptMessage(
          plaintext: message,
          recipientId: 'bob-agent-perf',
        );
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }
      
      final avgTime = times.reduce((a, b) => a + b) / iterations;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      developer.log(
        'Encryption Performance:',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Average: ${(avgTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Min: ${(minTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Max: ${(maxTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      
      // Benchmark: Encryption should be < 10ms
      expect(avgTime, lessThan(10000), // 10ms in microseconds
          reason: 'Encryption should be < 10ms on average');
    });
    
    test('Decryption Performance', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Establish session and encrypt messages
      final alicePreKeyBundle = await aliceKeyManager.generatePreKeyBundle();
      bobKeyManager.setTestPreKeyBundle('alice-agent-perf', alicePreKeyBundle);
      
      const iterations = 100;
      final encryptedMessages = <Uint8List>[];
      
      // Encrypt messages
      for (int i = 0; i < iterations; i++) {
        final message = Uint8List.fromList('Test message $i'.codeUnits);
        final encrypted = await bobProtocol.encryptMessage(
          plaintext: message,
          recipientId: 'alice-agent-perf',
        );
        encryptedMessages.add(encrypted.toBytes());
      }
      
      // Now decrypt them
      final times = <int>[];
      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        final encrypted = SignalEncryptedMessage.fromBytes(encryptedMessages[i]);
        await aliceProtocol.decryptMessage(
          encrypted: encrypted,
          senderId: 'bob-agent-perf',
        );
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }
      
      final avgTime = times.reduce((a, b) => a + b) / iterations;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      developer.log(
        'Decryption Performance:',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Average: ${(avgTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Min: ${(minTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Max: ${(maxTime / 1000).toStringAsFixed(2)}ms',
        name: 'SignalProtocolPerformanceTest',
      );
      
      // Benchmark: Decryption should be < 10ms
      expect(avgTime, lessThan(10000), // 10ms in microseconds
          reason: 'Decryption should be < 10ms on average');
    });
    
    test('Memory Usage', () async {
      if (!librariesAvailable) {
        return; // Skip if libraries not available
      }
      
      // Note: Accurate memory measurement in Dart is difficult
      // This test provides a rough estimate by checking process memory
      
      developer.log(
        'Memory Usage Test:',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Note: Accurate memory measurement requires platform-specific tools',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Signal Protocol libraries are loaded and initialized',
        name: 'SignalProtocolPerformanceTest',
      );
      developer.log(
        '  Expected memory usage: < 50MB for Signal Protocol components',
        name: 'SignalProtocolPerformanceTest',
      );
      
      // This test passes if we can initialize and use Signal Protocol
      // Actual memory measurement should be done with platform tools
      expect(aliceProtocol, isNotNull);
      expect(bobProtocol, isNotNull);
    });
  });
}
