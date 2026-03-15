import 'package:avrai_runtime_os/kernel/boundary/boundary_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class BoundaryNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class BoundaryNativeBridgeBindings implements BoundaryNativeInvocationBridge {
  BoundaryNativeBridgeBindings({
    BoundaryLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'BoundaryNativeBridgeBindings',
          libraryManager: libraryManager ?? BoundaryLibraryManager(),
          invokeSymbol: 'avrai_boundary_kernel_invoke_json',
          freeSymbol: 'avrai_boundary_kernel_free_string',
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
