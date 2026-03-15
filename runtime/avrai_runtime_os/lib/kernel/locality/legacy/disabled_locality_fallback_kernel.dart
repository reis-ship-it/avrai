import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';

class DisabledLocalityFallbackKernel
    implements LocalityWhereProviderFallbackSurface {
  const DisabledLocalityFallbackKernel();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Dart locality fallback is disabled. Native where kernel is required.',
    );
  }
}
