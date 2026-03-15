class ReplayAgentKernelBundle {
  const ReplayAgentKernelBundle({
    required this.actorId,
    required this.attachedKernelIds,
    required this.readyKernelIds,
    required this.higherAgentInterfaces,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final List<String> attachedKernelIds;
  final List<String> readyKernelIds;
  final List<String> higherAgentInterfaces;
  final Map<String, dynamic> metadata;

  bool get hasFullRequiredBundle =>
      attachedKernelIds.toSet().containsAll(readyKernelIds.toSet());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'attachedKernelIds': attachedKernelIds,
      'readyKernelIds': readyKernelIds,
      'higherAgentInterfaces': higherAgentInterfaces,
      'metadata': metadata,
    };
  }

  factory ReplayAgentKernelBundle.fromJson(Map<String, dynamic> json) {
    return ReplayAgentKernelBundle(
      actorId: json['actorId'] as String? ?? '',
      attachedKernelIds: (json['attachedKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      readyKernelIds: (json['readyKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      higherAgentInterfaces: (json['higherAgentInterfaces'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayKernelActivationTrace {
  const ReplayKernelActivationTrace({
    required this.traceId,
    required this.actorId,
    required this.contextType,
    required this.contextId,
    required this.activatedKernelIds,
    required this.higherAgentGuidanceIds,
    this.metadata = const <String, dynamic>{},
  });

  final String traceId;
  final String actorId;
  final String contextType;
  final String contextId;
  final List<String> activatedKernelIds;
  final List<String> higherAgentGuidanceIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'traceId': traceId,
      'actorId': actorId,
      'contextType': contextType,
      'contextId': contextId,
      'activatedKernelIds': activatedKernelIds,
      'higherAgentGuidanceIds': higherAgentGuidanceIds,
      'metadata': metadata,
    };
  }

  factory ReplayKernelActivationTrace.fromJson(Map<String, dynamic> json) {
    return ReplayKernelActivationTrace(
      traceId: json['traceId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      contextType: json['contextType'] as String? ?? '',
      contextId: json['contextId'] as String? ?? '',
      activatedKernelIds: (json['activatedKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      higherAgentGuidanceIds: (json['higherAgentGuidanceIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
