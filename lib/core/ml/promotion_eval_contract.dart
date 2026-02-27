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

class PromotionEvalManifestContract {
  const PromotionEvalManifestContract._();

  static const String manifestVersion = 'v1';
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
}
