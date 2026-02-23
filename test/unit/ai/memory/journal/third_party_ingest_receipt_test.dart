import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/third_party_ingest_receipt.dart';

void main() {
  group('ThirdPartyIngestReceipt', () {
    test('round-trips deterministic receipt fields', () {
      final receipt = ThirdPartyIngestReceipt(
        receiptId: 'r-1',
        providerId: 'provider-x',
        consentScope: 'city-level mobility features',
        legalBasis: ThirdPartyLegalBasis.userConsent,
        dpTier: ThirdPartyDpTier.medium,
        retentionStart: DateTime.utc(2026, 2, 20, 12),
        retentionEnd: DateTime.utc(2026, 8, 20, 12),
        allowedUseClass: ThirdPartyAllowedUseClass.trainingAllowed,
        metadata: const {'region': 'us-west'},
      );

      final decoded = ThirdPartyIngestReceipt.fromJson(receipt.toJson());
      expect(decoded.receiptId, 'r-1');
      expect(decoded.providerId, 'provider-x');
      expect(decoded.consentScope, 'city-level mobility features');
      expect(decoded.legalBasis, ThirdPartyLegalBasis.userConsent);
      expect(decoded.dpTier, ThirdPartyDpTier.medium);
      expect(
          decoded.allowedUseClass, ThirdPartyAllowedUseClass.trainingAllowed);
      expect(decoded.metadata['region'], 'us-west');
      expect(decoded.isValid, isTrue);
    });

    test('invalid when retention window is non-positive', () {
      final receipt = ThirdPartyIngestReceipt(
        receiptId: 'r-2',
        providerId: 'provider-y',
        consentScope: 'aggregated dwell features',
        legalBasis: ThirdPartyLegalBasis.contractualNecessity,
        dpTier: ThirdPartyDpTier.low,
        retentionStart: DateTime.utc(2026, 2, 20),
        retentionEnd: DateTime.utc(2026, 2, 20),
        allowedUseClass: ThirdPartyAllowedUseClass.trainingAllowed,
      );

      expect(receipt.isValid, isFalse);
    });

    test('invalid when no-DP receipt is allowed for training/planning', () {
      final receipt = ThirdPartyIngestReceipt(
        receiptId: 'r-3',
        providerId: 'provider-z',
        consentScope: 'raw logs',
        legalBasis: ThirdPartyLegalBasis.legitimateInterest,
        dpTier: ThirdPartyDpTier.none,
        retentionStart: DateTime.utc(2026, 2, 20),
        retentionEnd: DateTime.utc(2026, 3, 20),
        allowedUseClass: ThirdPartyAllowedUseClass.planningAllowed,
      );

      expect(receipt.isValid, isFalse);
    });
  });

  group('ThirdPartyIngestPolicyGate', () {
    const gate = ThirdPartyIngestPolicyGate();

    test('allows influence only when receipt is valid, active, and DP-safe',
        () {
      final now = DateTime.utc(2026, 2, 21);
      final receipt = ThirdPartyIngestReceipt(
        receiptId: 'r-4',
        providerId: 'provider-a',
        consentScope: 'summary stats',
        legalBasis: ThirdPartyLegalBasis.userConsent,
        dpTier: ThirdPartyDpTier.high,
        retentionStart: DateTime.utc(2026, 2, 20),
        retentionEnd: DateTime.utc(2026, 4, 20),
        allowedUseClass: ThirdPartyAllowedUseClass.planningAllowed,
      );

      expect(
        gate.canInfluenceTrainingOrPlanning(receipt: receipt, now: now),
        isTrue,
      );
    });

    test('blocks research-only or expired receipts', () {
      final receiptResearchOnly = ThirdPartyIngestReceipt(
        receiptId: 'r-5',
        providerId: 'provider-b',
        consentScope: 'research snapshot',
        legalBasis: ThirdPartyLegalBasis.userConsent,
        dpTier: ThirdPartyDpTier.medium,
        retentionStart: DateTime.utc(2026, 2, 20),
        retentionEnd: DateTime.utc(2026, 3, 20),
        allowedUseClass: ThirdPartyAllowedUseClass.researchOnly,
      );

      expect(
        gate.canInfluenceTrainingOrPlanning(
          receipt: receiptResearchOnly,
          now: DateTime.utc(2026, 2, 21),
        ),
        isFalse,
      );

      final receiptExpired = ThirdPartyIngestReceipt(
        receiptId: 'r-6',
        providerId: 'provider-c',
        consentScope: 'aggregates',
        legalBasis: ThirdPartyLegalBasis.regulatoryRequirement,
        dpTier: ThirdPartyDpTier.medium,
        retentionStart: DateTime.utc(2026, 1, 1),
        retentionEnd: DateTime.utc(2026, 1, 31),
        allowedUseClass: ThirdPartyAllowedUseClass.trainingAllowed,
      );

      expect(
        gate.canInfluenceTrainingOrPlanning(
          receipt: receiptExpired,
          now: DateTime.utc(2026, 2, 21),
        ),
        isFalse,
      );
    });
  });
}
