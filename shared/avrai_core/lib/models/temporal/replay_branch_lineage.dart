import 'package:avrai_core/models/temporal/temporal_instant.dart';

class ReplayBranchLineage {
  const ReplayBranchLineage({
    required this.branchId,
    required this.runId,
    required this.canonicalReplayYear,
    required this.seed,
    required this.createdAt,
    this.parentBranchId,
    this.parentRunId,
    this.divergencePointRef,
    this.branchPurpose,
    this.metadata = const <String, dynamic>{},
  });

  final String branchId;
  final String runId;
  final int canonicalReplayYear;
  final int seed;
  final TemporalInstant createdAt;
  final String? parentBranchId;
  final String? parentRunId;
  final String? divergencePointRef;
  final String? branchPurpose;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'runId': runId,
      'canonicalReplayYear': canonicalReplayYear,
      'seed': seed,
      'createdAt': createdAt.toJson(),
      'parentBranchId': parentBranchId,
      'parentRunId': parentRunId,
      'divergencePointRef': divergencePointRef,
      'branchPurpose': branchPurpose,
      'metadata': metadata,
    };
  }

  factory ReplayBranchLineage.fromJson(Map<String, dynamic> json) {
    return ReplayBranchLineage(
      branchId: json['branchId'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      canonicalReplayYear: (json['canonicalReplayYear'] as num?)?.toInt() ?? 0,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      createdAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['createdAt'] as Map? ?? const {}),
      ),
      parentBranchId: json['parentBranchId'] as String?,
      parentRunId: json['parentRunId'] as String?,
      divergencePointRef: json['divergencePointRef'] as String?,
      branchPurpose: json['branchPurpose'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
