import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/conviction_ledger.dart';

void main() {
  group('ConvictionLedgerEntry', () {
    test('round-trips deterministic confidence update payload', () {
      final entry = ConvictionLedgerEntry(
        entryId: 'cl-1',
        convictionId: 'conviction-abc',
        previousConfidence: 0.42,
        updatedConfidence: 0.57,
        supportingEvidenceIds: const ['ev-1', 'ev-2'],
        contradictionIds: const ['ctr-1'],
        delayedValidationWindowIds: const ['win-30d', 'win-90d'],
        recordedAt: DateTime.utc(2026, 2, 20, 15),
        metadata: const {'reason': 'new outcome evidence'},
      );

      final decoded = ConvictionLedgerEntry.fromJson(entry.toJson());

      expect(decoded.entryId, 'cl-1');
      expect(decoded.convictionId, 'conviction-abc');
      expect(decoded.previousConfidence, 0.42);
      expect(decoded.updatedConfidence, 0.57);
      expect(decoded.supportingEvidenceIds, ['ev-1', 'ev-2']);
      expect(decoded.contradictionIds, ['ctr-1']);
      expect(decoded.delayedValidationWindowIds, ['win-30d', 'win-90d']);
      expect(decoded.metadata['reason'], 'new outcome evidence');
      expect(decoded.isValid, isTrue);
    });

    test('requires delayed validation windows and evidence context', () {
      final invalid = ConvictionLedgerEntry(
        entryId: 'cl-x',
        convictionId: 'conviction-abc',
        previousConfidence: 0.3,
        updatedConfidence: 0.4,
        supportingEvidenceIds: const [],
        contradictionIds: const [],
        delayedValidationWindowIds: const [],
        recordedAt: DateTime.utc(2026, 2, 20),
      );

      expect(invalid.isValid, isFalse);
    });
  });

  group('ConvictionLedger', () {
    test('appends valid entries and queries by conviction id', () {
      final ledger = ConvictionLedger();
      ledger.append(
        ConvictionLedgerEntry(
          entryId: 'cl-1',
          convictionId: 'conviction-a',
          previousConfidence: 0.3,
          updatedConfidence: 0.5,
          supportingEvidenceIds: const ['ev-1'],
          contradictionIds: const [],
          delayedValidationWindowIds: const ['win-30d'],
          recordedAt: DateTime.utc(2026, 2, 20, 12),
        ),
      );
      ledger.append(
        ConvictionLedgerEntry(
          entryId: 'cl-2',
          convictionId: 'conviction-a',
          previousConfidence: 0.5,
          updatedConfidence: 0.6,
          supportingEvidenceIds: const ['ev-2'],
          contradictionIds: const ['ctr-2'],
          delayedValidationWindowIds: const ['win-90d'],
          recordedAt: DateTime.utc(2026, 2, 20, 13),
        ),
      );

      final entries = ledger.byConvictionId('conviction-a');
      expect(entries, hasLength(2));
      expect(entries.first.entryId, 'cl-2');
      expect(entries.last.entryId, 'cl-1');
    });
  });
}
