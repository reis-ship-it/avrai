import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';

import 'package:avrai_runtime_os/kernel/temporal/when_library_manager.dart';
import 'package:ffi/ffi.dart';

typedef _NativeInvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFreeJsonString = Void Function(Pointer<Utf8>);
typedef _FreeJsonString = void Function(Pointer<Utf8>);

abstract class WhenNativeInvocationBridge {
  bool get isAvailable;

  void initialize();

  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class WhenNativeBridgeBindings implements WhenNativeInvocationBridge {
  static const String _logName = 'WhenNativeBridgeBindings';

  WhenNativeBridgeBindings({
    WhenLibraryManager? libraryManager,
  }) : _libraryManager = libraryManager ?? WhenLibraryManager();

  final WhenLibraryManager _libraryManager;

  DynamicLibrary? _lib;
  bool _attemptedInitialization = false;
  bool _available = false;
  _InvokeJson? _invokeJson;
  _FreeJsonString? _freeJsonString;

  @override
  bool get isAvailable => _available;

  @override
  void initialize() {
    if (_attemptedInitialization) {
      return;
    }
    _attemptedInitialization = true;

    try {
      _lib = _libraryManager.getKernelLibrary();
      _invokeJson = _lib!
          .lookup<NativeFunction<_NativeInvokeJson>>(
            'avrai_when_kernel_invoke_json',
          )
          .asFunction<_InvokeJson>();
      _freeJsonString = _lib!
          .lookup<NativeFunction<_NativeFreeJsonString>>(
            'avrai_when_kernel_free_string',
          )
          .asFunction<_FreeJsonString>();
      _available = true;
      developer.log('When native bridge initialized', name: _logName);
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        'When native bridge unavailable; using fallback kernel: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    if (!_attemptedInitialization) {
      initialize();
    }
    if (!_available || _invokeJson == null) {
      throw StateError('When native bridge is not available.');
    }

    final requestPtr = jsonEncode(<String, dynamic>{
      'syscall': syscall,
      'payload': payload,
    }).toNativeUtf8();

    Pointer<Utf8>? responsePtr;
    try {
      responsePtr = _invokeJson!(requestPtr);
      if (responsePtr.address == 0) {
        throw StateError('When native bridge returned a null response.');
      }
      final decoded = jsonDecode(responsePtr.toDartString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError('When native bridge returned a non-map response.');
      }
      if (decoded['ok'] == false) {
        throw StateError(
          (decoded['error'] as String?) ?? 'Unknown native when error',
        );
      }
      return decoded;
    } finally {
      malloc.free(requestPtr);
      if (responsePtr != null &&
          responsePtr.address != 0 &&
          _freeJsonString != null) {
        _freeJsonString!(responsePtr);
      }
    }
  }
}
