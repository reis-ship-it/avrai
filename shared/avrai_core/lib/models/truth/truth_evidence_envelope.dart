import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:equatable/equatable.dart';

class TruthEvidenceEnvelope extends Equatable {
  const TruthEvidenceEnvelope({
    required this.scope,
    required this.traceId,
    required this.evidenceClass,
    required this.privacyLadderTag,
    this.sourceRefs = const <String>[],
    this.approvals = const <String>[],
    this.rollbackRefs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final TruthScopeDescriptor scope;
  final String traceId;
  final String evidenceClass;
  final String privacyLadderTag;
  final List<String> sourceRefs;
  final List<String> approvals;
  final List<String> rollbackRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scope': scope.toJson(),
      'traceId': traceId,
      'evidenceClass': evidenceClass,
      'privacyLadderTag': privacyLadderTag,
      'sourceRefs': sourceRefs,
      'approvals': approvals,
      'rollbackRefs': rollbackRefs,
      'metadata': metadata,
    };
  }

  factory TruthEvidenceEnvelope.fromJson(Map<String, dynamic> json) {
    return TruthEvidenceEnvelope(
      scope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(json['scope'] as Map? ?? const {}),
      ),
      traceId: json['traceId'] as String? ?? '',
      evidenceClass: json['evidenceClass'] as String? ?? 'unknown',
      privacyLadderTag: json['privacyLadderTag'] as String? ?? 'redacted',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      approvals: (json['approvals'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      rollbackRefs: (json['rollbackRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        scope,
        traceId,
        evidenceClass,
        privacyLadderTag,
        sourceRefs,
        approvals,
        rollbackRefs,
        metadata,
      ];
}
