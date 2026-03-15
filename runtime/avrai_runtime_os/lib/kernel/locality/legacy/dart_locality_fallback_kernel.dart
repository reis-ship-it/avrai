import 'package:avrai_runtime_os/kernel/locality/locality_runtime_context.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';

class DartLocalityFallbackKernel
    implements LocalityWhereProviderFallbackSurface {
  final LocalityKernelRuntimeContext _context;

  DartLocalityFallbackKernel.fromRuntimeContext(
    LocalityKernelRuntimeContext context,
  ) : _context = context;

  LocalityKernelRuntimeContext get context => _context;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
