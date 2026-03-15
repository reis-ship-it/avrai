import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';
import 'package:avrai_runtime_os/kernel/why/why_library_manager.dart';

abstract class WhyNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class WhyNativeBridgeBindings implements WhyNativeInvocationBridge {
  WhyNativeBridgeBindings({
    WhyLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'WhyNativeBridgeBindings',
          libraryManager: libraryManager ?? WhyLibraryManager(),
          invokeSymbol: 'avrai_why_kernel_invoke_json',
          freeSymbol: 'avrai_why_kernel_free_string',
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
