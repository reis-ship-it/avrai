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
      metadata['dominantSource'] = _dominantSource(state.sourceMix);
      metadata['sourceMixSummary'] = _sourceMixSummary(state.sourceMix);
      metadata['stabilityClass'] = _stabilityClass(state);
      metadata['nextStateRisk'] = _nextStateRisk(state);
      metadata['promotionReadiness'] = _promotionReadiness(state);
      metadata['explanatoryFactors'] = _explanatoryFactors(state);
    }
    if (request.includePrediction) {
      metadata['predictiveTrend'] = _predictiveTrend(state);
    }

    return LocalityProjection(
      primaryLabel: primaryLabel,
      confidenceBucket: confidenceBucket,
      nearBoundary: state.boundaryTension >= 0.5,
      activeToken: state.activeToken,
      metadata: metadata,
    );
  }

  String _dominantSource(LocalitySourceMix sourceMix) {
    final weights = <String, double>{
      'local': sourceMix.local,
      'mesh': sourceMix.mesh,
      'federated': sourceMix.federated,
      'geometry': sourceMix.geometry,
      'syntheticPrior': sourceMix.syntheticPrior,
    };
    return weights.entries
        .reduce((left, right) => left.value >= right.value ? left : right)
        .key;
  }

  String _sourceMixSummary(LocalitySourceMix sourceMix) {
    return switch (_dominantSource(sourceMix)) {
      'local' => 'localLed',
      'mesh' => 'meshLed',
      'federated' => 'federatedLed',
      'geometry' => 'geometryAnchored',
      _ => 'syntheticBootstrap',
    };
  }

  String _stabilityClass(LocalityState state) {
    if (state.advisoryStatus == LocalityAdvisoryStatus.active) {
      return 'advisory';
    }
    if (state.boundaryTension >= 0.72) {
      return 'boundaryVolatile';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate &&
        state.evolutionRate >= 0.08) {
      return 'emergent';
    }
    if (state.evolutionRate >= 0.12) {
      return 'accelerating';
    }
    if (state.confidence >= 0.75 && state.evolutionRate < 0.08) {
      return 'stable';
    }
    return 'watch';
  }

  String _predictiveTrend(LocalityState state) {
    if (state.advisoryStatus == LocalityAdvisoryStatus.active) {
      return 'advisoryRecovery';
    }
    if (state.boundaryTension >= 0.72) {
      return 'boundaryVolatile';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate &&
        state.evidenceCount >= 5) {
      return 'emerging';
    }
    if (state.evolutionRate >= 0.12) {
      return 'accelerating';
    }
    if (state.evolutionRate >= 0.08) {
      return 'changing';
    }
    return 'stable';
  }

  String _nextStateRisk(LocalityState state) {
    var score = 0;
    if (state.confidence < 0.45) {
      score += 2;
    } else if (state.confidence < 0.65) {
      score += 1;
    }
    if (state.boundaryTension >= 0.72) {
      score += 2;
    } else if (state.boundaryTension >= 0.5) {
      score += 1;
    }
    if (state.evolutionRate >= 0.12) {
      score += 2;
    } else if (state.evolutionRate >= 0.08) {
      score += 1;
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate ||
        state.reliabilityTier == LocalityReliabilityTier.bootstrap) {
      score += 1;
    }
    if (state.advisoryStatus == LocalityAdvisoryStatus.active) {
      score += 2;
    }

    if (score >= 5) {
      return 'high';
    }
    if (score >= 3) {
      return 'medium';
    }
    return 'low';
  }

  String _promotionReadiness(LocalityState state) {
    if (state.advisoryStatus == LocalityAdvisoryStatus.active) {
      return 'advisory';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.established) {
      return 'established';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate &&
        state.evidenceCount >= 6) {
      return 'promotable';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate) {
      return 'emerging';
    }
    if (state.reliabilityTier == LocalityReliabilityTier.bootstrap) {
      return 'bootstrapping';
    }
    return 'unseeded';
  }

  List<String> _explanatoryFactors(LocalityState state) {
    final factors = <String>[];
    if (state.confidence >= 0.75) {
      factors.add('highConfidence');
    } else if (state.confidence < 0.4) {
      factors.add('lowConfidence');
    }
    if (state.boundaryTension >= 0.5) {
      factors.add('boundaryTension');
    }
    if (state.evolutionRate >= 0.08) {
      factors.add('fastEvolution');
    }
    if (state.reliabilityTier == LocalityReliabilityTier.candidate &&
        state.evidenceCount >= 5) {
      factors.add('candidateEvidence');
    }
    if (state.advisoryStatus == LocalityAdvisoryStatus.active) {
      factors.add('activeAdvisory');
    }
    factors.add('source:${_dominantSource(state.sourceMix)}');
    if (factors.isEmpty) {
      factors.add('limitedSignal');
    }
    return factors;
  }
}
