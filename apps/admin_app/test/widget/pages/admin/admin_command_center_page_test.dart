import 'package:avrai_admin_app/ui/pages/admin_command_center_page.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/reality_model/reality_model_status_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/material.dart' show ListView, ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockAdminRuntimeGovernanceService extends Mock
    implements AdminRuntimeGovernanceService {}

class _MockBhamAdminOperationsService extends Mock
    implements BhamAdminOperationsService {}

class _MockReplaySimulationAdminService extends Mock
    implements ReplaySimulationAdminService {}

class _MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}

class _MockGovernedAutoresearchSupervisor extends Mock
    implements GovernedAutoresearchSupervisor {}

class _MockHeadlessAvraiOsHost extends Mock implements HeadlessAvraiOsHost {}

void main() {
  group('AdminCommandCenterPage Widget Tests', () {
    late _MockAdminRuntimeGovernanceService governanceService;
    late _MockBhamAdminOperationsService opsService;
    late _MockReplaySimulationAdminService replayService;
    late _MockSignatureHealthAdminService signatureHealthService;
    late _MockGovernedAutoresearchSupervisor researchSupervisor;
    late _MockHeadlessAvraiOsHost headlessOsHost;

    setUp(() {
      governanceService = _MockAdminRuntimeGovernanceService();
      opsService = _MockBhamAdminOperationsService();
      replayService = _MockReplaySimulationAdminService();
      signatureHealthService = _MockSignatureHealthAdminService();
      researchSupervisor = _MockGovernedAutoresearchSupervisor();
      headlessOsHost = _MockHeadlessAvraiOsHost();

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
          lastSignInPlatformCounts: AuthMixBucket(
            totalCounts: const <String, int>{'ios': 7, 'android': 5},
            recentCounts: const <String, int>{'ios': 2, 'android': 1},
          ),
        ),
        lastUpdated: DateTime.utc(2026, 3, 31, 12),
      );
      final activeAgents = <ActiveAIAgentData>[
        ActiveAIAgentData(
          userId: 'user-1',
          aiSignature: 'ai-1',
          latitude: 33.5,
          longitude: -86.8,
          isOnline: true,
          lastActive: DateTime.utc(2026, 3, 31, 12),
          aiConnections: 3,
          aiStatus: 'active',
          predictedActions: const <PredictionAction>[],
          currentStage: 'watching',
          confidence: 0.88,
        ),
      ];
      final communications = CommunicationsSnapshot(
        totalMessages: 30,
        recentMessages: const <dynamic>[],
        activeConnections: 4,
        lastUpdated: DateTime.utc(2026, 3, 31, 12),
      );
      final meshSnapshot = MeshTrustDiagnosticsSnapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 31, 12),
        trustedActiveAnnounceCount: 4,
        rejectedAnnounceCount: 1,
        rejectionReasonCounts: const <String, int>{'expired': 1},
        trustedReplayTriggerCount: 2,
        activeCredentialCount: 6,
        expiringSoonCredentialCount: 1,
        revokedCredentialCount: 0,
      );
      final rendezvousSnapshot = Ai2AiRendezvousDiagnosticsSnapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 31, 12),
        activeRendezvousCount: 3,
        releasedTicketCount: 2,
        blockedByConditionCount: 1,
        trustedRouteUnavailableBlockCount: 1,
        peerAppliedCount: 5,
        lastBlockedReason: 'trusted_route_unavailable',
      );
      final ambientSnapshot = AmbientSocialLearningDiagnosticsSnapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 31, 12),
        normalizedObservationCount: 10,
        candidateCoPresenceObservationCount: 7,
        confirmedInteractionPromotionCount: 4,
        duplicateMergeCount: 1,
        rejectedInteractionPromotionCount: 1,
        crowdUpgradeCount: 0,
        whatIngestionCount: 2,
        localityVibeUpdateCount: 3,
        personalDnaAuthorizedCount: 2,
        personalDnaAppliedCount: 2,
        latestNearbyPeerCount: 9,
        latestConfirmedInteractivePeerCount: 4,
      );
      final replaySnapshot = ReplaySimulationAdminSnapshot(
        generatedAt: DateTime.utc(2026, 3, 31, 12),
        environmentId: 'bham-replay-world-2023',
        cityCode: 'bham',
        replayYear: 2023,
        scenarios: <ReplayScenarioPacket>[
          ReplayScenarioPacket(
            scenarioId: 'storm-1',
            name: 'Storm corridor surge',
            description: 'Weather pressure against a downtown corridor.',
            cityCode: 'bham',
            baseReplayYear: 2023,
            scenarioKind: ReplayScenarioKind.weather,
            scope: ReplayScopeKind.corridor,
            seedEntityRefs: const <String>['entity-1'],
            seedLocalityCodes: const <String>['downtown'],
            seedObservationRefs: const <String>['obs-1'],
            interventions: const <ReplayScenarioIntervention>[],
            expectedQuestions: const <String>['What breaks first?'],
            createdAt: DateTime.utc(2026, 3, 31, 12),
            createdBy: 'test',
          ),
        ],
        comparisons: <ReplayScenarioComparison>[
          ReplayScenarioComparison(
            scenarioId: 'storm-1',
            baselineRunId: 'baseline-1',
            branchRunIds: const <String>['branch-1'],
            branchDiffs: const <ReplayScenarioBranchDiff>[
              ReplayScenarioBranchDiff(
                branchRunId: 'branch-1',
                attendanceDelta: 0.2,
                movementDelta: -0.1,
                deliveryDelta: -0.2,
                safetyStressDelta: 0.3,
                localityPressureDeltas: <String, double>{'downtown': 0.4},
                keyNarrativeLines: <String>[
                  'Downtown absorbs the first shock.'
                ],
              ),
            ],
            summary: 'Downtown carries the highest replay stress.',
            generatedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        receipts: const <SimulationTruthReceipt>[],
        contradictions: <ReplayContradictionSnapshot>[
          ReplayContradictionSnapshot(
            snapshotId: 'contr-1',
            runId: 'branch-1',
            entityRef: 'entity-1',
            localityCode: 'downtown',
            contradictionType: ReplayContradictionType.localityPressure,
            replayExpectation: 'moderate',
            liveObserved: 'high',
            severity: 0.72,
            status: ReplayContradictionStatus.open,
            capturedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        localityOverlays: <ReplayLocalityOverlaySnapshot>[
          ReplayLocalityOverlaySnapshot(
            localityCode: 'downtown',
            displayName: 'Downtown',
            pressureBand: 'high',
            attentionBand: 'urgent',
            primarySignals: <String>['weather_shift', 'support_deficit'],
            branchSensitivity: 0.82,
            contradictionCount: 1,
            updatedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        foundation: const ReplaySimulationAdminFoundationSummary(
          simulationMode: 'generic_city_pack',
          intakeFlowRefs: <String>[
            'source_intake_orchestrator',
            'air_gap_normalizer',
          ],
          sidecarRefs: <String>['city_packs/bham/2023_manifest.json'],
          metadata: <String, dynamic>{
            'cityPackStructuralRef': 'city_pack:bham_core_2023',
          },
          kernelStates: <ReplaySimulationKernelState>[
            ReplaySimulationKernelState(
              kernelId: 'forecast',
              status: 'active',
              reason: 'Scenario comparisons are present.',
            ),
          ],
        ),
        learningReadiness: ReplaySimulationLearningReadiness(
          trainingGrade: 'review',
          shareWithRealityModelAllowed: false,
          reasons: <String>['Truth receipts are still sparse.'],
          suggestedTrainingUse: 'evaluation_and_kernel_gap_review',
        ),
      );
      final replaySnapshotAtx = ReplaySimulationAdminSnapshot(
        generatedAt: DateTime.utc(2026, 3, 31, 12),
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        scenarios: <ReplayScenarioPacket>[
          ReplayScenarioPacket(
            scenarioId: 'heatwave-1',
            name: 'Heatwave corridor stress',
            description: 'Heat pressure against East Side and South Congress.',
            cityCode: 'atx',
            baseReplayYear: 2024,
            scenarioKind: ReplayScenarioKind.weather,
            scope: ReplayScopeKind.corridor,
            seedEntityRefs: const <String>['entity-atx-1'],
            seedLocalityCodes: const <String>['atx_east_side'],
            seedObservationRefs: const <String>['obs-atx-1'],
            interventions: const <ReplayScenarioIntervention>[],
            expectedQuestions: const <String>[
              'Which corridor destabilizes first?'
            ],
            createdAt: DateTime.utc(2026, 3, 31, 12),
            createdBy: 'test',
          ),
        ],
        comparisons: <ReplayScenarioComparison>[
          ReplayScenarioComparison(
            scenarioId: 'heatwave-1',
            baselineRunId: 'baseline-atx-1',
            branchRunIds: const <String>['branch-atx-1'],
            branchDiffs: const <ReplayScenarioBranchDiff>[
              ReplayScenarioBranchDiff(
                branchRunId: 'branch-atx-1',
                attendanceDelta: -0.15,
                movementDelta: -0.22,
                deliveryDelta: -0.18,
                safetyStressDelta: 0.35,
                localityPressureDeltas: <String, double>{'atx_east_side': 0.48},
                keyNarrativeLines: <String>[
                  'East Side takes the first heatwave contradiction.',
                ],
              ),
            ],
            summary: 'East Side carries the highest replay stress.',
            generatedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        receipts: const <SimulationTruthReceipt>[],
        contradictions: <ReplayContradictionSnapshot>[
          ReplayContradictionSnapshot(
            snapshotId: 'contr-atx-1',
            runId: 'branch-atx-1',
            entityRef: 'entity-atx-1',
            localityCode: 'atx_east_side',
            contradictionType: ReplayContradictionType.safetyStress,
            replayExpectation: 'moderate',
            liveObserved: 'high',
            severity: 0.79,
            status: ReplayContradictionStatus.open,
            capturedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        localityOverlays: <ReplayLocalityOverlaySnapshot>[
          ReplayLocalityOverlaySnapshot(
            localityCode: 'atx_east_side',
            displayName: 'East Side',
            pressureBand: 'high',
            attentionBand: 'urgent',
            primarySignals: <String>['weather_shift', 'branch_sensitive'],
            branchSensitivity: 0.88,
            contradictionCount: 1,
            updatedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
        foundation: const ReplaySimulationAdminFoundationSummary(
          simulationMode: 'generic_city_pack',
          intakeFlowRefs: <String>[
            'source_intake_orchestrator',
            'air_gap_normalizer',
            'entity_fit_router',
          ],
          sidecarRefs: <String>[
            'city_packs/atx/2024_manifest.json',
            'city_packs/atx/campaign_defaults.json',
          ],
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
              reason: 'Truth receipts are bounded and admin-visible.',
            ),
          ],
        ),
        learningReadiness: ReplaySimulationLearningReadiness(
          trainingGrade: 'strong',
          shareWithRealityModelAllowed: true,
          reasons: <String>[
            'Truth receipts carry forecast trace refs and bounded contradiction summaries.',
          ],
          suggestedTrainingUse: 'candidate_deeper_reality_model_training',
          requestPreviews: <ReplaySimulationRealityModelRequestPreview>[
            ReplaySimulationRealityModelRequestPreview(
              request: RealityModelEvaluationRequest(
                requestId: 'atx-share-1',
                subjectId: 'simulation:atx_east_side',
                domain: RealityModelDomain.locality,
                candidateRef: 'locality:atx_east_side',
                localityCode: 'atx_east_side',
                cityCode: 'atx',
                signalTags: <String>['simulation_bundle'],
                evidenceRefs: <String>[
                  'simulation_snapshot.json#overlay:atx_east_side',
                ],
                requestedAtUtc: DateTime.utc(2026, 3, 31, 12),
              ),
              rationale:
                  'Use the highest-attention locality as bounded review input.',
            ),
          ],
        ),
      );
      final signatureSnapshot = SignatureHealthSnapshot(
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
            environmentId: 'bham-replay-world-2023',
            displayName: 'Birmingham Simulation Environment 2023',
            cityCode: 'bham',
            replayYear: 2023,
            suggestedAction: 'watch_closely',
            suggestedReason:
                'The current rerun lane is stable enough for bounded review.',
            selectedAction: 'candidate_for_bounded_review',
            acceptedSuggestion: true,
            updatedAt: DateTime.utc(2026, 3, 31, 12, 5),
            cityPackStructuralRef: 'city_pack:bham_core_2023',
            latestOutcomeDisposition: 'accepted',
            latestRerunRequestStatus: 'completed',
            latestRerunJobStatus: 'completed',
          ),
        ],
        learningOutcomeItems: const <SignatureHealthLearningOutcomeItem>[
          SignatureHealthLearningOutcomeItem(
            sourceId: 'simulation_training_source_bham',
            environmentId: 'bham-replay-world-2023',
            cityCode: 'bham',
            learningPathway: 'deeper_reality_model_training',
            outcomeStatus: 'completed',
            summary: 'Reality-model learning completed locally.',
            adminEvidenceRefreshSnapshotJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/bham/admin_evidence_refresh_snapshot_admin_bham_replay_world_2023.json',
            supervisorLearningFeedbackStateJsonPath:
                '/tmp/AVRAI/simulation_learning_bundles/bham/supervisor_learning_feedback_state_supervisor_bham_replay_world_2023.json',
            adminEvidenceRefreshSummary:
                SignatureHealthAdminEvidenceRefreshSummary(
              status: 'executed_local_governed_refresh',
              environmentId: 'bham-replay-world-2023',
              cityCode: 'bham',
              summary:
                  'Admin evidence surfaces refreshed locally from the reality-model learning outcome.',
              requestCount: 1,
              recommendationCount: 1,
              averageConfidence: 0.79,
              jsonPath:
                  '/tmp/AVRAI/simulation_learning_bundles/bham/admin_evidence_refresh_snapshot_admin_bham_replay_world_2023.json',
            ),
            supervisorFeedbackSummary: SignatureHealthSupervisorFeedbackSummary(
              status: 'executed_local_governed_feedback',
              environmentId: 'bham-replay-world-2023',
              feedbackSummary:
                  'Supervisor learning has absorbed the local reality-model outcome and should use it as bounded evidence for later scheduling and recommendation posture.',
              boundedRecommendation:
                  'allow_bounded_retry_with_operator_visibility',
              requestCount: 1,
              recommendationCount: 1,
              averageConfidence: 0.79,
              jsonPath:
                  '/tmp/AVRAI/simulation_learning_bundles/bham/supervisor_learning_feedback_state_supervisor_bham_replay_world_2023.json',
            ),
            propagationTargets: <SignatureHealthPropagationTarget>[
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:locality',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham locality domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_locality.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'locality',
                  summary:
                      'Governed lower-tier `locality` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `locality` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_locality.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_locality.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:event',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham event domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_event.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'event',
                  summary:
                      'Governed lower-tier `event` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `event` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 2,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_event.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_event.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:place',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham place domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_place.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'place',
                  summary:
                      'Governed lower-tier `place` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `place` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_place.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_place.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:community',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham community domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_community.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'community',
                  summary:
                      'Governed lower-tier `community` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `community` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_community.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_community.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:business',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham business domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_business.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'business',
                  summary:
                      'Governed lower-tier `business` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `business` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_business.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_business.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'hierarchy:list',
                propagationKind: 'prior_and_explanation_delta',
                reason:
                    'Birmingham list domain is ready for governed propagation.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_list.json',
                hierarchyDomainDeltaSummary:
                    SignatureHealthHierarchyDomainDeltaSummary(
                  status: 'executed_local_governed_domain_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'list',
                  summary:
                      'Governed lower-tier `list` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
                  boundedUse:
                      'Apply this only as a domain-scoped delta for `list` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
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
                        '/tmp/AVRAI/simulation_learning_bundles/bham/domain_consumer_state_list.json',
                  ),
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/hierarchy_domain_delta_hierarchy_list.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:locality',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Birmingham personal-agent locality personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_locality.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'locality',
                  summary:
                      'The personal agent may now personalize the governed `locality` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `locality` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_locality.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:place',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Birmingham personal-agent place personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_place.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'place',
                  summary:
                      'The personal agent may now personalize the governed `place` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `place` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_place.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:business',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Birmingham personal-agent business personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_business.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'business',
                  summary:
                      'The personal agent may now personalize the governed `business` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `business` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_business.json',
                ),
              ),
              SignatureHealthPropagationTarget(
                targetId: 'personal_agent:list',
                propagationKind: 'personalized_guidance_delta',
                reason:
                    'Birmingham personal-agent list personalization is ready after hierarchy synthesis.',
                status: 'ready_for_governed_downstream_propagation_review',
                laneArtifactJsonPath:
                    '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_list.json',
                personalAgentPersonalizationSummary:
                    SignatureHealthPersonalAgentPersonalizationSummary(
                  status: 'executed_local_governed_personalization_delta',
                  environmentId: 'bham-replay-world-2023',
                  domainId: 'list',
                  summary:
                      'The personal agent may now personalize the governed `list` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
                  personalizationMode:
                      'final_contextualization_after_hierarchy_synthesis',
                  boundedUse:
                      'Use this only as the final personalized form of already-governed `list` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
                  requestCount: 1,
                  recommendationCount: 1,
                  averageConfidence: 0.79,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/bham/personal_agent_personalization_delta_personal_agent_list.json',
                ),
              ),
            ],
          ),
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
              requestCount: 2,
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
              requestCount: 2,
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
                  requestCount: 2,
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
                  requestCount: 3,
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
                  requestCount: 2,
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
            sourceId: 'upward_learning_source_bham_user_123_msg_1',
            sourceKind: 'personal_agent_human_intake',
            learningDirection: 'upward_personal_agent_to_reality_model',
            learningPathway: 'governed_upward_reality_model_learning',
            convictionTier: 'personal_agent_human_observation',
            status: 'integrated_as_bounded_local_reality_model_update',
            summary:
                'A bounded Birmingham upward conviction was validated and released back into governed lower-tier lanes.',
            environmentId: 'bham-replay-world-2023',
            cityCode: 'bham',
            hierarchyPath: <String>[
              'human',
              'personal_agent',
              'reality_model_agent'
            ],
            upwardDomainHints: <String>['locality', 'business'],
            upwardReferencedEntities: <String>[
              'downtown coffee shops',
              'recommendation:list_123',
            ],
            upwardQuestions: <String>[
              'Should this preference stay local or become a reusable business-layer conviction?',
            ],
            followUpPromptQuestion:
                'What felt off about "Quiet Roast" for you right then?',
            followUpResponseText:
                'It was busier than I wanted for a quiet work session.',
            followUpCompletionMode: 'assistant_follow_up_chat',
            upwardSignalTags: <String>[
              'source:human',
              'domain:business',
              'signal:preference',
            ],
            upwardPreferenceSignals: <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'business_preference',
                'value': 'quiet_coffee_shop',
                'weight': 0.82,
              },
            ],
            realityModelUpdateDownstreamRepropagationPlanJsonPath:
                '/tmp/AVRAI/upward_learning_bundles/bham/reality_model_update_downstream_repropagation_plan.json',
            realityModelUpdateDownstreamRepropagationOutcomeJsonPath:
                '/tmp/AVRAI/upward_learning_bundles/bham/reality_model_update_downstream_repropagation_outcome.json',
            downstreamRepropagationResolution: 'approve',
            downstreamRepropagationReleasedTargetIds: <String>[
              'admin:bham-replay-world-2023',
              'supervisor:bham-replay-world-2023',
              'hierarchy:locality',
              'hierarchy:business',
            ],
          ),
        ],
      );

      when(() => governanceService.watchCommunications()).thenAnswer(
        (_) => Stream<CommunicationsSnapshot>.value(communications),
      );
      when(() => governanceService.getDashboardData())
          .thenAnswer((_) async => dashboard);
      when(() => governanceService.getAllActiveAIAgents())
          .thenAnswer((_) async => activeAgents);
      when(() => governanceService.listRecentGovernanceInspections(limit: 4))
          .thenAnswer((_) async => <GovernanceInspectionResponse>[]);
      when(() => governanceService.listRecentBreakGlassReceipts(limit: 4))
          .thenAnswer((_) async => <BreakGlassGovernanceReceipt>[]);
      when(() => governanceService.getMeshTrustDiagnosticsSnapshot())
          .thenAnswer((_) async => meshSnapshot);
      when(() => governanceService.getAi2AiRendezvousDiagnosticsSnapshot())
          .thenAnswer((_) async => rendezvousSnapshot);
      when(() =>
              governanceService.getAmbientSocialLearningDiagnosticsSnapshot())
          .thenAnswer((_) async => ambientSnapshot);
      when(() => governanceService
              .runControlledPrivateMeshFieldAcceptanceValidation())
          .thenAnswer((_) async => const <DomainExecutionFieldScenarioProof>[]);
      when(() =>
          governanceService.exportRecentFieldValidationProofs(
              limit: any(named: 'limit'))).thenReturn(
          '{"exported_at_utc":"2026-03-31T12:00:00.000Z","proofs":[{},{}]}');
      when(() => opsService.getHealthSnapshot(
            platformHealth: any(named: 'platformHealth'),
          )).thenAnswer(
        (_) async => const AdminHealthSnapshot(
          adminAvailable: true,
          sessionValid: true,
          deviceApproved: true,
          internalUseAgreementVerified: true,
          openBreakGlassCount: 0,
          moderationQueueCount: 1,
          quarantinedCount: 0,
          failedDeliveryCount: 0,
          pendingFeedbackCount: 0,
          routeDeliveryHealth: 0.88,
          platformHealth: <String, int>{'ios': 7, 'android': 5},
          deviceStatusLabel: 'Approved desktop admin device',
        ),
      );
      when(() => opsService.getLaunchGateMetrics(
            platformHealth: any(named: 'platformHealth'),
          )).thenAnswer(
        (_) async => const LaunchGateAdminMetrics(
          availability: true,
          moderationQueueHealth: 1,
          quarantineCount: 0,
          falsityResetCount: 0,
          breakGlassCount: 0,
          routeDeliveryHealth: 0.88,
          platformHealth: <String, int>{'ios': 7, 'android': 5},
        ),
      );
      when(() => replayService.listEnvironments()).thenReturn(
        const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'bham-replay-world-2023',
            displayName: 'Birmingham Simulation Environment 2023',
            cityCode: 'bham',
            replayYear: 2023,
          ),
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'atx-replay-world-2024',
            displayName: 'Austin Simulation Environment 2024',
            cityCode: 'atx',
            replayYear: 2024,
          ),
        ],
      );
      when(
        () => replayService.getSnapshot(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer((invocation) async {
        final environmentId =
            invocation.namedArguments[#environmentId] as String?;
        if (environmentId == 'atx-replay-world-2024') {
          return replaySnapshotAtx;
        }
        return replaySnapshot;
      });
      when(() => signatureHealthService.getSnapshot())
          .thenAnswer((_) async => signatureSnapshot);
      when(
        () => replayService.exportLearningBundle(
          environmentId: any(named: 'environmentId'),
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationLearningBundleExport(
          environmentId: 'bham-replay-world-2023',
          bundleRoot: '/tmp/AVRAI/simulation_learning_bundles/bham',
          snapshotJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/bham/simulation_snapshot.json',
          learningBundleJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/bham/simulation_learning_bundle.json',
          realityModelRequestJsonPath:
              '/tmp/AVRAI/simulation_learning_bundles/bham/reality_model_request_previews.json',
          readmePath: '/tmp/AVRAI/simulation_learning_bundles/bham/README.md',
          exportedAt: DateTime.utc(2026, 3, 31, 12),
          shareWithRealityModelAllowed: false,
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
      when(() => headlessOsHost.start()).thenAnswer(
        (_) async => HeadlessAvraiOsHostState(
          started: true,
          startedAtUtc: DateTime.utc(2026, 3, 31, 12),
          localityContainedInWhere: true,
          summary: 'Headless AVRAI OS host started with locality inside where',
        ),
      );
      when(() => headlessOsHost.healthCheck()).thenAnswer(
        (_) async => const <KernelHealthReport>[
          KernelHealthReport(
            domain: KernelDomain.when,
            status: KernelHealthStatus.healthy,
            nativeBacked: true,
            headlessReady: true,
            authorityLevel: KernelAuthorityLevel.authoritative,
            summary: 'temporal authority ready',
          ),
          KernelHealthReport(
            domain: KernelDomain.where,
            status: KernelHealthStatus.healthy,
            nativeBacked: true,
            headlessReady: true,
            authorityLevel: KernelAuthorityLevel.authoritative,
            summary: 'locality authority ready',
          ),
        ],
      );
      when(() => researchSupervisor.listRuns()).thenAnswer(
        (_) async => <ResearchRunState>[
          ResearchRunState(
            id: 'run-1',
            title: 'Replay prior tuning',
            hypothesis:
                'Temporal route weighting lowers contradiction frequency.',
            layer: ResearchLayer.reality,
            ownerAgentAlias: 'admin-research',
            lifecycleState: ResearchRunLifecycleState.running,
            humanAccess: ResearchHumanAccess.adminOnly,
            visibilityScope: ResearchVisibilityScope.adminOnly,
            lane: ResearchRunLane.sandboxReplay,
            charter: ResearchCharter(
              id: 'charter-1',
              title: 'Replay prior tuning',
              objective: 'Improve sandbox replay ranking stability.',
              hypothesis: 'Temporal route weighting reduces contradictions.',
              allowedExperimentSurfaces: const <String>['sandbox_route_ranker'],
              successMetrics: const <String>['contradiction_rate_down'],
              stopConditions: const <String>['unstable_projection'],
              hardBans: const <String>['production_mutation'],
              createdAt: DateTime.utc(2026, 3, 31, 12),
              updatedAt: DateTime.utc(2026, 3, 31, 12),
            ),
            egressMode: ResearchEgressMode.internalOnly,
            requiresAdminApproval: true,
            sandboxOnly: true,
            modelVersion: 'g2a15',
            policyVersion: 'wave31',
            metrics: const <String, double>{'confidence': 0.82},
            tags: const <String>['reality', 'replay', 'sandbox'],
            controlActions: const <ResearchControlAction>[],
            checkpoints: const <ResearchCheckpoint>[],
            approvals: const <ResearchApproval>[],
            artifacts: const <ResearchArtifactRef>[],
            alerts: const <ResearchAlert>[],
            createdAt: DateTime.utc(2026, 3, 31, 12),
            updatedAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
      );
      when(() => researchSupervisor.listAlerts()).thenAnswer(
        (_) async => <ResearchAlert>[
          ResearchAlert(
            id: 'alert-1',
            runId: 'run-1',
            severity: ResearchAlertSeverity.warning,
            title: 'Checkpoint lag',
            message: 'Running sandbox has not checkpointed recently.',
            createdAt: DateTime.utc(2026, 3, 31, 12),
          ),
        ],
      );
    });

    tearDown(() async {
      await WidgetTestHelpers.cleanupWidgetTestEnvironment();
    });

    testWidgets('renders cockpit summaries for reality, mesh, and replay',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AdminCommandCenterPage(
          governanceService: governanceService,
          opsService: opsService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          realityModelStatusService: _FakeRealityModelStatusService(),
          researchSupervisor: researchSupervisor,
          headlessOsHost: headlessOsHost,
          showLiveAgentGlobe: false,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Admin Command Center'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Needs Attention'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Rejected mesh announces detected'), findsOneWidget);
      expect(
          find.text('Replay contradiction hotspot is active'), findsOneWidget);
      expect(
        find.text('Supervisor allows a bounded simulation retry'),
        findsOneWidget,
      );
      expect(
        find.text('Simulation target is ready for bounded review'),
        findsOneWidget,
      );
      expect(find.text('Open world simulation lab'), findsOneWidget);
      expect(find.text('Open bounded review'), findsOneWidget);
      expect(find.text('Open AI2AI lane'), findsOneWidget);
      expect(find.text('Open reality lane'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Oversight Cockpit'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Oversight Cockpit'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('AI2AI Mesh Health'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('AI2AI Mesh Health'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Simulation Snapshot'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Simulation Snapshot'), findsOneWidget);
      expect(find.textContaining('Storm corridor surge'), findsOneWidget);
      expect(find.textContaining('Downtown'), findsWidgets);
      expect(find.textContaining('Simulation basis: generic_city_pack'),
          findsOneWidget);
      expect(find.textContaining('source_intake_orchestrator'), findsOneWidget);
      expect(
        find.textContaining(
            'City-pack structural ref: city_pack:bham_core_2023'),
        findsOneWidget,
      );
      expect(find.text('Post-learning evidence'), findsOneWidget);
      expect(
        find.textContaining('Admin evidence surfaces refreshed locally'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bounded recommendation:'),
        findsOneWidget,
      );
      expect(
        find.text('Validated upward re-propagation release'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Re-propagation plan: /tmp/AVRAI/upward_learning_bundles/bham/reality_model_update_downstream_repropagation_plan.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Domain hints: locality, business'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Referenced entities: downtown coffee shops, recommendation:list_123',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Questions: Should this preference stay local or become a reusable business-layer conviction?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up prompt: What felt off about "Quiet Roast" for you right then?',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Follow-up answer: It was busier than I wanted for a quiet work session.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Follow-up completion: assistant_follow_up_chat'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Signal tags: source:human, domain:business, signal:preference',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Preference signals: business_preference:quiet_coffee_shop:w:0.82',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Released lanes: admin:bham-replay-world-2023, supervisor:bham-replay-world-2023, hierarchy:locality, hierarchy:business',
        ),
        findsOneWidget,
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
        find.text('Personal-agent personalization • business'),
        findsOneWidget,
      );
      expect(
        find.text('Personal-agent personalization • list'),
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
        find.textContaining('Lane artifact:'),
        findsWidgets,
      );
      expect(
        find.textContaining('Domain delta:'),
        findsWidgets,
      );
      expect(
        find.textContaining(
            'Personalization mode: final_contextualization_after_hierarchy_synthesis'),
        findsNWidgets(4),
      );
      expect(
        find.textContaining('Personalization delta:'),
        findsNWidgets(4),
      );
      expect(
        find.textContaining('hierarchy_domain_delta_hierarchy_locality.json'),
        findsWidgets,
      );
      expect(
        find.textContaining('hierarchy_domain_delta_hierarchy_event.json'),
        findsWidgets,
      );
      expect(
        find.textContaining(
            'personal_agent_personalization_delta_personal_agent_locality.json'),
        findsWidgets,
      );
      expect(find.text('Export local bundle'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.text('Kernel + Sandbox Research'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Kernel + Sandbox Research'), findsOneWidget);
      expect(find.textContaining('Replay prior tuning'), findsOneWidget);
      expect(find.textContaining('Checkpoint lag'), findsOneWidget);
      expect(find.text('Run controlled validation'), findsOneWidget);
      expect(find.text('Export field proofs'), findsOneWidget);
    });

    testWidgets(
        'runs bounded validation and export actions from command center',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AdminCommandCenterPage(
          governanceService: governanceService,
          opsService: opsService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          realityModelStatusService: _FakeRealityModelStatusService(),
          researchSupervisor: researchSupervisor,
          headlessOsHost: headlessOsHost,
          showLiveAgentGlobe: false,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
          find.text('Run controlled validation'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Run controlled validation'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.text('Controlled validation completed with 0 proofs.'),
        findsOneWidget,
      );
      verify(() => governanceService
          .runControlledPrivateMeshFieldAcceptanceValidation()).called(1);

      await tester.tap(find.text('Export field proofs'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(() =>
              governanceService.exportRecentFieldValidationProofs(limit: 8))
          .called(1);

      await tester.drag(find.byType(ListView).first, const Offset(0, 800));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Export local bundle'), findsOneWidget);
      await tester.tap(find.text('Export local bundle'));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      verify(
        () => replayService.exportLearningBundle(
          environmentId: any(named: 'environmentId'),
        ),
      ).called(1);
      expect(
        find.textContaining(
          'Local output: /tmp/AVRAI/simulation_learning_bundles/bham',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('replayEnvironmentSelector')),
        250,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('replayEnvironmentSelector')),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(
        find.text('Austin Simulation Environment 2024 (ATX 2024)').last,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Share to reality model'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Share to reality model'), 120);
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
    });

    testWidgets('surfaces research backend failures in the attention queue',
        (WidgetTester tester) async {
      when(() => researchSupervisor.listRuns())
          .thenThrow(StateError('research_unavailable'));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: AdminCommandCenterPage(
          governanceService: governanceService,
          opsService: opsService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          realityModelStatusService: _FakeRealityModelStatusService(),
          researchSupervisor: researchSupervisor,
          headlessOsHost: headlessOsHost,
          showLiveAgentGlobe: false,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(find.text('Needs Attention'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Research backend is unavailable'), findsOneWidget);
      expect(find.text('Open research center'), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text('Kernel + Sandbox Research'), 250);
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.textContaining(
          'Research backend unavailable: Bad state: research_unavailable',
        ),
        findsOneWidget,
      );
    });

    testWidgets('switches replay environments from the command center selector',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AdminCommandCenterPage(
          governanceService: governanceService,
          opsService: opsService,
          replaySimulationService: replayService,
          signatureHealthService: signatureHealthService,
          realityModelStatusService: _FakeRealityModelStatusService(),
          researchSupervisor: researchSupervisor,
          headlessOsHost: headlessOsHost,
          showLiveAgentGlobe: false,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('replayEnvironmentSelector')),
        250,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(
        find.textContaining('Birmingham Simulation Environment 2023'),
        findsWidgets,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('replayEnvironmentSelector')),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(
        find.text('Austin Simulation Environment 2024 (ATX 2024)').last,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining('Austin Simulation Environment 2024'),
        findsWidgets,
      );
      expect(find.textContaining('Heatwave corridor stress'), findsOneWidget);
      expect(find.textContaining('East Side'), findsWidgets);
      verify(
        () => replayService.getSnapshot(environmentId: 'atx-replay-world-2024'),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}

class _FakeRealityModelStatusService extends RealityModelStatusService {
  @override
  Future<RealityModelStatusSnapshot> loadStatus() async {
    return RealityModelStatusSnapshot(
      loadedAtUtc: DateTime.utc(2026, 3, 31, 12),
      available: true,
      mode: 'kernel_backed',
      boundary: 'reality_model_port',
      summary: 'Active contract boundary is healthy for command-center use.',
    );
  }
}
