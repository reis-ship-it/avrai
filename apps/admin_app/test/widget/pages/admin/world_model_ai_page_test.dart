import 'package:avrai_admin_app/ui/pages/world_model_ai_page.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('WorldModelAiPage', () {
    setUpAll(() {
      registerFallbackValue(DateTime.utc(2026, 4, 4));
    });

    tearDown(() async {
      if (GetIt.instance.isRegistered<RealityModelStatusService>()) {
        await GetIt.instance.unregister<RealityModelStatusService>();
      }
    });

    testWidgets('renders port-backed reality-model contract status',
        (WidgetTester tester) async {
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
                RealityModelDomain.locality,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary:
                'Active contract reality_model_wave1_bham_beta (2026.03-wave1) is running in kernel_backed_wave1 mode with 5 bounded evidence refs.',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const WorldModelAiPage(),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Reality Model'), findsOneWidget);
      expect(find.text('Active Reality Model Contract'), findsOneWidget);
      expect(find.text('Mode: Kernel Backed Wave1'), findsOneWidget);
      expect(
        find.text('Contract: reality_model_wave1_bham_beta (2026.03-wave1)'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces latest supervisor learning posture',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
                RealityModelDomain.locality,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 1, 15),
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
            servedBasisSummaries: <SignatureHealthServedBasisSummary>[
              SignatureHealthServedBasisSummary(
                environmentId: 'atx-replay-world-2024',
                displayName: 'Austin Simulation Environment 2024',
                cityCode: 'atx',
                replayYear: 2024,
                supportedPlaceRef: 'place:atx',
                cityPackStructuralRef: 'city_pack:atx_core_2024',
                currentBasisStatus: 'expired_latest_state_served_basis',
                latestStateHydrationStatus:
                    'expired_basis_ready_for_restore_review',
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
                followUpQueueStatus:
                    'queued_for_family_restage_follow_up_review',
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
                restageApplyQueueStatus:
                    'queued_for_family_restage_apply_review',
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
            labTargetActionItems: <SignatureHealthLabTargetActionItem>[
              SignatureHealthLabTargetActionItem(
                environmentId: 'atx-replay-world-2024',
                displayName: 'Austin Simulation Environment 2024',
                cityCode: 'atx',
                replayYear: 2024,
                suggestedAction: 'watch_closely',
                suggestedReason:
                    'Recent executed reruns are stable enough for bounded review.',
                selectedAction: 'candidate_for_bounded_review',
                acceptedSuggestion: true,
                updatedAt: DateTime.utc(2026, 4, 2, 9),
                variantId: 'variant-heatwave-lane',
                variantLabel: 'Heatwave mitigation lane',
                cityPackStructuralRef: 'city_pack:atx_core_2024',
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
                      label:
                          'Completed rerun @ 2026-04-02T09:05:00Z vs prior sample',
                      details: <String>[
                        'Added artifact families: replay_learning_bundle',
                      ],
                    ),
                    SignatureHealthLabTargetProvenanceHistoryEntry(
                      label:
                          'Lab outcome @ 2026-04-02T08:40:00Z vs prior sample',
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
                      label:
                          'Lab outcome @ 2026-04-02T08:15:00Z vs prior sample',
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
                    'Recent executed reruns are stable enough for bounded review.',
                selectedAction: 'candidate_for_bounded_review',
                acceptedSuggestion: true,
                updatedAt: DateTime.utc(2026, 4, 2, 9),
                variantId: 'variant-heatwave-lane',
                variantLabel: 'Heatwave mitigation lane',
                cityPackStructuralRef: 'city_pack:atx_core_2024',
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
                      label:
                          'Completed rerun @ 2026-04-02T09:05:00Z vs prior sample',
                      details: <String>[
                        'Added artifact families: replay_learning_bundle',
                      ],
                    ),
                    SignatureHealthLabTargetProvenanceHistoryEntry(
                      label:
                          'Lab outcome @ 2026-04-02T08:40:00Z vs prior sample',
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
              SignatureHealthLearningOutcomeItem(
                sourceId: 'simulation_training_source_atx',
                environmentId: 'atx-replay-world-2024',
                cityCode: 'atx',
                learningPathway: 'deeper_reality_model_training',
                outcomeStatus: 'completed',
                summary: 'Reality-model learning completed locally.',
                updatedAt: DateTime.utc(2026, 4, 1, 14, 45),
                supervisorLearningFeedbackStateJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
                adminEvidenceRefreshSnapshotJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
                adminEvidenceRefreshSummary:
                    const SignatureHealthAdminEvidenceRefreshSummary(
                  status: 'executed_local_governed_evidence_refresh',
                  environmentId: 'atx-replay-world-2024',
                  cityCode: 'atx',
                  summary:
                      'Admin evidence refresh now reflects the bounded reality-model learning outcome for Austin.',
                  requestCount: 2,
                  recommendationCount: 1,
                  averageConfidence: 0.72,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
                ),
                supervisorFeedbackSummary:
                    const SignatureHealthSupervisorFeedbackSummary(
                  status: 'executed_local_governed_feedback',
                  environmentId: 'atx-replay-world-2024',
                  feedbackSummary:
                      'Supervisor learning has absorbed the local reality-model outcome and should use it as bounded evidence for later scheduling and recommendation posture.',
                  boundedRecommendation:
                      'allow_bounded_retry_with_operator_visibility',
                  requestCount: 2,
                  recommendationCount: 1,
                  averageConfidence: 0.72,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/atx/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
                ),
                propagationTargets: const <SignatureHealthPropagationTarget>[
                  SignatureHealthPropagationTarget(
                    targetId: 'hierarchy:locality',
                    propagationKind: 'prior_and_explanation_delta',
                    reason:
                        'Austin locality domain is ready for governed propagation.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    hierarchyDomainDeltaSummary:
                        SignatureHealthHierarchyDomainDeltaSummary(
                      status: 'executed_local_governed_domain_delta',
                      environmentId: 'atx-replay-world-2024',
                      domainId: 'locality',
                      summary:
                          'Locality hierarchy can now synthesize Austin replay evidence into a bounded lower-tier delta.',
                      boundedUse:
                          'Apply this only as a locality-scoped delta after approval.',
                      requestCount: 1,
                      recommendationCount: 1,
                      averageConfidence: 0.72,
                      downstreamConsumerSummary:
                          SignatureHealthDomainConsumerSummary(
                        status:
                            'executed_local_governed_domain_consumer_refresh',
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
                    targetId: 'hierarchy:mobility',
                    propagationKind: 'prior_and_explanation_delta',
                    reason:
                        'Austin mobility domain is ready for governed propagation.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    hierarchyDomainDeltaSummary:
                        SignatureHealthHierarchyDomainDeltaSummary(
                      status: 'executed_local_governed_domain_delta',
                      environmentId: 'atx-replay-world-2024',
                      domainId: 'mobility',
                      summary:
                          'Mobility hierarchy can now synthesize detour and corridor evidence into a bounded lower-tier delta.',
                      boundedUse:
                          'Apply this only as a mobility-scoped delta after approval.',
                      requestCount: 1,
                      recommendationCount: 1,
                      averageConfidence: 0.7,
                      downstreamConsumerSummary:
                          SignatureHealthDomainConsumerSummary(
                        status:
                            'executed_local_governed_domain_consumer_refresh',
                        consumerId: 'mobility_guidance_lane',
                        domainId: 'mobility',
                        summary:
                            'Mobility hierarchy deltas should now refresh bounded mobility guidance consumers so governed reality-model learning can improve route priors, corridor reasoning, and mobility-facing explanations.',
                        boundedUse:
                            'Use only for mobility-scoped guidance, detour reasoning, and explanation consumers; do not treat this as broad retraining of unrelated locality or event systems.',
                        targetedSystems: <String>[
                          'mobility_route_priors',
                          'mobility_corridor_reasoning',
                          'mobility_explanation_surfaces',
                        ],
                        jsonPath:
                            '/tmp/AVRAI/simulation_learning_bundles/atx/domain_consumer_state_mobility.json',
                      ),
                      jsonPath:
                          '/tmp/AVRAI/simulation_learning_bundles/atx/hierarchy_domain_delta_hierarchy_mobility.json',
                    ),
                  ),
                  SignatureHealthPropagationTarget(
                    targetId: 'personal_agent:mobility',
                    propagationKind: 'personalized_guidance_delta',
                    reason:
                        'Personal-agent mobility guidance may now be contextualized after hierarchy synthesis.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    personalAgentPersonalizationSummary:
                        SignatureHealthPersonalAgentPersonalizationSummary(
                      status: 'executed_local_governed_personalization_delta',
                      environmentId: 'atx-replay-world-2024',
                      domainId: 'mobility',
                      summary:
                          'Personal agent may now contextualize governed mobility guidance for the person.',
                      personalizationMode:
                          'final_contextualization_after_hierarchy_synthesis',
                      boundedUse:
                          'Use this only as the final personalized mobility guidance delta.',
                      requestCount: 1,
                      recommendationCount: 1,
                      averageConfidence: 0.7,
                      jsonPath:
                          '/tmp/AVRAI/simulation_learning_bundles/atx/personal_agent_personalization_delta_personal_agent_mobility.json',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.text('Supervisor Learning Posture'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Supervisor Learning Posture'), findsOneWidget);
      expect(find.text('ATX • atx-replay-world-2024'), findsOneWidget);
      expect(
        find.text('Allow bounded retry with visibility'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Bounded recommendation: allow_bounded_retry_with_operator_visibility',
        ),
        findsOneWidget,
      );
      expect(find.text('Admin Evidence Refresh'), findsOneWidget);
      expect(
        find.textContaining('Admin evidence refresh now reflects'),
        findsOneWidget,
      );
      expect(find.text('Governed Post-Learning Chain'), findsOneWidget);
      expect(find.text('Domain propagation delta • locality'), findsOneWidget);
      expect(find.text('Domain propagation delta • mobility'), findsOneWidget);
      expect(find.text('Domain consumer • locality_intelligence_lane'),
          findsOneWidget);
      expect(find.text('Domain consumer • mobility_guidance_lane'),
          findsOneWidget);
      expect(find.textContaining('Targeted systems: locality_priors'),
          findsOneWidget);
      expect(find.textContaining('Targeted systems: mobility_route_priors'),
          findsOneWidget);
      expect(
        find.text('Personal-agent personalization • mobility'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
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
      expect(find.text('Open recovery review in lab'), findsOneWidget);
      expect(find.text('Family Restage Intake Follow-up'), findsOneWidget);
      expect(
        find.textContaining(
          'app observations • restage intake review approved',
        ),
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
      expect(find.text('Open intake review in lab'), findsOneWidget);
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
      expect(find.text('Target: Heatwave mitigation lane'), findsOneWidget);
      expect(find.text('Target: Riverfront realism lane'), findsOneWidget);
      expect(find.text('Target: Downtown calibration lane'), findsOneWidget);
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
      final downtownTarget = find.text('Target: Downtown calibration lane');
      final riverfrontTarget = find.text('Target: Riverfront realism lane');
      expect(
        tester.getTopLeft(downtownTarget).dy,
        lessThan(tester.getTopLeft(riverfrontTarget).dy),
      );
      final recentlyChangedChip =
          find.widgetWithText(ChoiceChip, 'Recently changed');
      await tester.ensureVisible(recentlyChangedChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(recentlyChangedChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
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
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(provenanceChurnChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.textContaining('sort: Provenance churn'),
        findsOneWidget,
      );
      final boundedAlertsChip =
          find.widgetWithText(ChoiceChip, 'Bounded alerts');
      await tester.ensureVisible(boundedAlertsChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(boundedAlertsChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.textContaining('sort: Bounded alerts'),
        findsOneWidget,
      );
      expect(find.text('Open bounded review'), findsOneWidget);
      expect(find.text('Open World Simulation Lab'), findsNWidgets(3));
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

      final austinEnvironmentChip = find.widgetWithText(
        ChoiceChip,
        'Austin Simulation Environment 2024',
      );
      await tester.ensureVisible(austinEnvironmentChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(austinEnvironmentChip);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.text(
          'Showing queue posture for Austin Simulation Environment 2024.',
        ),
        findsOneWidget,
      );
      expect(find.text('Target: Heatwave mitigation lane'), findsOneWidget);
      expect(find.text('Target: Downtown calibration lane'), findsOneWidget);
      expect(find.text('Target: Riverfront realism lane'), findsNothing);
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
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Downtown calibration lane'),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.text('Showing target lane Downtown calibration lane.'),
        findsOneWidget,
      );
      expect(find.text('Target: Downtown calibration lane'), findsOneWidget);
      expect(find.text('Target: Heatwave mitigation lane'), findsNothing);
    });

    testWidgets('marks visible bounded alerts seen in bulk',
        (WidgetTester tester) async {
      final service = _MockSignatureHealthAdminService();
      final snapshot = SignatureHealthSnapshot(
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
          ),
        ],
      );
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
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthService: service,
          signatureHealthSnapshot: snapshot,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Mark 1 visible alert seen',
      );
      expect(bulkButton, findsOneWidget);
      await tester.tap(bulkButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => service.acknowledgeLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
        ),
      ).called(1);
    });

    testWidgets('escalates visible bounded alerts in bulk',
        (WidgetTester tester) async {
      final service = _MockSignatureHealthAdminService();
      final snapshot = SignatureHealthSnapshot(
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
          ),
        ],
      );
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
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthService: service,
          signatureHealthSnapshot: snapshot,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Escalate 1 visible alert lane',
      );
      expect(bulkButton, findsOneWidget);
      await tester.ensureVisible(bulkButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(bulkButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);

      verify(
        () => service.escalateLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
        ),
      ).called(1);
    });

    testWidgets('clears visible escalated alerts in bulk',
        (WidgetTester tester) async {
      final service = _MockSignatureHealthAdminService();
      final snapshot = SignatureHealthSnapshot(
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
            alertAcknowledgedAt: DateTime.utc(2026, 4, 2, 9, 30),
            alertAcknowledgedSeverityCode: 'watch',
            alertEscalatedAt: DateTime.utc(2026, 4, 2, 9),
            alertEscalatedSeverityCode: 'watch',
          ),
        ],
      );
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
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthService: service,
          signatureHealthSnapshot: snapshot,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('1 escalated visible lane'), findsOneWidget);
      expect(find.textContaining('6h before this snapshot'), findsOneWidget);

      final bulkButton = find.widgetWithText(
        OutlinedButton,
        'Clear escalation on 1 visible lane',
      );
      expect(bulkButton, findsOneWidget);
      await tester.ensureVisible(bulkButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(bulkButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);

      verify(
        () => service.clearEscalatedLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
        ),
      ).called(1);
    });

    testWidgets('shows next unsnooze timing for visible snoozed alerts',
        (WidgetTester tester) async {
      final service = _MockSignatureHealthAdminService();
      final snapshot = SignatureHealthSnapshot(
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
      when(
        () => service.unsnoozeLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
        ),
      ).thenAnswer((_) async => snapshot);
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthService: service,
          signatureHealthSnapshot: snapshot,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('1 snoozed visible lane'), findsOneWidget);
      expect(
        find.text(
            'Next unsnooze: 2099-04-03T12:00:00.000Z (7d+ after this snapshot)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Unsnooze 1 visible alert lane'),
        findsOneWidget,
      );
    });

    testWidgets('escalates a lane-level bounded alert',
        (WidgetTester tester) async {
      final service = _MockSignatureHealthAdminService();
      final snapshot = SignatureHealthSnapshot(
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
            suggestedReason: 'Downtown lane needs attention.',
            selectedAction: 'watch_closely',
            acceptedSuggestion: false,
            updatedAt: DateTime.utc(2026, 4, 2, 8),
            variantId: 'variant-downtown-lane',
            variantLabel: 'Downtown calibration lane',
            cityPackStructuralRef: 'city_pack:atx_core_2024',
            boundedAlertSummary:
                const SignatureHealthLabTargetBoundedAlertSummary(
              severityCode: 'watch',
              summary:
                  'Bounded alert: review this lane closely because runtime instability and provenance churn are both present.',
            ),
          ),
        ],
      );
      when(
        () => service.escalateLabTargetAlert(
          environmentId: any(named: 'environmentId'),
          variantId: any(named: 'variantId'),
          alertSeverityCode: any(named: 'alertSeverityCode'),
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
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthService: service,
          signatureHealthSnapshot: snapshot,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      final escalateButton = find.widgetWithText(ActionChip, 'Escalate lane');
      expect(escalateButton, findsOneWidget);
      await tester.ensureVisible(escalateButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(escalateButton);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => service.escalateLabTargetAlert(
          environmentId: 'atx-replay-world-2024',
          variantId: 'variant-downtown-lane',
          alertSeverityCode: 'watch',
        ),
      ).called(1);
    });

    testWidgets(
        'shows latest routing posture when no active bounded review candidate exists',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary: 'status summary',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldModelAiPage(
          signatureHealthSnapshot: SignatureHealthSnapshot(
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
              ),
            ],
            learningOutcomeItems: const <SignatureHealthLearningOutcomeItem>[],
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab Review Queue'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('World Simulation Lab Review Queue'), findsOneWidget);
      expect(find.text('Tracked downgraded targets'), findsOneWidget);
      expect(find.text('Target: Riverfront realism lane'), findsOneWidget);
      expect(
        find.textContaining('Current routing posture: watch closely'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Riverfront realism lane is not currently in the active bounded-review queue.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open Reality Oversight'), findsOneWidget);
      expect(find.text('Open World Simulation Lab'), findsOneWidget);
      expect(find.text('Open bounded review'), findsNothing);
    });
  });
}

class _FakeRealityModelStatusService extends RealityModelStatusService {
  _FakeRealityModelStatusService(this.snapshot);

  final RealityModelStatusSnapshot snapshot;

  @override
  Future<RealityModelStatusSnapshot> loadStatus() async => snapshot;
}

class _MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}
