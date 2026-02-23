import 'package:avrai/core/ai/memory/journal/dream_failure_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DreamFailureArchive', () {
    DreamFailureRecord sampleRecord() {
      return DreamFailureRecord(
        dreamPathId: 'dream-path-1',
        failureSignature: 'sim_divergence:market_shift',
        suppressionTags: const {'anti_repeat', 'high_risk'},
        invalidatedAt: DateTime.utc(2026, 2, 20, 20),
        invalidationReason: 'Failed real-world contradiction check',
      );
    }

    test('archives invalidated dream path and blocks promotion', () {
      final archive = DreamFailureArchive();
      archive.archive(sampleRecord());

      expect(archive.lookup('dream-path-1'), isNotNull);
      expect(archive.isPromotionBlocked('dream-path-1'), isTrue);
    });

    test('supports suppression-tag queries', () {
      final archive = DreamFailureArchive();
      archive.archive(sampleRecord());

      final matched = archive.bySuppressionTag('anti_repeat');
      expect(matched, hasLength(1));
      expect(matched.first.dreamPathId, 'dream-path-1');
    });

    test('requires contradiction-clearing evidence to unblock promotion', () {
      final archive = DreamFailureArchive();
      archive.archive(sampleRecord());

      archive.clearSuppression(
        dreamPathId: 'dream-path-1',
        contradictionClearingEvidenceId: 'evidence-42',
      );

      expect(archive.isPromotionBlocked('dream-path-1'), isFalse);
      expect(
        archive.lookup('dream-path-1')?.clearedByEvidenceId,
        'evidence-42',
      );
    });

    test('json round-trip preserves deterministic archive contract', () {
      final record = sampleRecord();
      final decoded = DreamFailureRecord.fromJson(record.toJson());

      expect(decoded.dreamPathId, record.dreamPathId);
      expect(decoded.failureSignature, record.failureSignature);
      expect(decoded.suppressionTags, record.suppressionTags);
      expect(decoded.invalidationReason, record.invalidationReason);
      expect(decoded.invalidatedAt, record.invalidatedAt);
    });
  });
}
