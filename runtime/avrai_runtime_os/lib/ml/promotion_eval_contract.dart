// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:equatable/equatable.dart';

enum MandatoryEvalSuite {
  offlineReplay,
  adversarialRobustness,
  contradictionStress,
}

extension MandatoryEvalSuiteManifestCodec on MandatoryEvalSuite {
  String get manifestName {
    switch (this) {
      case MandatoryEvalSuite.offlineReplay:
        return 'offline_replay';
      case MandatoryEvalSuite.adversarialRobustness:
        return 'adversarial_robustness';
      case MandatoryEvalSuite.contradictionStress:
        return 'contradiction_stress';
    }
  }

  static MandatoryEvalSuite? fromManifestName(String name) {
    switch (name.trim()) {
      case 'offline_replay':
        return MandatoryEvalSuite.offlineReplay;
      case 'adversarial_robustness':
        return MandatoryEvalSuite.adversarialRobustness;
      case 'contradiction_stress':
        return MandatoryEvalSuite.contradictionStress;
      default:
        return null;
    }
  }
}

enum CompressionRegressionSuite {
  rankingDrift,
  calibrationDrift,
  contradictionDetectionDegradation,
  uncertaintyHonestyRegression,
}

extension CompressionRegressionSuiteManifestCodec
    on CompressionRegressionSuite {
  String get manifestName {
    switch (this) {
      case CompressionRegressionSuite.rankingDrift:
        return 'ranking_drift';
      case CompressionRegressionSuite.calibrationDrift:
        return 'calibration_drift';
      case CompressionRegressionSuite.contradictionDetectionDegradation:
        return 'contradiction_detection_degradation';
      case CompressionRegressionSuite.uncertaintyHonestyRegression:
        return 'uncertainty_honesty_regression';
    }
  }

  static CompressionRegressionSuite? fromManifestName(String name) {
    switch (name.trim()) {
      case 'ranking_drift':
        return CompressionRegressionSuite.rankingDrift;
      case 'calibration_drift':
        return CompressionRegressionSuite.calibrationDrift;
      case 'contradiction_detection_degradation':
        return CompressionRegressionSuite.contradictionDetectionDegradation;
      case 'uncertainty_honesty_regression':
        return CompressionRegressionSuite.uncertaintyHonestyRegression;
      default:
        return null;
    }
  }
}

class EvalSuiteResult extends Equatable {
  const EvalSuiteResult({
    required this.suite,
    required this.passed,
    required this.artifactPath,
  });

  final MandatoryEvalSuite suite;
  final bool passed;
  final String artifactPath;

  @override
  List<Object?> get props => [suite, passed, artifactPath];
}

class CompressionRegressionSuiteResult extends Equatable {
  const CompressionRegressionSuiteResult({
    required this.suite,
    required this.passed,
    required this.artifactPath,
    required this.observedRegression,
    required this.maxAllowedRegression,
  });

  final CompressionRegressionSuite suite;
  final bool passed;
  final String artifactPath;
  final double observedRegression;
  final double maxAllowedRegression;

  bool get withinBudget =>
      observedRegression >= 0 &&
      maxAllowedRegression >= 0 &&
      observedRegression <= maxAllowedRegression;

  @override
  List<Object?> get props => [
        suite,
        passed,
        artifactPath,
        observedRegression,
        maxAllowedRegression,
      ];
}

class PromotionEvalValidationResult extends Equatable {
  const PromotionEvalValidationResult({
    required this.isEligible,
    required this.missingSuites,
    required this.failedSuites,
    required this.reasonCode,
  });

  final bool isEligible;
  final List<MandatoryEvalSuite> missingSuites;
  final List<MandatoryEvalSuite> failedSuites;
  final String reasonCode;

  @override
  List<Object?> get props =>
      [isEligible, missingSuites, failedSuites, reasonCode];
}

class CompressionRegressionValidationResult extends Equatable {
  const CompressionRegressionValidationResult({
    required this.isEligible,
    required this.missingSuites,
    required this.failedSuites,
    required this.budgetExceededSuites,
    required this.reasonCode,
  });

  final bool isEligible;
  final List<CompressionRegressionSuite> missingSuites;
  final List<CompressionRegressionSuite> failedSuites;
  final List<CompressionRegressionSuite> budgetExceededSuites;
  final String reasonCode;

  @override
  List<Object?> get props => [
        isEligible,
        missingSuites,
        failedSuites,
        budgetExceededSuites,
        reasonCode,
      ];
}

class PromotionEvalGate {
  const PromotionEvalGate();

  static const List<MandatoryEvalSuite> requiredSuites = <MandatoryEvalSuite>[
    MandatoryEvalSuite.offlineReplay,
    MandatoryEvalSuite.adversarialRobustness,
    MandatoryEvalSuite.contradictionStress,
  ];

  PromotionEvalValidationResult validate(List<EvalSuiteResult> results) {
    final bySuite = <MandatoryEvalSuite, EvalSuiteResult>{
      for (final r in results) r.suite: r,
    };

    final missing = <MandatoryEvalSuite>[];
    final failed = <MandatoryEvalSuite>[];

    for (final suite in requiredSuites) {
      final result = bySuite[suite];
      if (result == null) {
        missing.add(suite);
        continue;
      }

      if (!result.passed || result.artifactPath.trim().isEmpty) {
        failed.add(suite);
      }
    }

    if (missing.isNotEmpty) {
      return PromotionEvalValidationResult(
        isEligible: false,
        missingSuites: missing,
        failedSuites: failed,
        reasonCode: 'missing_required_suites',
      );
    }

    if (failed.isNotEmpty) {
      return PromotionEvalValidationResult(
        isEligible: false,
        missingSuites: const <MandatoryEvalSuite>[],
        failedSuites: failed,
        reasonCode: 'failed_or_unattested_required_suites',
      );
    }

    return const PromotionEvalValidationResult(
      isEligible: true,
      missingSuites: <MandatoryEvalSuite>[],
      failedSuites: <MandatoryEvalSuite>[],
      reasonCode: 'eligible',
    );
  }
}

class CompressionRegressionGate {
  const CompressionRegressionGate();

  static const String compressedRealityModelProfile =
      'compressed_reality_model_v1';
  static const List<CompressionRegressionSuite> requiredSuites =
      <CompressionRegressionSuite>[
    CompressionRegressionSuite.rankingDrift,
    CompressionRegressionSuite.calibrationDrift,
    CompressionRegressionSuite.contradictionDetectionDegradation,
    CompressionRegressionSuite.uncertaintyHonestyRegression,
  ];

  CompressionRegressionValidationResult validate(
    List<CompressionRegressionSuiteResult> results,
  ) {
    final bySuite =
        <CompressionRegressionSuite, CompressionRegressionSuiteResult>{
      for (final r in results) r.suite: r,
    };

    final missing = <CompressionRegressionSuite>[];
    final failed = <CompressionRegressionSuite>[];
    final budgetExceeded = <CompressionRegressionSuite>[];

    for (final suite in requiredSuites) {
      final result = bySuite[suite];
      if (result == null) {
        missing.add(suite);
        continue;
      }

      if (!result.passed || result.artifactPath.trim().isEmpty) {
        failed.add(suite);
      }

      if (!result.withinBudget) {
        budgetExceeded.add(suite);
      }
    }

    if (missing.isNotEmpty) {
      return CompressionRegressionValidationResult(
        isEligible: false,
        missingSuites: missing,
        failedSuites: failed,
        budgetExceededSuites: budgetExceeded,
        reasonCode: 'missing_required_compression_suites',
      );
    }

    if (failed.isNotEmpty || budgetExceeded.isNotEmpty) {
      return CompressionRegressionValidationResult(
        isEligible: false,
        missingSuites: const <CompressionRegressionSuite>[],
        failedSuites: failed,
        budgetExceededSuites: budgetExceeded,
        reasonCode: 'failed_or_budget_exceeded_required_compression_suites',
      );
    }

    return const CompressionRegressionValidationResult(
      isEligible: true,
      missingSuites: <CompressionRegressionSuite>[],
      failedSuites: <CompressionRegressionSuite>[],
      budgetExceededSuites: <CompressionRegressionSuite>[],
      reasonCode: 'eligible',
    );
  }
}

class PromotionEvalManifestContract {
  const PromotionEvalManifestContract._();

  static const String manifestVersion = 'v2';
  static const String decisionApprove = 'approve';
  static const String decisionHold = 'hold';
  static const String decisionReject = 'reject';
  static const Set<String> allowedDecisions = <String>{
    decisionApprove,
    decisionHold,
    decisionReject,
  };

  static List<String> requiredSuiteManifestNames() {
    return PromotionEvalGate.requiredSuites
        .map((suite) => suite.manifestName)
        .toList(growable: false);
  }

  static List<String> requiredCompressionSuiteManifestNames() {
    return CompressionRegressionGate.requiredSuites
        .map((suite) => suite.manifestName)
        .toList(growable: false);
  }
}
