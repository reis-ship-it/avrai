import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class RealityModelInterfaceContractViolation implements Exception {
  const RealityModelInterfaceContractViolation(this.message);

  final String message;

  @override
  String toString() => 'RealityModelInterfaceContractViolation: $message';
}

enum RealityModelDomain {
  place,
  event,
  community,
  list,
  business,
  locality;

  String toWireValue() {
    return switch (this) {
      RealityModelDomain.place => 'place',
      RealityModelDomain.event => 'event',
      RealityModelDomain.community => 'community',
      RealityModelDomain.list => 'list',
      RealityModelDomain.business => 'business',
      RealityModelDomain.locality => 'locality',
    };
  }

  static RealityModelDomain fromWireValue(String value) {
    return RealityModelDomain.values.firstWhere(
      (entry) => entry.toWireValue() == value,
      orElse: () => RealityModelDomain.locality,
    );
  }

  static RealityModelDomain? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in RealityModelDomain.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }

  static RealityModelDomain requireFromWireValue(String value) {
    final resolved = tryFromWireValue(value);
    if (resolved != null) {
      return resolved;
    }
    throw RealityModelInterfaceContractViolation(
      'Unknown reality-model domain wire value: $value',
    );
  }
}

enum RealityExplanationRendererKind {
  template,
  offlineSlm,
  onlineAi;

  String toWireValue() {
    return switch (this) {
      RealityExplanationRendererKind.template => 'template',
      RealityExplanationRendererKind.offlineSlm => 'offline_slm',
      RealityExplanationRendererKind.onlineAi => 'online_ai',
    };
  }

  static RealityExplanationRendererKind fromWireValue(String value) {
    return RealityExplanationRendererKind.values.firstWhere(
      (entry) => entry.toWireValue() == value,
      orElse: () => RealityExplanationRendererKind.template,
    );
  }

  static RealityExplanationRendererKind? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in RealityExplanationRendererKind.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }

  static RealityExplanationRendererKind requireFromWireValue(String value) {
    final resolved = tryFromWireValue(value);
    if (resolved != null) {
      return resolved;
    }
    throw RealityModelInterfaceContractViolation(
      'Unknown reality-model explanation renderer wire value: $value',
    );
  }
}

enum RealityUncertaintyDisposition {
  neverBluff,
  askFollowUp,
  defer;

  String toWireValue() {
    return switch (this) {
      RealityUncertaintyDisposition.neverBluff => 'never_bluff',
      RealityUncertaintyDisposition.askFollowUp => 'ask_follow_up',
      RealityUncertaintyDisposition.defer => 'defer',
    };
  }

  static RealityUncertaintyDisposition fromWireValue(String value) {
    return RealityUncertaintyDisposition.values.firstWhere(
      (entry) => entry.toWireValue() == value,
      orElse: () => RealityUncertaintyDisposition.neverBluff,
    );
  }

  static RealityUncertaintyDisposition? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in RealityUncertaintyDisposition.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }

  static RealityUncertaintyDisposition requireFromWireValue(String value) {
    final resolved = tryFromWireValue(value);
    if (resolved != null) {
      return resolved;
    }
    throw RealityModelInterfaceContractViolation(
      'Unknown reality-model uncertainty disposition wire value: $value',
    );
  }
}

enum RealityDecisionDisposition {
  recommend,
  compare,
  askFollowUp,
  defer,
  observe;

  String toWireValue() {
    return switch (this) {
      RealityDecisionDisposition.recommend => 'recommend',
      RealityDecisionDisposition.compare => 'compare',
      RealityDecisionDisposition.askFollowUp => 'ask_follow_up',
      RealityDecisionDisposition.defer => 'defer',
      RealityDecisionDisposition.observe => 'observe',
    };
  }

  static RealityDecisionDisposition fromWireValue(String value) {
    return RealityDecisionDisposition.values.firstWhere(
      (entry) => entry.toWireValue() == value,
      orElse: () => RealityDecisionDisposition.observe,
    );
  }

  static RealityDecisionDisposition? tryFromWireValue(String value) {
    final trimmed = value.trim();
    for (final entry in RealityDecisionDisposition.values) {
      if (entry.toWireValue() == trimmed) {
        return entry;
      }
    }
    return null;
  }

  static RealityDecisionDisposition requireFromWireValue(String value) {
    final resolved = tryFromWireValue(value);
    if (resolved != null) {
      return resolved;
    }
    throw RealityModelInterfaceContractViolation(
      'Unknown reality-model decision disposition wire value: $value',
    );
  }
}

enum RealityModelValidationIssue {
  missingIdentifier,
  emptySupportedDomains,
  invalidMaxEvidenceRefs,
  invalidMaxHighlights,
  invalidScore,
  invalidConfidence,
  missingSummary,
  missingRequestCandidate,
  missingTraceSelection,
}

class RealityModelValidationResult {
  const RealityModelValidationResult._({
    required this.isValid,
    required this.issues,
  });

  factory RealityModelValidationResult.valid() {
    return const RealityModelValidationResult._(
      isValid: true,
      issues: <RealityModelValidationIssue>[],
    );
  }

  factory RealityModelValidationResult.invalid(
    List<RealityModelValidationIssue> issues,
  ) {
    return RealityModelValidationResult._(
      isValid: false,
      issues: List<RealityModelValidationIssue>.unmodifiable(issues),
    );
  }

  final bool isValid;
  final List<RealityModelValidationIssue> issues;
}

class RealityModelContract {
  const RealityModelContract({
    required this.contractId,
    required this.version,
    required this.supportedDomains,
    required this.rendererKinds,
    required this.uncertaintyDisposition,
    required this.followUpQuestionsAllowed,
    required this.maxEvidenceRefs,
    required this.maxHighlights,
    this.metadata = const <String, dynamic>{},
  });

  final String contractId;
  final String version;
  final List<RealityModelDomain> supportedDomains;
  final List<RealityExplanationRendererKind> rendererKinds;
  final RealityUncertaintyDisposition uncertaintyDisposition;
  final bool followUpQuestionsAllowed;
  final int maxEvidenceRefs;
  final int maxHighlights;
  final Map<String, dynamic> metadata;

  RealityModelContract normalized() {
    return RealityModelContract(
      contractId: contractId.trim(),
      version: version.trim(),
      supportedDomains: _distinctByWireValue(supportedDomains),
      rendererKinds: _distinctByWireValue(rendererKinds),
      uncertaintyDisposition: uncertaintyDisposition,
      followUpQuestionsAllowed: followUpQuestionsAllowed,
      maxEvidenceRefs: maxEvidenceRefs < 1 ? 1 : maxEvidenceRefs,
      maxHighlights: maxHighlights < 1 ? 1 : maxHighlights,
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final normalized = this.normalized();
    return <String, dynamic>{
      'contractId': normalized.contractId,
      'version': normalized.version,
      'supportedDomains': normalized.supportedDomains
          .map((entry) => entry.toWireValue())
          .toList(growable: false),
      'rendererKinds': normalized.rendererKinds
          .map((entry) => entry.toWireValue())
          .toList(growable: false),
      'uncertaintyDisposition': normalized.uncertaintyDisposition.toWireValue(),
      'followUpQuestionsAllowed': normalized.followUpQuestionsAllowed,
      'maxEvidenceRefs': normalized.maxEvidenceRefs,
      'maxHighlights': normalized.maxHighlights,
      'metadata': normalized.metadata,
    };
  }

  factory RealityModelContract.fromJson(Map<String, dynamic> json) {
    return RealityModelContract(
      contractId: json['contractId'] as String? ?? '',
      version: json['version'] as String? ?? '',
      supportedDomains: (json['supportedDomains'] as List?)
              ?.map((entry) => RealityModelDomain.fromWireValue(
                    entry.toString(),
                  ))
              .toList(growable: false) ??
          const <RealityModelDomain>[],
      rendererKinds: (json['rendererKinds'] as List?)
              ?.map((entry) => RealityExplanationRendererKind.fromWireValue(
                    entry.toString(),
                  ))
              .toList(growable: false) ??
          const <RealityExplanationRendererKind>[],
      uncertaintyDisposition: RealityUncertaintyDisposition.fromWireValue(
        json['uncertaintyDisposition'] as String? ?? '',
      ),
      followUpQuestionsAllowed:
          json['followUpQuestionsAllowed'] as bool? ?? false,
      maxEvidenceRefs: json['maxEvidenceRefs'] as int? ?? 0,
      maxHighlights: json['maxHighlights'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }

  factory RealityModelContract.fromJsonStrict(Map<String, dynamic> json) {
    return RealityModelContract(
      contractId: json['contractId'] as String? ?? '',
      version: json['version'] as String? ?? '',
      supportedDomains: (json['supportedDomains'] as List?)
              ?.map((entry) => RealityModelDomain.requireFromWireValue(
                    entry.toString(),
                  ))
              .toList(growable: false) ??
          const <RealityModelDomain>[],
      rendererKinds: (json['rendererKinds'] as List?)
              ?.map((entry) =>
                  RealityExplanationRendererKind.requireFromWireValue(
                    entry.toString(),
                  ))
              .toList(growable: false) ??
          const <RealityExplanationRendererKind>[],
      uncertaintyDisposition:
          RealityUncertaintyDisposition.requireFromWireValue(
        json['uncertaintyDisposition'] as String? ?? '',
      ),
      followUpQuestionsAllowed:
          json['followUpQuestionsAllowed'] as bool? ?? false,
      maxEvidenceRefs: json['maxEvidenceRefs'] as int? ?? 0,
      maxHighlights: json['maxHighlights'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }
}

class RealityModelEvaluationRequest {
  const RealityModelEvaluationRequest({
    required this.requestId,
    required this.subjectId,
    required this.domain,
    required this.candidateRef,
    required this.localityCode,
    required this.cityCode,
    required this.signalTags,
    required this.evidenceRefs,
    required this.requestedAtUtc,
    this.truthScope,
    this.metadata = const <String, dynamic>{},
  });

  final String requestId;
  final String subjectId;
  final RealityModelDomain domain;
  final String candidateRef;
  final String localityCode;
  final String cityCode;
  final List<String> signalTags;
  final List<String> evidenceRefs;
  final DateTime requestedAtUtc;
  final TruthScopeDescriptor? truthScope;
  final Map<String, dynamic> metadata;

  RealityModelEvaluationRequest normalized() {
    return RealityModelEvaluationRequest(
      requestId: requestId.trim(),
      subjectId: subjectId.trim(),
      domain: domain,
      candidateRef: candidateRef.trim(),
      localityCode: localityCode.trim(),
      cityCode: cityCode.trim(),
      signalTags: _normalizedStrings(signalTags),
      evidenceRefs: _normalizedStrings(evidenceRefs),
      requestedAtUtc: requestedAtUtc.toUtc(),
      truthScope: truthScope,
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final normalized = this.normalized();
    return <String, dynamic>{
      'requestId': normalized.requestId,
      'subjectId': normalized.subjectId,
      'domain': normalized.domain.toWireValue(),
      'candidateRef': normalized.candidateRef,
      'localityCode': normalized.localityCode,
      'cityCode': normalized.cityCode,
      'signalTags': normalized.signalTags,
      'evidenceRefs': normalized.evidenceRefs,
      'requestedAtUtc': normalized.requestedAtUtc.toIso8601String(),
      'truthScope': normalized.truthScope?.toJson(),
      'metadata': normalized.metadata,
    };
  }

  factory RealityModelEvaluationRequest.fromJson(Map<String, dynamic> json) {
    return RealityModelEvaluationRequest(
      requestId: json['requestId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      domain: RealityModelDomain.fromWireValue(
        json['domain'] as String? ?? '',
      ),
      candidateRef: json['candidateRef'] as String? ?? '',
      localityCode: json['localityCode'] as String? ?? '',
      cityCode: json['cityCode'] as String? ?? '',
      signalTags: (json['signalTags'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      evidenceRefs: (json['evidenceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      requestedAtUtc: DateTime.tryParse(
            json['requestedAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }
}

class RealityModelEvaluation {
  const RealityModelEvaluation({
    required this.evaluationId,
    required this.requestId,
    required this.contractId,
    required this.domain,
    required this.candidateRef,
    required this.score,
    required this.confidence,
    required this.uncertaintySummary,
    required this.supportingEvidenceRefs,
    required this.generatedAtUtc,
    this.localityCode,
    this.truthScope,
    this.metadata = const <String, dynamic>{},
  });

  final String evaluationId;
  final String requestId;
  final String contractId;
  final RealityModelDomain domain;
  final String candidateRef;
  final double score;
  final double confidence;
  final String uncertaintySummary;
  final List<String> supportingEvidenceRefs;
  final DateTime generatedAtUtc;
  final String? localityCode;
  final TruthScopeDescriptor? truthScope;
  final Map<String, dynamic> metadata;

  RealityModelEvaluation normalized() {
    return RealityModelEvaluation(
      evaluationId: evaluationId.trim(),
      requestId: requestId.trim(),
      contractId: contractId.trim(),
      domain: domain,
      candidateRef: candidateRef.trim(),
      score: score.isFinite ? score : 0,
      confidence: confidence.isFinite ? confidence : 0,
      uncertaintySummary: uncertaintySummary.trim(),
      supportingEvidenceRefs: _normalizedStrings(supportingEvidenceRefs),
      generatedAtUtc: generatedAtUtc.toUtc(),
      localityCode:
          localityCode?.trim().isNotEmpty == true ? localityCode!.trim() : null,
      truthScope: truthScope,
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final normalized = this.normalized();
    return <String, dynamic>{
      'evaluationId': normalized.evaluationId,
      'requestId': normalized.requestId,
      'contractId': normalized.contractId,
      'domain': normalized.domain.toWireValue(),
      'candidateRef': normalized.candidateRef,
      'score': normalized.score,
      'confidence': normalized.confidence,
      'uncertaintySummary': normalized.uncertaintySummary,
      'supportingEvidenceRefs': normalized.supportingEvidenceRefs,
      'generatedAtUtc': normalized.generatedAtUtc.toIso8601String(),
      'localityCode': normalized.localityCode,
      'truthScope': normalized.truthScope?.toJson(),
      'metadata': normalized.metadata,
    };
  }

  factory RealityModelEvaluation.fromJson(Map<String, dynamic> json) {
    return RealityModelEvaluation(
      evaluationId: json['evaluationId'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      domain: RealityModelDomain.fromWireValue(
        json['domain'] as String? ?? '',
      ),
      candidateRef: json['candidateRef'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      uncertaintySummary: json['uncertaintySummary'] as String? ?? '',
      supportingEvidenceRefs: (json['supportingEvidenceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      generatedAtUtc: DateTime.tryParse(
            json['generatedAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localityCode: json['localityCode'] as String?,
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }

  factory RealityModelEvaluation.fromJsonStrict(Map<String, dynamic> json) {
    return RealityModelEvaluation(
      evaluationId: json['evaluationId'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      domain: RealityModelDomain.requireFromWireValue(
        json['domain'] as String? ?? '',
      ),
      candidateRef: json['candidateRef'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      uncertaintySummary: json['uncertaintySummary'] as String? ?? '',
      supportingEvidenceRefs: (json['supportingEvidenceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      generatedAtUtc: DateTime.tryParse(
            json['generatedAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localityCode: json['localityCode'] as String?,
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }
}

class RealityDecisionTrace {
  const RealityDecisionTrace({
    required this.traceId,
    required this.contractId,
    required this.requestId,
    required this.selectedEvaluationId,
    required this.selectedCandidateRef,
    required this.disposition,
    required this.evidenceRefs,
    required this.createdAtUtc,
    this.localityCode,
    this.metadata = const <String, dynamic>{},
  });

  final String traceId;
  final String contractId;
  final String requestId;
  final String selectedEvaluationId;
  final String selectedCandidateRef;
  final RealityDecisionDisposition disposition;
  final List<String> evidenceRefs;
  final DateTime createdAtUtc;
  final String? localityCode;
  final Map<String, dynamic> metadata;

  RealityDecisionTrace normalized() {
    return RealityDecisionTrace(
      traceId: traceId.trim(),
      contractId: contractId.trim(),
      requestId: requestId.trim(),
      selectedEvaluationId: selectedEvaluationId.trim(),
      selectedCandidateRef: selectedCandidateRef.trim(),
      disposition: disposition,
      evidenceRefs: _normalizedStrings(evidenceRefs),
      createdAtUtc: createdAtUtc.toUtc(),
      localityCode:
          localityCode?.trim().isNotEmpty == true ? localityCode!.trim() : null,
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final normalized = this.normalized();
    return <String, dynamic>{
      'traceId': normalized.traceId,
      'contractId': normalized.contractId,
      'requestId': normalized.requestId,
      'selectedEvaluationId': normalized.selectedEvaluationId,
      'selectedCandidateRef': normalized.selectedCandidateRef,
      'disposition': normalized.disposition.toWireValue(),
      'evidenceRefs': normalized.evidenceRefs,
      'createdAtUtc': normalized.createdAtUtc.toIso8601String(),
      'localityCode': normalized.localityCode,
      'metadata': normalized.metadata,
    };
  }

  factory RealityDecisionTrace.fromJson(Map<String, dynamic> json) {
    return RealityDecisionTrace(
      traceId: json['traceId'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      selectedEvaluationId: json['selectedEvaluationId'] as String? ?? '',
      selectedCandidateRef: json['selectedCandidateRef'] as String? ?? '',
      disposition: RealityDecisionDisposition.fromWireValue(
        json['disposition'] as String? ?? '',
      ),
      evidenceRefs: (json['evidenceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      createdAtUtc: DateTime.tryParse(
            json['createdAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localityCode: json['localityCode'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }

  factory RealityDecisionTrace.fromJsonStrict(Map<String, dynamic> json) {
    return RealityDecisionTrace(
      traceId: json['traceId'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      selectedEvaluationId: json['selectedEvaluationId'] as String? ?? '',
      selectedCandidateRef: json['selectedCandidateRef'] as String? ?? '',
      disposition: RealityDecisionDisposition.requireFromWireValue(
        json['disposition'] as String? ?? '',
      ),
      evidenceRefs: (json['evidenceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      createdAtUtc: DateTime.tryParse(
            json['createdAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localityCode: json['localityCode'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }
}

class RealityModelExplanation {
  const RealityModelExplanation({
    required this.explanationId,
    required this.traceId,
    required this.evaluationId,
    required this.rendererKind,
    required this.summary,
    required this.highlights,
    required this.uncertaintySummary,
    required this.createdAtUtc,
    this.followUpQuestion,
    this.metadata = const <String, dynamic>{},
  });

  final String explanationId;
  final String traceId;
  final String evaluationId;
  final RealityExplanationRendererKind rendererKind;
  final String summary;
  final List<String> highlights;
  final String uncertaintySummary;
  final DateTime createdAtUtc;
  final String? followUpQuestion;
  final Map<String, dynamic> metadata;

  RealityModelExplanation normalized() {
    return RealityModelExplanation(
      explanationId: explanationId.trim(),
      traceId: traceId.trim(),
      evaluationId: evaluationId.trim(),
      rendererKind: rendererKind,
      summary: summary.trim(),
      highlights: _normalizedStrings(highlights),
      uncertaintySummary: uncertaintySummary.trim(),
      createdAtUtc: createdAtUtc.toUtc(),
      followUpQuestion: followUpQuestion?.trim().isNotEmpty == true
          ? followUpQuestion!.trim()
          : null,
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final normalized = this.normalized();
    return <String, dynamic>{
      'explanationId': normalized.explanationId,
      'traceId': normalized.traceId,
      'evaluationId': normalized.evaluationId,
      'rendererKind': normalized.rendererKind.toWireValue(),
      'summary': normalized.summary,
      'highlights': normalized.highlights,
      'uncertaintySummary': normalized.uncertaintySummary,
      'createdAtUtc': normalized.createdAtUtc.toIso8601String(),
      'followUpQuestion': normalized.followUpQuestion,
      'metadata': normalized.metadata,
    };
  }

  factory RealityModelExplanation.fromJson(Map<String, dynamic> json) {
    return RealityModelExplanation(
      explanationId: json['explanationId'] as String? ?? '',
      traceId: json['traceId'] as String? ?? '',
      evaluationId: json['evaluationId'] as String? ?? '',
      rendererKind: RealityExplanationRendererKind.fromWireValue(
        json['rendererKind'] as String? ?? '',
      ),
      summary: json['summary'] as String? ?? '',
      highlights: (json['highlights'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      uncertaintySummary: json['uncertaintySummary'] as String? ?? '',
      createdAtUtc: DateTime.tryParse(
            json['createdAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      followUpQuestion: json['followUpQuestion'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }

  factory RealityModelExplanation.fromJsonStrict(Map<String, dynamic> json) {
    return RealityModelExplanation(
      explanationId: json['explanationId'] as String? ?? '',
      traceId: json['traceId'] as String? ?? '',
      evaluationId: json['evaluationId'] as String? ?? '',
      rendererKind: RealityExplanationRendererKind.requireFromWireValue(
        json['rendererKind'] as String? ?? '',
      ),
      summary: json['summary'] as String? ?? '',
      highlights: (json['highlights'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      uncertaintySummary: json['uncertaintySummary'] as String? ?? '',
      createdAtUtc: DateTime.tryParse(
            json['createdAtUtc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      followUpQuestion: json['followUpQuestion'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    ).normalized();
  }
}

class RealityModelBoundaryValidator {
  const RealityModelBoundaryValidator();

  RealityModelValidationResult validateContract(RealityModelContract contract) {
    final issues = <RealityModelValidationIssue>[];
    if (contract.contractId.trim().isEmpty || contract.version.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingIdentifier);
    }
    if (contract.supportedDomains.isEmpty) {
      issues.add(RealityModelValidationIssue.emptySupportedDomains);
    }
    if (contract.maxEvidenceRefs < 1) {
      issues.add(RealityModelValidationIssue.invalidMaxEvidenceRefs);
    }
    if (contract.maxHighlights < 1) {
      issues.add(RealityModelValidationIssue.invalidMaxHighlights);
    }
    return issues.isEmpty
        ? RealityModelValidationResult.valid()
        : RealityModelValidationResult.invalid(issues);
  }

  RealityModelValidationResult validateRequest(
    RealityModelEvaluationRequest request,
  ) {
    final issues = <RealityModelValidationIssue>[];
    if (request.requestId.trim().isEmpty || request.subjectId.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingIdentifier);
    }
    if (request.candidateRef.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingRequestCandidate);
    }
    return issues.isEmpty
        ? RealityModelValidationResult.valid()
        : RealityModelValidationResult.invalid(issues);
  }

  RealityModelValidationResult validateEvaluation(
    RealityModelEvaluation evaluation,
  ) {
    final issues = <RealityModelValidationIssue>[];
    if (evaluation.evaluationId.trim().isEmpty ||
        evaluation.requestId.trim().isEmpty ||
        evaluation.contractId.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingIdentifier);
    }
    if (!_isScoreBounded(evaluation.score)) {
      issues.add(RealityModelValidationIssue.invalidScore);
    }
    if (!_isScoreBounded(evaluation.confidence)) {
      issues.add(RealityModelValidationIssue.invalidConfidence);
    }
    return issues.isEmpty
        ? RealityModelValidationResult.valid()
        : RealityModelValidationResult.invalid(issues);
  }

  RealityModelValidationResult validateTrace(RealityDecisionTrace trace) {
    final issues = <RealityModelValidationIssue>[];
    if (trace.traceId.trim().isEmpty ||
        trace.contractId.trim().isEmpty ||
        trace.requestId.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingIdentifier);
    }
    if (trace.selectedEvaluationId.trim().isEmpty ||
        trace.selectedCandidateRef.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingTraceSelection);
    }
    return issues.isEmpty
        ? RealityModelValidationResult.valid()
        : RealityModelValidationResult.invalid(issues);
  }

  RealityModelValidationResult validateExplanation(
    RealityModelExplanation explanation,
  ) {
    final issues = <RealityModelValidationIssue>[];
    if (explanation.explanationId.trim().isEmpty ||
        explanation.traceId.trim().isEmpty ||
        explanation.evaluationId.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingIdentifier);
    }
    if (explanation.summary.trim().isEmpty) {
      issues.add(RealityModelValidationIssue.missingSummary);
    }
    return issues.isEmpty
        ? RealityModelValidationResult.valid()
        : RealityModelValidationResult.invalid(issues);
  }

  bool _isScoreBounded(double value) {
    return value.isFinite && value >= 0 && value <= 1;
  }
}

List<T> _distinctByWireValue<T>(List<T> entries) {
  final seen = <String>{};
  final normalized = <T>[];
  for (final entry in entries) {
    final wireValue = switch (entry) {
      RealityModelDomain domain => domain.toWireValue(),
      RealityExplanationRendererKind renderer => renderer.toWireValue(),
      RealityUncertaintyDisposition disposition => disposition.toWireValue(),
      RealityDecisionDisposition decision => decision.toWireValue(),
      _ => entry.toString(),
    };
    if (wireValue.isEmpty || !seen.add(wireValue)) {
      continue;
    }
    normalized.add(entry);
  }
  return List<T>.unmodifiable(normalized);
}

List<String> _normalizedStrings(List<String> values) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }
  return List<String>.unmodifiable(normalized);
}
