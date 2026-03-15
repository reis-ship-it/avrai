import 'package:avrai_runtime_os/kernel/how/how_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class HowNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class HowNativeBridgeBindings implements HowNativeInvocationBridge {
  HowNativeBridgeBindings({
    HowLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'HowNativeBridgeBindings',
          libraryManager: libraryManager ?? HowLibraryManager(),
          invokeSymbol: 'avrai_how_kernel_invoke_json',
          freeSymbol: 'avrai_how_kernel_free_string',
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
