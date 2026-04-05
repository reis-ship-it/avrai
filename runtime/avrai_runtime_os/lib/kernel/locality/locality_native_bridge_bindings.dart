import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class LocalityNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class LocalityNativeBridgeBindings implements LocalityNativeInvocationBridge {
  LocalityNativeBridgeBindings({
    LocalityLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'LocalityNativeBridgeBindings',
          libraryManager: libraryManager ?? LocalityLibraryManager(),
          invokeSymbol: 'avrai_locality_kernel_invoke_json',
          freeSymbol: 'avrai_locality_kernel_free_string',
        );

  final KernelJsonNativeBridge _bridge;

  @override
  bool get isAvailable => _bridge.isAvailable;

  @override
  void initialize() => _bridge.initialize();

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) =>
      _bridge.invoke(syscall: syscall, payload: payload);
}
