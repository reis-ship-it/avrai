import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';

bool hasCanonicalVibeSignal(
  VibeStateSnapshot snapshot, {
  double epsilon = 0.000001,
}) {
  if (snapshot.provenanceTags.isNotEmpty) {
    return true;
  }
  if (snapshot.behaviorPatterns.observationCount > 0) {
    return true;
  }
  if (snapshot.pheromones.vectors.values.any((value) => value.abs() > epsilon)) {
    return true;
  }
  for (final dimension in VibeConstants.coreDimensions) {
    final value = snapshot.coreDna.dimensions[dimension];
    if (value != null &&
        (value - VibeConstants.defaultDimensionValue).abs() > epsilon) {
      return true;
    }
  }
  return false;
}
