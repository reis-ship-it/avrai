import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';

class DartWhenFallbackKernel extends WhenKernelFallbackSurface {
  const DartWhenFallbackKernel();

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    final observedAt = envelope.occurredAtUtc.toUtc();
    final expiresAt = observedAt.add(const Duration(hours: 4));
    return WhenKernelSnapshot(
      observedAt: observedAt,
      effectiveAt: observedAt,
      expiresAt: expiresAt,
      freshness: 1.0,
      cadence: envelope.context['cadence'] as String?,
      recencyBucket: 'immediate',
      timingConflictFlags: const <String>[],
      temporalConfidence: 0.92,
    );
  }
}
