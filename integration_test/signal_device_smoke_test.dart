import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';

import 'package:avrai/core/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

import '../test/mocks/in_memory_flutter_secure_storage.dart';

Uint8List _randomKey32() {
  final r = math.Random.secure();
  final out = Uint8List(32);
  for (var i = 0; i < out.length; i++) {
    out[i] = r.nextInt(256);
  }
  return out;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Signal DM + sender-key share smoke (device)', (tester) async {
    await tester.runAsync(() async {
      // Debug: confirm the native libs are loadable in the test runner.
      // ignore: avoid_print
      print('🔎 [signal_smoke] Probing wrapper dylib...');
      try {
        final dl = Platform.isIOS
            ? DynamicLibrary.open('SignalFfiWrapper.framework/SignalFfiWrapper')
            : DynamicLibrary.open('libsignal_ffi_wrapper.so');
        dl.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'spots_rust_register_dispatch_callback',
        );
        // ignore: avoid_print
        print('✅ [signal_smoke] wrapper dylib loaded + symbol found');
      } catch (e) {
        // ignore: avoid_print
        print('❌ [signal_smoke] wrapper dylib probe failed: $e');
      }

      // ignore: avoid_print
      print('🔎 [signal_smoke] Probing main libsignal_ffi dylib...');
      try {
        final dl = Platform.isIOS
            ? DynamicLibrary.open('SignalFfi.framework/SignalFfi')
            : DynamicLibrary.open('libsignal_ffi.so');
        dl.lookup<NativeFunction<Void Function()>>('signal_error_free');
        // ignore: avoid_print
        print('✅ [signal_smoke] main dylib loaded + symbol found');
      } catch (e) {
        // ignore: avoid_print
        print('❌ [signal_smoke] main dylib probe failed: $e');
      }

      // Shared native libraries / dispatch registry.
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Rust wrapper...');
      final rustWrapper = SignalRustWrapperBindings();
      await rustWrapper.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Rust wrapper initialized');

      // Platform bridge is legacy now (store callbacks register directly).
      // Keep it uninitialized here to reduce native loads in device tests.
      final platformBridge = SignalPlatformBridgeBindings();

      // Alice stack (Phase 26: SecureSignalStorage)
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Alice FFI...');
      final aliceStorage = InMemoryFlutterSecureStorage();
      final aliceSecureSignalStorage = SecureSignalStorage(secureStorage: aliceStorage);
      final aliceFfi = SignalFFIBindings();
      final aliceSupabase = SupabaseService();
      await aliceFfi.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Alice FFI initialized');
      final aliceKeyManager = SignalKeyManager(
        secureStorage: aliceStorage,
        ffiBindings: aliceFfi,
        supabaseService: aliceSupabase,
      );
      final aliceSessionManager = SignalSessionManager(
        ffiBindings: aliceFfi,
        keyManager: aliceKeyManager,
        storage: aliceSecureSignalStorage,
      );
      final aliceStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
        ffiBindings: aliceFfi,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
      );
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Alice store callbacks...');
      await aliceStoreCallbacks.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Alice store callbacks initialized');
      final aliceProtocol = SignalProtocolService(
        ffiBindings: aliceFfi,
        storeCallbacks: aliceStoreCallbacks,
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
      );
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Alice protocol...');
      await aliceProtocol.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Alice protocol initialized');

      // Bob stack (Phase 26: SecureSignalStorage)
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Bob FFI...');
      final bobStorage = InMemoryFlutterSecureStorage();
      final bobSecureSignalStorage = SecureSignalStorage(secureStorage: bobStorage);
      final bobFfi = SignalFFIBindings();
      final bobSupabase = SupabaseService();
      await bobFfi.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Bob FFI initialized');
      final bobKeyManager = SignalKeyManager(
        secureStorage: bobStorage,
        ffiBindings: bobFfi,
        supabaseService: bobSupabase,
      );
      final bobSessionManager = SignalSessionManager(
        ffiBindings: bobFfi,
        keyManager: bobKeyManager,
        storage: bobSecureSignalStorage,
      );
      final bobStoreCallbacks = SignalFFIStoreCallbacks(
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
        ffiBindings: bobFfi,
        rustWrapper: rustWrapper,
        platformBridge: platformBridge,
      );
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Bob store callbacks...');
      await bobStoreCallbacks.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Bob store callbacks initialized');
      final bobProtocol = SignalProtocolService(
        ffiBindings: bobFfi,
        storeCallbacks: bobStoreCallbacks,
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
      );
      // ignore: avoid_print
      print('🔎 [signal_smoke] Initializing Bob protocol...');
      await bobProtocol.initialize();
      // ignore: avoid_print
      print('✅ [signal_smoke] Bob protocol initialized');

      const aliceUserId = 'signal-smoke-alice';
      const bobUserId = 'signal-smoke-bob';

      // Bob publishes a prekey bundle (local records stored).
      // ignore: avoid_print
      print('🔎 [signal_smoke] Generating Bob prekey bundle...');
      final bobBundle = await bobKeyManager.generatePreKeyBundle();
      // ignore: avoid_print
      print('✅ [signal_smoke] Bob prekey bundle generated');
      aliceKeyManager.setTestPreKeyBundle(bobUserId, bobBundle);

      // DM: Alice -> Bob (first message is typically a PreKey message).
      // ignore: avoid_print
      print('🔎 [signal_smoke] Encrypting hello-1 (Alice -> Bob)...');
      final hello1 = Uint8List.fromList(utf8.encode('hello-1'));
      final enc1 = await aliceProtocol.encryptMessage(
        plaintext: hello1,
        recipientId: bobUserId,
      );
      expect(enc1.ciphertext, isNotEmpty);
      // ignore: avoid_print
      print('✅ [signal_smoke] Encrypted hello-1');

      // ignore: avoid_print
      print('🔎 [signal_smoke] Decrypting hello-1 (Bob)...');
      final dec1 = await bobProtocol.decryptMessage(
        encrypted: SignalEncryptedMessage.fromBytes(enc1.toBytes()),
        senderId: aliceUserId,
      );
      expect(utf8.decode(dec1), equals('hello-1'));
      // ignore: avoid_print
      print('✅ [signal_smoke] Decrypted hello-1');

      // DM: Alice -> Bob again (should be session-based now).
      // ignore: avoid_print
      print('🔎 [signal_smoke] Encrypting hello-2 (Alice -> Bob)...');
      final hello2 = Uint8List.fromList(utf8.encode('hello-2'));
      final enc2 = await aliceProtocol.encryptMessage(
        plaintext: hello2,
        recipientId: bobUserId,
      );
      expect(enc2.ciphertext, isNotEmpty);
      // ignore: avoid_print
      print('✅ [signal_smoke] Encrypted hello-2');

      // ignore: avoid_print
      print('🔎 [signal_smoke] Decrypting hello-2 (Bob)...');
      final dec2 = await bobProtocol.decryptMessage(
        encrypted: SignalEncryptedMessage.fromBytes(enc2.toBytes()),
        senderId: aliceUserId,
      );
      expect(utf8.decode(dec2), equals('hello-2'));
      // ignore: avoid_print
      print('✅ [signal_smoke] Decrypted hello-2');

      // "Group" smoke: distribute a sender key via Signal once, then encrypt
      // messages with AES-256-GCM using that shared key.
      final senderKey32 = _randomKey32();
      final sharePayload = jsonEncode(<String, dynamic>{
        'key_id': 'k1',
        'key_base64': base64Encode(senderKey32),
      });

      final shareEncrypted = await aliceProtocol.encryptMessage(
        plaintext: Uint8List.fromList(utf8.encode(sharePayload)),
        recipientId: bobUserId,
      );

      final shareDecrypted = await bobProtocol.decryptMessage(
        encrypted: SignalEncryptedMessage.fromBytes(shareEncrypted.toBytes()),
        senderId: aliceUserId,
      );
      final decoded = jsonDecode(utf8.decode(shareDecrypted)) as Map<String, dynamic>;
      expect(decoded['key_id'], equals('k1'));
      expect(decoded['key_base64'], isA<String>());

      const groupPlaintext = 'group-hello';
      final ciphertextBase64 = Aes256GcmFixedKeyCodec.encryptStringToBase64(
        key32: senderKey32,
        plaintext: groupPlaintext,
      );

      final restored = Aes256GcmFixedKeyCodec.decryptBase64ToString(
        key32: senderKey32,
        ciphertextBase64: ciphertextBase64,
      );
      expect(restored, equals(groupPlaintext));
    });
  });
}

