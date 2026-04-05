import 'package:avrai_admin_app/ui/pages/reality_system_oversight_page.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/admin_conversation_style_hydration_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockAdminRuntimeGovernanceService extends Mock
    implements AdminRuntimeGovernanceService {}

class _MockReplaySimulationAdminService extends Mock
    implements ReplaySimulationAdminService {}

class _MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}

class _MockLanguageProfileDiagnosticsService extends Mock
    implements LanguageProfileDiagnosticsService {}

class _NoopLanguageProfileDiagnosticsService
    implements LanguageProfileDiagnosticsService {
  @override
  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForProfileRef(
    String profileRef, {
    int recentEventLimit = 6,
  }) async {
    return null;
  }

  @override
  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForUser(
    String userId, {
    int recentEventLimit = 6,
  }) async {
    return null;
  }
}

class _FakeAdminConversationStyleHydrationService
    extends AdminConversationStyleHydrationService {
  _FakeAdminConversationStyleHydrationService(this.snapshot)
      : super(
          languageDiagnosticsService: _NoopLanguageProfileDiagnosticsService(),
        );

  final AdminConversationStyleSessionSnapshot snapshot;

  @override
  Future<AdminConversationStyleSessionSnapshot?>
      hydrateForCurrentSession() async {
    return snapshot;
  }

  @override
  AdminConversationStyleSessionSnapshot? getCurrentSnapshot() => snapshot;
}

class _FakeRecommendationFeedbackPromptPlannerService
    extends RecommendationFeedbackPromptPlannerService {
  _FakeRecommendationFeedbackPromptPlannerService(this.plans);

  final List<RecommendationFeedbackPromptPlan> plans;

  @override
  Future<List<RecommendationFeedbackPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakePostEventFeedbackPromptPlannerService
    extends PostEventFeedbackPromptPlannerService {
  _FakePostEventFeedbackPromptPlannerService(this.plans);

  final List<PostEventFeedbackPromptPlan> plans;

  @override
  Future<List<PostEventFeedbackPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeCorrectionFollowUpPromptPlannerService
    extends UserGovernedLearningCorrectionFollowUpPromptPlannerService {
  _FakeCorrectionFollowUpPromptPlannerService(this.plans);

  final List<UserGovernedLearningCorrectionFollowUpPlan> plans;

  @override
  Future<List<UserGovernedLearningCorrectionFollowUpPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeOnboardingFollowUpPromptPlannerService
    extends OnboardingFollowUpPromptPlannerService {
  _FakeOnboardingFollowUpPromptPlannerService(this.plans);

  final List<OnboardingFollowUpPromptPlan> plans;

  @override
  Future<List<OnboardingFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeVisitLocalityFollowUpPromptPlannerService
    extends VisitLocalityFollowUpPromptPlannerService {
  _FakeVisitLocalityFollowUpPromptPlannerService(this.plans);

  final List<VisitLocalityFollowUpPromptPlan> plans;

  @override
  Future<List<VisitLocalityFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeCommunityFollowUpPromptPlannerService
    extends CommunityFollowUpPromptPlannerService {
  _FakeCommunityFollowUpPromptPlannerService(this.plans);

  final List<CommunityFollowUpPromptPlan> plans;

  @override
  Future<List<CommunityFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeBusinessOperatorFollowUpPromptPlannerService
    extends BusinessOperatorFollowUpPromptPlannerService {
  _FakeBusinessOperatorFollowUpPromptPlannerService(this.plans);

  final List<BusinessOperatorFollowUpPromptPlan> plans;

  @override
  Future<List<BusinessOperatorFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

class _FakeReservationOperationalFollowUpPromptPlannerService
    extends ReservationOperationalFollowUpPromptPlannerService {
  _FakeReservationOperationalFollowUpPromptPlannerService(this.plans);

  final List<ReservationOperationalFollowUpPromptPlan> plans;

  @override
  Future<List<ReservationOperationalFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    return plans.take(limit).toList(growable: false);
  }
}

void main() {
  group('RealitySystemOversightPage Widget Tests', () {
    late _MockAdminRuntimeGovernanceService governanceService;
    late _MockReplaySimulationAdminService replayService;
    late _MockSignatureHealthAdminService signatureHealthService;
    late _MockLanguageProfileDiagnosticsService languageDiagnosticsService;
    late SignatureHealthSnapshot signatureSnapshot;

    setUp(() {
      governanceService = _MockAdminRuntimeGovernanceService();
      replayService = _MockReplaySimulationAdminService();
      signatureHealthService = _MockSignatureHealthAdminService();
      languageDiagnosticsService = _MockLanguageProfileDiagnosticsService();

      final dashboard = GodModeDashboardData(
        totalUsers: 42,
        activeUsers: 12,
        totalBusinessAccounts: 6,
        activeConnections: 5,
        totalCommunications: 24,
        systemHealth: 0.93,
        aggregatePrivacyMetrics: AggregatePrivacyMetrics(
          meanOverallPrivacyScore: 0.98,
          meanAnonymizationLevel: 0.97,
          meanDataSecurityScore: 0.98,
          meanEncryptionStrength: 0.99,
          meanComplianceRate: 0.98,
          totalPrivacyViolations: 0,
          userCount: 12,
          lastUpdated: DateTime.utc(2026, 3, 31, 12),
        ),
        authMix: AuthMixSummary(
          signupProviderCounts: const <String, int>{},
          lastSignInProviderCounts: AuthMixBucket.empty(),
          lastSignInPlatformCounts: AuthMixBucket.empty(),
        ),
        lastUpdated: DateTime.utc(2026, 3, 31, 12),
      );
      final collaborativeMetrics = CollaborativeActivityMetrics(
        totalCollaborativeLists: 18,
        groupChatLists: 7,
        dmLists: 11,
        avgListSize: 5.2,
        avgCollaboratorCount: 2.1,
        groupSizeDistribution: const <int, int>{2: 11, 3: 5, 4: 2},
        collaborationRate: 0.81,
        totalPlanningSessions: 9,
        avgSessionDuration: 16,
        followThroughRate: 0.74,
        activityByHour: const <int, int>{10: 2, 11: 4, 18: 3},
        collectionStart: DateTime.utc(2026, 3, 1),
        lastUpdated: DateTime.utc(2026, 3, 31, 12),
        measurementWindow: const Duration(days: 30),
        totalUsersContributing: 12,
      );
      final replaySnapshot = ReplaySimulationAdminSnapshot(
        generatedAt: DateTime.utc(2026, 3, 31, 12),
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        scenarios: const <ReplayScenarioPacket>[],
        comparisons: const <ReplayScenarioComparison>[],
        receipts: const <SimulationTruthReceipt>[],
        contradictions: const <ReplayContradictionSnapshot>[],
        localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
        foundation: const ReplaySimulationAdminFoundationSummary(
          simulationMode: 'generic_city_pack',
          intakeFlowRefs: <String>[
            'source_intake_orchestrator',
            'air_gap_normalizer',
          ],
          sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
          metadata: <String, dynamic>{
            'cityPackStructuralRef': 'city_pack:atx_core_2024',
          },
          kernelStates: <ReplaySimulationKernelState>[
            ReplaySimulationKernelState(
              kernelId: 'forecast',
              status: 'active',
              reason: 'Scenario comparisons are present.',
            ),
            ReplaySimulationKernelState(
              kernelId: 'governance',
              status: 'active',
              reason: 'Simulation lineage is attached.',
            ),
          ],
        ),
        learningReadiness: ReplaySimulationLearningReadiness(
          trainingGrade: 'strong',
          shareWithRealityModelAllowed: true,
          reasons: <String>[
            'Structural refs and simulation lineage are present.',
            'Kernel participation is broad enough for bounded learning review.',
          ],
          suggestedTrainingUse: 'bounded_reality_model_review',
          requestPreviews: <ReplaySimulationRealityModelRequestPreview>[
            ReplaySimulationRealityModelRequestPreview(
              request: RealityModelEvaluationRequest(
                requestId: 'share-oversight-1',
                subjectId: 'simulation:atx_downtown',
                domain: RealityModelDomain.locality,
                candidateRef: 'locality:atx_downtown',
                localityCode: 'atx_downtown',
                cityCode: 'atx',
                signalTags: <String>['simulation_bundle'],
                evidenceRefs: <String>[
                  'simulation_snapshot.json#overlay:atx_downtown',
                ],
                requestedAtUtc: DateTime.utc(2026, 3, 31, 12),
              ),
              rationale: 'Use the lead locality as bounded review input.',
            ),
          ],
        ),
      );
      signatureSnapshot = SignatureHealthSnapshot(
        generatedAt: DateTime.utc(2026, 3, 31, 12),
        overview: const SignatureHealthOverview(
          strongCount: 0,
          weakDataCount: 0,
          staleCount: 0,
          fallbackCount: 0,
          reviewNeededCount: 0,
          bundleCount: 0,
          softIgnoreCount: 0,
          hardNotInterestedCount: 0,
        ),
        records: const <SignatureHealthRecord>[],
        reviewQueueCount: 0,
        boundedReviewCandidates: <SignatureHealthBoundedReviewCandidate>[
          SignatureHealthBoundedReviewCandidate(
            environmentId: 'atx-replay-world-2024',
            displayName: 'Austin Simulation Environment 2024',
            cityCode: 'atx',
            replayYear: 2024,
            suggestedAction: 'watch_closely',
            suggestedReason:
                'Recent executed reruns are stable enough for bounded review.',
            selectedAction: 'candidate_for_bounded_review',
            acceptedSuggestion: true,
            updatedAt: DateTime.utc(2026, 3, 31, 12, 5),
            variantId: 'variant-heatwave-lane',
            variantLabel: 'Heatwave mitigation lane',
            cityPackStructuralRef: 'city_pack:atx_core_2024',
            latestOutcomeDisposition: 'accepted',
            latestRerunRequestStatus: 'completed',
            latestRerunJobStatus: 'completed',
          ),
        ],
        learningOutcomeItems: const <SignatureHealthLearningOutcomeItem>[
          SignatureHealthLearningOutcomeItem(
            sourceId: 'simulation_training_source_atx',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            learningPathway: 'deeper_reality_model_training',
            outcomeStatus: 'completed',
            summary: 'Reality-model learning completed locally.',
            adminEvidenceRefreshSnapshotJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
            supervisorLearningFeedbackStateJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
            adminEvidenceRefreshSummary:
                SignatureHealthAdminEvidenceRefreshSummary(
              status: 'executed_local_governed_refresh',
              environmentId: 'atx-replay-world-2024',
              cityCode: 'atx',
              summary:
                  'Admin evidence surfaces refreshed locally from the reality-model learning outcome.',
              requestCount: 1,
              recommendationCount: 1,
              averageConfidence: 0.84,
              jsonPath:
                  '/tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
            ),
            supervisorFeedbackSummary: SignatureHealthSupervisorFeedbackSummary(
              status: 'executed_local_governed_feedback',
              environmentId: 'atx-replay-world-2024',
              feedbackSummary:
                  'Supervisor learning has absorbed the local reality-model outcome and should use it as bounded evidence for later scheduling and recommendation posture.',
              boundedRecommendation:
                  'prefer_similar_reality_model_learning_candidates',
              requestCount: 1,
              recommendationCount: 1,
              averageConfidence: 0.84,
              jsonPath:
                  '/tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
            ),
            propagationTargets: <SignatureHealthPropagationTarget>[
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:locality',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Austin locality domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'locality',
                  summary:
                      'Governed lower-tier `locality` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `locality` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'locality_intelligence_lane',
                    domainId: 'locality',
                    summary:
                        'Locality hierarchy deltas should now refresh bounded locality intelligence consumers so governed reality-model learning can improve locality priors, neighborhood reasoning, and locality-facing explanations.',
                    boundedUse:
                        'Use only for locality-scoped reasoning, prioritization, and explanation consumers; do not turn this into a shortcut for broader citywide retraining.',
                    targetedSystems: <String>[
                      'locality_priors',
                      'locality_reasoning',
                      'locality_explanation_surfaces',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_locality.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:event',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Austin event domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_event.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'event',
                  summary:
                      'Governed lower-tier `event` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `event` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 2,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'event_intelligence_lane',
                    domainId: 'event',
                    summary:
                        'Event hierarchy deltas should now refresh bounded event intelligence consumers so governed reality-model learning can improve event priors, timing reasoning, and event-facing explanations.',
                    boundedUse:
                        'Use only for event-scoped timing, ranking, and explanation consumers; do not generalize this into broad world-model retraining.',
                    targetedSystems: <String>[
                      'event_priors',
                      'event_timing_reasoning',
                      'event_explanation_surfaces',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_event.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_event.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:place',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Austin place domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_place.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'place',
                  summary:
                      'Governed lower-tier `place` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `place` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'place_intelligence_lane',
                    domainId: 'place',
                    summary:
                        'Place hierarchy deltas should now refresh bounded place intelligence consumers so governed reality-model learning can improve place priors, availability reasoning, and place-facing explanations.',
                    boundedUse:
                        'Use only for place-scoped reasoning, availability, and explanation consumers; do not treat this as a shortcut for broader locality or citywide retraining.',
                    targetedSystems: <String>[
                      'place_priors',
                      'place_availability_reasoning',
                      'place_explanation_surfaces',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_place.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_place.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:community',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Austin community domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_community.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'community',
                  summary:
                      'Governed lower-tier `community` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `community` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'community_coordination_lane',
                    domainId: 'community',
                    summary:
                        'Community hierarchy deltas should now refresh bounded community coordination consumers so governed reality-model learning can improve community priors, moderation context, and collaboration guidance.',
                    boundedUse:
                        'Use only for community-scoped coordination, moderation-context, and explanation consumers; do not generalize this into broad social-policy retraining.',
                    targetedSystems: <String>[
                      'community_coordination_priors',
                      'community_moderation_context',
                      'community_explanation_surfaces',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_community.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_community.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:business',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Austin business domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_business.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'business',
                  summary:
                      'Governed lower-tier `business` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `business` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'business_intelligence_lane',
                    domainId: 'business',
                    summary:
                        'Business hierarchy deltas should now refresh bounded business intelligence consumers so governed reality-model learning can improve business-facing priors, explanations, and account guidance.',
                    boundedUse:
                        'Use only for business-scoped recommendation, explanation, and account-support consumers; do not generalize this into broader commercial policy or citywide retraining.',
                    targetedSystems: <String>[
                      'business_account_guidance',
                      'business_recommendation_priors',
                      'business_explanation_surfaces',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_business.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_business.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:list',
                propagationKind: 'prior_and_explanation_delta',
                reason: 'Austin list domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_list.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'list',
                  summary:
                      'Governed lower-tier `list` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `list` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  downstreamConsumerSummary:
                      SignatureHealthDomainConsumerSummary(
                    status: 'executed_local_governed_domain_consumer_refresh',
                    consumerId: 'list_curation_lane',
                    domainId: 'list',
                    summary:
                        'List hierarchy deltas should now refresh bounded list curation consumers so governed reality-model learning can improve ranking, explanation, and watchlist-priority behavior.',
                    boundedUse:
                        'Use only for list-scoped curation, ranking, and explanation consumers; do not treat this as a shortcut for retraining unrelated discovery or world-model systems.',
                    targetedSystems: <String>[
                      'list_curation_priors',
                      'list_explanation_surfaces',
                      'watchlist_priority_refresh',
                    ],
                    jsonPath:
                        '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_list.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_list.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:locality',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Austin personal-agent locality personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_locality.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'locality',
                  summary:
                      'The personal agent may now personalize the governed `locality` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `locality` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_locality.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:place',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Austin personal-agent place personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_place.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'place',
                  summary:
                      'The personal agent may now personalize the governed `place` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `place` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_place.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:business',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Austin personal-agent business personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_business.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'business',
                  summary:
                      'The personal agent may now personalize the governed `business` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `business` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_business.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:list',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Austin personal-agent list personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_list.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'atx-replay-world-2024',
                  domainId: 'list',
                  summary:
                      'The personal agent may now personalize the governed `list` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `list` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.84,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_list.json',
                ),
              ),
            ],
          ),
        ],
        upwardLearningItems: const <SignatureHealthUpwardLearningItem>[
          SignatureHealthUpwardLearningItem(
            sourceId: 'upward_learning_source_atx_user_123_msg_1',
            sourceKind: 'personal_agent_human_intake',
            learningDirection: 'upward_personal_agent_to_reality_model',
            learningPathway: 'governed_upward_reality_model_learning',
            convictionTier: 'personal_agent_human_observation',
            status: 'integrated_as_bounded_local_reality_model_update',
            summary:
                'A bounded Austin upward conviction was validated and released back into governed lower-tier lanes.',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            hierarchyPath: <String>[
              'human',
              'personal_agent',
              'reality_model_agent'
            ],
            upwardDomainHints: <String>['community', 'place'],
            upwardReferencedEntities: <String>[
              'heatwave mitigation lane',
              'recommendation:spot_123',
            ],
            upwardQuestions: <String>[
              'Does this validation result justify promoting a place-level conviction beyond the current replay context?',
            ],
            followUpPromptQuestion:
                'What made the cooling strategy feel like a real improvement?',
            followUpResponseText:
                'It made the venue feel calmer and easier to stay in longer.',
            followUpCompletionMode: 'assistant_follow_up_chat',
            upwardSignalTags: <String>[
              'source:simulation_validation',
              'domain:place',
              'signal:positive_outcome',
            ],
            upwardPreferenceSignals: <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'place_affinity',
                'value': 'cool_indoor_spaces',
                'weight': 0.91,
              },
            ],
            realityModelUpdateDownstreamRepropagationPlanJsonPath:
                '/tmp/AVRAI/upward_learning_bundles/atx/reality_model_update_downstream_repropagation_plan.json',
            realityModelUpdateDownstreamRepropagationOutcomeJsonPath:
                '/tmp/AVRAI/upward_learning_bundles/atx/reality_model_update_downstream_repropagation_outcome.json',
            downstreamRepropagationResolution: 'approve',
            downstreamRepropagationReleasedTargetIds: <String>[
              'admin:atx-replay-world-2024',
              'supervisor:atx-replay-world-2024',
              'hierarchy:community',
              'hierarchy:place',
            ],
          ),
        ],
      );

      when(() => governanceService.getDashboardData())
          .thenAnswer((_) async => dashboard);
      when(() => governanceService.getAggregatePrivacyMetrics())
          .thenAnswer((_) async => dashboard.aggregatePrivacyMetrics);
      when(() => governanceService.getCollaborativeActivityMetrics())
          .thenAnswer((_) async => collaborativeMetrics);
      when(() => replayService.listEnvironments()).thenReturn(
        const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'atx-replay-world-2024',
            displayName: 'Austin Simulation Environment 2024',
            cityCode: 'atx',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
          ),
        ],
      );
      when(
        () => replayService.getSnapshot(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer((_) async => replaySnapshot);
      when(() => signatureHealthService.getSnapshot())
          .thenAnswer((_) async => signatureSnapshot);
      when(
        () => replayService.recordLabTargetActionDecision(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
          suggestedAction: any(named: 'suggestedAction'),
          suggestedReason: any(named: 'suggestedReason'),
          selectedAction: any(named: 'selectedAction'),
        ),
      ).thenAnswer((invocation) async {
        final selectedAction =
            invocation.namedArguments[#selectedAction] as String;
        final suggestedAction =
            invocation.namedArguments[#suggestedAction] as String;
        final suggestedReason =
            invocation.namedArguments[#suggestedReason] as String;
        final variantId = invocation.namedArguments[#variantId] as String?;
        final normalizedVariantId =
            variantId?.trim().isEmpty == true ? null : variantId?.trim();
        final updatedAt = DateTime.utc(2026, 3, 31, 12, 10);
        final nextCandidates = selectedAction == 'candidate_for_bounded_review'
            ? <SignatureHealthBoundedReviewCandidate>[
                SignatureHealthBoundedReviewCandidate(
                  environmentId: 'atx-replay-world-2024',
                  displayName: 'Austin Simulation Environment 2024',
                  cityCode: 'atx',
                  replayYear: 2024,
                  suggestedAction: suggestedAction,
                  suggestedReason: suggestedReason,
                  selectedAction: selectedAction,
                  acceptedSuggestion: selectedAction == suggestedAction,
                  updatedAt: updatedAt,
                  variantId: normalizedVariantId,
                  variantLabel: 'Heatwave mitigation lane',
                  cityPackStructuralRef: 'city_pack:atx_core_2024',
                  latestOutcomeDisposition: 'accepted',
                  latestRerunRequestStatus: 'completed',
                  latestRerunJobStatus: 'completed',
                ),
              ]
            : const <SignatureHealthBoundedReviewCandidate>[];
        signatureSnapshot = SignatureHealthSnapshot(
          generatedAt: updatedAt,
          overview: signatureSnapshot.overview,
          records: signatureSnapshot.records,
          reviewQueueCount: signatureSnapshot.reviewQueueCount,
          reviewItems: signatureSnapshot.reviewItems,
          boundedReviewCandidates: nextCandidates,
          learningOutcomeItems: signatureSnapshot.learningOutcomeItems,
        );
        return ReplaySimulationLabRuntimeState(
          environmentId: 'atx-replay-world-2024',
          updatedAt: updatedAt,
          targetActionDecisions: <ReplaySimulationLabTargetActionDecision>[
            ReplaySimulationLabTargetActionDecision(
              environmentId: 'atx-replay-world-2024',
              updatedAt: updatedAt,
              suggestedAction: suggestedAction,
              suggestedReason: suggestedReason,
              selectedAction: selectedAction,
              acceptedSuggestion: selectedAction == suggestedAction,
              variantId: normalizedVariantId,
              variantLabel: 'Heatwave mitigation lane',
            ),
          ],
        );
      });
      when(
        () => replayService.exportLearningBundle(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationLearningBundleExport(
          environmentId: 'atx-replay-world-2024',
          bundleRoot:
              '/tmp/AVRAI/simulation_learning_bundles/atx/20260331T120000Z',
          snapshotJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/20260331T120000Z/simulation_snapshot.json',
          learningBundleJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/20260331T120000Z/simulation_learning_bundle.json',
          realityModelRequestJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/20260331T120000Z/reality_model_request_previews.json',
          readmePath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/20260331T120000Z/README.md',
          exportedAt: DateTime.utc(2026, 3, 31, 12),
          shareWithRealityModelAllowed: true,
        ),
      );
      when(
        () => replayService.shareLearningBundleWithRealityModel(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationRealityModelShareReport(
          environmentId: 'atx-replay-world-2024',
          bundleRoot: '/tmp/AVRAI/simulation_learning_bundles/atx',
          reviewJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_share_review.json',
          sharedAt: DateTime.utc(2026, 3, 31, 12),
          contractId: 'reality_model_wave1_bham_beta',
          contractVersion: '2026.03-wave1',
          requestCount: 1,
          recommendationCount: 1,
          outcomes: const <ReplaySimulationRealityModelShareOutcome>[],
        ),
      );
      when(
        () => replayService.stageDeeperTrainingCandidate(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationTrainingCandidateExport(
          environmentId: 'atx-replay-world-2024',
          bundleRoot: '/tmp/AVRAI/simulation_learning_bundles/atx',
          trainingManifestJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
          readmePath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/SIMULATION_TRAINING_CANDIDATE_README.md',
          stagedAt: DateTime.utc(2026, 3, 31, 12),
          shareReviewJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_share_review.json',
          status: 'simulation_candidate_ready_for_deeper_training_review',
        ),
      );
      when(
        () => replayService.queueDeeperTrainingIntake(
          environmentId: any(named: 'environmentId'),
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationTrainingIntakeQueueExport(
          environmentId: 'atx-replay-world-2024',
          bundleRoot: '/tmp/AVRAI/simulation_learning_bundles/atx',
          queueJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_intake_queue.json',
          readmePath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/SIMULATION_TRAINING_INTAKE_QUEUE_README.md',
          trainingManifestJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
          shareReviewJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_share_review.json',
          queuedAt: DateTime.utc(2026, 3, 31, 12),
          status: 'queued_for_deeper_training_intake_review',
          sourceId: 'simulation_training_source_atx',
          jobId: 'simulation_training_job_atx',
          reviewItemId: 'simulation_training_review_atx',
        ),
      );
      when(
        () => languageDiagnosticsService.getDiagnosticsForProfileRef(
          any(),
          recentEventLimit: any(named: 'recentEventLimit'),
        ),
      ).thenAnswer((_) async => null);
    });

    testWidgets('shows simulation learning evidence and exports bundle',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: RealitySystemOversightPage(
          layer: OversightLayer.reality,
          initialFocus: 'atx-replay-world-2024',
          initialAttention: 'bounded_review_candidate:variant-heatwave-lane',
          governanceService: governanceService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          languageDiagnosticsService: languageDiagnosticsService,
          conversationStyleHydrationService:
              _FakeAdminConversationStyleHydrationService(
            AdminConversationStyleSessionSnapshot(
              operatorToken: 'admin:reis',
              profileRef: 'governance_operator_admin_reis',
              displayRef: 'admin:reis',
              hydratedAtUtc: DateTime.utc(2026, 4, 4, 12),
              loginTimeUtc: DateTime.utc(2026, 4, 4, 11, 45),
              expiresAtUtc: DateTime.utc(2026, 4, 4, 19, 45),
              status: 'session_hydrated_with_learning_in_progress',
              readyForAdaptation: false,
              messageCount: 14,
              learningConfidence: 0.42,
              topVocabulary: const <String>['bounded', 'evidence', 'lane'],
              topPhrases: const <String>[
                'keep it bounded',
                'show the evidence',
              ],
              recentLearningScopes: const <String>[
                'governance_feedback_acceptance',
                'governance',
              ],
              mouthGuidance:
                  'Hydrated from governed operator language learning: prefer direct answers, keep the register plain, keep emphasis restrained.',
            ),
          ),
          feedbackPromptPlannerService:
              _FakeRecommendationFeedbackPromptPlannerService(
            <RecommendationFeedbackPromptPlan>[
              RecommendationFeedbackPromptPlan(
                planId: 'plan_1',
                ownerUserId: 'user_123',
                sourceEventRef: 'spot:spot_123:lessLikeThis:1',
                entity: const DiscoveryEntityReference(
                  type: DiscoveryEntityType.spot,
                  id: 'spot_123',
                  title: 'Heatwave Cafe',
                  localityLabel: 'atx_downtown',
                ),
                action: RecommendationFeedbackAction.lessLikeThis,
                eventOccurredAtUtc: DateTime.utc(2026, 4, 4, 10),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 10, 5),
                sourceSurface: 'explore_discovery',
                promptQuestion:
                    'What felt off about "Heatwave Cafe" for you right then?',
                promptRationale:
                    'A bounded follow-up can clarify why Heatwave Cafe led to a lessLikeThis signal on explore_discovery.',
                priority: 'high',
                channelHint: 'next_contextual_session',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why':
                      'It was recommended because of prior downtown coffee saves',
                  'how': 'place_intelligence_lane via explore_discovery',
                  'where': 'atx_downtown',
                },
                signalTags: const <String>[
                  'feedback_action:lessLikeThis',
                ],
              ),
            ],
          ),
          eventFeedbackPromptPlannerService:
              _FakePostEventFeedbackPromptPlannerService(
            <PostEventFeedbackPromptPlan>[
              PostEventFeedbackPromptPlan(
                planId: 'event_plan_1',
                ownerUserId: 'user_789',
                sourceFeedbackId: 'feedback_123',
                eventId: 'event_123',
                eventTitle: 'Rooftop Jazz Night',
                feedbackOccurredAtUtc: DateTime.utc(2026, 4, 4, 23),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 23, 5),
                sourceSurface: 'post_event_feedback',
                promptQuestion:
                    'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
                promptRationale:
                    'A bounded follow-up can clarify what should change after the first event reaction.',
                priority: 'high',
                channelHint: 'event_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why':
                      'The attendee signaled they would not attend again after a crowded event experience',
                  'how': 'post_event_feedback',
                  'where': 'atx_east',
                  'who': 'attendee:user_789',
                },
                signalTags: const <String>[
                  'source:event_feedback_follow_up_plan',
                  'channel:event_reflection_follow_up',
                ],
              ),
            ],
          ),
          onboardingFollowUpPlannerService:
              _FakeOnboardingFollowUpPromptPlannerService(
            <OnboardingFollowUpPromptPlan>[
              OnboardingFollowUpPromptPlan(
                planId: 'onboarding_plan_1',
                ownerUserId: 'user_onboarding',
                agentId: 'agent_onboarding',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 8),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 8, 5),
                sourceSurface: 'onboarding_completion',
                promptQuestion:
                    'Which part of what you told AVRAI about Austin, TX and the places you named should stay durable, and which part is still exploratory?',
                promptRationale:
                    'A bounded follow-up can separate durable onboarding signal from exploratory signal before broader profile learning hardens.',
                priority: 'high',
                channelHint: 'onboarding_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                homebase: 'Austin, TX',
                questionnaireVersion: 'v3',
                boundedContext: const <String, dynamic>{
                  'why': 'direct_onboarding_dimensions:openness',
                  'how': 'onboarding_data_service',
                  'where': 'Austin, TX',
                },
                signalTags: const <String>[
                  'source:onboarding_follow_up_plan',
                  'domain:identity',
                ],
              ),
            ],
          ),
          correctionFollowUpPlannerService:
              _FakeCorrectionFollowUpPromptPlannerService(
            <UserGovernedLearningCorrectionFollowUpPlan>[
              UserGovernedLearningCorrectionFollowUpPlan(
                planId: 'correction_plan_1',
                ownerUserId: 'user_456',
                targetEnvelopeId: 'env_456',
                targetSourceId: 'src_456',
                targetSummary: 'The user wants a quieter weeknight plan.',
                correctionText: 'Actually I only mean that on weekdays.',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 9),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 9, 5),
                sourceSurface: 'data_center_correction',
                promptQuestion:
                    'Should I treat your correction about "The user wants a quieter weeknight plan." as durable, or only for a specific situation?',
                promptRationale:
                    'A bounded follow-up can clarify whether the correction is durable or situational before broader learning.',
                priority: 'high',
                channelHint: 'bounded_correction_scope_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why':
                      'The original record described a quieter weeknight preference',
                  'how': 'data_center_correction',
                  'where': 'atx_downtown',
                },
                signalTags: const <String>[
                  'source:explicit_correction_follow_up_plan',
                  'domain:place',
                ],
              ),
            ],
          ),
          communityFollowUpPlannerService:
              _FakeCommunityFollowUpPromptPlannerService(
            <CommunityFollowUpPromptPlan>[
              CommunityFollowUpPromptPlan(
                planId: 'community_plan_1',
                ownerUserId: 'user_321',
                followUpKind: 'community_coordination',
                sourceEventRef:
                    'community_coordination:community_123:add_member',
                targetLabel: 'Night Owls',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 20),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 20, 5),
                sourceSurface: 'community_coordination',
                promptQuestion:
                    'What about "Night Owls" made joining feel right, and what should AVRAI remember from that?',
                promptRationale:
                    'A bounded follow-up can clarify what the join action should mean before broader community learning.',
                priority: 'medium',
                channelHint: 'community_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why': 'add_member',
                  'where': 'atx_downtown',
                },
                signalTags: const <String>[
                  'source:community_follow_up_plan',
                  'kind:community_coordination',
                ],
              ),
            ],
          ),
          businessFollowUpPlannerService:
              _FakeBusinessOperatorFollowUpPromptPlannerService(
            <BusinessOperatorFollowUpPromptPlan>[
              BusinessOperatorFollowUpPromptPlan(
                planId: 'business_plan_1',
                ownerUserId: 'owner_123',
                businessId: 'business_123',
                businessName: 'Night Owl Cafe',
                action: 'update',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 22),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 22, 5),
                sourceSurface: 'business_account',
                promptQuestion:
                    'What about the updated location or footprint for "Night Owl Cafe" should AVRAI remember before it changes place or locality learning?',
                promptRationale:
                    'A bounded follow-up can clarify what the location update should change before broader business learning.',
                priority: 'high',
                channelHint: 'business_operator_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why': 'location,categories',
                  'how': 'business_account_service',
                  'where': 'atx_downtown',
                },
                signalTags: const <String>[
                  'source:business_operator_follow_up_plan',
                  'action:update',
                ],
              ),
            ],
          ),
          visitLocalityFollowUpPlannerService:
              _FakeVisitLocalityFollowUpPromptPlannerService(
            <VisitLocalityFollowUpPromptPlan>[
              VisitLocalityFollowUpPromptPlan(
                planId: 'behavior_plan_1',
                ownerUserId: 'user_321',
                observationKind: 'locality',
                sourceEventRef: 'locality:gh7:abc1234:1',
                targetLabel: 'gh7:abc1234',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 21),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 21, 5),
                sourceSurface: 'locality_observation',
                promptQuestion:
                    'What was going on around "gh7:abc1234" that should shape future locality guidance?',
                promptRationale:
                    'A bounded follow-up can clarify what a passive locality signal should mean before broader learning.',
                priority: 'high',
                channelHint: 'behavior_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why': 'social_cluster',
                  'where': 'gh7:abc1234',
                },
                signalTags: const <String>[
                  'source:locality_follow_up_plan',
                  'domain:locality',
                ],
              ),
            ],
          ),
          reservationFollowUpPlannerService:
              _FakeReservationOperationalFollowUpPromptPlannerService(
            <ReservationOperationalFollowUpPromptPlan>[
              ReservationOperationalFollowUpPromptPlan(
                planId: 'reservation_plan_1',
                ownerUserId: 'user_654',
                reservationId: 'reservation_123',
                reservationType: 'business',
                targetId: 'business_789',
                targetLabel: 'business:business_789',
                operationKind: 'reservation_calendar_sync',
                occurredAtUtc: DateTime.utc(2026, 4, 4, 19),
                plannedAtUtc: DateTime.utc(2026, 4, 4, 19, 5),
                sourceSurface: 'reservation_calendar',
                promptQuestion:
                    'What about syncing this business reservation to your calendar mattered most for future timing guidance?',
                promptRationale:
                    'A bounded follow-up can clarify what this calendar sync should mean before broader reservation learning.',
                priority: 'medium',
                channelHint: 'reservation_operational_reflection_follow_up',
                status: 'planned_local_bounded_follow_up',
                boundedContext: const <String, dynamic>{
                  'why': 'calendar sync confirmed',
                  'how': 'reservation_calendar',
                  'where': 'downtown',
                },
                signalTags: const <String>[
                  'source:reservation_operational_follow_up_plan',
                  'operation:reservation_calendar_sync',
                ],
              ),
            ],
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Command Center handoff'), findsOneWidget);
      expect(
        find.textContaining('Focus: atx-replay-world-2024'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Attention: bounded_review_candidate:variant-heatwave-lane',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Review target: Heatwave mitigation lane'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Simulation Learning Bundle'),
        250,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Simulation Learning Bundle'), findsOneWidget);
      expect(find.textContaining('Simulation basis: generic_city_pack'),
          findsOneWidget);
      expect(find.textContaining('source_intake_orchestrator'), findsOneWidget);
      expect(
        find.textContaining(
            'City-pack structural ref: city_pack:atx_core_2024'),
        findsNWidgets(2),
      );
      expect(find.text('Export local bundle'), findsOneWidget);
      expect(find.text('Share to reality model'), findsOneWidget);
      expect(find.text('Stage deeper training candidate'), findsOneWidget);
      expect(find.text('Queue deeper training intake'), findsOneWidget);
      expect(find.text('Post-learning evidence'), findsOneWidget);
      expect(
        find.textContaining('Admin evidence surfaces refreshed locally'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Bounded recommendation: prefer_similar_reality_model_learning_candidates',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Validated upward re-propagation release'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Re-propagation plan: /tmp/AVRAI/upward_learning_bundles/atx/reality_model_update_downstream_repropagation_plan.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Domain hints: community, place'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Referenced entities: heatwave mitigation lane, recommendation:spot_123',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Questions: Does this validation result justify promoting a place-level conviction beyond the current replay context?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up prompt: What made the cooling strategy feel like a real improvement?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up answer: It made the venue feel calmer and easier to stay in longer.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Follow-up completion: assistant_follow_up_chat'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Onboarding Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Onboarding Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining('Owner: user_onboarding • homebase:Austin, TX'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining(
          'Signal tags: source:simulation_validation, domain:place, signal:positive_outcome',
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.textContaining(
          'Signal tags: source:simulation_validation, domain:place, signal:positive_outcome',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Preference signals: place_affinity:cool_indoor_spaces:w:0.91',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Released lanes: admin:atx-replay-world-2024, supervisor:atx-replay-world-2024, hierarchy:community, hierarchy:place',
        ),
        findsOneWidget,
      );
      expect(find.text('Active bounded review target'), findsOneWidget);
      expect(
        find.textContaining(
          'Heatwave mitigation lane was carried in from World Simulation Lab',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Selected action: candidate for bounded review',
        ),
        findsOneWidget,
      );
      expect(find.text('Keep candidate for bounded review'), findsOneWidget);
      expect(find.text('Watch closely instead'), findsOneWidget);
      expect(find.text('Keep iterating instead'), findsOneWidget);
      expect(find.text('Bounded review routing'), findsOneWidget);
      expect(
        find.textContaining(
          'Heatwave mitigation lane is explicitly marked as a candidate for bounded review',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Latest lab outcome: accepted'),
        findsNWidgets(2),
      );
      expect(
        find.textContaining('Latest rerun: job completed'),
        findsNWidgets(2),
      );
      expect(find.text('Governed downstream propagation'), findsOneWidget);
      expect(find.text('Domain propagation delta • locality'), findsOneWidget);
      expect(find.text('Domain propagation delta • event'), findsOneWidget);
      expect(find.text('Domain propagation delta • place'), findsOneWidget);
      expect(find.text('Domain propagation delta • community'), findsOneWidget);
      expect(find.text('Domain propagation delta • business'), findsOneWidget);
      expect(find.text('Domain propagation delta • list'), findsOneWidget);
      expect(
        find.text('Personal-agent personalization • locality'),
        findsOneWidget,
      );
      expect(
        find.text('Personal-agent personalization • place'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hierarchy:locality • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hierarchy:event • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hierarchy:place • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'hierarchy:community • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hierarchy:business • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hierarchy:list • prior_and_explanation_delta'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • business_intelligence_lane'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • list_curation_lane'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • place_intelligence_lane'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • community_coordination_lane'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • locality_intelligence_lane'),
        findsOneWidget,
      );
      expect(
        find.text('Domain consumer • event_intelligence_lane'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: locality_priors'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: event_priors'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: place_priors'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: community_coordination_priors'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: business_account_guidance'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Targeted systems: list_curation_priors'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'personal_agent:locality • personalized_guidance_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'personal_agent:place • personalized_guidance_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'personal_agent:business • personalized_guidance_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'personal_agent:list • personalized_guidance_delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Bounded use: Apply this only as a domain-scoped delta'),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Lane artifact: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Lane artifact: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_event.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Domain delta: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Domain delta: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_event.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Personalization mode: final_contextualization_after_hierarchy_synthesis',
        ),
        findsNWidgets(4),
      );
      expect(
        find.textContaining(
          'Personalization delta: /tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_locality.json',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Export local bundle'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Export local bundle'));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      verify(
        () => replayService.exportLearningBundle(
          environmentId: any(named: 'environmentId'),
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Local bundle: /tmp/AVRAI/simulation_learning_bundles/atx',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Share to reality model'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Share to reality model'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => replayService.shareLearningBundleWithRealityModel(
          environmentId: any(named: 'environmentId'),
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Reality-model review: /tmp/AVRAI/simulation_learning_bundles/atx/reality_model_share_review.json',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Stage deeper training candidate'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Stage deeper training candidate'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => replayService.stageDeeperTrainingCandidate(
          environmentId: any(named: 'environmentId'),
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Training candidate: /tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Queue deeper training intake'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Queue deeper training intake'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => replayService.queueDeeperTrainingIntake(
          environmentId: any(named: 'environmentId'),
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Training intake queue: /tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_intake_queue.json',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Admin Conversation Style Session'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Admin Conversation Style Session'), findsOneWidget);
      expect(find.textContaining('admin:reis'), findsWidgets);
      expect(
        find.textContaining(
          'Mouth guidance: Hydrated from governed operator language learning: prefer direct answers, keep the register plain, keep emphasis restrained.',
        ),
        findsOneWidget,
      );
      expect(find.text('Bounded Feedback Prompt Plans'), findsOneWidget);
      expect(
        find.textContaining(
          'What felt off about "Heatwave Cafe" for you right then?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Priority: high • Channel hint: next_contextual_session',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Event Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Event Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining(
          'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
        ),
        findsOneWidget,
      );
      expect(find.text('Bounded Correction Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining('Actually I only mean that on weekdays.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Community Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Community Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining(
          'What about "Night Owls" made joining feel right',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Business Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Business Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining(
          'What about the updated location or footprint for "Night Owl Cafe"',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Visit & Locality Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Visit & Locality Follow-Up Plans'),
          findsOneWidget);
      expect(
        find.textContaining(
          'What was going on around "gh7:abc1234" that should shape future locality guidance?',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Bounded Reservation Follow-Up Plans'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Bounded Reservation Follow-Up Plans'), findsOneWidget);
      expect(
        find.textContaining(
          'What about syncing this business reservation to your calendar mattered most',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Priority: medium • Channel hint: reservation_operational_reflection_follow_up',
        ),
        findsOneWidget,
      );
    });

    testWidgets('can downgrade the active bounded review target in place',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: RealitySystemOversightPage(
          layer: OversightLayer.reality,
          initialFocus: 'atx-replay-world-2024',
          initialAttention: 'bounded_review_candidate:variant-heatwave-lane',
          governanceService: governanceService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          languageDiagnosticsService: languageDiagnosticsService,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.scrollUntilVisible(
        find.text('Watch closely instead'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(find.text('Watch closely instead'));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      verify(
        () => replayService.recordLabTargetActionDecision(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-heatwave-lane',
          suggestedAction: 'watch_closely',
          suggestedReason:
              'Recent executed reruns are stable enough for bounded review.',
          selectedAction: 'watch_closely',
        ),
      ).called(1);

      expect(find.text('Active bounded review target'), findsNothing);
      expect(
        find.textContaining('Review target: Heatwave mitigation lane'),
        findsNothing,
      );
      expect(
        find.textContaining(
          'Bounded review target updated: Heatwave mitigation lane will now stay on the watch-closely lane.',
        ),
        findsOneWidget,
      );
    });
  });
}
