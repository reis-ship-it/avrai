import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/boundary/boundary_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_kernel_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:reality_engine/reality_engine.dart';

class HumanLanguageKernelTurn {
  const HumanLanguageKernelTurn({
    required this.interpretation,
    required this.boundary,
  });

  final InterpretationResult interpretation;
  final BoundaryDecision boundary;

  bool get acceptedForTranscript =>
      boundary.accepted && boundary.transcriptStorageAllowed;

  bool get acceptedForLearning =>
      boundary.accepted && boundary.learningAllowed && boundary.storageAllowed;

  bool get egressRequiresAirGap =>
      boundary.accepted && boundary.egressAllowed && boundary.airGapRequired;
}

class LanguageKernelOrchestratorService {
  LanguageKernelOrchestratorService({
    InterpretationKernelService? interpretationKernel,
    BoundaryKernelService? boundaryKernel,
    ExpressionKernelService? expressionKernel,
    LanguagePatternLearningService? languageLearningService,
    VibeKernel? vibeKernel,
  })  : _interpretationKernel =
            interpretationKernel ?? InterpretationKernelService(),
        _boundaryKernel = boundaryKernel ?? BoundaryKernelService(),
        _expressionKernel = expressionKernel ??
            ExpressionKernelService(
              nativeBridge: ExpressionNativeBridgeBindings(),
            ),
        _languageLearningService = languageLearningService,
        _vibeKernel = vibeKernel ?? VibeKernel();

  final InterpretationKernelService _interpretationKernel;
  final BoundaryKernelService _boundaryKernel;
  final ExpressionKernelService _expressionKernel;
  final LanguagePatternLearningService? _languageLearningService;
  final VibeKernel _vibeKernel;

  Future<HumanLanguageKernelTurn> processHumanText({
    required String actorAgentId,
    required String rawText,
    required Set<String> consentScopes,
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    bool shareRequested = false,
    BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.none,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
  }) async {
    final interpretation = _interpretationKernel.interpretHumanText(
      rawText: rawText,
      surface: surface,
      channel: channel,
    );
    final boundary = _boundaryKernel.enforceBoundary(
      actorAgentId: actorAgentId,
      rawText: rawText,
      interpretation: interpretation,
      consentScopes: consentScopes,
      privacyMode: privacyMode,
      shareRequested: shareRequested,
      egressPurpose: egressPurpose,
    );
    final languageLearningService = _languageLearningService;
    if (userId != null &&
        boundary.learningAllowed &&
        languageLearningService != null) {
      await languageLearningService.analyzeMessage(userId, rawText, chatType);
    }
    if (boundary.vibeMutationDecision.stateWriteAllowed &&
        interpretation.vibeEvidence.hasAnySignals) {
      _vibeKernel.ingestLanguageEvidence(
        subjectId: actorAgentId,
        evidence: interpretation.vibeEvidence,
        mutationDecision: boundary.vibeMutationDecision,
        provenanceTags: <String>[
          'language_kernel_orchestrator',
          surface,
          channel,
        ],
      );
    }
    return HumanLanguageKernelTurn(
      interpretation: interpretation,
      boundary: boundary,
    );
  }

  RenderedExpression renderGroundedOutput({
    required ExpressionSpeechAct speechAct,
    required ExpressionAudience audience,
    required ExpressionSurfaceShape surfaceShape,
    required String subjectLabel,
    required List<String> allowedClaims,
    List<String> forbiddenClaims = const <String>[],
    List<String> evidenceRefs = const <String>[],
    String confidenceBand = 'medium',
    String toneProfile = 'clear_calm',
    VibeExpressionContext? vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    final plan = _expressionKernel.compileUtterancePlan(
      speechAct: speechAct,
      audience: audience,
      surfaceShape: surfaceShape,
      subjectLabel: subjectLabel,
      allowedClaims: allowedClaims,
      forbiddenClaims: forbiddenClaims,
      evidenceRefs: evidenceRefs,
      confidenceBand: confidenceBand,
      toneProfile: toneProfile,
      vibeContext: vibeContext,
      uncertaintyNotice: uncertaintyNotice,
      cta: cta,
      adaptationProfileRef: adaptationProfileRef,
    );
    final rendered = _expressionKernel.renderDeterministic(plan);
    final validation = _expressionKernel.validateUtterance(
      allowedClaims: allowedClaims,
      assertedClaims: rendered.assertedClaims,
      forbiddenClaims: forbiddenClaims,
    );
    if (validation.valid) {
      return rendered;
    }
    final fallbackSections = <ExpressionSection>[
      if (surfaceShape != ExpressionSurfaceShape.chatTurn)
        ExpressionSection(kind: 'title', text: subjectLabel),
      const ExpressionSection(
        kind: 'body',
        text: 'AVRAI can only express what it has grounded right now.',
      ),
    ];
    return _expressionKernel.renderDeterministic(
      ExpressionPlan(
        speechAct: speechAct,
        audience: audience,
        surfaceShape: surfaceShape,
        allowedClaims: allowedClaims,
        forbiddenClaims: forbiddenClaims,
        evidenceRefs: evidenceRefs,
        confidenceBand: confidenceBand,
        toneProfile: toneProfile,
        vibeContext: vibeContext,
        uncertaintyNotice: uncertaintyNotice,
        sections: fallbackSections,
        cta: cta,
        fallbackText: 'AVRAI can only express what it has grounded right now.',
        adaptationProfileRef: adaptationProfileRef,
      ),
    );
  }

  Map<String, dynamic> diagnose() => <String, dynamic>{
        'interpretation': _interpretationKernel.diagnose(),
        'boundary': _boundaryKernel.diagnose(),
        'expression': _expressionKernel.diagnose(),
      };
}
