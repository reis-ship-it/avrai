import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';

class DisabledWhyFallbackKernel extends WhyKernelFallbackSurface {
  const DisabledWhyFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart why fallback is disabled. Native why kernel is required.',
    );
  }
}
