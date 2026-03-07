import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

class LocalityLibraryManager {
  static const String _logName = 'LocalityLibraryManager';
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  static final LocalityLibraryManager _instance =
      LocalityLibraryManager._internal();

  factory LocalityLibraryManager() => _instance;

  LocalityLibraryManager._internal();

  DynamicLibrary? _kernelLib;
  // ignore: unused_field - Intentionally held to prevent library GC
  static DynamicLibrary? _staticKernelLib;

  DynamicLibrary getKernelLibrary() {
    if (_kernelLib != null) {
      return _kernelLib!;
    }

    try {
      if (Platform.isIOS) {
        developer.log('Loading locality kernel library (iOS)', name: _logName);
        try {
          _kernelLib = DynamicLibrary.open(
            'AVRAILocalityKernel.framework/AVRAILocalityKernel',
          );
        } catch (_) {
          _kernelLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        developer.log(
          'Loading locality kernel library (macOS)${_isFlutterTest ? " [flutter_test]" : ""}',
          name: _logName,
        );
        if (_isFlutterTest) {
          _kernelLib = DynamicLibrary.process();
        } else {
          final currentDir = Directory.current.path;
          final candidatePaths = <String>[
            '$currentDir/runtime/avrai_network/native/locality_kernel/macos/libavrai_locality_kernel.dylib',
            '$currentDir/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.dylib',
            '$currentDir/runtime/avrai_network/native/locality_kernel/target/release/libavrai_locality_kernel.dylib',
          ];
          final existingPath = candidatePaths.cast<String?>().firstWhere(
                (path) => path != null && File(path).existsSync(),
                orElse: () => null,
              );
          if (existingPath != null) {
            _kernelLib = DynamicLibrary.open(existingPath);
          } else {
            try {
              _kernelLib =
                  DynamicLibrary.open('libavrai_locality_kernel.dylib');
            } catch (_) {
              _kernelLib = DynamicLibrary.process();
            }
          }
        }
      } else if (Platform.isAndroid) {
        _kernelLib = DynamicLibrary.open('libavrai_locality_kernel.so');
      } else if (Platform.isLinux) {
        _kernelLib = DynamicLibrary.open('libavrai_locality_kernel.so');
      } else if (Platform.isWindows) {
        _kernelLib = DynamicLibrary.open('avrai_locality_kernel.dll');
      } else {
        throw UnsupportedError(
          'Unsupported platform for locality kernel library: ${Platform.operatingSystem}',
        );
      }

      _staticKernelLib = _kernelLib;
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
