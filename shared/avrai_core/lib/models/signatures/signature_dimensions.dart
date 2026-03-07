import 'package:avrai_core/utils/vibe_constants.dart';

/// Shared helpers for working with normalized signature vectors.
abstract final class SignatureDimensions {
  static List<String> get coreDimensions => VibeConstants.coreDimensions;

  static Map<String, double> normalize(Map<String, double> raw) {
    final normalized = <String, double>{};
    for (final dimension in coreDimensions) {
      normalized[dimension] =
          (raw[dimension] ?? VibeConstants.defaultDimensionValue)
              .clamp(0.0, 1.0);
    }
    return normalized;
  }

  static Map<String, double> weightedBlend(
    List<Map<String, double>> vectors, {
    List<double>? weights,
  }) {
    if (vectors.isEmpty) {
      return normalize(const <String, double>{});
    }

    final resolvedWeights = weights == null || weights.length != vectors.length
        ? List<double>.filled(vectors.length, 1.0)
        : weights;
    final totalWeight = resolvedWeights.fold<double>(0.0, (sum, w) => sum + w);
    if (totalWeight <= 0) {
      return normalize(const <String, double>{});
    }

    final blended = <String, double>{};
    for (final dimension in coreDimensions) {
      var value = 0.0;
      for (var index = 0; index < vectors.length; index++) {
        final normalized = normalize(vectors[index]);
        value +=
            (normalized[dimension] ?? VibeConstants.defaultDimensionValue) *
                resolvedWeights[index];
      }
      blended[dimension] = (value / totalWeight).clamp(0.0, 1.0);
    }
    return blended;
  }

  static double similarity(
    Map<String, double> left,
    Map<String, double> right,
  ) {
    final normalizedLeft = normalize(left);
    final normalizedRight = normalize(right);
    var total = 0.0;
    for (final dimension in coreDimensions) {
      total += 1.0 -
          ((normalizedLeft[dimension] ?? 0.5) -
                  (normalizedRight[dimension] ?? 0.5))
              .abs();
    }
    return (total / coreDimensions.length).clamp(0.0, 1.0);
  }

  static double average(Iterable<double> values, {double defaultValue = 0.5}) {
    if (values.isEmpty) {
      return defaultValue;
    }
    final list = values.toList();
    return (list.fold<double>(0.0, (sum, value) => sum + value) / list.length)
        .clamp(0.0, 1.0);
  }

  static Map<String, double> nudge(
    Map<String, double> base,
    Map<String, double> nudges,
  ) {
    final normalized = normalize(base);
    final next = <String, double>{...normalized};
    for (final entry in nudges.entries) {
      next[entry.key] =
          ((next[entry.key] ?? 0.5) + entry.value).clamp(0.0, 1.0);
    }
    return normalize(next);
  }
}
