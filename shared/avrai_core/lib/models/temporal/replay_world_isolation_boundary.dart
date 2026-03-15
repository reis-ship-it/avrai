enum ReplayWorldAccessPolicy {
  blocked,
  replayOnlyInternal,
  adminOnly,
}

class ReplayWorldIsolationBoundary {
  const ReplayWorldIsolationBoundary({
    required this.environmentNamespace,
    required this.sourceArtifactRefs,
    required this.runtimeMutationPolicy,
    required this.liveDataIngressPolicy,
    required this.appSurfacePolicy,
    required this.adminInspectionPolicy,
    required this.higherAgentPolicy,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentNamespace;
  final List<String> sourceArtifactRefs;
  final ReplayWorldAccessPolicy runtimeMutationPolicy;
  final ReplayWorldAccessPolicy liveDataIngressPolicy;
  final ReplayWorldAccessPolicy appSurfacePolicy;
  final ReplayWorldAccessPolicy adminInspectionPolicy;
  final ReplayWorldAccessPolicy higherAgentPolicy;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentNamespace': environmentNamespace,
      'sourceArtifactRefs': sourceArtifactRefs,
      'runtimeMutationPolicy': runtimeMutationPolicy.name,
      'liveDataIngressPolicy': liveDataIngressPolicy.name,
      'appSurfacePolicy': appSurfacePolicy.name,
      'adminInspectionPolicy': adminInspectionPolicy.name,
      'higherAgentPolicy': higherAgentPolicy.name,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayWorldIsolationBoundary.fromJson(Map<String, dynamic> json) {
    ReplayWorldAccessPolicy readPolicy(
      Object? raw,
      ReplayWorldAccessPolicy fallback,
    ) {
      for (final value in ReplayWorldAccessPolicy.values) {
        if (value.name == raw) {
          return value;
        }
      }
      return fallback;
    }

    return ReplayWorldIsolationBoundary(
      environmentNamespace: json['environmentNamespace'] as String? ?? '',
      sourceArtifactRefs: (json['sourceArtifactRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      runtimeMutationPolicy: readPolicy(
        json['runtimeMutationPolicy'],
        ReplayWorldAccessPolicy.blocked,
      ),
      liveDataIngressPolicy: readPolicy(
        json['liveDataIngressPolicy'],
        ReplayWorldAccessPolicy.blocked,
      ),
      appSurfacePolicy: readPolicy(
        json['appSurfacePolicy'],
        ReplayWorldAccessPolicy.blocked,
      ),
      adminInspectionPolicy: readPolicy(
        json['adminInspectionPolicy'],
        ReplayWorldAccessPolicy.adminOnly,
      ),
      higherAgentPolicy: readPolicy(
        json['higherAgentPolicy'],
        ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      notes:
          (json['notes'] as List?)?.map((entry) => entry.toString()).toList() ??
              const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
