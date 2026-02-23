enum BeliefTier {
  dream,
  hypothesis,
  candidateConviction,
  provenConviction,
}

class BeliefTierContract {
  static const List<BeliefTier> immutablePrecedence = <BeliefTier>[
    BeliefTier.dream,
    BeliefTier.hypothesis,
    BeliefTier.candidateConviction,
    BeliefTier.provenConviction,
  ];

  static const Map<BeliefTier, double> confidenceCeilings =
      <BeliefTier, double>{
    BeliefTier.dream: 0.35,
    BeliefTier.hypothesis: 0.65,
    BeliefTier.candidateConviction: 0.9,
    BeliefTier.provenConviction: 1.0,
  };

  const BeliefTierContract();

  bool isTierTransitionAllowed({
    required BeliefTier from,
    required BeliefTier to,
  }) {
    final fromIndex = immutablePrecedence.indexOf(from);
    final toIndex = immutablePrecedence.indexOf(to);
    return toIndex <= fromIndex + 1;
  }

  bool isConfidenceValidForTier({
    required BeliefTier tier,
    required double confidence,
  }) {
    if (confidence < 0 || confidence > 1) return false;
    final ceiling = confidenceCeilings[tier];
    if (ceiling == null) return false;
    return confidence <= ceiling;
  }

  bool validatesWrite({
    required BeliefTier fromTier,
    required BeliefTier toTier,
    required double confidence,
  }) {
    return isTierTransitionAllowed(from: fromTier, to: toTier) &&
        isConfidenceValidForTier(tier: toTier, confidence: confidence);
  }

  Map<String, dynamic> toJson() {
    return {
      'immutable_precedence':
          immutablePrecedence.map((tier) => tier.name).toList(growable: false),
      'confidence_ceilings': confidenceCeilings
          .map((tier, ceiling) => MapEntry(tier.name, ceiling)),
    };
  }
}
