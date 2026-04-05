enum GovernedLearningAdoptionStatus {
  acceptedForLearning,
  queuedForSurfaceRefresh,
  firstSurfacedOnSurface,
}

class GovernedLearningAdoptionReceipt {
  const GovernedLearningAdoptionReceipt({
    required this.id,
    required this.ownerUserId,
    required this.envelopeId,
    required this.sourceId,
    required this.status,
    required this.recordedAtUtc,
    required this.reason,
    this.surface,
    this.decisionFamily,
    this.domainId,
    this.domainLabel,
    this.targetEntityId,
    this.targetEntityType,
    this.targetEntityTitle,
  });

  final String id;
  final String ownerUserId;
  final String envelopeId;
  final String sourceId;
  final GovernedLearningAdoptionStatus status;
  final DateTime recordedAtUtc;
  final String reason;
  final String? surface;
  final String? decisionFamily;
  final String? domainId;
  final String? domainLabel;
  final String? targetEntityId;
  final String? targetEntityType;
  final String? targetEntityTitle;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ownerUserId': ownerUserId,
        'envelopeId': envelopeId,
        'sourceId': sourceId,
        'status': status.name,
        'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
        'reason': reason,
        'surface': surface,
        'decisionFamily': decisionFamily,
        'domainId': domainId,
        'domainLabel': domainLabel,
        'targetEntityId': targetEntityId,
        'targetEntityType': targetEntityType,
        'targetEntityTitle': targetEntityTitle,
      };

  factory GovernedLearningAdoptionReceipt.fromJson(Map<String, dynamic> json) {
    return GovernedLearningAdoptionReceipt(
      id: json['id']?.toString() ?? '',
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      envelopeId: json['envelopeId']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      status: _parseGovernedLearningAdoptionStatus(json['status']),
      recordedAtUtc: _parseDateTime(json['recordedAtUtc']),
      reason: json['reason']?.toString() ?? '',
      surface: json['surface']?.toString(),
      decisionFamily: json['decisionFamily']?.toString(),
      domainId: json['domainId']?.toString(),
      domainLabel: json['domainLabel']?.toString(),
      targetEntityId: json['targetEntityId']?.toString(),
      targetEntityType: json['targetEntityType']?.toString(),
      targetEntityTitle: json['targetEntityTitle']?.toString(),
    );
  }
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

GovernedLearningAdoptionStatus _parseGovernedLearningAdoptionStatus(
  Object? value,
) {
  final raw = value?.toString();
  for (final status in GovernedLearningAdoptionStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return GovernedLearningAdoptionStatus.acceptedForLearning;
}
