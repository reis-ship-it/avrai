class MonteCarloRunContext {
  const MonteCarloRunContext({
    required this.canonicalReplayYear,
    required this.replayYear,
    required this.branchId,
    required this.runId,
    required this.seed,
    required this.divergencePolicy,
    this.branchPurpose,
    this.parentRunId,
    this.parentBranchId,
    this.metadata = const <String, dynamic>{},
  });

  final int canonicalReplayYear;
  final int replayYear;
  final String branchId;
  final String runId;
  final int seed;
  final String divergencePolicy;
  final String? branchPurpose;
  final String? parentRunId;
  final String? parentBranchId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'canonicalReplayYear': canonicalReplayYear,
      'replayYear': replayYear,
      'branchId': branchId,
      'runId': runId,
      'seed': seed,
      'divergencePolicy': divergencePolicy,
      'branchPurpose': branchPurpose,
      'parentRunId': parentRunId,
      'parentBranchId': parentBranchId,
      'metadata': metadata,
    };
  }

  factory MonteCarloRunContext.fromJson(Map<String, dynamic> json) {
    return MonteCarloRunContext(
      canonicalReplayYear: (json['canonicalReplayYear'] as num?)?.toInt() ?? 0,
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      branchId: json['branchId'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      divergencePolicy: json['divergencePolicy'] as String? ?? 'unknown',
      branchPurpose: json['branchPurpose'] as String?,
      parentRunId: json['parentRunId'] as String?,
      parentBranchId: json['parentBranchId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
