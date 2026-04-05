import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _NativeInvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFreeJsonString = Void Function(Pointer<Utf8>);
typedef _FreeJsonString = void Function(Pointer<Utf8>);

abstract class KernelJsonLibraryManager {
  DynamicLibrary getKernelLibrary();
}

class KernelJsonNativeBridge {
  KernelJsonNativeBridge({
    required this.logName,
    required this.libraryManager,
    required this.invokeSymbol,
    required this.freeSymbol,
  });

  final String logName;
  final KernelJsonLibraryManager libraryManager;
  final String invokeSymbol;
  final String freeSymbol;

  DynamicLibrary? _lib;
  bool _attemptedInitialization = false;
  bool _available = false;
  _InvokeJson? _invokeJson;
  _FreeJsonString? _freeJsonString;

  bool get isAvailable => _available;

  void initialize() {
    if (_attemptedInitialization) {
      return;
    }
    _attemptedInitialization = true;
    try {
      _lib = libraryManager.getKernelLibrary();
      _invokeJson = _lib!
          .lookup<NativeFunction<_NativeInvokeJson>>(invokeSymbol)
          .asFunction<_InvokeJson>();
      _freeJsonString = _lib!
          .lookup<NativeFunction<_NativeFreeJsonString>>(freeSymbol)
          .asFunction<_FreeJsonString>();
      _available = true;
      developer.log('$logName initialized', name: logName);
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        '$logName unavailable: $error',
        name: logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    if (!_attemptedInitialization) {
      initialize();
    }
    if (!_available || _invokeJson == null) {
      throw StateError('$logName is not available.');
    }

    final requestPtr = jsonEncode(<String, dynamic>{
      'syscall': syscall,
      'payload': payload,
    }).toNativeUtf8();

    Pointer<Utf8>? responsePtr;
    try {
      responsePtr = _invokeJson!(requestPtr);
      if (responsePtr.address == 0) {
        throw StateError('$logName returned a null response.');
      }
      final decoded = jsonDecode(responsePtr.toDartString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError('$logName returned a non-map response.');
      }
      if (decoded['ok'] == false) {
        throw StateError(
          (decoded['error'] as String?) ?? 'Unknown native kernel error',
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
