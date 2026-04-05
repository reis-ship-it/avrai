import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/boundary/boundary_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:reality_engine/reality_engine.dart';

bool _looksSensitive(String rawText) {
  final normalized = rawText.toLowerCase();
  return normalized.contains('5551234567') ||
      normalized.contains('me@example.com') ||
      normalized.contains('phone number');
}

bool _looksLikePreference(String rawText) {
  final normalized = rawText.toLowerCase();
  return normalized.contains('prefer') ||
      normalized.contains('i like') ||
      normalized.contains('i love') ||
      normalized.contains('want') ||
      normalized.contains('wish') ||
      normalized.contains('planning') ||
      normalized.contains('collaborative') ||
      normalized.contains('coordinate') ||
      normalized.contains('quiet') ||
      normalized.contains('slow') ||
      normalized.contains('chill') ||
      normalized.contains('local');
}

bool _containsAny(String rawText, List<String> markers) {
  final normalized = rawText.toLowerCase();
  return markers.any(normalized.contains);
}

InterpretationResult buildTestInterpretationResult(
  String rawText, {
  String surface = 'chat',
  String channel = 'in_app',
}) {
  final sensitive = _looksSensitive(rawText);
  final prefer = _looksLikePreference(rawText);
  final identitySignals = <VibeSignal>[
    if (_containsAny(rawText, const <String>[
      'quiet',
      'quieter',
      'slow',
      'slower',
      'chill',
      'calm',
      'cozy',
      'relaxed',
    ]))
      const VibeSignal(
        key: 'energy_preference',
        kind: VibeSignalKind.identity,
        value: 0.24,
        confidence: 0.88,
        provenance: <String>['test_fixture', 'quiet_energy'],
      ),
    if (_containsAny(rawText, const <String>[
      'quiet',
      'quieter',
      'less crowded',
      'not crowded',
      'uncrowded',
      'small',
    ]))
      const VibeSignal(
        key: 'crowd_tolerance',
        kind: VibeSignalKind.identity,
        value: 0.24,
        confidence: 0.84,
        provenance: <String>['test_fixture', 'quiet_crowd'],
      ),
    if (_containsAny(rawText, const <String>[
      'local',
      'hidden gem',
      'hidden gems',
      'authentic',
      'independent',
      'neighborhood',
    ]))
      const VibeSignal(
        key: 'authenticity_preference',
        kind: VibeSignalKind.identity,
        value: 0.8,
        confidence: 0.86,
        provenance: <String>['test_fixture', 'authenticity'],
      ),
    if (_containsAny(rawText, const <String>[
      'explore',
      'exploring',
      'adventure',
      'adventurous',
      'new neighborhood',
      'new neighborhoods',
      'different places',
      'discover',
    ]))
      const VibeSignal(
        key: 'exploration_eagerness',
        kind: VibeSignalKind.identity,
        value: 0.76,
        confidence: 0.84,
        provenance: <String>['test_fixture', 'exploration'],
      ),
    if (_containsAny(rawText, const <String>[
      'friends',
      'community',
      'social',
      'meet people',
      'together',
      'shared',
    ]))
      const VibeSignal(
        key: 'community_orientation',
        kind: VibeSignalKind.identity,
        value: 0.72,
        confidence: 0.82,
        provenance: <String>['test_fixture', 'community'],
      ),
  ];
  final vocabulary = rawText
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .take(6)
      .toList(growable: false);
  return InterpretationResult(
    intent:
        prefer ? InterpretationIntent.prefer : InterpretationIntent.inform,
    normalizedText: rawText.toLowerCase(),
    requestArtifact: InterpretationRequestArtifact(
      summary: rawText,
      asksForResponse: false,
      asksForRecommendation: false,
      asksForAction: false,
      asksForExplanation: false,
      referencedEntities: const <String>[],
      questions: const <String>[],
      preferenceSignals: <InterpretationPreferenceSignal>[
        if (prefer)
          const InterpretationPreferenceSignal(
            kind: 'interaction_mode',
            value: 'collaborative_planning',
            confidence: 0.88,
          ),
      ],
      shareIntent: false,
    ),
    learningArtifact: InterpretationLearningArtifact(
      vocabulary: vocabulary,
      phrases: <String>[rawText],
      toneMetrics: const <String, double>{'warmth': 0.6, 'clarity': 0.8},
      directnessPreference: 0.6,
      brevityPreference: 0.5,
    ),
    vibeEvidence: (prefer || identitySignals.isNotEmpty)
        ? VibeEvidence(
            summary: identitySignals.isEmpty
                ? 'User expressed a collaborative planning preference.'
                : 'User expressed stable vibe preferences in language.',
            identitySignals: <VibeSignal>[
              if (prefer)
                const VibeSignal(
                  key: 'collaboration_preference',
                  kind: VibeSignalKind.identity,
                  value: 0.82,
                  confidence: 0.88,
                  provenance: <String>['test_fixture'],
                ),
              ...identitySignals,
            ],
            pheromoneSignals: const <VibeSignal>[],
            behaviorSignals: const <VibeSignal>[],
            affectiveSignals: const <VibeSignal>[],
            styleSignals: const <VibeSignal>[],
          )
        : const VibeEvidence(
            summary: '',
            identitySignals: <VibeSignal>[],
            pheromoneSignals: <VibeSignal>[],
            behaviorSignals: <VibeSignal>[],
            affectiveSignals: <VibeSignal>[],
            styleSignals: <VibeSignal>[],
          ),
    privacySensitivity: sensitive
        ? InterpretationPrivacySensitivity.high
        : InterpretationPrivacySensitivity.low,
    confidence: 0.9,
    ambiguityFlags: <String>[
      if (surface == 'ai2ai_connection' && channel == 'session_outcome')
        'session_outcome'
    ],
    needsClarification: false,
    safeForLearning: !sensitive,
  );
}

BoundaryDecision buildTestBoundaryDecision({
  required String rawText,
  required InterpretationResult interpretation,
  required bool shareRequested,
  required BoundaryEgressPurpose egressPurpose,
  BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.userRuntime,
}) {
  final accepted = interpretation.safeForLearning;
  final isDirectDraft =
      privacyMode == BoundaryPrivacyMode.localSovereign &&
          egressPurpose == BoundaryEgressPurpose.directMessage &&
          !shareRequested;
  final isDirectEgress =
      privacyMode == BoundaryPrivacyMode.localSovereign &&
          egressPurpose == BoundaryEgressPurpose.directMessage &&
          shareRequested;
  final isBlockedArtifactEgress =
      privacyMode == BoundaryPrivacyMode.localSovereign &&
          egressPurpose == BoundaryEgressPurpose.ai2aiLearningArtifact &&
          shareRequested;
  final isBlockedLocalSovereignShare =
      privacyMode == BoundaryPrivacyMode.localSovereign &&
          shareRequested &&
          !isDirectEgress &&
          !isBlockedArtifactEgress;
  final learningAllowed =
      accepted &&
      !shareRequested &&
      !isDirectDraft &&
      !isBlockedArtifactEgress &&
      !isBlockedLocalSovereignShare;
  final storageAllowed =
      accepted &&
      !shareRequested &&
      !isDirectDraft &&
      !isBlockedArtifactEgress &&
      !isBlockedLocalSovereignShare;
  final transcriptStorageAllowed = accepted;
  final egressAllowed = accepted && isDirectEgress;
  final isGovernanceLearning =
      privacyMode == BoundaryPrivacyMode.governance &&
          consentScopesContainGovernanceSignal(
            interpretation: interpretation,
          );
  final disposition = !accepted
      ? BoundaryDisposition.block
      : isDirectEgress
          ? BoundaryDisposition.userAuthorizedEgress
          : (isDirectDraft ||
                  isBlockedArtifactEgress ||
                  isBlockedLocalSovereignShare)
              ? BoundaryDisposition.localOnly
              : BoundaryDisposition.storeSanitized;
  final reasonCodes = !accepted
      ? <String>['contains_sensitive_contact_data']
      : isDirectEgress
          ? <String>['explicit_user_message_delivery']
          : isDirectDraft
              ? <String>['local_transcript_only_message_draft']
              : isBlockedArtifactEgress
                  ? <String>['local_sovereign_blocks_egress']
                  : isBlockedLocalSovereignShare
                      ? <String>['local_sovereign_blocks_egress']
                  : isGovernanceLearning
                      ? <String>['accepted_for_governance_learning']
                      : <String>['accepted_for_local_learning'];
  return BoundaryDecision(
    accepted: accepted,
    disposition: disposition,
    transcriptStorageAllowed: transcriptStorageAllowed,
    storageAllowed: storageAllowed,
    learningAllowed: learningAllowed,
    egressAllowed: egressAllowed,
    airGapRequired: false,
    reasonCodes: reasonCodes,
    sanitizedArtifact: BoundarySanitizedArtifact(
      pseudonymousActorRef: 'anon_test_actor',
      summary: rawText,
      safeClaims: <String>[if (accepted) rawText],
      safeQuestions: const <String>[],
      safePreferenceSignals: interpretation.requestArtifact.preferenceSignals,
      learningVocabulary: interpretation.learningArtifact.vocabulary,
      learningPhrases: interpretation.learningArtifact.phrases,
      redactedText: accepted ? rawText : '[redacted]',
      sharePayload: egressAllowed ? rawText : null,
    ),
    vibeMutationDecision: VibeMutationDecision(
      stateWriteAllowed: learningAllowed,
      dnaWriteAllowed: learningAllowed,
      pheromoneWriteAllowed: false,
      behaviorWriteAllowed: false,
      affectiveWriteAllowed: false,
      styleWriteAllowed: learningAllowed,
      reasonCodes: reasonCodes,
      governanceScope: 'personal',
    ),
    egressPurpose: egressPurpose,
  );
}

bool consentScopesContainGovernanceSignal({
  required InterpretationResult interpretation,
}) {
  return interpretation.requestArtifact.summary.toLowerCase().contains(
        'transport drift',
      );
}

class TestInterpretationKernelService extends InterpretationKernelService {
  TestInterpretationKernelService();

  @override
  InterpretationResult interpretHumanText({
    required String rawText,
    String surface = 'chat',
    String channel = 'in_app',
    String locale = 'en-US',
  }) {
    return buildTestInterpretationResult(
      rawText,
      surface: surface,
      channel: channel,
    );
  }
}

class TestBoundaryKernelService extends BoundaryKernelService {
  TestBoundaryKernelService();

  @override
  BoundaryDecision enforceBoundary({
    required String actorAgentId,
    required String rawText,
    required InterpretationResult interpretation,
    required Set<String> consentScopes,
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    bool shareRequested = false,
    BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.none,
  }) {
    return buildTestBoundaryDecision(
      rawText: rawText,
      interpretation: interpretation,
      shareRequested: shareRequested,
      egressPurpose: egressPurpose,
      privacyMode: privacyMode,
    );
  }
}

class TestHumanLanguageBoundaryReviewLane extends HumanLanguageBoundaryReviewLane {
  TestHumanLanguageBoundaryReviewLane();

  @override
  Future<HumanLanguageBoundaryReview> reviewOutboundText({
    required String actorAgentId,
    required String rawText,
    required BoundaryEgressPurpose egressPurpose,
    required bool egressRequested,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    Set<String>? consentScopes,
  }) async {
    final interpretation = buildTestInterpretationResult(
      rawText,
      surface: surface,
      channel: channel,
    );
    return HumanLanguageBoundaryReview(
      rawText: rawText,
      turn: HumanLanguageKernelTurn(
        interpretation: interpretation,
        boundary: buildTestBoundaryDecision(
          rawText: rawText,
          interpretation: interpretation,
          shareRequested: egressRequested,
          egressPurpose: egressPurpose,
          privacyMode: privacyMode,
        ),
      ),
      egressRequested: egressRequested,
      egressPurpose: egressPurpose,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
  }

  @override
  Future<HumanLanguageBoundaryReview> reviewLocalLearningText({
    required String actorAgentId,
    required String rawText,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.userRuntime,
    Set<String>? consentScopes,
  }) async {
    final interpretation = buildTestInterpretationResult(
      rawText,
      surface: surface,
      channel: channel,
    );
    return HumanLanguageBoundaryReview(
      rawText: rawText,
      turn: HumanLanguageKernelTurn(
        interpretation: interpretation,
        boundary: buildTestBoundaryDecision(
          rawText: rawText,
          interpretation: interpretation,
          shareRequested: false,
          egressPurpose: BoundaryEgressPurpose.none,
          privacyMode: privacyMode,
        ),
      ),
      egressRequested: false,
      egressPurpose: BoundaryEgressPurpose.none,
      chatType: chatType,
      surface: surface,
      channel: channel,
    );
  }
}

class TestLanguageKernelOrchestratorService
    extends LanguageKernelOrchestratorService {
  TestLanguageKernelOrchestratorService();

  @override
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
    final interpretation = buildTestInterpretationResult(
      rawText,
      surface: surface,
      channel: channel,
    );
    return HumanLanguageKernelTurn(
      interpretation: interpretation,
      boundary: buildTestBoundaryDecision(
        rawText: rawText,
        interpretation: interpretation,
        shareRequested: shareRequested,
        egressPurpose: egressPurpose,
        privacyMode: privacyMode,
      ),
    );
  }
}

class TestExpressionKernelService extends ExpressionKernelService {
  TestExpressionKernelService();

  @override
  ExpressionPlan compileUtterancePlan({
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
    return ExpressionPlan(
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
      sections: <ExpressionSection>[
        if (surfaceShape != ExpressionSurfaceShape.chatTurn)
          ExpressionSection(kind: 'title', text: subjectLabel),
        ExpressionSection(
          kind: 'body',
          text: allowedClaims.join(' '),
        ),
      ],
      cta: cta,
      fallbackText: 'AVRAI can only express what it has grounded right now.',
      adaptationProfileRef: adaptationProfileRef,
    );
  }

  @override
  RenderedExpression renderDeterministic(ExpressionPlan plan) {
    return RenderedExpression(
      text: plan.sections.map((section) => section.text).join('\n'),
      sections: plan.sections,
      assertedClaims: plan.allowedClaims,
    );
  }

  @override
  ExpressionValidationResult validateUtterance({
    required List<String> allowedClaims,
    required List<String> assertedClaims,
    List<String> forbiddenClaims = const <String>[],
  }) {
    final forbiddenHits = assertedClaims
        .where((claim) => forbiddenClaims.contains(claim))
        .toList(growable: false);
    final unsupportedClaims = assertedClaims
        .where((claim) => !allowedClaims.contains(claim))
        .toList(growable: false);
    return ExpressionValidationResult(
      valid: forbiddenHits.isEmpty && unsupportedClaims.isEmpty,
      unsupportedClaims: unsupportedClaims,
      forbiddenHits: forbiddenHits,
      fallbackRequired: forbiddenHits.isNotEmpty || unsupportedClaims.isNotEmpty,
    );
  }
}

LanguageKernelOrchestratorService buildDeterministicLanguageKernelOrchestrator({
  VibeKernel? vibeKernel,
}) {
  return LanguageKernelOrchestratorService(
    interpretationKernel: TestInterpretationKernelService(),
    boundaryKernel: TestBoundaryKernelService(),
    expressionKernel: TestExpressionKernelService(),
    vibeKernel: vibeKernel,
  );
}
