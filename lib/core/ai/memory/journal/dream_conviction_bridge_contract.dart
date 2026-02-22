enum DreamBeliefTier {
  dream,
  hypothesis,
  candidateConviction,
  provenConviction,
}

class DreamDerivedConfidenceUpdate {
  final String dreamId;
  final DreamBeliefTier fromTier;
  final DreamBeliefTier toTier;
  final String? internalValidationId;
  final String? externalOrRealOutcomeId;

  const DreamDerivedConfidenceUpdate({
    required this.dreamId,
    required this.fromTier,
    required this.toTier,
    this.internalValidationId,
    this.externalOrRealOutcomeId,
  });
}

class DreamConvictionBridgeContract {
  const DreamConvictionBridgeContract();

  bool requiresDualKeyEvidence(DreamBeliefTier targetTier) {
    return targetTier.index > DreamBeliefTier.hypothesis.index;
  }

  bool validates(DreamDerivedConfidenceUpdate update) {
    if (update.dreamId.trim().isEmpty) return false;

    final monotonic = update.toTier.index <= update.fromTier.index + 1;
    if (!monotonic) return false;

    if (!requiresDualKeyEvidence(update.toTier)) {
      return true;
    }

    final internal = update.internalValidationId?.trim() ?? '';
    final external = update.externalOrRealOutcomeId?.trim() ?? '';
    return internal.isNotEmpty && external.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'dual_key_threshold': DreamBeliefTier.hypothesis.name,
      'required_keys': const [
        'internal_validation_id',
        'external_or_real_outcome_id',
      ],
      'rule':
          'dream-derived updates targeting tiers above hypothesis require both evidence keys',
    };
  }
}
