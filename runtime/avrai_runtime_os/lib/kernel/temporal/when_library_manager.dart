import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

class WhenLibraryManager {
  static const String _logName = 'WhenLibraryManager';
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  DynamicLibrary? _kernelLib;

  DynamicLibrary getKernelLibrary() {
    if (_kernelLib != null) {
      return _kernelLib!;
    }

    try {
      if (Platform.isIOS) {
        try {
          _kernelLib =
              DynamicLibrary.open('AVRAIWhenKernel.framework/AVRAIWhenKernel');
        } catch (_) {
          _kernelLib = DynamicLibrary.process();
        }
      } else if (Platform.isMacOS) {
        if (_isFlutterTest) {
          _kernelLib = DynamicLibrary.process();
        } else {
          final currentDir = Directory.current.path;
          final candidatePaths = <String>[
            '$currentDir/runtime/avrai_network/native/when_kernel/macos/libavrai_when_kernel.dylib',
            '$currentDir/runtime/avrai_network/native/when_kernel/target/debug/libavrai_when_kernel.dylib',
            '$currentDir/runtime/avrai_network/native/when_kernel/target/release/libavrai_when_kernel.dylib',
          ];
          final existingPath = candidatePaths.cast<String?>().firstWhere(
                (path) => path != null && File(path).existsSync(),
                orElse: () => null,
              );
          if (existingPath != null) {
            _kernelLib = DynamicLibrary.open(existingPath);
          } else {
            _kernelLib = DynamicLibrary.open('libavrai_when_kernel.dylib');
          }
        }
      } else if (Platform.isAndroid || Platform.isLinux) {
        _kernelLib = DynamicLibrary.open('libavrai_when_kernel.so');
      } else if (Platform.isWindows) {
        _kernelLib = DynamicLibrary.open('avrai_when_kernel.dll');
      } else {
        throw UnsupportedError(
          'Unsupported platform for when kernel library: ${Platform.operatingSystem}',
        );
      }
      developer.log('When kernel library loaded', name: _logName);
      return _kernelLib!;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load when kernel library: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
