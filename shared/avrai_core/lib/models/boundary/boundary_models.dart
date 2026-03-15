import 'package:equatable/equatable.dart';

import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';

enum BoundaryPrivacyMode {
  localSovereign,
  userRuntime,
  ai2aiOptIn,
  governance;

  String toWireValue() => switch (this) {
        BoundaryPrivacyMode.localSovereign => 'local_sovereign',
        BoundaryPrivacyMode.userRuntime => 'user_runtime',
        BoundaryPrivacyMode.ai2aiOptIn => 'ai2ai_opt_in',
        BoundaryPrivacyMode.governance => 'governance',
      };

  static BoundaryPrivacyMode fromWireValue(String? value) => switch (value) {
        'user_runtime' => BoundaryPrivacyMode.userRuntime,
        'ai2ai_opt_in' => BoundaryPrivacyMode.ai2aiOptIn,
        'governance' => BoundaryPrivacyMode.governance,
        _ => BoundaryPrivacyMode.localSovereign,
      };
}

enum BoundaryDisposition {
  block,
  localOnly,
  storeSanitized,
  userAuthorizedEgress,
  egressViaAirGap;

  String toWireValue() => switch (this) {
        BoundaryDisposition.block => 'block',
        BoundaryDisposition.localOnly => 'local_only',
        BoundaryDisposition.storeSanitized => 'store_sanitized',
        BoundaryDisposition.userAuthorizedEgress => 'user_authorized_egress',
        BoundaryDisposition.egressViaAirGap => 'egress_via_air_gap',
      };

  static BoundaryDisposition fromWireValue(String? value) => switch (value) {
        'local_only' => BoundaryDisposition.localOnly,
        'store_sanitized' => BoundaryDisposition.storeSanitized,
        'user_authorized_egress' => BoundaryDisposition.userAuthorizedEgress,
        'egress_via_air_gap' => BoundaryDisposition.egressViaAirGap,
        _ => BoundaryDisposition.block,
      };
}

enum BoundaryEgressPurpose {
  none,
  directMessage,
  communityMessage,
  ai2aiLearningArtifact,
  adminExport,
  externalShare;

  String toWireValue() => switch (this) {
        BoundaryEgressPurpose.none => 'none',
        BoundaryEgressPurpose.directMessage => 'direct_message',
        BoundaryEgressPurpose.communityMessage => 'community_message',
        BoundaryEgressPurpose.ai2aiLearningArtifact =>
          'ai2ai_learning_artifact',
        BoundaryEgressPurpose.adminExport => 'admin_export',
        BoundaryEgressPurpose.externalShare => 'external_share',
      };

  static BoundaryEgressPurpose fromWireValue(String? value) => switch (value) {
        'direct_message' => BoundaryEgressPurpose.directMessage,
        'community_message' => BoundaryEgressPurpose.communityMessage,
        'ai2ai_learning_artifact' =>
          BoundaryEgressPurpose.ai2aiLearningArtifact,
        'admin_export' => BoundaryEgressPurpose.adminExport,
        'external_share' => BoundaryEgressPurpose.externalShare,
        _ => BoundaryEgressPurpose.none,
      };
}

class BoundarySanitizedArtifact extends Equatable {
  const BoundarySanitizedArtifact({
    required this.pseudonymousActorRef,
    required this.summary,
    required this.safeClaims,
    required this.safeQuestions,
    required this.safePreferenceSignals,
    required this.learningVocabulary,
    required this.learningPhrases,
    required this.redactedText,
    this.sharePayload,
    this.schemaVersion = 1,
  });

  final String pseudonymousActorRef;
  final String summary;
  final List<String> safeClaims;
  final List<String> safeQuestions;
  final List<InterpretationPreferenceSignal> safePreferenceSignals;
  final List<String> learningVocabulary;
  final List<String> learningPhrases;
  final String redactedText;
  final String? sharePayload;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pseudonymous_actor_ref': pseudonymousActorRef,
        'summary': summary,
        'safe_claims': safeClaims,
        'safe_questions': safeQuestions,
        'safe_preference_signals':
            safePreferenceSignals.map((entry) => entry.toJson()).toList(),
        'learning_vocabulary': learningVocabulary,
        'learning_phrases': learningPhrases,
        'redacted_text': redactedText,
        if (sharePayload != null) 'share_payload': sharePayload,
        'schema_version': schemaVersion,
      };

  factory BoundarySanitizedArtifact.fromJson(Map<String, dynamic> json) {
    return BoundarySanitizedArtifact(
      pseudonymousActorRef:
          json['pseudonymous_actor_ref'] as String? ?? 'anon_unknown',
      summary: json['summary'] as String? ?? '',
      safeClaims: ((json['safe_claims'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      safeQuestions: ((json['safe_questions'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      safePreferenceSignals:
          ((json['safe_preference_signals'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => InterpretationPreferenceSignal.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      learningVocabulary:
          ((json['learning_vocabulary'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      learningPhrases:
          ((json['learning_phrases'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      redactedText: json['redacted_text'] as String? ?? '',
      sharePayload: json['share_payload'] as String?,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        pseudonymousActorRef,
        summary,
        safeClaims,
        safeQuestions,
        safePreferenceSignals,
        learningVocabulary,
        learningPhrases,
        redactedText,
        sharePayload,
        schemaVersion,
      ];
}

class BoundaryDecision extends Equatable {
  const BoundaryDecision({
    required this.accepted,
    required this.disposition,
    required this.transcriptStorageAllowed,
    required this.storageAllowed,
    required this.learningAllowed,
    required this.egressAllowed,
    required this.airGapRequired,
    required this.reasonCodes,
    required this.sanitizedArtifact,
    this.vibeMutationDecision = const VibeMutationDecision(
      stateWriteAllowed: false,
      dnaWriteAllowed: false,
      pheromoneWriteAllowed: false,
      behaviorWriteAllowed: false,
      affectiveWriteAllowed: false,
      styleWriteAllowed: false,
      reasonCodes: <String>[],
    ),
    this.egressPurpose = BoundaryEgressPurpose.none,
    this.schemaVersion = 1,
  });

  final bool accepted;
  final BoundaryDisposition disposition;
  final bool transcriptStorageAllowed;
  final bool storageAllowed;
  final bool learningAllowed;
  final bool egressAllowed;
  final bool airGapRequired;
  final List<String> reasonCodes;
  final BoundarySanitizedArtifact sanitizedArtifact;
  final VibeMutationDecision vibeMutationDecision;
  final BoundaryEgressPurpose egressPurpose;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accepted': accepted,
        'disposition': disposition.toWireValue(),
        'transcript_storage_allowed': transcriptStorageAllowed,
        'storage_allowed': storageAllowed,
        'learning_allowed': learningAllowed,
        'egress_allowed': egressAllowed,
        'air_gap_required': airGapRequired,
        'reason_codes': reasonCodes,
        'sanitized_artifact': sanitizedArtifact.toJson(),
        'vibe_mutation_decision': vibeMutationDecision.toJson(),
        'egress_purpose': egressPurpose.toWireValue(),
        'schema_version': schemaVersion,
      };

  factory BoundaryDecision.fromJson(Map<String, dynamic> json) {
    return BoundaryDecision(
      accepted: json['accepted'] as bool? ?? false,
      disposition:
          BoundaryDisposition.fromWireValue(json['disposition'] as String?),
      transcriptStorageAllowed:
          json['transcript_storage_allowed'] as bool? ??
              json['storage_allowed'] as bool? ??
              false,
      storageAllowed: json['storage_allowed'] as bool? ?? false,
      learningAllowed: json['learning_allowed'] as bool? ?? false,
      egressAllowed: json['egress_allowed'] as bool? ?? false,
      airGapRequired: json['air_gap_required'] as bool? ?? false,
      reasonCodes: ((json['reason_codes'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      sanitizedArtifact: BoundarySanitizedArtifact.fromJson(
        Map<String, dynamic>.from(
          (json['sanitized_artifact'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      vibeMutationDecision: VibeMutationDecision.fromJson(
        Map<String, dynamic>.from(
          (json['vibe_mutation_decision'] as Map?) ??
              const <String, dynamic>{},
        ),
      ),
      egressPurpose:
          BoundaryEgressPurpose.fromWireValue(json['egress_purpose'] as String?),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        accepted,
        disposition,
        transcriptStorageAllowed,
        storageAllowed,
        learningAllowed,
        egressAllowed,
        airGapRequired,
        reasonCodes,
        sanitizedArtifact,
        vibeMutationDecision,
        egressPurpose,
        schemaVersion,
      ];
}
