import 'functional_kernel_models.dart';

class RootCauseIndexEntry {
  const RootCauseIndexEntry({
    required this.eventId,
    required this.rootCauseType,
    required this.topDriverLabels,
    required this.topInhibitorLabels,
    this.failureSignatureId,
    this.recommendationAction,
    required this.createdAtUtc,
  });

  final String eventId;
  final WhyRootCauseType rootCauseType;
  final List<String> topDriverLabels;
  final List<String> topInhibitorLabels;
  final String? failureSignatureId;
  final String? recommendationAction;
  final DateTime createdAtUtc;
}

abstract class KernelRootCauseIndex {
  Future<void> index(KernelBundleRecord record);
  List<RootCauseIndexEntry> listAll({int limit = 100});
  List<RootCauseIndexEntry> listByRootCauseType(
    WhyRootCauseType rootCauseType, {
    int limit = 50,
  });
}

class InMemoryKernelRootCauseIndex implements KernelRootCauseIndex {
  final List<RootCauseIndexEntry> _entries = <RootCauseIndexEntry>[];

  @override
  Future<void> index(KernelBundleRecord record) async {
    final why = record.bundle.why;
    if (why == null) {
      return;
    }
    _entries.removeWhere((entry) => entry.eventId == record.eventId);
    _entries.add(
      RootCauseIndexEntry(
        eventId: record.eventId,
        rootCauseType: why.rootCauseType,
        topDriverLabels: why.drivers.map((signal) => signal.label).toList(),
        topInhibitorLabels:
            why.inhibitors.map((signal) => signal.label).toList(),
        failureSignatureId: why.failureSignature?.signatureId,
        recommendationAction: why.recommendationAction,
        createdAtUtc: record.createdAtUtc,
      ),
    );
    _entries.sort(
      (left, right) => right.createdAtUtc.compareTo(left.createdAtUtc),
    );
  }

  @override
  List<RootCauseIndexEntry> listAll({int limit = 100}) {
    return _entries.take(limit).toList(growable: false);
  }

  @override
  List<RootCauseIndexEntry> listByRootCauseType(
    WhyRootCauseType rootCauseType, {
    int limit = 50,
  }) {
    return _entries
        .where((entry) => entry.rootCauseType == rootCauseType)
        .take(limit)
        .toList(growable: false);
  }
}
