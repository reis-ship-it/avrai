import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';

class SignatureMatchService {
  static const double minConfidenceThreshold = 0.6;
  static const double minFreshnessThreshold = 0.45;

  const SignatureMatchService();

  SignatureMatchResult match({
    required EntitySignature userSignature,
    required EntitySignature entitySignature,
    required double fallbackScore,
    double dnaWeight = 0.65,
    double pheromoneWeight = 0.35,
  }) {
    final dnaScore =
        SignatureDimensions.similarity(userSignature.dna, entitySignature.dna);
    final pheromoneScore = SignatureDimensions.similarity(
      userSignature.pheromones,
      entitySignature.pheromones,
    );
    final signatureScore =
        ((dnaScore * dnaWeight) + (pheromoneScore * pheromoneWeight))
            .clamp(0.0, 1.0);
    final confidence = userSignature.confidence < entitySignature.confidence
        ? userSignature.confidence
        : entitySignature.confidence;
    final freshness = userSignature.freshness < entitySignature.freshness
        ? userSignature.freshness
        : entitySignature.freshness;
    final useSignature = confidence >= minConfidenceThreshold &&
        freshness >= minFreshnessThreshold;

    return SignatureMatchResult(
      entityId: entitySignature.entityId,
      entityKind: entitySignature.entityKind,
      dnaScore: dnaScore,
      pheromoneScore: pheromoneScore,
      signatureScore: signatureScore,
      finalScore: useSignature ? signatureScore : fallbackScore,
      fallbackScore: fallbackScore,
      confidence: confidence,
      freshness: freshness,
      mode: useSignature
          ? SignatureScoreMode.signaturePrimary
          : SignatureScoreMode.fallback,
      summary: useSignature
          ? 'DNA ${(dnaScore * 100).toStringAsFixed(0)}%, live pull ${(pheromoneScore * 100).toStringAsFixed(0)}%.'
          : 'Fallback used because signature confidence or freshness was too weak.',
    );
  }
}
