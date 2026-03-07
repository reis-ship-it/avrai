import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';

class SyntheticLocalityTrainingService implements LocalityTrainingContract {
  const SyntheticLocalityTrainingService();

  @override
  Future<LocalityTrainingArtifact> loadBaselineArtifact({
    required String cityProfile,
    required String modelFamily,
  }) async {
    return LocalityTrainingArtifact(
      artifactId: 'locality-$modelFamily-$cityProfile-v1',
      version: '1.0.0',
      calibration: <String, dynamic>{
        'cityProfile': cityProfile,
        'modelFamily': modelFamily,
        'candidatePromotionThreshold': 8,
        'advisoryActivationThreshold': 0.45,
        'bootstrapConfidenceFloor': 0.35,
        'zeroLocalityFallback': 'synthetic_bootstrap',
      },
    );
  }

  @override
  Future<LocalitySimulationBatch> buildBootstrapBatch({
    required String cityProfile,
    int localityCount = 12,
  }) async {
    final scenarios = <LocalitySimulationScenario>[
      LocalitySimulationScenario(
        scenarioId: '$cityProfile-zero-locality',
        cityProfile: cityProfile,
        localityCount: localityCount,
      ),
      LocalitySimulationScenario(
        scenarioId: '$cityProfile-boundary-tension',
        cityProfile: cityProfile,
        localityCount: localityCount,
        fuzzyBoundaries: true,
      ),
      LocalitySimulationScenario(
        scenarioId: '$cityProfile-mesh-only',
        cityProfile: cityProfile,
        localityCount: localityCount ~/ 2,
      ),
      LocalitySimulationScenario(
        scenarioId: '$cityProfile-federated-refresh',
        cityProfile: cityProfile,
        localityCount: localityCount,
      ),
      LocalitySimulationScenario(
        scenarioId: '$cityProfile-advisory-recovery',
        cityProfile: cityProfile,
        localityCount: localityCount ~/ 3,
      ),
    ];

    return LocalitySimulationBatch(
      batchId: 'bootstrap-$cityProfile-v1',
      scenarios: scenarios,
    );
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocality({
    required LocalityTrainingArtifact artifact,
    required LocalitySimulationBatch batch,
  }) async {
    final scenarioCount = batch.scenarios.length;
    final localityMass = batch.scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.localityCount,
    );
    final normalization = localityMass <= 0 ? 1 : localityMass;

    final metrics = <LocalityEvaluationMetric>[
      LocalityEvaluationMetric(
        name: 'cold_start_plausibility',
        value: (0.72 + (scenarioCount * 0.015)).clamp(0.0, 0.92),
        target: 0.7,
      ),
      LocalityEvaluationMetric(
        name: 'confidence_calibration',
        value: (0.74 + (normalization / 400)).clamp(0.0, 0.9),
        target: 0.72,
      ),
      LocalityEvaluationMetric(
        name: 'boundary_case_stability',
        value: batch.scenarios.any((scenario) => scenario.fuzzyBoundaries)
            ? 0.78
            : 0.68,
        target: 0.7,
      ),
      const LocalityEvaluationMetric(
        name: 'candidate_promotion_precision',
        value: 0.76,
        target: 0.74,
      ),
      const LocalityEvaluationMetric(
        name: 'advisory_recovery_quality',
        value: 0.73,
        target: 0.7,
      ),
    ];

    return LocalityZeroReliabilityReport(
      evaluationId: '${artifact.artifactId}:${batch.batchId}',
      metrics: metrics,
      calibration: <String, dynamic>{
        ...artifact.calibration,
        'scenarioCount': scenarioCount,
        'localityMass': localityMass,
      },
    );
  }
}
