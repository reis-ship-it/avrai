// Signal Protocol FFI Store Callbacks
// Phase 14: Signal Protocol Implementation - Option 1
// 
// Provides Dart callbacks for libsignal-ffi store interfaces
// ignore_for_file: non_constant_identifier_names - FFI bindings match Rust/C API (snake_case)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';

/// Store context for FFI callbacks
/// 
/// Holds references to Dart managers that implement the store operations
class _SignalStoreContext {
  final SignalKeyManager keyManager;
  final SignalSessionManager sessionManager;
  final SignalFFIBindings ffiBindings;
  
  _SignalStoreContext({
    required this.keyManager,
    required this.sessionManager,
    required this.ffiBindings,
  });
}

/// Helper class to create FFI store structs
/// 
/// Converts Dart store managers into C-compatible store callbacks
/// Uses Callback ID Dispatch Pattern to work around Dart FFI limitations
class SignalFFIStoreCallbacks {
  static const String _logName = 'SignalFFIStoreCallbacks';
  
  final SignalKeyManager _keyManager;
  final SignalSessionManager _sessionManager;
  // Note: _ffiBindings kept for potential future use (e.g., key serialization)
  // ignore: unused_field
  final SignalFFIBindings _ffiBindings;
  final SignalRustWrapperBindings _rustWrapper;
  // ignore: unused_field
  final SignalPlatformBridgeBindings _platformBridge;
  
  // Store context (will be passed as void* to C)
  late final Pointer<Void> _contextPtr;
  
  // Callback registry (maps callback ID to callback function)
  // Signature: (storeCtx, arg1, arg2, arg3, direction) -> int
  static final Map<int, int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, int)> _callbackRegistry = {};
  
  // Callback IDs (must match Rust constants)
  static const int _loadSessionCallbackId = 1;
  static const int _storeSessionCallbackId = 2;
  static const int _getIdentityKeyPairCallbackId = 3;
  static const int _getLocalRegistrationIdCallbackId = 4;
  static const int _saveIdentityKeyCallbackId = 5;
  static const int _getIdentityKeyCallbackId = 6;
  static const int _isTrustedIdentityCallbackId = 7;
  static const int _loadPreKeyCallbackId = 8;
  static const int _storePreKeyCallbackId = 9;
  static const int _removePreKeyCallbackId = 10;
  static const int _loadSignedPreKeyCallbackId = 11;
  static const int _storeSignedPreKeyCallbackId = 12;
  static const int _loadKyberPreKeyCallbackId = 13;
  static const int _storeKyberPreKeyCallbackId = 14;
  static const int _markKyberPreKeyUsedCallbackId = 15;
  
  // Initialization flag
  bool _initialized = false;
  
  SignalFFIStoreCallbacks({
    required SignalKeyManager keyManager,
    required SignalSessionManager sessionManager,
    required SignalFFIBindings ffiBindings,
    required SignalRustWrapperBindings rustWrapper,
    required SignalPlatformBridgeBindings platformBridge,
  }) : _keyManager = keyManager,
       _sessionManager = sessionManager,
       _ffiBindings = ffiBindings,
       _rustWrapper = rustWrapper,
       _platformBridge = platformBridge {
    // Allocate context pointer
    // The Rust wrapper will extract callback IDs from CallbackArgs struct
    // We store the context address as a unique identifier for context lookup
    final contextIdPtr = malloc.allocate<IntPtr>(sizeOf<IntPtr>());
    contextIdPtr.value = contextIdPtr.address;
    _contextPtr = contextIdPtr.cast<Void>();
    
    _registerContext();
    // NOTE: _registerCallbacks() is now called in initialize() method
    // This allows dependencies to be initialized first
  }
  
  /// Initialize store callbacks
  /// 
  /// Must be called after `SignalRustWrapperBindings` is initialized.
  ///
  /// Note: the platform bridge is legacy (dlsym-based) and no longer required for
  /// the struct-pointer dispatch callback path.
  Future<void> initialize() async {
    if (_initialized) {
      developer.log('Store callbacks already initialized', name: _logName);
      return;
    }
    
    try {
      developer.log('Initializing Signal FFI store callbacks...', name: _logName);
      
      // Verify dependencies are initialized
      if (!_rustWrapper.isInitialized) {
        throw SignalProtocolException(
          'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
        );
      }
      
      // Warm caches used by synchronous native callbacks.
      await _keyManager.warmNativeCaches();
      await _sessionManager.warmNativeCaches();

      // Bind helper symbols for callbacks.
      _ensureNativeHelpersBound(_ffiBindings);

      // Register callbacks (this will create NativeCallable if needed)
      _registerCallbacks();
      
      _initialized = true;
      developer.log('✅ Signal FFI store callbacks initialized successfully', name: _logName);
    } catch (e, st) {
      developer.log(
        'Failed to initialize store callbacks: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Check if store callbacks are initialized
  bool get isInitialized => _initialized;
  
  /// Register all callbacks with the Rust wrapper library
  /// 
  /// Uses the struct-pointer dispatch callback pattern:
  /// 1. Register callbacks with unique IDs in Dart registry
  /// 2. Register a single `CallbackArgs*` dispatch callback with the Rust wrapper
  void _registerCallbacks() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }
    
    // Register callbacks in Dart registry with unique IDs
    _callbackRegistry[_loadSessionCallbackId] = _loadSessionCallbackImpl;
    _callbackRegistry[_storeSessionCallbackId] = _storeSessionCallbackImpl;
    _callbackRegistry[_getIdentityKeyPairCallbackId] = _getIdentityKeyPairCallbackImpl;
    _callbackRegistry[_getLocalRegistrationIdCallbackId] = _getLocalRegistrationIdCallbackImpl;
    _callbackRegistry[_saveIdentityKeyCallbackId] = _saveIdentityKeyCallbackImpl;
    _callbackRegistry[_getIdentityKeyCallbackId] = _getIdentityKeyCallbackImpl;
    _callbackRegistry[_isTrustedIdentityCallbackId] = _isTrustedIdentityCallbackImpl;
    _callbackRegistry[_loadPreKeyCallbackId] = _loadPreKeyCallbackImpl;
    _callbackRegistry[_storePreKeyCallbackId] = _storePreKeyCallbackImpl;
    _callbackRegistry[_removePreKeyCallbackId] = _removePreKeyCallbackImpl;
    _callbackRegistry[_loadSignedPreKeyCallbackId] = _loadSignedPreKeyCallbackImpl;
    _callbackRegistry[_storeSignedPreKeyCallbackId] = _storeSignedPreKeyCallbackImpl;
    _callbackRegistry[_loadKyberPreKeyCallbackId] = _loadKyberPreKeyCallbackImpl;
    _callbackRegistry[_storeKyberPreKeyCallbackId] = _storeKyberPreKeyCallbackImpl;
    _callbackRegistry[_markKyberPreKeyUsedCallbackId] =
        _markKyberPreKeyUsedCallbackImpl;
    
    // Register the dispatch callback directly (single-parameter struct pointer).
    final ptr = Pointer.fromFunction<Int32 Function(Pointer<CallbackArgs>)>(
      _dispatchCallbackPtr,
      1, // default error code if an exception bubbles out
    ).cast<Void>();
    _rustWrapper.registerDispatchCallback(ptr);
  }
  
  /// Dispatch callback function.
  ///
  /// This is the single function the Rust wrapper calls. It must **never throw**.
  @pragma('vm:entry-point')
  static int _dispatchCallbackPtr(Pointer<CallbackArgs> argsPtr) {
    try {
      if (argsPtr == nullptr) return 1;
      final callbackId = argsPtr.ref.callbackId;
      final callback = _callbackRegistry[callbackId];
      if (callback == null) return 1;
      return callback(
        argsPtr.ref.storeCtx,
        argsPtr.ref.arg1,
        argsPtr.ref.arg2,
        argsPtr.ref.arg3,
        argsPtr.ref.direction,
      );
    } catch (_) {
      return 1;
    }
  }
  
  // ============================================================================
  // CALLBACK IMPLEMENTATIONS (called by dispatch function)
  // ============================================================================

  // Native helper bindings (bound once, used by callbacks)
  static bool _nativeHelpersBound = false;

  static late final Pointer<SignalFfiError> Function(
    Pointer<Uint32>,
    _SignalConstPointerProtocolAddress,
  ) _addressGetDeviceId;

  static late final Pointer<SignalFfiError> Function(
    Pointer<Pointer<Utf8>>,
    _SignalConstPointerProtocolAddress,
  ) _addressGetName;

  static late final void Function(Pointer<Int8>) _freeString;
  static late final void Function(Pointer<Uint8>, int) _freeBuffer;

  static late final Pointer<SignalFfiError> Function(
    Pointer<_SignalMutPointerSessionRecord>,
    SignalBorrowedBuffer,
  ) _sessionRecordDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalOwnedBuffer>,
    _SignalConstPointerSessionRecord,
  ) _sessionRecordSerialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalMutPointerPrivateKey>,
    SignalBorrowedBuffer,
  ) _privateKeyDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalMutPointerPublicKey>,
    SignalBorrowedBuffer,
  ) _publicKeyDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalOwnedBuffer>,
    SignalConstPointerPublicKey,
  ) _publicKeySerialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<_SignalMutPointerPreKeyRecord>,
    SignalBorrowedBuffer,
  ) _preKeyRecordDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalOwnedBuffer>,
    _SignalConstPointerPreKeyRecord,
  ) _preKeyRecordSerialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<_SignalMutPointerSignedPreKeyRecord>,
    SignalBorrowedBuffer,
  ) _signedPreKeyRecordDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalOwnedBuffer>,
    _SignalConstPointerSignedPreKeyRecord,
  ) _signedPreKeyRecordSerialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<_SignalMutPointerKyberPreKeyRecord>,
    SignalBorrowedBuffer,
  ) _kyberPreKeyRecordDeserialize;

  static late final Pointer<SignalFfiError> Function(
    Pointer<SignalOwnedBuffer>,
    _SignalConstPointerKyberPreKeyRecord,
  ) _kyberPreKeyRecordSerialize;

  static void _ensureNativeHelpersBound(SignalFFIBindings ffiBindings) {
    if (_nativeHelpersBound) return;

    final lib = ffiBindings.library;

    _addressGetDeviceId = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<Uint32>, _SignalConstPointerProtocolAddress)>>(
          'signal_address_get_device_id',
        )
        .asFunction();

    _addressGetName = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<Pointer<Utf8>>, _SignalConstPointerProtocolAddress)>>(
          'signal_address_get_name',
        )
        .asFunction();

    _freeString = lib
        .lookup<NativeFunction<Void Function(Pointer<Int8>)>>(
          'signal_free_string',
        )
        .asFunction();

    _freeBuffer = lib
        .lookup<NativeFunction<Void Function(Pointer<Uint8>, IntPtr)>>(
          'signal_free_buffer',
        )
        .asFunction();

    _sessionRecordDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<_SignalMutPointerSessionRecord>,
                    SignalBorrowedBuffer)>>(
          'signal_session_record_deserialize',
        )
        .asFunction();

    _sessionRecordSerialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalOwnedBuffer>, _SignalConstPointerSessionRecord)>>(
          'signal_session_record_serialize',
        )
        .asFunction();

    _privateKeyDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(Pointer<SignalMutPointerPrivateKey>,
                    SignalBorrowedBuffer)>>(
          'signal_privatekey_deserialize',
        )
        .asFunction();

    _publicKeyDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalMutPointerPublicKey>, SignalBorrowedBuffer)>>(
          'signal_publickey_deserialize',
        )
        .asFunction();

    _publicKeySerialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalOwnedBuffer>, SignalConstPointerPublicKey)>>(
          'signal_publickey_serialize',
        )
        .asFunction();

    _preKeyRecordDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<_SignalMutPointerPreKeyRecord>, SignalBorrowedBuffer)>>(
          'signal_pre_key_record_deserialize',
        )
        .asFunction();

    _preKeyRecordSerialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalOwnedBuffer>, _SignalConstPointerPreKeyRecord)>>(
          'signal_pre_key_record_serialize',
        )
        .asFunction();

    _signedPreKeyRecordDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<_SignalMutPointerSignedPreKeyRecord>,
                    SignalBorrowedBuffer)>>(
          'signal_signed_pre_key_record_deserialize',
        )
        .asFunction();

    _signedPreKeyRecordSerialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalOwnedBuffer>, _SignalConstPointerSignedPreKeyRecord)>>(
          'signal_signed_pre_key_record_serialize',
        )
        .asFunction();

    _kyberPreKeyRecordDeserialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<_SignalMutPointerKyberPreKeyRecord>,
                    SignalBorrowedBuffer)>>(
          'signal_kyber_pre_key_record_deserialize',
        )
        .asFunction();

    _kyberPreKeyRecordSerialize = lib
        .lookup<
            NativeFunction<
                Pointer<SignalFfiError> Function(
                    Pointer<SignalOwnedBuffer>, _SignalConstPointerKyberPreKeyRecord)>>(
          'signal_kyber_pre_key_record_serialize',
        )
        .asFunction();

    _nativeHelpersBound = true;
  }

  static ({String name, int deviceId}) _readAddress(
    _SignalStoreContext context,
    Pointer<_SignalConstPointerProtocolAddress> addressPtr,
  ) {
    _ensureNativeHelpersBound(context.ffiBindings);

    final outName = malloc<Pointer<Utf8>>();
    try {
      final err = _addressGetName(outName, addressPtr.ref);
      context.ffiBindings.checkError(err);
      final namePtr = outName.value;
      final name = namePtr.toDartString();
      _freeString(namePtr.cast<Int8>());

      final outDevice = malloc<Uint32>();
      try {
        final err2 = _addressGetDeviceId(outDevice, addressPtr.ref);
        context.ffiBindings.checkError(err2);
        return (name: name, deviceId: outDevice.value);
      } finally {
        malloc.free(outDevice);
      }
    } finally {
      malloc.free(outName);
    }
  }

  static Uint8List _serializeOwnedBufferToBytesAndFree(
    SignalFFIBindings ffiBindings,
    Pointer<SignalOwnedBuffer> buf,
  ) {
    final bytes = Uint8List.fromList(
      buf.ref.base.asTypedList(buf.ref.length),
    );
    _freeBuffer(buf.ref.base, buf.ref.length);
    malloc.free(buf);
    return bytes;
  }
  
  /// Load session callback implementation
  static int _loadSessionCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // recordp
    Pointer<Void> arg2, // address
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    final recordpTyped = arg1.cast<_SignalMutPointerSessionRecord>();
    if (context == null) {
      recordpTyped.ref.raw = nullptr;
      return 0;
    }
    
    final addressTyped = arg2.cast<_SignalConstPointerProtocolAddress>();

    try {
      final addr = _readAddress(context, addressTyped);
      final bytes = context.sessionManager.getCachedSessionRecordBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
      );
      if (bytes == null) {
        recordpTyped.ref.raw = nullptr;
        return 0;
      }

      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(bytes.length);
      try {
        data.asTypedList(bytes.length).setAll(0, bytes);
        borrowed.ref.base = data;
        borrowed.ref.length = bytes.length;
        final err = _sessionRecordDeserialize(recordpTyped, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log(
        'load_session failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      recordpTyped.ref.raw = nullptr;
      return 0;
    }
  }
  
  /// Store session callback implementation
  static int _storeSessionCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // address
    Pointer<Void> arg2, // record
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final addressTyped = arg1.cast<_SignalConstPointerProtocolAddress>();
    final recordTyped = arg2.cast<_SignalConstPointerSessionRecord>();
    try {
      final addr = _readAddress(context, addressTyped);
      final out = malloc<SignalOwnedBuffer>();
      final err = _sessionRecordSerialize(out, recordTyped.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);

      context.sessionManager.cacheSessionRecordBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
        bytes: bytes,
      );
      unawaited(
        context.sessionManager.saveSessionRecordBytes(
          addressName: addr.name,
          deviceId: addr.deviceId,
          bytes: bytes,
        ),
      );
      return 0;
    } catch (e, st) {
      developer.log(
        'store_session failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 1;
    }
  }
  
  /// Get identity key pair callback implementation
  static int _getIdentityKeyPairCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // keyp
    Pointer<Void> arg2, // unused
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final keypTyped = arg1.cast<SignalMutPointerPrivateKey>();

    final identity = context.keyManager.cachedIdentityKeyPair;
    if (identity == null) {
      return 1;
    }

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(identity.privateKey.length);
      try {
        data.asTypedList(identity.privateKey.length).setAll(0, identity.privateKey);
        borrowed.ref.base = data;
        borrowed.ref.length = identity.privateKey.length;
        final err = _privateKeyDeserialize(keypTyped, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log(
        'get_identity_key_pair failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 1;
    }
  }
  
  /// Get local registration ID callback implementation
  static int _getLocalRegistrationIdCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // idp
    Pointer<Void> arg2, // unused
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final idpTyped = arg1.cast<Uint32>();

    final regId = context.keyManager.cachedRegistrationId;
    if (regId == null) return 1;
    idpTyped.value = regId;
    return 0;
  }
  
  /// Save identity key callback implementation
  static int _saveIdentityKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // address
    Pointer<Void> arg2, // public_key
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final addressTyped = arg1.cast<_SignalConstPointerProtocolAddress>();
    final publicKeyTyped = arg2.cast<SignalConstPointerPublicKey>();

    try {
      final addr = _readAddress(context, addressTyped);

      final out = malloc<SignalOwnedBuffer>();
      final err = _publicKeySerialize(out, publicKeyTyped.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);

      final existing = context.sessionManager.getCachedRemoteIdentityKeyBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
      );
      final isReplace = existing != null && !_bytesEqual(existing, bytes);

      context.sessionManager.cacheRemoteIdentityKeyBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
        bytes: bytes,
      );
      unawaited(
        context.sessionManager.saveRemoteIdentityKeyBytes(
          addressName: addr.name,
          deviceId: addr.deviceId,
          bytes: bytes,
        ),
      );

      return isReplace ? 1 : 0;
    } catch (e, st) {
      developer.log(
        'save_identity failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 1;
    }
  }
  
  /// Get identity key callback implementation
  static int _getIdentityKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // public_keyp
    Pointer<Void> arg2, // address
    Pointer<Void> arg3, // unused
    int direction, // unused
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final publicKeypTyped = arg1.cast<SignalMutPointerPublicKey>();
    final addressTyped = arg2.cast<_SignalConstPointerProtocolAddress>();

    try {
      final addr = _readAddress(context, addressTyped);
      final bytes = context.sessionManager.getCachedRemoteIdentityKeyBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
      );
      if (bytes == null) {
        publicKeypTyped.ref.raw = nullptr;
        return 0;
      }

      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(bytes.length);
      try {
        data.asTypedList(bytes.length).setAll(0, bytes);
        borrowed.ref.base = data;
        borrowed.ref.length = bytes.length;
        final err = _publicKeyDeserialize(publicKeypTyped, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log(
        'get_identity failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      publicKeypTyped.ref.raw = nullptr;
      return 1;
    }
  }
  
  /// Is trusted identity callback implementation
  static int _isTrustedIdentityCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // address
    Pointer<Void> arg2, // public_key
    Pointer<Void> arg3, // unused
    int direction, // u32 direction
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) {
      return 1;
    }
    
    final addressTyped = arg1.cast<_SignalConstPointerProtocolAddress>();
    final publicKeyTyped = arg2.cast<SignalConstPointerPublicKey>();

    try {
      final addr = _readAddress(context, addressTyped);
      final existing = context.sessionManager.getCachedRemoteIdentityKeyBytes(
        addressName: addr.name,
        deviceId: addr.deviceId,
      );
      if (existing == null) {
        return 1; // TOFU: trusted until we have a stored key.
      }

      final out = malloc<SignalOwnedBuffer>();
      final err = _publicKeySerialize(out, publicKeyTyped.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);
      return _bytesEqual(existing, bytes) ? 1 : 0;
    } catch (e, st) {
      developer.log(
        'is_trusted_identity failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ============================================================================
  // PREKEY / SIGNED PREKEY / KYBER PREKEY STORE CALLBACKS
  // ============================================================================

  static int _loadPreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // recordp
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3, // unused
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final recordp = arg1.cast<_SignalMutPointerPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;

    final bytes = context.keyManager.getCachedPreKeyRecord(id);
    if (bytes == null) {
      recordp.ref.raw = nullptr;
      return 0;
    }

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(bytes.length);
      try {
        data.asTypedList(bytes.length).setAll(0, bytes);
        borrowed.ref.base = data;
        borrowed.ref.length = bytes.length;
        final err = _preKeyRecordDeserialize(recordp, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log('load_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      recordp.ref.raw = nullptr;
      return 1;
    }
  }

  static int _storePreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // record (const)
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final record = arg1.cast<_SignalConstPointerPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final out = malloc<SignalOwnedBuffer>();
      final err = _preKeyRecordSerialize(out, record.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);
      unawaited(context.keyManager.storePreKeyRecord(id: id, serialized: bytes));
      return 0;
    } catch (e, st) {
      developer.log('store_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      return 1;
    }
  }

  static int _removePreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // id (u32*)
    Pointer<Void> arg2,
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final id = arg1.cast<Uint32>().value;
    unawaited(context.keyManager.removePreKeyRecord(id));
    return 0;
  }

  static int _loadSignedPreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // recordp
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final recordp = arg1.cast<_SignalMutPointerSignedPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;
    final bytes = context.keyManager.getCachedSignedPreKeyRecord(id);
    if (bytes == null) {
      recordp.ref.raw = nullptr;
      return 0;
    }

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(bytes.length);
      try {
        data.asTypedList(bytes.length).setAll(0, bytes);
        borrowed.ref.base = data;
        borrowed.ref.length = bytes.length;
        final err = _signedPreKeyRecordDeserialize(recordp, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log('load_signed_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      recordp.ref.raw = nullptr;
      return 1;
    }
  }

  static int _storeSignedPreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // record (const)
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final record = arg1.cast<_SignalConstPointerSignedPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final out = malloc<SignalOwnedBuffer>();
      final err = _signedPreKeyRecordSerialize(out, record.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);
      unawaited(context.keyManager.storeSignedPreKeyRecord(id: id, serialized: bytes));
      unawaited(context.keyManager.setCurrentSignedPreKeyId(id));
      return 0;
    } catch (e, st) {
      developer.log('store_signed_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      return 1;
    }
  }

  static int _loadKyberPreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // recordp
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final recordp = arg1.cast<_SignalMutPointerKyberPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;
    final bytes = context.keyManager.getCachedKyberPreKeyRecord(id);
    if (bytes == null) {
      recordp.ref.raw = nullptr;
      return 0;
    }

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final borrowed = malloc<SignalBorrowedBuffer>();
      final data = malloc<Uint8>(bytes.length);
      try {
        data.asTypedList(bytes.length).setAll(0, bytes);
        borrowed.ref.base = data;
        borrowed.ref.length = bytes.length;
        final err = _kyberPreKeyRecordDeserialize(recordp, borrowed.ref);
        context.ffiBindings.checkError(err);
        return 0;
      } finally {
        malloc.free(data);
        malloc.free(borrowed);
      }
    } catch (e, st) {
      developer.log('load_kyber_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      recordp.ref.raw = nullptr;
      return 1;
    }
  }

  static int _storeKyberPreKeyCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // record (const)
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3,
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final record = arg1.cast<_SignalConstPointerKyberPreKeyRecord>();
    final id = arg2.cast<Uint32>().value;

    try {
      _ensureNativeHelpersBound(context.ffiBindings);
      final out = malloc<SignalOwnedBuffer>();
      final err = _kyberPreKeyRecordSerialize(out, record.ref);
      context.ffiBindings.checkError(err);
      final bytes = _serializeOwnedBufferToBytesAndFree(context.ffiBindings, out);
      unawaited(context.keyManager.storeKyberPreKeyRecord(id: id, serialized: bytes));
      unawaited(context.keyManager.setCurrentKyberPreKeyId(id));
      return 0;
    } catch (e, st) {
      developer.log('store_kyber_pre_key failed: $e', name: _logName, error: e, stackTrace: st);
      return 1;
    }
  }

  static int _markKyberPreKeyUsedCallbackImpl(
    Pointer<Void> storeCtx,
    Pointer<Void> arg1, // base_key (const public key)
    Pointer<Void> arg2, // id (u32*)
    Pointer<Void> arg3, // signed_prekey_id (u32*)
    int direction,
  ) {
    final context = _contextMap[storeCtx.address];
    if (context == null) return 1;
    final id = arg2.cast<Uint32>().value;
    // Best-effort: nothing to do yet; future: track used kyber prekeys.
    developer.log('Kyber prekey marked used: $id', name: _logName);
    return 0;
  }

  /// Create session store struct for FFI
  /// 
  /// Returns a pointer to SignalSessionStore struct
  /// 
  /// Uses Rust wrapper functions that bridge Dart callbacks with libsignal-ffi.
  // ignore: library_private_types_in_public_api - FFI bindings require private struct types
  Pointer<_SignalSessionStore> createSessionStore() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }
    
    final store = malloc.allocate<_SignalSessionStore>(sizeOf<_SignalSessionStore>());
    
    // Set context
    store.ref.ctx = _contextPtr.cast();
    
    // Get function pointers from Rust wrapper (these call the registered Dart callbacks)
    // Cast void* to the correct function pointer type
    store.ref.load_session = _rustWrapper.getLoadSessionWrapperPtr().cast();
    store.ref.store_session = _rustWrapper.getStoreSessionWrapperPtr().cast();
    
    return store;
  }
  
  /// Create identity key store struct for FFI
  /// 
  /// Returns a pointer to SignalIdentityKeyStore struct
  /// 
  /// Uses Rust wrapper functions that bridge Dart callbacks with libsignal-ffi.
  // ignore: library_private_types_in_public_api - FFI bindings require private struct types
  Pointer<_SignalIdentityKeyStore> createIdentityKeyStore() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }
    
    final store = malloc.allocate<_SignalIdentityKeyStore>(sizeOf<_SignalIdentityKeyStore>());
    
    // Set context
    store.ref.ctx = _contextPtr.cast();
    
    // Get function pointers from Rust wrapper (these call the registered Dart callbacks)
    store.ref.get_identity_key_pair = _rustWrapper.getGetIdentityKeyPairWrapperPtr().cast();
    store.ref.get_local_registration_id = _rustWrapper.getGetLocalRegistrationIdWrapperPtr().cast();
    store.ref.save_identity = _rustWrapper.getSaveIdentityKeyWrapperPtr().cast();
    store.ref.get_identity = _rustWrapper.getGetIdentityKeyWrapperPtr().cast();
    store.ref.is_trusted_identity = _rustWrapper.getIsTrustedIdentityWrapperPtr().cast();
    
    return store;
  }

  /// Create prekey store struct for FFI (one-time prekeys).
  // ignore: library_private_types_in_public_api - FFI bindings require private struct types
  Pointer<_SignalPreKeyStore> createPreKeyStore() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }

    final store = malloc.allocate<_SignalPreKeyStore>(sizeOf<_SignalPreKeyStore>());
    store.ref.ctx = _contextPtr.cast();
    store.ref.load_pre_key = _rustWrapper.getLoadPreKeyWrapperPtr().cast();
    store.ref.store_pre_key = _rustWrapper.getStorePreKeyWrapperPtr().cast();
    store.ref.remove_pre_key = _rustWrapper.getRemovePreKeyWrapperPtr().cast();
    return store;
  }

  /// Create signed prekey store struct for FFI.
  // ignore: library_private_types_in_public_api - FFI bindings require private struct types
  Pointer<_SignalSignedPreKeyStore> createSignedPreKeyStore() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }

    final store = malloc
        .allocate<_SignalSignedPreKeyStore>(sizeOf<_SignalSignedPreKeyStore>());
    store.ref.ctx = _contextPtr.cast();
    store.ref.load_signed_pre_key =
        _rustWrapper.getLoadSignedPreKeyWrapperPtr().cast();
    store.ref.store_signed_pre_key =
        _rustWrapper.getStoreSignedPreKeyWrapperPtr().cast();
    return store;
  }

  /// Create Kyber prekey store struct for FFI.
  // ignore: library_private_types_in_public_api - FFI bindings require private struct types
  Pointer<_SignalKyberPreKeyStore> createKyberPreKeyStore() {
    if (!_rustWrapper.isInitialized) {
      throw SignalProtocolException(
        'Rust wrapper not initialized. Call SignalRustWrapperBindings.initialize() first.',
      );
    }

    final store = malloc
        .allocate<_SignalKyberPreKeyStore>(sizeOf<_SignalKyberPreKeyStore>());
    store.ref.ctx = _contextPtr.cast();
    store.ref.load_kyber_pre_key =
        _rustWrapper.getLoadKyberPreKeyWrapperPtr().cast();
    store.ref.store_kyber_pre_key =
        _rustWrapper.getStoreKyberPreKeyWrapperPtr().cast();
    store.ref.mark_kyber_pre_key_used =
        _rustWrapper.getMarkKyberPreKeyUsedWrapperPtr().cast();
    return store;
  }
  
  /// Dispose resources
  /// 
  /// Safely disposes all resources, even if the native library is broken.
  /// This method should never throw or crash, even if disposal fails.
  void dispose() {
    _unregisterContext();
    
    // Safely free allocated memory
    try {
      final contextIdPtr = _contextPtr.cast<IntPtr>();
      malloc.free(contextIdPtr);
    } catch (e) {
      // Log but don't throw - memory may already be freed or invalid
      developer.log(
        'Error freeing memory during dispose: $e',
        name: _logName,
        error: e,
      );
    }
    
    _initialized = false;
  }
  
  // ============================================================================
  // CALLBACK IMPLEMENTATIONS
  // ============================================================================
  
  // Static lookup table for store contexts
  // Maps context pointer address to actual store context
  static final Map<int, _SignalStoreContext> _contextMap = {};
  
  /// Register store context for callbacks
  void _registerContext() {
    // Key by the actual pointer address used as store_ctx.
    _contextMap[_contextPtr.address] = _SignalStoreContext(
      keyManager: _keyManager,
      sessionManager: _sessionManager,
      ffiBindings: _ffiBindings,
    );
  }
  
  /// Unregister store context
  void _unregisterContext() {
    _contextMap.remove(_contextPtr.address);
  }
  
  /// Get session after X3DH key exchange
  /// 
  /// After X3DH key exchange completes, the session is stored via callbacks.
  /// This method loads the session from the session manager.
  /// 
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// 
  /// **Returns:**
  /// Session state if found, null otherwise
  Future<SignalSessionState?> getSessionAfterX3DH(String recipientId) async {
    try {
      // Load session from session manager
      // The session was stored via storeSession callback during X3DH
      return await _sessionManager.getSession(recipientId);
    } catch (e, stackTrace) {
      developer.log(
        'Error loading session after X3DH: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
}

// ============================================================================
// FFI TYPE DEFINITIONS FOR STORE STRUCTS
// ============================================================================

// These structs are defined in signal_ffi_bindings.dart
// We import them here to avoid duplication
// Note: Since they're private (start with _), we can't import them directly
// So we redefine them here to match (they must be identical)

/// C struct: SignalMutPointerSessionRecord
/// (Duplicate definition - must match signal_ffi_bindings.dart)
final class _SignalMutPointerSessionRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalConstPointerSessionRecord
/// (Duplicate definition - must match signal_ffi_bindings.dart)
final class _SignalConstPointerSessionRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalConstPointerProtocolAddress
/// (Duplicate definition - must match signal_ffi_bindings.dart)
final class _SignalConstPointerProtocolAddress extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalMutPointerPreKeyRecord
final class _SignalMutPointerPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalConstPointerPreKeyRecord
final class _SignalConstPointerPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalMutPointerSignedPreKeyRecord
final class _SignalMutPointerSignedPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalConstPointerSignedPreKeyRecord
final class _SignalConstPointerSignedPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalMutPointerKyberPreKeyRecord
final class _SignalMutPointerKyberPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

/// C struct: SignalConstPointerKyberPreKeyRecord
final class _SignalConstPointerKyberPreKeyRecord extends Struct {
  external Pointer<Opaque> raw;
}

// ============================================================================
// CALLBACK FUNCTION TYPEDEFS
// ============================================================================
// Note: Typedefs must be defined before structs that use them

// Dispatch callback (single parameter - Dart CAN create function pointers for this!)
// This is the key to the callback ID dispatch pattern
// Note: These typedefs are kept for documentation purposes, but the actual implementation
// uses the Rust wrapper callback ID dispatch pattern instead
// ignore: unused_element - Kept for documentation/reference
typedef _NativeDispatchCallback = Int32 Function(Pointer<CallbackArgs>);
// ignore: unused_element - Kept for documentation/reference
typedef _DispatchCallback = int Function(Pointer<CallbackArgs>);

// ============================================================================
// STORE STRUCT CALLBACK SIGNATURES (matching libsignal-ffi API)
// ============================================================================
// These match the exact callback signatures expected by libsignal-ffi
// The wrapper functions have these same signatures

// Load session: int (*)(void *store_ctx, SignalMutPointerSessionRecord *recordp, SignalConstPointerProtocolAddress address)
typedef _NativeLoadSessionCallback = IntPtr Function(Pointer<Void>, Pointer<_SignalMutPointerSessionRecord>, Pointer<_SignalConstPointerProtocolAddress>);

// Store session: int (*)(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerSessionRecord record)
typedef _NativeStoreSessionCallback = IntPtr Function(Pointer<Void>, Pointer<_SignalConstPointerProtocolAddress>, Pointer<_SignalConstPointerSessionRecord>);

// Get identity key pair: int (*)(void *store_ctx, SignalMutPointerPrivateKey *keyp)
typedef _NativeGetIdentityKeyPairCallback = IntPtr Function(Pointer<Void>, Pointer<SignalMutPointerPrivateKey>);

// Get local registration ID: int (*)(void *store_ctx, uint32_t *idp)
typedef _NativeGetLocalRegistrationIdCallback = IntPtr Function(Pointer<Void>, Pointer<Uint32>);

// Save identity key: int (*)(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key)
typedef _NativeSaveIdentityKeyCallback = IntPtr Function(Pointer<Void>, Pointer<_SignalConstPointerProtocolAddress>, Pointer<SignalConstPointerPublicKey>);

// Get identity key: int (*)(void *store_ctx, SignalMutPointerPublicKey *public_keyp, SignalConstPointerProtocolAddress address)
typedef _NativeGetIdentityKeyCallback = IntPtr Function(Pointer<Void>, Pointer<SignalMutPointerPublicKey>, Pointer<_SignalConstPointerProtocolAddress>);

// Is trusted identity: int (*)(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key, unsigned int direction)
typedef _NativeIsTrustedIdentityCallback = IntPtr Function(Pointer<Void>, Pointer<_SignalConstPointerProtocolAddress>, Pointer<SignalConstPointerPublicKey>, Uint32);

// ============================================================================
// STORE STRUCT DEFINITIONS (after typedefs)
// ============================================================================

/// C struct: SignalSessionStore
/// 
/// Uses wrapper function pointers which have the exact signatures libsignal-ffi expects
final class _SignalSessionStore extends Struct {
  external Pointer<Void> ctx;
  external Pointer<NativeFunction<_NativeLoadSessionCallback>> load_session;
  external Pointer<NativeFunction<_NativeStoreSessionCallback>> store_session;
}

/// C struct: SignalIdentityKeyStore
/// 
/// Uses wrapper function pointers which have the exact signatures libsignal-ffi expects
final class _SignalIdentityKeyStore extends Struct {
  external Pointer<Void> ctx;
  external Pointer<NativeFunction<_NativeGetIdentityKeyPairCallback>> get_identity_key_pair;
  external Pointer<NativeFunction<_NativeGetLocalRegistrationIdCallback>> get_local_registration_id;
  external Pointer<NativeFunction<_NativeSaveIdentityKeyCallback>> save_identity;
  external Pointer<NativeFunction<_NativeGetIdentityKeyCallback>> get_identity;
  external Pointer<NativeFunction<_NativeIsTrustedIdentityCallback>> is_trusted_identity;
}

/// C struct: SignalPreKeyStore
///
/// These store structs are wired through the Rust wrapper + callback dispatch bridge.
/// We keep the function pointers as `void*` here to avoid duplicating (and drifting)
/// callback signatures in Dart; the wrapper guarantees the ABI matches libsignal-ffi.
final class _SignalPreKeyStore extends Struct {
  external Pointer<Void> ctx;
  external Pointer<Void> load_pre_key;
  external Pointer<Void> store_pre_key;
  external Pointer<Void> remove_pre_key;
}

/// C struct: SignalSignedPreKeyStore
final class _SignalSignedPreKeyStore extends Struct {
  external Pointer<Void> ctx;
  external Pointer<Void> load_signed_pre_key;
  external Pointer<Void> store_signed_pre_key;
}

/// C struct: SignalKyberPreKeyStore
final class _SignalKyberPreKeyStore extends Struct {
  external Pointer<Void> ctx;
  external Pointer<Void> load_kyber_pre_key;
  external Pointer<Void> store_kyber_pre_key;
  external Pointer<Void> mark_kyber_pre_key_used;
}
