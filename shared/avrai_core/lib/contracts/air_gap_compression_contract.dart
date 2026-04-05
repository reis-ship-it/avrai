import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:equatable/equatable.dart';

class AirGapCompressionContract extends Equatable {
  const AirGapCompressionContract({
    required this.contractId,
    required this.artifactType,
    required this.payload,
    required this.privacyLadderTag,
    this.provenanceRefs = const <String>[],
    this.requiredRetainedPaths = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String contractId;
  final AirGapCompressionArtifactType artifactType;
  final Map<String, dynamic> payload;
  final String privacyLadderTag;
  final List<String> provenanceRefs;
  final List<String> requiredRetainedPaths;
  final Map<String, dynamic> metadata;

  factory AirGapCompressionContract.semanticTupleBundle({
    required String contractId,
    required List<SemanticTuple> tuples,
    required String privacyLadderTag,
    List<String> provenanceRefs = const <String>[],
    List<String> requiredRetainedPaths = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return AirGapCompressionContract(
      contractId: contractId,
      artifactType: AirGapCompressionArtifactType.semanticTupleBundle,
      payload: <String, dynamic>{
        'tuples': tuples.map((tuple) => tuple.toJson()).toList(),
      },
      privacyLadderTag: privacyLadderTag,
      provenanceRefs: provenanceRefs,
      requiredRetainedPaths: requiredRetainedPaths,
      metadata: metadata,
    );
  }

  factory AirGapCompressionContract.safeEmbeddingVector({
    required String contractId,
    required List<double> values,
    required String privacyLadderTag,
    required String embeddingKind,
    List<String> provenanceRefs = const <String>[],
    List<String> requiredRetainedPaths = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return AirGapCompressionContract(
      contractId: contractId,
      artifactType: AirGapCompressionArtifactType.safeEmbeddingVector,
      payload: <String, dynamic>{
        'values': values,
        'embeddingKind': embeddingKind,
      },
      privacyLadderTag: privacyLadderTag,
      provenanceRefs: provenanceRefs,
      requiredRetainedPaths: requiredRetainedPaths,
      metadata: metadata,
    );
  }

  factory AirGapCompressionContract.truthEvidenceEnvelope({
    required String contractId,
    required TruthEvidenceEnvelope envelope,
    List<String> requiredRetainedPaths = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return AirGapCompressionContract(
      contractId: contractId,
      artifactType: AirGapCompressionArtifactType.truthEvidenceEnvelope,
      payload: envelope.toJson(),
      privacyLadderTag: envelope.privacyLadderTag,
      provenanceRefs: envelope.sourceRefs,
      requiredRetainedPaths: requiredRetainedPaths,
      metadata: metadata,
    );
  }

  factory AirGapCompressionContract.higherLayerArtifact({
    required String contractId,
    required Map<String, dynamic> artifact,
    required String privacyLadderTag,
    required String approvalRef,
    List<String> provenanceRefs = const <String>[],
    List<String> requiredRetainedPaths = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return AirGapCompressionContract(
      contractId: contractId,
      artifactType: AirGapCompressionArtifactType.higherLayerArtifact,
      payload: <String, dynamic>{
        'artifact': artifact,
      },
      privacyLadderTag: privacyLadderTag,
      provenanceRefs: provenanceRefs,
      requiredRetainedPaths: requiredRetainedPaths,
      metadata: <String, dynamic>{
        ...metadata,
        'approvalRef': approvalRef,
        'policyApprovedHigherLayerArtifact': true,
      },
    );
  }

  AirGapCompressionContract normalized() {
    return AirGapCompressionContract(
      contractId:
          contractId.trim().isEmpty ? 'air_gap_compression' : contractId.trim(),
      artifactType: artifactType,
      payload: Map<String, dynamic>.from(payload),
      privacyLadderTag: privacyLadderTag.trim().isEmpty
          ? 'redacted'
          : privacyLadderTag.trim(),
      provenanceRefs: _normalizeStrings(provenanceRefs),
      requiredRetainedPaths: _normalizeStrings(requiredRetainedPaths),
      metadata: Map<String, dynamic>.from(metadata),
    );
  }

  static List<String> _normalizeStrings(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  List<Object?> get props => <Object?>[
        contractId,
        artifactType,
        payload,
        privacyLadderTag,
        provenanceRefs,
        requiredRetainedPaths,
        metadata,
      ];
}

class AirGapCompressionException implements Exception {
  AirGapCompressionException(this.message);

  final String message;

  @override
  String toString() => 'AirGapCompressionException: $message';
}
