import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _NativeInvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFreeJsonString = Void Function(Pointer<Utf8>);
typedef _FreeJsonString = void Function(Pointer<Utf8>);

abstract class ForecastKernelLibraryManager {
  DynamicLibrary getKernelLibrary();
}

class DefaultForecastKernelLibraryManager implements ForecastKernelLibraryManager {
  @override
  DynamicLibrary getKernelLibrary() {
    final candidates = _candidatePaths();

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) {
        return DynamicLibrary.open(candidate);
      }
    }
    throw StateError(
      'Forecast kernel library not found in expected locations: ${candidates.join(', ')}',
    );
  }

  List<String> _candidatePaths() {
    final roots = <String>{};
    var cursor = Directory.current.absolute;
    for (var depth = 0; depth < 5; depth++) {
      roots.add(cursor.path);
      final parent = cursor.parent;
      if (parent.path == cursor.path) {
        break;
      }
      cursor = parent;
    }

    final candidates = <String>[];
    for (final root in roots) {
      candidates.addAll(<String>[
        '$root/runtime/avrai_network/native/forecast_kernel/target/debug/libavrai_forecast_kernel.dylib',
        '$root/runtime/avrai_network/native/forecast_kernel/target/release/libavrai_forecast_kernel.dylib',
        '$root/runtime/avrai_network/native/forecast_kernel/macos/libavrai_forecast_kernel.dylib',
      ]);
    }
    return candidates.toSet().toList(growable: false);
  }
}

class ForecastKernelJsonNativeBridge {
  ForecastKernelJsonNativeBridge({
    ForecastKernelLibraryManager? libraryManager,
  }) : _libraryManager =
            libraryManager ?? DefaultForecastKernelLibraryManager();

  final ForecastKernelLibraryManager _libraryManager;

  DynamicLibrary? _lib;
  _InvokeJson? _invokeJson;
  _FreeJsonString? _freeJsonString;
  bool _attemptedInitialization = false;
  bool _available = false;

  bool get isAvailable => _available;

  void initialize() {
    if (_attemptedInitialization) {
      return;
    }
    _attemptedInitialization = true;
    try {
      _lib = _libraryManager.getKernelLibrary();
      _invokeJson = _lib!
          .lookup<NativeFunction<_NativeInvokeJson>>(
            'avrai_forecast_kernel_invoke_json',
          )
          .asFunction<_InvokeJson>();
      _freeJsonString = _lib!
          .lookup<NativeFunction<_NativeFreeJsonString>>(
            'avrai_forecast_kernel_free_string',
          )
          .asFunction<_FreeJsonString>();
      _available = true;
      developer.log(
        'ForecastKernelJsonNativeBridge initialized',
        name: 'ForecastKernelJsonNativeBridge',
      );
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        'ForecastKernelJsonNativeBridge unavailable: $error',
        name: 'ForecastKernelJsonNativeBridge',
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
      throw StateError('Forecast native bridge is not available.');
    }

    final requestPtr = jsonEncode(<String, dynamic>{
      'syscall': syscall,
      'payload': payload,
    }).toNativeUtf8();

    Pointer<Utf8>? responsePtr;
    try {
      responsePtr = _invokeJson!(requestPtr);
      if (responsePtr.address == 0) {
        throw StateError('Forecast native bridge returned a null response.');
      }
      final decoded = jsonDecode(responsePtr.toDartString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Forecast native bridge returned a non-map response.');
      }
      if (decoded['ok'] == false) {
        throw StateError(
          (decoded['error'] as String?) ?? 'Unknown forecast native error',
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
