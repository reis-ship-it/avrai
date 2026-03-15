import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';

class DisabledWhenFallbackKernel extends WhenKernelFallbackSurface {
  const DisabledWhenFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart when fallback is disabled. Native when kernel is required.',
    );
  }
}
