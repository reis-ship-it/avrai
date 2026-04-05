import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/ui/pages/kernel_graph_run_detail_page.dart';
import 'package:avrai_admin_app/ui/pages/signature_source_health_page.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}

void main() {
  group('SignatureSourceHealthPage', () {
    late GetIt getIt;
    late MockSignatureHealthAdminService service;
    late StreamController<SignatureHealthSnapshot> controller;

    final snapshot = SignatureHealthSnapshot(
      generatedAt: DateTime(2026, 3, 6),
      overview: const SignatureHealthOverview(
        strongCount: 1,
        weakDataCount: 1,
        staleCount: 0,
        fallbackCount: 1,
        reviewNeededCount: 0,
        bundleCount: 0,
        softIgnoreCount: 1,
        hardNotInterestedCount: 0,
        kernelGraphRecentCount: 1,
        kernelGraphFailedCount: 0,
        kernelGraphHumanReviewCount: 1,
      ),
      reviewQueueCount: 2,
      servedBasisSummaries: <SignatureHealthServedBasisSummary>[
        SignatureHealthServedBasisSummary(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          supportedPlaceRef: 'place:atx',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          currentBasisStatus: 'expired_latest_state_served_basis',
          latestStateHydrationStatus: 'expired_basis_ready_for_restore_review',
          latestStatePromotionReadiness:
              'ready_for_bounded_served_basis_restore',
          latestStateDecisionStatus: 'promoted',
          latestStateRevalidationStatus: 'current',
          latestStateRecoveryDecisionStatus: 'not_reviewed',
          hydrationFreshnessPosture:
              'expired_basis_supported_by_current_receipts_pending_restore_review',
          servedBasisRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
          latestStateRevalidationReceiptRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_revalidation_receipts.revalidation.json',
          latestStateRecoveryDecisionArtifactRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_restore_decision.restored.json',
          updatedAt: DateTime.utc(2026, 4, 2, 10),
        ),
      ],
      familyRestageIntakeReviewSummaries: <SignatureHealthFamilyRestageIntakeReviewSummary>[
        SignatureHealthFamilyRestageIntakeReviewSummary(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          supportedPlaceRef: 'place:atx',
          evidenceFamily: 'app_observations',
          restageTarget: 'restage_input_family:app_observations',
          restageTargetSummary:
              'app observations: route to restage input family `app observations` because this family is repeatedly degrading.',
          policyAction: 'force_restaged_inputs',
          policyActionSummary:
              'app observations now needs bounded restage intake review.',
          queueStatus: 'restage_intake_review_approved',
          itemJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
          restageIntakeQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_intake_review.current.json',
          restageIntakeReviewItemId:
              'family_restage_review_atx-replay-world-2024_app_observations',
          restageIntakeResolutionStatus: 'approved',
          restageIntakeResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
          followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
          followUpQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
          followUpReviewItemId:
              'family_restage_follow_up_review_atx-replay-world-2024_app_observations',
          followUpResolutionStatus: 'approved',
          followUpResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
          restageResolutionQueueStatus:
              'queued_for_family_restage_resolution_review',
          restageResolutionQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
          restageResolutionReviewItemId:
              'family_restage_resolution_review_atx-replay-world-2024_app_observations',
          restageResolutionResolutionStatus:
              'approved_for_bounded_family_restage_execution',
          restageResolutionResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
          restageExecutionQueueStatus:
              'queued_for_family_restage_execution_review',
          restageExecutionQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
          restageExecutionReviewItemId:
              'family_restage_execution_review_atx-replay-world-2024_app_observations',
          restageExecutionResolutionStatus:
              'approved_for_bounded_family_restage_application',
          restageExecutionResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
          restageApplicationQueueStatus:
              'queued_for_family_restage_application_review',
          restageApplicationQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
          restageApplicationReviewItemId:
              'family_restage_application_review_atx-replay-world-2024_app_observations',
          restageApplicationResolutionStatus:
              'approved_for_bounded_family_restage_apply_to_served_basis',
          restageApplicationResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
          restageApplyQueueStatus: 'queued_for_family_restage_apply_review',
          restageApplyQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
          restageApplyReviewItemId:
              'family_restage_apply_review_atx-replay-world-2024_app_observations',
          restageApplyResolutionStatus:
              'approved_for_bounded_family_restage_served_basis_update',
          restageApplyResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
          restageServedBasisUpdateQueueStatus:
              'queued_for_family_restage_served_basis_update_review',
          restageServedBasisUpdateQueueJsonPath:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update_review.current.json',
          restageServedBasisUpdateReviewItemId:
              'family_restage_served_basis_update_review_atx-replay-world-2024_app_observations',
          restageServedBasisUpdateResolutionStatus:
              'approved_for_bounded_family_restage_served_basis_mutation',
          restageServedBasisUpdateResolutionArtifactRef:
              '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update.approved.json',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          updatedAt: DateTime.utc(2026, 4, 2, 10, 15),
        ),
      ],
      reviewItems: <SignatureHealthReviewQueueItem>[
        SignatureHealthReviewQueueItem(
          id: 'review-sim-1',
          sourceId: 'simulation_training_source_atx',
          ownerUserId: 'admin_operator',
          targetType: 'review',
          title: 'Deeper training intake review for atx-replay-world-2024',
          summary:
              'Strong simulation candidate is queued for governed deeper-training intake review.',
          missingFields: const <String>[],
          createdAt: DateTime(2026, 3, 31, 12),
          payload: const <String, dynamic>{
            'environmentId': 'atx-replay-world-2024',
            'status': 'queued_for_deeper_training_intake_review',
            'suggestedTrainingUse': 'candidate_deeper_reality_model_training',
            'cityPackStructuralRef': 'city_pack:atx_core_2024',
            'intakeFlowRefs': <String>['source_intake_orchestrator'],
            'sidecarRefs': <String>['city_packs/atx/2024_manifest.json'],
            'trainingManifestJsonPath':
                '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
          },
        ),
        SignatureHealthReviewQueueItem(
          id: 'review-up-1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          targetType: 'review',
          title: 'Upward learning review: personal-agent human intake',
          summary:
              'A governed personal-agent human intake item is ready for upward learning review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 2, 21),
          payload: const <String, dynamic>{
            'queueKind': 'queued_for_upward_learning_review',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'sourceKind': 'personal_agent_human_intake',
            'convictionTier': 'personal_agent_human_observation',
            'hierarchyPath': <String>[
              'human',
              'personal_agent',
              'reality_model_agent',
            ],
            'upwardDomainHints': <String>['locality', 'place'],
            'upwardReferencedEntities': <String>[
              'downtown coffee shop',
              'recommendation:spot_123',
            ],
            'upwardQuestions': <String>[
              'Should this preference remain local or move upward as a reusable place conviction?',
            ],
            'upwardSignalTags': <String>[
              'source:human',
              'domain:place',
            ],
            'upwardPreferenceSignals': <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'place_preference',
                'value': 'coffee_shop',
              },
            ],
            'temporalLineage': <String, dynamic>{
              'originOccurredAt': '2026-04-02T20:55:00.000Z',
              'reviewQueuedAt': '2026-04-02T21:00:00.000Z',
              'kernelExchangePhase': 'queued_upward_learning_review',
            },
          },
        ),
      ],
      labTargetActionItems: <SignatureHealthLabTargetActionItem>[
        SignatureHealthLabTargetActionItem(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          suggestedAction: 'watch_closely',
          suggestedReason:
              'Recent executed reruns stabilized enough for bounded review.',
          selectedAction: 'candidate_for_bounded_review',
          acceptedSuggestion: true,
          updatedAt: DateTime.utc(2026, 4, 1, 16),
          variantId: 'variant-heatwave-lane',
          variantLabel: 'Heatwave mitigation lane',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>[
            'city_packs/atx/2024_manifest.json',
            'world_models/atx/jepa_geo_realism_v2.json',
          ],
          latestOutcomeDisposition: 'accepted',
          latestRerunRequestStatus: 'completed',
          latestRerunJobStatus: 'completed',
          trendSummary: const SignatureHealthLabTargetTrendSummary(
            completedRerunCount: 2,
            runtimeTrendSeverityCode: 'improving',
            runtimeTrendSummary:
                'Runtime trend: Improving within bounded runtime drift.',
            runtimeDeltaSummary:
                'Runtime delta vs prior completed rerun: contradictions down 1, receipts up 1, overlays stable, request previews up 1.',
            outcomeTrendSummary:
                'Outcome trend: improved from denial to accepted evidence.',
          ),
          provenanceDeltaSummary:
              const SignatureHealthLabTargetProvenanceDeltaSummary(
            summary:
                'Latest provenance delta highlights what changed between the latest two persisted samples.',
            details: <String>[
              'Added sidecars: world_models/atx/jepa_geo_realism_v2.json',
              'Added artifact families: replay_learning_bundle',
            ],
          ),
          provenanceHistorySummary:
              const SignatureHealthLabTargetProvenanceHistorySummary(
            sampleCount: 4,
            entries: <SignatureHealthLabTargetProvenanceHistoryEntry>[
              SignatureHealthLabTargetProvenanceHistoryEntry(
                label: 'Completed rerun @ 2026-04-02T09:05:00Z vs prior sample',
                details: <String>[
                  'Added artifact families: replay_learning_bundle',
                ],
              ),
              SignatureHealthLabTargetProvenanceHistoryEntry(
                label: 'Lab outcome @ 2026-04-02T08:40:00Z vs prior sample',
                details: <String>[
                  'Added sidecars: world_models/atx/jepa_geo_realism_v2.json',
                ],
              ),
            ],
          ),
          provenanceEmphasisSummary:
              const SignatureHealthLabTargetProvenanceEmphasisSummary(
            severityCode: 'elevated_churn',
            summary:
                'Provenance churn: Elevated realism-pack churn across recent persisted samples.',
          ),
        ),
        SignatureHealthLabTargetActionItem(
          environmentId: 'sav-replay-world-2024',
          displayName: 'Savannah Simulation Environment 2024',
          cityCode: 'sav',
          replayYear: 2024,
          suggestedAction: 'candidate_for_bounded_review',
          suggestedReason:
              'The target was recently rechecked but still needs one more watch lane.',
          selectedAction: 'watch_closely',
          acceptedSuggestion: false,
          updatedAt: DateTime.utc(2026, 4, 2, 10),
          variantId: 'variant-riverfront-lane',
          variantLabel: 'Riverfront realism lane',
          cityPackStructuralRef: 'city_pack:sav_core_2024',
          latestOutcomeDisposition: 'denied',
          latestRerunRequestStatus: 'completed',
          latestRerunJobStatus: 'completed',
          trendSummary: const SignatureHealthLabTargetTrendSummary(
            completedRerunCount: 1,
            runtimeTrendSeverityCode: 'low_confidence',
            runtimeTrendSummary:
                'Runtime trend: Low confidence; only one completed rerun exists.',
            runtimeDeltaSummary:
                'Runtime delta: only one completed rerun exists so far.',
            outcomeTrendSummary:
                'Outcome trend: only one labeled outcome exists so far.',
          ),
        ),
        SignatureHealthLabTargetActionItem(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          suggestedAction: 'candidate_for_bounded_review',
          suggestedReason:
              'Downtown lane still needs one more bounded watch pass.',
          selectedAction: 'watch_closely',
          acceptedSuggestion: false,
          updatedAt: DateTime.utc(2026, 4, 2, 8),
          variantId: 'variant-downtown-lane',
          variantLabel: 'Downtown calibration lane',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          latestOutcomeDisposition: 'draft',
          latestRerunRequestStatus: 'completed',
          latestRerunJobStatus: 'completed',
          trendSummary: const SignatureHealthLabTargetTrendSummary(
            completedRerunCount: 2,
            runtimeTrendSeverityCode: 'mixed',
            runtimeTrendSummary:
                'Runtime trend: Mixed drift; operator review still required.',
            runtimeDeltaSummary:
                'Runtime delta vs prior completed rerun: contradictions stable, receipts stable, overlays up 1, request previews down 1.',
            outcomeTrendSummary:
                'Outcome trend: latest run moved back into draft iteration.',
          ),
          provenanceDeltaSummary:
              const SignatureHealthLabTargetProvenanceDeltaSummary(
            summary:
                'Latest provenance delta highlights what changed between the latest two persisted samples.',
            details: <String>[
              'Removed sidecars: world_models/atx/mirofish_realism_v1.json',
            ],
          ),
          provenanceHistorySummary:
              const SignatureHealthLabTargetProvenanceHistorySummary(
            sampleCount: 3,
            entries: <SignatureHealthLabTargetProvenanceHistoryEntry>[
              SignatureHealthLabTargetProvenanceHistoryEntry(
                label: 'Lab outcome @ 2026-04-02T08:15:00Z vs prior sample',
                details: <String>[
                  'Removed sidecars: world_models/atx/mirofish_realism_v1.json',
                ],
              ),
            ],
          ),
          provenanceEmphasisSummary:
              const SignatureHealthLabTargetProvenanceEmphasisSummary(
            severityCode: 'targeted_change',
            summary:
                'Provenance churn: Targeted realism-pack changes detected in recent persisted samples.',
          ),
          boundedAlertSummary:
              const SignatureHealthLabTargetBoundedAlertSummary(
            severityCode: 'watch',
            summary:
                'Bounded alert: review this lane closely because runtime instability and provenance churn are both present.',
          ),
        ),
      ],
      boundedReviewCandidates: <SignatureHealthBoundedReviewCandidate>[
        SignatureHealthBoundedReviewCandidate(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          suggestedAction: 'watch_closely',
          suggestedReason:
              'Recent executed reruns stabilized enough for bounded review.',
          selectedAction: 'candidate_for_bounded_review',
          acceptedSuggestion: true,
          updatedAt: DateTime.utc(2026, 4, 1, 16),
          variantId: 'variant-heatwave-lane',
          variantLabel: 'Heatwave mitigation lane',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>[
            'city_packs/atx/2024_manifest.json',
            'world_models/atx/jepa_geo_realism_v2.json',
          ],
          latestOutcomeDisposition: 'accepted',
          latestRerunRequestStatus: 'completed',
          latestRerunJobStatus: 'completed',
          trendSummary: const SignatureHealthLabTargetTrendSummary(
            completedRerunCount: 2,
            runtimeTrendSeverityCode: 'improving',
            runtimeTrendSummary:
                'Runtime trend: Improving within bounded runtime drift.',
            runtimeDeltaSummary:
                'Runtime delta vs prior completed rerun: contradictions down 1, receipts up 1, overlays stable, request previews up 1.',
            outcomeTrendSummary:
                'Outcome trend: improved from denial to accepted evidence.',
          ),
          provenanceDeltaSummary:
              const SignatureHealthLabTargetProvenanceDeltaSummary(
            summary:
                'Latest provenance delta highlights what changed between the latest two persisted samples.',
            details: <String>[
              'Added sidecars: world_models/atx/jepa_geo_realism_v2.json',
              'Added artifact families: replay_learning_bundle',
            ],
          ),
          provenanceHistorySummary:
              const SignatureHealthLabTargetProvenanceHistorySummary(
            sampleCount: 4,
            entries: <SignatureHealthLabTargetProvenanceHistoryEntry>[
              SignatureHealthLabTargetProvenanceHistoryEntry(
                label: 'Completed rerun @ 2026-04-02T09:05:00Z vs prior sample',
                details: <String>[
                  'Added artifact families: replay_learning_bundle',
                ],
              ),
              SignatureHealthLabTargetProvenanceHistoryEntry(
                label: 'Lab outcome @ 2026-04-02T08:40:00Z vs prior sample',
                details: <String>[
                  'Added sidecars: world_models/atx/jepa_geo_realism_v2.json',
                ],
              ),
            ],
          ),
          provenanceEmphasisSummary:
              const SignatureHealthLabTargetProvenanceEmphasisSummary(
            severityCode: 'elevated_churn',
            summary:
                'Provenance churn: Elevated realism-pack churn across recent persisted samples.',
          ),
        ),
      ],
      learningOutcomeItems: <SignatureHealthLearningOutcomeItem>[
        const SignatureHealthLearningOutcomeItem(
          sourceId: 'simulation_training_source_atx',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          learningPathway: 'deeper_reality_model_training',
          outcomeStatus: 'completed',
          summary: 'Reality-model learning completed locally.',
          learningOutcomeJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_learning_outcome.json',
          downstreamPropagationPlanJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/downstream_agent_propagation_plan.json',
          adminEvidenceRefreshSnapshotJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
          supervisorLearningFeedbackStateJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
          adminEvidenceRefreshSummary:
              SignatureHealthAdminEvidenceRefreshSummary(
            status: 'refreshed_local_admin_evidence',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            summary:
                'Admin evidence refresh now mirrors the bounded learning outcome for the selected environment.',
            requestCount: 1,
            recommendationCount: 1,
            averageConfidence: 0.84,
          ),
          supervisorFeedbackSummary: SignatureHealthSupervisorFeedbackSummary(
            status: 'recorded_local_supervisor_feedback',
            environmentId: 'atx-replay-world-2024',
            feedbackSummary:
                'Supervisor feedback allows a bounded retry with operator visibility.',
            boundedRecommendation:
                'allow_bounded_retry_with_operator_visibility',
            requestCount: 1,
            recommendationCount: 1,
            averageConfidence: 0.84,
          ),
          propagationTargets: <SignatureHealthPropagationTarget>[
            SignatureHealthPropagationTarget(
              targetId: 'hierarchy:locality',
              propagationKind: 'prior_and_explanation_delta',
              reason: 'Locality domain is ready for propagation.',
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
                jsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
              ),
            ),
            SignatureHealthPropagationTarget(
              targetId: 'personal_agent:locality',
              propagationKind: 'personalized_guidance_delta',
              reason:
                  'Personal agent locality personalization is ready after hierarchy synthesis.',
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
          ],
        ),
      ],
      upwardLearningItems: <SignatureHealthUpwardLearningItem>[
        SignatureHealthUpwardLearningItem(
          sourceId: 'upward_learning_source_user_123_msg_1',
          sourceKind: 'personal_agent_human_intake',
          learningDirection: 'upward_personal_agent_to_reality_model',
          learningPathway: 'governed_upward_reality_model_learning',
          convictionTier: 'personal_agent_human_observation',
          status: 'ready_for_governed_truth_conviction_review',
          summary:
              'A governed truth/conviction review is now ready from the local reality-model-agent outcome.',
          environmentId: 'unknown_environment',
          cityCode: 'unknown',
          hierarchyPath: const <String>[
            'human',
            'personal_agent',
            'reality_model_agent',
          ],
          upwardDomainHints: const <String>['locality', 'place'],
          upwardReferencedEntities: const <String>[
            'downtown coffee shop',
            'recommendation:spot_123',
          ],
          upwardQuestions: const <String>[
            'Should this preference remain local or move upward as a reusable place conviction?',
          ],
          followUpPromptQuestion:
              'What felt off about "Heatwave Cafe" for you right then?',
          followUpResponseText:
              'It felt too loud and crowded for what I wanted.',
          followUpCompletionMode: 'assistant_follow_up_chat',
          chatObservationSummary: SignatureHealthChatObservationSummary(
            totalCount: 3,
            acknowledgedCount: 1,
            requestedFollowUpCount: 1,
            correctedCount: 1,
            forgotCount: 0,
            stoppedUsingCount: 0,
            openRequestedFollowUpCount: 1,
            openCorrectedCount: 1,
            openForgotCount: 0,
            openStoppedUsingCount: 0,
            latestOutcome:
                GovernedLearningChatObservationOutcome.requestedFollowUp,
            latestValidationStatus:
                GovernedLearningChatObservationValidationStatus
                    .validatedBySurfacedAdoption,
            latestGovernanceStatus:
                GovernedLearningChatObservationGovernanceStatus
                    .reinforcedByGovernance,
            latestAttentionStatus:
                GovernedLearningChatObservationAttentionStatus.pending,
            latestRecordedAt: DateTime.utc(2026, 4, 2, 21, 4),
            latestFocus: 'trail',
            latestQuestion: 'Show me what this came from.',
            latestGovernanceStage: 'reality_model_truth_review',
            latestGovernanceReason:
                'Promoted after corroborating evidence held up in truth review.',
            latestAttentionDispositionSummary:
                'attention pending while governance review is still open',
          ),
          upwardSignalTags: const <String>[
            'source:human',
            'domain:place',
          ],
          upwardPreferenceSignals: const <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'place_preference',
              'value': 'coffee_shop',
            },
          ],
          hierarchySynthesisPlanJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_plan.json',
          hierarchySynthesisOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_outcome.json',
          realityModelAgentHandoffJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_handoff.json',
          realityModelAgentOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_outcome.json',
          realityModelTruthReviewJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_truth_review.json',
          truthIntegrationStatus:
              'needs_governed_truth_validation_against_real_world',
          realityModelUpdateCandidateJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_candidate.json',
          truthReviewResolution: 'promoteToUpdateCandidate',
          realityModelUpdateDecisionJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_decision.json',
          realityModelUpdateOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_outcome.json',
          updateCandidateResolution: 'approveBoundedUpdate',
          realityModelUpdateAdminBriefJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_admin_brief.json',
          realityModelUpdateSupervisorBriefJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_supervisor_brief.json',
          realityModelUpdateSimulationSuggestionJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_validation_simulation_suggestion.json',
          realityModelUpdateDownstreamRepropagationReviewJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_review.json',
          realityModelUpdateDownstreamRepropagationPlanJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_plan.json',
          downstreamRepropagationReleasedTargetIds: <String>[
            'admin:unknown_environment',
            'supervisor:unknown_environment',
            'hierarchy:locality',
          ],
        ),
      ],
      kernelGraphRuns: <KernelGraphRunRecord>[
        KernelGraphRunRecord(
          runId: 'kernel-graph-run-1',
          specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
          graphTitle: 'Governed upward intake persistence',
          kind: KernelGraphKind.learningIntake,
          status: KernelGraphRunStatus.completed,
          startedAt: DateTime.utc(2026, 4, 2, 21, 0),
          completedAt: DateTime.utc(2026, 4, 2, 21, 0, 2),
          sourceId: 'upward_learning_source_user_123_msg_1',
          reviewItemId: 'review-up-1',
          jobId: 'upward_learning_source_user_123_msg_1:job',
          sourceKind: 'personal_agent_human_intake',
          spec: KernelGraphSpec(
            id: 'kernel_graph:upward_learning_source_user_123_msg_1',
            title: 'Governed upward learning intake persistence',
            kind: KernelGraphKind.learningIntake,
            version: '0.1',
            executionPolicy: const KernelGraphExecutionPolicy(
              environment: KernelGraphExecutionEnvironment.runtime,
              requiresHumanReview: true,
              maxStepCount: 3,
              allowedMutableSurfaces: <String>[
                'intake_repository.sources',
                'intake_repository.jobs',
                'intake_repository.reviews',
              ],
            ),
            metadata: const <String, dynamic>{
              'learningPathway': 'governed_upward_reality_model_learning',
              'queueKind': 'queued_for_upward_learning_review',
            },
            nodes: const <KernelGraphNodeSpec>[
              KernelGraphNodeSpec(
                id: 'persist_source_descriptor',
                primitiveId: 'intake.upsert_source_descriptor',
                label: 'Persist source descriptor',
                config: <String, dynamic>{
                  'descriptor': <String, dynamic>{
                    'id': 'upward_learning_source_user_123_msg_1',
                    'sourceLabel': 'Personal-agent human upward learning',
                    'sourceProvider': 'personal_agent_human_intake',
                  },
                },
              ),
              KernelGraphNodeSpec(
                id: 'persist_sync_job',
                primitiveId: 'intake.upsert_sync_job',
                label: 'Persist sync job',
                config: <String, dynamic>{
                  'job': <String, dynamic>{
                    'id': 'upward_learning_source_user_123_msg_1:job',
                    'queueKind': 'queued_for_upward_learning_review',
                    'status': 'needsReview',
                  },
                },
              ),
              KernelGraphNodeSpec(
                id: 'queue_review_item',
                primitiveId: 'intake.upsert_review_item',
                label: 'Queue review item',
                config: <String, dynamic>{
                  'reviewItem': <String, dynamic>{
                    'id': 'review-up-1',
                    'title': 'Governed upward intake persistence',
                    'summary': 'Queued for upward learning review.',
                  },
                },
              ),
            ],
            edges: const <KernelGraphEdgeSpec>[
              KernelGraphEdgeSpec(
                fromNodeId: 'persist_source_descriptor',
                toNodeId: 'persist_sync_job',
                label: 'source_to_job',
              ),
              KernelGraphEdgeSpec(
                fromNodeId: 'persist_sync_job',
                toNodeId: 'queue_review_item',
                label: 'job_to_review',
              ),
            ],
          ),
          compiledPlan: KernelGraphCompiledPlan(
            specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
            title: 'Governed upward learning intake persistence',
            kind: KernelGraphKind.learningIntake,
            version: '0.1',
            executionPolicy: const KernelGraphExecutionPolicy(
              environment: KernelGraphExecutionEnvironment.runtime,
              requiresHumanReview: true,
              maxStepCount: 3,
              allowedMutableSurfaces: <String>[
                'intake_repository.sources',
                'intake_repository.jobs',
                'intake_repository.reviews',
              ],
            ),
            steps: const <KernelGraphCompiledStep>[
              KernelGraphCompiledStep(
                nodeId: 'persist_source_descriptor',
                primitiveId: 'intake.upsert_source_descriptor',
                label: 'Persist source descriptor',
                order: 0,
              ),
              KernelGraphCompiledStep(
                nodeId: 'persist_sync_job',
                primitiveId: 'intake.upsert_sync_job',
                label: 'Persist sync job',
                order: 1,
              ),
              KernelGraphCompiledStep(
                nodeId: 'queue_review_item',
                primitiveId: 'intake.upsert_review_item',
                label: 'Queue review item',
                order: 2,
              ),
            ],
          ),
          adminDigest: const KernelGraphAdminDigest(
            runId: 'kernel-graph-run-1',
            specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
            graphTitle: 'Governed upward intake persistence',
            kind: KernelGraphKind.learningIntake,
            status: KernelGraphRunStatus.completed,
            summary: 'Completed 3 of 3 nodes.',
            requiresHumanReview: true,
            completedNodeCount: 3,
            totalNodeCount: 3,
            lineageRefs: <String>[
              'upward_learning_source_user_123_msg_1',
              'upward_learning_source_user_123_msg_1:job',
              'review-up-1',
            ],
            rollbackRefs: <String>[
              'upward_learning_source_user_123_msg_1',
              'review-up-1',
            ],
          ),
          receipt: KernelGraphExecutionReceipt(
            runId: 'kernel-graph-run-1',
            specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
            title: 'Governed upward intake persistence',
            kind: KernelGraphKind.learningIntake,
            status: KernelGraphRunStatus.completed,
            startedAt: DateTime.utc(2026, 4, 2, 21, 0),
            completedAt: DateTime.utc(2026, 4, 2, 21, 0, 2),
            nodeReceipts: <KernelGraphNodeReceipt>[
              KernelGraphNodeReceipt(
                nodeId: 'persist_source_descriptor',
                primitiveId: 'intake.upsert_source_descriptor',
                status: KernelGraphNodeStatus.completed,
                startedAt: DateTime.utc(2026, 4, 2, 21, 0),
                completedAt: DateTime.utc(2026, 4, 2, 21, 0, 1),
                summary:
                    'Persisted intake source `upward_learning_source_user_123_msg_1`.',
                outputRefs: <String>['upward_learning_source_user_123_msg_1'],
                metadata: <String, dynamic>{
                  'sourceId': 'upward_learning_source_user_123_msg_1',
                },
              ),
              KernelGraphNodeReceipt(
                nodeId: 'persist_sync_job',
                primitiveId: 'intake.upsert_sync_job',
                status: KernelGraphNodeStatus.completed,
                startedAt: DateTime.utc(2026, 4, 2, 21, 0, 1),
                completedAt: DateTime.utc(2026, 4, 2, 21, 0, 1),
                summary:
                    'Persisted intake job `upward_learning_source_user_123_msg_1:job`.',
                outputRefs: <String>[
                  'upward_learning_source_user_123_msg_1:job'
                ],
                metadata: <String, dynamic>{
                  'jobId': 'upward_learning_source_user_123_msg_1:job',
                },
              ),
              KernelGraphNodeReceipt(
                nodeId: 'queue_review_item',
                primitiveId: 'intake.upsert_review_item',
                status: KernelGraphNodeStatus.completed,
                startedAt: DateTime.utc(2026, 4, 2, 21, 0, 1),
                completedAt: DateTime.utc(2026, 4, 2, 21, 0, 2),
                summary: 'Queued review item `review-up-1`.',
                outputRefs: <String>['review-up-1'],
                metadata: <String, dynamic>{
                  'reviewItemId': 'review-up-1',
                },
              ),
            ],
            rollbackDescriptor: const KernelGraphRollbackDescriptor(
              id: 'kernel-graph-run-1:rollback',
              strategy: 'idempotent_intake_review_upserts',
              refs: <String>[
                'upward_learning_source_user_123_msg_1',
                'upward_learning_source_user_123_msg_1:job',
                'review-up-1',
              ],
            ),
          ),
        ),
      ],
      records: <SignatureHealthRecord>[
        const SignatureHealthRecord(
          sourceId: 'source-1',
          provider: 'eventbrite',
          entityType: 'event',
          categoryLabel: 'music',
          sourceLabel: 'Source One',
          confidence: 0.91,
          freshness: 0.83,
          fallbackRate: 0.0,
          reviewNeeded: false,
          syncState: 'active',
          healthCategory: SignatureHealthCategory.strong,
          summary: 'Strong source summary.',
        ),
        const SignatureHealthRecord(
          sourceId: 'source-2',
          provider: 'manual',
          entityType: 'spot',
          categoryLabel: 'coffee',
          sourceLabel: 'Source Two',
          confidence: 0.52,
          freshness: 0.71,
          fallbackRate: 0.2,
          reviewNeeded: false,
          syncState: 'active',
          healthCategory: SignatureHealthCategory.fallback,
          summary: 'Fallback source summary.',
        ),
        SignatureHealthRecord(
          sourceId: 'feedback-1',
          provider: 'user_feedback',
          entityType: 'suggested_list',
          categoryLabel: 'soft_ignore',
          sourceLabel: 'Suggested list feedback',
          confidence: 0.68,
          freshness: 0.92,
          fallbackRate: 0.0,
          reviewNeeded: false,
          updatedAt: DateTime(2026, 3, 6),
          syncState: 'active',
          healthCategory: SignatureHealthCategory.strong,
          summary: 'Soft ignore captured.',
        ),
      ],
    );

    setUpAll(() {
      registerFallbackValue(DateTime.utc(2026, 4, 4));
      registerFallbackValue(SignatureHealthReviewResolution.approved);
      registerFallbackValue(SignatureHealthPropagationResolution.approved);
      registerFallbackValue(
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate,
      );
      registerFallbackValue(
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate,
      );
      registerFallbackValue(
        SignatureHealthDownstreamRepropagationResolution.approve,
      );
    });

    setUp(() {
      getIt = GetIt.instance;
      service = MockSignatureHealthAdminService();
      controller = StreamController<SignatureHealthSnapshot>.broadcast();

      if (getIt.isRegistered<SignatureHealthAdminService>()) {
        getIt.unregister<SignatureHealthAdminService>();
      }
      getIt.registerSingleton<SignatureHealthAdminService>(service);

      when(() => service.watchSnapshot()).thenAnswer((_) => controller.stream);
      when(() => service.getSnapshot()).thenAnswer((_) async => snapshot);
      when(() => service.getKernelGraphRun(any()))
          .thenAnswer((invocation) async {
        final runId = invocation.positionalArguments.first.toString();
        for (final run in snapshot.kernelGraphRuns) {
          if (run.runId == runId) {
            return run;
          }
        }
        return null;
      });
      when(
        () => service.acknowledgeLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
          alertSeverityCode: any(named: 'alertSeverityCode'),
        ),
      ).thenAnswer((_) async => snapshot);
      when(
        () => service.escalateLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
          alertSeverityCode: any(named: 'alertSeverityCode'),
        ),
      ).thenAnswer((_) async => snapshot);
      when(
        () => service.snoozeLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
          alertSeverityCode: any(named: 'alertSeverityCode'),
          snoozedUntilUtc: any(named: 'snoozedUntilUtc'),
        ),
      ).thenAnswer((_) async => snapshot);
      when(
        () => service.clearEscalatedLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
        ),
      ).thenAnswer((_) async => snapshot);
      when(
        () => service.unsnoozeLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
        ),
      ).thenAnswer((_) async => snapshot);
      when(
        () => service.resolveReviewItem(
          reviewItemId: any(named: 'reviewItemId'),
          resolution: any(named: 'resolution'),
        ),
      ).thenAnswer(
        (invocation) async {
          final reviewItemId =
              invocation.namedArguments[#reviewItemId] as String;
          if (reviewItemId == 'review-up-1') {
            return const SignatureHealthReviewResolutionResult(
              reviewItemId: 'review-up-1',
              resolution: SignatureHealthReviewResolution.approved,
              hierarchySynthesisPlanJsonPath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_plan.json',
              hierarchySynthesisPlanReadmePath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/UPWARD_HIERARCHY_SYNTHESIS_PLAN_README.md',
              hierarchySynthesisOutcomeJsonPath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_outcome.json',
              hierarchySynthesisOutcomeReadmePath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/UPWARD_HIERARCHY_SYNTHESIS_OUTCOME_README.md',
              realityModelAgentHandoffJsonPath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_handoff.json',
              realityModelAgentHandoffReadmePath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_AGENT_HANDOFF_README.md',
              realityModelAgentOutcomeJsonPath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_outcome.json',
              realityModelAgentOutcomeReadmePath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_AGENT_OUTCOME_README.md',
              realityModelTruthReviewJsonPath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_truth_review.json',
              realityModelTruthReviewReadmePath:
                  '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_TRUTH_REVIEW_README.md',
            );
          }
          return const SignatureHealthReviewResolutionResult(
            reviewItemId: 'review-sim-1',
            resolution: SignatureHealthReviewResolution.approved,
            executionQueueJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_execution_queue.json',
            executionQueueReadmePath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/SIMULATION_TRAINING_EXECUTION_QUEUE_README.md',
            learningExecutionJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_learning_execution.json',
            learningExecutionReadmePath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/REALITY_MODEL_LEARNING_EXECUTION_README.md',
            downstreamPropagationPlanJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/downstream_agent_propagation_plan.json',
            learningOutcomeJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/reality_model_learning_outcome.json',
            learningOutcomeReadmePath:
                '/tmp/AVRAI/simulation_learning_bundles/atx/REALITY_MODEL_LEARNING_OUTCOME_README.md',
          );
        },
      );
      when(
        () => service.resolvePropagationTarget(
          sourceId: any(named: 'sourceId'),
          targetId: any(named: 'targetId'),
          resolution: any(named: 'resolution'),
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthPropagationResolutionResult(
          sourceId: 'simulation_training_source_atx',
          targetId: 'hierarchy:locality',
          resolution: SignatureHealthPropagationResolution.approved,
          downstreamPropagationPlanJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/downstream_agent_propagation_plan.json',
          propagationReceiptJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_receipt_hierarchy_locality.json',
          propagationReceiptReadmePath:
              '/tmp/AVRAI/simulation_learning_bundles/atx/HIERARCHY_DOMAIN_DELTA_RECEIPT_HIERARCHY_LOCALITY.md',
        ),
      );
      when(
        () => service.resolveTruthReview(
          sourceId: any(named: 'sourceId'),
          resolution: any(named: 'resolution'),
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthTruthReviewResolutionResult(
          sourceId: 'upward_learning_source_user_123_msg_1',
          resolution:
              SignatureHealthTruthReviewResolution.promoteToUpdateCandidate,
          realityModelTruthReviewJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_truth_review.json',
          realityModelTruthReviewReadmePath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_TRUTH_REVIEW_README.md',
          realityModelUpdateCandidateJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_candidate.json',
          realityModelUpdateCandidateReadmePath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_UPDATE_CANDIDATE_README.md',
        ),
      );
      when(
        () => service.resolveRealityModelUpdateCandidate(
          sourceId: any(named: 'sourceId'),
          resolution: any(named: 'resolution'),
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthRealityModelUpdateResolutionResult(
          sourceId: 'upward_learning_source_user_123_msg_1',
          resolution:
              SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate,
          realityModelUpdateCandidateJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_candidate.json',
          realityModelUpdateDecisionJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_decision.json',
          realityModelUpdateDecisionReadmePath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_UPDATE_DECISION_README.md',
          realityModelUpdateOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_outcome.json',
          realityModelUpdateOutcomeReadmePath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_UPDATE_OUTCOME_README.md',
        ),
      );
      when(
        () => service.startRealityModelUpdateValidationSimulation(
          sourceId: any(named: 'sourceId'),
        ),
      ).thenAnswer(
        (_) async =>
            const SignatureHealthRealityModelUpdateSimulationStartResult(
          sourceId: 'upward_learning_source_user_123_msg_1',
          realityModelUpdateSimulationSuggestionJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_validation_simulation_suggestion.json',
          realityModelUpdateSimulationRequestJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_validation_simulation_request.json',
          realityModelUpdateSimulationRequestReadmePath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/REALITY_MODEL_UPDATE_VALIDATION_SIMULATION_REQUEST_README.md',
          realityModelUpdateSimulationOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_validation_simulation_outcome.json',
          realityModelUpdateDownstreamRepropagationReviewJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_review.json',
        ),
      );
      when(
        () => service.resolveRealityModelUpdateDownstreamRepropagation(
          sourceId: any(named: 'sourceId'),
          resolution: any(named: 'resolution'),
        ),
      ).thenAnswer(
        (_) async =>
            const SignatureHealthDownstreamRepropagationResolutionResult(
          sourceId: 'upward_learning_source_user_123_msg_1',
          resolution: SignatureHealthDownstreamRepropagationResolution.approve,
          realityModelUpdateDownstreamRepropagationReviewJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_review.json',
          realityModelUpdateDownstreamRepropagationDecisionJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_decision.json',
          realityModelUpdateDownstreamRepropagationOutcomeJsonPath:
              '/tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_outcome.json',
        ),
      );
    });

    tearDown(() async {
      await controller.close();
      if (getIt.isRegistered<SignatureHealthAdminService>()) {
        getIt.unregister<SignatureHealthAdminService>();
      }
    });

    testWidgets('renders live signature health sections', (tester) async {
      final router = GoRouter(
        initialLocation: '/signature',
        routes: [
          GoRoute(
            path: '/signature',
            builder: (context, state) => const SignatureSourceHealthPage(),
          ),
          GoRoute(
            path: AdminRoutePaths.worldSimulationLab,
            builder: (context, state) => Text(
              'World Simulation Lab focus=${state.uri.queryParameters['focus']} attention=${state.uri.queryParameters['attention']}',
            ),
          ),
          GoRoute(
            path: AdminRoutePaths.realitySystemReality,
            builder: (context, state) => Text(
              'Reality route focus=${state.uri.queryParameters['focus']} attention=${state.uri.queryParameters['attention']}',
            ),
          ),
          GoRoute(
            path: AdminRoutePaths.realitySystemWorld,
            builder: (context, state) => Text(
              'World route focus=${state.uri.queryParameters['focus']} attention=${state.uri.queryParameters['attention']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      controller.add(snapshot);
      await tester.pumpAndSettle();

      expect(find.text('Signature + Source Health'), findsOneWidget);
      expect(find.text('Live signature + intake health'), findsOneWidget);
      expect(find.textContaining('Strong: 1'), findsOneWidget);
      expect(find.textContaining('Soft ignore: 1'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Feedback trend by entity type'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Feedback trend by entity type'), findsOneWidget);
      expect(find.text('suggested_list'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recent KernelGraph runs'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Recent KernelGraph runs'), findsOneWidget);
      expect(find.text('Governed upward intake persistence'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Review Queue'), findsOneWidget);
      expect(
        find.text('Deeper training intake review for atx-replay-world-2024'),
        findsOneWidget,
      );
      expect(
        find.text('Upward learning review: personal-agent human intake'),
        findsOneWidget,
      );
      expect(find.text('Simulation training'), findsOneWidget);
      expect(find.text('Upward learning'), findsOneWidget);
      expect(find.textContaining('atx-replay-world-2024'), findsWidgets);
      expect(
        find.textContaining(
            'City-pack structural ref: city_pack:atx_core_2024'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Conviction tier: personal_agent_human_observation'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Domain hints: locality, place'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Referenced entities: downtown coffee shop, recommendation:spot_123',
        ),
        findsOneWidget,
      );
      final acceptButton = find.byIcon(Icons.check_circle_outline).first;
      await tester.ensureVisible(acceptButton);
      await tester.pumpAndSettle();
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();
      verify(
        () => service.resolveReviewItem(
          reviewItemId: 'review-sim-1',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Review accepted and reality-model learning outcome saved: /tmp/AVRAI/simulation_learning_bundles/atx/reality_model_learning_outcome.json',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Living City-Pack Basis'), findsOneWidget);
      expect(
        find.textContaining(
          'Basis: expired latest-state served basis • Revalidation: current • Recovery: not reviewed',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Hydration: expired basis ready for restore review • Readiness: ready for bounded served-basis restore',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Shared review surfaces only mirror this posture. Restore/restage remains lab-only.',
        ),
        findsOneWidget,
      );
      final openRecoveryReviewButton =
          find.widgetWithText(OutlinedButton, 'Open recovery review in lab');
      expect(openRecoveryReviewButton, findsOneWidget);
      expect(find.text('Family Restage Intake Follow-up'), findsOneWidget);
      expect(
        find.textContaining(
            'app observations • restage intake review approved'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up review item: family_restage_follow_up_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Follow-up resolution: approved'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up resolution artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Resolution review item: family_restage_resolution_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Resolution queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Resolution outcome: approved_for_bounded_family_restage_execution',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Resolution outcome artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Execution review item: family_restage_execution_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Execution queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Execution outcome: approved_for_bounded_family_restage_application',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Execution outcome artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Application review item: family_restage_application_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Application queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Application outcome: approved_for_bounded_family_restage_apply_to_served_basis',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Application outcome artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Apply review item: family_restage_apply_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Apply queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Apply outcome: approved_for_bounded_family_restage_served_basis_update',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Apply outcome artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Served-basis update review item: family_restage_served_basis_update_review_atx-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Served-basis update queue artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Served-basis update outcome: approved_for_bounded_family_restage_served_basis_mutation',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Served-basis update outcome artifact: /tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Open intake review in lab'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Reality-Model Learning Outcomes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Reality-Model Learning Outcomes'), findsOneWidget);
      expect(find.text('Post-learning chain'), findsOneWidget);
      expect(
        find.textContaining(
          'simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> domain propagation delta',
        ),
        findsOneWidget,
      );
      expect(find.text('ATX • atx-replay-world-2024'), findsOneWidget);
      expect(find.text('Propagation ready'), findsOneWidget);
      expect(
        find.textContaining(
            'Admin evidence refresh: /tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Supervisor feedback state: /tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Upward Learning Handoffs'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Upward Learning Handoffs'), findsOneWidget);
      expect(find.text('Upward chain'), findsOneWidget);
      expect(
        find.textContaining(
          'Personal or AI2AI intake -> hierarchy synthesis -> reality-model agent',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Reality-model-agent handoff: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_handoff.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up prompt: What felt off about "Heatwave Cafe" for you right then?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up answer: It felt too loud and crowded for what I wanted.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Follow-up completion: assistant_follow_up_chat'),
        findsOneWidget,
      );
      expect(find.text('Chat loop'), findsOneWidget);
      expect(
        find.textContaining(
          'Observations: 3 • ack 1 • follow-up 1 • corrected 1',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Latest chat outcome: requested follow-up • validation validated by surfaced adoption • governance reinforced by governance',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Open pressure: follow-up 1 • corrected 1 • forgot 0 • stop using 0 • latest attention pending attention',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Attention disposition: attention pending while governance review is still open',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Latest chat question: Show me what this came from.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Latest governance stage: reality-model truth review',
        ),
        findsOneWidget,
      );
      expect(find.text('Chat follow-up pressure'), findsOneWidget);
      expect(
        find.textContaining('Signal tags: source:human, domain:place'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Preference signals: place_preference=coffee_shop',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Hierarchy synthesis outcome: /tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_outcome.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Reality-model-agent outcome: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_agent_outcome.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Truth/conviction review: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_truth_review.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Truth integration status: needs_governed_truth_validation_against_real_world',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Reality-model update candidate: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_candidate.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Admin dashboard brief: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_admin_brief.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Supervisor/daemon brief: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_supervisor_brief.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Validation simulation suggestion: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_validation_simulation_suggestion.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Downstream re-propagation review: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_review.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Downstream re-propagation plan: /tmp/AVRAI/upward_learning_bundles/user_123/reality_model_update_downstream_repropagation_plan.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Released follow-on lanes: admin:unknown_environment, supervisor:unknown_environment, hierarchy:locality',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'admin, supervisor, and assistant observers can all inspect the same bounded follow-on plan',
        ),
        findsOneWidget,
      );
      final startValidationSimulationButton = find.byKey(
        const Key('signatureSourceHealthStartValidationSimulationButton'),
      );
      expect(startValidationSimulationButton, findsOneWidget);
      expect(find.text('Hold for evidence'), findsOneWidget);
      expect(find.text('Reject integration'), findsOneWidget);
      await tester.scrollUntilVisible(
        startValidationSimulationButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(startValidationSimulationButton);
      await tester.pumpAndSettle();
      await tester.tap(startValidationSimulationButton);
      await tester.pumpAndSettle();
      verify(
        () => service.startRealityModelUpdateValidationSimulation(
          sourceId: 'upward_learning_source_user_123_msg_1',
        ),
      ).called(1);
      final approveDownstreamRepropagationButton = find.byKey(
        const Key('signatureSourceHealthApproveDownstreamRepropagationButton'),
      );
      expect(approveDownstreamRepropagationButton, findsOneWidget);
      await tester.scrollUntilVisible(
        approveDownstreamRepropagationButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(approveDownstreamRepropagationButton);
      await tester.pumpAndSettle();
      verify(
        () => service.resolveRealityModelUpdateDownstreamRepropagation(
          sourceId: 'upward_learning_source_user_123_msg_1',
          resolution: SignatureHealthDownstreamRepropagationResolution.approve,
        ),
      ).called(1);
      expect(find.text('Open reality-model lane'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining(
          'Admin evidence refresh now mirrors the bounded learning outcome',
        ),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Admin evidence refresh now mirrors the bounded learning outcome',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Supervisor feedback allows a bounded retry with operator visibility.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Supervisor recommendation: Allow bounded retry with visibility',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('World Simulation Lab Review Queue'), findsOneWidget);
      expect(find.text('Active bounded review candidates'), findsOneWidget);
      expect(find.text('Tracked downgraded targets'), findsOneWidget);
      expect(
        find.text(
          'Within each queue, higher-risk routing posture and stronger runtime regression signals rise first.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sort queue by'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Priority'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Bounded alerts'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, 'Provenance churn'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, 'Recently changed'),
        findsOneWidget,
      );
      expect(find.textContaining('Escalation summary:'), findsOneWidget);
      expect(
        find.textContaining('highest provenance churn: elevated'),
        findsOneWidget,
      );
      expect(
        find.textContaining('highest bounded alert: watch'),
        findsOneWidget,
      );
      expect(find.text('Bounded review candidate'), findsOneWidget);
      expect(
        find.textContaining('Target: Heatwave mitigation lane'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Target: Downtown calibration lane'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Target: Riverfront realism lane'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Latest lab outcome: accepted'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Latest rerun: job completed'),
        findsNWidgets(3),
      );
      expect(
        find.text('Runtime trend: Improving within bounded runtime drift.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Runtime trend: Mixed drift; operator review still required.'),
        findsOneWidget,
      );
      expect(
        find.text('Outcome trend: improved from denial to accepted evidence.'),
        findsOneWidget,
      );
      expect(find.text('Latest provenance delta'), findsNWidgets(2));
      expect(
        find.text('Provenance history: 4 persisted samples tracked.'),
        findsOneWidget,
      );
      expect(
        find.text('Provenance history: 3 persisted samples tracked.'),
        findsOneWidget,
      );
      expect(find.text('Recent provenance changes'), findsNWidgets(2));
      expect(
        find.text(
          'Provenance churn: Elevated realism-pack churn across recent persisted samples.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Provenance churn: Targeted realism-pack changes detected in recent persisted samples.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Bounded alert: review this lane closely because runtime instability and provenance churn are both present.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mark alert seen'), findsOneWidget);
      expect(
        find.textContaining(
          'Added sidecars: world_models/atx/jepa_geo_realism_v2.json',
        ),
        findsNWidgets(2),
      );
      expect(
        find.textContaining(
          'Completed rerun @ 2026-04-02T09:05:00Z vs prior sample',
        ),
        findsOneWidget,
      );
      final downtownTarget = find.textContaining(
        'Target: Downtown calibration lane',
      );
      final riverfrontTarget = find.textContaining(
        'Target: Riverfront realism lane',
      );
      expect(
        tester.getTopLeft(downtownTarget).dy,
        lessThan(tester.getTopLeft(riverfrontTarget).dy),
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Recently changed'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final recentlyChangedChip =
          find.widgetWithText(ChoiceChip, 'Recently changed');
      await tester.ensureVisible(recentlyChangedChip);
      await tester.pumpAndSettle();
      await tester.tap(recentlyChangedChip);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('sort: Recently changed'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(riverfrontTarget).dy,
        lessThan(tester.getTopLeft(downtownTarget).dy),
      );
      expect(
        find.textContaining(
          'Current routing posture: candidate for bounded review',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Current routing posture: watch closely'),
        findsNWidgets(2),
      );
      final provenanceChurnChip =
          find.widgetWithText(ChoiceChip, 'Provenance churn');
      await tester.ensureVisible(provenanceChurnChip);
      await tester.pumpAndSettle();
      await tester.tap(provenanceChurnChip);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('sort: Provenance churn'),
        findsOneWidget,
      );
      final boundedAlertsChip =
          find.widgetWithText(ChoiceChip, 'Bounded alerts');
      await tester.ensureVisible(boundedAlertsChip);
      await tester.pumpAndSettle();
      await tester.tap(boundedAlertsChip);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('sort: Bounded alerts'),
        findsOneWidget,
      );
      final markAlertSeenButton = find.widgetWithText(
        ActionChip,
        'Mark alert seen',
      );
      await tester.ensureVisible(markAlertSeenButton);
      await tester.pumpAndSettle();
      await tester.tap(markAlertSeenButton);
      await tester.pumpAndSettle();
      verify(
        () => service.acknowledgeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
        ),
      ).called(1);
      expect(find.text('Open bounded review'), findsOneWidget);
      expect(
        find.textContaining('Open World Simulation Lab'),
        findsNWidgets(3),
      );
      expect(
        find.textContaining('Open Reality Oversight'),
        findsNWidgets(2),
      );
      expect(
          find.widgetWithText(ChoiceChip, 'All environments'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Austin Simulation Environment 2024'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, 'Savannah Simulation Environment 2024'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'All environments'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All environments'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Austin Simulation Environment 2024'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Austin Simulation Environment 2024'),
      );
      await tester.pumpAndSettle();
      expect(
          find.widgetWithText(ChoiceChip, 'All target lanes'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Heatwave mitigation lane'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, 'Downtown calibration lane'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Downtown calibration lane'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Downtown calibration lane'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Showing target lane Downtown calibration lane.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Target: Downtown calibration lane'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'All environments'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All environments'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining(
          'Lane artifact: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Lane artifact: /tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_locality.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Governed lower-tier `locality` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Bounded use: Apply this only as a domain-scoped delta'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'The personal agent may now personalize the governed `locality` knowledge that was synthesized by the hierarchy above',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Personalization mode: final_contextualization_after_hierarchy_synthesis',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Approve propagation').first);
      await tester.pumpAndSettle();
      verify(
        () => service.resolvePropagationTarget(
          sourceId: 'simulation_training_source_atx',
          targetId: 'hierarchy:locality',
          resolution: SignatureHealthPropagationResolution.approved,
        ),
      ).called(1);

      await tester.scrollUntilVisible(
        find.text('Deeper training intake review for atx-replay-world-2024'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final openRealityLaneButton =
          find.widgetWithText(OutlinedButton, 'Open reality lane').first;
      await tester.scrollUntilVisible(
        openRealityLaneButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(openRealityLaneButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Reality route focus=atx-replay-world-2024'),
        findsOneWidget,
      );
    });

    testWidgets('opens KernelGraph run drill-down details', (tester) async {
      final router = GoRouter(
        initialLocation: AdminRoutePaths.signatureHealth,
        routes: [
          GoRoute(
            path: AdminRoutePaths.signatureHealth,
            builder: (context, state) => SignatureSourceHealthPage(
              initialFocus: state.uri.queryParameters['focus'],
              initialAttention: state.uri.queryParameters['attention'],
            ),
          ),
          GoRoute(
            path: AdminRoutePaths.kernelGraphRunDetailPattern,
            builder: (context, state) => KernelGraphRunDetailPage(
              runId: state.pathParameters['id'] ?? 'unknown_run',
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      controller.add(snapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Recent KernelGraph runs'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final detailsButton = find.widgetWithText(OutlinedButton, 'Open details');
      expect(detailsButton, findsOneWidget);
      await tester.ensureVisible(detailsButton);
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.byType(KernelGraphRunDetailPage), findsOneWidget);
      expect(find.text('KernelGraph Run'), findsOneWidget);
      expect(find.text('Governed upward intake persistence'), findsOneWidget);
      expect(find.text('Completed 3 of 3 nodes.'), findsOneWidget);
      expect(find.text('kernel-graph-run-1'), findsOneWidget);
      expect(
        find.text('kernel_graph:upward_learning_source_user_123_msg_1'),
        findsOneWidget,
      );
      expect(find.text('Human review required'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Node receipts'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final sourceReceiptTile = find.widgetWithText(
        ExpansionTile,
        'persist_source_descriptor',
      );
      expect(sourceReceiptTile, findsOneWidget);
      await tester.tap(sourceReceiptTile);
      await tester.pumpAndSettle();
      expect(find.text('Artifact drill-down'), findsOneWidget);
      expect(
        find.text('Personal-agent human upward learning'),
        findsWidgets,
      );
      expect(find.text('matches run source'), findsOneWidget);
      expect(find.text('lineage ref'), findsOneWidget);
      expect(find.text('Copy ref'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);
      final openInSignatureHealthButton = find.text('Open in Signature Health');
      expect(openInSignatureHealthButton, findsOneWidget);
      expect(find.text('Artifact payload JSON'), findsOneWidget);
      expect(find.text('Node metadata JSON'), findsOneWidget);
      await tester.ensureVisible(find.text('Artifact payload JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artifact payload JSON'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(
              '"sourceProvider": "personal_agent_human_intake"'),
          findsOneWidget);
      await tester.ensureVisible(openInSignatureHealthButton.first);
      await tester.pumpAndSettle();
      await tester.tap(openInSignatureHealthButton.first);
      await tester.pump();
      controller.add(snapshot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SignatureSourceHealthPage), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.queryParameters['focus'],
        'upward_learning_source_user_123_msg_1',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['attention'],
        'source',
      );
      expect(
        find.textContaining(
          'Focus: upward_learning_source_user_123_msg_1',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Review items: 1', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('KG runs: 1', skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('opens served-basis recovery review in lab', (tester) async {
      final router = GoRouter(
        initialLocation: AdminRoutePaths.signatureHealth,
        routes: [
          GoRoute(
            path: AdminRoutePaths.signatureHealth,
            builder: (context, state) => SignatureSourceHealthPage(
              initialFocus: state.uri.queryParameters['focus'],
              initialAttention: state.uri.queryParameters['attention'],
            ),
          ),
          GoRoute(
            path: AdminRoutePaths.worldSimulationLab,
            builder: (context, state) => Text(
              'World Simulation Lab focus=${state.uri.queryParameters['focus']} attention=${state.uri.queryParameters['attention']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      controller.add(snapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final openRecoveryReviewButton =
          find.widgetWithText(OutlinedButton, 'Open recovery review in lab');
      expect(openRecoveryReviewButton, findsOneWidget);
      await tester.ensureVisible(openRecoveryReviewButton.first);
      await tester.pumpAndSettle();
      await tester.tap(openRecoveryReviewButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(
          'World Simulation Lab focus=atx-replay-world-2024 attention=served_basis_recovery:restore_review',
        ),
        findsOneWidget,
      );
    });

    testWidgets('marks visible bounded alerts seen in bulk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignatureSourceHealthPage(),
        ),
      );

      controller.add(snapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Mark 1 visible alert seen',
      );
      expect(bulkButton, findsOneWidget);
      await tester.ensureVisible(bulkButton);
      await tester.pumpAndSettle();
      await tester.tap(bulkButton);
      await tester.pumpAndSettle();

      verify(
        () => service.acknowledgeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
        ),
      ).called(1);
    });

    testWidgets('snoozes visible bounded alerts in bulk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignatureSourceHealthPage(),
        ),
      );

      controller.add(snapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Snooze 1 visible alert lane',
      );
      expect(bulkButton, findsOneWidget);
      await tester.ensureVisible(bulkButton);
      await tester.pumpAndSettle();
      await tester.tap(bulkButton);
      await tester.pumpAndSettle();

      verify(
        () => service.snoozeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
          snoozedUntilUtc: any(named: 'snoozedUntilUtc'),
        ),
      ).called(1);
    });

    testWidgets('unsnoozes visible bounded alerts in bulk', (tester) async {
      final snoozedSnapshot = SignatureHealthSnapshot(
        generatedAt: DateTime.utc(2026, 4, 2, 15),
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
        labTargetActionItems: <SignatureHealthLabTargetActionItem>[
          SignatureHealthLabTargetActionItem(
            environmentId: 'atx-replay-world-2024',
            displayName: 'Austin Simulation Environment 2024',
            cityCode: 'atx',
            replayYear: 2024,
            suggestedAction: 'candidate_for_bounded_review',
            suggestedReason: 'One more watched pass is still required.',
            selectedAction: 'watch_closely',
            acceptedSuggestion: false,
            updatedAt: DateTime.utc(2026, 4, 2, 8),
            variantId: 'variant-downtown-lane',
            variantLabel: 'Downtown calibration lane',
            cityPackStructuralRef: 'city_pack:atx_core_2024',
            latestOutcomeDisposition: 'draft',
            latestRerunRequestStatus: 'completed',
            latestRerunJobStatus: 'completed',
            boundedAlertSummary:
                const SignatureHealthLabTargetBoundedAlertSummary(
              severityCode: 'watch',
              summary:
                  'Bounded alert: review this lane closely because runtime instability and provenance churn are both present.',
            ),
            alertAcknowledgedAt: DateTime.utc(2026, 4, 2, 8, 30),
            alertAcknowledgedSeverityCode: 'watch',
            alertSnoozedUntil: DateTime.utc(2099, 4, 3, 12),
            alertSnoozedSeverityCode: 'watch',
          ),
        ],
      );

      when(() => service.getSnapshot())
          .thenAnswer((_) async => snoozedSnapshot);
      when(() => service.watchSnapshot()).thenAnswer((_) => controller.stream);
      when(
        () => service.unsnoozeLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
        ),
      ).thenAnswer((_) async => snoozedSnapshot);

      await tester.pumpWidget(
        const MaterialApp(
          home: SignatureSourceHealthPage(),
        ),
      );

      controller.add(snoozedSnapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 snoozed visible lane'), findsOneWidget);
      expect(
        find.text(
            'Next unsnooze: 2099-04-03T12:00:00.000Z (7d+ after this snapshot)'),
        findsOneWidget,
      );

      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Unsnooze 1 visible alert lane',
      );
      expect(bulkButton, findsOneWidget);
      await tester.ensureVisible(bulkButton);
      await tester.pumpAndSettle();
      await tester.tap(bulkButton);
      await tester.pumpAndSettle();

      verify(
        () => service.unsnoozeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
        ),
      ).called(1);
    });

    testWidgets('snoozes a lane-level bounded alert', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignatureSourceHealthPage(),
        ),
      );

      controller.add(snapshot);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final snoozeButton = find.widgetWithText(ActionChip, 'Snooze 24h');
      expect(snoozeButton, findsOneWidget);
      await tester.ensureVisible(snoozeButton);
      await tester.pumpAndSettle();
      await tester.tap(snoozeButton);
      await tester.pumpAndSettle();

      verify(
        () => service.snoozeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
          snoozedUntilUtc: any(named: 'snoozedUntilUtc'),
        ),
      ).called(1);
    });
  });
}
