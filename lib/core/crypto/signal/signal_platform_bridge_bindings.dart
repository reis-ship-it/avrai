// Platform-Specific Callback Bridge Bindings
// Phase 14: Signal Protocol Implementation - Option 1
//
// This file provides Dart bindings to the platform-specific callback bridge.
// The bridge works around Dart FFI limitations by creating function pointers
// in C/Objective-C/Swift/JNI that Dart cannot create.

import 'dart:developer' as developer;
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_library_manager.dart';

// ============================================================================
// FFI FUNCTION TYPEDEFS
// ============================================================================

// Dispatch callback type (pointer address as Uint64)
// Note: These typedefs are kept for documentation purposes
// ignore: unused_element - Kept for documentation/reference
typedef _NativeDispatchCallback = Int32 Function(Uint64);
// ignore: unused_element - Kept for documentation/reference
typedef _DispatchCallback = Int32 Function(Uint64);

// Registration function by name (takes function name as C string)
typedef _NativeRegisterDispatchCallbackByName = Void Function(Pointer<Utf8>);
typedef _RegisterDispatchCallbackByName = void Function(Pointer<Utf8>);

// Function pointer getter
typedef _NativeGetDispatchFunctionPtr = Pointer<Void> Function();
typedef _GetDispatchFunctionPtr = Pointer<Void> Function();

/// Platform-Specific Callback Bridge Bindings
/// 
/// Provides Dart interface to the platform-specific callback bridge.
/// The bridge creates C function pointers that Dart FFI cannot create.
class SignalPlatformBridgeBindings {
  static const String _logName = 'SignalPlatformBridgeBindings';
  
  // Use unified library manager for all library loading
  final SignalLibraryManager _libManager = SignalLibraryManager();
  
  DynamicLibrary? _lib;
  bool _initialized = false;
  
  late final _RegisterDispatchCallbackByName _registerDispatchCallbackByName;
  late final _GetDispatchFunctionPtr _getDispatchFunctionPtr;
  
  bool get isInitialized => _initialized;
  
  // Expose _lib for use in store callbacks (for dlsym registration)
  DynamicLibrary? get library => _lib;
  
  // Library loading is now handled by SignalLibraryManager
  // Removed _loadLibrary() method
  
  /// Initialize platform bridge bindings
  Future<void> initialize() async {
    if (_initialized) {
      developer.log('Platform bridge bindings already initialized', name: _logName);
      return;
    }
    
    try {
      // Use unified library manager for loading
      _lib = _libManager.getBridgeLibrary();
      
      // Bind registration function by name
      _registerDispatchCallbackByName = _lib!
          .lookup<NativeFunction<_NativeRegisterDispatchCallbackByName>>('signal_register_dispatch_callback_by_name')
          .asFunction<_RegisterDispatchCallbackByName>();
      
      // Bind function pointer getter
      _getDispatchFunctionPtr = _lib!
          .lookup<NativeFunction<_NativeGetDispatchFunctionPtr>>('signal_get_dispatch_function_ptr')
          .asFunction<_GetDispatchFunctionPtr>();
      
      _initialized = true;
      developer.log('Platform bridge bindings initialized successfully', name: _logName);
    } on ArgumentError catch (e) {
      // Convert ArgumentError (library not found) to SignalProtocolException
      final error = SignalProtocolException('Failed to load platform bridge library: ${e.message}');
      developer.log('Failed to initialize platform bridge bindings: $error', error: error, name: _logName);
      throw error;
    } catch (e, st) {
      developer.log('Failed to initialize platform bridge bindings: $e', error: e, stackTrace: st, name: _logName);
      rethrow;
    }
  }
  
  /// Dispose of the loaded library
  void dispose() {
    if (_lib != null) {
      _lib = null;
      _initialized = false;
      developer.log('Platform bridge bindings disposed', name: _logName);
    }
  }
  
  // ============================================================================
  // DART-CALLABLE FUNCTIONS
  // ============================================================================
  
  /// Register the Dart dispatch callback by name (using dlsym)
  /// 
  /// The Dart function must be exported with:
  /// - @pragma('vm:entry-point')
  /// - @pragma('vm:external-name', functionName)
  /// 
  /// The C bridge will use dlsym to find the function by name.
  /// This avoids needing to create function pointers in Dart!
  void registerDispatchCallbackByName(String functionName) {
    if (!_initialized) {
      throw SignalProtocolException('Platform bridge bindings not initialized. Call initialize() first.');
    }
    final namePtr = functionName.toNativeUtf8();
    try {
      _registerDispatchCallbackByName(namePtr);
    } finally {
      malloc.free(namePtr);
    }
  }
  
  /// Get the function pointer for the dispatch callback
  /// 
  /// Returns a C function pointer that can be passed to Rust.
  /// The C function will call the registered Dart callback.
  Pointer<Void> getDispatchFunctionPtr() {
    if (!_initialized) {
      throw SignalProtocolException('Platform bridge bindings not initialized. Call initialize() first.');
    }
    return _getDispatchFunctionPtr();
  }
}
