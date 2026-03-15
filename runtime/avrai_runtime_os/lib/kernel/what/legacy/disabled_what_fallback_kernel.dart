import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';

class DisabledWhatFallbackKernel implements WhatKernelFallbackSurface {
  const DisabledWhatFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart what fallback is disabled. Native what kernel is required. '
      'Enable AVRAI_ENABLE_DART_WHAT_FALLBACK=true or FLUTTER_TEST=true '
      'to re-enable the legacy Dart fallback path.',
    );
  }
}
