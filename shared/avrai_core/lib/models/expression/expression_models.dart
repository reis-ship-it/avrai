import 'package:equatable/equatable.dart';

import 'package:avrai_core/models/vibe/vibe_models.dart';

enum ExpressionSpeechAct {
  recommend,
  explain,
  clarify,
  ask,
  decline,
  reassure,
  confirm,
  warn;

  String toWireValue() => switch (this) {
        ExpressionSpeechAct.recommend => 'recommend',
        ExpressionSpeechAct.explain => 'explain',
        ExpressionSpeechAct.clarify => 'clarify',
        ExpressionSpeechAct.ask => 'ask',
        ExpressionSpeechAct.decline => 'decline',
        ExpressionSpeechAct.reassure => 'reassure',
        ExpressionSpeechAct.confirm => 'confirm',
        ExpressionSpeechAct.warn => 'warn',
      };

  static ExpressionSpeechAct fromWireValue(String? value) => switch (value) {
        'recommend' => ExpressionSpeechAct.recommend,
        'clarify' => ExpressionSpeechAct.clarify,
        'ask' => ExpressionSpeechAct.ask,
        'decline' => ExpressionSpeechAct.decline,
        'reassure' => ExpressionSpeechAct.reassure,
        'confirm' => ExpressionSpeechAct.confirm,
        'warn' => ExpressionSpeechAct.warn,
        _ => ExpressionSpeechAct.explain,
      };
}

enum ExpressionAudience {
  userSafe,
  agent,
  admin,
  governance;

  String toWireValue() => switch (this) {
        ExpressionAudience.userSafe => 'user_safe',
        ExpressionAudience.agent => 'agent',
        ExpressionAudience.admin => 'admin',
        ExpressionAudience.governance => 'governance',
      };

  static ExpressionAudience fromWireValue(String? value) => switch (value) {
        'agent' => ExpressionAudience.agent,
        'admin' => ExpressionAudience.admin,
        'governance' => ExpressionAudience.governance,
        _ => ExpressionAudience.userSafe,
      };
}

enum ExpressionSurfaceShape {
  card,
  chatTurn,
  banner,
  settingsExplainer,
  modal,
  receipt,
  emptyState,
  errorState;

  String toWireValue() => switch (this) {
        ExpressionSurfaceShape.card => 'card',
        ExpressionSurfaceShape.chatTurn => 'chat_turn',
        ExpressionSurfaceShape.banner => 'banner',
        ExpressionSurfaceShape.settingsExplainer => 'settings_explainer',
        ExpressionSurfaceShape.modal => 'modal',
        ExpressionSurfaceShape.receipt => 'receipt',
        ExpressionSurfaceShape.emptyState => 'empty_state',
        ExpressionSurfaceShape.errorState => 'error_state',
      };

  static ExpressionSurfaceShape fromWireValue(String? value) => switch (value) {
        'chat_turn' => ExpressionSurfaceShape.chatTurn,
        'banner' => ExpressionSurfaceShape.banner,
        'settings_explainer' => ExpressionSurfaceShape.settingsExplainer,
        'modal' => ExpressionSurfaceShape.modal,
        'receipt' => ExpressionSurfaceShape.receipt,
        'empty_state' => ExpressionSurfaceShape.emptyState,
        'error_state' => ExpressionSurfaceShape.errorState,
        _ => ExpressionSurfaceShape.card,
      };
}

class ExpressionSection extends Equatable {
  const ExpressionSection({
    required this.kind,
    required this.text,
  });

  final String kind;
  final String text;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind,
        'text': text,
      };

  factory ExpressionSection.fromJson(Map<String, dynamic> json) {
    return ExpressionSection(
      kind: json['kind'] as String? ?? 'body',
      text: json['text'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[kind, text];
}

class ExpressionPlan extends Equatable {
  const ExpressionPlan({
    required this.speechAct,
    required this.audience,
    required this.surfaceShape,
    required this.allowedClaims,
    required this.forbiddenClaims,
    required this.evidenceRefs,
    required this.confidenceBand,
    required this.toneProfile,
    required this.sections,
    required this.fallbackText,
    this.vibeContext,
    this.uncertaintyNotice,
    this.cta,
    this.adaptationProfileRef,
    this.schemaVersion = 1,
  });

  final ExpressionSpeechAct speechAct;
  final ExpressionAudience audience;
  final ExpressionSurfaceShape surfaceShape;
  final List<String> allowedClaims;
  final List<String> forbiddenClaims;
  final List<String> evidenceRefs;
  final String confidenceBand;
  final String toneProfile;
  final VibeExpressionContext? vibeContext;
  final String? uncertaintyNotice;
  final List<ExpressionSection> sections;
  final String? cta;
  final String fallbackText;
  final String? adaptationProfileRef;
  final int schemaVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'speech_act': speechAct.toWireValue(),
        'audience': audience.toWireValue(),
        'surface_shape': surfaceShape.toWireValue(),
        'allowed_claims': allowedClaims,
        'forbidden_claims': forbiddenClaims,
        'evidence_refs': evidenceRefs,
        'confidence_band': confidenceBand,
        'tone_profile': toneProfile,
        if (vibeContext != null) 'vibe_context': vibeContext!.toJson(),
        if (uncertaintyNotice != null) 'uncertainty_notice': uncertaintyNotice,
        'sections': sections.map((entry) => entry.toJson()).toList(),
        if (cta != null) 'cta': cta,
        'fallback_text': fallbackText,
        if (adaptationProfileRef != null)
          'adaptation_profile_ref': adaptationProfileRef,
        'schema_version': schemaVersion,
      };

  factory ExpressionPlan.fromJson(Map<String, dynamic> json) {
    return ExpressionPlan(
      speechAct:
          ExpressionSpeechAct.fromWireValue(json['speech_act'] as String?),
      audience: ExpressionAudience.fromWireValue(json['audience'] as String?),
      surfaceShape: ExpressionSurfaceShape.fromWireValue(
        json['surface_shape'] as String?,
      ),
      allowedClaims: ((json['allowed_claims'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      forbiddenClaims:
          ((json['forbidden_claims'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      evidenceRefs: ((json['evidence_refs'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      confidenceBand: json['confidence_band'] as String? ?? 'medium',
      toneProfile: json['tone_profile'] as String? ?? 'clear_calm',
      vibeContext: json['vibe_context'] is Map
          ? VibeExpressionContext.fromJson(
              Map<String, dynamic>.from(json['vibe_context'] as Map),
            )
          : null,
      uncertaintyNotice: json['uncertainty_notice'] as String?,
      sections: ((json['sections'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ExpressionSection.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      cta: json['cta'] as String?,
      fallbackText: json['fallback_text'] as String? ??
          'I can only express what AVRAI has grounded right now.',
      adaptationProfileRef: json['adaptation_profile_ref'] as String?,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        speechAct,
        audience,
        surfaceShape,
        allowedClaims,
        forbiddenClaims,
        evidenceRefs,
        confidenceBand,
        toneProfile,
        vibeContext,
        uncertaintyNotice,
        sections,
        cta,
        fallbackText,
        adaptationProfileRef,
        schemaVersion,
      ];
}

class RenderedExpression extends Equatable {
  const RenderedExpression({
    required this.text,
    required this.sections,
    required this.assertedClaims,
  });

  final String text;
  final List<ExpressionSection> sections;
  final List<String> assertedClaims;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'sections': sections.map((entry) => entry.toJson()).toList(),
        'asserted_claims': assertedClaims,
      };

  factory RenderedExpression.fromJson(Map<String, dynamic> json) {
    return RenderedExpression(
      text: json['text'] as String? ?? '',
      sections: ((json['sections'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => ExpressionSection.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      assertedClaims: ((json['asserted_claims'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => <Object?>[text, sections, assertedClaims];
}

class ExpressionValidationResult extends Equatable {
  const ExpressionValidationResult({
    required this.valid,
    required this.unsupportedClaims,
    required this.forbiddenHits,
    required this.fallbackRequired,
  });

  final bool valid;
  final List<String> unsupportedClaims;
  final List<String> forbiddenHits;
  final bool fallbackRequired;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'valid': valid,
        'unsupported_claims': unsupportedClaims,
        'forbidden_hits': forbiddenHits,
        'fallback_required': fallbackRequired,
      };

  factory ExpressionValidationResult.fromJson(Map<String, dynamic> json) {
    return ExpressionValidationResult(
      valid: json['valid'] as bool? ?? false,
      unsupportedClaims:
          ((json['unsupported_claims'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      forbiddenHits: ((json['forbidden_hits'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      fallbackRequired: json['fallback_required'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        valid,
        unsupportedClaims,
        forbiddenHits,
        fallbackRequired,
      ];
}
