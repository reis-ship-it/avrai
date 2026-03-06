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

  Map<String, dynamic> toJson() => {
        'artifactId': artifactId,
        'version': version,
        'calibration': calibration,
      };

  factory LocalityTrainingArtifact.fromJson(Map<String, dynamic> json) {
    return LocalityTrainingArtifact(
      artifactId: (json['artifactId'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      calibration: Map<String, dynamic>.from(
        json['calibration'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

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

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'cityProfile': cityProfile,
        'localityCount': localityCount,
        'fuzzyBoundaries': fuzzyBoundaries,
      };

  factory LocalitySimulationScenario.fromJson(Map<String, dynamic> json) {
    return LocalitySimulationScenario(
      scenarioId: (json['scenarioId'] as String?) ?? '',
      cityProfile: (json['cityProfile'] as String?) ?? '',
      localityCount: (json['localityCount'] as num?)?.toInt() ?? 0,
      fuzzyBoundaries: json['fuzzyBoundaries'] as bool? ?? true,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
      };

  factory LocalitySimulationBatch.fromJson(Map<String, dynamic> json) {
    final scenarios = (json['scenarios'] as List?)
            ?.map(
              (entry) => LocalitySimulationScenario.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList() ??
        const <LocalitySimulationScenario>[];
    return LocalitySimulationBatch(
      batchId: (json['batchId'] as String?) ?? '',
      scenarios: scenarios,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'target': target,
      };

  factory LocalityEvaluationMetric.fromJson(Map<String, dynamic> json) {
    return LocalityEvaluationMetric(
      name: (json['name'] as String?) ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'evaluationId': evaluationId,
        'metrics': metrics.map((metric) => metric.toJson()).toList(),
        'calibration': calibration,
      };

  factory LocalityZeroReliabilityReport.fromJson(Map<String, dynamic> json) {
    final metrics = (json['metrics'] as List?)
            ?.map(
              (entry) => LocalityEvaluationMetric.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList() ??
        const <LocalityEvaluationMetric>[];
    return LocalityZeroReliabilityReport(
      evaluationId: (json['evaluationId'] as String?) ?? '',
      metrics: metrics,
      calibration: Map<String, dynamic>.from(
        json['calibration'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => [evaluationId, metrics, calibration];
}
