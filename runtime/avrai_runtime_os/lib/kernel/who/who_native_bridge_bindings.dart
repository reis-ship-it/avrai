import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';
import 'package:avrai_runtime_os/kernel/who/who_library_manager.dart';

abstract class WhoNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class WhoNativeBridgeBindings implements WhoNativeInvocationBridge {
  WhoNativeBridgeBindings({
    WhoLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'WhoNativeBridgeBindings',
          libraryManager: libraryManager ?? WhoLibraryManager(),
          invokeSymbol: 'avrai_who_kernel_invoke_json',
          freeSymbol: 'avrai_who_kernel_free_string',
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
  }) {
    return _bridge.invoke(syscall: syscall, payload: payload);
  }
}
