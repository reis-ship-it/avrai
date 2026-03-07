import 'package:equatable/equatable.dart';

abstract class LocalityTrainingContract {
  Future<LocalityTrainingArtifact> loadBaselineArtifact({
    required String cityProfile,
    required String modelFamily,
  });

  Future<LocalitySimulationBatch> buildBootstrapBatch({
    required String cityProfile,
    int localityCount = 12,
  });

  Future<LocalityZeroReliabilityReport> evaluateZeroLocality({
    required LocalityTrainingArtifact artifact,
    required LocalitySimulationBatch batch,
  });
}

class LocalityTrainingArtifact extends Equatable {
  final String artifactId;
  final String version;
  final Map<String, dynamic> calibration;

  const LocalityTrainingArtifact({
    required this.artifactId,
    required this.version,
    this.calibration = const <String, dynamic>{},
  });

  @override
  List<Object?> get props => [artifactId, version, calibration];
}

class LocalitySimulationScenario extends Equatable {
  final String scenarioId;
  final String cityProfile;
  final int localityCount;
  final bool fuzzyBoundaries;

  const LocalitySimulationScenario({
    required this.scenarioId,
    required this.cityProfile,
    required this.localityCount,
    this.fuzzyBoundaries = true,
  });

  @override
  List<Object?> get props => [
        scenarioId,
        cityProfile,
        localityCount,
        fuzzyBoundaries,
      ];
}

class LocalitySimulationBatch extends Equatable {
  final String batchId;
  final List<LocalitySimulationScenario> scenarios;

  const LocalitySimulationBatch({
    required this.batchId,
    required this.scenarios,
  });

  @override
  List<Object?> get props => [batchId, scenarios];
}

class LocalityEvaluationMetric extends Equatable {
  final String name;
  final double value;
  final double target;

  const LocalityEvaluationMetric({
    required this.name,
    required this.value,
    required this.target,
  });

  bool get passes => value >= target;

  @override
  List<Object?> get props => [name, value, target];
}

class LocalityZeroReliabilityReport extends Equatable {
  final String evaluationId;
  final List<LocalityEvaluationMetric> metrics;
  final Map<String, dynamic> calibration;

  const LocalityZeroReliabilityReport({
    required this.evaluationId,
    required this.metrics,
    this.calibration = const <String, dynamic>{},
  });

  bool get passes => metrics.every((metric) => metric.passes);

  @override
  List<Object?> get props => [evaluationId, metrics, calibration];
}
