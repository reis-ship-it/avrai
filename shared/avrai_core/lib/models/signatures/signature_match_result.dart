import 'package:equatable/equatable.dart';

import 'entity_signature.dart';

enum SignatureScoreMode {
  signaturePrimary,
  fallback,
}

class SignatureMatchResult extends Equatable {
  final String entityId;
  final SignatureEntityKind entityKind;
  final double dnaScore;
  final double pheromoneScore;
  final double signatureScore;
  final double finalScore;
  final double fallbackScore;
  final double confidence;
  final double freshness;
  final SignatureScoreMode mode;
  final String summary;

  const SignatureMatchResult({
    required this.entityId,
    required this.entityKind,
    required this.dnaScore,
    required this.pheromoneScore,
    required this.signatureScore,
    required this.finalScore,
    required this.fallbackScore,
    required this.confidence,
    required this.freshness,
    required this.mode,
    required this.summary,
  });

  bool get usedSignaturePrimary => mode == SignatureScoreMode.signaturePrimary;
  bool get usedFallback => mode == SignatureScoreMode.fallback;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entityId': entityId,
      'entityKind': entityKind.name,
      'dnaScore': dnaScore,
      'pheromoneScore': pheromoneScore,
      'signatureScore': signatureScore,
      'finalScore': finalScore,
      'fallbackScore': fallbackScore,
      'confidence': confidence,
      'freshness': freshness,
      'mode': mode.name,
      'summary': summary,
    };
  }

  factory SignatureMatchResult.fromJson(Map<String, dynamic> json) {
    return SignatureMatchResult(
      entityId: json['entityId'] as String? ?? '',
      entityKind: SignatureEntityKind.values.firstWhere(
        (value) => value.name == json['entityKind'],
        orElse: () => SignatureEntityKind.bundle,
      ),
      dnaScore: (json['dnaScore'] as num?)?.toDouble() ?? 0.5,
      pheromoneScore: (json['pheromoneScore'] as num?)?.toDouble() ?? 0.5,
      signatureScore: (json['signatureScore'] as num?)?.toDouble() ?? 0.5,
      finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0.5,
      fallbackScore: (json['fallbackScore'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      freshness: (json['freshness'] as num?)?.toDouble() ?? 0.5,
      mode: SignatureScoreMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => SignatureScoreMode.fallback,
      ),
      summary: json['summary'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        entityId,
        entityKind,
        dnaScore,
        pheromoneScore,
        signatureScore,
        finalScore,
        fallbackScore,
        confidence,
        freshness,
        mode,
        summary,
      ];
}
