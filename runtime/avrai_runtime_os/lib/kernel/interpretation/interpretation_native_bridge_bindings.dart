import 'package:avrai_runtime_os/kernel/interpretation/interpretation_library_manager.dart';
import 'package:avrai_runtime_os/kernel/os/native_kernel_support.dart';

abstract class InterpretationNativeInvocationBridge {
  bool get isAvailable;
  void initialize();
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class InterpretationNativeBridgeBindings
    implements InterpretationNativeInvocationBridge {
  InterpretationNativeBridgeBindings({
    InterpretationLibraryManager? libraryManager,
  }) : _bridge = KernelJsonNativeBridge(
          logName: 'InterpretationNativeBridgeBindings',
          libraryManager: libraryManager ?? InterpretationLibraryManager(),
          invokeSymbol: 'avrai_interpretation_kernel_invoke_json',
          freeSymbol: 'avrai_interpretation_kernel_free_string',
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
