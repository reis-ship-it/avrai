import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';

class DisabledHowFallbackKernel extends HowKernelFallbackSurface {
  const DisabledHowFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart how fallback is disabled. Native how kernel is required.',
    );
  }
}
