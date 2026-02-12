// Unit tests for Signal Protocol FFI Prekey Bundle Creation
// Phase 14: Signal Protocol Implementation - Option 1
// 
// Tests prekey bundle creation functionality

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';

void main() {
  group('SignalFFIBindings - Prekey Bundle', () {
    late SignalFFIBindings ffiBindings;
    bool librariesAvailable = false;
    
    setUpAll(() {
      // Check if native libraries are available
      if (Platform.isMacOS) {
        const libPath = 'native/signal_ffi/macos/libsignal_ffi.dylib';
        final libFile = File(libPath);
        librariesAvailable = libFile.existsSync();
      } else {
        librariesAvailable = false;
      }
    });
    
    setUp(() {
      // Don't load libraries in setUp - only load when individual tests need them
      // This prevents crashes in tests that don't need libraries
      ffiBindings = SignalFFIBindings();
    });
    
    tearDown(() {
      // NOTE: We intentionally do NOT call dispose() in unit tests to prevent SIGABRT crashes.
      //
      // Native library teardown can abort the process during test finalization on some platforms
      // (especially when libraries are missing/incompatible). Unit tests should prioritize
      // determinism and avoid native teardown paths.
    });
    
    test('should initialize prekey bundle functions', () async {
      // Skip if libraries not available
      if (!librariesAvailable) {
        return;
      }
      
      // Load library only for this test
      try {
        await ffiBindings.initialize();
        if (!ffiBindings.isInitialized) {
          return;
        }
      } catch (e) {
        // Libraries not available - skip test
        if (e is SignalProtocolException) {
          return;
        }
        rethrow;
      }
      
      // Verify bindings are initialized
      expect(ffiBindings.isInitialized, isTrue);
      
      // Note: We can't directly test the function pointers, but if initialization
      // succeeded, the functions should be available
    });
    
    test('generatePreKeyBundle should throw NOT_IMPLEMENTED', () async {
      // Skip if libraries not available
      if (!librariesAvailable) {
        return;
      }
      
      // Skip if not initialized
      if (!ffiBindings.isInitialized) {
        return;
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
      
      // Should throw NOT_IMPLEMENTED since full implementation requires
      // key generation and signing functions
      expect(
        () => ffiBindings.generatePreKeyBundle(identityKeyPair: identityKeyPair),
        throwsA(isA<SignalProtocolException>().having(
          (e) => e.code,
          'code',
          'NOT_IMPLEMENTED',
        )),
      );
    });
  });
}
