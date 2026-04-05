enum GovernedLearningUsageInfluenceKind {
  boost,
  suppress,
  reference,
}

class GovernedLearningUsageReceipt {
  const GovernedLearningUsageReceipt({
    required this.id,
    required this.ownerUserId,
    required this.envelopeId,
    required this.sourceId,
    required this.decisionFamily,
    required this.decisionId,
    required this.domainId,
    required this.domainLabel,
    required this.targetEntityId,
    required this.targetEntityType,
    required this.targetEntityTitle,
    required this.usedAtUtc,
    required this.influenceKind,
    required this.influenceScoreDelta,
    required this.influenceReason,
    this.surface,
  });

  final String id;
  final String ownerUserId;
  final String envelopeId;
  final String sourceId;
  final String decisionFamily;
  final String decisionId;
  final String domainId;
  final String domainLabel;
  final String targetEntityId;
  final String targetEntityType;
  final String targetEntityTitle;
  final DateTime usedAtUtc;
  final GovernedLearningUsageInfluenceKind influenceKind;
  final double influenceScoreDelta;
  final String influenceReason;
  final String? surface;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ownerUserId': ownerUserId,
        'envelopeId': envelopeId,
        'sourceId': sourceId,
        'decisionFamily': decisionFamily,
        'decisionId': decisionId,
        'domainId': domainId,
        'domainLabel': domainLabel,
        'targetEntityId': targetEntityId,
        'targetEntityType': targetEntityType,
        'targetEntityTitle': targetEntityTitle,
        'usedAtUtc': usedAtUtc.toUtc().toIso8601String(),
        'influenceKind': influenceKind.name,
        'influenceScoreDelta': influenceScoreDelta,
        'influenceReason': influenceReason,
        'surface': surface,
      };

  factory GovernedLearningUsageReceipt.fromJson(Map<String, dynamic> json) {
    return GovernedLearningUsageReceipt(
      id: json['id']?.toString() ?? '',
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      envelopeId: json['envelopeId']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      decisionFamily: json['decisionFamily']?.toString() ?? '',
      decisionId: json['decisionId']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      domainLabel: json['domainLabel']?.toString() ?? '',
      targetEntityId: json['targetEntityId']?.toString() ?? '',
      targetEntityType: json['targetEntityType']?.toString() ?? '',
      targetEntityTitle: json['targetEntityTitle']?.toString() ?? '',
      usedAtUtc: _parseDateTime(json['usedAtUtc']),
      influenceKind: _parseInfluenceKind(json['influenceKind']),
      influenceScoreDelta:
          (json['influenceScoreDelta'] as num?)?.toDouble() ?? 0,
      influenceReason: json['influenceReason']?.toString() ?? '',
      surface: json['surface']?.toString(),
    );
  }
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

GovernedLearningUsageInfluenceKind _parseInfluenceKind(Object? value) {
  final raw = value?.toString();
  for (final kind in GovernedLearningUsageInfluenceKind.values) {
    if (kind.name == raw) {
      return kind;
    }
  }
  return GovernedLearningUsageInfluenceKind.reference;
}
