class ReplayOutcomeLabel {
  const ReplayOutcomeLabel({
    required this.labelId,
    required this.actorId,
    required this.contextId,
    required this.contextType,
    required this.monthKey,
    required this.outcomeKind,
    required this.outcomeValue,
    this.metadata = const <String, dynamic>{},
  });

  final String labelId;
  final String actorId;
  final String contextId;
  final String contextType;
  final String monthKey;
  final String outcomeKind;
  final String outcomeValue;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'labelId': labelId,
      'actorId': actorId,
      'contextId': contextId,
      'contextType': contextType,
      'monthKey': monthKey,
      'outcomeKind': outcomeKind,
      'outcomeValue': outcomeValue,
      'metadata': metadata,
    };
  }

  factory ReplayOutcomeLabel.fromJson(Map<String, dynamic> json) {
    return ReplayOutcomeLabel(
      labelId: json['labelId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      contextId: json['contextId'] as String? ?? '',
      contextType: json['contextType'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      outcomeKind: json['outcomeKind'] as String? ?? '',
      outcomeValue: json['outcomeValue'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
