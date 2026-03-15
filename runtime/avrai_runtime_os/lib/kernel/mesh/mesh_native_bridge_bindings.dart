import 'package:avrai_runtime_os/kernel/mesh/mesh_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class MeshNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class MeshNativeBridgeBindings implements MeshNativeInvocationBridge {
  MeshNativeBridgeBindings({
    MeshLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'MeshNativeBridgeBindings',
          libraryManager: libraryManager ?? MeshLibraryManager(),
          invokeSymbol: 'avrai_mesh_kernel_invoke_json',
          freeSymbol: 'avrai_mesh_kernel_free_string',
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
