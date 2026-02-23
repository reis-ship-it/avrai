import 'package:avrai/core/ai/memory/journal/dream_conviction_bridge_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DreamConvictionBridgeContract', () {
    const contract = DreamConvictionBridgeContract();

    test('does not require dual-key evidence at or below hypothesis', () {
      expect(contract.requiresDualKeyEvidence(DreamBeliefTier.dream), isFalse);
      expect(
        contract.requiresDualKeyEvidence(DreamBeliefTier.hypothesis),
        isFalse,
      );
    });

    test('requires dual-key evidence above hypothesis tier', () {
      expect(
        contract.requiresDualKeyEvidence(DreamBeliefTier.candidateConviction),
        isTrue,
      );
      expect(
        contract.requiresDualKeyEvidence(DreamBeliefTier.provenConviction),
        isTrue,
      );
    });

    test('rejects promotion above hypothesis without both evidence keys', () {
      const missingExternal = DreamDerivedConfidenceUpdate(
        dreamId: 'dream-1',
        fromTier: DreamBeliefTier.hypothesis,
        toTier: DreamBeliefTier.candidateConviction,
        internalValidationId: 'iv-1',
      );
      const missingInternal = DreamDerivedConfidenceUpdate(
        dreamId: 'dream-1',
        fromTier: DreamBeliefTier.hypothesis,
        toTier: DreamBeliefTier.candidateConviction,
        externalOrRealOutcomeId: 'ev-1',
      );

      expect(contract.validates(missingExternal), isFalse);
      expect(contract.validates(missingInternal), isFalse);
    });

    test('allows promotion above hypothesis with dual-key evidence', () {
      const valid = DreamDerivedConfidenceUpdate(
        dreamId: 'dream-2',
        fromTier: DreamBeliefTier.hypothesis,
        toTier: DreamBeliefTier.candidateConviction,
        internalValidationId: 'iv-2',
        externalOrRealOutcomeId: 'ev-2',
      );

      expect(contract.validates(valid), isTrue);
    });

    test('rejects non-monotonic promotion jumps even with evidence', () {
      const invalid = DreamDerivedConfidenceUpdate(
        dreamId: 'dream-3',
        fromTier: DreamBeliefTier.dream,
        toTier: DreamBeliefTier.provenConviction,
        internalValidationId: 'iv-3',
        externalOrRealOutcomeId: 'ev-3',
      );

      expect(contract.validates(invalid), isFalse);
    });

    test('serializes deterministic contract metadata', () {
      final json = contract.toJson();
      expect(json['dual_key_threshold'], DreamBeliefTier.hypothesis.name);
      expect(
        json['required_keys'],
        ['internal_validation_id', 'external_or_real_outcome_id'],
      );
    });
  });
}
