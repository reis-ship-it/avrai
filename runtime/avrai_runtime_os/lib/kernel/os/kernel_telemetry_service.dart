import 'functional_kernel_models.dart';

class KernelTelemetrySnapshot {
  const KernelTelemetrySnapshot({
    required this.totalBundles,
    required this.completeBundles,
    required this.degradedBundles,
    required this.rootCauseCounts,
    required this.failureSignatureCount,
  });

  final int totalBundles;
  final int completeBundles;
  final int degradedBundles;
  final Map<WhyRootCauseType, int> rootCauseCounts;
  final int failureSignatureCount;
}

abstract class KernelTelemetryService {
  Future<void> record(KernelBundleRecord record);
  KernelTelemetrySnapshot snapshot();
}

class InMemoryKernelTelemetryService implements KernelTelemetryService {
  int _totalBundles = 0;
  int _completeBundles = 0;
  int _degradedBundles = 0;
  int _failureSignatureCount = 0;
  final Map<WhyRootCauseType, int> _rootCauseCounts = <WhyRootCauseType, int>{};

  @override
  Future<void> record(KernelBundleRecord record) async {
    _totalBundles++;
    final bundle = record.bundle;
    final isComplete = bundle.who != null &&
        bundle.what != null &&
        bundle.when != null &&
        bundle.where != null &&
        bundle.how != null &&
        bundle.why != null;
    if (isComplete) {
      _completeBundles++;
    } else {
      _degradedBundles++;
    }

    final why = bundle.why;
    if (why != null) {
      _rootCauseCounts.update(
        why.rootCauseType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (why.failureSignature != null) {
        _failureSignatureCount++;
      }
    }
  }

  @override
  KernelTelemetrySnapshot snapshot() {
    return KernelTelemetrySnapshot(
      totalBundles: _totalBundles,
      completeBundles: _completeBundles,
      degradedBundles: _degradedBundles,
      rootCauseCounts: Map<WhyRootCauseType, int>.from(_rootCauseCounts),
      failureSignatureCount: _failureSignatureCount,
    );
  }
}
