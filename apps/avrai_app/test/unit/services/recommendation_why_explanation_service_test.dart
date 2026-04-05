import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/events/event_recommendation.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    as kernel_models;
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_why_explanation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/integration_test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('RecommendationWhyExplanationService', () {
    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() async {
      await StorageService.instance.clear();
      await StorageService.instance.clear(box: 'spots_user');
      await StorageService.instance.clear(box: 'spots_ai');
      await StorageService.instance.clear(box: 'spots_analytics');
    });

    final service = RecommendationWhyExplanationService(
      expressionKernelService: _TestExpressionKernelService(),
    );

    test('explains a strong local recommendation with canonical why fields',
        () {
      final user = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'user-1',
        category: 'food',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-1',
        host: user,
        category: 'food',
      ).copyWith(location: 'Austin, TX');

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.86,
        reason: RecommendationReason.categoryPreference,
        preferenceMatch: const PreferenceMatchDetails(
          categoryMatch: 0.92,
          localityMatch: 0.81,
          scopeMatch: 0.7,
          eventTypeMatch: 0.68,
          localExpertMatch: 0.66,
        ),
        isExploration: false,
        generatedAt: DateTime.utc(2026, 3, 7, 9),
      );

      final snapshot = service.explainRecommendation(
        user: user,
        recommendation: recommendation,
      );

      expect(snapshot.queryKind, WhyQueryKind.recommendation);
      expect(snapshot.rootCauseType, isNot(WhyRootCauseType.unknown));
      expect(
          snapshot.traceRefs.map((entry) => entry.kernel),
          containsAll(<WhyEvidenceSourceKernel>[
            WhyEvidenceSourceKernel.when,
            WhyEvidenceSourceKernel.how,
          ]));
      expect(snapshot.drivers, isNotEmpty);
      expect(snapshot.summary, contains('recommend_event'));
    });

    test('redacts user-safe recommendation explanations', () {
      final user = IntegrationTestHelpers.createUserWithoutHosting(
        id: 'user-2',
      );
      final host = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'music',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-2',
        host: host,
        category: 'music',
      ).copyWith(location: 'Dallas, TX');

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.51,
        reason: RecommendationReason.exploration,
        preferenceMatch: const PreferenceMatchDetails(
          categoryMatch: 0.32,
          localityMatch: 0.2,
          scopeMatch: 0.41,
          eventTypeMatch: 0.38,
          localExpertMatch: 0.3,
        ),
        isExploration: true,
        generatedAt: DateTime.utc(2026, 3, 7, 20),
      );

      final snapshot = service.explainRecommendation(
        user: user,
        recommendation: recommendation,
        perspective: 'user_safe',
      );

      expect(snapshot.governanceEnvelope.redacted, isTrue);
      expect(snapshot.traceRefs, isEmpty);
      expect(snapshot.counterfactuals, isNotEmpty);
    });

    test('enriches recommendation explanations from headless kernel context',
        () async {
      final host = _FakeHeadlessAvraiOsHost();
      final service = RecommendationWhyExplanationService(
        headlessOsHost: host,
        expressionKernelService: _TestExpressionKernelService(),
      );
      final user = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'user-3',
        category: 'food',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-3',
        host: user,
        category: 'food',
      ).copyWith(location: 'Austin, TX');

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.88,
        reason: RecommendationReason.localityPreference,
        preferenceMatch: const PreferenceMatchDetails(
          categoryMatch: 0.9,
          localityMatch: 0.84,
          scopeMatch: 0.66,
          eventTypeMatch: 0.61,
          localExpertMatch: 0.7,
        ),
        generatedAt: DateTime.utc(2026, 3, 7, 11),
      );

      final snapshot = await service.explainRecommendationWithKernelContext(
        user: user,
        recommendation: recommendation,
      );

      expect(host.startCount, 1);
      expect(host.runtimeExecutionCount, 1);
      expect(host.governanceInspectionCount, 1);
      expect(
        snapshot.traceRefs.map((entry) => entry.kernel),
        containsAll(<WhyEvidenceSourceKernel>[
          WhyEvidenceSourceKernel.where,
          WhyEvidenceSourceKernel.how,
          WhyEvidenceSourceKernel.when,
        ]),
      );
      expect(
        snapshot.drivers.any(
          (entry) =>
              entry.label.contains('personal vibe') ||
              entry.label.contains('geographic vibe') ||
              entry.label.contains('scoped context') ||
              entry.label.contains('entity vibe'),
        ),
        isTrue,
      );
    });

    test(
        'builds a grounded expression artifact for user-safe recommendation copy',
        () {
      final user = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'user-4',
        category: 'food',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-4',
        host: user,
        category: 'food',
      ).copyWith(location: 'Austin, TX');

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.84,
        reason: RecommendationReason.categoryPreference,
        preferenceMatch: const PreferenceMatchDetails(
          categoryMatch: 0.91,
          localityMatch: 0.76,
          scopeMatch: 0.69,
          eventTypeMatch: 0.63,
          localExpertMatch: 0.7,
        ),
        generatedAt: DateTime.utc(2026, 3, 7, 12),
      );

      final artifact = service.expressRecommendation(
        user: user,
        recommendation: recommendation,
        perspective: 'user_safe',
      );

      expect(artifact.validation.valid, isTrue);
      expect(artifact.plan.allowedClaims, isNotEmpty);
      expect(
        artifact.rendered.text,
        contains('Matches your interest in food'),
      );
      expect(
        artifact.plan.adaptationProfileRef,
        'recommendation_explanation:user-4',
      );
    });

    test(
        'surfaces governed learning memory evidence in user-safe recommendation explanations',
        () async {
      final repository = UniversalIntakeRepository();
      final usageService = UserGovernedLearningUsageService(
        storageService: StorageService.instance,
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        usageService: usageService,
      );
      final upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final service = RecommendationWhyExplanationService(
        expressionKernelService: _TestExpressionKernelService(),
        userGovernedLearningProjectionService: projectionService,
        userGovernedLearningUsageService: usageService,
      );

      final user = IntegrationTestHelpers.createUserWithoutHosting(
        id: 'user-5',
      );
      final host = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-5',
        category: 'music',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-5',
        host: host,
        category: 'music',
      ).copyWith(
        title: 'Austin After Dark',
        location: 'Austin, TX',
      );

      final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
        ownerUserId: user.id,
        actorAgentId: 'agent-user-5',
        chatId: 'chat-5',
        messageId: 'message-nightlife-5',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 1),
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: DateTime.now().toUtc(),
          sanitizedPayload: <String, dynamic>{
            'sourceKind': 'personal_agent_human_intake',
            'sourceScope': 'human',
            'sourceOccurredAtUtc': '2026-04-05T01:00:00.000Z',
            'chatId': 'chat-5',
            'messageId': 'message-nightlife-5',
          },
          pseudonymousActorRef: 'anon_user',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants louder nightlife scenes.',
          'sanitized_summary': 'The user wants louder nightlife scenes.',
          'referenced_entities': <String>['Austin After Dark', 'nightlife'],
          'accepted': true,
          'learning_allowed': true,
        },
      );

      await usageService.recordReceipts([
        GovernedLearningUsageReceipt(
          id: 'usage_receipt_event_5',
          ownerUserId: user.id,
          envelopeId: intakeResult.envelope.id,
          sourceId: intakeResult.sourceId,
          decisionFamily: 'event_recommendation',
          decisionId: 'decision_event_5',
          domainId: 'nightlife',
          domainLabel: 'Nightlife',
          targetEntityId: event.id,
          targetEntityType: 'event',
          targetEntityTitle: event.title,
          usedAtUtc: DateTime.utc(2026, 4, 5, 2),
          influenceKind: GovernedLearningUsageInfluenceKind.boost,
          influenceScoreDelta: 0.08,
          influenceReason:
              'Governed learning about louder nightlife scenes boosted this event.',
          surface: 'events_personalized',
        ),
      ]);
      final storedReceipts = await usageService.listReceiptsForUser(
        ownerUserId: user.id,
      );
      expect(
        storedReceipts,
        isNotEmpty,
        reason: 'expected receipt to be persisted before explanation build',
      );

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.82,
        reason: RecommendationReason.categoryPreference,
        preferenceMatch: const PreferenceMatchDetails(
          categoryMatch: 0.88,
          localityMatch: 0.74,
          scopeMatch: 0.62,
          eventTypeMatch: 0.58,
          localExpertMatch: 0.61,
        ),
        generatedAt: DateTime.utc(2026, 4, 5, 2),
      );

      final snapshot = await service.explainRecommendationWithKernelContext(
        user: user,
        recommendation: recommendation,
        perspective: 'user_safe',
      );
      final artifact = await service.expressRecommendationWithKernelContext(
        user: user,
        recommendation: recommendation,
        perspective: 'user_safe',
      );

      expect(
        snapshot.drivers.any(
          (entry) =>
              entry.kernel == WhyEvidenceSourceKernel.memory &&
              entry.label.contains('you wanted louder nightlife scenes'),
        ),
        isTrue,
      );
      expect(
        artifact.rendered.text,
        contains(
          'A recent signal that you wanted louder nightlife scenes also boosted this recommendation.',
        ),
      );
    });
  });
}

class _TestExpressionKernelService extends ExpressionKernelService {
  _TestExpressionKernelService();

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
        ExpressionSection(kind: 'body', text: allowedClaims.join(' ')),
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
      fallbackRequired:
          forbiddenHits.isNotEmpty || unsupportedClaims.isNotEmpty,
    );
  }
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCount = 0;
  int runtimeExecutionCount = 0;
  int governanceInspectionCount = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCount += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'test host',
    );
  }

  @override
  Future<kernel_models.RealityKernelFusionInput> buildModelTruth({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<kernel_models.KernelHealthReport>> healthCheck() async =>
      const <kernel_models.KernelHealthReport>[];

  @override
  Future<kernel_models.KernelGovernanceReport> inspectGovernance({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    governanceInspectionCount += 1;
    return kernel_models.KernelGovernanceReport(
      envelope: envelope,
      bundle: _bundle,
      projections: const <kernel_models.KernelGovernanceProjection>[
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.where,
          summary: 'locality contained in where',
          confidence: 0.9,
        ),
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.how,
          summary: 'recommendation pipeline path',
          confidence: 0.82,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7),
    );
  }

  @override
  Future<kernel_models.KernelContextBundle> resolveRuntimeExecution({
    required kernel_models.KernelEventEnvelope envelope,
  }) async {
    runtimeExecutionCount += 1;
    return _bundle;
  }

  kernel_models.KernelContextBundle get _bundle =>
      kernel_models.KernelContextBundle(
        who: const kernel_models.WhoKernelSnapshot(
          primaryActor: 'user-3',
          affectedActor: 'user-3',
          companionActors: <String>[],
          actorRoles: <String>['user'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.9,
        ),
        what: const kernel_models.WhatKernelSnapshot(
          actionType: 'recommend_event',
          targetEntityType: 'event',
          targetEntityId: 'event-3',
          stateTransitionType: 'generated',
          outcomeType: 'generated',
          semanticTags: <String>['recommendation'],
          taxonomyConfidence: 0.88,
        ),
        when: kernel_models.WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 11),
          freshness: 1.0,
          recencyBucket: 'current',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.94,
        ),
        where: const kernel_models.WhereKernelSnapshot(
          localityToken: 'where:austin',
          cityCode: 'aus',
          localityCode: 'austin',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.05,
          spatialConfidence: 0.92,
          travelFriction: 0.15,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const kernel_models.HowKernelSnapshot(
          executionPath: 'event_recommendation_pipeline',
          workflowStage: 'ranking',
          transportMode: 'in_process',
          plannerMode: 'event_recommendation',
          modelFamily: 'event_recommendation',
          interventionChain: <String>['match', 'preference_score', 'rank'],
          failureMechanism: 'none',
          mechanismConfidence: 0.83,
        ),
        vibe: _vibeSnapshot(
          subjectId: 'agent-user-3',
          subjectKind: 'personal_agent',
          confidence: 0.96,
          affectiveLabel: 'engaged',
        ),
        vibeStack: HierarchicalVibeStack(
          primarySnapshot: _vibeSnapshot(
            subjectId: 'agent-user-3',
            subjectKind: 'personal_agent',
            confidence: 0.96,
            affectiveLabel: 'engaged',
          ),
          geographicSnapshots: <VibeStateSnapshot>[
            _vibeSnapshot(
              subjectId: 'locality-agent:austin',
              subjectKind: 'geographic_agent',
              confidence: 0.93,
              affectiveLabel: 'local',
            ),
            _vibeSnapshot(
              subjectId: 'city-agent:aus',
              subjectKind: 'geographic_agent',
              confidence: 0.9,
              affectiveLabel: 'city',
            ),
          ],
          geographicBinding: GeographicVibeBinding(
            localityRef: VibeSubjectRef.locality('austin'),
            stableKey: 'austin',
            cityCode: 'aus',
            regionCode: 'tx',
            globalCode: 'earth',
          ),
          scopedBindings: <ScopedVibeBinding>[
            ScopedVibeBinding(
              contextRef: VibeSubjectRef.scoped(
                scopedId: 'scene:austin:food',
                scopedKind: ScopedAgentKind.scene,
              ),
              scopedKind: ScopedAgentKind.scene,
              anchorGeographicRef: VibeSubjectRef.locality('austin'),
            ),
          ],
          activeLocalitySnapshot: _vibeSnapshot(
            subjectId: 'locality-agent:austin',
            subjectKind: 'geographic_agent',
            confidence: 0.93,
            affectiveLabel: 'local',
          ),
          higherAgentSnapshots: <VibeStateSnapshot>[
            _vibeSnapshot(
              subjectId: 'city-agent:aus',
              subjectKind: 'geographic_agent',
              confidence: 0.9,
              affectiveLabel: 'city',
            ),
            _vibeSnapshot(
              subjectId: 'global-agent:earth',
              subjectKind: 'geographic_agent',
              confidence: 0.87,
              affectiveLabel: 'global',
            ),
          ],
          scopedContextSnapshots: <VibeStateSnapshot>[
            _vibeSnapshot(
              subjectId: 'scene:austin:food',
              subjectKind: 'scoped_agent',
              confidence: 0.95,
              affectiveLabel: 'scene',
            ),
          ],
          selectedEntitySnapshots: <EntityVibeSnapshot>[
            EntityVibeSnapshot(
              entityId: 'event-3',
              entityType: 'event',
              vibe: _vibeSnapshot(
                subjectId: 'event-3',
                subjectKind: 'entity',
                confidence: 0.94,
                affectiveLabel: 'entity',
              ),
            ),
          ],
        ),
        why: kernel_models.WhyKernelSnapshot(
          goal: 'explain_event_recommendation',
          summary: 'kernel explanation context',
          rootCauseType: kernel_models.WhyRootCauseType.locality,
          confidence: 0.9,
          drivers: const <kernel_models.WhySignal>[],
          inhibitors: const <kernel_models.WhySignal>[],
          counterfactuals: const <kernel_models.WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 7),
        ),
      );
}

VibeStateSnapshot _vibeSnapshot({
  required String subjectId,
  required String subjectKind,
  required double confidence,
  required String affectiveLabel,
}) {
  return VibeStateSnapshot.fromJson(
    <String, dynamic>{
      'subject_id': subjectId,
      'subject_kind': subjectKind,
      'core_dna': <String, dynamic>{
        'dimensions': <String, double>{'exploration_eagerness': 0.71},
        'dimension_confidence': <String, double>{'exploration_eagerness': 0.7},
        'drift_budget_remaining': 0.28,
      },
      'quantum_vibe': <String, dynamic>{
        'amplitudes': <String, double>{'exploration_eagerness': 0.71},
        'phase_alignment': 0.68,
        'coherence': 0.74,
      },
      'pheromones': <String, dynamic>{
        'vectors': <String, double>{'exploration_eagerness': 0.69},
        'decay_rate': 0.08,
        'last_decay_at_utc': DateTime.utc(2026, 3, 7).toIso8601String(),
      },
      'behavior_patterns': <String, dynamic>{
        'pattern_weights': <String, double>{'repeat_attendance': 0.62},
        'observation_count': 3,
        'cadence_hours': 12.0,
      },
      'affective_state': <String, dynamic>{
        'valence': 0.67,
        'arousal': 0.58,
        'dominance': 0.55,
        'label': affectiveLabel,
        'confidence': confidence,
      },
      'knot_invariants': <String, dynamic>{
        'signature': 'test-knot',
        'crossing_number': 3,
        'alexander_polynomial': '1-t+t^2',
        'jones_polynomial': '1-q+q^2',
      },
      'worldsheet': <String, dynamic>{
        'phase_position': 0.4,
        'drift_rate': 0.08,
        'stability': 0.76,
      },
      'string_evolution': <String, dynamic>{
        'mutation_velocity': 0.14,
        'resonance': 0.62,
        'tension': 0.21,
      },
      'decoherence_state': <String, dynamic>{
        'noise_floor': 0.13,
        'signal_purity': 0.82,
        'decoherence_rate': 0.11,
      },
      'expression_context': <String, dynamic>{
        'tone': 'calm',
        'directness': 0.62,
        'warmth': 0.58,
        'verbosity': 0.44,
        'schema_version': 1,
      },
      'confidence': confidence,
      'freshness_hours': 1.5,
      'provenance_tags': <String>['test:canonical_vibe'],
      'updated_at_utc': DateTime.utc(2026, 3, 7, 11).toIso8601String(),
    },
  );
}
