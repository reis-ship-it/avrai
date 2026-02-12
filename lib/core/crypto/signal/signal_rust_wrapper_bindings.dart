// Signal Protocol Rust Wrapper Bindings
// Phase 14: Signal Protocol Implementation - Option 1
//
// This file provides Dart bindings to the Rust wrapper layer.
// The Rust wrapper solves the Dart FFI callback registration limitation.
//
// Architecture:
//   Dart → C FFI → Rust Wrapper → libsignal-ffi (C library) → Signal Protocol

import 'dart:developer' as developer;
import 'dart:ffi';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_library_manager.dart';

// ============================================================================
// FFI TYPE DEFINITIONS - CallbackArgs Struct
// ============================================================================

/// Callback arguments struct (matches Rust CallbackArgs)
/// 
/// Single-parameter struct pattern - Dart CAN create function pointers for this!
/// 
/// **Note:** This struct must be exported/accessible from signal_ffi_store_callbacks.dart
final class CallbackArgs extends Struct {
  @Uint64()
  external int callbackId; // u64 in Rust
  
  external Pointer<Void> storeCtx; // *mut c_void in Rust
  external Pointer<Void> arg1; // *mut c_void in Rust
  external Pointer<Void> arg2; // *mut c_void in Rust
  external Pointer<Void> arg3; // *mut c_void in Rust
  @Uint32()
  external int direction; // u32 in Rust
}

// ============================================================================
// FFI FUNCTION TYPEDEFS - Callback Registration
// ============================================================================

// Dispatch function (single parameter - Dart CAN create function pointers for this!)
// Note: These typedefs are kept for documentation purposes
// ignore: unused_element - Kept for documentation/reference
typedef _NativeDispatchCallback = Int32 Function(Pointer<CallbackArgs>);
// ignore: unused_element - Kept for documentation/reference
typedef _DispatchCallback = int Function(Pointer<CallbackArgs>);

// Registration function (takes void* for dispatch function pointer)
typedef _NativeRegisterDispatchCallback = Void Function(Pointer<Void>);
typedef _RegisterDispatchCallback = void Function(Pointer<Void>);

// Function pointer getters (return void*)
typedef _NativeGetWrapperPtr = Pointer<Void> Function();
typedef _GetWrapperPtr = Pointer<Void> Function();

/// Signal Protocol Rust Wrapper Bindings
/// 
/// Provides Dart interface to the Rust wrapper layer for callback registration.
/// 
/// The Rust wrapper can create function pointers that Dart FFI cannot,
/// solving the callback registration limitation.
class SignalRustWrapperBindings {
  static const String _logName = 'SignalRustWrapperBindings';
  
  // Use unified library manager for all library loading
  final SignalLibraryManager _libManager = SignalLibraryManager();
  
  DynamicLibrary? _lib;
  bool _initialized = false;
  
  // Dispatch callback registration
  late final _RegisterDispatchCallback _registerDispatchCallback;
  
  // Function pointer getters
  late final _GetWrapperPtr _getLoadSessionWrapperPtr;
  late final _GetWrapperPtr _getStoreSessionWrapperPtr;
  late final _GetWrapperPtr _getGetIdentityKeyPairWrapperPtr;
  late final _GetWrapperPtr _getGetLocalRegistrationIdWrapperPtr;
  late final _GetWrapperPtr _getSaveIdentityKeyWrapperPtr;
  late final _GetWrapperPtr _getGetIdentityKeyWrapperPtr;
  late final _GetWrapperPtr _getIsTrustedIdentityWrapperPtr;
  late final _GetWrapperPtr _getLoadPreKeyWrapperPtr;
  late final _GetWrapperPtr _getStorePreKeyWrapperPtr;
  late final _GetWrapperPtr _getRemovePreKeyWrapperPtr;
  late final _GetWrapperPtr _getLoadSignedPreKeyWrapperPtr;
  late final _GetWrapperPtr _getStoreSignedPreKeyWrapperPtr;
  late final _GetWrapperPtr _getLoadKyberPreKeyWrapperPtr;
  late final _GetWrapperPtr _getStoreKyberPreKeyWrapperPtr;
  late final _GetWrapperPtr _getMarkKyberPreKeyUsedWrapperPtr;
  
  // Library loading is now handled by SignalLibraryManager
  // Removed _loadLibrary() method
  
  /// Initialize Rust wrapper bindings
  Future<void> initialize() async {
    if (_initialized) {
      developer.log('Rust wrapper bindings already initialized', name: _logName);
      return;
    }
    
    try {
      // Use unified library manager for loading
      _lib = _libManager.getWrapperLibrary();
      
      // Bind dispatch callback registration
      _registerDispatchCallback = _lib!
          .lookup<NativeFunction<_NativeRegisterDispatchCallback>>('spots_rust_register_dispatch_callback')
          .asFunction<_RegisterDispatchCallback>();
      
      // Bind function pointer getters
      _getLoadSessionWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_load_session_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getStoreSessionWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_store_session_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getGetIdentityKeyPairWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_get_identity_key_pair_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getGetLocalRegistrationIdWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_get_local_registration_id_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getSaveIdentityKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_save_identity_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getGetIdentityKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_get_identity_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _getIsTrustedIdentityWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_is_trusted_identity_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getLoadPreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_load_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getStorePreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_store_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getRemovePreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_remove_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getLoadSignedPreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_load_signed_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getStoreSignedPreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_store_signed_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getLoadKyberPreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_load_kyber_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getStoreKyberPreKeyWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_store_kyber_pre_key_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();

      _getMarkKyberPreKeyUsedWrapperPtr = _lib!
          .lookup<NativeFunction<_NativeGetWrapperPtr>>('spots_rust_get_mark_kyber_pre_key_used_wrapper_ptr')
          .asFunction<_GetWrapperPtr>();
      
      _initialized = true;
      developer.log('✅ Rust wrapper bindings initialized', name: _logName);
    } on ArgumentError catch (e) {
      // Convert ArgumentError (library not found) to SignalProtocolException
      final error = SignalProtocolException('Failed to load Rust wrapper library: ${e.message}');
      developer.log('Failed to initialize Rust wrapper bindings: $error', error: error, name: _logName);
      throw error;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing Rust wrapper bindings: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw SignalProtocolException(
        'Failed to initialize Rust wrapper bindings: $e',
        originalError: e,
      );
    }
  }
  
  /// Check if bindings are initialized
  bool get isInitialized => _initialized;
  
  // ============================================================================
  // CALLBACK REGISTRATION (DART → RUST)
  // ============================================================================
  
  /// Register the dispatch callback function
  /// 
  /// **Note:** Dart CAN create function pointers for `int Function(Pointer<CallbackArgs>)`
  /// because it's a single-parameter struct pointer. This works around the Dart FFI limitation!
  void registerDispatchCallback(Pointer<Void> dispatchCallback) {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    _registerDispatchCallback(dispatchCallback);
  }
  
  // ============================================================================
  // FUNCTION POINTER GETTERS (RUST → DART)
  // ============================================================================
  
  /// Get function pointer for load_session wrapper
  /// 
  /// This returns a function pointer that can be passed to libsignal-ffi.
  /// The function pointer has the exact signature libsignal-ffi expects.
  Pointer<Void> getLoadSessionWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getLoadSessionWrapperPtr();
  }
  
  /// Get function pointer for store_session wrapper
  Pointer<Void> getStoreSessionWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getStoreSessionWrapperPtr();
  }
  
  /// Get function pointer for get_identity_key_pair wrapper
  Pointer<Void> getGetIdentityKeyPairWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getGetIdentityKeyPairWrapperPtr();
  }
  
  /// Get function pointer for get_local_registration_id wrapper
  Pointer<Void> getGetLocalRegistrationIdWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getGetLocalRegistrationIdWrapperPtr();
  }
  
  /// Get function pointer for save_identity_key wrapper
  Pointer<Void> getSaveIdentityKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getSaveIdentityKeyWrapperPtr();
  }
  
  /// Get function pointer for get_identity_key wrapper
  Pointer<Void> getGetIdentityKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getGetIdentityKeyWrapperPtr();
  }
  
  /// Get function pointer for is_trusted_identity wrapper
  Pointer<Void> getIsTrustedIdentityWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getIsTrustedIdentityWrapperPtr();
  }

  Pointer<Void> getLoadPreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getLoadPreKeyWrapperPtr();
  }

  Pointer<Void> getStorePreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getStorePreKeyWrapperPtr();
  }

  Pointer<Void> getRemovePreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getRemovePreKeyWrapperPtr();
  }

  Pointer<Void> getLoadSignedPreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getLoadSignedPreKeyWrapperPtr();
  }

  Pointer<Void> getStoreSignedPreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getStoreSignedPreKeyWrapperPtr();
  }

  Pointer<Void> getLoadKyberPreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getLoadKyberPreKeyWrapperPtr();
  }

  Pointer<Void> getStoreKyberPreKeyWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getStoreKyberPreKeyWrapperPtr();
  }

  Pointer<Void> getMarkKyberPreKeyUsedWrapperPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Rust wrapper bindings not initialized. Call initialize() first.');
    }
    return _getMarkKyberPreKeyUsedWrapperPtr();
  }
  
  /// Dispose resources
  void dispose() {
    _lib = null;
    _initialized = false;
    developer.log('Rust wrapper bindings disposed', name: _logName);
  }
}
