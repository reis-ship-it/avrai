class ReplayActionExplanation {
  const ReplayActionExplanation({
    required this.actionId,
    required this.actorOrAgentId,
    required this.kernelLanes,
    required this.supportingSourceRefs,
    required this.explanation,
    required this.localityAnchor,
    this.metadata = const <String, dynamic>{},
  });

  final String actionId;
  final String actorOrAgentId;
  final List<String> kernelLanes;
  final List<String> supportingSourceRefs;
  final String explanation;
  final String localityAnchor;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actionId': actionId,
      'actorOrAgentId': actorOrAgentId,
      'kernelLanes': kernelLanes,
      'supportingSourceRefs': supportingSourceRefs,
      'explanation': explanation,
      'localityAnchor': localityAnchor,
      'metadata': metadata,
    };
  }

  factory ReplayActionExplanation.fromJson(Map<String, dynamic> json) {
    return ReplayActionExplanation(
      actionId: json['actionId'] as String? ?? '',
      actorOrAgentId: json['actorOrAgentId'] as String? ?? '',
      kernelLanes: (json['kernelLanes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      supportingSourceRefs: (json['supportingSourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      explanation: json['explanation'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
