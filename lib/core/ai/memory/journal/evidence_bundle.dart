enum EvidenceMethodClass {
  internalTelemetry,
  externalPaper,
  thirdPartyDataset,
  controlledExperiment,
}

enum EvidenceAdoptionVerdict {
  approved,
  rejected,
  pending,
}

class EvidenceBundle {
  final String evidenceId;
  final String sourceUri;
  final EvidenceMethodClass methodClass;
  final DateTime observedAt;
  final String datasetFingerprint;
  final String experimentContractId;
  final EvidenceAdoptionVerdict adoptionVerdict;
  final Map<String, Object?> metadata;

  const EvidenceBundle({
    required this.evidenceId,
    required this.sourceUri,
    required this.methodClass,
    required this.observedAt,
    required this.datasetFingerprint,
    required this.experimentContractId,
    required this.adoptionVerdict,
    this.metadata = const {},
  });

  bool get isValid {
    if (evidenceId.trim().isEmpty) return false;
    if (sourceUri.trim().isEmpty) return false;
    if (datasetFingerprint.trim().isEmpty) return false;
    if (experimentContractId.trim().isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'evidence_id': evidenceId,
      'source_uri': sourceUri,
      'method_class': methodClass.name,
      'observed_at': observedAt.toUtc().toIso8601String(),
      'dataset_fingerprint': datasetFingerprint,
      'experiment_contract_id': experimentContractId,
      'adoption_verdict': adoptionVerdict.name,
      'metadata': metadata,
    };
  }

  factory EvidenceBundle.fromJson(Map<String, dynamic> json) {
    return EvidenceBundle(
      evidenceId: json['evidence_id'] as String? ?? '',
      sourceUri: json['source_uri'] as String? ?? '',
      methodClass: EvidenceMethodClass.values.firstWhere(
        (v) => v.name == (json['method_class'] as String?),
        orElse: () => EvidenceMethodClass.internalTelemetry,
      ),
      observedAt: DateTime.tryParse(json['observed_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      datasetFingerprint: json['dataset_fingerprint'] as String? ?? '',
      experimentContractId: json['experiment_contract_id'] as String? ?? '',
      adoptionVerdict: EvidenceAdoptionVerdict.values.firstWhere(
        (v) => v.name == (json['adoption_verdict'] as String?),
        orElse: () => EvidenceAdoptionVerdict.pending,
      ),
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}
