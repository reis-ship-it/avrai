import 'package:equatable/equatable.dart';

import 'package:avrai_core/models/vibe/vibe_models.dart';

enum InterpretationIntent {
  inform,
  ask,
  prefer,
  correct,
  confirm,
  reject,
  reflect,
  plan,
  share,
  unknown;

  String toWireValue() => switch (this) {
        InterpretationIntent.inform => 'inform',
        InterpretationIntent.ask => 'ask',
        InterpretationIntent.prefer => 'prefer',
        InterpretationIntent.correct => 'correct',
        InterpretationIntent.confirm => 'confirm',
        InterpretationIntent.reject => 'reject',
        InterpretationIntent.reflect => 'reflect',
        InterpretationIntent.plan => 'plan',
        InterpretationIntent.share => 'share',
        InterpretationIntent.unknown => 'unknown',
      };

  static InterpretationIntent fromWireValue(String? value) => switch (value) {
        'inform' => InterpretationIntent.inform,
        'ask' => InterpretationIntent.ask,
        'prefer' => InterpretationIntent.prefer,
        'correct' => InterpretationIntent.correct,
        'confirm' => InterpretationIntent.confirm,
        'reject' => InterpretationIntent.reject,
        'reflect' => InterpretationIntent.reflect,
        'plan' => InterpretationIntent.plan,
        'share' => InterpretationIntent.share,
        _ => InterpretationIntent.unknown,
      };
}

enum InterpretationPrivacySensitivity {
  low,
  medium,
  high;

  String toWireValue() => switch (this) {
        InterpretationPrivacySensitivity.low => 'low',
        InterpretationPrivacySensitivity.medium => 'medium',
        InterpretationPrivacySensitivity.high => 'high',
      };

  static InterpretationPrivacySensitivity fromWireValue(String? value) =>
      switch (value) {
        'low' => InterpretationPrivacySensitivity.low,
        'high' => InterpretationPrivacySensitivity.high,
        _ => InterpretationPrivacySensitivity.medium,
      };
}

class InterpretationPreferenceSignal extends Equatable {
  const InterpretationPreferenceSignal({
    required this.kind,
    required this.value,
    required this.confidence,
  });

  final String kind;
  final String value;
  final double confidence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind,
        'value': value,
        'confidence': confidence,
      };

  factory InterpretationPreferenceSignal.fromJson(Map<String, dynamic> json) {
    return InterpretationPreferenceSignal(
      kind: json['kind'] as String? ?? 'unknown',
      value: json['value'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => <Object?>[kind, value, confidence];
}

class InterpretationRequestArtifact extends Equatable {
  const InterpretationRequestArtifact({
    required this.summary,
    required this.asksForResponse,
    required this.asksForRecommendation,
    required this.asksForAction,
    required this.asksForExplanation,
    required this.referencedEntities,
    required this.questions,
    required this.preferenceSignals,
    required this.shareIntent,
  });

  final String summary;
  final bool asksForResponse;
  final bool asksForRecommendation;
  final bool asksForAction;
  final bool asksForExplanation;
  final List<String> referencedEntities;
  final List<String> questions;
  final List<InterpretationPreferenceSignal> preferenceSignals;
  final bool shareIntent;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'summary': summary,
        'asks_for_response': asksForResponse,
        'asks_for_recommendation': asksForRecommendation,
        'asks_for_action': asksForAction,
        'asks_for_explanation': asksForExplanation,
        'referenced_entities': referencedEntities,
        'questions': questions,
        'preference_signals':
            preferenceSignals.map((entry) => entry.toJson()).toList(),
        'share_intent': shareIntent,
      };

  factory InterpretationRequestArtifact.fromJson(Map<String, dynamic> json) {
    return InterpretationRequestArtifact(
      summary: json['summary'] as String? ?? '',
      asksForResponse: json['asks_for_response'] as bool? ?? true,
      asksForRecommendation: json['asks_for_recommendation'] as bool? ?? false,
      asksForAction: json['asks_for_action'] as bool? ?? false,
      asksForExplanation: json['asks_for_explanation'] as bool? ?? false,
      referencedEntities:
          ((json['referenced_entities'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      questions: ((json['questions'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      preferenceSignals:
          ((json['preference_signals'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => InterpretationPreferenceSignal.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
      shareIntent: json['share_intent'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        summary,
        asksForResponse,
        asksForRecommendation,
        asksForAction,
        asksForExplanation,
        referencedEntities,
        questions,
        preferenceSignals,
        shareIntent,
      ];
}

class InterpretationLearningArtifact extends Equatable {
  const InterpretationLearningArtifact({
    required this.vocabulary,
    required this.phrases,
    required this.toneMetrics,
    required this.directnessPreference,
    required this.brevityPreference,
    this.schemaVersion = 1,
  });

  final List<String> vocabulary;
  final List<String> phrases;
  final Map<String, double> toneMetrics;
  final double directnessPreference;
  final double brevityPreference;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vocabulary': vocabulary,
        'phrases': phrases,
        'tone_metrics': toneMetrics,
        'directness_preference': directnessPreference,
        'brevity_preference': brevityPreference,
        'schema_version': schemaVersion,
      };

  factory InterpretationLearningArtifact.fromJson(Map<String, dynamic> json) {
    return InterpretationLearningArtifact(
      vocabulary: ((json['vocabulary'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      phrases: ((json['phrases'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      toneMetrics:
          ((json['tone_metrics'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      directnessPreference:
          (json['directness_preference'] as num?)?.toDouble() ?? 0.5,
      brevityPreference:
          (json['brevity_preference'] as num?)?.toDouble() ?? 0.5,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        vocabulary,
        phrases,
        toneMetrics,
        directnessPreference,
        brevityPreference,
        schemaVersion,
      ];
}

class InterpretationResult extends Equatable {
  const InterpretationResult({
    required this.intent,
    required this.normalizedText,
    required this.requestArtifact,
    required this.learningArtifact,
    this.vibeEvidence = const VibeEvidence(
      summary: '',
      identitySignals: <VibeSignal>[],
      pheromoneSignals: <VibeSignal>[],
      behaviorSignals: <VibeSignal>[],
      affectiveSignals: <VibeSignal>[],
      styleSignals: <VibeSignal>[],
    ),
    required this.privacySensitivity,
    required this.confidence,
    required this.ambiguityFlags,
    required this.needsClarification,
    required this.safeForLearning,
    this.schemaVersion = 1,
  });

  final InterpretationIntent intent;
  final String normalizedText;
  final InterpretationRequestArtifact requestArtifact;
  final InterpretationLearningArtifact learningArtifact;
  final VibeEvidence vibeEvidence;
  final InterpretationPrivacySensitivity privacySensitivity;
  final double confidence;
  final List<String> ambiguityFlags;
  final bool needsClarification;
  final bool safeForLearning;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'intent': intent.toWireValue(),
        'normalized_text': normalizedText,
        'request_artifact': requestArtifact.toJson(),
        'learning_artifact': learningArtifact.toJson(),
        'vibe_evidence': vibeEvidence.toJson(),
        'privacy_sensitivity': privacySensitivity.toWireValue(),
        'confidence': confidence,
        'ambiguity_flags': ambiguityFlags,
        'needs_clarification': needsClarification,
        'safe_for_learning': safeForLearning,
        'schema_version': schemaVersion,
      };

  factory InterpretationResult.fromJson(Map<String, dynamic> json) {
    return InterpretationResult(
      intent: InterpretationIntent.fromWireValue(json['intent'] as String?),
      normalizedText: json['normalized_text'] as String? ?? '',
      requestArtifact: InterpretationRequestArtifact.fromJson(
        Map<String, dynamic>.from(
          (json['request_artifact'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      learningArtifact: InterpretationLearningArtifact.fromJson(
        Map<String, dynamic>.from(
          (json['learning_artifact'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      vibeEvidence: VibeEvidence.fromJson(
        Map<String, dynamic>.from(
          (json['vibe_evidence'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      privacySensitivity: InterpretationPrivacySensitivity.fromWireValue(
        json['privacy_sensitivity'] as String?,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      ambiguityFlags: ((json['ambiguity_flags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      needsClarification: json['needs_clarification'] as bool? ?? false,
      safeForLearning: json['safe_for_learning'] as bool? ?? false,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        intent,
        normalizedText,
        requestArtifact,
        learningArtifact,
        vibeEvidence,
        privacySensitivity,
        confidence,
        ambiguityFlags,
        needsClarification,
        safeForLearning,
        schemaVersion,
      ];
}
