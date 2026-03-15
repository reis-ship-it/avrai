import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class Ai2AiNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class Ai2AiNativeBridgeBindings implements Ai2AiNativeInvocationBridge {
  Ai2AiNativeBridgeBindings({
    Ai2AiLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'Ai2AiNativeBridgeBindings',
          libraryManager: libraryManager ?? Ai2AiLibraryManager(),
          invokeSymbol: 'avrai_ai2ai_kernel_invoke_json',
          freeSymbol: 'avrai_ai2ai_kernel_free_string',
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
