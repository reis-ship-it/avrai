import 'package:avrai_admin_app/ui/pages/world_simulation_lab_page.dart';
import 'package:avrai_core/models/reality/reality_model_contracts.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';

class MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}

Future<void> _dragUntilTextVisible(
  WidgetTester tester,
  String text, {
  required Finder scrollable,
  int maxDrags = 12,
  double dragOffset = 240,
}) async {
  for (var index = 0;
      index < maxDrags && find.text(text).evaluate().isEmpty;
      index++) {
    await tester.drag(scrollable, Offset(0, -dragOffset));
    await WidgetTestHelpers.safePumpAndSettle(tester);
  }
}

void main() {
  group('WorldSimulationLabPage', () {
    tearDown(() async {
      await WidgetTestHelpers.cleanupWidgetTestEnvironment();
    });

    testWidgets('renders savannah simulation basis and history',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        initialHistory: <String, List<ReplaySimulationLabOutcomeRecord>>{
          'sav-replay-world-2024': <ReplaySimulationLabOutcomeRecord>[
            _buildOutcome(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              disposition: ReplaySimulationLabDisposition.denied,
              recordedAt: DateTime.utc(2026, 4, 1, 12, 30),
              operatorRationale:
                  'Storm corridor bundle still contradicts port-traffic behavior.',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
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
            learningOutcomeItems: <SignatureHealthLearningOutcomeItem>[
              SignatureHealthLearningOutcomeItem(
                sourceId: 'simulation_training_source_sav',
                environmentId: 'sav-replay-world-2024',
                cityCode: 'sav',
                learningPathway: 'deeper_reality_model_training',
                outcomeStatus: 'completed',
                summary:
                    'Reality-model learning completed locally from the accepted Savannah simulation.',
                updatedAt: DateTime.utc(2026, 4, 1, 14, 45),
                adminEvidenceRefreshSummary:
                    const SignatureHealthAdminEvidenceRefreshSummary(
                  status: 'executed_local_governed_evidence_refresh',
                  environmentId: 'sav-replay-world-2024',
                  cityCode: 'sav',
                  summary:
                      'Admin evidence refresh now reflects the Savannah learning outcome.',
                  requestCount: 3,
                  recommendationCount: 2,
                  averageConfidence: 0.75,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/sav/admin_evidence_refresh_snapshot_admin_sav_replay_world_2024.json',
                ),
                supervisorFeedbackSummary:
                    const SignatureHealthSupervisorFeedbackSummary(
                  status: 'executed_local_governed_feedback',
                  environmentId: 'sav-replay-world-2024',
                  feedbackSummary:
                      'Supervisor learning has absorbed the Savannah learning outcome as bounded evidence.',
                  boundedRecommendation:
                      'allow_bounded_retry_with_operator_visibility',
                  requestCount: 3,
                  recommendationCount: 2,
                  averageConfidence: 0.75,
                  jsonPath:
                      '/tmp/AVRAI/simulation_learning_bundles/sav/supervisor_learning_feedback_state_supervisor_sav_replay_world_2024.json',
                ),
                propagationTargets: const <SignatureHealthPropagationTarget>[
                  SignatureHealthPropagationTarget(
                    targetId: 'hierarchy:venue',
                    propagationKind: 'prior_and_explanation_delta',
                    reason:
                        'Savannah venue domain is ready for governed propagation.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    hierarchyDomainDeltaSummary:
                        SignatureHealthHierarchyDomainDeltaSummary(
                      status: 'executed_local_governed_domain_delta',
                      environmentId: 'sav-replay-world-2024',
                      domainId: 'venue',
                      summary:
                          'Venue hierarchy can now synthesize port and waterfront venue evidence.',
                      boundedUse:
                          'Apply this only as a venue-scoped delta after approval.',
                      requestCount: 2,
                      recommendationCount: 2,
                      averageConfidence: 0.75,
                      downstreamConsumerSummary:
                          SignatureHealthDomainConsumerSummary(
                        status:
                            'executed_local_governed_domain_consumer_refresh',
                        consumerId: 'venue_intelligence_lane',
                        domainId: 'venue',
                        summary:
                            'Venue hierarchy deltas should now refresh bounded venue intelligence consumers so governed reality-model learning can improve venue priors, availability reasoning, and venue-facing explanations.',
                        boundedUse:
                            'Use only for venue-scoped availability, occupancy, and explanation consumers; do not generalize this into broader place or business retraining.',
                        targetedSystems: <String>[
                          'venue_priors',
                          'venue_availability_reasoning',
                          'venue_explanation_surfaces',
                        ],
                        jsonPath:
                            '/tmp/AVRAI/simulation_learning_bundles/sav/domain_consumer_state_venue.json',
                      ),
                      jsonPath:
                          '/tmp/AVRAI/simulation_learning_bundles/sav/hierarchy_domain_delta_hierarchy_venue.json',
                    ),
                  ),
                  SignatureHealthPropagationTarget(
                    targetId: 'hierarchy:mobility',
                    propagationKind: 'prior_and_explanation_delta',
                    reason:
                        'Savannah mobility domain is ready for governed propagation.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    hierarchyDomainDeltaSummary:
                        SignatureHealthHierarchyDomainDeltaSummary(
                      status: 'executed_local_governed_domain_delta',
                      environmentId: 'sav-replay-world-2024',
                      domainId: 'mobility',
                      summary:
                          'Mobility hierarchy can now synthesize corridor evidence.',
                      boundedUse:
                          'Apply this only as a mobility-scoped delta after approval.',
                      requestCount: 1,
                      recommendationCount: 2,
                      averageConfidence: 0.71,
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
                            '/tmp/AVRAI/simulation_learning_bundles/sav/domain_consumer_state_mobility.json',
                      ),
                      jsonPath:
                          '/tmp/AVRAI/simulation_learning_bundles/sav/hierarchy_domain_delta_hierarchy_mobility.json',
                    ),
                  ),
                  SignatureHealthPropagationTarget(
                    targetId: 'personal_agent:mobility',
                    propagationKind: 'personalized_guidance_delta',
                    reason:
                        'Personal-agent mobility guidance may now be contextualized.',
                    status: 'ready_for_governed_downstream_propagation_review',
                    personalAgentPersonalizationSummary:
                        SignatureHealthPersonalAgentPersonalizationSummary(
                      status: 'executed_local_governed_personalization_delta',
                      environmentId: 'sav-replay-world-2024',
                      domainId: 'mobility',
                      summary:
                          'Personal agent may now contextualize governed mobility guidance for the person.',
                      personalizationMode:
                          'final_contextualization_after_hierarchy_synthesis',
                      boundedUse:
                          'Use this only as the final personalized mobility guidance delta.',
                      requestCount: 1,
                      recommendationCount: 2,
                      averageConfidence: 0.71,
                      jsonPath:
                          '/tmp/AVRAI/simulation_learning_bundles/sav/personal_agent_personalization_delta_personal_agent_mobility.json',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('World Simulation Lab'), findsOneWidget);
      expect(find.text('Pre-training simulation workbench'), findsOneWidget);
      expect(find.text('Register Simulation Environment'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Simulation Environment'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Simulation Environment'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('This run remains pre-training only'),
        120,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.textContaining('This run remains pre-training only'),
          findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Post-Learning Chain'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Post-Learning Chain'), findsOneWidget);
      expect(find.text('Domain propagation delta • venue'), findsOneWidget);
      expect(find.text('Domain propagation delta • mobility'), findsOneWidget);
      expect(find.text('Domain consumer • venue_intelligence_lane'),
          findsOneWidget);
      expect(find.text('Domain consumer • mobility_guidance_lane'),
          findsOneWidget);
      expect(find.textContaining('Targeted systems: venue_priors'),
          findsOneWidget);
      expect(find.textContaining('Targeted systems: mobility_route_priors'),
          findsOneWidget);
      expect(
        find.text('Personal-agent personalization • mobility'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Variant Scaffolding'),
        180,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Variant Scaffolding'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Daemon Feedback Timeline'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Daemon Feedback Timeline'), findsOneWidget);
      expect(
        find.text('Denied • Savannah Simulation Environment 2024'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Storm corridor bundle still contradicts'),
        findsWidgets,
      );
    });

    testWidgets('surfaces served-basis recovery handoff from shared review',
        (WidgetTester tester) async {
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          initialFocus: 'sav-replay-world-2024',
          initialAttention: 'served_basis_recovery:restore_review',
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.text('World Simulation Lab handoff'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('World Simulation Lab handoff'), findsOneWidget);
      expect(
        find.textContaining('Review restore-or-restage posture'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Restore/restage and family-intake follow-up decisions remain lab-only here',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'refreshes latest-state evidence from the simulation basis card',
        (WidgetTester tester) async {
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('worldSimulationLabRefreshLatestStateEvidenceButton'),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key('worldSimulationLabRefreshLatestStateEvidenceButton'),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Refresh receipt artifact: world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Evidence selection: app observations -> world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Evidence aging: app observations: within policy window at 0.0h of 12h and receipt-backed.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Evidence aging trend: app observations: recent cadence checks refreshed this family and it remains within policy window.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Evidence policy action: app observations: no policy action required because this family is stable with recent refresh and remains within policy window.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Evidence restage target:',
        ),
        findsNothing,
      );
    });

    testWidgets('renders explicit evidence restage targets in simulation basis',
        (WidgetTester tester) async {
      final baseSnapshot = _buildSnapshot(
        environmentId: 'sav-replay-world-2024',
        cityCode: 'sav',
        replayYear: 2024,
        shareWithRealityModelAllowed: false,
      );
      final snapshot = _replaceSnapshotFoundationMetadata(
        baseSnapshot,
        Map<String, dynamic>.from(baseSnapshot.foundation.metadata)
          ..['latestStateEvidencePolicyActionSummaries'] = <String>[
            'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
          ]
          ..['latestStateEvidenceRestageTargetSummaries'] = <String>[
            'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
          ],
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': snapshot,
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.textContaining('Evidence restage target:'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Evidence restage target: app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders family restage review lane items in simulation basis',
        (WidgetTester tester) async {
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'queued_for_family_restage_review',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.textContaining('Family restage review lane:'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.text('Family restage review lane: 1 queued item'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabRequestFamilyRestageIntakeButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.text('Restage review status: restage intake requested'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Queue decision artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_decision.restage_intake_requested.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Restage intake queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_review.current.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Restage intake review item: family_restage_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabDeferFamilyRestageReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.text('Restage review status: watch family before restage'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Queue decision artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_decision.watch_family_before_restage.json',
        ),
        findsOneWidget,
      );
    });

    testWidgets('resolves family restage intake review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageIntakeOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
          familyRestageIntakeOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_INTAKE_RESOLUTION_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_requested',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              queueDecisionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_decision.restage_intake_requested.json',
              restageIntakeQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_review.current.json',
              restageIntakeReadmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_INTAKE_REVIEW_README.md',
              restageIntakeSourceId:
                  'family_restage_source_sav-replay-world-2024_app_observations',
              restageIntakeJobId:
                  'family_restage_job_sav-replay-world-2024_app_observations',
              restageIntakeReviewItemId:
                  'family_restage_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 4, 12),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageIntakeReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageIntakeReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.text('Restage review status: restage intake review approved'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Restage intake resolution artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family follow-up queue: queued for family restage follow-up review',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family follow-up review item: family_restage_follow_up_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets('resolves family restage follow-up review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageFollowUpOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
          familyRestageFollowUpOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_FOLLOW_UP_RESOLUTION_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReadmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_FOLLOW_UP_REVIEW_README.md',
              followUpSourceId:
                  'family_restage_follow_up_source_sav-replay-world-2024_app_observations',
              followUpJobId:
                  'family_restage_follow_up_job_sav-replay-world-2024_app_observations',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 10),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageFollowUpReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageFollowUpReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining('Family follow-up resolution: approved'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family follow-up resolution artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family resolution queue: queued for family restage resolution review',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family resolution review item: family_restage_resolution_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets('resolves family restage resolution review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_resolution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_resolution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageResolutionOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
          familyRestageResolutionOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_RESOLUTION_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
              followUpResolutionStatus: 'approved',
              followUpResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
              restageResolutionQueueStatus:
                  'queued_for_family_restage_resolution_review',
              restageResolutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
              restageResolutionReviewItemId:
                  'family_restage_resolution_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 10),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageResolutionReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageResolutionReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Family resolution outcome: approved for bounded family restage execution',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family resolution outcome artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family execution review item: family_restage_execution_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family execution queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_resolution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets('resolves family restage execution review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_execution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_execution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageExecutionOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
          familyRestageExecutionOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_EXECUTION_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
              followUpResolutionStatus: 'approved',
              followUpResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
              restageResolutionQueueStatus:
                  'queued_for_family_restage_resolution_review',
              restageResolutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
              restageResolutionReviewItemId:
                  'family_restage_resolution_review_sav-replay-world-2024_app_observations',
              restageResolutionResolutionStatus:
                  'approved_for_bounded_family_restage_execution',
              restageResolutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
              restageExecutionQueueStatus:
                  'queued_for_family_restage_execution_review',
              restageExecutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
              restageExecutionReviewItemId:
                  'family_restage_execution_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 11),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageExecutionReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageExecutionReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Family execution outcome: approved for bounded family restage application',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family execution outcome artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family application review item: family_restage_application_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family application queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_execution_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets(
        'resolves family restage application review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_application_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_application_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageApplicationOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
          familyRestageApplicationOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_APPLICATION_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
              followUpResolutionStatus: 'approved',
              followUpResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
              restageResolutionQueueStatus:
                  'queued_for_family_restage_resolution_review',
              restageResolutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
              restageResolutionReviewItemId:
                  'family_restage_resolution_review_sav-replay-world-2024_app_observations',
              restageResolutionResolutionStatus:
                  'approved_for_bounded_family_restage_execution',
              restageResolutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
              restageExecutionQueueStatus:
                  'queued_for_family_restage_execution_review',
              restageExecutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
              restageExecutionReviewItemId:
                  'family_restage_execution_review_sav-replay-world-2024_app_observations',
              restageExecutionResolutionStatus:
                  'approved_for_bounded_family_restage_application',
              restageExecutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
              restageApplicationQueueStatus:
                  'queued_for_family_restage_application_review',
              restageApplicationQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
              restageApplicationReviewItemId:
                  'family_restage_application_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 12),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageApplicationReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageApplicationReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Family application outcome: approved for bounded family restage apply to served basis',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family application outcome artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family apply review item: family_restage_apply_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family apply queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_application_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets('resolves family restage apply review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_apply_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_apply_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageApplyOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
          familyRestageApplyOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_APPLY_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'app observations: route to restage input family `app observations` because this family must be restaged before the next served-basis review while it is past policy window, receipt-backed.',
              policyAction: 'force_restaged_family_inputs',
              policyActionSummary:
                  'app observations: force restaged inputs for this family before the next promotion review because it is past policy window, receipt-backed.',
              queuedAt: DateTime.utc(2026, 4, 4, 10),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
              followUpResolutionStatus: 'approved',
              followUpResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
              restageResolutionQueueStatus:
                  'queued_for_family_restage_resolution_review',
              restageResolutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
              restageResolutionReviewItemId:
                  'family_restage_resolution_review_sav-replay-world-2024_app_observations',
              restageResolutionResolutionStatus:
                  'approved_for_bounded_family_restage_execution',
              restageResolutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
              restageExecutionQueueStatus:
                  'queued_for_family_restage_execution_review',
              restageExecutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
              restageExecutionReviewItemId:
                  'family_restage_execution_review_sav-replay-world-2024_app_observations',
              restageExecutionResolutionStatus:
                  'approved_for_bounded_family_restage_application',
              restageExecutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
              restageApplicationQueueStatus:
                  'queued_for_family_restage_application_review',
              restageApplicationQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
              restageApplicationReviewItemId:
                  'family_restage_application_review_sav-replay-world-2024_app_observations',
              restageApplicationResolutionStatus:
                  'approved_for_bounded_family_restage_apply_to_served_basis',
              restageApplicationResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
              restageApplyQueueStatus: 'queued_for_family_restage_apply_review',
              restageApplyQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
              restageApplyReviewItemId:
                  'family_restage_apply_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 12),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageApplyReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageApplyReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Family apply outcome: approved for bounded family restage served basis update',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family apply outcome artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family served-basis update review item: family_restage_served_basis_update_review_sav-replay-world-2024_app_observations',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family served-basis update queue artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update_review.current.json',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_apply_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets(
        'resolves family restage served-basis update review from the basis lane',
        (WidgetTester tester) async {
      final signatureService = MockSignatureHealthAdminService();
      when(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_served_basis_update_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).thenAnswer(
        (_) async => const SignatureHealthReviewResolutionResult(
          reviewItemId:
              'family_restage_served_basis_update_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
          familyRestageServedBasisUpdateOutcomeJsonPath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update.approved.json',
          familyRestageServedBasisUpdateOutcomeReadmePath:
              '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_SERVED_BASIS_UPDATE_APPROVED_README.md',
        ),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
        familyRestageReviewItems: <String,
            List<ReplaySimulationLabFamilyRestageReviewItem>>{
          'sav-replay-world-2024': <ReplaySimulationLabFamilyRestageReviewItem>[
            ReplaySimulationLabFamilyRestageReviewItem(
              itemId: 'sav-replay-world-2024-family-restage-app-observations',
              environmentId: 'sav-replay-world-2024',
              supportedPlaceRef: 'place:sav',
              evidenceFamily: 'app_observations',
              restageTarget: 'restage_input_family:app_observations',
              restageTargetSummary:
                  'App observations should be restaged before latest-state promotion.',
              policyAction: 'force_restaged_inputs',
              policyActionSummary:
                  'App observations now needs bounded restage intake review.',
              queuedAt: DateTime.utc(2026, 4, 2, 10, 0),
              queueStatus: 'restage_intake_review_approved',
              itemRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations',
              itemJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
              servedBasisRef:
                  'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
              currentBasisStatus: 'expired_latest_state_served_basis',
              queueDecisionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_review_decision.restage_intake_requested.json',
              queueDecisionRationale:
                  'Requested bounded restage intake review for this evidence family from World Simulation Lab.',
              queueDecisionRecordedAt: DateTime.utc(2026, 4, 2, 10, 15),
              restageIntakeQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake_review.current.json',
              restageIntakeReviewItemId:
                  'family_restage_review_sav-replay-world-2024_app_observations',
              restageIntakeResolutionStatus: 'approved',
              restageIntakeResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_intake.approved.json',
              followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
              followUpQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
              followUpReviewItemId:
                  'family_restage_follow_up_review_sav-replay-world-2024_app_observations',
              followUpResolutionStatus: 'approved',
              followUpResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up.approved.json',
              restageResolutionQueueStatus:
                  'queued_for_family_restage_resolution_review',
              restageResolutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
              restageResolutionReviewItemId:
                  'family_restage_resolution_review_sav-replay-world-2024_app_observations',
              restageResolutionResolutionStatus:
                  'approved_for_bounded_family_restage_execution',
              restageResolutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_resolution.approved.json',
              restageExecutionQueueStatus:
                  'queued_for_family_restage_execution_review',
              restageExecutionQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
              restageExecutionReviewItemId:
                  'family_restage_execution_review_sav-replay-world-2024_app_observations',
              restageExecutionResolutionStatus:
                  'approved_for_bounded_family_restage_application',
              restageExecutionResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
              restageApplicationQueueStatus:
                  'queued_for_family_restage_application_review',
              restageApplicationQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
              restageApplicationReviewItemId:
                  'family_restage_application_review_sav-replay-world-2024_app_observations',
              restageApplicationResolutionStatus:
                  'approved_for_bounded_family_restage_apply_to_served_basis',
              restageApplicationResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
              restageApplyQueueStatus: 'queued_for_family_restage_apply_review',
              restageApplyQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
              restageApplyReviewItemId:
                  'family_restage_apply_review_sav-replay-world-2024_app_observations',
              restageApplyResolutionStatus:
                  'approved_for_bounded_family_restage_served_basis_update',
              restageApplyResolutionArtifactRef:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
              restageServedBasisUpdateQueueStatus:
                  'queued_for_family_restage_served_basis_update_review',
              restageServedBasisUpdateQueueJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update_review.current.json',
              restageServedBasisUpdateReviewItemId:
                  'family_restage_served_basis_update_review_sav-replay-world-2024_app_observations',
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(
          replaySimulationService: service,
          signatureHealthService: signatureService,
          signatureHealthSnapshot: SignatureHealthSnapshot(
            generatedAt: DateTime.utc(2026, 4, 5, 12),
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
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageServedBasisUpdateReviewButton_app_observations',
          ),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabApproveFamilyRestageServedBasisUpdateReviewButton_app_observations',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'Family served-basis update outcome: approved for bounded family restage served basis mutation',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Family served-basis update outcome artifact: /tmp/world_simulation_lab/sav-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update.approved.json',
        ),
        findsOneWidget,
      );
      verify(
        () => signatureService.resolveReviewItem(
          reviewItemId:
              'family_restage_served_basis_update_review_sav-replay-world-2024_app_observations',
          resolution: SignatureHealthReviewResolution.approved,
        ),
      ).called(1);
    });

    testWidgets('runs refresh cadence check from the simulation basis card',
        (WidgetTester tester) async {
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: false,
          ),
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('worldSimulationLabRunRefreshCadenceCheckButton'),
        ),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.tap(
        find.byKey(
          const Key('worldSimulationLabRunRefreshCadenceCheckButton'),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.text('Refresh execution: executed due refresh'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Refresh execution receipt artifact: world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh_cadence.current.json',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders operator introspection cards for simulation review',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final snapshot = _buildSnapshot(
        environmentId: 'sav-replay-world-2024',
        cityCode: 'sav',
        replayYear: 2024,
        shareWithRealityModelAllowed: false,
      );
      const deniedProvenance = ReplaySimulationRealismProvenanceSummary(
        simulationMode: 'generic_city_pack',
        cityPackStructuralRef: 'city_pack:sav_core_2024',
        populationModelKind: 'scenario_seeded_synthetic_city',
        modeledUserLayerKind: 'representative_synthetic_human_lanes',
        intakeFlowRefs: <String>[
          'source_intake_orchestrator',
          'air_gap_normalizer',
        ],
        sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
        trainingArtifactFamilies: <String>['simulation_snapshot'],
      );
      const rerunProvenance = ReplaySimulationRealismProvenanceSummary(
        simulationMode: 'generic_city_pack',
        cityPackStructuralRef: 'city_pack:sav_core_2024',
        populationModelKind: 'scenario_seeded_synthetic_city',
        modeledUserLayerKind: 'representative_synthetic_human_lanes',
        intakeFlowRefs: <String>[
          'source_intake_orchestrator',
          'air_gap_normalizer',
        ],
        sidecarRefs: <String>[
          'city_packs/sav/2024_manifest.json',
          'world_models/sav/jepa_geo_realism_v2.json',
        ],
        trainingArtifactFamilies: <String>[
          'simulation_snapshot',
          'learning_bundle',
          'replay_learning_bundle',
        ],
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
            sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': snapshot,
        },
        initialHistory: <String, List<ReplaySimulationLabOutcomeRecord>>{
          'sav-replay-world-2024': <ReplaySimulationLabOutcomeRecord>[
            _buildOutcome(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              disposition: ReplaySimulationLabDisposition.denied,
              recordedAt: DateTime.utc(2026, 4, 1, 11, 30),
              operatorRationale:
                  'Storm corridor bundle still contradicts the waterfront lane.',
              syntheticHumanKernelEntries:
                  snapshot.syntheticHumanKernelExplorer.entries,
              localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
              higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
              realismProvenance: deniedProvenance,
            ),
          ],
        },
        rerunJobs: <String, List<ReplaySimulationLabRerunJob>>{
          'sav-replay-world-2024': <ReplaySimulationLabRerunJob>[
            _buildCompletedRerunJob(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              startedAt: DateTime.utc(2026, 4, 1, 12, 0),
              completedAt: DateTime.utc(2026, 4, 1, 12, 10),
              syntheticHumanKernelEntries:
                  snapshot.syntheticHumanKernelExplorer.entries,
              localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
              higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
              realismProvenance: rerunProvenance,
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await _dragUntilTextVisible(
        tester,
        'Synthetic Human Kernel Explorer',
        scrollable: scrollable,
      );
      expect(find.text('Synthetic Human Kernel Explorer'), findsOneWidget);
      expect(
        find.text('Savannah Waterfront Representative Lane'),
        findsOneWidget,
      );
      expect(find.text('Bundle trace'), findsOneWidget);
      expect(
        find.textContaining(
            'Missing required kernels: kernel.mobility.routing'),
        findsOneWidget,
      );
      expect(find.text('Kernel activation history'), findsOneWidget);
      expect(find.text('Completed rerun • 2026-04-01'), findsOneWidget);
      expect(find.text('Denied outcome • 2026-04-01'), findsOneWidget);
      await _dragUntilTextVisible(
        tester,
        'Locality Hierarchy Health',
        scrollable: scrollable,
      );
      expect(find.text('Locality Hierarchy Health'), findsOneWidget);
      expect(find.text('Savannah Waterfront'), findsWidgets);
      expect(find.text('Hierarchy trace'), findsWidgets);
      expect(find.text('Hierarchy history'), findsWidgets);
      expect(find.text('Completed rerun • 2026-04-01'), findsWidgets);
      expect(find.text('Denied outcome • 2026-04-01'), findsWidgets);
      expect(find.textContaining('Branch sensitivity: 47%'), findsWidgets);
      await _dragUntilTextVisible(
        tester,
        'Higher-Agent Handoff View',
        scrollable: scrollable,
      );
      expect(find.text('Higher-Agent Handoff View'), findsOneWidget);
      expect(find.text('Trace context'), findsWidgets);
      expect(find.text('Handoff lineage'), findsWidgets);
      expect(find.text('Completed rerun • 2026-04-01'), findsWidgets);
      expect(find.text('Denied outcome • 2026-04-01'), findsWidgets);
      await _dragUntilTextVisible(
        tester,
        'Realism Provenance Panel',
        scrollable: scrollable,
      );
      expect(find.text('Realism Provenance Panel'), findsOneWidget);
      expect(find.textContaining('Population model'), findsWidgets);
      expect(find.text('Latest provenance delta'), findsOneWidget);
      expect(
        find.textContaining(
          'Added sidecars: world_models/sav/jepa_geo_realism_v2.json',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Added artifact families: learning_bundle • replay_learning_bundle',
        ),
        findsOneWidget,
      );
      expect(find.text('Provenance history'), findsOneWidget);
      expect(
        find.textContaining('Sidecars: city_packs/sav/2024_manifest.json'),
        findsWidgets,
      );
      expect(
          find.textContaining('Training artifact families:'), findsOneWidget);
      await _dragUntilTextVisible(
        tester,
        'Weak Spots Before Training Summary',
        scrollable: scrollable,
      );
      expect(find.text('Weak Spots Before Training Summary'), findsOneWidget);
      expect(find.text('Kernel gap: kernel.mobility.routing'), findsOneWidget);
      expect(find.textContaining('Trace anchor: kernelId='), findsOneWidget);
    });

    testWidgets('records accepted world-simulation lab outcomes',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: true,
          ),
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      final acceptedButton =
          find.byKey(const Key('worldSimulationLabAcceptedButton'));
      await tester.scrollUntilVisible(
        acceptedButton,
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.enterText(
        find.byKey(const Key('worldSimulationLabRationaleField')),
        'Savannah waterfront mix is stable enough for learning review.',
      );
      await tester.enterText(
        find.byKey(const Key('worldSimulationLabNotesField')),
        'Keep freight detour active.\nRetest pedestrian surge next.',
      );
      await tester.scrollUntilVisible(
        acceptedButton,
        100,
        scrollable: scrollable,
      );
      final button = tester.widget<ButtonStyleButton>(acceptedButton);
      button.onPressed!.call();
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.scrollUntilVisible(
        find.text('Daemon Feedback Timeline'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      expect(find.text('Daemon Feedback Timeline'), findsOneWidget);

      final history = await service.listLabOutcomes(
        environmentId: 'sav-replay-world-2024',
      );
      expect(history, hasLength(1));
      expect(
          history.single.disposition, ReplaySimulationLabDisposition.accepted);
      expect(
        history.single.operatorNotes,
        const <String>[
          'Keep freight detour active.',
          'Retest pedestrian surge next.',
        ],
      );
    });

    testWidgets('surfaces daemon learning snapshot and variant comparison',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final variant = ReplaySimulationLabVariantDraft(
        environmentId: 'sav-replay-world-2024',
        variantId: 'sav-waterfront-detour',
        label: 'Waterfront detour',
        hypothesis:
            'Shift corridor pressure away from the port bottleneck and compare pedestrian spillover.',
        localityCodes: const <String>['waterfront', 'historic_core'],
        operatorNotes: const <String>[
          'Hold port traffic lower during peak hours.',
          'Watch pedestrian spillover near River Street.',
        ],
        createdAt: DateTime.utc(2026, 4, 1, 10),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: true,
          ),
        },
        variants: <String, List<ReplaySimulationLabVariantDraft>>{
          'sav-replay-world-2024': <ReplaySimulationLabVariantDraft>[variant],
        },
        rerunJobs: <String, List<ReplaySimulationLabRerunJob>>{
          'sav-replay-world-2024': <ReplaySimulationLabRerunJob>[
            ReplaySimulationLabRerunJob(
              jobId: 'sav-base-run-job-1',
              requestId: 'rerun-sav-base-1',
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              replayYear: 2024,
              jobStatus: 'completed',
              jobRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1',
              jobJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1/world_simulation_lab_rerun_job.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1/WORLD_SIMULATION_LAB_RERUN_JOB.md',
              startedAt: DateTime.utc(2026, 4, 1, 12, 15),
              completedAt: DateTime.utc(2026, 4, 1, 12, 25),
              cityPackStructuralRef: 'city_pack:sav_core_2024',
              snapshotJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1/simulation_snapshot.json',
              learningBundleJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1/simulation_learning_bundle.json',
              realityModelRequestJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/base-job-1/reality_model_request_previews.json',
              scenarioCount: 1,
              comparisonCount: 1,
              receiptCount: 2,
              contradictionCount: 3,
              overlayCount: 1,
              requestPreviewCount: 1,
            ),
            ReplaySimulationLabRerunJob(
              jobId: 'sav-waterfront-detour-job-2',
              requestId: 'rerun-sav-2',
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              replayYear: 2024,
              jobStatus: 'completed',
              jobRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2',
              jobJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2/world_simulation_lab_rerun_job.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2/WORLD_SIMULATION_LAB_RERUN_JOB.md',
              startedAt: DateTime.utc(2026, 4, 1, 13, 15),
              completedAt: DateTime.utc(2026, 4, 1, 13, 25),
              variantId: variant.variantId,
              variantLabel: variant.label,
              cityPackStructuralRef: 'city_pack:sav_core_2024',
              snapshotJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2/simulation_snapshot.json',
              learningBundleJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2/simulation_learning_bundle.json',
              realityModelRequestJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-2/reality_model_request_previews.json',
              scenarioCount: 2,
              comparisonCount: 2,
              receiptCount: 4,
              contradictionCount: 2,
              overlayCount: 2,
              requestPreviewCount: 3,
            ),
            ReplaySimulationLabRerunJob(
              jobId: 'sav-waterfront-detour-job-1',
              requestId: 'rerun-sav-1',
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              replayYear: 2024,
              jobStatus: 'completed',
              jobRoot:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1',
              jobJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1/world_simulation_lab_rerun_job.json',
              readmePath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1/WORLD_SIMULATION_LAB_RERUN_JOB.md',
              startedAt: DateTime.utc(2026, 4, 1, 12, 45),
              completedAt: DateTime.utc(2026, 4, 1, 12, 55),
              variantId: variant.variantId,
              variantLabel: variant.label,
              cityPackStructuralRef: 'city_pack:sav_core_2024',
              snapshotJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1/simulation_snapshot.json',
              learningBundleJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1/simulation_learning_bundle.json',
              realityModelRequestJsonPath:
                  '/tmp/world_simulation_lab/sav-replay-world-2024/runtime_jobs/job-1/reality_model_request_previews.json',
              scenarioCount: 2,
              comparisonCount: 2,
              receiptCount: 3,
              contradictionCount: 4,
              overlayCount: 2,
              requestPreviewCount: 2,
            ),
          ],
        },
        initialHistory: <String, List<ReplaySimulationLabOutcomeRecord>>{
          'sav-replay-world-2024': <ReplaySimulationLabOutcomeRecord>[
            _buildOutcome(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              disposition: ReplaySimulationLabDisposition.denied,
              recordedAt: DateTime.utc(2026, 4, 1, 12, 30),
              operatorRationale:
                  'Port-side contradiction pressure is still too high.',
            ),
            _buildOutcome(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              disposition: ReplaySimulationLabDisposition.accepted,
              recordedAt: DateTime.utc(2026, 4, 1, 11, 45),
              operatorRationale:
                  'Waterfront detour variant is stable enough for bounded learning review.',
              variantId: variant.variantId,
              variantLabel: variant.label,
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('worldSimulationLabDaemonLearningCard')),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Daemon Learning Snapshot'), findsOneWidget);
      expect(find.text('Outcomes: 2'), findsOneWidget);
      expect(find.text('Accepted: 1'), findsOneWidget);
      expect(find.text('Denied: 1'), findsOneWidget);
      expect(find.text('Variants: 1'), findsOneWidget);
      expect(find.text('Latest denial memory'), findsOneWidget);
      expect(find.textContaining('Port-side contradiction pressure'),
          findsWidgets);
      expect(find.text('Latest accepted evidence'), findsOneWidget);
      expect(find.textContaining('bounded learning review'), findsWidgets);
      expect(find.textContaining('accepted evidence regressed into a denial'),
          findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Variant Comparison'),
        200,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Waterfront detour'), findsWidgets);
      expect(
        find.text(
          'Shift corridor pressure away from the port bottleneck and compare pedestrian spillover.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Focus localities: waterfront, historic_core'),
        findsWidgets,
      );
      expect(
        find.textContaining(
            'Latest outcome: Accepted For Learning on 2026-04-01'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Latest executed rerun: Completed on 2026-04-01 with 2 contradictions, 4 receipts, and 3 request previews.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Runtime delta vs prior executed rerun: contradictions down 2, receipts up 1, overlays stable, request previews up 1.',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('worldSimulationLabExecutedRerunsCard')),
        200,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Executed Rerun Timeline'), findsOneWidget);
      expect(find.text('Showing all targets.'), findsOneWidget);
      expect(find.text('Base run'), findsWidgets);
      expect(find.text('Completed reruns: 2'), findsOneWidget);
      expect(find.text('Completed • 2026-04-01'), findsWidgets);
      expect(
        find.text(
          'Contradictions 2 • Receipts 4 • Overlays 2 • Request previews 3',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Contradictions 4 • Receipts 3 • Overlays 2 • Request previews 2',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Contradictions 3 • Receipts 2 • Overlays 1 • Request previews 1',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Trend severity: Improving within bounded runtime drift.'),
        findsOneWidget,
      );
      expect(
        find.text('Suggested action: Candidate for bounded review.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Reason: runtime trend is bounded and the latest labeled outcome is no longer blocked by denial memory.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('worldSimulationLabExecutedRerunsFilter')),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Waterfront detour').last);
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Focused target: Waterfront detour'), findsOneWidget);
      expect(find.text('Base run'), findsNothing);
      expect(
        find.text(
          'Contradictions 3 • Receipts 2 • Overlays 1 • Request previews 1',
        ),
        findsNothing,
      );
      expect(find.text('Completed reruns: 2'), findsOneWidget);
      expect(
        find.text(
          'Contradictions 2 • Receipts 4 • Overlays 2 • Request previews 3',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Suggested action: Candidate for bounded review.'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabAcceptSuggestedActionButton_sav-waterfront-detour',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      var runtimeState = await service.getLabRuntimeState(
        environmentId: 'sav-replay-world-2024',
      );
      expect(runtimeState.targetActionDecisions, hasLength(1));
      expect(
        runtimeState.targetActionDecisions.single.selectedAction,
        'candidate_for_bounded_review',
      );
      expect(
          runtimeState.targetActionDecisions.single.acceptedSuggestion, true);
      expect(
        runtimeState.targetActionDecisions.single.suggestedReason,
        'runtime trend is bounded and the latest labeled outcome is no longer blocked by denial memory.',
      );
      expect(
        find.text('Suggested action: Candidate for bounded review.'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(
          const Key(
            'worldSimulationLabOverrideActionButton_watch_closely_sav-waterfront-detour',
          ),
        ),
        120,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(
        find.byKey(
          const Key(
            'worldSimulationLabOverrideActionButton_watch_closely_sav-waterfront-detour',
          ),
        ),
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      runtimeState = await service.getLabRuntimeState(
        environmentId: 'sav-replay-world-2024',
      );
      expect(runtimeState.targetActionDecisions, hasLength(1));
      expect(
        runtimeState.targetActionDecisions.single.selectedAction,
        'watch_closely',
      );
      expect(
          runtimeState.targetActionDecisions.single.acceptedSuggestion, false);
      expect(
        runtimeState.targetActionDecisions.single.suggestedAction,
        'candidate_for_bounded_review',
      );
      expect(
        find.text('Suggested action: Candidate for bounded review.'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Daemon Feedback Timeline'),
        200,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Daemon Feedback Timeline'), findsOneWidget);
      expect(
        find.textContaining('Retain this as rejection memory'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Retain this as positive local evidence only'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Variant hypothesis: Shift corridor pressure'),
        findsOneWidget,
      );
    });

    testWidgets('persists next run target and applies it to recorded outcomes',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final variant = ReplaySimulationLabVariantDraft(
        environmentId: 'sav-replay-world-2024',
        variantId: 'sav-waterfront-detour',
        label: 'Waterfront detour',
        hypothesis: 'Reduce corridor pressure near the port.',
        localityCodes: const <String>['waterfront'],
        operatorNotes: const <String>['Keep freight detour active.'],
        createdAt: DateTime.utc(2026, 4, 1, 10),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: true,
          ),
        },
        variants: <String, List<ReplaySimulationLabVariantDraft>>{
          'sav-replay-world-2024': <ReplaySimulationLabVariantDraft>[variant],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('worldSimulationLabVariantSelector')),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester
          .tap(find.byKey(const Key('worldSimulationLabVariantSelector')));
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Waterfront detour').last);
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(
        find.textContaining(
          'The selected variant persists as the next run target',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('worldSimulationLabAcceptedButton')),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      await tester.enterText(
        find.byKey(const Key('worldSimulationLabRationaleField')),
        'Waterfront detour is now ready for bounded learning review.',
      );
      await tester
          .tap(find.byKey(const Key('worldSimulationLabAcceptedButton')));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      final history = await service.listLabOutcomes(
        environmentId: 'sav-replay-world-2024',
      );
      expect(history, hasLength(1));
      expect(history.single.variantId, variant.variantId);
      expect(history.single.variantLabel, variant.label);

      final runtimeState = await service.getLabRuntimeState(
        environmentId: 'sav-replay-world-2024',
      );
      expect(runtimeState.activeVariantId, variant.variantId);
      expect(runtimeState.activeVariantLabel, variant.label);
    });

    testWidgets('queues rerun requests with target lineage',
        (WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final variant = ReplaySimulationLabVariantDraft(
        environmentId: 'sav-replay-world-2024',
        variantId: 'sav-waterfront-detour',
        label: 'Waterfront detour',
        hypothesis: 'Reduce corridor pressure near the port.',
        localityCodes: const <String>['waterfront'],
        operatorNotes: const <String>['Keep freight detour active.'],
        createdAt: DateTime.utc(2026, 4, 1, 10),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
      );
      final service = _FakeReplaySimulationAdminService(
        environments: const <ReplaySimulationAdminEnvironmentDescriptor>[
          ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
        ],
        snapshots: <String, ReplaySimulationAdminSnapshot>{
          'sav-replay-world-2024': _buildSnapshot(
            environmentId: 'sav-replay-world-2024',
            cityCode: 'sav',
            replayYear: 2024,
            shareWithRealityModelAllowed: true,
          ),
        },
        variants: <String, List<ReplaySimulationLabVariantDraft>>{
          'sav-replay-world-2024': <ReplaySimulationLabVariantDraft>[variant],
        },
        runtimeStates: <String, ReplaySimulationLabRuntimeState>{
          'sav-replay-world-2024': ReplaySimulationLabRuntimeState(
            environmentId: 'sav-replay-world-2024',
            updatedAt: DateTime.utc(2026, 4, 1, 13, 0),
            activeVariantId: variant.variantId,
            activeVariantLabel: variant.label,
            targetActionDecisions: <ReplaySimulationLabTargetActionDecision>[
              ReplaySimulationLabTargetActionDecision(
                environmentId: 'sav-replay-world-2024',
                updatedAt: DateTime.utc(2026, 4, 1, 13, 15),
                suggestedAction: 'candidate_for_bounded_review',
                suggestedReason:
                    'Runtime drift is bounded and the latest labeled outcome is no longer blocked by denial memory.',
                selectedAction: 'candidate_for_bounded_review',
                acceptedSuggestion: true,
                variantId: variant.variantId,
                variantLabel: variant.label,
              ),
            ],
          ),
        },
        initialHistory: <String, List<ReplaySimulationLabOutcomeRecord>>{
          'sav-replay-world-2024': <ReplaySimulationLabOutcomeRecord>[
            _buildOutcome(
              environmentId: 'sav-replay-world-2024',
              cityCode: 'sav',
              disposition: ReplaySimulationLabDisposition.denied,
              recordedAt: DateTime.utc(2026, 4, 1, 12, 30),
              operatorRationale:
                  'Port-side contradiction pressure is still too high.',
              variantId: variant.variantId,
              variantLabel: variant.label,
            ),
          ],
        },
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: WorldSimulationLabPage(replaySimulationService: service),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.scrollUntilVisible(
        find.text('Queue Next Rerun'),
        250,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);

      expect(find.text('Current target: Waterfront detour'), findsOneWidget);
      expect(find.textContaining('Lineage basis: Denied on 2026-04-01'),
          findsOneWidget);
      expect(
        find.text(
          'Default next action: Candidate for bounded review. • accepted suggestion on 2026-04-01',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Routing: this target is ready for bounded review'),
        findsOneWidget,
      );
      expect(find.text('Open bounded review'), findsOneWidget);
      expect(find.text('Queue review-check rerun'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('worldSimulationLabRerunNotesField')),
        'Retest with lower freight pressure.\nCompare pedestrian spillover.',
      );
      await tester
          .tap(find.byKey(const Key('worldSimulationLabQueueRerunButton')));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      final requests = await service.listLabRerunRequests(
        environmentId: 'sav-replay-world-2024',
      );
      expect(requests, hasLength(1));
      expect(requests.single.variantId, variant.variantId);
      expect(requests.single.variantLabel, variant.label);
      expect(requests.single.lineageDisposition, 'denied');
      expect(
        requests.single.targetActionSelected,
        'candidate_for_bounded_review',
      );
      expect(
        requests.single.targetActionSuggested,
        'candidate_for_bounded_review',
      );
      expect(requests.single.targetActionAcceptedSuggestion, true);
      expect(requests.single.requestNotes, const <String>[
        'Retest with lower freight pressure.',
        'Compare pedestrian spillover.',
      ]);

      expect(find.text('Recent rerun requests'), findsOneWidget);
      expect(find.text('Waterfront detour'), findsWidgets);
      expect(
          find.textContaining('Lineage: denied on 2026-04-01'), findsOneWidget);
      expect(
        find.text(
          'Default next action: Candidate for bounded review. • accepted suggestion on 2026-04-01',
        ),
        findsWidgets,
      );
      expect(find.text('Execute rerun'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Execute rerun'),
        200,
        scrollable: scrollable,
      );
      await WidgetTestHelpers.safePumpAndSettle(tester);
      await tester.tap(find.text('Execute rerun'));
      await WidgetTestHelpers.safePumpAndSettle(tester);

      final completedRequests = await service.listLabRerunRequests(
        environmentId: 'sav-replay-world-2024',
      );
      expect(completedRequests.single.requestStatus, 'completed');
      expect(completedRequests.single.latestJobStatus, 'completed');
      expect(completedRequests.single.latestJobSnapshotJsonPath, isNotNull);
      final jobs = await service.listLabRerunJobs(
        environmentId: 'sav-replay-world-2024',
        requestId: completedRequests.single.requestId,
      );
      expect(jobs, hasLength(1));
      expect(jobs.single.jobStatus, 'completed');
      expect(find.textContaining('Completed • requested'), findsOneWidget);
      expect(
          find.textContaining('Latest runtime job: Completed'), findsOneWidget);
    });
  });
}

class _FakeReplaySimulationAdminService extends ReplaySimulationAdminService {
  _FakeReplaySimulationAdminService({
    required List<ReplaySimulationAdminEnvironmentDescriptor> environments,
    required Map<String, ReplaySimulationAdminSnapshot> snapshots,
    Map<String, List<ReplaySimulationLabVariantDraft>> variants =
        const <String, List<ReplaySimulationLabVariantDraft>>{},
    Map<String, ReplaySimulationLabRuntimeState> runtimeStates =
        const <String, ReplaySimulationLabRuntimeState>{},
    Map<String, List<ReplaySimulationLabRerunRequest>> rerunRequests =
        const <String, List<ReplaySimulationLabRerunRequest>>{},
    Map<String, List<ReplaySimulationLabRerunJob>> rerunJobs =
        const <String, List<ReplaySimulationLabRerunJob>>{},
    Map<String, List<ReplaySimulationLabFamilyRestageReviewItem>> familyRestageReviewItems =
        const <String, List<ReplaySimulationLabFamilyRestageReviewItem>>{},
    Map<String, List<ReplaySimulationLabOutcomeRecord>> initialHistory =
        const <String, List<ReplaySimulationLabOutcomeRecord>>{},
  })  : _environments = environments,
        _snapshots = snapshots,
        _variants = variants.map(
          (key, value) => MapEntry(
            key,
            List<ReplaySimulationLabVariantDraft>.from(value),
          ),
        ),
        _history = initialHistory.map(
          (key, value) => MapEntry(
            key,
            List<ReplaySimulationLabOutcomeRecord>.from(value),
          ),
        ),
        _runtimeStates = Map<String, ReplaySimulationLabRuntimeState>.from(
          runtimeStates,
        ),
        _rerunRequests = rerunRequests.map(
          (key, value) => MapEntry(
            key,
            List<ReplaySimulationLabRerunRequest>.from(value),
          ),
        ),
        _rerunJobs = rerunJobs.map(
          (key, value) => MapEntry(
            key,
            List<ReplaySimulationLabRerunJob>.from(value),
          ),
        ),
        _familyRestageReviewItems = familyRestageReviewItems.map(
          (key, value) => MapEntry(
            key,
            List<ReplaySimulationLabFamilyRestageReviewItem>.from(value),
          ),
        ),
        super(
            environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[]);

  final List<ReplaySimulationAdminEnvironmentDescriptor> _environments;
  final Map<String, ReplaySimulationAdminSnapshot> _snapshots;
  final Map<String, List<ReplaySimulationLabVariantDraft>> _variants;
  final Map<String, List<ReplaySimulationLabOutcomeRecord>> _history;
  final Map<String, ReplaySimulationLabRuntimeState> _runtimeStates;
  final Map<String, List<ReplaySimulationLabRerunRequest>> _rerunRequests;
  final Map<String, List<ReplaySimulationLabRerunJob>> _rerunJobs;
  final Map<String, List<ReplaySimulationLabFamilyRestageReviewItem>>
      _familyRestageReviewItems;
  int _recordCount = 0;

  @override
  List<ReplaySimulationAdminEnvironmentDescriptor> listEnvironments() =>
      List<ReplaySimulationAdminEnvironmentDescriptor>.from(_environments);

  @override
  Future<List<ReplaySimulationAdminEnvironmentDescriptor>>
      listAvailableEnvironments() async {
    return List<ReplaySimulationAdminEnvironmentDescriptor>.from(
      _environments,
    );
  }

  @override
  Future<ReplaySimulationAdminSnapshot> getSnapshot({
    String? environmentId,
  }) async {
    final resolvedEnvironmentId =
        environmentId ?? _environments.first.environmentId;
    return _snapshots[resolvedEnvironmentId]!;
  }

  @override
  Future<ReplaySimulationLabOutcomeRecord> recordLabOutcome({
    String? environmentId,
    required ReplaySimulationLabDisposition disposition,
    String operatorRationale = '',
    List<String> operatorNotes = const <String>[],
    String? variantId,
    String? variantLabel,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final runtimeState = await getLabRuntimeState(
      environmentId: snapshot.environmentId,
    );
    _recordCount++;
    final recordedAt = DateTime.utc(2026, 4, 1, 13, _recordCount);
    final record = ReplaySimulationLabOutcomeRecord(
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      replayYear: snapshot.replayYear,
      labRoot:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/$_recordCount',
      snapshotJsonPath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/simulation_snapshot.json',
      learningBundleJsonPath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/simulation_learning_bundle.json',
      realityModelRequestJsonPath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/reality_model_request_previews.json',
      outcomeJsonPath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/world_simulation_lab_outcome.json',
      readmePath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/WORLD_SIMULATION_LAB_README.md',
      recordedAt: recordedAt,
      disposition: disposition,
      operatorRationale: operatorRationale,
      operatorNotes: operatorNotes,
      trainingGrade: snapshot.learningReadiness.trainingGrade,
      suggestedTrainingUse: snapshot.learningReadiness.suggestedTrainingUse,
      shareWithRealityModelAllowed:
          snapshot.learningReadiness.shareWithRealityModelAllowed,
      scenarioCount: snapshot.scenarios.length,
      comparisonCount: snapshot.comparisons.length,
      receiptCount: snapshot.receipts.length,
      contradictionCount: snapshot.contradictions.length,
      overlayCount: snapshot.localityOverlays.length,
      requestPreviewCount: snapshot.learningReadiness.requestPreviews.length,
      simulationMode: snapshot.foundation.simulationMode,
      syntheticHumanKernelEntries:
          snapshot.syntheticHumanKernelExplorer.entries,
      localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
      higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
      realismProvenance: snapshot.realismProvenance,
      intakeFlowRefs: snapshot.foundation.intakeFlowRefs,
      sidecarRefs: snapshot.foundation.sidecarRefs,
      trainingArtifactFamilies: snapshot.foundation.trainingArtifactFamilies,
      variantId: variantId ?? runtimeState.activeVariantId,
      variantLabel: variantLabel ?? runtimeState.activeVariantLabel,
    );
    _history
        .putIfAbsent(
          snapshot.environmentId,
          () => <ReplaySimulationLabOutcomeRecord>[],
        )
        .insert(0, record);
    return record;
  }

  @override
  Future<List<ReplaySimulationLabVariantDraft>> listLabVariants({
    String? environmentId,
  }) async {
    final resolvedEnvironmentId =
        environmentId ?? _environments.first.environmentId;
    return List<ReplaySimulationLabVariantDraft>.from(
      _variants[resolvedEnvironmentId] ??
          const <ReplaySimulationLabVariantDraft>[],
    );
  }

  @override
  Future<ReplaySimulationLabRuntimeState> getLabRuntimeState({
    required String environmentId,
  }) async {
    return _runtimeStates[environmentId] ??
        ReplaySimulationLabRuntimeState(
          environmentId: environmentId,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
  }

  @override
  Future<ReplaySimulationLabRuntimeState> setActiveLabVariantTarget({
    required String environmentId,
    String? variantId,
  }) async {
    final existing = await getLabRuntimeState(environmentId: environmentId);
    String? resolvedVariantLabel;
    if (variantId != null && variantId.isNotEmpty) {
      final variant = (_variants[environmentId] ?? const [])
          .singleWhere((entry) => entry.variantId == variantId);
      resolvedVariantLabel = variant.label;
    }
    final state = ReplaySimulationLabRuntimeState(
      environmentId: environmentId,
      updatedAt: DateTime.utc(2026, 4, 1, 13, 0),
      activeVariantId:
          variantId == null || variantId.isEmpty ? null : variantId,
      activeVariantLabel: resolvedVariantLabel,
      targetActionDecisions: existing.targetActionDecisions,
    );
    _runtimeStates[environmentId] = state;
    return state;
  }

  @override
  Future<ReplaySimulationLabRuntimeState> recordLabTargetActionDecision({
    required String environmentId,
    String? variantId,
    required String suggestedAction,
    required String suggestedReason,
    required String selectedAction,
  }) async {
    final existing = await getLabRuntimeState(environmentId: environmentId);
    String? resolvedVariantLabel;
    final normalizedVariantId = variantId?.trim();
    if (normalizedVariantId != null && normalizedVariantId.isNotEmpty) {
      resolvedVariantLabel = (_variants[environmentId] ?? const [])
          .singleWhere((entry) => entry.variantId == normalizedVariantId)
          .label;
    }
    final decision = ReplaySimulationLabTargetActionDecision(
      environmentId: environmentId,
      updatedAt: DateTime.utc(2026, 4, 1, 14, 30),
      suggestedAction: suggestedAction,
      suggestedReason: suggestedReason,
      selectedAction: selectedAction,
      acceptedSuggestion: suggestedAction == selectedAction,
      variantId: normalizedVariantId,
      variantLabel: resolvedVariantLabel,
    );
    final updatedDecisions = existing.targetActionDecisions
        .where(
          (entry) => (entry.variantId?.trim().isEmpty ?? true)
              ? !(normalizedVariantId == null || normalizedVariantId.isEmpty)
              : entry.variantId != normalizedVariantId,
        )
        .toList(growable: true)
      ..insert(0, decision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: environmentId,
      updatedAt: decision.updatedAt,
      activeVariantId: existing.activeVariantId,
      activeVariantLabel: existing.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    _runtimeStates[environmentId] = state;
    return state;
  }

  @override
  Future<ReplaySimulationLabRerunRequest> createLabRerunRequest({
    required String environmentId,
    String? variantId,
    List<String> requestNotes = const <String>[],
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final runtimeState = await getLabRuntimeState(
      environmentId: snapshot.environmentId,
    );
    final effectiveVariantId = variantId ?? runtimeState.activeVariantId;
    final effectiveVariantLabel = effectiveVariantId == null
        ? null
        : (_variants[snapshot.environmentId] ?? const [])
            .singleWhere((entry) => entry.variantId == effectiveVariantId)
            .label;
    ReplaySimulationLabTargetActionDecision? targetActionDecision;
    for (final entry in runtimeState.targetActionDecisions) {
      final entryVariantId = entry.variantId?.trim();
      final effectiveTargetId = effectiveVariantId?.trim();
      final targetsBaseRun =
          (entryVariantId == null || entryVariantId.isEmpty) &&
              (effectiveTargetId == null || effectiveTargetId.isEmpty);
      if (targetsBaseRun || entryVariantId == effectiveTargetId) {
        targetActionDecision = entry;
        break;
      }
    }
    final lineage = (_history[snapshot.environmentId] ?? const []).firstWhere(
      (entry) => (effectiveVariantId == null || effectiveVariantId.isEmpty)
          ? (entry.variantId == null || entry.variantId!.isEmpty)
          : entry.variantId == effectiveVariantId,
      orElse: () => ReplaySimulationLabOutcomeRecord(
        environmentId: '',
        cityCode: '',
        replayYear: 0,
        labRoot: '',
        snapshotJsonPath: '',
        learningBundleJsonPath: '',
        realityModelRequestJsonPath: '',
        outcomeJsonPath: '',
        readmePath: '',
        recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        disposition: ReplaySimulationLabDisposition.draft,
        operatorRationale: '',
        operatorNotes: const <String>[],
        trainingGrade: '',
        suggestedTrainingUse: '',
        shareWithRealityModelAllowed: false,
        scenarioCount: 0,
        comparisonCount: 0,
        receiptCount: 0,
        contradictionCount: 0,
        overlayCount: 0,
        requestPreviewCount: 0,
        simulationMode: '',
        intakeFlowRefs: const <String>[],
        sidecarRefs: const <String>[],
        trainingArtifactFamilies: const <String>[],
      ),
    );
    final request = ReplaySimulationLabRerunRequest(
      requestId: 'rerun-${snapshot.environmentId}-${_rerunRequests.length + 1}',
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      replayYear: snapshot.replayYear,
      requestedAt: DateTime.utc(2026, 4, 1, 14, 0),
      requestStatus: 'queued',
      requestRoot: '/tmp/world_simulation_lab/${snapshot.environmentId}/reruns',
      requestJsonPath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/rerun_request.json',
      readmePath:
          '/tmp/world_simulation_lab/${snapshot.environmentId}/WORLD_SIMULATION_LAB_RERUN.md',
      requestNotes: requestNotes,
      sidecarRefs: snapshot.foundation.sidecarRefs,
      cityPackStructuralRef:
          snapshot.foundation.metadata['cityPackStructuralRef']?.toString(),
      variantId: effectiveVariantId,
      variantLabel: effectiveVariantLabel,
      lineageOutcomeJsonPath:
          lineage.outcomeJsonPath.isEmpty ? null : lineage.outcomeJsonPath,
      lineageDisposition: lineage.environmentId.isEmpty
          ? null
          : lineage.disposition.toWireValue(),
      lineageRecordedAt:
          lineage.environmentId.isEmpty ? null : lineage.recordedAt,
      targetActionSuggested: targetActionDecision?.suggestedAction,
      targetActionSuggestedReason: targetActionDecision?.suggestedReason,
      targetActionSelected: targetActionDecision?.selectedAction,
      targetActionAcceptedSuggestion: targetActionDecision?.acceptedSuggestion,
      targetActionUpdatedAt: targetActionDecision?.updatedAt,
    );
    _rerunRequests
        .putIfAbsent(
          snapshot.environmentId,
          () => <ReplaySimulationLabRerunRequest>[],
        )
        .insert(0, request);
    return request;
  }

  @override
  Future<ReplaySimulationLabRerunRequest> startLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) async {
    return _updateRerunRequestStatus(
      environmentId: environmentId,
      requestId: requestId,
      nextStatus: 'running',
    );
  }

  @override
  Future<ReplaySimulationLabRerunRequest> completeLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) async {
    return _updateRerunRequestStatus(
      environmentId: environmentId,
      requestId: requestId,
      nextStatus: 'completed',
    );
  }

  @override
  Future<ReplaySimulationLabRerunJob> executeLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final requests =
        _rerunRequests[environmentId] ?? <ReplaySimulationLabRerunRequest>[];
    final index = requests.indexWhere((entry) => entry.requestId == requestId);
    if (index == -1) {
      throw StateError('Unknown rerun request `$requestId`.');
    }
    final existing = requests[index];
    final startedAt = DateTime.utc(2026, 4, 1, 14, 5);
    final completedAt = DateTime.utc(2026, 4, 1, 14, 15);
    final job = ReplaySimulationLabRerunJob(
      jobId: '${existing.requestId}-job-1',
      requestId: existing.requestId,
      environmentId: existing.environmentId,
      cityCode: existing.cityCode,
      replayYear: existing.replayYear,
      jobStatus: 'completed',
      jobRoot:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs',
      jobJsonPath:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs/world_simulation_lab_rerun_job.json',
      readmePath:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs/WORLD_SIMULATION_LAB_RERUN_JOB.md',
      startedAt: startedAt,
      completedAt: completedAt,
      variantId: existing.variantId,
      variantLabel: existing.variantLabel,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      snapshotJsonPath:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs/simulation_snapshot.json',
      learningBundleJsonPath:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs/simulation_learning_bundle.json',
      realityModelRequestJsonPath:
          '/tmp/world_simulation_lab/${existing.environmentId}/runtime_jobs/reality_model_request_previews.json',
      scenarioCount: 1,
      comparisonCount: 1,
      receiptCount: 1,
      contradictionCount: 1,
      overlayCount: 1,
      requestPreviewCount: 1,
      syntheticHumanKernelEntries:
          snapshot.syntheticHumanKernelExplorer.entries,
      localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
      higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
      realismProvenance: snapshot.realismProvenance,
    );
    _rerunJobs
        .putIfAbsent(environmentId, () => <ReplaySimulationLabRerunJob>[])
        .insert(0, job);
    requests[index] = existing.copyWith(
      requestStatus: 'completed',
      startedAt: startedAt,
      completedAt: completedAt,
      latestJobId: job.jobId,
      latestJobJsonPath: job.jobJsonPath,
      latestJobStatus: job.jobStatus,
      latestJobStartedAt: job.startedAt,
      latestJobCompletedAt: job.completedAt,
      latestJobSnapshotJsonPath: job.snapshotJsonPath,
    );
    return job;
  }

  @override
  Future<List<ReplaySimulationLabRerunRequest>> listLabRerunRequests({
    String? environmentId,
    int limit = 12,
  }) async {
    final resolvedEnvironmentId =
        environmentId ?? _environments.first.environmentId;
    final requests = List<ReplaySimulationLabRerunRequest>.from(
      _rerunRequests[resolvedEnvironmentId] ??
          const <ReplaySimulationLabRerunRequest>[],
    )..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
    if (limit <= 0 || requests.length <= limit) {
      return requests;
    }
    return requests.take(limit).toList(growable: false);
  }

  @override
  Future<List<ReplaySimulationLabRerunJob>> listLabRerunJobs({
    required String environmentId,
    String? requestId,
    int limit = 12,
  }) async {
    final jobs = List<ReplaySimulationLabRerunJob>.from(
      _rerunJobs[environmentId] ?? const <ReplaySimulationLabRerunJob>[],
    )..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    final filtered = requestId == null
        ? jobs
        : jobs.where((entry) => entry.requestId == requestId).toList();
    if (limit <= 0 || filtered.length <= limit) {
      return filtered;
    }
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<List<ReplaySimulationLabFamilyRestageReviewItem>>
      listLabFamilyRestageReviewItems({
    required String environmentId,
    int limit = 12,
  }) async {
    final items = List<ReplaySimulationLabFamilyRestageReviewItem>.from(
      _familyRestageReviewItems[environmentId] ??
          const <ReplaySimulationLabFamilyRestageReviewItem>[],
    )..sort((left, right) => right.queuedAt.compareTo(left.queuedAt));
    if (limit <= 0 || items.length <= limit) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      requestLabFamilyRestageIntake({
    required String environmentId,
    required String evidenceFamily,
    String rationale = '',
    String ownerUserId = 'admin_operator',
  }) async {
    return _updateFamilyRestageReviewItem(
      environmentId: environmentId,
      evidenceFamily: evidenceFamily,
      nextStatus: 'restage_intake_requested',
      rationale: rationale,
    );
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      deferLabFamilyRestageReview({
    required String environmentId,
    required String evidenceFamily,
    String rationale = '',
  }) async {
    return _updateFamilyRestageReviewItem(
      environmentId: environmentId,
      evidenceFamily: evidenceFamily,
      nextStatus: 'watch_family_before_restage',
      rationale: rationale,
    );
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageIntakeReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: resolutionStatus == 'approved'
          ? 'restage_intake_review_approved'
          : 'restage_intake_review_held',
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: resolutionStatus,
      restageIntakeResolutionArtifactRef: resolutionArtifactRef,
      restageIntakeResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage intake review for this evidence family.'
              : 'Held bounded family restage intake review pending more evidence.'
          : rationale,
      restageIntakeResolutionRecordedAt: DateTime.utc(2026, 4, 4, 12, 0),
      followUpQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_follow_up_review'
          : existing.followUpQueueStatus,
      followUpQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_follow_up_review.current.json'
          : existing.followUpQueueJsonPath,
      followUpReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_FOLLOW_UP_REVIEW_README.md'
          : existing.followUpReadmePath,
      followUpSourceId: resolutionStatus == 'approved'
          ? 'family_restage_follow_up_source_${environmentId}_$evidenceFamily'
          : existing.followUpSourceId,
      followUpJobId: resolutionStatus == 'approved'
          ? 'family_restage_follow_up_job_${environmentId}_$evidenceFamily'
          : existing.followUpJobId,
      followUpReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_follow_up_review_${environmentId}_$evidenceFamily'
          : existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageFollowUpReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: resolutionStatus,
      followUpResolutionArtifactRef: resolutionArtifactRef,
      followUpResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage follow-up review for this evidence family.'
              : 'Held bounded family restage follow-up review pending more evidence.'
          : rationale,
      followUpResolutionRecordedAt: DateTime.utc(2026, 4, 5, 9, 0),
      restageResolutionQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_resolution_review'
          : existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_resolution_review.current.json'
          : existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_RESOLUTION_REVIEW_README.md'
          : existing.restageResolutionReadmePath,
      restageResolutionSourceId: resolutionStatus == 'approved'
          ? 'family_restage_resolution_source_${environmentId}_$evidenceFamily'
          : existing.restageResolutionSourceId,
      restageResolutionJobId: resolutionStatus == 'approved'
          ? 'family_restage_resolution_job_${environmentId}_$evidenceFamily'
          : existing.restageResolutionJobId,
      restageResolutionReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_resolution_review_${environmentId}_$evidenceFamily'
          : existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageResolutionReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus: resolutionStatus == 'approved'
          ? 'approved_for_bounded_family_restage_execution'
          : 'held_for_more_family_restage_resolution_evidence',
      restageResolutionResolutionArtifactRef: resolutionArtifactRef,
      restageResolutionResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage resolution review for this evidence family.'
              : 'Held bounded family restage resolution review pending more evidence.'
          : rationale,
      restageResolutionResolutionRecordedAt: DateTime.utc(2026, 4, 5, 10, 0),
      restageExecutionQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_execution_review'
          : existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_execution_review.current.json'
          : existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_EXECUTION_REVIEW_README.md'
          : existing.restageExecutionReadmePath,
      restageExecutionSourceId: resolutionStatus == 'approved'
          ? 'family_restage_execution_source_${environmentId}_$evidenceFamily'
          : existing.restageExecutionSourceId,
      restageExecutionJobId: resolutionStatus == 'approved'
          ? 'family_restage_execution_job_${environmentId}_$evidenceFamily'
          : existing.restageExecutionJobId,
      restageExecutionReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_execution_review_${environmentId}_$evidenceFamily'
          : existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageExecutionReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus: resolutionStatus == 'approved'
          ? 'approved_for_bounded_family_restage_application'
          : 'held_for_more_family_restage_execution_evidence',
      restageExecutionResolutionArtifactRef: resolutionArtifactRef,
      restageExecutionResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage execution review for this evidence family.'
              : 'Held bounded family restage execution review pending more evidence.'
          : rationale,
      restageExecutionResolutionRecordedAt: DateTime.utc(2026, 4, 5, 11, 0),
      restageApplicationQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_application_review'
          : existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_application_review.current.json'
          : existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_APPLICATION_REVIEW_README.md'
          : existing.restageApplicationReadmePath,
      restageApplicationSourceId: resolutionStatus == 'approved'
          ? 'family_restage_application_source_${environmentId}_$evidenceFamily'
          : existing.restageApplicationSourceId,
      restageApplicationJobId: resolutionStatus == 'approved'
          ? 'family_restage_application_job_${environmentId}_$evidenceFamily'
          : existing.restageApplicationJobId,
      restageApplicationReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_application_review_${environmentId}_$evidenceFamily'
          : existing.restageApplicationReviewItemId,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageApplicationReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus: resolutionStatus == 'approved'
          ? 'approved_for_bounded_family_restage_apply_to_served_basis'
          : 'held_for_more_family_restage_application_evidence',
      restageApplicationResolutionArtifactRef: resolutionArtifactRef,
      restageApplicationResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage application review for this evidence family.'
              : 'Held bounded family restage application review pending more evidence.'
          : rationale,
      restageApplicationResolutionRecordedAt: DateTime.utc(2026, 4, 5, 12, 0),
      restageApplyQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_apply_review'
          : existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_apply_review.current.json'
          : existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_APPLY_REVIEW_README.md'
          : existing.restageApplyReadmePath,
      restageApplySourceId: resolutionStatus == 'approved'
          ? 'family_restage_apply_source_${environmentId}_$evidenceFamily'
          : existing.restageApplySourceId,
      restageApplyJobId: resolutionStatus == 'approved'
          ? 'family_restage_apply_job_${environmentId}_$evidenceFamily'
          : existing.restageApplyJobId,
      restageApplyReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_apply_review_${environmentId}_$evidenceFamily'
          : existing.restageApplyReviewItemId,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageApplyReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: resolutionStatus == 'approved'
          ? 'approved_for_bounded_family_restage_served_basis_update'
          : 'held_for_more_family_restage_apply_evidence',
      restageApplyResolutionArtifactRef: resolutionArtifactRef,
      restageApplyResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage apply review for this evidence family.'
              : 'Held bounded family restage apply review pending more evidence.'
          : rationale,
      restageApplyResolutionRecordedAt: DateTime.utc(2026, 4, 5, 12, 0),
      restageServedBasisUpdateQueueStatus: resolutionStatus == 'approved'
          ? 'queued_for_family_restage_served_basis_update_review'
          : existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/family_restage_served_basis_update_review.current.json'
          : existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath: resolutionStatus == 'approved'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_SERVED_BASIS_UPDATE_REVIEW_README.md'
          : existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId: resolutionStatus == 'approved'
          ? 'family_restage_served_basis_update_source_${environmentId}_$evidenceFamily'
          : existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: resolutionStatus == 'approved'
          ? 'family_restage_served_basis_update_job_${environmentId}_$evidenceFamily'
          : existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId: resolutionStatus == 'approved'
          ? 'family_restage_served_basis_update_review_${environmentId}_$evidenceFamily'
          : existing.restageServedBasisUpdateReviewItemId,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageServedBasisUpdateReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus: resolutionStatus == 'approved'
          ? 'approved_for_bounded_family_restage_served_basis_mutation'
          : 'held_for_more_family_restage_served_basis_update_evidence',
      restageServedBasisUpdateResolutionArtifactRef: resolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale: rationale.isEmpty
          ? resolutionStatus == 'approved'
              ? 'Approved bounded family restage served-basis update review for this evidence family.'
              : 'Held bounded family restage served-basis update review pending more evidence.'
          : rationale,
      restageServedBasisUpdateResolutionRecordedAt:
          DateTime.utc(2026, 4, 5, 12, 5),
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  ReplaySimulationLabFamilyRestageReviewItem _updateFamilyRestageReviewItem({
    required String environmentId,
    required String evidenceFamily,
    required String nextStatus,
    required String rationale,
  }) {
    final items = _familyRestageReviewItems[environmentId] ??
        <ReplaySimulationLabFamilyRestageReviewItem>[];
    final index =
        items.indexWhere((entry) => entry.evidenceFamily == evidenceFamily);
    if (index == -1) {
      throw StateError('Unknown family restage review item `$evidenceFamily`.');
    }
    final existing = items[index];
    final artifactFileName = nextStatus == 'restage_intake_requested'
        ? 'family_restage_review_decision.restage_intake_requested.json'
        : 'family_restage_review_decision.watch_family_before_restage.json';
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: nextStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: '${existing.itemRoot}/$artifactFileName',
      queueDecisionRationale: rationale.isEmpty
          ? nextStatus == 'restage_intake_requested'
              ? 'Requested bounded restage intake review for this evidence family from World Simulation Lab.'
              : 'Deferred this evidence family into watch posture before requesting bounded restage intake.'
          : rationale,
      queueDecisionRecordedAt: DateTime.utc(2026, 4, 4, 11, 0),
      restageIntakeQueueJsonPath: nextStatus == 'restage_intake_requested'
          ? '${existing.itemRoot}/family_restage_intake_review.current.json'
          : existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: nextStatus == 'restage_intake_requested'
          ? '${existing.itemRoot}/FAMILY_RESTAGE_INTAKE_REVIEW_README.md'
          : existing.restageIntakeReadmePath,
      restageIntakeSourceId: nextStatus == 'restage_intake_requested'
          ? 'family_restage_source_${environmentId}_$evidenceFamily'
          : existing.restageIntakeSourceId,
      restageIntakeJobId: nextStatus == 'restage_intake_requested'
          ? 'family_restage_job_${environmentId}_$evidenceFamily'
          : existing.restageIntakeJobId,
      restageIntakeReviewItemId: nextStatus == 'restage_intake_requested'
          ? 'family_restage_review_${environmentId}_$evidenceFamily'
          : existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus:
          existing.restageServedBasisUpdateResolutionStatus,
      restageServedBasisUpdateResolutionArtifactRef:
          existing.restageServedBasisUpdateResolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale:
          existing.restageServedBasisUpdateResolutionRationale,
      restageServedBasisUpdateResolutionRecordedAt:
          existing.restageServedBasisUpdateResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    items[index] = updated;
    return updated;
  }

  ReplaySimulationLabRerunRequest _updateRerunRequestStatus({
    required String environmentId,
    required String requestId,
    required String nextStatus,
  }) {
    final requests =
        _rerunRequests[environmentId] ?? <ReplaySimulationLabRerunRequest>[];
    final index = requests.indexWhere((entry) => entry.requestId == requestId);
    if (index == -1) {
      throw StateError('Unknown rerun request `$requestId`.');
    }
    final now = nextStatus == 'running'
        ? DateTime.utc(2026, 4, 1, 14, 5)
        : DateTime.utc(2026, 4, 1, 14, 15);
    final existing = requests[index];
    final updated = switch (nextStatus) {
      'running' => existing.copyWith(
          requestStatus: 'running',
          startedAt: existing.startedAt ?? now,
        ),
      'completed' => existing.copyWith(
          requestStatus: 'completed',
          startedAt: existing.startedAt ?? DateTime.utc(2026, 4, 1, 14, 5),
          completedAt: now,
        ),
      _ => throw StateError('Unknown rerun status `$nextStatus`.'),
    };
    requests[index] = updated;
    return updated;
  }

  @override
  Future<List<ReplaySimulationLabOutcomeRecord>> listLabOutcomes({
    String? environmentId,
    int limit = 12,
  }) async {
    final resolvedEnvironmentId =
        environmentId ?? _environments.first.environmentId;
    final records = List<ReplaySimulationLabOutcomeRecord>.from(
      _history[resolvedEnvironmentId] ??
          const <ReplaySimulationLabOutcomeRecord>[],
    )..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    if (limit <= 0 || records.length <= limit) {
      return records;
    }
    return records.take(limit).toList(growable: false);
  }

  @override
  Future<ReplaySimulationLabServedBasisState> promoteStagedLatestStateBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'currentBasisStatus': 'latest_state_served_basis',
        'latestStateHydrationStatus': 'latest_state_basis_served',
        'latestStatePromotionReadiness': 'promoted_to_served_basis',
        'latestStateDecisionStatus': 'promoted',
        'latestStateDecisionArtifactRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_promotion_decision.promoted.json',
        'latestStateDecisionRationale': rationale.isEmpty
            ? 'Promoted after bounded latest-state basis review.'
            : rationale,
        'latestStateRefreshReceiptRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_refresh_receipts.refresh.json',
        'hydrationFreshnessPosture':
            'served_basis_updated_from_latest_state_receipts',
        'latestStatePromotionBlockedReasons': const <String>[],
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 15),
      servedBasisRef:
          'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: const <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
      },
      latestStateDecisionStatus: 'promoted',
      latestStateDecisionArtifactRef:
          metadata['latestStateDecisionArtifactRef'] as String,
      latestStateDecisionRationale:
          metadata['latestStateDecisionRationale'] as String,
      latestStateRefreshReceiptRef:
          metadata['latestStateRefreshReceiptRef'] as String,
      currentBasisStatus: 'latest_state_served_basis',
      latestStateHydrationStatus: 'latest_state_basis_served',
      latestStatePromotionReadiness: 'promoted_to_served_basis',
      hydrationFreshnessPosture:
          'served_basis_updated_from_latest_state_receipts',
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState> rejectStagedLatestStateBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'currentBasisStatus': 'replay_grounded_seed_basis',
        'latestStateHydrationStatus': 'latest_state_basis_rejected',
        'latestStatePromotionReadiness':
            'blocked_pending_latest_state_evidence',
        'latestStateDecisionStatus': 'rejected',
        'latestStateDecisionArtifactRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_promotion_decision.rejected.json',
        'latestStateDecisionRationale': rationale.isEmpty
            ? 'Rejected after bounded latest-state basis review.'
            : rationale,
        'latestStateRefreshReceiptRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_refresh_receipts.refresh.json',
        'hydrationFreshnessPosture':
            'prior_served_basis_restored_after_rejection',
        'latestStatePromotionBlockedReasons': const <String>[
          'The previously staged latest-state basis was rejected during bounded review.',
        ],
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 15),
      servedBasisRef:
          'world_simulation_lab/registered_environments/$environmentId/served_city_pack_basis.seed.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: const <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.seed.json',
      },
      latestStateDecisionStatus: 'rejected',
      latestStateDecisionArtifactRef:
          metadata['latestStateDecisionArtifactRef'] as String,
      latestStateDecisionRationale:
          metadata['latestStateDecisionRationale'] as String,
      latestStateRefreshReceiptRef:
          metadata['latestStateRefreshReceiptRef'] as String,
      currentBasisStatus: 'replay_grounded_seed_basis',
      latestStateHydrationStatus: 'latest_state_basis_rejected',
      latestStatePromotionReadiness: 'blocked_pending_latest_state_evidence',
      latestStatePromotionBlockedReasons: const <String>[
        'The previously staged latest-state basis was rejected during bounded review.',
      ],
      hydrationFreshnessPosture: 'prior_served_basis_restored_after_rejection',
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState> revalidatePromotedServedBasis({
    required String environmentId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'currentBasisStatus': 'latest_state_served_basis',
        'latestStateHydrationStatus': 'latest_state_basis_served_revalidated',
        'latestStatePromotionReadiness': 'served_basis_revalidated_current',
        'latestStateRevalidationStatus': 'current',
        'latestStateRevalidationReceiptRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_revalidation_receipts.revalidation.json',
        'latestStateRevalidationArtifactRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_revalidation.current.json',
        'hydrationFreshnessPosture':
            'served_basis_still_supported_by_current_receipts',
        'latestStatePromotionBlockedReasons': const <String>[],
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 16),
      servedBasisRef:
          'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: const <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
      },
      latestStateDecisionStatus:
          metadata['latestStateDecisionStatus']?.toString() ?? 'promoted',
      latestStateDecisionArtifactRef:
          metadata['latestStateDecisionArtifactRef'] as String?,
      latestStateDecisionRationale:
          metadata['latestStateDecisionRationale'] as String?,
      latestStateRefreshReceiptRef:
          metadata['latestStateRefreshReceiptRef'] as String?,
      latestStateRevalidationStatus: 'current',
      latestStateRevalidationReceiptRef:
          metadata['latestStateRevalidationReceiptRef'] as String,
      latestStateRevalidationArtifactRef:
          metadata['latestStateRevalidationArtifactRef'] as String,
      currentBasisStatus: 'latest_state_served_basis',
      latestStateHydrationStatus: 'latest_state_basis_served_revalidated',
      latestStatePromotionReadiness: 'served_basis_revalidated_current',
      hydrationFreshnessPosture:
          'served_basis_still_supported_by_current_receipts',
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState> refreshLatestStateEvidenceBundle({
    required String environmentId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'latestStateHydrationStatus':
            'latest_avrai_evidence_refreshed_ready_for_staging',
        'latestStatePromotionReadiness': 'ready_for_bounded_basis_review',
        'latestStatePromotionBlockedReasons': const <String>[],
        'hydrationFreshnessPosture':
            'ready_for_served_basis_review_with_receipts',
        'latestStateRefreshReceiptRef':
            'world_simulation_lab/registered_environments/$environmentId/latest_state/latest_state_refresh.current.json',
        'latestStateRefreshCadenceStatus': 'within_refresh_window',
        'latestStateRefreshReferenceAt':
            DateTime.utc(2026, 4, 1, 16, 30).toIso8601String(),
        'latestStateEvidenceRefs': <String>[
          'world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.current.json',
          'world_simulation_lab/registered_environments/$environmentId/latest_state/runtime_os_locality_state.current.json',
          'world_simulation_lab/registered_environments/$environmentId/latest_state/governed_reality_model_outputs.current.json',
        ],
        'latestStateEvidenceSelectionSummaries': <String>[
          'app observations -> world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.current.json (selected current evidence, 0.0h, 86% strength, receipt-backed, policy <= 12h and >= 72%)',
          'runtime/OS locality state -> world_simulation_lab/registered_environments/$environmentId/latest_state/runtime_os_locality_state.current.json (selected current evidence, 0.0h, 89% strength, receipt-backed, policy <= 10h and >= 78%)',
          'governed reality-model outputs -> world_simulation_lab/registered_environments/$environmentId/latest_state/governed_reality_model_outputs.current.json (selected current evidence, 0.0h, 80% strength, receipt-backed, policy <= 24h and >= 70%)',
        ],
        'latestStateEvidenceAgingSummaries': <String>[
          'app observations: within policy window at 0.0h of 12h and receipt-backed.',
          'runtime/OS locality state: within policy window at 0.0h of 10h and receipt-backed.',
          'governed reality-model outputs: within policy window at 0.0h of 24h and receipt-backed.',
        ],
        'latestStateEvidenceAgingTrendSummaries': <String>[
          'app observations: recent cadence checks refreshed this family and it remains within policy window.',
          'runtime/OS locality state: recent cadence checks refreshed this family and it remains within policy window.',
          'governed reality-model outputs: recent cadence checks refreshed this family and it remains within policy window.',
        ],
        'latestStateEvidencePolicyActionSummaries': <String>[
          'app observations: no policy action required because this family is stable with recent refresh and remains within policy window.',
          'runtime/OS locality state: no policy action required because this family is stable with recent refresh and remains within policy window.',
          'governed reality-model outputs: no policy action required because this family is stable with recent refresh and remains within policy window.',
        ],
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 16, 30),
      servedBasisRef: metadata['servedBasisRef']?.toString() ??
          'world_simulation_lab/registered_environments/$environmentId/served_city_pack_basis.seed.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.current.json',
        'runtime_os_locality_state':
            'world_simulation_lab/registered_environments/$environmentId/latest_state/runtime_os_locality_state.current.json',
        'governed_reality_model_outputs':
            'world_simulation_lab/registered_environments/$environmentId/latest_state/governed_reality_model_outputs.current.json',
      },
      latestStateEvidenceSelectionSummariesByFamily: <String, String>{
        'app_observations':
            'app observations -> world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.current.json (selected current evidence, 0.0h, 86% strength, receipt-backed, policy <= 12h and >= 72%)',
        'runtime_os_locality_state':
            'runtime/OS locality state -> world_simulation_lab/registered_environments/$environmentId/latest_state/runtime_os_locality_state.current.json (selected current evidence, 0.0h, 89% strength, receipt-backed, policy <= 10h and >= 78%)',
        'governed_reality_model_outputs':
            'governed reality-model outputs -> world_simulation_lab/registered_environments/$environmentId/latest_state/governed_reality_model_outputs.current.json (selected current evidence, 0.0h, 80% strength, receipt-backed, policy <= 24h and >= 70%)',
      },
      latestStateEvidenceAgingStatusesByFamily: const <String, String>{
        'app_observations': 'within_policy_window',
        'runtime_os_locality_state': 'within_policy_window',
        'governed_reality_model_outputs': 'within_policy_window',
      },
      latestStateEvidenceAgingSummariesByFamily: const <String, String>{
        'app_observations':
            'app observations: within policy window at 0.0h of 12h and receipt-backed.',
        'runtime_os_locality_state':
            'runtime/OS locality state: within policy window at 0.0h of 10h and receipt-backed.',
        'governed_reality_model_outputs':
            'governed reality-model outputs: within policy window at 0.0h of 24h and receipt-backed.',
      },
      latestStateEvidenceAgingTransitionsByFamily: const <String, String>{
        'app_observations': 'refreshed_with_newer_evidence',
        'runtime_os_locality_state': 'refreshed_with_newer_evidence',
        'governed_reality_model_outputs': 'refreshed_with_newer_evidence',
      },
      latestStateEvidenceAgingTrendsByFamily: const <String, String>{
        'app_observations': 'stable_with_recent_refresh',
        'runtime_os_locality_state': 'stable_with_recent_refresh',
        'governed_reality_model_outputs': 'stable_with_recent_refresh',
      },
      latestStateEvidenceAgingTrendSummariesByFamily: const <String, String>{
        'app_observations':
            'app observations: recent cadence checks refreshed this family and it remains within policy window.',
        'runtime_os_locality_state':
            'runtime/OS locality state: recent cadence checks refreshed this family and it remains within policy window.',
        'governed_reality_model_outputs':
            'governed reality-model outputs: recent cadence checks refreshed this family and it remains within policy window.',
      },
      latestStateEvidencePolicyActionsByFamily: const <String, String>{
        'app_observations': 'no_action_family_stable',
        'runtime_os_locality_state': 'no_action_family_stable',
        'governed_reality_model_outputs': 'no_action_family_stable',
      },
      latestStateEvidencePolicyActionSummariesByFamily: const <String, String>{
        'app_observations':
            'app observations: no policy action required because this family is stable with recent refresh and remains within policy window.',
        'runtime_os_locality_state':
            'runtime/OS locality state: no policy action required because this family is stable with recent refresh and remains within policy window.',
        'governed_reality_model_outputs':
            'governed reality-model outputs: no policy action required because this family is stable with recent refresh and remains within policy window.',
      },
      latestStateRefreshReceiptRef:
          metadata['latestStateRefreshReceiptRef'] as String,
      currentBasisStatus: metadata['currentBasisStatus']?.toString() ??
          'replay_grounded_seed_basis',
      latestStateHydrationStatus:
          'latest_avrai_evidence_refreshed_ready_for_staging',
      latestStatePromotionReadiness: 'ready_for_bounded_basis_review',
      latestStatePromotionBlockedReasons: const <String>[],
      hydrationFreshnessPosture: 'ready_for_served_basis_review_with_receipts',
      latestStateRefreshCadenceHours:
          (metadata['latestStateRefreshCadenceHours'] as num?)?.toInt() ?? 18,
      latestStateRefreshCadenceStatus: 'within_refresh_window',
      latestStateRefreshReferenceAt: DateTime.utc(2026, 4, 1, 16, 30),
      latestStateRefreshPolicySummaries:
          (metadata['latestStateRefreshPolicySummaries'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false),
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState>
      runScheduledLatestStateRefreshCheck({
    required String environmentId,
  }) async {
    final refreshed = await refreshLatestStateEvidenceBundle(
      environmentId: environmentId,
    );
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'latestStateRefreshExecutionStatus': 'executed_due_refresh',
        'latestStateRefreshExecutionReceiptRef':
            'world_simulation_lab/registered_environments/$environmentId/latest_state/latest_state_refresh_cadence.current.json',
        'latestStateRefreshExecutionCheckedAt':
            DateTime.utc(2026, 4, 2, 13, 0).toIso8601String(),
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: refreshed.environmentId,
      supportedPlaceRef: refreshed.supportedPlaceRef,
      stagedAt: refreshed.stagedAt,
      servedBasisRef: refreshed.servedBasisRef,
      cityPackStructuralRef: refreshed.cityPackStructuralRef,
      latestStateEvidenceRefsByFamily:
          refreshed.latestStateEvidenceRefsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          refreshed.latestStateEvidenceSelectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          refreshed.latestStateEvidenceAgingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          refreshed.latestStateEvidenceAgingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          refreshed.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          refreshed.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          refreshed.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          refreshed.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          refreshed.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateRefreshReceiptRef: refreshed.latestStateRefreshReceiptRef,
      currentBasisStatus: refreshed.currentBasisStatus,
      latestStateHydrationStatus: refreshed.latestStateHydrationStatus,
      latestStatePromotionReadiness: refreshed.latestStatePromotionReadiness,
      latestStatePromotionBlockedReasons:
          refreshed.latestStatePromotionBlockedReasons,
      hydrationFreshnessPosture: refreshed.hydrationFreshnessPosture,
      latestStateRefreshCadenceHours: refreshed.latestStateRefreshCadenceHours,
      latestStateRefreshCadenceStatus:
          refreshed.latestStateRefreshCadenceStatus,
      latestStateRefreshReferenceAt: refreshed.latestStateRefreshReferenceAt,
      latestStateRefreshPolicySummaries:
          refreshed.latestStateRefreshPolicySummaries,
      latestStateRefreshExecutionStatus: 'executed_due_refresh',
      latestStateRefreshExecutionReceiptRef:
          'world_simulation_lab/registered_environments/$environmentId/latest_state/latest_state_refresh_cadence.current.json',
      latestStateRefreshExecutionCheckedAt: DateTime.utc(2026, 4, 2, 13, 0),
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState>
      confirmExpiredServedBasisRestageRequired({
    required String environmentId,
    String rationale = '',
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'currentBasisStatus': 'expired_latest_state_served_basis',
        'latestStateHydrationStatus':
            'expired_basis_restage_required_confirmed',
        'latestStatePromotionReadiness':
            'restage_required_before_served_basis_reuse',
        'latestStateRecoveryDecisionStatus': 'restage_required_confirmed',
        'latestStateRecoveryDecisionArtifactRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_restore_decision.restage_required.json',
        'latestStateRecoveryDecisionRationale': rationale.isEmpty
            ? 'The expired served basis must remain out of service until a new staged refresh is reviewed.'
            : rationale,
        'hydrationFreshnessPosture': 'expired_basis_restage_required_confirmed',
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 16),
      servedBasisRef:
          'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: const <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
      },
      latestStateRecoveryDecisionStatus: 'restage_required_confirmed',
      latestStateRecoveryDecisionArtifactRef:
          metadata['latestStateRecoveryDecisionArtifactRef'] as String,
      latestStateRecoveryDecisionRationale:
          metadata['latestStateRecoveryDecisionRationale'] as String,
      currentBasisStatus: 'expired_latest_state_served_basis',
      latestStateHydrationStatus: 'expired_basis_restage_required_confirmed',
      latestStatePromotionReadiness:
          'restage_required_before_served_basis_reuse',
      hydrationFreshnessPosture: 'expired_basis_restage_required_confirmed',
    );
  }

  @override
  Future<ReplaySimulationLabServedBasisState> restoreExpiredServedBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final metadata = Map<String, dynamic>.from(snapshot.foundation.metadata)
      ..addAll(<String, dynamic>{
        'currentBasisStatus': 'latest_state_served_basis',
        'latestStateHydrationStatus':
            'latest_state_basis_restored_after_review',
        'latestStatePromotionReadiness':
            'restored_to_served_basis_after_review',
        'latestStateRecoveryDecisionStatus': 'restored_after_review',
        'latestStateRecoveryDecisionArtifactRef':
            'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/basis_restore_decision.restored.json',
        'latestStateRecoveryDecisionRationale': rationale.isEmpty
            ? 'Restored after bounded review confirmed current latest-state evidence is strong enough to serve again.'
            : rationale,
        'hydrationFreshnessPosture':
            'served_basis_restored_from_revalidated_receipts',
      });
    _snapshots[environmentId] = _replaceSnapshotFoundationMetadata(
      snapshot,
      metadata,
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: environmentId,
      supportedPlaceRef: 'place:${snapshot.cityCode}',
      stagedAt: DateTime.utc(2026, 4, 1, 16),
      servedBasisRef:
          'world_simulation_lab/registered_environments/$environmentId/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
      cityPackStructuralRef:
          metadata['cityPackStructuralRef']?.toString().trim().isEmpty ?? true
              ? null
              : metadata['cityPackStructuralRef'].toString(),
      latestStateEvidenceRefsByFamily: const <String, String>{
        'app_observations':
            'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
      },
      latestStateRecoveryDecisionStatus: 'restored_after_review',
      latestStateRecoveryDecisionArtifactRef:
          metadata['latestStateRecoveryDecisionArtifactRef'] as String,
      latestStateRecoveryDecisionRationale:
          metadata['latestStateRecoveryDecisionRationale'] as String,
      currentBasisStatus: 'latest_state_served_basis',
      latestStateHydrationStatus: 'latest_state_basis_restored_after_review',
      latestStatePromotionReadiness: 'restored_to_served_basis_after_review',
      hydrationFreshnessPosture:
          'served_basis_restored_from_revalidated_receipts',
    );
  }
}

ReplaySimulationAdminSnapshot _replaceSnapshotFoundationMetadata(
  ReplaySimulationAdminSnapshot snapshot,
  Map<String, dynamic> metadata,
) {
  return ReplaySimulationAdminSnapshot(
    generatedAt: snapshot.generatedAt,
    environmentId: snapshot.environmentId,
    cityCode: snapshot.cityCode,
    replayYear: snapshot.replayYear,
    scenarios: snapshot.scenarios,
    comparisons: snapshot.comparisons,
    receipts: snapshot.receipts,
    contradictions: snapshot.contradictions,
    localityOverlays: snapshot.localityOverlays,
    foundation: ReplaySimulationAdminFoundationSummary(
      simulationMode: snapshot.foundation.simulationMode,
      intakeFlowRefs: snapshot.foundation.intakeFlowRefs,
      sidecarRefs: snapshot.foundation.sidecarRefs,
      trainingArtifactFamilies: snapshot.foundation.trainingArtifactFamilies,
      kernelStates: snapshot.foundation.kernelStates,
      notes: snapshot.foundation.notes,
      metadata: metadata,
    ),
    learningReadiness: snapshot.learningReadiness,
    syntheticHumanKernelExplorer: snapshot.syntheticHumanKernelExplorer,
    localityHierarchyHealth: snapshot.localityHierarchyHealth,
    higherAgentHandoffView: snapshot.higherAgentHandoffView,
    realismProvenance: snapshot.realismProvenance,
    weakSpots: snapshot.weakSpots,
  );
}

ReplaySimulationAdminSnapshot _buildSnapshot({
  required String environmentId,
  required String cityCode,
  required int replayYear,
  required bool shareWithRealityModelAllowed,
}) {
  return ReplaySimulationAdminSnapshot(
    generatedAt: DateTime.utc(2026, 4, 1, 12),
    environmentId: environmentId,
    cityCode: cityCode,
    replayYear: replayYear,
    scenarios: <ReplayScenarioPacket>[
      ReplayScenarioPacket(
        scenarioId: 'savannah_freight_detour',
        name: 'Savannah Freight Detour',
        description: 'Simulate freight rerouting pressure near the waterfront.',
        cityCode: cityCode,
        baseReplayYear: replayYear,
        scenarioKind: ReplayScenarioKind.transitFriction,
        scope: ReplayScopeKind.corridor,
        seedEntityRefs: const <String>['corridor:sav-waterfront'],
        seedLocalityCodes: <String>['$cityCode-waterfront'],
        seedObservationRefs: const <String>['obs:waterfront:freight'],
        interventions: const <ReplayScenarioIntervention>[],
        expectedQuestions: const <String>[
          'Does the waterfront detour remain stable under surge conditions?',
        ],
        createdAt: DateTime.utc(2026, 4, 1, 11),
        createdBy: 'world_simulation_lab_test',
      ),
    ],
    comparisons: const <ReplayScenarioComparison>[],
    receipts: const <SimulationTruthReceipt>[],
    contradictions: const <ReplayContradictionSnapshot>[],
    localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
    foundation: ReplaySimulationAdminFoundationSummary(
      simulationMode: 'generic_city_pack',
      intakeFlowRefs: const <String>[
        'source_intake_orchestrator',
        'air_gap_normalizer',
      ],
      sidecarRefs: <String>['city_packs/$cityCode/${replayYear}_manifest.json'],
      metadata: <String, dynamic>{
        'cityPackStructuralRef': 'city_pack:${cityCode}_core_$replayYear',
        'populationModelKind': 'scenario_seeded_synthetic_city',
        'modeledUserLayerKind': 'representative_synthetic_human_lanes',
        'campaignDefaultsRef': 'city_packs/$cityCode/campaign_defaults.json',
        'localityExpectationProfileRef':
            'city_packs/$cityCode/locality_expectations.json',
        'worldHealthProfileRef': 'city_packs/$cityCode/world_health.json',
        'supportedPlaceRef': 'place:$cityCode',
        'cityPackRefreshMode': 'versioned_living_city_pack',
        'currentBasisStatus': 'replay_grounded_seed_basis',
        'latestStateHydrationStatus': 'awaiting_latest_avrai_evidence_refresh',
        'latestStatePromotionReadiness':
            'blocked_pending_latest_state_evidence',
        'latestStatePromotionBlockedReasons': const <String>[
          'app observations is still using seed placeholder evidence.',
        ],
        'hydrationEvidenceFamilies': const <String>[
          'app_observations',
          'runtime_os_locality_state',
          'governed_reality_model_outputs',
        ],
        'hydrationFreshnessPosture':
            'refresh_receipts_required_before_served_basis_change',
        'latestStateRefreshCadenceHours': cityCode == 'sav' ? 18 : 24,
        'latestStateRefreshCadenceStatus': 'awaiting_first_refresh_receipts',
        'latestStateRefreshPolicySummaries': <String>[
          if (cityCode == 'sav')
            'app observations <= 12h, >= 72% strength for place:$cityCode',
          if (cityCode == 'sav')
            'runtime/OS locality state <= 10h, >= 78% strength for place:$cityCode',
          if (cityCode == 'sav')
            'governed reality-model outputs <= 24h, >= 70% strength for place:$cityCode'
          else
            'app observations <= 18h, >= 70% strength for place:$cityCode',
        ],
        'latestStateEvidenceSelectionSummaries': <String>[
          'app observations -> world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.seed.json (seed placeholder, 9999h, 0% strength, not receipt-backed, policy <= 12h and >= 72%)',
        ],
        'latestStateEvidenceAgingSummaries': <String>[
          'app observations: seed placeholder still active against the 12h policy window for place:$cityCode.',
        ],
        'latestStateEvidenceAgingTrendSummaries': const <String>[],
        'latestStateEvidencePolicyActionSummaries': const <String>[],
        'latestStateEvidenceRefs': <String>[
          'world_simulation_lab/registered_environments/$environmentId/latest_state/app_observations.seed.json',
          'world_simulation_lab/registered_environments/$environmentId/latest_state/runtime_os_locality_state.seed.json',
          'world_simulation_lab/registered_environments/$environmentId/latest_state/governed_reality_model_outputs.seed.json',
        ],
        'servedBasisRef':
            'world_simulation_lab/registered_environments/$environmentId/served_city_pack_basis.seed.json',
      },
      kernelStates: const <ReplaySimulationKernelState>[
        ReplaySimulationKernelState(
          kernelId: 'kernel.mobility.routing',
          status: 'missing',
          reason: 'Routing kernel still lacks stable waterfront evidence.',
        ),
        ReplaySimulationKernelState(
          kernelId: 'kernel.event.pressure',
          status: 'active',
          reason: 'Event pressure kernel is already active.',
        ),
      ],
      trainingArtifactFamilies: const <String>[
        'simulation_snapshot',
        'learning_bundle',
      ],
    ),
    learningReadiness: ReplaySimulationLearningReadiness(
      trainingGrade: shareWithRealityModelAllowed ? 'strong' : 'review',
      shareWithRealityModelAllowed: shareWithRealityModelAllowed,
      reasons: <String>[
        if (shareWithRealityModelAllowed)
          'Simulation has enough stable evidence for bounded learning review.'
        else
          'Simulation still needs operator iteration before training.',
      ],
      suggestedTrainingUse: shareWithRealityModelAllowed
          ? 'bounded_reality_model_review'
          : 'simulation_debug_only',
      requestPreviews: shareWithRealityModelAllowed
          ? <ReplaySimulationRealityModelRequestPreview>[
              ReplaySimulationRealityModelRequestPreview(
                request: RealityModelEvaluationRequest(
                  requestId: 'sim-$cityCode-1',
                  subjectId: 'simulation:$cityCode-waterfront',
                  domain: RealityModelDomain.locality,
                  candidateRef: 'locality:$cityCode-waterfront',
                  localityCode: '$cityCode-waterfront',
                  cityCode: cityCode,
                  signalTags: const <String>['simulation_bundle'],
                  evidenceRefs: const <String>[
                    'simulation_snapshot.json#overlay:waterfront',
                  ],
                  requestedAtUtc: DateTime.utc(2026, 4, 1, 12),
                ),
                rationale:
                    'Use the waterfront locality as the bounded review seed.',
              ),
            ]
          : const <ReplaySimulationRealityModelRequestPreview>[],
    ),
    syntheticHumanKernelExplorer: ReplaySimulationSyntheticHumanKernelExplorer(
      requiredKernelIds: const <String>[
        'kernel.mobility.routing',
        'kernel.event.pressure',
      ],
      modeledActorCount: 2,
      actorsWithFullBundle: 1,
      summary:
          'Representative synthetic-human lanes expose where the current simulation still needs operator-guided realism work.',
      entries: <ReplaySimulationSyntheticHumanKernelEntry>[
        ReplaySimulationSyntheticHumanKernelEntry(
          actorId: 'synthetic:$cityCode:waterfront:lane:1',
          displayName: 'Savannah Waterfront Representative Lane',
          localityAnchor: 'waterfront',
          attachedKernelIds: const <String>[
            'kernel.mobility.routing',
            'kernel.event.pressure',
          ],
          readyKernelIds: const <String>['kernel.event.pressure'],
          missingKernelIds: const <String>['kernel.mobility.routing'],
          notReadyKernelIds: const <String>['kernel.mobility.routing'],
          activationCountByKernel: const <String, int>{
            'kernel.mobility.routing': 2,
            'kernel.event.pressure': 6,
          },
          higherAgentGuidanceCount: 2,
          summary:
              'Waterfront synthetic-human lane is still short on route realism but strong on event pressure behavior.',
          traceSummary: const <String>[
            'Scenario seeds: Savannah Freight Detour',
            'Contradictions: 2 • Receipts: 0 • Branch diffs: 1',
            'Branch sensitivity: 47% • Attention: escalate',
          ],
        ),
      ],
    ),
    localityHierarchyHealth: ReplaySimulationLocalityHierarchyHealth(
      summary:
          'Savannah Waterfront is currently the most stressed lane, while Savannah Midtown remains the cleanest hierarchy lane.',
      strongestLocalityLabel: 'Savannah Midtown',
      stressedLocalityLabel: 'Savannah Waterfront',
      stableLocalityCount: 1,
      escalatingLocalityCount: 1,
      nodes: const <ReplaySimulationLocalityHierarchyNodeSummary>[
        ReplaySimulationLocalityHierarchyNodeSummary(
          localityCode: 'sav_waterfront',
          displayName: 'Savannah Waterfront',
          pressureBand: 'high',
          attentionBand: 'escalate',
          primarySignals: <String>['freight detour', 'pedestrian spillover'],
          branchSensitivity: 0.47,
          contradictionCount: 2,
          effectiveness: 'stressed',
          risk: 'high',
          summary:
              'Savannah Waterfront still shows contradiction pressure and branch sensitivity that should stay in bounded review.',
          traceSummary: <String>[
            'Branch sensitivity: 47%',
            'Primary signal count: 2',
            'Scenario seeds: Savannah Freight Detour',
            'Hierarchy posture: review-first',
          ],
        ),
        ReplaySimulationLocalityHierarchyNodeSummary(
          localityCode: 'sav_midtown',
          displayName: 'Savannah Midtown',
          pressureBand: 'moderate',
          attentionBand: 'watch',
          primarySignals: <String>['venue occupancy'],
          branchSensitivity: 0.16,
          contradictionCount: 0,
          effectiveness: 'stable',
          risk: 'low',
          summary:
              'Savannah Midtown is currently functioning as the cleanest locality lane.',
          traceSummary: <String>[
            'Branch sensitivity: 16%',
            'Primary signal count: 1',
            'Hierarchy posture: bounded handoff',
          ],
        ),
      ],
    ),
    higherAgentHandoffView: ReplaySimulationHigherAgentHandoffView(
      summary:
          'Higher-agent synthesis is still review-first because the waterfront lane remains stressed.',
      items: const <ReplaySimulationHigherAgentHandoffItem>[
        ReplaySimulationHigherAgentHandoffItem(
          scope: 'locality',
          targetLabel: 'Savannah Waterfront',
          status: 'review_only',
          summary:
              'Keep Savannah Waterfront inside bounded review until the contradiction pressure falls.',
          guidance: <String>[
            'Primary signals: freight detour, pedestrian spillover',
            'Attention band: escalate',
          ],
          traceSummary: <String>[
            'Locality code: sav_waterfront',
            'Risk: high • Effectiveness: stressed',
            'Contradictions: 2 • Branch sensitivity: 47%',
          ],
        ),
        ReplaySimulationHigherAgentHandoffItem(
          scope: 'city',
          targetLabel: 'Savannah Simulation Environment 2024 city synthesis',
          status: 'bounded_review_before_downward_guidance',
          summary:
              'The city layer is still aggregating one stressed locality lane.',
          guidance: <String>[
            'Strongest locality lane: Savannah Midtown',
            'Most stressed locality lane: Savannah Waterfront',
          ],
          traceSummary: <String>[
            'Tracked locality lanes: 2',
            'Escalating localities: 1',
            'Stable localities: 1',
          ],
        ),
      ],
    ),
    realismProvenance: ReplaySimulationRealismProvenanceSummary(
      simulationMode: 'generic_city_pack',
      cityPackStructuralRef: 'city_pack:${cityCode}_core_$replayYear',
      populationModelKind: 'scenario_seeded_synthetic_city',
      modeledUserLayerKind: 'representative_synthetic_human_lanes',
      campaignDefaultsRef: 'city_packs/$cityCode/campaign_defaults.json',
      localityExpectationProfileRef:
          'city_packs/$cityCode/locality_expectations.json',
      worldHealthProfileRef: 'city_packs/$cityCode/world_health.json',
      intakeFlowRefs: const <String>[
        'source_intake_orchestrator',
        'air_gap_normalizer',
      ],
      sidecarRefs: <String>['city_packs/$cityCode/${replayYear}_manifest.json'],
      trainingArtifactFamilies: const <String>[
        'simulation_snapshot',
        'learning_bundle',
      ],
    ),
    weakSpots: const <ReplaySimulationWeakSpotSummary>[
      ReplaySimulationWeakSpotSummary(
        title: 'Kernel gap: kernel.mobility.routing',
        severity: 'high',
        summary:
            'Routing kernel still lacks stable waterfront evidence before training.',
        recommendedAction:
            'Add route realism evidence and rerun the waterfront lane before bounded review.',
        metadata: <String, dynamic>{
          'kernelId': 'kernel.mobility.routing',
          'status': 'missing',
        },
      ),
      ReplaySimulationWeakSpotSummary(
        title: 'Locality stress: Savannah Waterfront',
        severity: 'high',
        summary:
            'Savannah Waterfront remains stressed with contradiction and hierarchy pressure.',
        recommendedAction: 'Iterate the waterfront lane again before training.',
        metadata: <String, dynamic>{'localityCode': 'sav_waterfront'},
      ),
    ],
  );
}

ReplaySimulationLabOutcomeRecord _buildOutcome({
  required String environmentId,
  required String cityCode,
  required ReplaySimulationLabDisposition disposition,
  required DateTime recordedAt,
  required String operatorRationale,
  String? variantId,
  String? variantLabel,
  List<ReplaySimulationSyntheticHumanKernelEntry> syntheticHumanKernelEntries =
      const <ReplaySimulationSyntheticHumanKernelEntry>[],
  List<ReplaySimulationLocalityHierarchyNodeSummary> localityHierarchyNodes =
      const <ReplaySimulationLocalityHierarchyNodeSummary>[],
  List<ReplaySimulationHigherAgentHandoffItem> higherAgentHandoffItems =
      const <ReplaySimulationHigherAgentHandoffItem>[],
  ReplaySimulationRealismProvenanceSummary realismProvenance =
      const ReplaySimulationRealismProvenanceSummary(),
}) {
  return ReplaySimulationLabOutcomeRecord(
    environmentId: environmentId,
    cityCode: cityCode,
    replayYear: 2024,
    labRoot: '/tmp/world_simulation_lab/$environmentId/history',
    snapshotJsonPath:
        '/tmp/world_simulation_lab/$environmentId/simulation_snapshot.json',
    learningBundleJsonPath:
        '/tmp/world_simulation_lab/$environmentId/simulation_learning_bundle.json',
    realityModelRequestJsonPath:
        '/tmp/world_simulation_lab/$environmentId/reality_model_request_previews.json',
    outcomeJsonPath:
        '/tmp/world_simulation_lab/$environmentId/world_simulation_lab_outcome.json',
    readmePath:
        '/tmp/world_simulation_lab/$environmentId/WORLD_SIMULATION_LAB_README.md',
    recordedAt: recordedAt,
    disposition: disposition,
    operatorRationale: operatorRationale,
    operatorNotes: const <String>[],
    trainingGrade: 'review',
    suggestedTrainingUse: 'simulation_debug_only',
    shareWithRealityModelAllowed: false,
    scenarioCount: 1,
    comparisonCount: 0,
    receiptCount: 0,
    contradictionCount: 0,
    overlayCount: 0,
    requestPreviewCount: 0,
    simulationMode: 'generic_city_pack',
    syntheticHumanKernelEntries: syntheticHumanKernelEntries,
    localityHierarchyNodes: localityHierarchyNodes,
    higherAgentHandoffItems: higherAgentHandoffItems,
    realismProvenance: realismProvenance,
    intakeFlowRefs: const <String>['source_intake_orchestrator'],
    sidecarRefs: const <String>['city_packs/sav/2024_manifest.json'],
    cityPackStructuralRef: 'city_pack:sav_core_2024',
    trainingArtifactFamilies: const <String>[],
    variantId: variantId,
    variantLabel: variantLabel,
  );
}

ReplaySimulationLabRerunJob _buildCompletedRerunJob({
  required String environmentId,
  required String cityCode,
  required DateTime startedAt,
  required DateTime completedAt,
  String? variantId,
  String? variantLabel,
  List<ReplaySimulationSyntheticHumanKernelEntry> syntheticHumanKernelEntries =
      const <ReplaySimulationSyntheticHumanKernelEntry>[],
  List<ReplaySimulationLocalityHierarchyNodeSummary> localityHierarchyNodes =
      const <ReplaySimulationLocalityHierarchyNodeSummary>[],
  List<ReplaySimulationHigherAgentHandoffItem> higherAgentHandoffItems =
      const <ReplaySimulationHigherAgentHandoffItem>[],
  ReplaySimulationRealismProvenanceSummary realismProvenance =
      const ReplaySimulationRealismProvenanceSummary(),
}) {
  return ReplaySimulationLabRerunJob(
    jobId: 'rerun-job-$environmentId-${startedAt.toIso8601String()}',
    requestId: 'rerun-request-$environmentId',
    environmentId: environmentId,
    cityCode: cityCode,
    replayYear: 2024,
    jobStatus: 'completed',
    jobRoot: '/tmp/world_simulation_lab/$environmentId/runtime_jobs',
    jobJsonPath:
        '/tmp/world_simulation_lab/$environmentId/runtime_jobs/world_simulation_lab_rerun_job.json',
    readmePath:
        '/tmp/world_simulation_lab/$environmentId/runtime_jobs/WORLD_SIMULATION_LAB_RERUN_JOB.md',
    startedAt: startedAt,
    variantId: variantId,
    variantLabel: variantLabel,
    cityPackStructuralRef: 'city_pack:sav_core_2024',
    snapshotJsonPath:
        '/tmp/world_simulation_lab/$environmentId/runtime_jobs/simulation_snapshot.json',
    learningBundleJsonPath:
        '/tmp/world_simulation_lab/$environmentId/runtime_jobs/simulation_learning_bundle.json',
    realityModelRequestJsonPath:
        '/tmp/world_simulation_lab/$environmentId/runtime_jobs/reality_model_request_previews.json',
    completedAt: completedAt,
    scenarioCount: 1,
    comparisonCount: 1,
    receiptCount: 1,
    contradictionCount: 1,
    overlayCount: 1,
    requestPreviewCount: 1,
    syntheticHumanKernelEntries: syntheticHumanKernelEntries,
    localityHierarchyNodes: localityHierarchyNodes,
    higherAgentHandoffItems: higherAgentHandoffItems,
    realismProvenance: realismProvenance,
  );
}
