import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';

class LocalityProjectionService {
  LocalityProjection project(LocalityProjectionRequest request) {
    final state = request.state;
    final primaryLabel =
        state.topAlias ?? state.activeToken.alias ?? state.activeToken.id;
    final confidenceBucket = switch (state.confidence) {
      >= 0.75 => 'high',
      >= 0.4 => 'medium',
      _ => 'low',
    };

    final metadata = <String, dynamic>{};
    if (request.audience != LocalityProjectionAudience.user) {
      metadata['confidence'] = state.confidence;
      metadata['boundaryTension'] = state.boundaryTension;
      metadata['sourceMix'] = state.sourceMix.toJson();
      metadata['evolutionRate'] = state.evolutionRate;
      metadata['reliabilityTier'] = state.reliabilityTier.name;
      metadata['advisoryStatus'] = state.advisoryStatus.name;
    }
    if (request.includePrediction) {
      metadata['predictiveTrend'] =
          state.evolutionRate > 0.08 ? 'changing' : 'stable';
    }

    return LocalityProjection(
      primaryLabel: primaryLabel,
      confidenceBucket: confidenceBucket,
      nearBoundary: state.boundaryTension >= 0.5,
      activeToken: state.activeToken,
      metadata: metadata,
    );
  }
}
