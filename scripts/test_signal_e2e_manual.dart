#!/usr/bin/env dart
// ignore_for_file: avoid_print
// Signal Protocol End-to-End Manual Test
//
// Purpose: Test Signal Protocol integration end-to-end without Flutter test framework
// This script verifies the complete flow:
// 1. Initialize Signal Protocol for Alice and Bob
// 2. Generate prekey bundles
// 3. Perform X3DH key exchange
// 4. Encrypt message from Alice to Bob
// 5. Decrypt message on Bob's side
// 6. Verify message integrity
//
// Run with: dart run scripts/test_signal_e2e_manual.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;

// Flutter dependencies
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';

// Signal Protocol imports
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/services/security/signal_protocol_initialization_service.dart';

/// Test logging helper
void logStep(String step, {Map<String, dynamic>? data}) {
  final message = '🧪 $step';
  print(message);
  if (data != null) {
    data.forEach((key, value) {
      print('   $key: $value');
    });
  }
  developer.log(message, name: 'SignalE2ETest', error: data?.toString());
}

/// Find project root
String? findProjectRoot() {
  try {
    var current = Directory.current;
    while (current.path != current.parent.path) {
      final pubspec = File('${current.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        return current.path;
      }
      current = current.parent;
    }
  } catch (e) {
    return null;
  }
  return null;
}

/// Check if native libraries are available
bool checkLibrariesAvailable() {
  if (!Platform.isMacOS) {
    logStep('⚠️  Platform not macOS - Signal Protocol tests currently support macOS only');
    return false;
  }
  
  final pathsToTry = [
    'native/signal_ffi/macos/libsignal_ffi.dylib',
    '${Directory.current.path}/native/signal_ffi/macos/libsignal_ffi.dylib',
    findProjectRoot() != null
        ? '${findProjectRoot()}/native/signal_ffi/macos/libsignal_ffi.dylib'
        : null,
  ].whereType<String>().toList();
  
  for (final libPath in pathsToTry) {
    final libFile = File(libPath);
    if (libFile.existsSync()) {
      logStep('✅ Found Signal Protocol library', data: {'path': libPath});
      return true;
    }
  }
  
  logStep('❌ Signal Protocol library not found', data: {'pathsChecked': pathsToTry.length});
  return false;
}

void main() async {
  print('=' * 70);
  print('Signal Protocol End-to-End Manual Test');
  print('=' * 70);
  print('');
  
  // Check library availability
  if (!checkLibrariesAvailable()) {
    print('❌ Cannot proceed - libraries not available');
    exit(1);
  }
  
  print('');
  logStep('Setting up test environment...');
  
  // Create SecureSignalStorage (Phase 26 migration)
  // Note: Using real FlutterSecureStorage - this requires platform support
  final secureSignalStorage = SecureSignalStorage(
    secureStorage: const FlutterSecureStorage(),
  );
  
  // Setup Alice's Signal Protocol services
  logStep('Setting up Alice...');
  final aliceFFI = SignalFFIBindings();
  final alicePlatformBridge = SignalPlatformBridgeBindings();
  final aliceRustWrapper = SignalRustWrapperBindings();
  
  // Note: Using real FlutterSecureStorage - in production this would work
  // For testing, we could use a mock, but this tests the real integration
  final aliceKeyManager = SignalKeyManager(
    secureStorage: const FlutterSecureStorage(),
    ffiBindings: aliceFFI,
  );
  
  final aliceSessionManager = SignalSessionManager(
    storage: secureSignalStorage,
    ffiBindings: aliceFFI,
    keyManager: aliceKeyManager,
  );
  
  final aliceStoreCallbacks = SignalFFIStoreCallbacks(
    ffiBindings: aliceFFI,
    rustWrapper: aliceRustWrapper,
    platformBridge: alicePlatformBridge,
    keyManager: aliceKeyManager,
    sessionManager: aliceSessionManager,
  );
  
  final aliceProtocol = SignalProtocolService(
    ffiBindings: aliceFFI,
    storeCallbacks: aliceStoreCallbacks,
    keyManager: aliceKeyManager,
    sessionManager: aliceSessionManager,
  );
  
  // Setup Bob's Signal Protocol services
  logStep('Setting up Bob...');
  final bobFFI = SignalFFIBindings();
  final bobPlatformBridge = SignalPlatformBridgeBindings();
  final bobRustWrapper = SignalRustWrapperBindings();
  
  final bobKeyManager = SignalKeyManager(
    secureStorage: const FlutterSecureStorage(),
    ffiBindings: bobFFI,
  );
  
  final bobSessionManager = SignalSessionManager(
    storage: secureSignalStorage,
    ffiBindings: bobFFI,
    keyManager: bobKeyManager,
  );
  
  final bobStoreCallbacks = SignalFFIStoreCallbacks(
    ffiBindings: bobFFI,
    rustWrapper: bobRustWrapper,
    platformBridge: bobPlatformBridge,
    keyManager: bobKeyManager,
    sessionManager: bobSessionManager,
  );
  
  final bobProtocol = SignalProtocolService(
    ffiBindings: bobFFI,
    storeCallbacks: bobStoreCallbacks,
    keyManager: bobKeyManager,
    sessionManager: bobSessionManager,
  );
  
  try {
    // Initialize Signal Protocol
    logStep('Initializing Signal Protocol for Alice...');
    final aliceInit = SignalProtocolInitializationService(
      signalProtocol: aliceProtocol,
      platformBridge: alicePlatformBridge,
      rustWrapper: aliceRustWrapper,
      storeCallbacks: aliceStoreCallbacks,
    );
    await aliceInit.initialize();
    logStep('✅ Alice initialized', data: {'isInitialized': aliceProtocol.isInitialized});
    
    logStep('Initializing Signal Protocol for Bob...');
    final bobInit = SignalProtocolInitializationService(
      signalProtocol: bobProtocol,
      platformBridge: bobPlatformBridge,
      rustWrapper: bobRustWrapper,
      storeCallbacks: bobStoreCallbacks,
    );
    await bobInit.initialize();
    logStep('✅ Bob initialized', data: {'isInitialized': bobProtocol.isInitialized});
    
    if (!aliceProtocol.isInitialized || !bobProtocol.isInitialized) {
      print('❌ Initialization failed');
      exit(1);
    }
    
    print('');
    print('=' * 70);
    print('TEST 1: Prekey Bundle Generation');
    print('=' * 70);
    
    // Test: Bob generates prekey bundle
    logStep('Bob generating prekey bundle...');
    final stopwatch = Stopwatch()..start();
    final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
    stopwatch.stop();
    
    logStep('✅ Prekey bundle generated', data: {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'hasIdentityKey': bobPreKeyBundle.identityKey.isNotEmpty,
      'hasSignedPreKey': bobPreKeyBundle.signedPreKey.isNotEmpty,
      'identityKeyLength': bobPreKeyBundle.identityKey.length,
      'signedPreKeyLength': bobPreKeyBundle.signedPreKey.length,
    });
    
    // Store Bob's prekey bundle for Alice to fetch
    bobKeyManager.setTestPreKeyBundle('agent_bob', bobPreKeyBundle);
    
    print('');
    print('=' * 70);
    print('TEST 2: X3DH Key Exchange');
    print('=' * 70);
    
    // Test: Alice performs X3DH
    logStep('Alice getting identity key...');
    stopwatch.reset();
    stopwatch.start();
    final aliceIdentityKey = await aliceKeyManager.getOrGenerateIdentityKeyPair();
    stopwatch.stop();
    logStep('✅ Alice identity key ready', data: {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'publicKeyLength': aliceIdentityKey.publicKey.length,
    });
    
    logStep('Alice performing X3DH key exchange with Bob...');
    stopwatch.reset();
    stopwatch.start();
    await aliceFFI.performX3DHKeyExchange(
      recipientId: 'agent_bob',
      preKeyBundle: bobPreKeyBundle,
      identityKeyPair: aliceIdentityKey,
      storeCallbacks: aliceStoreCallbacks,
    );
    stopwatch.stop();
    logStep('✅ X3DH key exchange complete', data: {
      'duration_ms': stopwatch.elapsedMilliseconds,
    });
    
    // Verify session was created
    final session = await aliceSessionManager.getSession('agent_bob');
    logStep('Session verification', data: {
      'sessionExists': session != null,
      // SignalSessionState does not expose raw bytes; use JSON size as a proxy.
      'sessionJsonLength': session == null ? 0 : session.toJson().toString().length,
    });
    
    print('');
    print('=' * 70);
    print('TEST 3: Message Encryption');
    print('=' * 70);
    
    // Test: Alice encrypts message
    const plaintext = 'Hello from Alice! This is a test message for Signal Protocol end-to-end testing.';
    logStep('Alice encrypting message...', data: {
      'plaintext': plaintext,
      'plaintextLength': plaintext.length,
    });
    
    stopwatch.reset();
    stopwatch.start();
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = await aliceProtocol.encryptMessage(
      plaintext: plaintextBytes,
      recipientId: 'agent_bob',
    );
    stopwatch.stop();
    
    logStep('✅ Message encrypted', data: {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'ciphertextLength': encrypted.ciphertext.length,
      'hasCiphertext': encrypted.ciphertext.isNotEmpty,
    });
    
    print('');
    print('=' * 70);
    print('TEST 4: Message Decryption');
    print('=' * 70);
    
    // Test: Bob decrypts message
    logStep('Bob decrypting message...');
    stopwatch.reset();
    stopwatch.start();
    final decrypted = await bobProtocol.decryptMessage(
      encrypted: encrypted,
      senderId: 'agent_alice',
    );
    stopwatch.stop();
    
    final decryptedText = utf8.decode(decrypted);
    logStep('✅ Message decrypted', data: {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'decryptedLength': decrypted.length,
    });
    
    print('');
    print('=' * 70);
    print('VERIFICATION');
    print('=' * 70);
    
    // Verify
    logStep('Comparing original and decrypted messages...');
    print('  Original:  "$plaintext"');
    print('  Decrypted: "$decryptedText"');
    print('');
    
    final match = plaintext == decryptedText;
    if (match) {
      print('✅ Messages match perfectly!');
    } else {
      print('❌ Messages do not match!');
      print('   Original length:  ${plaintext.length}');
      print('   Decrypted length: ${decryptedText.length}');
    }
    
    print('');
    print('=' * 70);
    print('TEST SUMMARY');
    print('=' * 70);
    print('');
    print('✅ Prekey bundle generation: PASSED');
    print('✅ X3DH key exchange: PASSED');
    print('✅ Message encryption: PASSED');
    print('${match ? "✅" : "❌"} Message decryption: ${match ? "PASSED" : "FAILED"}');
    print('${match ? "✅" : "❌"} End-to-end test: ${match ? "PASSED" : "FAILED"}');
    print('');
    
    if (match) {
      print('🎉 SUCCESS! Signal Protocol end-to-end test passed!');
      print('   All operations completed successfully.');
      print('   Message encryption and decryption work correctly.');
      exit(0);
    } else {
      print('❌ FAILED! Messages do not match.');
      print('   Signal Protocol integration has an issue.');
      exit(1);
    }
  } catch (e, stackTrace) {
    print('');
    print('=' * 70);
    print('ERROR');
    print('=' * 70);
    print('❌ Test failed with error:');
    print('   $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    developer.log('Test failed', error: e, stackTrace: stackTrace, name: 'SignalE2ETest');
    exit(1);
  }
}
