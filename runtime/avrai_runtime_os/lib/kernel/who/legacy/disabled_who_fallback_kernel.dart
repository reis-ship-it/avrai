import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';

class DisabledWhoFallbackKernel extends WhoKernelFallbackSurface {
  const DisabledWhoFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart who fallback is disabled. Native who kernel is required.',
    );
  }
}
