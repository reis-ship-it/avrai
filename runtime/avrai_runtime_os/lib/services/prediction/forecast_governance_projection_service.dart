import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_ensemble_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_regime_shift_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_resolution_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

enum ForecastGovernanceDisposition {
  admitted,
  admittedWithCaution,
  downgraded,
  blocked,
}

class ForecastGovernanceProjection {
  const ForecastGovernanceProjection({
    required this.result,
    required this.trace,
    required this.disposition,
    required this.recordedAt,
    required this.replayYearScore,
    required this.actionabilityScore,
    required this.contradictionStress,
    required this.governanceReasons,
  });

  final ForecastKernelResult result;
  final ForecastEvaluationTrace trace;
  final ForecastGovernanceDisposition disposition;
  final TemporalInstant recordedAt;
  final ReplayYearCompletenessScore replayYearScore;
  final double actionabilityScore;
  final int contradictionStress;
  final List<String> governanceReasons;
}

class ForecastGovernanceProjectionService {
  factory ForecastGovernanceProjectionService({
    required ForecastKernel forecastKernel,
    required TemporalKernel temporalKernel,
    ForecastSkillLedger? skillLedger,
    ForecastEnsembleService? ensembleService,
    ForecastCalibrationService? calibrationService,
    ForecastRegimeShiftService? regimeShiftService,
    ForecastStrengthService? forecastStrengthService,
    ForecastResolutionService? forecastResolutionService,
    double minimumSupportQuality = 0.45,
    double minimumForecastStrength = 0.35,
    double minimumActionability = 0.65,
    double blockChangePointProbabilityAbove = 0.60,
    int maxOverrideStressBeforeBlock = 3,
  }) {
    final resolvedSkillLedger = skillLedger ?? ForecastSkillLedger();
    final resolvedEnsembleService = ensembleService ??
        ForecastEnsembleService(skillLedger: resolvedSkillLedger);
    final resolvedCalibrationService = calibrationService ??
        ForecastCalibrationService(skillLedger: resolvedSkillLedger);
    final resolvedRegimeShiftService = regimeShiftService ??
        ForecastRegimeShiftService(skillLedger: resolvedSkillLedger);
    final resolvedForecastStrengthService = forecastStrengthService ??
        ForecastStrengthService(
          ensembleService: resolvedEnsembleService,
          calibrationService: resolvedCalibrationService,
          regimeShiftService: resolvedRegimeShiftService,
        );
    final resolvedForecastResolutionService = forecastResolutionService ??
        ForecastResolutionService(skillLedger: resolvedSkillLedger);
    return ForecastGovernanceProjectionService._(
      forecastKernel: forecastKernel,
      temporalKernel: temporalKernel,
      skillLedger: resolvedSkillLedger,
      ensembleService: resolvedEnsembleService,
      calibrationService: resolvedCalibrationService,
      regimeShiftService: resolvedRegimeShiftService,
      forecastStrengthService: resolvedForecastStrengthService,
      forecastResolutionService: resolvedForecastResolutionService,
      minimumSupportQuality: minimumSupportQuality,
      minimumForecastStrength: minimumForecastStrength,
      minimumActionability: minimumActionability,
      blockChangePointProbabilityAbove: blockChangePointProbabilityAbove,
      maxOverrideStressBeforeBlock: maxOverrideStressBeforeBlock,
    );
  }

  ForecastGovernanceProjectionService._({
    required this.forecastKernel,
    required this.temporalKernel,
    required this.skillLedger,
    required this.ensembleService,
    required this.calibrationService,
    required this.regimeShiftService,
    required this.forecastStrengthService,
    required this.forecastResolutionService,
    required this.minimumSupportQuality,
    required this.minimumForecastStrength,
    required this.minimumActionability,
    required this.blockChangePointProbabilityAbove,
    required this.maxOverrideStressBeforeBlock,
  });

  final ForecastKernel forecastKernel;
  final TemporalKernel temporalKernel;
  final ForecastSkillLedger skillLedger;
  final ForecastEnsembleService ensembleService;
  final ForecastCalibrationService calibrationService;
  final ForecastRegimeShiftService regimeShiftService;
  final ForecastStrengthService forecastStrengthService;
  final ForecastResolutionService forecastResolutionService;
  final double minimumSupportQuality;
  final double minimumForecastStrength;
  final double minimumActionability;
  final double blockChangePointProbabilityAbove;
  final int maxOverrideStressBeforeBlock;

  Future<ForecastGovernanceProjection> evaluateForecast({
    required ForecastKernelRequest request,
    required ReplayYearCompletenessScore replayYearScore,
    List<GroundTruthOverrideRecord> overrideRecords =
        const <GroundTruthOverrideRecord>[],
  }) async {
    final kernelResult = await forecastKernel.forecast(request);
    final relevantOverrides = overrideRecords.where((record) {
      final branchMatches = record.branchId == null ||
          record.branchId == request.runContext.branchId;
      final runMatches =
          record.runId == null || record.runId == request.runContext.runId;
      return record.subjectId == request.subjectId &&
          branchMatches &&
          runMatches;
    }).toList();

    final contradictionStress = relevantOverrides.length;
    final assessment = forecastStrengthService.assess(
      request: request,
      kernelResult: kernelResult,
      replayYearScore: replayYearScore,
    );
    final validityWindowOpen = !kernelResult
        .claim.targetWindow.end.referenceTime
        .isBefore(kernelResult.claim.forecastCreatedAt.toUtc());
    final governanceReasons = <String>[
      if (!validityWindowOpen) 'forecast validity window has already closed',
      if (assessment.supportQuality < minimumSupportQuality)
        'support quality is too weak for forecast admission',
      if (assessment.forecastStrength < minimumForecastStrength)
        'forecast strength is below the minimum statistical usefulness threshold',
      if (assessment.regimeShift.probability > blockChangePointProbabilityAbove)
        'regime shift probability is too high for autonomous admission',
      if (assessment.actionability < minimumActionability)
        'forecast actionability is below the autonomous admission threshold',
      if (assessment.calibrationSnapshot.warmingUp)
        'forecast family calibration is still warming up on resolved outcomes',
      if (contradictionStress > 0)
        'ground truth overrides contradict this forecast',
    ];

    final disposition = _dispositionFor(
      validityWindowOpen: validityWindowOpen,
      supportQuality: assessment.supportQuality,
      forecastStrength: assessment.forecastStrength,
      actionability: assessment.actionability,
      changePointProbability: assessment.regimeShift.probability,
      contradictionStress: contradictionStress,
    );
    final result = _finalizeResult(
      request: request,
      kernelResult: kernelResult,
      assessment: assessment,
    );
    final receipt = await temporalKernel.recordForecast(result.claim);
    skillLedger.recordIssuedForecast(
      forecastStrengthService.buildIssuedRecord(
        request: request,
        result: result,
        assessment: assessment,
        dispositionName: disposition.name,
        governanceReasons: governanceReasons,
      ),
    );

    final trace = ForecastEvaluationTrace(
      traceId: '${request.forecastId}:trace',
      forecastId: request.forecastId,
      subjectId: request.subjectId,
      replayEnvelope: request.replayEnvelope,
      runContext: request.runContext,
      validityWindow: request.targetWindow,
      uncertainty: request.replayEnvelope.uncertainty,
      explanation: result.explanation,
      truthScope: result.truthScope,
      forecastFamilyId: result.forecastFamilyId,
      rawPredictiveDistribution: result.rawPredictiveDistribution,
      calibratedPredictiveDistribution: result.calibratedPredictiveDistribution,
      diagnostics: result.diagnostics,
      inputSourceRefs: (request.metadata['source_refs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      contradictionHooks: result.contradictionHooks,
      metadata: <String, dynamic>{
        ...result.metadata,
        'governance_reasons': governanceReasons,
        'contradiction_stress': contradictionStress,
        'actionability_score': result.actionability,
      },
    );

    return ForecastGovernanceProjection(
      result: result,
      trace: trace,
      disposition: disposition,
      recordedAt: receipt.recordedAt,
      replayYearScore: replayYearScore,
      actionabilityScore: result.actionability,
      contradictionStress: contradictionStress,
      governanceReasons: governanceReasons,
    );
  }

  ForecastGovernanceDisposition _dispositionFor({
    required bool validityWindowOpen,
    required double supportQuality,
    required double forecastStrength,
    required double actionability,
    required double changePointProbability,
    required int contradictionStress,
  }) {
    if (!validityWindowOpen ||
        supportQuality < minimumSupportQuality ||
        forecastStrength < minimumForecastStrength ||
        changePointProbability > blockChangePointProbabilityAbove ||
        contradictionStress >= maxOverrideStressBeforeBlock) {
      return ForecastGovernanceDisposition.blocked;
    }
    if (contradictionStress > 0) {
      return ForecastGovernanceDisposition.downgraded;
    }
    if (actionability < minimumActionability) {
      return ForecastGovernanceDisposition.admittedWithCaution;
    }
    return ForecastGovernanceDisposition.admitted;
  }

  ForecastKernelResult _finalizeResult({
    required ForecastKernelRequest request,
    required ForecastKernelResult kernelResult,
    required ForecastStrengthAssessment assessment,
  }) {
    final finalizedClaim = ForecastTemporalClaim(
      claimId: kernelResult.claim.claimId,
      forecastCreatedAt: kernelResult.claim.forecastCreatedAt,
      targetWindow: kernelResult.claim.targetWindow,
      evidenceWindow: kernelResult.claim.evidenceWindow,
      confidence: assessment.forecastStrength,
      modelVersion: kernelResult.claim.modelVersion,
      provenance: kernelResult.claim.provenance,
      outcomeProbability: assessment.outcomeProbability,
      predictedOutcome: assessment.predictedOutcome,
      outcomeKind: kernelResult.outcomeKind,
      forecastFamilyId: kernelResult.forecastFamilyId,
      laterOutcomeRef: kernelResult.claim.laterOutcomeRef ?? request.subjectId,
      truthScope: assessment.truthScope,
    );
    return ForecastKernelResult(
      claim: finalizedClaim,
      predictedOutcome: assessment.predictedOutcome,
      confidence: assessment.forecastStrength,
      branchId: kernelResult.branchId,
      runId: kernelResult.runId,
      explanation: kernelResult.explanation,
      forecastFamilyId: kernelResult.forecastFamilyId,
      outcomeProbability: assessment.outcomeProbability,
      outcomeKind: kernelResult.outcomeKind,
      rawPredictiveDistribution: assessment.rawDistribution,
      calibratedPredictiveDistribution: assessment.calibratedDistribution,
      forecastStrength: assessment.forecastStrength,
      actionability: assessment.actionability,
      diagnostics: assessment.diagnostics,
      decisionSpec: kernelResult.decisionSpec ?? request.decisionSpec,
      truthScope: assessment.truthScope,
      contradictionHooks: kernelResult.contradictionHooks,
      metadata: <String, dynamic>{
        ...kernelResult.metadata,
        'forecast_strength': assessment.forecastStrength,
        'actionability': assessment.actionability,
        'support_quality': assessment.supportQuality,
        'decision_margin': assessment.decisionMargin,
        'calibration_gap': assessment.calibrationSnapshot.calibrationGap,
        'skill_lower_confidence_bound':
            assessment.calibrationSnapshot.skillLowerConfidenceBound,
        'change_point_probability': assessment.regimeShift.probability,
        'bucket_key': assessment.bucketKey,
        'bucket_hierarchy': assessment.bucketHierarchy,
        'truth_scope': assessment.truthScope.toJson(),
        'scope_key': assessment.truthScope.scopeKey,
        'representation_mix': assessment.representationMix,
      },
    );
  }
}
