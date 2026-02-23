enum ThirdPartyLegalBasis {
  userConsent,
  contractualNecessity,
  legitimateInterest,
  regulatoryRequirement,
}

enum ThirdPartyDpTier {
  none,
  low,
  medium,
  high,
}

enum ThirdPartyAllowedUseClass {
  researchOnly,
  trainingAllowed,
  planningAllowed,
}

class ThirdPartyIngestReceipt {
  final String receiptId;
  final String providerId;
  final String consentScope;
  final ThirdPartyLegalBasis legalBasis;
  final ThirdPartyDpTier dpTier;
  final DateTime retentionStart;
  final DateTime retentionEnd;
  final ThirdPartyAllowedUseClass allowedUseClass;
  final Map<String, Object?> metadata;

  const ThirdPartyIngestReceipt({
    required this.receiptId,
    required this.providerId,
    required this.consentScope,
    required this.legalBasis,
    required this.dpTier,
    required this.retentionStart,
    required this.retentionEnd,
    required this.allowedUseClass,
    this.metadata = const {},
  });

  bool get isValid {
    if (receiptId.trim().isEmpty) return false;
    if (providerId.trim().isEmpty) return false;
    if (consentScope.trim().isEmpty) return false;
    if (!retentionEnd.isAfter(retentionStart)) return false;
    if (dpTier == ThirdPartyDpTier.none &&
        allowedUseClass != ThirdPartyAllowedUseClass.researchOnly) {
      return false;
    }
    return true;
  }

  bool isActiveAt(DateTime when) {
    final at = when.toUtc();
    return !at.isBefore(retentionStart.toUtc()) &&
        at.isBefore(retentionEnd.toUtc());
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'provider_id': providerId,
      'consent_scope': consentScope,
      'legal_basis': legalBasis.name,
      'dp_tier': dpTier.name,
      'retention_start': retentionStart.toUtc().toIso8601String(),
      'retention_end': retentionEnd.toUtc().toIso8601String(),
      'allowed_use_class': allowedUseClass.name,
      'metadata': metadata,
    };
  }

  factory ThirdPartyIngestReceipt.fromJson(Map<String, dynamic> json) {
    return ThirdPartyIngestReceipt(
      receiptId: json['receipt_id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      consentScope: json['consent_scope'] as String? ?? '',
      legalBasis: ThirdPartyLegalBasis.values.firstWhere(
        (v) => v.name == (json['legal_basis'] as String?),
        orElse: () => ThirdPartyLegalBasis.userConsent,
      ),
      dpTier: ThirdPartyDpTier.values.firstWhere(
        (v) => v.name == (json['dp_tier'] as String?),
        orElse: () => ThirdPartyDpTier.none,
      ),
      retentionStart:
          DateTime.tryParse(json['retention_start'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      retentionEnd: DateTime.tryParse(json['retention_end'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      allowedUseClass: ThirdPartyAllowedUseClass.values.firstWhere(
        (v) => v.name == (json['allowed_use_class'] as String?),
        orElse: () => ThirdPartyAllowedUseClass.researchOnly,
      ),
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}

class ThirdPartyIngestPolicyGate {
  const ThirdPartyIngestPolicyGate();

  bool canInfluenceTrainingOrPlanning({
    required ThirdPartyIngestReceipt receipt,
    required DateTime now,
  }) {
    if (!receipt.isValid) return false;
    if (!receipt.isActiveAt(now)) return false;
    if (receipt.dpTier == ThirdPartyDpTier.none) return false;

    switch (receipt.allowedUseClass) {
      case ThirdPartyAllowedUseClass.trainingAllowed:
      case ThirdPartyAllowedUseClass.planningAllowed:
        return true;
      case ThirdPartyAllowedUseClass.researchOnly:
        return false;
    }
  }
}
