import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

class LocalityLibraryManager implements KernelJsonLibraryManager {
  static const String _logName = 'LocalityLibraryManager';
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  DynamicLibrary? _kernelLib;
  @override
  DynamicLibrary getKernelLibrary() {
    if (_kernelLib != null) return _kernelLib!;
    try {
      if (Platform.isIOS) {
        try {
          _kernelLib = DynamicLibrary.open(
            'AVRAILocalityKernel.framework/AVRAILocalityKernel',
          );
        } catch (_) {
          _kernelLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        if (_isFlutterTest) {
          _kernelLib = DynamicLibrary.process();
        } else {
          final currentDir = Directory.current.path;
          final candidatePaths = <String>[
            '$currentDir/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.dylib',
            '$currentDir/runtime/avrai_network/native/locality_kernel/target/release/libavrai_locality_kernel.dylib',
          ];
          final existingPath = candidatePaths.cast<String?>().firstWhere(
                (path) => path != null && File(path).existsSync(),
                orElse: () => null,
              );
          _kernelLib = existingPath == null
              ? DynamicLibrary.open('libavrai_locality_kernel.dylib')
              : DynamicLibrary.open(existingPath);
        }
      } else if (Platform.isAndroid || Platform.isLinux) {
        _kernelLib = DynamicLibrary.open('libavrai_locality_kernel.so');
      } else if (Platform.isWindows) {
        _kernelLib = DynamicLibrary.open('avrai_locality_kernel.dll');
      } else {
        throw UnsupportedError(
          'Unsupported platform for locality kernel library.',
        );
      }
      developer.log('Locality kernel library loaded', name: _logName);
      return _kernelLib!;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load locality kernel library: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
