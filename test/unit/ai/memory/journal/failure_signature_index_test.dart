import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/failure_signature_index.dart';

void main() {
  group('FailureSignatureIndex', () {
    test('creates new signature record on first observation', () {
      final index = FailureSignatureIndex();
      final record = index.upsert(
        issueClass: 'rollback_regression',
        fingerprint: 'sig-001',
        observedAt: DateTime.utc(2026, 2, 20, 8),
        metadata: const {'cohort': 'tier2'},
      );

      expect(record.signatureId, 'rollback_regression_sig-001');
      expect(record.occurrenceCount, 1);
      expect(record.metadata['cohort'], 'tier2');
      expect(index.all(), hasLength(1));
    });

    test('bumps occurrence count for repeated fingerprint and updates metadata',
        () {
      final index = FailureSignatureIndex();
      index.upsert(
        issueClass: 'rollback_regression',
        fingerprint: 'sig-001',
        observedAt: DateTime.utc(2026, 2, 20, 8),
      );

      final updated = index.upsert(
        issueClass: 'rollback_regression',
        fingerprint: 'sig-001',
        observedAt: DateTime.utc(2026, 2, 20, 9),
        metadata: const {'latest_model': 'v5.2.11'},
      );

      expect(updated.occurrenceCount, 2);
      expect(updated.lastSeenAt, DateTime.utc(2026, 2, 20, 9));
      expect(updated.metadata['latest_model'], 'v5.2.11');
    });

    test('queries signatures by issue class in recency order', () {
      final index = FailureSignatureIndex();
      index.upsert(
        issueClass: 'rollback_regression',
        fingerprint: 'sig-a',
        observedAt: DateTime.utc(2026, 2, 20, 8),
      );
      index.upsert(
        issueClass: 'drift_alert',
        fingerprint: 'sig-b',
        observedAt: DateTime.utc(2026, 2, 20, 9),
      );
      index.upsert(
        issueClass: 'rollback_regression',
        fingerprint: 'sig-c',
        observedAt: DateTime.utc(2026, 2, 20, 10),
      );

      final rollback = index.queryByIssueClass('rollback_regression');
      expect(rollback.map((r) => r.fingerprint).toList(), ['sig-c', 'sig-a']);
    });

    test('rejects empty fingerprint', () {
      final index = FailureSignatureIndex();
      expect(
        () => index.upsert(
          issueClass: 'rollback_regression',
          fingerprint: '',
          observedAt: DateTime.utc(2026, 2, 20),
        ),
        throwsArgumentError,
      );
    });
  });
}
