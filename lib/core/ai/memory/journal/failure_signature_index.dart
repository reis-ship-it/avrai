class FailureSignatureRecord {
  final String signatureId;
  final String issueClass;
  final String fingerprint;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int occurrenceCount;
  final Map<String, Object?> metadata;

  const FailureSignatureRecord({
    required this.signatureId,
    required this.issueClass,
    required this.fingerprint,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.occurrenceCount,
    this.metadata = const {},
  });

  FailureSignatureRecord bump({
    required DateTime observedAt,
    Map<String, Object?> metadataDelta = const {},
  }) {
    return FailureSignatureRecord(
      signatureId: signatureId,
      issueClass: issueClass,
      fingerprint: fingerprint,
      firstSeenAt: firstSeenAt,
      lastSeenAt: observedAt.toUtc(),
      occurrenceCount: occurrenceCount + 1,
      metadata: {...metadata, ...metadataDelta},
    );
  }
}

class FailureSignatureIndex {
  final Map<String, FailureSignatureRecord> _byFingerprint = {};

  List<FailureSignatureRecord> all() {
    final items = _byFingerprint.values.toList(growable: false)
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    return items;
  }

  FailureSignatureRecord? getByFingerprint(String fingerprint) {
    return _byFingerprint[fingerprint];
  }

  FailureSignatureRecord upsert({
    required String issueClass,
    required String fingerprint,
    required DateTime observedAt,
    Map<String, Object?> metadata = const {},
  }) {
    final key = fingerprint.trim();
    if (key.isEmpty) {
      throw ArgumentError('fingerprint must not be empty');
    }
    final now = observedAt.toUtc();
    final existing = _byFingerprint[key];

    if (existing == null) {
      final created = FailureSignatureRecord(
        signatureId: '${issueClass}_$key',
        issueClass: issueClass,
        fingerprint: key,
        firstSeenAt: now,
        lastSeenAt: now,
        occurrenceCount: 1,
        metadata: metadata,
      );
      _byFingerprint[key] = created;
      return created;
    }

    final updated = existing.bump(observedAt: now, metadataDelta: metadata);
    _byFingerprint[key] = updated;
    return updated;
  }

  List<FailureSignatureRecord> queryByIssueClass(String issueClass) {
    final matches = _byFingerprint.values
        .where((item) => item.issueClass == issueClass)
        .toList(growable: false)
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    return matches;
  }
}
