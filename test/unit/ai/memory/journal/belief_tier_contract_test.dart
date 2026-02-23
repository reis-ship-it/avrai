import 'package:avrai/core/ai/memory/journal/belief_tier_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeliefTierContract', () {
    const contract = BeliefTierContract();

    test('enforces immutable precedence order', () {
      expect(
        BeliefTierContract.immutablePrecedence,
        const [
          BeliefTier.dream,
          BeliefTier.hypothesis,
          BeliefTier.candidateConviction,
          BeliefTier.provenConviction,
        ],
      );
    });

    test('allows same-tier and next-tier promotion only', () {
      expect(
        contract.isTierTransitionAllowed(
          from: BeliefTier.dream,
          to: BeliefTier.dream,
        ),
        isTrue,
      );
      expect(
        contract.isTierTransitionAllowed(
          from: BeliefTier.dream,
          to: BeliefTier.hypothesis,
        ),
        isTrue,
      );
      expect(
        contract.isTierTransitionAllowed(
          from: BeliefTier.dream,
          to: BeliefTier.candidateConviction,
        ),
        isFalse,
      );
    });

    test('enforces tier-specific confidence ceilings', () {
      expect(
        contract.isConfidenceValidForTier(
          tier: BeliefTier.dream,
          confidence: 0.35,
        ),
        isTrue,
      );
      expect(
        contract.isConfidenceValidForTier(
          tier: BeliefTier.dream,
          confidence: 0.36,
        ),
        isFalse,
      );

      expect(
        contract.isConfidenceValidForTier(
          tier: BeliefTier.hypothesis,
          confidence: 0.65,
        ),
        isTrue,
      );
      expect(
        contract.isConfidenceValidForTier(
          tier: BeliefTier.candidateConviction,
          confidence: 0.91,
        ),
        isFalse,
      );
      expect(
        contract.isConfidenceValidForTier(
          tier: BeliefTier.provenConviction,
          confidence: 1.0,
        ),
        isTrue,
      );
    });

    test('rejects writes that violate monotonic promotion flow', () {
      expect(
        contract.validatesWrite(
          fromTier: BeliefTier.hypothesis,
          toTier: BeliefTier.provenConviction,
          confidence: 0.8,
        ),
        isFalse,
      );
      expect(
        contract.validatesWrite(
          fromTier: BeliefTier.hypothesis,
          toTier: BeliefTier.candidateConviction,
          confidence: 0.91,
        ),
        isFalse,
      );
      expect(
        contract.validatesWrite(
          fromTier: BeliefTier.hypothesis,
          toTier: BeliefTier.candidateConviction,
          confidence: 0.89,
        ),
        isTrue,
      );
    });

    test('serializes precedence and ceilings to deterministic json', () {
      final json = contract.toJson();

      expect(json['immutable_precedence'], [
        'dream',
        'hypothesis',
        'candidateConviction',
        'provenConviction',
      ]);
      expect(
        (json['confidence_ceilings'] as Map<String, dynamic>)['hypothesis'],
        0.65,
      );
    });
  });
}
