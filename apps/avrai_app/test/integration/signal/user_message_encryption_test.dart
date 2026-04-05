// Simple test to verify user-to-user message encryption works end-to-end
// Tests the complete flow: User A sends encrypted message to User B

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';
import '../../mocks/in_memory_flutter_secure_storage.dart';
import 'dart:io';
import 'dart:developer' as developer;

void main() {
  final runNativeSignalTests =
      Platform.environment['RUN_SIGNAL_NATIVE_TESTS'] == 'true';
  if (!runNativeSignalTests) {
    test(
      'Signal native integration tests are skipped by default',
      () {
        // Set RUN_SIGNAL_NATIVE_TESTS=true to opt in locally.
      },
    );
    return;
  }

  group('User-to-User Message Encryption', () {
    late InMemoryFlutterSecureStorage aliceStorage;
    late InMemoryFlutterSecureStorage bobStorage;
    late SupabaseService supabaseService;

    // Mock user IDs
    const aliceUserId = 'alice-user-123';
    const bobUserId = 'bob-user-456';

    // Signal Protocol services for Alice
    late SignalFFIBindings aliceFFI;
    late SignalPlatformBridgeBindings alicePlatformBridge;
    late SignalRustWrapperBindings aliceRustWrapper;
    late SignalKeyManager aliceKeyManager;
    late SignalSessionManager aliceSessionManager;
    late SignalFFIStoreCallbacks aliceStoreCallbacks;
    late SignalProtocolService aliceProtocol;
    late SignalProtocolEncryptionService aliceEncryptionService;

    // Signal Protocol services for Bob
    late SignalFFIBindings bobFFI;
    late SignalPlatformBridgeBindings bobPlatformBridge;
    late SignalRustWrapperBindings bobRustWrapper;
    late SignalKeyManager bobKeyManager;
    late SignalSessionManager bobSessionManager;
    late SignalFFIStoreCallbacks bobStoreCallbacks;
    late SignalProtocolService bobProtocol;
    late SignalProtocolEncryptionService bobEncryptionService;

    // Encryption services
    late MessageEncryptionService aliceMessageEncryption;
    late MessageEncryptionService bobMessageEncryption;

    bool librariesAvailable = false;
    bool signalUsable = false;

    setUpAll(() async {
      // Check if native libraries are available
      try {
        final currentDir = Directory.current.path;
        final libPath =
            '$currentDir/runtime/avrai_network/native/signal_ffi/macos/libsignal_ffi.dylib';
        final libFile = File(libPath);
        librariesAvailable = libFile.existsSync();

        if (!librariesAvailable) {
          developer.log(
              '⚠️ Native libraries not found, skipping Signal Protocol tests');
        }
      } catch (e) {
        developer.log('⚠️ Error checking for native libraries: $e');
        librariesAvailable = false;
      }
    });

    setUp(() async {
      if (!librariesAvailable) {
        return; // Skip setup if libraries not available
      }

      signalUsable = false;

      // Initialize storage
      aliceStorage = InMemoryFlutterSecureStorage();
      bobStorage = InMemoryFlutterSecureStorage();

      // Initialize services
      supabaseService = SupabaseService();

      // Initialize Alice's Signal Protocol services
      aliceFFI = SignalFFIBindings();
      try {
        await aliceFFI.initialize();
      } catch (e) {
        developer.log('⚠️ Signal FFI init failed; skipping Signal tests: $e');
        return;
      }

      alicePlatformBridge = SignalPlatformBridgeBindings();
      await alicePlatformBridge.initialize();

      aliceRustWrapper = SignalRustWrapperBindings();
      await aliceRustWrapper.initialize();

      // Share the same wrapper/bridge between Alice and Bob to ensure a single
      // Rust callback registry (avoids duplicate dylib loads in tests).
      bobPlatformBridge = alicePlatformBridge;
      bobRustWrapper = aliceRustWrapper;

      aliceKeyManager = SignalKeyManager(
        secureStorage: aliceStorage,
        ffiBindings: aliceFFI,
        supabaseService: supabaseService,
      );

      aliceSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: aliceStorage),
        ffiBindings: aliceFFI,
        keyManager: aliceKeyManager,
      );

      aliceStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
        ffiBindings: aliceFFI,
        rustWrapper: aliceRustWrapper,
        platformBridge: alicePlatformBridge,
      );
      await aliceStoreCallbacks.initialize();

      aliceProtocol = SignalProtocolService(
        ffiBindings: aliceFFI,
        storeCallbacks: aliceStoreCallbacks,
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
      );

      await aliceProtocol.initialize();

      aliceEncryptionService = SignalProtocolEncryptionService(
        signalProtocol: aliceProtocol,
        supabaseService: supabaseService,
        atomicClock: AtomicClockService(),
      );

      // Initialize Bob's Signal Protocol services
      bobFFI = SignalFFIBindings();
      try {
        await bobFFI.initialize();
      } catch (e) {
        developer.log('⚠️ Signal FFI init failed; skipping Signal tests: $e');
        return;
      }

      bobKeyManager = SignalKeyManager(
        secureStorage: bobStorage,
        ffiBindings: bobFFI,
        supabaseService: supabaseService,
      );

      bobSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: bobStorage),
        ffiBindings: bobFFI,
        keyManager: bobKeyManager,
      );

      bobStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
        ffiBindings: bobFFI,
        rustWrapper: bobRustWrapper,
        platformBridge: bobPlatformBridge,
      );
      await bobStoreCallbacks.initialize();

      bobProtocol = SignalProtocolService(
        ffiBindings: bobFFI,
        storeCallbacks: bobStoreCallbacks,
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
      );

      await bobProtocol.initialize();

      // Generate Bob's prekey bundle (local-only; we use test bundle wiring in this integration test).
      final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
      aliceKeyManager.setTestPreKeyBundle(bobUserId, bobPreKeyBundle);

      bobEncryptionService = SignalProtocolEncryptionService(
        signalProtocol: bobProtocol,
        supabaseService: supabaseService,
        atomicClock: AtomicClockService(),
      );

      // Use Signal directly for native integration runs (no AES fallback masking failures).
      aliceMessageEncryption = aliceEncryptionService;
      bobMessageEncryption = bobEncryptionService;

      signalUsable = true;
      developer.log('✅ Test setup complete');
    });

    tearDown(() async {
      // Note: We don't call dispose() to avoid SIGABRT crashes during test finalization
      // This is expected behavior - see PHASE_14_SIGABRT_FINAL_ANALYSIS.md
    });

    test('Alice should encrypt message for Bob, Bob should decrypt it',
        () async {
      if (!librariesAvailable || !signalUsable) {
        // ignore: avoid_print
        print(
            '⚠️ Skipping test - Signal Protocol not available/usable in this environment');
        return;
      }

      // Original message
      const originalMessage = 'Hello Bob! This is a test message from Alice.';

      developer.log('📝 Original message: $originalMessage');

      // Step 1: Alice encrypts message for Bob
      developer.log('🔐 Step 1: Alice encrypting message for Bob...');
      final encrypted = await aliceMessageEncryption.encrypt(
        originalMessage,
        bobUserId,
      );

      expect(encrypted, isNotNull);
      expect(encrypted.encryptedContent, isNotEmpty);
      expect(encrypted.encryptionType, isNotNull);

      developer.log('✅ Message encrypted');
      developer.log('   Encryption type: ${encrypted.encryptionType}');
      developer.log(
          '   Encrypted length: ${encrypted.encryptedContent.length} bytes');

      // Step 2: Bob decrypts message from Alice
      developer.log('🔓 Step 2: Bob decrypting message from Alice...');
      final decrypted = await bobMessageEncryption.decrypt(
        encrypted,
        aliceUserId,
      );

      expect(decrypted, isNotNull);
      expect(decrypted, equals(originalMessage));

      developer.log('✅ Message decrypted successfully');
      developer.log('   Decrypted message: $decrypted');

      // Verify round-trip
      expect(decrypted, equals(originalMessage),
          reason: 'Decrypted message should match original');

      developer.log('✅ Round-trip encryption/decryption successful!');
    });

    test('Multiple messages should work correctly', () async {
      if (!librariesAvailable || !signalUsable) {
        // ignore: avoid_print
        print(
            '⚠️ Skipping test - Signal Protocol not available/usable in this environment');
        return;
      }

      final messages = [
        'First message',
        'Second message',
        'Third message with special chars: !@#\$%^&*()',
      ];

      for (final message in messages) {
        developer.log('📝 Testing message: $message');

        // Alice encrypts
        final encrypted = await aliceMessageEncryption.encrypt(
          message,
          bobUserId,
        );

        expect(encrypted, isNotNull);

        // Bob decrypts
        final decrypted = await bobMessageEncryption.decrypt(
          encrypted,
          aliceUserId,
        );

        expect(decrypted, equals(message),
            reason: 'Message "$message" should decrypt correctly');

        developer
            .log('✅ Message "$message" encrypted and decrypted successfully');
      }

      developer
          .log('✅ All multiple messages encrypted/decrypted successfully!');
    });
  });
}
