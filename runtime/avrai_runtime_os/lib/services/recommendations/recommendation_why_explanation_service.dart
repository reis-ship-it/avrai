import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/events/event_recommendation.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    as kernel_models;
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/why/why_evidence_adapters.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_support.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
import 'package:get_it/get_it.dart';

class RecommendationExpressionArtifact {
  const RecommendationExpressionArtifact({
    required this.explanation,
    required this.plan,
    required this.rendered,
    required this.validation,
  });

  final WhySnapshot explanation;
  final ExpressionPlan plan;
  final RenderedExpression rendered;
  final ExpressionValidationResult validation;

  String get displayText => rendered.text;
}

class RecommendationWhyExplanationService {
  RecommendationWhyExplanationService({
    this.headlessOsHost,
    this.whySupport = const DefaultWhyKernelSupport(),
    this.temporalEvidenceAdapter = const TemporalWhyEvidenceAdapter(
      sourceSubsystem: 'event_recommendation_service',
    ),
    this.howEvidenceAdapter = const HowMechanismWhyEvidenceAdapter(
      sourceSubsystem: 'event_recommendation_service',
    ),
    ExpressionKernelService? expressionKernelService,
    UserGovernedLearningProjectionService?
        userGovernedLearningProjectionService,
    UserGovernedLearningUsageService? userGovernedLearningUsageService,
  })  : expressionKernelService = expressionKernelService ??
            ExpressionKernelService(
              nativeBridge: ExpressionNativeBridgeBindings(),
            ),
        _userGovernedLearningProjectionService =
            userGovernedLearningProjectionService ??
                (GetIt.instance
                        .isRegistered<UserGovernedLearningProjectionService>()
                    ? GetIt.instance<UserGovernedLearningProjectionService>()
                    : null),
        _userGovernedLearningUsageService = userGovernedLearningUsageService ??
            (GetIt.instance.isRegistered<UserGovernedLearningUsageService>()
                ? GetIt.instance<UserGovernedLearningUsageService>()
                : null);

  final HeadlessAvraiOsHost? headlessOsHost;
  final DefaultWhyKernelSupport whySupport;
  final TemporalWhyEvidenceAdapter temporalEvidenceAdapter;
  final HowMechanismWhyEvidenceAdapter howEvidenceAdapter;
  final ExpressionKernelService expressionKernelService;
  final UserGovernedLearningProjectionService?
      _userGovernedLearningProjectionService;
  final UserGovernedLearningUsageService? _userGovernedLearningUsageService;

  WhySnapshot explainRecommendation({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'system',
  }) {
    return _explainRecommendationInternal(
      user: user,
      recommendation: recommendation,
      perspective: perspective,
    );
  }

  Future<WhySnapshot> explainRecommendationWithKernelContext({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'system',
  }) async {
    kernel_models.KernelContextBundle? runtimeBundle;
    kernel_models.KernelGovernanceReport? governanceReport;
    final osHost = headlessOsHost;
    if (osHost != null) {
      try {
        await osHost.start();
        final envelope = kernel_models.KernelEventEnvelope(
          eventId:
              'recommendation_why:${user.id}:${recommendation.event.id}:${recommendation.generatedAt.microsecondsSinceEpoch}',
          userId: user.id,
          occurredAtUtc: recommendation.generatedAt.toUtc(),
          sourceSystem: 'recommendation_why_explanation_service',
          eventType: 'recommendation_explained',
          actionType: 'explain_recommendation',
          entityId: recommendation.event.id,
          entityType: 'event',
          context: <String, dynamic>{
            if ((recommendation.event.location ?? '').isNotEmpty)
              'location_label': recommendation.event.location,
          },
          predictionContext: <String, dynamic>{
            'predicted_relevance': recommendation.relevanceScore,
            'reason': recommendation.reason.name,
          },
          runtimeContext: const <String, dynamic>{
            'execution_path': 'recommendation_why_explanation_service',
            'workflow_stage': 'explanation',
          },
        );
        runtimeBundle =
            await osHost.resolveRuntimeExecution(envelope: envelope);
        governanceReport = await osHost.inspectGovernance(
          envelope: envelope,
          whyRequest: kernel_models.KernelWhyRequest(
            bundle: runtimeBundle.withoutWhy(),
            goal: 'explain_event_recommendation',
            predictedOutcome: 'recommendation_visible',
            predictedConfidence: recommendation.relevanceScore,
            actualOutcome: 'generated',
            actualOutcomeScore: 1.0,
            coreSignals: <kernel_models.WhySignal>[
              kernel_models.WhySignal(
                label: 'recommendation_score',
                weight: recommendation.relevanceScore,
                source: 'core',
                durable: true,
              ),
            ],
          ),
        );
      } catch (_) {}
    }
    return _explainRecommendationInternalWithGovernedEvidence(
      user: user,
      recommendation: recommendation,
      perspective: perspective,
      kernelContextBundle: runtimeBundle,
      governanceReport: governanceReport,
    );
  }

  RecommendationExpressionArtifact expressRecommendation({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'user_safe',
  }) {
    final explanation = explainRecommendation(
      user: user,
      recommendation: recommendation,
      perspective: perspective,
    );
    return buildRecommendationExpressionArtifact(
      userId: user.id,
      recommendation: recommendation,
      explanation: explanation,
      perspective: perspective,
    );
  }

  Future<RecommendationExpressionArtifact>
      expressRecommendationWithKernelContext({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'user_safe',
  }) async {
    final explanation = await explainRecommendationWithKernelContext(
      user: user,
      recommendation: recommendation,
      perspective: perspective,
    );
    return buildRecommendationExpressionArtifact(
      userId: user.id,
      recommendation: recommendation,
      explanation: explanation,
      perspective: perspective,
    );
  }

  RecommendationExpressionArtifact buildRecommendationExpressionArtifact({
    required String userId,
    required EventRecommendation recommendation,
    required WhySnapshot explanation,
    String perspective = 'user_safe',
  }) {
    final governedLearningClaim = _governedLearningClaim(explanation);
    final allowedClaims = _allowedClaims(
      recommendation: recommendation,
      explanation: explanation,
      governedLearningClaim: governedLearningClaim,
    );
    final forbiddenClaims = _forbiddenClaims(
      recommendation: recommendation,
      explanation: explanation,
      perspective: perspective,
    );
    final plan = expressionKernelService.compileUtterancePlan(
      speechAct: ExpressionSpeechAct.explain,
      audience: _expressionAudienceFor(perspective),
      surfaceShape: ExpressionSurfaceShape.card,
      subjectLabel: recommendation.event.title,
      allowedClaims: allowedClaims,
      forbiddenClaims: forbiddenClaims,
      evidenceRefs: _evidenceRefs(explanation),
      confidenceBand: _confidenceBand(
          recommendation.relevanceScore, explanation.confidence),
      toneProfile: _toneProfileFor(explanation),
      uncertaintyNotice: _uncertaintyNotice(explanation),
      cta: 'Open the event to see details.',
      adaptationProfileRef: 'recommendation_explanation:$userId',
    );
    var rendered = expressionKernelService.renderDeterministic(plan);
    var validation = expressionKernelService.validateUtterance(
      allowedClaims: plan.allowedClaims,
      assertedClaims: rendered.assertedClaims,
      forbiddenClaims: plan.forbiddenClaims,
    );
    if (validation.fallbackRequired) {
      rendered = RenderedExpression(
        text: plan.fallbackText,
        sections: <ExpressionSection>[
          ExpressionSection(kind: 'body', text: plan.fallbackText),
        ],
        assertedClaims: const <String>[],
      );
      validation = const ExpressionValidationResult(
        valid: true,
        unsupportedClaims: <String>[],
        forbiddenHits: <String>[],
        fallbackRequired: false,
      );
    }
    return RecommendationExpressionArtifact(
      explanation: explanation,
      plan: plan,
      rendered: rendered,
      validation: validation,
    );
  }

  Future<WhySnapshot> _explainRecommendationInternalWithGovernedEvidence({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    required String perspective,
    kernel_models.KernelContextBundle? kernelContextBundle,
    kernel_models.KernelGovernanceReport? governanceReport,
  }) async {
    final governedEvidence = await _loadGovernedLearningEvidence(
      user: user,
      recommendation: recommendation,
    );
    return _explainRecommendationInternal(
      user: user,
      recommendation: recommendation,
      perspective: perspective,
      kernelContextBundle: kernelContextBundle,
      governanceReport: governanceReport,
      extraEvidence: governedEvidence,
    );
  }

  WhySnapshot _explainRecommendationInternal({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    required String perspective,
    kernel_models.KernelContextBundle? kernelContextBundle,
    kernel_models.KernelGovernanceReport? governanceReport,
    List<WhyEvidence> extraEvidence = const <WhyEvidence>[],
  }) {
    final event = recommendation.event;
    final temporalSnapshot = _buildTemporalSnapshot(recommendation);
    final temporalEvidence =
        temporalEvidenceAdapter.toWhyEvidence(temporalSnapshot);
    final mechanismEvidence = howEvidenceAdapter.toWhyEvidence(
      HowMechanismContext(
        executionPath: 'event_recommendation_pipeline',
        workflowStage: 'ranking',
        failureMechanism:
            recommendation.isWeaklyRelevant ? 'low_relevance_score' : null,
        mechanismConfidence: recommendation.relevanceScore.clamp(0.0, 1.0),
        interventionChain: const <String>[
          'match',
          'preference_score',
          'blend',
          'rank',
        ],
        modelFamily: 'event_recommendation',
      ),
    );
    final evidence = <WhyEvidence>[
      temporalEvidence,
      ...extraEvidence,
      mechanismEvidence,
      _primaryRecommendationEvidence(recommendation),
      _reasonEvidence(recommendation),
      _categoryEvidence(event, recommendation),
      _localityEvidence(event, user, recommendation),
      _scopeEvidence(recommendation),
      _matchingEvidence(recommendation),
      _explorationEvidence(recommendation),
      ..._kernelBundleEvidence(kernelContextBundle),
      ..._governanceEvidence(governanceReport),
    ].where(_meaningfulEvidence).toList();

    return whySupport.explain(
      WhyKernelRequest(
        goal: 'explain_event_recommendation',
        subjectRef: WhyRef(
          id: user.id,
          label: user.displayName ?? user.id,
          kind: 'user',
        ),
        actionRef: const WhyRef(
          id: 'recommend_event',
          label: 'recommend_event',
          kind: 'recommendation_action',
        ),
        outcomeRef: WhyRef(
          id: event.id,
          label: event.title,
          kind: 'expertise_event',
        ),
        queryKind: WhyQueryKind.recommendation,
        requestedPerspective:
            WhyRequestedPerspective.fromWireValue(perspective),
        evidenceBundle: WhyEvidenceBundle(entries: evidence),
        linkedWhoRefs: <WhyRef>[
          WhyRef(
            id: event.host.id,
            label: event.host.displayName ?? event.host.id,
            kind: 'host',
          ),
        ],
        linkedWhatRefs: <WhyRef>[
          WhyRef(
            id: event.id,
            label: event.title,
            kind: 'event',
          ),
        ],
        linkedWhereRefs: <WhyRef>[
          if ((event.location ?? '').isNotEmpty)
            WhyRef(
              id: event.location!,
              label: event.location,
              kind: 'location',
            ),
        ],
        linkedWhenRefs: <WhyRef>[
          WhyRef(
            id: recommendation.generatedAt.toIso8601String(),
            label: temporalSnapshot.semanticBand.name,
            kind: 'recommendation_time',
          ),
        ],
        linkedHowRefs: const <WhyRef>[
          WhyRef(
            id: 'event_recommendation_pipeline',
            label: 'event_recommendation_pipeline',
            kind: 'execution_path',
          ),
        ],
        maxCounterfactuals: 2,
        explanationDepth: 3,
      ),
    );
  }

  List<WhyEvidence> _kernelBundleEvidence(
    kernel_models.KernelContextBundle? bundle,
  ) {
    if (bundle == null) {
      return const <WhyEvidence>[];
    }
    return <WhyEvidence>[
      if (bundle.where != null)
        WhyEvidence(
          id: 'kernel_where_${bundle.where!.localityToken}',
          label: 'kernel locality ${bundle.where!.localityToken}',
          weight: bundle.where!.spatialConfidence.clamp(0.0, 1.0),
          polarity: WhyEvidencePolarity.positive,
          sourceKernel: WhyEvidenceSourceKernel.where,
          sourceSubsystem: 'headless_os_host',
          durability: 'transient',
          confidence: bundle.where!.spatialConfidence.clamp(0.0, 1.0),
          observed: false,
          inferred: true,
          subjectRef: bundle.where!.localityToken,
          scope: bundle.where!.localityCode,
        ),
      if (bundle.how != null)
        WhyEvidence(
          id: 'kernel_how_${bundle.how!.workflowStage}',
          label: 'kernel path ${bundle.how!.executionPath}',
          weight: bundle.how!.mechanismConfidence.clamp(0.0, 1.0),
          polarity: WhyEvidencePolarity.positive,
          sourceKernel: WhyEvidenceSourceKernel.how,
          sourceSubsystem: 'headless_os_host',
          durability: 'transient',
          confidence: bundle.how!.mechanismConfidence.clamp(0.0, 1.0),
          observed: false,
          inferred: true,
          subjectRef: bundle.how!.executionPath,
          scope: bundle.how!.workflowStage,
        ),
      if (bundle.when != null)
        WhyEvidence(
          id: 'kernel_when_${bundle.when!.recencyBucket}',
          label: 'kernel timing ${bundle.when!.recencyBucket}',
          weight: bundle.when!.temporalConfidence.clamp(0.0, 1.0),
          polarity: WhyEvidencePolarity.positive,
          sourceKernel: WhyEvidenceSourceKernel.when,
          sourceSubsystem: 'headless_os_host',
          durability: 'transient',
          confidence: bundle.when!.temporalConfidence.clamp(0.0, 1.0),
          observed: false,
          inferred: true,
          subjectRef: bundle.when!.observedAt.toIso8601String(),
          scope: bundle.when!.recencyBucket,
        ),
      ..._canonicalVibeEvidence(bundle),
    ];
  }

  List<WhyEvidence> _canonicalVibeEvidence(
    kernel_models.KernelContextBundle bundle,
  ) {
    final evidence = <WhyEvidence>[];
    final personalSnapshot = bundle.vibe ?? bundle.vibeStack?.primarySnapshot;
    if (personalSnapshot != null) {
      evidence.add(
        _snapshotEvidence(
          id: 'kernel_vibe_${personalSnapshot.subjectId}',
          label: 'personal vibe ${personalSnapshot.affectiveState.label}',
          snapshot: personalSnapshot,
          sourceKernel: WhyEvidenceSourceKernel.who,
          scope: 'personal',
        ),
      );
    }

    final vibeStack = bundle.vibeStack;
    if (vibeStack == null) {
      return evidence;
    }

    final activeLocalitySnapshot = vibeStack.activeLocalitySnapshot ??
        (vibeStack.geographicSnapshots.isNotEmpty
            ? vibeStack.geographicSnapshots.first
            : null);
    if (activeLocalitySnapshot != null) {
      evidence.add(
        _snapshotEvidence(
          id: 'kernel_geographic_${activeLocalitySnapshot.subjectId}',
          label:
              'geographic vibe ${_geographicLabel(activeLocalitySnapshot.subjectRef.effectiveGeographicLevel)}',
          snapshot: activeLocalitySnapshot,
          sourceKernel: WhyEvidenceSourceKernel.where,
          scope: _geographicLabel(
            activeLocalitySnapshot.subjectRef.effectiveGeographicLevel,
          ),
        ),
      );
    }

    for (final higherSnapshot in vibeStack.higherAgentSnapshots.take(2)) {
      evidence.add(
        _snapshotEvidence(
          id: 'kernel_higher_${higherSnapshot.subjectId}',
          label:
              'higher geographic vibe ${_geographicLabel(higherSnapshot.subjectRef.effectiveGeographicLevel)}',
          snapshot: higherSnapshot,
          sourceKernel: WhyEvidenceSourceKernel.where,
          scope: _geographicLabel(
            higherSnapshot.subjectRef.effectiveGeographicLevel,
          ),
        ),
      );
    }

    for (final scopedSnapshot in vibeStack.scopedContextSnapshots.take(2)) {
      final scopedKind = vibeStack.scopedBindings
          .firstWhere(
            (entry) => entry.contextRef.subjectId == scopedSnapshot.subjectId,
            orElse: () => ScopedVibeBinding(
              contextRef: scopedSnapshot.subjectRef,
              scopedKind: ScopedAgentKind.scene,
            ),
          )
          .scopedKind
          .toWireValue();
      evidence.add(
        _snapshotEvidence(
          id: 'kernel_scoped_${scopedSnapshot.subjectId}',
          label: 'scoped context $scopedKind',
          snapshot: scopedSnapshot,
          sourceKernel: WhyEvidenceSourceKernel.social,
          scope: scopedKind,
        ),
      );
    }

    for (final entitySnapshot in vibeStack.selectedEntitySnapshots.take(2)) {
      evidence.add(
        _snapshotEvidence(
          id: 'kernel_entity_${entitySnapshot.entityId}',
          label: 'entity vibe ${entitySnapshot.entityType}',
          snapshot: entitySnapshot.vibe,
          sourceKernel: WhyEvidenceSourceKernel.what,
          scope: entitySnapshot.entityType,
        ),
      );
    }

    return evidence;
  }

  WhyEvidence _snapshotEvidence({
    required String id,
    required String label,
    required VibeStateSnapshot snapshot,
    required WhyEvidenceSourceKernel sourceKernel,
    required String scope,
  }) {
    return WhyEvidence(
      id: id,
      label: label,
      weight: snapshot.confidence.clamp(0.0, 1.0),
      polarity: WhyEvidencePolarity.positive,
      sourceKernel: sourceKernel,
      sourceSubsystem: 'canonical_vibe_kernel',
      durability: scope == 'personal' ? 'durable' : 'transient',
      confidence: snapshot.confidence.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: snapshot.subjectId,
      scope: scope,
      tags: snapshot.provenanceTags,
    );
  }

  String _geographicLabel(GeographicAgentLevel? level) =>
      level?.toWireValue() ?? 'locality';

  List<WhyEvidence> _governanceEvidence(
    kernel_models.KernelGovernanceReport? governanceReport,
  ) {
    if (governanceReport == null || governanceReport.projections.isEmpty) {
      return const <WhyEvidence>[];
    }
    return governanceReport.projections.take(3).map((projection) {
      return WhyEvidence(
        id: 'governance_${projection.domain.name}',
        label: projection.summary,
        weight: projection.confidence.clamp(0.0, 1.0),
        polarity: WhyEvidencePolarity.positive,
        sourceKernel: _mapDomain(projection.domain),
        sourceSubsystem: 'headless_governance',
        durability: 'transient',
        confidence: projection.confidence.clamp(0.0, 1.0),
        observed: false,
        inferred: true,
        subjectRef: projection.domain.name,
        scope: projection.domain.name,
        tags: projection.highlights,
      );
    }).toList(growable: false);
  }

  WhyEvidenceSourceKernel _mapDomain(kernel_models.KernelDomain domain) {
    return switch (domain) {
      kernel_models.KernelDomain.who => WhyEvidenceSourceKernel.who,
      kernel_models.KernelDomain.what => WhyEvidenceSourceKernel.what,
      kernel_models.KernelDomain.when => WhyEvidenceSourceKernel.when,
      kernel_models.KernelDomain.where => WhyEvidenceSourceKernel.where,
      kernel_models.KernelDomain.why => WhyEvidenceSourceKernel.model,
      kernel_models.KernelDomain.how => WhyEvidenceSourceKernel.how,
      kernel_models.KernelDomain.vibe => WhyEvidenceSourceKernel.model,
    };
  }

  WhyEvidence _primaryRecommendationEvidence(
      EventRecommendation recommendation) {
    return WhyEvidence(
      id: 'event_${recommendation.event.id}_score',
      label:
          'recommendation score ${recommendation.relevanceScore.toStringAsFixed(2)}',
      weight: recommendation.relevanceScore.clamp(0.0, 1.0),
      polarity: recommendation.isWeaklyRelevant
          ? WhyEvidencePolarity.negative
          : WhyEvidencePolarity.positive,
      sourceKernel: WhyEvidenceSourceKernel.what,
      sourceSubsystem: 'event_recommendation_service',
      durability: 'transient',
      confidence: recommendation.relevanceScore.clamp(0.0, 1.0),
      observed: true,
      inferred: false,
      subjectRef: recommendation.event.id,
      scope: recommendation.reason.name,
      tags: <String>[recommendation.reason.name],
    );
  }

  WhyEvidence _reasonEvidence(EventRecommendation recommendation) {
    return WhyEvidence(
      id: 'reason_${recommendation.reason.name}_${recommendation.event.id}',
      label: recommendation.reasonDisplayText,
      weight: _reasonWeight(recommendation.reason),
      polarity: WhyEvidencePolarity.positive,
      sourceKernel: _reasonKernel(recommendation.reason),
      sourceSubsystem: 'event_recommendation_reason',
      durability: recommendation.reason == RecommendationReason.exploration
          ? 'transient'
          : 'durable',
      confidence: recommendation.relevanceScore.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: recommendation.event.id,
      scope: recommendation.reason.name,
      tags: <String>[recommendation.reason.name],
    );
  }

  WhyEvidence _categoryEvidence(
    ExpertiseEvent event,
    EventRecommendation recommendation,
  ) {
    return WhyEvidence(
      id: 'category_${event.id}',
      label: 'category fit ${event.category}',
      weight: recommendation.preferenceMatch.categoryMatch.clamp(0.0, 1.0),
      polarity: recommendation.preferenceMatch.categoryMatch >= 0.4
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.neutral,
      sourceKernel: WhyEvidenceSourceKernel.what,
      sourceSubsystem: 'category_preference',
      durability: 'durable',
      confidence: recommendation.preferenceMatch.categoryMatch.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: event.id,
      scope: event.category,
      tags: <String>[event.category],
    );
  }

  WhyEvidence _localityEvidence(
    ExpertiseEvent event,
    UnifiedUser user,
    EventRecommendation recommendation,
  ) {
    final userLocality = _extractLocality(user.location);
    final eventLocality = _extractLocality(event.location);
    final localityMatch = recommendation.preferenceMatch.localityMatch;
    return WhyEvidence(
      id: 'locality_${event.id}',
      label: eventLocality == null
          ? 'locality unknown'
          : userLocality != null && userLocality == eventLocality
              ? 'same locality as user'
              : 'connected locality $eventLocality',
      weight: localityMatch.clamp(0.0, 1.0),
      polarity: localityMatch >= 0.35
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.neutral,
      sourceKernel: WhyEvidenceSourceKernel.where,
      sourceSubsystem: 'locality_match',
      durability: 'transient',
      confidence: localityMatch.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: event.id,
      scope: eventLocality,
      tags: <String>[
        if (eventLocality != null) eventLocality,
      ],
    );
  }

  WhyEvidence _scopeEvidence(EventRecommendation recommendation) {
    return WhyEvidence(
      id: 'scope_${recommendation.event.id}',
      label: 'scope fit ${recommendation.reason.name}',
      weight: recommendation.preferenceMatch.scopeMatch.clamp(0.0, 1.0),
      polarity: recommendation.preferenceMatch.scopeMatch >= 0.35
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.neutral,
      sourceKernel: WhyEvidenceSourceKernel.who,
      sourceSubsystem: 'scope_preference',
      durability: 'durable',
      confidence: recommendation.preferenceMatch.scopeMatch.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: recommendation.event.id,
      scope: recommendation.reason.name,
      tags: <String>['scope'],
    );
  }

  WhyEvidence _matchingEvidence(EventRecommendation recommendation) {
    final score = recommendation.matchingScore?.score ??
        recommendation.preferenceMatch.overallMatch;
    return WhyEvidence(
      id: 'matching_${recommendation.event.id}',
      label: 'matching alignment ${score.toStringAsFixed(2)}',
      weight: score.clamp(0.0, 1.0),
      polarity: score >= 0.4
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.negative,
      sourceKernel: WhyEvidenceSourceKernel.social,
      sourceSubsystem: 'matching_score',
      durability: 'transient',
      confidence: score.clamp(0.0, 1.0),
      observed: false,
      inferred: true,
      subjectRef: recommendation.event.id,
      scope: 'matching',
      tags: <String>['matching'],
    );
  }

  WhyEvidence _explorationEvidence(EventRecommendation recommendation) {
    if (!recommendation.isExploration) {
      return const WhyEvidence(
        id: 'exploration_none',
        label: 'no exploration override',
        weight: 0.0,
        polarity: WhyEvidencePolarity.neutral,
        sourceKernel: WhyEvidenceSourceKernel.how,
      );
    }
    return WhyEvidence(
      id: 'exploration_${recommendation.event.id}',
      label: 'exploration door opened',
      weight: 0.52,
      polarity: WhyEvidencePolarity.positive,
      sourceKernel: WhyEvidenceSourceKernel.how,
      sourceSubsystem: 'exploration_blend',
      durability: 'transient',
      confidence: 0.58,
      observed: false,
      inferred: true,
      subjectRef: recommendation.event.id,
      scope: 'exploration',
      tags: const <String>['exploration'],
    );
  }

  TemporalSnapshot _buildTemporalSnapshot(EventRecommendation recommendation) {
    final instant = TemporalInstant(
      referenceTime: recommendation.generatedAt.toUtc(),
      civilTime: recommendation.generatedAt.toUtc(),
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'event_recommendation_service',
      ),
      uncertainty: const TemporalUncertainty.zero(),
    );
    return TemporalSnapshot(
      observedAt: instant,
      recordedAt: instant,
      effectiveAt: instant,
      semanticBand: _semanticBandFor(recommendation.generatedAt.toUtc()),
      lineageRef: 'event_recommendation_${recommendation.event.id}',
    );
  }

  SemanticTimeBand _semanticBandFor(DateTime instant) {
    final hour = instant.hour;
    if (hour >= 5 && hour < 8) return SemanticTimeBand.dawn;
    if (hour >= 8 && hour < 12) return SemanticTimeBand.morning;
    if (hour == 12) return SemanticTimeBand.noon;
    if (hour > 12 && hour < 17) return SemanticTimeBand.afternoon;
    if (hour >= 17 && hour < 19) return SemanticTimeBand.dusk;
    if (hour >= 19 && hour < 20) return SemanticTimeBand.goldenHour;
    if (hour >= 20 || hour < 5) return SemanticTimeBand.night;
    return SemanticTimeBand.unknown;
  }

  WhyEvidenceSourceKernel _reasonKernel(RecommendationReason reason) {
    return switch (reason) {
      RecommendationReason.categoryPreference => WhyEvidenceSourceKernel.what,
      RecommendationReason.localityPreference ||
      RecommendationReason.crossLocality =>
        WhyEvidenceSourceKernel.where,
      RecommendationReason.scopePreference ||
      RecommendationReason.localExpert =>
        WhyEvidenceSourceKernel.who,
      RecommendationReason.eventTypePreference => WhyEvidenceSourceKernel.what,
      RecommendationReason.matchingScore => WhyEvidenceSourceKernel.social,
      RecommendationReason.exploration => WhyEvidenceSourceKernel.how,
      RecommendationReason.combined => WhyEvidenceSourceKernel.model,
    };
  }

  double _reasonWeight(RecommendationReason reason) {
    return switch (reason) {
      RecommendationReason.categoryPreference => 0.78,
      RecommendationReason.localityPreference => 0.72,
      RecommendationReason.scopePreference => 0.68,
      RecommendationReason.eventTypePreference => 0.65,
      RecommendationReason.localExpert => 0.74,
      RecommendationReason.matchingScore => 0.7,
      RecommendationReason.exploration => 0.52,
      RecommendationReason.crossLocality => 0.6,
      RecommendationReason.combined => 0.8,
    };
  }

  bool _meaningfulEvidence(WhyEvidence evidence) {
    return evidence.weight > 0;
  }

  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) {
      return null;
    }
    return location.split(',').first.trim();
  }

  ExpressionAudience _expressionAudienceFor(String perspective) {
    return switch (perspective) {
      'agent' => ExpressionAudience.agent,
      'admin' => ExpressionAudience.admin,
      'governance' => ExpressionAudience.governance,
      _ => ExpressionAudience.userSafe,
    };
  }

  List<String> _allowedClaims({
    required EventRecommendation recommendation,
    required WhySnapshot explanation,
    String? governedLearningClaim,
  }) {
    final claims = <String>[
      recommendation.reasonDisplayText,
      if (recommendation.isHighlyRelevant)
        'This is a strong fit for you right now.'
      else if (recommendation.isModeratelyRelevant)
        'This looks like a plausible fit for you right now.'
      else
        'This is a lower-confidence option being shown carefully.',
      if ((recommendation.event.location ?? '').isNotEmpty)
        'The event is in ${recommendation.event.location}.',
      if (recommendation.isExploration)
        'AVRAI is using this as a controlled exploration door.',
      if (governedLearningClaim != null) governedLearningClaim,
      if (governedLearningClaim == null && explanation.drivers.isNotEmpty)
        'The strongest signal is ${explanation.drivers.first.label}.',
      if (explanation.drivers.length > 1)
        'A second supporting signal is ${explanation.drivers[1].label}.',
    ];
    return claims.toSet().toList(growable: false);
  }

  Future<List<WhyEvidence>> _loadGovernedLearningEvidence({
    required UnifiedUser user,
    required EventRecommendation recommendation,
  }) async {
    final usageService = _userGovernedLearningUsageService;
    if (usageService == null) {
      return const <WhyEvidence>[];
    }
    List<GovernedLearningUsageReceipt> relevantReceipts;
    try {
      final receipts = await usageService.listReceiptsForUser(
        ownerUserId: user.id,
      );
      relevantReceipts = receipts
          .where(
            (receipt) =>
                receipt.targetEntityId == recommendation.event.id &&
                receipt.targetEntityType == 'event',
          )
          .toList(growable: false)
        ..sort((left, right) => right.usedAtUtc.compareTo(left.usedAtUtc));
    } catch (_) {
      return const <WhyEvidence>[];
    }
    if (relevantReceipts.isEmpty) {
      return const <WhyEvidence>[];
    }

    final projectionService = _userGovernedLearningProjectionService;
    final recordsByEnvelopeId = <String, UserVisibleGovernedLearningRecord>{};
    if (projectionService != null) {
      try {
        final visibleRecords = await projectionService.listVisibleRecords(
          ownerUserId: user.id,
          limit: 20,
        );
        for (final record in visibleRecords) {
          recordsByEnvelopeId[record.envelopeId] = record;
        }
      } catch (_) {
        // Receipt-backed evidence is still useful even if the projection layer
        // cannot recover the visible record in this moment.
      }
    }

    return relevantReceipts.take(2).map((receipt) {
      final record = recordsByEnvelopeId[receipt.envelopeId];
      final label = _buildGovernedLearningEvidenceLabel(
        receipt: receipt,
        record: record,
      );
      return WhyEvidence(
        id: 'governed_learning_${receipt.id}',
        label: label,
        weight: _governedLearningEvidenceWeight(
          receipt: receipt,
          record: record,
        ),
        polarity: WhyEvidencePolarity.positive,
        sourceKernel: WhyEvidenceSourceKernel.memory,
        sourceSubsystem: 'governed_learning_usage',
        durability:
            record?.requiresHumanReview == true ? 'transient' : 'durable',
        confidence: _governedLearningEvidenceConfidence(
          receipt: receipt,
          record: record,
        ),
        observed: true,
        inferred: false,
        provenance: receipt.surface,
        timeRef: receipt.usedAtUtc.toUtc().toIso8601String(),
        subjectRef: recommendation.event.id,
        scope: (receipt.domainLabel.isNotEmpty
                ? receipt.domainLabel
                : receipt.domainId)
            .toLowerCase(),
        tags: <String>[
          receipt.decisionFamily,
          if ((receipt.surface ?? '').isNotEmpty) receipt.surface!,
          if (record != null) record.convictionTier,
        ],
      );
    }).toList(growable: false);
  }

  String _buildGovernedLearningEvidenceLabel({
    required GovernedLearningUsageReceipt receipt,
    UserVisibleGovernedLearningRecord? record,
  }) {
    final domain = _humanizeGovernedDomain(
      receipt.domainLabel.isNotEmpty ? receipt.domainLabel : receipt.domainId,
    );
    final summary = _humanizeGovernedLearningSummary(record?.safeSummary) ??
        _humanizeGovernedLearningSummary(
          _extractSummaryFromInfluenceReason(receipt.influenceReason),
        );
    if (summary != null) {
      return 'A recent signal that $summary also boosted this recommendation.';
    }
    return 'A recent $domain preference signal also boosted this recommendation.';
  }

  double _governedLearningEvidenceWeight({
    required GovernedLearningUsageReceipt receipt,
    UserVisibleGovernedLearningRecord? record,
  }) {
    final base = record == null
        ? 0.86
        : switch (record.convictionTier) {
            'explicit_correction_signal' => 0.92,
            'ai2ai_explicit_correction_signal' => 0.9,
            'recommendation_feedback_correction_signal' => 0.89,
            'personal_agent_human_observation' => 0.84,
            'onboarding_declared_preference' => 0.86,
            _ => 0.82,
          };
    final influenceFloor = switch (receipt.influenceKind) {
      GovernedLearningUsageInfluenceKind.boost => 0.87,
      GovernedLearningUsageInfluenceKind.reference => 0.85,
      GovernedLearningUsageInfluenceKind.suppress => 0.82,
    };
    final reviewPenalty = record?.requiresHumanReview == true ? 0.02 : 0.0;
    final weighted = (base +
            (receipt.influenceScoreDelta.clamp(0.0, 0.12) * 0.6) -
            reviewPenalty)
        .clamp(0.0, 0.95);
    return weighted < influenceFloor ? influenceFloor : weighted;
  }

  double _governedLearningEvidenceConfidence({
    required GovernedLearningUsageReceipt receipt,
    UserVisibleGovernedLearningRecord? record,
  }) {
    final base = record?.requiresHumanReview == true ? 0.72 : 0.82;
    return (base + receipt.influenceScoreDelta.clamp(0.0, 0.12))
        .clamp(0.0, 0.95);
  }

  String? _governedLearningClaim(WhySnapshot explanation) {
    for (final driver in explanation.drivers) {
      if (driver.kernel != WhyEvidenceSourceKernel.memory) {
        continue;
      }
      if ((driver.source ?? '') != 'governed_learning_usage') {
        continue;
      }
      return driver.label;
    }
    return null;
  }

  String _humanizeGovernedDomain(String raw) {
    final normalized =
        raw.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return 'local';
    }
    return normalized.toLowerCase();
  }

  String? _humanizeGovernedLearningSummary(String? summary) {
    final trimmed = summary?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    const replacements = <MapEntry<String, String>>[
      MapEntry('The user wants ', 'you wanted '),
      MapEntry('The user prefers ', 'you preferred '),
      MapEntry('The user likes ', 'you liked '),
      MapEntry('The user does not like ', 'you did not like '),
      MapEntry('The user reacted ', 'you reacted '),
      MapEntry('The user said ', 'you said '),
      MapEntry('The user asked ', 'you asked '),
      MapEntry('The user corrected ', 'you corrected '),
    ];
    for (final replacement in replacements) {
      if (trimmed.startsWith(replacement.key)) {
        return _ensureSentenceFragment(
          replacement.value + trimmed.substring(replacement.key.length),
        );
      }
    }
    return _ensureSentenceFragment(trimmed);
  }

  String _ensureSentenceFragment(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('.')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String? _extractSummaryFromInfluenceReason(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final aboutIndex = normalized.toLowerCase().indexOf('about ');
    if (aboutIndex < 0) {
      return null;
    }
    final start = aboutIndex + 'about '.length;
    final lower = normalized.toLowerCase();
    final endCandidates = <int>[
      lower.indexOf(' helped', start),
      lower.indexOf(' boosted', start),
    ].where((index) => index > start).toList(growable: false);
    final end = endCandidates.isEmpty
        ? normalized.length
        : endCandidates.reduce((left, right) => left < right ? left : right);
    final extracted = normalized.substring(start, end).trim();
    return extracted.isEmpty ? null : extracted;
  }

  List<String> _forbiddenClaims({
    required EventRecommendation recommendation,
    required WhySnapshot explanation,
    required String perspective,
  }) {
    final claims = <String>[
      'The host is definitely your best match.',
      'This outcome is guaranteed.',
    ];
    if (perspective == 'user_safe' && explanation.governanceEnvelope.redacted) {
      claims.add('Internal kernel traces are visible here.');
    }
    if ((recommendation.event.location ?? '').isEmpty) {
      claims.add('The event location is known.');
    }
    return claims;
  }

  List<String> _evidenceRefs(WhySnapshot explanation) {
    return explanation.traceRefs
        .map((entry) => [
              entry.kernel.toWireValue(),
              entry.traceType,
              entry.entityId,
              entry.eventId,
              entry.timeRef,
              entry.explanationRef,
            ].whereType<String>().join(':'))
        .toList(growable: false);
  }

  String _confidenceBand(double recommendationScore, double whyConfidence) {
    final effective =
        ((recommendationScore + whyConfidence) / 2).clamp(0.0, 1.0);
    if (effective >= 0.75) return 'high';
    if (effective >= 0.45) return 'medium';
    return 'low';
  }

  String? _uncertaintyNotice(WhySnapshot explanation) {
    if (explanation.ambiguity >= 0.55 || explanation.confidence < 0.45) {
      return 'AVRAI is keeping this explanation cautious because the signal is not fully settled.';
    }
    if (explanation.governanceEnvelope.redacted) {
      return 'Some internal traces are intentionally hidden in this user-safe explanation.';
    }
    return null;
  }

  String _toneProfileFor(WhySnapshot explanation) {
    if (explanation.governanceEnvelope.redacted) {
      return 'clear_cautious';
    }
    if (explanation.confidence >= 0.75) {
      return 'clear_direct';
    }
    return 'clear_calm';
  }
}
