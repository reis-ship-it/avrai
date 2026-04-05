enum GovernedLearningChatObservationKind {
  explanation,
}

enum GovernedLearningChatObservationOutcome {
  pending,
  acknowledged,
  requestedFollowUp,
  correctedRecord,
  forgotRecord,
  stoppedUsingSignal,
}

enum GovernedLearningChatObservationValidationStatus {
  pending,
  validatedBySurfacedAdoption,
}

enum GovernedLearningChatObservationGovernanceStatus {
  pending,
  reinforcedByGovernance,
  constrainedByGovernance,
  overruledByGovernance,
}

enum GovernedLearningChatObservationAttentionStatus {
  pending,
  clearedByGovernance,
  satisfiedByGovernance,
}

class GovernedLearningChatObservationReceipt {
  const GovernedLearningChatObservationReceipt({
    required this.id,
    required this.ownerUserId,
    required this.envelopeId,
    required this.sourceId,
    required this.kind,
    required this.outcome,
    required this.recordedAtUtc,
    required this.chatId,
    required this.userMessageId,
    this.assistantMessageId,
    this.focus,
    this.userQuestion,
    this.renderedResponse,
    this.resolvedAtUtc,
    this.validationStatus =
        GovernedLearningChatObservationValidationStatus.pending,
    this.validatedAtUtc,
    this.validatedSurface,
    this.validatedTargetEntityTitle,
    this.governanceStatus =
        GovernedLearningChatObservationGovernanceStatus.pending,
    this.governanceUpdatedAtUtc,
    this.governanceStage,
    this.governanceReason,
    this.attentionStatus =
        GovernedLearningChatObservationAttentionStatus.pending,
    this.attentionUpdatedAtUtc,
  });

  final String id;
  final String ownerUserId;
  final String envelopeId;
  final String sourceId;
  final GovernedLearningChatObservationKind kind;
  final GovernedLearningChatObservationOutcome outcome;
  final DateTime recordedAtUtc;
  final String chatId;
  final String userMessageId;
  final String? assistantMessageId;
  final String? focus;
  final String? userQuestion;
  final String? renderedResponse;
  final DateTime? resolvedAtUtc;
  final GovernedLearningChatObservationValidationStatus validationStatus;
  final DateTime? validatedAtUtc;
  final String? validatedSurface;
  final String? validatedTargetEntityTitle;
  final GovernedLearningChatObservationGovernanceStatus governanceStatus;
  final DateTime? governanceUpdatedAtUtc;
  final String? governanceStage;
  final String? governanceReason;
  final GovernedLearningChatObservationAttentionStatus attentionStatus;
  final DateTime? attentionUpdatedAtUtc;

  GovernedLearningChatObservationReceipt copyWith({
    GovernedLearningChatObservationOutcome? outcome,
    String? assistantMessageId,
    DateTime? resolvedAtUtc,
    GovernedLearningChatObservationValidationStatus? validationStatus,
    DateTime? validatedAtUtc,
    String? validatedSurface,
    String? validatedTargetEntityTitle,
    GovernedLearningChatObservationGovernanceStatus? governanceStatus,
    DateTime? governanceUpdatedAtUtc,
    String? governanceStage,
    String? governanceReason,
    GovernedLearningChatObservationAttentionStatus? attentionStatus,
    DateTime? attentionUpdatedAtUtc,
  }) {
    return GovernedLearningChatObservationReceipt(
      id: id,
      ownerUserId: ownerUserId,
      envelopeId: envelopeId,
      sourceId: sourceId,
      kind: kind,
      outcome: outcome ?? this.outcome,
      recordedAtUtc: recordedAtUtc,
      chatId: chatId,
      userMessageId: userMessageId,
      assistantMessageId: assistantMessageId ?? this.assistantMessageId,
      focus: focus,
      userQuestion: userQuestion,
      renderedResponse: renderedResponse,
      resolvedAtUtc: resolvedAtUtc ?? this.resolvedAtUtc,
      validationStatus: validationStatus ?? this.validationStatus,
      validatedAtUtc: validatedAtUtc ?? this.validatedAtUtc,
      validatedSurface: validatedSurface ?? this.validatedSurface,
      validatedTargetEntityTitle:
          validatedTargetEntityTitle ?? this.validatedTargetEntityTitle,
      governanceStatus: governanceStatus ?? this.governanceStatus,
      governanceUpdatedAtUtc:
          governanceUpdatedAtUtc ?? this.governanceUpdatedAtUtc,
      governanceStage: governanceStage ?? this.governanceStage,
      governanceReason: governanceReason ?? this.governanceReason,
      attentionStatus: attentionStatus ?? this.attentionStatus,
      attentionUpdatedAtUtc:
          attentionUpdatedAtUtc ?? this.attentionUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ownerUserId': ownerUserId,
        'envelopeId': envelopeId,
        'sourceId': sourceId,
        'kind': kind.name,
        'outcome': outcome.name,
        'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
        'chatId': chatId,
        'userMessageId': userMessageId,
        'assistantMessageId': assistantMessageId,
        'focus': focus,
        'userQuestion': userQuestion,
        'renderedResponse': renderedResponse,
        'resolvedAtUtc': resolvedAtUtc?.toUtc().toIso8601String(),
        'validationStatus': validationStatus.name,
        'validatedAtUtc': validatedAtUtc?.toUtc().toIso8601String(),
        'validatedSurface': validatedSurface,
        'validatedTargetEntityTitle': validatedTargetEntityTitle,
        'governanceStatus': governanceStatus.name,
        'governanceUpdatedAtUtc':
            governanceUpdatedAtUtc?.toUtc().toIso8601String(),
        'governanceStage': governanceStage,
        'governanceReason': governanceReason,
        'attentionStatus': attentionStatus.name,
        'attentionUpdatedAtUtc':
            attentionUpdatedAtUtc?.toUtc().toIso8601String(),
      };

  factory GovernedLearningChatObservationReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    return GovernedLearningChatObservationReceipt(
      id: json['id']?.toString() ?? '',
      ownerUserId: json['ownerUserId']?.toString() ?? '',
      envelopeId: json['envelopeId']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      kind: _parseGovernedLearningChatObservationKind(json['kind']),
      outcome: _parseGovernedLearningChatObservationOutcome(json['outcome']),
      recordedAtUtc: _parseDateTime(json['recordedAtUtc']),
      chatId: json['chatId']?.toString() ?? '',
      userMessageId: json['userMessageId']?.toString() ?? '',
      assistantMessageId: json['assistantMessageId']?.toString(),
      focus: json['focus']?.toString(),
      userQuestion: json['userQuestion']?.toString(),
      renderedResponse: json['renderedResponse']?.toString(),
      resolvedAtUtc: json['resolvedAtUtc'] != null
          ? _parseDateTime(json['resolvedAtUtc'])
          : null,
      validationStatus: _parseGovernedLearningChatObservationValidationStatus(
        json['validationStatus'],
      ),
      validatedAtUtc: json['validatedAtUtc'] != null
          ? _parseDateTime(json['validatedAtUtc'])
          : null,
      validatedSurface: json['validatedSurface']?.toString(),
      validatedTargetEntityTitle:
          json['validatedTargetEntityTitle']?.toString(),
      governanceStatus: _parseGovernedLearningChatObservationGovernanceStatus(
        json['governanceStatus'],
      ),
      governanceUpdatedAtUtc: json['governanceUpdatedAtUtc'] != null
          ? _parseDateTime(json['governanceUpdatedAtUtc'])
          : null,
      governanceStage: json['governanceStage']?.toString(),
      governanceReason: json['governanceReason']?.toString(),
      attentionStatus: _parseGovernedLearningChatObservationAttentionStatus(
        json['attentionStatus'],
      ),
      attentionUpdatedAtUtc: json['attentionUpdatedAtUtc'] != null
          ? _parseDateTime(json['attentionUpdatedAtUtc'])
          : null,
    );
  }
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

GovernedLearningChatObservationKind _parseGovernedLearningChatObservationKind(
    Object? value) {
  final raw = value?.toString();
  for (final kind in GovernedLearningChatObservationKind.values) {
    if (kind.name == raw) {
      return kind;
    }
  }
  return GovernedLearningChatObservationKind.explanation;
}

GovernedLearningChatObservationOutcome
    _parseGovernedLearningChatObservationOutcome(Object? value) {
  final raw = value?.toString();
  for (final outcome in GovernedLearningChatObservationOutcome.values) {
    if (outcome.name == raw) {
      return outcome;
    }
  }
  return GovernedLearningChatObservationOutcome.pending;
}

GovernedLearningChatObservationValidationStatus
    _parseGovernedLearningChatObservationValidationStatus(Object? value) {
  final raw = value?.toString();
  for (final status in GovernedLearningChatObservationValidationStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return GovernedLearningChatObservationValidationStatus.pending;
}

GovernedLearningChatObservationGovernanceStatus
    _parseGovernedLearningChatObservationGovernanceStatus(Object? value) {
  final raw = value?.toString();
  for (final status in GovernedLearningChatObservationGovernanceStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return GovernedLearningChatObservationGovernanceStatus.pending;
}

GovernedLearningChatObservationAttentionStatus
    _parseGovernedLearningChatObservationAttentionStatus(Object? value) {
  final raw = value?.toString();
  for (final status in GovernedLearningChatObservationAttentionStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return GovernedLearningChatObservationAttentionStatus.pending;
}
