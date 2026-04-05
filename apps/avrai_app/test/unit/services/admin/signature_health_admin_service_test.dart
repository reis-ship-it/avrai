import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/kernel_graph/kernel_graph_run_ledger.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_storage_service.dart';

class MockRemoteSourceHealthService extends Mock
    implements RemoteSourceHealthService {}

class MockReplaySimulationAdminService extends Mock
    implements ReplaySimulationAdminService {}

void main() {
  group('SignatureHealthAdminService', () {
    late UniversalIntakeRepository repository;

    setUp(() {
      repository = UniversalIntakeRepository();
    });

    test('maps sources into health categories and review queue counts',
        () async {
      final service = SignatureHealthAdminService(intakeRepository: repository);

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'source-strong',
          ownerUserId: 'owner-1',
          sourceProvider: 'eventbrite',
          sourceLabel: 'Strong Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'event',
            'signatureConfidence': 0.91,
            'signatureFreshness': 0.84,
            'signatureSummary': 'Healthy source.',
          },
        ),
      );
      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'source-review',
          ownerUserId: 'owner-1',
          sourceProvider: 'facebook',
          sourceLabel: 'Review Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.needsReview,
          metadata: const <String, dynamic>{
            'entityType': 'community',
            'signatureConfidence': 0.48,
            'signatureFreshness': 0.32,
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-1',
          sourceId: 'source-review',
          ownerUserId: 'owner-1',
          targetType: IntakeEntityType.community,
          title: 'Review needed',
          summary: 'Missing fields',
          missingFields: const <String>['description'],
          createdAt: DateTime(2026, 3, 1),
          payload: const <String, dynamic>{},
        ),
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.overview.strongCount, 1);
      expect(snapshot.overview.reviewNeededCount, 1);
      expect(snapshot.reviewQueueCount, 1);
      expect(snapshot.reviewItems, hasLength(1));
      expect(
        snapshot.records
            .firstWhere((record) => record.sourceId == 'source-review')
            .healthCategory,
        SignatureHealthCategory.reviewNeeded,
      );
    });

    test('surfaces simulation-training intake review metadata in snapshot',
        () async {
      final service = SignatureHealthAdminService(intakeRepository: repository);

      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-sim-1',
          sourceId: 'simulation_training_source_atx',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title: 'Deeper training intake review for atx-replay-world-2024',
          summary:
              'Strong simulation candidate is queued for governed deeper-training intake review.',
          missingFields: const <String>[],
          createdAt: DateTime(2026, 3, 31, 12),
          payload: const <String, dynamic>{
            'environmentId': 'atx-replay-world-2024',
            'status': 'queued_for_deeper_training_intake_review',
            'suggestedTrainingUse': 'candidate_deeper_reality_model_training',
            'intakeFlowRefs': <String>['source_intake_orchestrator'],
            'sidecarRefs': <String>['city_packs/atx/2024_manifest.json'],
            'trainingManifestJsonPath':
                '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
          },
        ),
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.reviewItems, hasLength(1));
      expect(snapshot.reviewItems.single.isSimulationTrainingIntake, isTrue);
      expect(
          snapshot.reviewItems.single.environmentId, 'atx-replay-world-2024');
      expect(
        snapshot.reviewItems.single.trainingManifestJsonPath,
        '/tmp/AVRAI/simulation_learning_bundles/atx/simulation_training_candidate_manifest.json',
      );
    });

    test('surfaces upward learning review metadata in snapshot', () async {
      final service = SignatureHealthAdminService(intakeRepository: repository);

      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-up-1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          targetType: IntakeEntityType.review,
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
            'temporalLineage': <String, dynamic>{
              'originOccurredAt': '2026-04-02T20:55:00.000Z',
              'reviewQueuedAt': '2026-04-02T21:00:00.000Z',
              'kernelExchangePhase': 'queued_upward_learning_review',
            },
          },
        ),
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.reviewItems, hasLength(1));
      expect(snapshot.reviewItems.single.isUpwardLearningReview, isTrue);
      expect(
        snapshot.reviewItems.single.convictionTier,
        'personal_agent_human_observation',
      );
      expect(
        snapshot.reviewItems.single.hierarchyPath,
        <String>['human', 'personal_agent', 'reality_model_agent'],
      );
      expect(
        snapshot.reviewItems.single.temporalLineage?.kernelExchangePhase,
        'queued_upward_learning_review',
      );
    });

    test('surfaces chat observation summaries on upward learning handoffs',
        () async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        userGovernedLearningChatObservationService: observationService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Personal-agent upward intake',
          createdAt: DateTime.utc(2026, 4, 2, 21),
          updatedAt: DateTime.utc(2026, 4, 2, 21, 5),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'review',
            'sourceKind': 'personal_agent_human_intake',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'convictionTier': 'personal_agent_human_observation',
            'governedLearningEnvelopeId':
                'gle:upward_learning_source_user_123_msg_1',
            'upwardHierarchySynthesisPlanJsonPath':
                '/tmp/AVRAI/upward_learning_bundles/user_123/upward_hierarchy_synthesis_plan.json',
            'safeSummary':
                'A governed personal-agent human intake item is staged for hierarchy synthesis.',
          },
        ),
      );

      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'obs-1',
          ownerUserId: 'user_123',
          envelopeId: 'gle:upward_learning_source_user_123_msg_1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 1),
          chatId: 'chat-1',
          userMessageId: 'user-msg-1',
        ),
        GovernedLearningChatObservationReceipt(
          id: 'obs-2',
          ownerUserId: 'user_123',
          envelopeId: 'gle:upward_learning_source_user_123_msg_1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.requestedFollowUp,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 3),
          chatId: 'chat-1',
          userMessageId: 'user-msg-2',
          focus: 'trail',
          userQuestion: 'Show me what this came from.',
          validationStatus: GovernedLearningChatObservationValidationStatus
              .validatedBySurfacedAdoption,
          governanceStatus: GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance,
          governanceStage: 'reality_model_truth_review',
          governanceReason:
              'Promoted after corroborating evidence held up in truth review.',
        ),
      ]);

      final snapshot = await service.getSnapshot();

      final item = snapshot.upwardLearningItems.single;
      expect(item.chatObservationSummary, isNotNull);
      expect(item.chatObservationSummary!.totalCount, 2);
      expect(item.chatObservationSummary!.acknowledgedCount, 1);
      expect(item.chatObservationSummary!.requestedFollowUpCount, 1);
      expect(
        item.chatObservationSummary!.latestOutcome,
        GovernedLearningChatObservationOutcome.requestedFollowUp,
      );
      expect(
        item.chatObservationSummary!.latestValidationStatus,
        GovernedLearningChatObservationValidationStatus
            .validatedBySurfacedAdoption,
      );
      expect(
        item.chatObservationSummary!.latestGovernanceStatus,
        GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance,
      );
      expect(
        item.chatObservationSummary!.latestGovernanceStage,
        'reality_model_truth_review',
      );
    });

    test('prioritizes upward handoffs with stronger chat follow-up pressure',
        () async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        userGovernedLearningChatObservationService: observationService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_low_pressure',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Low pressure upward intake',
          createdAt: DateTime.utc(2026, 4, 2, 20),
          updatedAt: DateTime.utc(2026, 4, 2, 22),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'review',
            'sourceKind': 'personal_agent_human_intake',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'convictionTier': 'personal_agent_human_observation',
            'governedLearningEnvelopeId': 'gle:low_pressure',
            'upwardHierarchySynthesisPlanJsonPath':
                '/tmp/AVRAI/upward_learning_bundles/user_123/low_pressure_plan.json',
            'safeSummary': 'Lower-pressure upward learning handoff.',
          },
        ),
      );
      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_high_pressure',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'High pressure upward intake',
          createdAt: DateTime.utc(2026, 4, 2, 19),
          updatedAt: DateTime.utc(2026, 4, 2, 21),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'review',
            'sourceKind': 'personal_agent_human_intake',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'convictionTier': 'personal_agent_human_observation',
            'governedLearningEnvelopeId': 'gle:high_pressure',
            'upwardHierarchySynthesisPlanJsonPath':
                '/tmp/AVRAI/upward_learning_bundles/user_123/high_pressure_plan.json',
            'safeSummary': 'Higher-pressure upward learning handoff.',
          },
        ),
      );

      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'low-ack',
          ownerUserId: 'user_123',
          envelopeId: 'gle:low_pressure',
          sourceId: 'upward_learning_source_low_pressure',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 22, 5),
          chatId: 'chat-low',
          userMessageId: 'msg-low',
        ),
        GovernedLearningChatObservationReceipt(
          id: 'high-follow-up',
          ownerUserId: 'user_123',
          envelopeId: 'gle:high_pressure',
          sourceId: 'upward_learning_source_high_pressure',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.requestedFollowUp,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 5),
          chatId: 'chat-high',
          userMessageId: 'msg-high',
        ),
      ]);

      final snapshot = await service.getSnapshot();

      expect(snapshot.upwardLearningItems, hasLength(2));
      expect(
        snapshot.upwardLearningItems.first.sourceId,
        'upward_learning_source_high_pressure',
      );
      expect(snapshot.upwardLearningItems.first.needsChatAttention, isTrue);
      expect(
        snapshot.upwardLearningItems.first.chatAttentionScore,
        greaterThan(snapshot.upwardLearningItems.last.chatAttentionScore),
      );
    });

    test('governance satisfies open follow-up pressure on upward handoffs',
        () async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_upward_attention_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        userGovernedLearningChatObservationService: observationService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_user_123_msg_pressure',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Personal-agent upward intake',
          createdAt: DateTime.utc(2026, 4, 2, 21),
          updatedAt: DateTime.utc(2026, 4, 2, 21),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'entityType': 'review',
            'bundleRoot': bundleDir.path,
            'sourceKind': 'personal_agent_human_intake',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'convictionTier': 'personal_agent_human_observation',
            'governedLearningEnvelopeId':
                'gle:upward_learning_source_user_123_msg_pressure',
            'hierarchyPath': <String>[
              'human',
              'personal_agent',
              'reality_model_agent',
            ],
            'safeSummary':
                'A governed personal-agent human intake item is ready for upward learning review.',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-up-pressure',
          sourceId: 'upward_learning_source_user_123_msg_pressure',
          ownerUserId: 'user_123',
          targetType: IntakeEntityType.review,
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
          },
        ),
      );
      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'pressure_obs_1',
          ownerUserId: 'user_123',
          envelopeId: 'gle:upward_learning_source_user_123_msg_pressure',
          sourceId: 'upward_learning_source_user_123_msg_pressure',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.requestedFollowUp,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 1),
          chatId: 'chat_upward_pressure',
          userMessageId: 'user_msg_upward_pressure',
        ),
      ]);

      await service.resolveReviewItem(
        reviewItemId: 'review-up-pressure',
        resolution: SignatureHealthReviewResolution.approved,
      );

      final snapshot = await service.getSnapshot();
      final item = snapshot.upwardLearningItems.single;
      expect(item.chatObservationSummary, isNotNull);
      expect(item.chatObservationSummary!.requestedFollowUpCount, 1);
      expect(item.chatObservationSummary!.openRequestedFollowUpCount, 0);
      expect(
        item.chatObservationSummary!.latestAttentionStatus,
        GovernedLearningChatObservationAttentionStatus
            .satisfiedByGovernance,
      );
      expect(
        item.chatObservationSummary!.latestAttentionDispositionSummary,
        contains('attention satisfied when upward learning review approved the governed-learning path'),
      );
      expect(item.needsChatAttention, isFalse);

      final receipt = (await observationService.listReceiptsForUser(
        ownerUserId: 'user_123',
      ))
          .firstWhere((entry) => entry.id == 'pressure_obs_1');
      expect(
        receipt.attentionStatus,
        GovernedLearningChatObservationAttentionStatus
            .satisfiedByGovernance,
      );
    });

    test('surfaces recent KernelGraph learning-intake runs in snapshot',
        () async {
      final kernelGraphRunLedger = KernelGraphRunLedger();
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        kernelGraphRunLedger: kernelGraphRunLedger,
      );

      await kernelGraphRunLedger.recordRun(
        KernelGraphRunRecord(
          runId: 'kernel-graph-run-1',
          specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
          graphTitle: 'Upward learning review: personal-agent human intake',
          kind: KernelGraphKind.learningIntake,
          status: KernelGraphRunStatus.completed,
          startedAt: DateTime.utc(2026, 4, 3, 2, 0),
          completedAt: DateTime.utc(2026, 4, 3, 2, 0, 3),
          sourceId: 'upward_learning_source_user_123_msg_1',
          reviewItemId: 'upward_learning_source_user_123_msg_1:review',
          jobId: 'upward_learning_source_user_123_msg_1:job',
          sourceKind: 'personal_agent_human_intake',
          spec: KernelGraphSpec(
            id: 'kernel_graph:upward_learning_source_user_123_msg_1',
            title: 'Upward learning review: personal-agent human intake',
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
            nodes: const <KernelGraphNodeSpec>[
              KernelGraphNodeSpec(
                id: 'persist_source_descriptor',
                primitiveId: 'intake.upsert_source_descriptor',
                label: 'Persist source descriptor',
              ),
              KernelGraphNodeSpec(
                id: 'persist_sync_job',
                primitiveId: 'intake.upsert_sync_job',
                label: 'Persist sync job',
              ),
              KernelGraphNodeSpec(
                id: 'queue_review_item',
                primitiveId: 'intake.upsert_review_item',
                label: 'Queue review item',
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
            title: 'Upward learning review: personal-agent human intake',
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
            graphTitle: 'Upward learning review: personal-agent human intake',
            kind: KernelGraphKind.learningIntake,
            status: KernelGraphRunStatus.completed,
            summary: 'Completed 3 of 3 nodes.',
            requiresHumanReview: true,
            completedNodeCount: 3,
            totalNodeCount: 3,
          ),
          receipt: KernelGraphExecutionReceipt(
            runId: 'kernel-graph-run-1',
            specId: 'kernel_graph:upward_learning_source_user_123_msg_1',
            title: 'Upward learning review: personal-agent human intake',
            kind: KernelGraphKind.learningIntake,
            status: KernelGraphRunStatus.completed,
            startedAt: DateTime.utc(2026, 4, 3, 2, 0),
            completedAt: DateTime.utc(2026, 4, 3, 2, 0, 3),
          ),
          metadata: <String, dynamic>{
            'learningPathway': 'governed_upward_reality_model_learning',
          },
        ),
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.overview.kernelGraphRecentCount, 1);
      expect(snapshot.overview.kernelGraphFailedCount, 0);
      expect(snapshot.overview.kernelGraphHumanReviewCount, 1);
      expect(snapshot.kernelGraphRuns, hasLength(1));
      expect(
        snapshot.kernelGraphRuns.single.graphTitle,
        'Upward learning review: personal-agent human intake',
      );
      expect(
        snapshot.kernelGraphRuns.single.adminDigest.completedNodeCount,
        3,
      );
      final storedRun = await service.getKernelGraphRun('kernel-graph-run-1');
      expect(storedRun?.runId, 'kernel-graph-run-1');
      expect(storedRun?.spec?.nodes, hasLength(3));
      expect(storedRun?.compiledPlan?.steps, hasLength(3));
    });

    test('resolves queued simulation-training intake reviews locally',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_training_exec_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'simulation_training_source_atx',
          ownerUserId: 'admin_operator',
          sourceProvider: 'replay_simulation_training_candidate',
          sourceLabel: 'ATX simulation candidate',
          createdAt: DateTime(2026, 3, 31, 12),
          updatedAt: DateTime(2026, 3, 31, 12),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'entityType': 'review',
            'bundleRoot': bundleDir.path,
            'trainingManifestJsonPath':
                '${bundleDir.path}/simulation_training_candidate_manifest.json',
            'shareReviewJsonPath':
                '${bundleDir.path}/reality_model_share_review.json',
          },
        ),
      );
      final shareReviewFile = File(
        '${bundleDir.path}/reality_model_share_review.json',
      );
      await shareReviewFile.writeAsString(
        '''
{
  "environmentId": "atx-replay-world-2024",
  "requestCount": 5,
  "recommendationCount": 4,
  "outcomes": [
    {
      "request": {
        "requestId": "review-1",
        "domain": "locality",
        "candidateRef": "locality:atx_downtown",
        "localityCode": "atx_downtown"
      },
      "evaluation": {
        "evaluationId": "review-1:evaluation",
        "confidence": 0.84
      }
    },
    {
      "request": {
        "requestId": "review-2",
        "domain": "place",
        "candidateRef": "place:atx_downtown_anchor",
        "localityCode": "atx_downtown"
      },
      "evaluation": {
        "evaluationId": "review-2:evaluation",
        "confidence": 0.79
      }
    },
    {
      "request": {
        "requestId": "review-3",
        "domain": "community",
        "candidateRef": "community:atx_coordination_mesh",
        "localityCode": "atx_downtown"
      },
      "evaluation": {
        "evaluationId": "review-3:evaluation",
        "confidence": 0.77
      }
    },
    {
      "request": {
        "requestId": "review-4",
        "domain": "business",
        "candidateRef": "business:atx_economic_corridor",
        "localityCode": "atx_downtown"
      },
      "evaluation": {
        "evaluationId": "review-4:evaluation",
        "confidence": 0.75
      }
    },
    {
      "request": {
        "requestId": "review-5",
        "domain": "list",
        "candidateRef": "list:atx_priority_watchlist",
        "localityCode": "atx_downtown"
      },
      "evaluation": {
        "evaluationId": "review-5:evaluation",
        "confidence": 0.72
      }
    }
  ]
}
''',
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-sim-1',
          sourceId: 'simulation_training_source_atx',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title: 'Deeper training intake review for atx-replay-world-2024',
          summary:
              'Strong simulation candidate is queued for governed deeper-training intake review.',
          missingFields: const <String>[],
          createdAt: DateTime(2026, 3, 31, 12),
          payload: const <String, dynamic>{
            'environmentId': 'atx-replay-world-2024',
            'status': 'queued_for_deeper_training_intake_review',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-sim-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      final reviews = await repository.getAllReviewItems();
      final source =
          await repository.getSourceById('simulation_training_source_atx');
      expect(reviews, isEmpty);
      expect(source, isNotNull);
      expect(source!.syncState, ExternalSyncState.active);
      expect(source.metadata['reviewResolution'], 'approved');
      expect(
        result.executionQueueJsonPath,
        '${bundleDir.path}/simulation_training_execution_queue.json',
      );
      expect(
        source.metadata['trainingExecutionQueueJsonPath'],
        '${bundleDir.path}/simulation_training_execution_queue.json',
      );
      expect(
        result.learningExecutionJsonPath,
        '${bundleDir.path}/reality_model_learning_execution.json',
      );
      expect(
        result.learningOutcomeJsonPath,
        '${bundleDir.path}/reality_model_learning_outcome.json',
      );
      expect(
        source.metadata['realityModelLearningExecutionJsonPath'],
        '${bundleDir.path}/reality_model_learning_execution.json',
      );
      expect(
        source.metadata['realityModelLearningOutcomeJsonPath'],
        '${bundleDir.path}/reality_model_learning_outcome.json',
      );
      expect(
        source.metadata['downstreamPropagationPlanJsonPath'],
        '${bundleDir.path}/downstream_agent_propagation_plan.json',
      );
      expect(
        File(result.learningExecutionJsonPath!).existsSync(),
        isTrue,
      );
      expect(File(result.learningOutcomeJsonPath!).existsSync(), isTrue);
      final propagationPlan = File(
        '${bundleDir.path}/downstream_agent_propagation_plan.json',
      ).readAsStringSync();
      expect(
        propagationPlan,
        contains('ready_for_governed_downstream_propagation_review'),
      );
      final learningOutcome = Map<String, dynamic>.from(
        jsonDecode(
          File('${bundleDir.path}/reality_model_learning_outcome.json')
              .readAsStringSync(),
        ) as Map,
      );
      expect(
        Map<String, dynamic>.from(learningOutcome['domainCoverage'] as Map),
        containsPair('place', 1),
      );
      expect(
        Map<String, dynamic>.from(learningOutcome['domainCoverage'] as Map),
        containsPair('community', 1),
      );
      expect(
        Map<String, dynamic>.from(learningOutcome['domainCoverage'] as Map),
        containsPair('business', 1),
      );
      expect(
        Map<String, dynamic>.from(learningOutcome['domainCoverage'] as Map),
        containsPair('list', 1),
      );
      final learningOutcomeTemporal = Map<String, dynamic>.from(
        learningOutcome['temporalLineage'] as Map,
      );
      expect(learningOutcomeTemporal['reviewQueuedAt'], isNotNull);
      expect(learningOutcomeTemporal['reviewResolvedAt'], isNotNull);
      expect(learningOutcomeTemporal['learningQueuedAt'], isNotNull);
      expect(learningOutcomeTemporal['learningIntegratedAt'], isNotNull);
      expect(
        learningOutcomeTemporal['kernelExchangePhase'],
        'reality_model_learning_outcome',
      );
      final propagationPlanPayload = Map<String, dynamic>.from(
        jsonDecode(propagationPlan) as Map,
      );
      final propagationTemporal = Map<String, dynamic>.from(
        propagationPlanPayload['temporalLineage'] as Map,
      );
      expect(propagationTemporal['propagationPreparedAt'], isNotNull);
      expect(propagationTemporal['learningIntegratedAt'], isNotNull);
      final proposedTargets = List<Map<String, dynamic>>.from(
        (propagationPlanPayload['proposedTargets'] as List)
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry)),
      );
      final targetIds = proposedTargets
          .map((entry) => entry['targetId']?.toString() ?? '')
          .toSet();
      expect(targetIds, contains('hierarchy:place'));
      expect(targetIds, contains('personal_agent:place'));
      expect(targetIds, contains('hierarchy:community'));
      expect(targetIds, contains('personal_agent:community'));
      expect(targetIds, contains('hierarchy:business'));
      expect(targetIds, contains('personal_agent:business'));
      expect(targetIds, contains('hierarchy:list'));
      expect(targetIds, contains('personal_agent:list'));
      expect(
        Map<String, dynamic>.from(proposedTargets.first['temporalLineage']
            as Map)['kernelExchangePhase'],
        contains('target'),
      );
      final postLearningSnapshot = await service.getSnapshot();
      expect(
        postLearningSnapshot.learningOutcomeItems.single.temporalLineage,
        isNotNull,
      );
      expect(
        postLearningSnapshot
            .learningOutcomeItems.single.temporalLineage!.learningIntegratedAt,
        isNotNull,
      );
    });

    test(
        'resolves accepted upward learning reviews into local executed artifacts',
        () async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_upward_handoff_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        userGovernedLearningChatObservationService: observationService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Personal-agent upward intake',
          createdAt: DateTime.utc(2026, 4, 2, 21),
          updatedAt: DateTime.utc(2026, 4, 2, 21),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'entityType': 'review',
            'bundleRoot': bundleDir.path,
            'sourceKind': 'personal_agent_human_intake',
            'learningDirection': 'upward_personal_agent_to_reality_model',
            'learningPathway': 'governed_upward_reality_model_learning',
            'convictionTier': 'personal_agent_human_observation',
            'governedLearningEnvelopeId':
                'gle:upward_learning_source_user_123_msg_1',
            'hierarchyPath': <String>[
              'human',
              'personal_agent',
              'reality_model_agent',
            ],
            'safeSummary':
                'A governed personal-agent human intake item is ready for upward learning review.',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-up-1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          targetType: IntakeEntityType.review,
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
          },
        ),
      );
      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'upward_obs_1',
          ownerUserId: 'user_123',
          envelopeId: 'gle:upward_learning_source_user_123_msg_1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 1),
          chatId: 'chat_upward_1',
          userMessageId: 'user_msg_upward_1',
        ),
      ]);

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-up-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.hierarchySynthesisPlanJsonPath, isNotNull);
      expect(result.hierarchySynthesisOutcomeJsonPath, isNotNull);
      expect(result.realityModelAgentHandoffJsonPath, isNotNull);
      expect(result.realityModelAgentOutcomeJsonPath, isNotNull);
      expect(result.realityModelTruthReviewJsonPath, isNotNull);
      expect(File(result.hierarchySynthesisPlanJsonPath!).existsSync(), isTrue);
      expect(
        File(result.hierarchySynthesisOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
          File(result.realityModelAgentHandoffJsonPath!).existsSync(), isTrue);
      expect(
        File(result.realityModelAgentOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.realityModelTruthReviewJsonPath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'upward_learning_source_user_123_msg_1',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['upwardHierarchySynthesisPlanJsonPath'],
        result.hierarchySynthesisPlanJsonPath,
      );
      expect(
        source.metadata['upwardHierarchySynthesisOutcomeJsonPath'],
        result.hierarchySynthesisOutcomeJsonPath,
      );
      expect(
        source.metadata['realityModelAgentHandoffJsonPath'],
        result.realityModelAgentHandoffJsonPath,
      );
      expect(
        source.metadata['realityModelAgentOutcomeJsonPath'],
        result.realityModelAgentOutcomeJsonPath,
      );
      expect(
        source.metadata['realityModelTruthReviewJsonPath'],
        result.realityModelTruthReviewJsonPath,
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot.upwardLearningItems, hasLength(1));
      expect(
        snapshot.upwardLearningItems.single.learningDirection,
        'upward_personal_agent_to_reality_model',
      );
      expect(
        snapshot.upwardLearningItems.single.hierarchyPath,
        <String>['human', 'personal_agent', 'reality_model_agent'],
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelAgentHandoffJsonPath,
        result.realityModelAgentHandoffJsonPath,
      );
      expect(
        snapshot.upwardLearningItems.single.hierarchySynthesisOutcomeJsonPath,
        result.hierarchySynthesisOutcomeJsonPath,
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelAgentOutcomeJsonPath,
        result.realityModelAgentOutcomeJsonPath,
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelTruthReviewJsonPath,
        result.realityModelTruthReviewJsonPath,
      );
      expect(
        snapshot.upwardLearningItems.single.status,
        'ready_for_governed_truth_conviction_review',
      );
      expect(
        snapshot.upwardLearningItems.single.truthIntegrationStatus,
        'needs_governed_truth_validation_against_real_world',
      );
      final observationReceipts = await observationService.listReceiptsForUser(
        ownerUserId: 'user_123',
      );
      expect(observationReceipts, isNotEmpty);
      final governedReceipt = observationReceipts.firstWhere(
        (receipt) => receipt.id == 'upward_obs_1',
      );
      expect(
        governedReceipt.governanceStatus,
        GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance,
      );
      expect(
        governedReceipt.attentionStatus,
        GovernedLearningChatObservationAttentionStatus.pending,
      );
      expect(
        governedReceipt.governanceStage,
        'upward_learning_review',
      );
    });

    test(
        'resolves family restage intake reviews into bounded intake outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_restage_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_intake_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_restage_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage intake review',
          createdAt: DateTime.utc(2026, 4, 4, 11),
          updatedAt: DateTime.utc(2026, 4, 4, 11),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations is repeatedly degrading and needs bounded restage intake review.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-restage-1',
          sourceId: 'family_restage_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title: 'Family restage intake review for Savannah app observations',
          summary:
              'App-observation family inputs need a bounded intake follow-up.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 4, 11, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_intake_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations is repeatedly degrading and needs bounded restage intake review.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-restage-1',
        resolution: SignatureHealthReviewResolution.rejected,
      );

      expect(result.familyRestageIntakeOutcomeJsonPath, isNotNull);
      expect(result.familyRestageIntakeOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageIntakeOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageIntakeOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_restage_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageIntakeReviewStatus'],
        'held_for_more_family_restage_evidence',
      );
      expect(
        source.metadata['familyRestageIntakeReviewResolution'],
        'rejected',
      );
      expect(
        source.metadata['familyRestageIntakeOutcomeJsonPath'],
        result.familyRestageIntakeOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageIntakeOutcomeJsonPath!).readAsStringSync(),
        ) as Map,
      );
      expect(payload['status'], 'held_for_more_family_restage_evidence');
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['restageTarget'],
        'restage_input_family:app_observations',
      );
    });

    test(
        'resolves family restage follow-up reviews into bounded follow-up outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_follow_up_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_follow_up_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_follow_up_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage_follow_up',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage follow-up review',
          createdAt: DateTime.utc(2026, 4, 5, 9),
          updatedAt: DateTime.utc(2026, 4, 5, 9),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations is repeatedly degrading and now needs bounded governed follow-up review.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'intakeResolutionArtifactRef':
                '${bundleDir.path}/family_restage_intake_resolution.approved.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-follow-up-1',
          sourceId: 'family_follow_up_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title:
              'Family restage follow-up review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed follow-up review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 9, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_follow_up_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations is repeatedly degrading and now needs bounded governed follow-up review.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'intakeResolutionArtifactRef':
                'family_restage_intake_resolution.approved.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-follow-up-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageFollowUpOutcomeJsonPath, isNotNull);
      expect(result.familyRestageFollowUpOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageFollowUpOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageFollowUpOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_follow_up_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageFollowUpReviewStatus'],
        'approved_for_bounded_family_restage_resolution',
      );
      expect(
        source.metadata['familyRestageFollowUpReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageFollowUpOutcomeJsonPath'],
        result.familyRestageFollowUpOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageFollowUpOutcomeJsonPath!).readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_resolution',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['intakeResolutionArtifactRef'],
        'family_restage_intake_resolution.approved.json',
      );
    });

    test(
        'resolves family restage resolution reviews into bounded resolution outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_resolution_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_resolution_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_resolution_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage_resolution',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage resolution review',
          createdAt: DateTime.utc(2026, 4, 5, 10),
          updatedAt: DateTime.utc(2026, 4, 5, 10),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed resolution review before restage execution.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'followUpResolutionArtifactRef':
                '${bundleDir.path}/family_restage_follow_up_resolution.approved.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-resolution-1',
          sourceId: 'family_resolution_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title:
              'Family restage resolution review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed resolution review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 10, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_resolution_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed resolution review before restage execution.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'followUpResolutionArtifactRef':
                'family_restage_follow_up_resolution.approved.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-resolution-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageResolutionOutcomeJsonPath, isNotNull);
      expect(result.familyRestageResolutionOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageResolutionOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageResolutionOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_resolution_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageResolutionReviewStatus'],
        'approved_for_bounded_family_restage_execution',
      );
      expect(
        source.metadata['familyRestageResolutionReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageResolutionOutcomeJsonPath'],
        result.familyRestageResolutionOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageResolutionOutcomeJsonPath!)
              .readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_execution',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['followUpResolutionArtifactRef'],
        'family_restage_follow_up_resolution.approved.json',
      );
    });

    test(
        'resolves family restage execution reviews into bounded execution outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_execution_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_execution_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_execution_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage_execution',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage execution review',
          createdAt: DateTime.utc(2026, 4, 5, 11),
          updatedAt: DateTime.utc(2026, 4, 5, 11),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed execution review before application.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'resolutionReviewOutcomeArtifactRef':
                '${bundleDir.path}/family_restage_resolution.approved.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-execution-1',
          sourceId: 'family_execution_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title:
              'Family restage execution review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed execution review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 11, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_execution_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed execution review before application.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'resolutionReviewOutcomeArtifactRef':
                'family_restage_resolution.approved.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-execution-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageExecutionOutcomeJsonPath, isNotNull);
      expect(result.familyRestageExecutionOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageExecutionOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageExecutionOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_execution_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageExecutionReviewStatus'],
        'approved_for_bounded_family_restage_application',
      );
      expect(
        source.metadata['familyRestageExecutionReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageExecutionOutcomeJsonPath'],
        result.familyRestageExecutionOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageExecutionOutcomeJsonPath!)
              .readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_application',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['resolutionReviewOutcomeArtifactRef'],
        'family_restage_resolution.approved.json',
      );
    });

    test(
        'resolves family restage application reviews into bounded application outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_application_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_application_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_application_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage_application',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage application review',
          createdAt: DateTime.utc(2026, 4, 5, 12),
          updatedAt: DateTime.utc(2026, 4, 5, 12),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed application review before any later apply step.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'executionReviewOutcomeArtifactRef':
                '${bundleDir.path}/family_restage_execution.approved.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-application-1',
          sourceId: 'family_application_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title:
              'Family restage application review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed application review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 12, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_application_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must be restaged before the next served-basis review.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed application review before any later apply step.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'executionReviewOutcomeArtifactRef':
                'family_restage_execution.approved.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-application-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageApplicationOutcomeJsonPath, isNotNull);
      expect(result.familyRestageApplicationOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageApplicationOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageApplicationOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_application_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageApplicationReviewStatus'],
        'approved_for_bounded_family_restage_apply_to_served_basis',
      );
      expect(
        source.metadata['familyRestageApplicationReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageApplicationOutcomeJsonPath'],
        result.familyRestageApplicationOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageApplicationOutcomeJsonPath!)
              .readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_apply_to_served_basis',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['executionReviewOutcomeArtifactRef'],
        'family_restage_execution.approved.json',
      );
    });

    test(
        'resolves family restage apply reviews into bounded apply outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_apply_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_apply_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_apply_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider: 'world_simulation_lab_family_restage_apply',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage apply review',
          createdAt: DateTime.utc(2026, 4, 5, 12),
          updatedAt: DateTime.utc(2026, 4, 5, 12),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must clear bounded apply review before any later served-basis update step.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed apply review before any served-basis update lane.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'applicationReviewOutcomeArtifactRef':
                '${bundleDir.path}/family_restage_application.approved.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-apply-1',
          sourceId: 'family_apply_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title: 'Family restage apply review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed apply review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 12, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_apply_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must clear bounded apply review before any later served-basis update step.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed apply review before any served-basis update lane.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'applicationReviewOutcomeArtifactRef':
                'family_restage_application.approved.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-apply-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageApplyOutcomeJsonPath, isNotNull);
      expect(result.familyRestageApplyOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageApplyOutcomeJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageApplyOutcomeReadmePath!).existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_apply_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageApplyReviewStatus'],
        'approved_for_bounded_family_restage_served_basis_update',
      );
      expect(
        source.metadata['familyRestageApplyReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageApplyOutcomeJsonPath'],
        result.familyRestageApplyOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(result.familyRestageApplyOutcomeJsonPath!).readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_served_basis_update',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['applicationReviewOutcomeArtifactRef'],
        'family_restage_application.approved.json',
      );
    });

    test(
        'resolves family restage served-basis update reviews into bounded served-basis update outcome artifacts',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_family_served_basis_update_review_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(intakeRepository: repository);
      final queueJsonPath =
          '${bundleDir.path}/family_restage_served_basis_update_review.current.json';

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'family_served_basis_update_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          sourceProvider:
              'world_simulation_lab_family_restage_served_basis_update',
          sourceUrl: queueJsonPath,
          sourceLabel: 'Savannah family restage served-basis update review',
          createdAt: DateTime.utc(2026, 4, 5, 12),
          updatedAt: DateTime.utc(2026, 4, 5, 12),
          syncState: ExternalSyncState.needsReview,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must clear bounded served-basis update review before any later served-basis mutation step.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed served-basis update review before any served-basis mutation lane.',
            'servedBasisRef':
                '${bundleDir.path}/served_city_pack_basis.refresh.json',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'applyReviewOutcomeArtifactRef':
                '${bundleDir.path}/family_restage_apply.approved.json',
            'latestStateRefreshReceiptRef':
                '${bundleDir.path}/basis_refresh_receipts.refresh.json',
            'latestStateRevalidationReceiptRef':
                '${bundleDir.path}/basis_revalidation_receipts.revalidation.json',
            'basisRefreshLineageRef':
                '${bundleDir.path}/basis_refresh_lineage.current.json',
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-family-served-basis-update-1',
          sourceId: 'family_served_basis_update_source_sav_app_observations',
          ownerUserId: 'admin_operator',
          targetType: IntakeEntityType.review,
          title:
              'Family restage served-basis update review for Savannah app observations',
          summary:
              'App-observation family inputs need bounded governed served-basis update review.',
          missingFields: const <String>[],
          createdAt: DateTime.utc(2026, 4, 5, 12, 5),
          payload: const <String, dynamic>{
            'status': 'queued_for_family_restage_served_basis_update_review',
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': 'app_observations',
            'restageTarget': 'restage_input_family:app_observations',
            'restageTargetSummary':
                'app observations must clear bounded served-basis update review before any later served-basis mutation step.',
            'policyAction': 'force_restaged_family_inputs',
            'policyActionSummary':
                'app observations now needs bounded governed served-basis update review before any served-basis mutation lane.',
            'servedBasisRef': 'served_basis_ref',
            'cityPackStructuralRef': 'city_pack:sav_core_2024',
            'applyReviewOutcomeArtifactRef':
                'family_restage_apply.approved.json',
            'latestStateRefreshReceiptRef':
                'basis_refresh_receipts.refresh.json',
            'latestStateRevalidationReceiptRef':
                'basis_revalidation_receipts.revalidation.json',
            'basisRefreshLineageRef': 'basis_refresh_lineage.current.json',
          },
        ),
      );

      final result = await service.resolveReviewItem(
        reviewItemId: 'review-family-served-basis-update-1',
        resolution: SignatureHealthReviewResolution.approved,
      );

      expect(result.familyRestageServedBasisUpdateOutcomeJsonPath, isNotNull);
      expect(result.familyRestageServedBasisUpdateOutcomeReadmePath, isNotNull);
      expect(
        File(result.familyRestageServedBasisUpdateOutcomeJsonPath!)
            .existsSync(),
        isTrue,
      );
      expect(
        File(result.familyRestageServedBasisUpdateOutcomeReadmePath!)
            .existsSync(),
        isTrue,
      );
      expect(await repository.getAllReviewItems(), isEmpty);

      final source = await repository.getSourceById(
        'family_served_basis_update_source_sav_app_observations',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['familyRestageServedBasisUpdateReviewStatus'],
        'approved_for_bounded_family_restage_served_basis_mutation',
      );
      expect(
        source.metadata['familyRestageServedBasisUpdateReviewResolution'],
        'approved',
      );
      expect(
        source.metadata['familyRestageServedBasisUpdateOutcomeJsonPath'],
        result.familyRestageServedBasisUpdateOutcomeJsonPath,
      );

      final payload = Map<String, dynamic>.from(
        jsonDecode(
          File(
            result.familyRestageServedBasisUpdateOutcomeJsonPath!,
          ).readAsStringSync(),
        ) as Map,
      );
      expect(
        payload['status'],
        'approved_for_bounded_family_restage_served_basis_mutation',
      );
      expect(payload['evidenceFamily'], 'app_observations');
      expect(
        payload['applyReviewOutcomeArtifactRef'],
        'family_restage_apply.approved.json',
      );
    });

    test('promotes truth review into a bounded reality-model update candidate',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_truth_review_',
      );
      final repository = UniversalIntakeRepository();
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        userGovernedLearningChatObservationService: observationService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Personal-agent human intake',
          createdAt: DateTime.utc(2026, 4, 2, 20, 55),
          updatedAt: DateTime.utc(2026, 4, 2, 21, 10),
          syncState: ExternalSyncState.active,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'governedLearningEnvelopeId':
                'gle:upward_learning_source_user_123_msg_1',
            'realityModelTruthReviewJsonPath':
                '${bundleDir.path}/reality_model_truth_review.json',
            'realityModelTruthReviewReadmePath':
                '${bundleDir.path}/REALITY_MODEL_TRUTH_REVIEW_README.md',
          },
        ),
      );
      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'truth_obs_1',
          ownerUserId: 'user_123',
          envelopeId: 'gle:upward_learning_source_user_123_msg_1',
          sourceId: 'upward_learning_source_user_123_msg_1',
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 2, 21, 11),
          chatId: 'chat_truth_1',
          userMessageId: 'user_msg_truth_1',
        ),
      ]);
      await File('${bundleDir.path}/reality_model_truth_review.json')
          .writeAsString(
        '''
{
  "sourceId": "upward_learning_source_user_123_msg_1",
  "status": "ready_for_governed_truth_conviction_review",
  "sourceKind": "personal_agent_human_intake",
  "learningDirection": "upward_personal_agent_to_reality_model",
  "learningPathway": "governed_upward_reality_model_learning",
  "convictionTier": "personal_agent_human_observation",
  "environmentId": "unknown_environment",
  "cityCode": "unknown",
  "hierarchyPath": ["human", "personal_agent", "reality_model_agent"],
  "safeSummary": "A strong personal conviction is ready for broader truth review.",
  "summary": "A governed truth/conviction review is now ready from the local reality-model-agent outcome.",
  "truthIntegrationStatus": "ready_for_governed_truth_conviction_review",
  "convictionAction": "candidate_for_local_truth_validation_and_conviction_escalation"
}
''',
      );

      final result = await service.resolveTruthReview(
        sourceId: 'upward_learning_source_user_123_msg_1',
        resolution:
            SignatureHealthTruthReviewResolution.promoteToUpdateCandidate,
      );

      expect(result.realityModelUpdateCandidateJsonPath, isNotNull);
      expect(
        File(result.realityModelUpdateCandidateJsonPath!).existsSync(),
        isTrue,
      );

      final source = await repository.getSourceById(
        'upward_learning_source_user_123_msg_1',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['realityModelTruthReviewResolution'],
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate.name,
      );
      expect(
        source.metadata['realityModelUpdateCandidateJsonPath'],
        result.realityModelUpdateCandidateJsonPath,
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot.upwardLearningItems, hasLength(1));
      expect(
        snapshot.upwardLearningItems.single.truthReviewResolution,
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate.name,
      );
      expect(
        snapshot.upwardLearningItems.single.truthIntegrationStatus,
        'candidate_for_bounded_reality_model_update',
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelUpdateCandidateJsonPath,
        result.realityModelUpdateCandidateJsonPath,
      );
      final observationReceipts = await observationService.listReceiptsForUser(
        ownerUserId: 'user_123',
      );
      expect(observationReceipts, isNotEmpty);
      final governedReceipt = observationReceipts.firstWhere(
        (receipt) => receipt.id == 'truth_obs_1',
      );
      expect(
        governedReceipt.governanceStatus,
        GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance,
      );
      expect(
        governedReceipt.attentionStatus,
        GovernedLearningChatObservationAttentionStatus.pending,
      );
      expect(
        governedReceipt.governanceStage,
        'reality_model_truth_review',
      );
    });

    test(
        'approves a bounded reality-model update candidate into a local update outcome',
        () async {
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_update_candidate_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final repository = UniversalIntakeRepository();
      final upwardRepository = UniversalIntakeRepository();
      final governedUpwardLearningIntakeService =
          GovernedUpwardLearningIntakeService(
        intakeRepository: upwardRepository,
        atomicClockService: AtomicClockService(),
      );
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        governedUpwardLearningIntakeService:
            governedUpwardLearningIntakeService,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'upward_learning_source_user_123_msg_1',
          ownerUserId: 'user_123',
          sourceProvider: 'personal_agent_human_intake',
          sourceLabel: 'Personal-agent human intake',
          cityCode: 'atx',
          localityCode: 'atx_downtown',
          createdAt: DateTime.utc(2026, 4, 2, 20, 55),
          updatedAt: DateTime.utc(2026, 4, 2, 21, 20),
          syncState: ExternalSyncState.active,
          metadata: <String, dynamic>{
            'bundleRoot': bundleDir.path,
            'safeSummary':
                'A strong real-world conviction is ready for bounded update review.',
            'upwardDomainHints': <String>['business', 'venue', 'list'],
            'realityModelUpdateCandidateJsonPath':
                '${bundleDir.path}/reality_model_update_candidate.json',
          },
        ),
      );
      await File('${bundleDir.path}/reality_model_update_candidate.json')
          .writeAsString(
        '''
{
  "sourceId": "upward_learning_source_user_123_msg_1",
  "status": "queued_for_governed_reality_model_update_review",
  "sourceKind": "personal_agent_human_intake",
  "learningDirection": "upward_personal_agent_to_reality_model",
  "learningPathway": "governed_upward_reality_model_learning",
  "convictionTier": "personal_agent_human_observation",
  "environmentId": "unknown_environment",
  "cityCode": "unknown",
  "hierarchyPath": ["human", "personal_agent", "reality_model_agent"],
  "safeSummary": "A strong personal conviction is ready for bounded reality-model update review.",
  "summary": "A bounded reality-model update candidate was promoted from a governed truth/conviction review.",
  "truthReviewJsonPath": "${bundleDir.path}/reality_model_truth_review.json",
  "updateScope": "bounded_reality_model_review_candidate",
  "truthIntegrationStatus": "candidate_for_bounded_reality_model_update"
}
''',
      );

      final result = await service.resolveRealityModelUpdateCandidate(
        sourceId: 'upward_learning_source_user_123_msg_1',
        resolution:
            SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate,
      );

      expect(result.realityModelUpdateDecisionJsonPath, isNotNull);
      expect(result.realityModelUpdateOutcomeJsonPath, isNotNull);
      expect(
        File('${bundleDir.path}/reality_model_update_admin_brief.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/reality_model_update_supervisor_brief.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          '${bundleDir.path}/reality_model_update_validation_simulation_suggestion.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(result.realityModelUpdateDecisionJsonPath!).existsSync(),
        isTrue,
      );
      expect(
        File(result.realityModelUpdateOutcomeJsonPath!).existsSync(),
        isTrue,
      );

      final source = await repository.getSourceById(
        'upward_learning_source_user_123_msg_1',
      );
      expect(source, isNotNull);
      expect(
        source!.metadata['realityModelUpdateCandidateResolution'],
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate.name,
      );
      expect(
        source.metadata['realityModelUpdateDecisionJsonPath'],
        result.realityModelUpdateDecisionJsonPath,
      );
      expect(
        source.metadata['realityModelUpdateOutcomeJsonPath'],
        result.realityModelUpdateOutcomeJsonPath,
      );
      expect(
        source.metadata['realityModelUpdateAdminBriefJsonPath'],
        '${bundleDir.path}/reality_model_update_admin_brief.json',
      );
      expect(
        source.metadata['realityModelUpdateSupervisorBriefJsonPath'],
        '${bundleDir.path}/reality_model_update_supervisor_brief.json',
      );
      expect(
        source.metadata['realityModelUpdateSimulationSuggestionJsonPath'],
        '${bundleDir.path}/reality_model_update_validation_simulation_suggestion.json',
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot.upwardLearningItems, hasLength(1));
      expect(
        snapshot.upwardLearningItems.single.updateCandidateResolution,
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate.name,
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelUpdateDecisionJsonPath,
        result.realityModelUpdateDecisionJsonPath,
      );
      expect(
        snapshot.upwardLearningItems.single.realityModelUpdateOutcomeJsonPath,
        result.realityModelUpdateOutcomeJsonPath,
      );
      expect(
        snapshot
            .upwardLearningItems.single.realityModelUpdateAdminBriefJsonPath,
        '${bundleDir.path}/reality_model_update_admin_brief.json',
      );
      expect(
        snapshot.upwardLearningItems.single
            .realityModelUpdateSupervisorBriefJsonPath,
        '${bundleDir.path}/reality_model_update_supervisor_brief.json',
      );
      expect(
        snapshot.upwardLearningItems.single
            .realityModelUpdateSimulationSuggestionJsonPath,
        '${bundleDir.path}/reality_model_update_validation_simulation_suggestion.json',
      );
      var supervisorObservationReviews =
          await upwardRepository.getAllReviewItems();
      expect(supervisorObservationReviews, hasLength(1));
      expect(
        supervisorObservationReviews.single.payload['sourceKind'],
        'supervisor_bounded_observation_intake',
      );
      expect(
        supervisorObservationReviews.single.payload['channel'],
        'reality_model_update_supervisor_brief',
      );
      expect(
        supervisorObservationReviews.single.payload['airGapArtifact'],
        isA<Map<String, dynamic>>(),
      );
      expect(
        source.metadata['latestSupervisorObservationKind'],
        'reality_model_update_supervisor_brief',
      );

      final simulationStart =
          await service.startRealityModelUpdateValidationSimulation(
        sourceId: 'upward_learning_source_user_123_msg_1',
      );
      expect(
        simulationStart.realityModelUpdateSimulationRequestJsonPath,
        '${bundleDir.path}/reality_model_update_validation_simulation_request.json',
      );
      expect(
        File(
          simulationStart.realityModelUpdateSimulationRequestJsonPath!,
        ).existsSync(),
        isTrue,
      );

      final updatedSource = await repository.getSourceById(
        'upward_learning_source_user_123_msg_1',
      );
      expect(
        updatedSource!.metadata['realityModelUpdateSimulationRequestJsonPath'],
        '${bundleDir.path}/reality_model_update_validation_simulation_request.json',
      );

      final updatedSnapshot = await service.getSnapshot();
      expect(
        updatedSnapshot.upwardLearningItems.single
            .realityModelUpdateSimulationRequestJsonPath,
        '${bundleDir.path}/reality_model_update_validation_simulation_request.json',
      );
      expect(
        updatedSnapshot.upwardLearningItems.single
            .realityModelUpdateSimulationOutcomeJsonPath,
        '${bundleDir.path}/reality_model_update_validation_simulation_outcome.json',
      );
      expect(
        updatedSnapshot.upwardLearningItems.single
            .realityModelUpdateDownstreamRepropagationReviewJsonPath,
        '${bundleDir.path}/reality_model_update_downstream_repropagation_review.json',
      );
      supervisorObservationReviews = await upwardRepository.getAllReviewItems();
      expect(supervisorObservationReviews, hasLength(2));
      expect(
        supervisorObservationReviews
            .map((item) => item.payload['channel'])
            .contains('reality_model_update_validation_simulation_outcome'),
        isTrue,
      );

      final repropagation =
          await service.resolveRealityModelUpdateDownstreamRepropagation(
        sourceId: 'upward_learning_source_user_123_msg_1',
        resolution: SignatureHealthDownstreamRepropagationResolution.approve,
      );
      expect(
        repropagation.realityModelUpdateDownstreamRepropagationDecisionJsonPath,
        '${bundleDir.path}/reality_model_update_downstream_repropagation_decision.json',
      );
      expect(
        repropagation.realityModelUpdateDownstreamRepropagationOutcomeJsonPath,
        '${bundleDir.path}/reality_model_update_downstream_repropagation_outcome.json',
      );
      expect(
        File(
          '${bundleDir.path}/reality_model_update_downstream_repropagation_plan.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${bundleDir.path}/admin_evidence_refresh_snapshot_admin_unknown_environment.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${bundleDir.path}/supervisor_learning_feedback_state_supervisor_unknown_environment.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/hierarchy_domain_delta_hierarchy_locality.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/hierarchy_domain_delta_hierarchy_business.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/hierarchy_domain_delta_hierarchy_venue.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/hierarchy_domain_delta_hierarchy_list.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_locality.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_business.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_venue.json').existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_list.json').existsSync(),
        isTrue,
      );

      final resolvedSnapshot = await service.getSnapshot();
      expect(
        resolvedSnapshot.upwardLearningItems.single
            .realityModelUpdateDownstreamRepropagationDecisionJsonPath,
        '${bundleDir.path}/reality_model_update_downstream_repropagation_decision.json',
      );
      expect(
        resolvedSnapshot.upwardLearningItems.single
            .realityModelUpdateDownstreamRepropagationOutcomeJsonPath,
        '${bundleDir.path}/reality_model_update_downstream_repropagation_outcome.json',
      );
      expect(
        resolvedSnapshot
            .upwardLearningItems.single.downstreamRepropagationResolution,
        SignatureHealthDownstreamRepropagationResolution.approve.name,
      );
      final resolvedSource = await repository.getSourceById(
        'upward_learning_source_user_123_msg_1',
      );
      expect(
        resolvedSource!
            .metadata['realityModelUpdateDownstreamRepropagationPlanJsonPath'],
        '${bundleDir.path}/reality_model_update_downstream_repropagation_plan.json',
      );
      expect(
        resolvedSource.metadata['latestSupervisorObservationKind'],
        'reality_model_update_downstream_repropagation_gate',
      );
      supervisorObservationReviews = await upwardRepository.getAllReviewItems();
      expect(supervisorObservationReviews, hasLength(3));
      expect(
        supervisorObservationReviews
            .map((item) => item.payload['channel'])
            .contains('reality_model_update_downstream_repropagation_gate'),
        isTrue,
      );
      final supervisorObservationSources =
          await upwardRepository.getAllSources();
      expect(supervisorObservationSources, hasLength(3));
      expect(
        supervisorObservationSources
            .map((item) => item.metadata['airGapArtifact'])
            .whereType<Map<String, dynamic>>()
            .length,
        3,
      );
    });

    test('surfaces local learning outcomes and resolves propagation targets',
        () async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      final governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
      final bundleDir = await Directory.systemTemp.createTemp(
        'sig_health_learning_outcome_',
      );
      addTearDown(() async {
        if (bundleDir.existsSync()) {
          await bundleDir.delete(recursive: true);
        }
      });
      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        governedDomainConsumerStateService: governedStateService,
      );

      await File('${bundleDir.path}/reality_model_learning_outcome.json')
          .writeAsString(
        '''
{
  "environmentId": "atx-replay-world-2024",
  "cityCode": "atx",
  "status": "completed",
  "learningPathway": "deeper_reality_model_training",
  "summary": "Reality-model learning completed locally.",
  "requestCount": 3,
  "recommendationCount": 2,
  "averageConfidence": 0.84,
  "domainCoverage": {
    "locality": 1,
    "event": 2,
    "place": 1,
    "community": 1,
    "mobility": 1,
    "venue": 1,
    "business": 1,
    "list": 1
  },
  "learningDeltas": [
    "Reality-model learning can now refine `locality` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `event` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `place` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `community` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `mobility` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `venue` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `business` priors and explanations for atx-replay-world-2024 from governed simulation evidence.",
    "Reality-model learning can now refine `list` priors and explanations for atx-replay-world-2024 from governed simulation evidence."
  ]
}
''',
      );
      await File('${bundleDir.path}/downstream_agent_propagation_plan.json')
          .writeAsString(
        '''
{
  "status": "ready_for_governed_downstream_propagation_review",
  "proposedTargets": [
    {
      "targetId": "admin:atx-replay-world-2024",
      "propagationKind": "evidence_and_explanation_refresh",
      "reason": "Admin evidence is ready to refresh.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "supervisor:atx-replay-world-2024",
      "propagationKind": "learning_feedback",
      "reason": "Supervisor feedback is ready to refresh.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "hierarchy:locality",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Locality domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:locality",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent locality personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:event",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Event domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:event",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent event personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:place",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Place domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:place",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent place personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:community",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Community domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:community",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent community personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:mobility",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Mobility domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:mobility",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent mobility personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:venue",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Venue domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:venue",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent venue personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:business",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "Business domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:business",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent business personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    },
    {
      "targetId": "hierarchy:list",
      "propagationKind": "prior_and_explanation_delta",
      "reason": "List domain is ready for propagation.",
      "status": "ready_for_governed_downstream_propagation_review"
    },
    {
      "targetId": "personal_agent:list",
      "propagationKind": "personalized_guidance_delta",
      "reason": "Personal agent list personalization is waiting on hierarchy synthesis.",
      "status": "blocked_until_hierarchy_domain_delta"
    }
  ]
}
''',
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'simulation_training_source_atx',
          ownerUserId: 'admin_operator',
          sourceProvider: 'replay_simulation_training_candidate',
          sourceLabel: 'ATX simulation candidate',
          cityCode: 'atx',
          createdAt: DateTime(2026, 3, 31, 12),
          updatedAt: DateTime(2026, 3, 31, 12),
          syncState: ExternalSyncState.active,
          metadata: <String, dynamic>{
            'entityType': 'review',
            'realityModelLearningOutcomeJsonPath':
                '${bundleDir.path}/reality_model_learning_outcome.json',
            'downstreamPropagationPlanJsonPath':
                '${bundleDir.path}/downstream_agent_propagation_plan.json',
          },
        ),
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot.learningOutcomeItems, hasLength(1));
      expect(snapshot.learningOutcomeItems.single.environmentId,
          'atx-replay-world-2024');
      expect(snapshot.learningOutcomeItems.single.hasReadyTargets, isTrue);
      final initialPersonalLocality = snapshot
          .learningOutcomeItems.single.propagationTargets
          .firstWhere((target) => target.targetId == 'personal_agent:locality');
      expect(initialPersonalLocality.isReadyForReview, isFalse);

      final adminResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'admin:atx-replay-world-2024',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(adminResult.sourceId, 'simulation_training_source_atx');
      expect(adminResult.propagationReceiptJsonPath, isNotNull);
      expect(
          File(adminResult.propagationReceiptJsonPath!).existsSync(), isTrue);
      expect(
        adminResult.propagationReceiptJsonPath,
        contains('admin_evidence_refresh_receipt_admin_atx_replay_world_2024'),
      );
      expect(
        File(
          '${bundleDir.path}/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
        ).existsSync(),
        isTrue,
      );

      final supervisorResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'supervisor:atx-replay-world-2024',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(supervisorResult.propagationReceiptJsonPath, isNotNull);
      expect(
        supervisorResult.propagationReceiptJsonPath,
        contains(
          'supervisor_learning_feedback_receipt_supervisor_atx_replay_world_2024',
        ),
      );
      expect(
        File(
          '${bundleDir.path}/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
        ).existsSync(),
        isTrue,
      );
      final updatedSource =
          await repository.getSourceById('simulation_training_source_atx');
      expect(
        updatedSource!.metadata['adminEvidenceRefreshReceiptJsonPath'],
        adminResult.propagationReceiptJsonPath,
      );
      expect(
        updatedSource.metadata['supervisorLearningFeedbackReceiptJsonPath'],
        supervisorResult.propagationReceiptJsonPath,
      );
      expect(
        updatedSource.metadata['adminEvidenceRefreshSnapshotJsonPath'],
        '${bundleDir.path}/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
      );
      expect(
        updatedSource.metadata['supervisorLearningFeedbackStateJsonPath'],
        '${bundleDir.path}/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
      );

      final hierarchyResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:locality',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(hierarchyResult.propagationReceiptJsonPath, isNotNull);
      expect(
        hierarchyResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_locality'),
      );
      expect(
        File(
          '${bundleDir.path}/hierarchy_domain_delta_hierarchy_locality.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/downstream_agent_propagation_plan.json')
            .readAsStringSync(),
        contains('executed_local_governed_downstream_propagation'),
      );
      final hierarchyArtifact = File(
        '${bundleDir.path}/hierarchy_domain_delta_hierarchy_locality.json',
      ).readAsStringSync();
      expect(
          hierarchyArtifact, contains('executed_local_governed_domain_delta'));
      expect(hierarchyArtifact, contains('"domainId": "locality"'));
      final hierarchyUpdatedSource =
          await repository.getSourceById('simulation_training_source_atx');
      expect(
        hierarchyUpdatedSource!.metadata['hierarchyPropagationDeltaJsonPaths'],
        containsPair(
          'locality',
          '${bundleDir.path}/hierarchy_domain_delta_hierarchy_locality.json',
        ),
      );
      final afterHierarchySnapshot = await service.getSnapshot();
      final personalLocalityReady = afterHierarchySnapshot
          .learningOutcomeItems.single.propagationTargets
          .firstWhere((target) => target.targetId == 'personal_agent:locality');
      expect(personalLocalityReady.isReadyForReview, isTrue);
      final eventResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:event',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(eventResult.propagationReceiptJsonPath, isNotNull);
      expect(
        eventResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_event'),
      );
      expect(
        File(
          '${bundleDir.path}/hierarchy_domain_delta_hierarchy_event.json',
        ).existsSync(),
        isTrue,
      );
      final eventUpdatedSource =
          await repository.getSourceById('simulation_training_source_atx');
      expect(
        eventUpdatedSource!.metadata['hierarchyPropagationDeltaJsonPaths'],
        containsPair(
          'event',
          '${bundleDir.path}/hierarchy_domain_delta_hierarchy_event.json',
        ),
      );
      final refreshedSnapshot = await service.getSnapshot();
      final learningItem = refreshedSnapshot.learningOutcomeItems.single;
      expect(
        learningItem.adminEvidenceRefreshSnapshotJsonPath,
        '${bundleDir.path}/admin_evidence_refresh_snapshot_admin_atx_replay_world_2024.json',
      );
      expect(
        learningItem.supervisorLearningFeedbackStateJsonPath,
        '${bundleDir.path}/supervisor_learning_feedback_state_supervisor_atx_replay_world_2024.json',
      );
      final adminTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'admin:atx-replay-world-2024',
      );
      expect(adminTarget.laneArtifactJsonPath, isNotNull);
      final supervisorTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'supervisor:atx-replay-world-2024',
      );
      expect(supervisorTarget.laneArtifactJsonPath, isNotNull);
      final hierarchyTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:locality',
      );
      expect(
        hierarchyTarget.laneArtifactJsonPath,
        '${bundleDir.path}/hierarchy_domain_delta_hierarchy_locality.json',
      );
      expect(hierarchyTarget.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        hierarchyTarget.hierarchyDomainDeltaSummary!.domainId,
        'locality',
      );
      expect(
        hierarchyTarget.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        hierarchyTarget
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'locality_intelligence_lane',
      );
      expect(hierarchyTarget.temporalLineage, isNotNull);
      expect(
        hierarchyTarget.temporalLineage!.propagationResolvedAt,
        isNotNull,
      );
      expect(
        hierarchyTarget.hierarchyDomainDeltaSummary!.temporalLineage,
        isNotNull,
      );
      expect(
        hierarchyTarget.hierarchyDomainDeltaSummary!.downstreamConsumerSummary!
            .temporalLineage,
        isNotNull,
      );
      final eventTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:event',
      );
      expect(
        eventTarget.laneArtifactJsonPath,
        '${bundleDir.path}/hierarchy_domain_delta_hierarchy_event.json',
      );
      expect(eventTarget.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        eventTarget.hierarchyDomainDeltaSummary!.domainId,
        'event',
      );
      expect(
        eventTarget.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        eventTarget
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'event_intelligence_lane',
      );
      final mobilityTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:mobility',
      );
      expect(mobilityTarget.hierarchyDomainDeltaSummary, isNull);
      final venueTarget = learningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:venue',
      );
      expect(venueTarget.hierarchyDomainDeltaSummary, isNull);
      final placeResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:place',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        placeResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_place'),
      );
      final communityResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:community',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        communityResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_community'),
      );

      final personalLocalityResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'personal_agent:locality',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(personalLocalityResult.propagationReceiptJsonPath, isNotNull);
      expect(
        personalLocalityResult.propagationReceiptJsonPath,
        contains(
            'personal_agent_personalization_receipt_personal_agent_locality'),
      );
      expect(
        File(
          '${bundleDir.path}/personal_agent_personalization_delta_personal_agent_locality.json',
        ).existsSync(),
        isTrue,
      );
      final afterPersonalizationSnapshot = await service.getSnapshot();
      final personalLocalityAfter = afterPersonalizationSnapshot
          .learningOutcomeItems.single.propagationTargets
          .firstWhere(
        (target) => target.targetId == 'personal_agent:locality',
      );
      expect(
          personalLocalityAfter.personalAgentPersonalizationSummary, isNotNull);
      expect(
        personalLocalityAfter.personalAgentPersonalizationSummary!.domainId,
        'locality',
      );
      expect(
        personalLocalityAfter
            .personalAgentPersonalizationSummary!.temporalLineage,
        isNotNull,
      );

      final mobilityResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:mobility',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        mobilityResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_mobility'),
      );
      final venueResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:venue',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        venueResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_venue'),
      );
      final personalMobilityResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'personal_agent:mobility',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        personalMobilityResult.propagationReceiptJsonPath,
        contains(
          'personal_agent_personalization_receipt_personal_agent_mobility',
        ),
      );

      final finalSnapshot = await service.getSnapshot();
      final finalLearningItem = finalSnapshot.learningOutcomeItems.single;
      final mobilityAfter = finalLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:mobility',
      );
      expect(mobilityAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        mobilityAfter.hierarchyDomainDeltaSummary!.domainId,
        'mobility',
      );
      expect(
        mobilityAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        mobilityAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'mobility_guidance_lane',
      );
      final venueAfter = finalLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:venue',
      );
      expect(venueAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        venueAfter.hierarchyDomainDeltaSummary!.domainId,
        'venue',
      );
      expect(
        venueAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        venueAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'venue_intelligence_lane',
      );
      final placeAfter = finalLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:place',
      );
      expect(placeAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        placeAfter.hierarchyDomainDeltaSummary!.domainId,
        'place',
      );
      expect(
        placeAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        placeAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'place_intelligence_lane',
      );
      final communityAfter = finalLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:community',
      );
      expect(communityAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        communityAfter.hierarchyDomainDeltaSummary!.domainId,
        'community',
      );
      expect(
        communityAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        communityAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'community_coordination_lane',
      );
      final businessResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:business',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        businessResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_business'),
      );
      final listResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'hierarchy:list',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        listResult.propagationReceiptJsonPath,
        contains('hierarchy_domain_delta_receipt_hierarchy_list'),
      );
      final personalBusinessResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'personal_agent:business',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        personalBusinessResult.propagationReceiptJsonPath,
        contains(
          'personal_agent_personalization_receipt_personal_agent_business',
        ),
      );
      final personalListResult = await service.resolvePropagationTarget(
        sourceId: 'simulation_training_source_atx',
        targetId: 'personal_agent:list',
        resolution: SignatureHealthPropagationResolution.approved,
      );
      expect(
        personalListResult.propagationReceiptJsonPath,
        contains('personal_agent_personalization_receipt_personal_agent_list'),
      );

      final broadenedSnapshot = await service.getSnapshot();
      final broadenedLearningItem =
          broadenedSnapshot.learningOutcomeItems.single;
      final businessAfter = broadenedLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:business',
      );
      expect(businessAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        businessAfter.hierarchyDomainDeltaSummary!.domainId,
        'business',
      );
      expect(
        businessAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        businessAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'business_intelligence_lane',
      );
      final listAfter = broadenedLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'hierarchy:list',
      );
      expect(listAfter.hierarchyDomainDeltaSummary, isNotNull);
      expect(
        listAfter.hierarchyDomainDeltaSummary!.domainId,
        'list',
      );
      expect(
        listAfter.hierarchyDomainDeltaSummary!.downstreamConsumerSummary,
        isNotNull,
      );
      expect(
        listAfter
            .hierarchyDomainDeltaSummary!.downstreamConsumerSummary!.consumerId,
        'list_curation_lane',
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_business.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_place.json').existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_locality.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_event.json').existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_mobility.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_venue.json').existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_community.json')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${bundleDir.path}/domain_consumer_state_list.json').existsSync(),
        isTrue,
      );
      final persistedLocalityState = governedStateService.latestStateFor(
        cityCode: 'atx',
        domainId: 'locality',
      );
      expect(persistedLocalityState, isNotNull);
      expect(
        persistedLocalityState!.consumerId,
        'locality_intelligence_lane',
      );
      final persistedMobilityState = governedStateService.latestStateFor(
        cityCode: 'atx',
        domainId: 'mobility',
      );
      expect(persistedMobilityState, isNotNull);
      expect(
        persistedMobilityState!.consumerId,
        'mobility_guidance_lane',
      );
      final personalBusinessAfter =
          broadenedLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'personal_agent:business',
      );
      expect(
        personalBusinessAfter.personalAgentPersonalizationSummary,
        isNotNull,
      );
      expect(
        personalBusinessAfter.personalAgentPersonalizationSummary!.domainId,
        'business',
      );
      final personalListAfter =
          broadenedLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'personal_agent:list',
      );
      expect(
        personalListAfter.personalAgentPersonalizationSummary,
        isNotNull,
      );
      expect(
        personalListAfter.personalAgentPersonalizationSummary!.domainId,
        'list',
      );
      final personalMobilityAfter =
          finalLearningItem.propagationTargets.firstWhere(
        (target) => target.targetId == 'personal_agent:mobility',
      );
      expect(
        personalMobilityAfter.personalAgentPersonalizationSummary,
        isNotNull,
      );
      expect(
        personalMobilityAfter.personalAgentPersonalizationSummary!.domainId,
        'mobility',
      );
    });

    test('merges remote records and emits live updates when local data changes',
        () async {
      final remoteService = MockRemoteSourceHealthService();
      when(() => remoteService.fetchRows()).thenAnswer(
        (_) async => const <SignatureHealthRecord>[
          SignatureHealthRecord(
            sourceId: 'remote-source',
            provider: 'meetup',
            entityType: 'event',
            categoryLabel: 'music',
            sourceLabel: 'Remote Source',
            confidence: 0.88,
            freshness: 0.81,
            fallbackRate: 0.0,
            reviewNeeded: false,
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Remote record is healthy.',
          ),
        ],
      );
      when(() => remoteService.watchRows()).thenAnswer(
        (_) => const Stream<List<SignatureHealthRecord>>.empty(),
      );

      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        remoteSourceHealthService: remoteService,
      );

      final stream = service.watchSnapshot();
      final initial = await stream.first;
      expect(
        initial.records.any((record) => record.sourceId == 'remote-source'),
        isTrue,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'local-source',
          ownerUserId: 'owner-1',
          sourceProvider: 'manual',
          sourceLabel: 'Local Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'spot',
            'signatureConfidence': 0.79,
            'signatureFreshness': 0.62,
          },
        ),
      );

      final updated = await stream.firstWhere(
        (snapshot) =>
            snapshot.records.any((record) => record.sourceId == 'local-source'),
      );

      expect(updated.records.length, 2);
    });

    test('builds feedback trend rows by entity type and recency window',
        () async {
      final remoteService = MockRemoteSourceHealthService();
      when(() => remoteService.fetchRows()).thenAnswer(
        (_) async => <SignatureHealthRecord>[
          SignatureHealthRecord(
            sourceId: 'feedback-soft',
            provider: 'user_feedback',
            entityType: 'suggested_list',
            categoryLabel: 'soft_ignore',
            sourceLabel: 'List soft ignore',
            confidence: 0.68,
            freshness: 0.9,
            fallbackRate: 0.0,
            reviewNeeded: false,
            updatedAt: DateTime(2026, 3, 6),
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Soft ignore feedback.',
          ),
          SignatureHealthRecord(
            sourceId: 'feedback-hard',
            provider: 'user_feedback',
            entityType: 'spot',
            categoryLabel: 'hard_not_interested',
            sourceLabel: 'Spot hard reject',
            confidence: 0.72,
            freshness: 0.91,
            fallbackRate: 0.0,
            reviewNeeded: false,
            updatedAt: DateTime(2026, 3, 2),
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Hard reject feedback.',
          ),
        ],
      );
      when(() => remoteService.watchRows()).thenAnswer(
        (_) => const Stream<List<SignatureHealthRecord>>.empty(),
      );

      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        remoteSourceHealthService: remoteService,
      );

      final snapshot = await service.getSnapshot();
      final trendRows = snapshot.buildFeedbackTrendRows(
        now: DateTime(2026, 3, 6, 12),
      );

      expect(trendRows.length, 2);
      expect(
        trendRows
            .firstWhere((row) => row.entityType == 'suggested_list')
            .countsByWindow['24h']!
            .softIgnoreCount,
        1,
      );
      expect(
        trendRows
            .firstWhere((row) => row.entityType == 'spot')
            .countsByWindow['7d']!
            .hardNotInterestedCount,
        1,
      );
    });

    test('surfaces bounded review candidates from world simulation lab state',
        () async {
      final replayService = MockReplaySimulationAdminService();
      const environment = ReplaySimulationAdminEnvironmentDescriptor(
        environmentId: 'atx-replay-world-2024',
        displayName: 'Austin Simulation Environment 2024',
        cityCode: 'atx',
        replayYear: 2024,
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        sidecarRefs: <String>[
          'city_packs/atx/2024_manifest.json',
          'world_models/atx/jepa_geo_realism_v2.json',
        ],
      );
      final runtimeState = ReplaySimulationLabRuntimeState(
        environmentId: 'atx-replay-world-2024',
        updatedAt: DateTime.utc(2026, 4, 2, 8),
        targetActionDecisions: <ReplaySimulationLabTargetActionDecision>[
          ReplaySimulationLabTargetActionDecision(
            environmentId: 'atx-replay-world-2024',
            updatedAt: DateTime.utc(2026, 4, 2, 8),
            suggestedAction: 'watch_closely',
            suggestedReason:
                'Recent runs stabilized enough for bounded review.',
            selectedAction: 'candidate_for_bounded_review',
            acceptedSuggestion: false,
            alertAcknowledgedAt: DateTime.utc(2026, 4, 2, 8, 45),
            alertAcknowledgedSeverityCode: 'spiking',
            alertEscalatedAt: DateTime.utc(2026, 4, 2, 9),
            alertEscalatedSeverityCode: 'spiking',
            variantId: 'variant-heatwave-lane',
            variantLabel: 'Heatwave mitigation lane',
          ),
        ],
      );
      final latestOutcome = ReplaySimulationLabOutcomeRecord(
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        labRoot: '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1',
        snapshotJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1/simulation_snapshot.json',
        learningBundleJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1/learning_bundle.json',
        realityModelRequestJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1/reality_model_request.json',
        outcomeJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1/lab_outcome.json',
        readmePath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-1/README.md',
        recordedAt: DateTime.utc(2026, 4, 2, 7, 30),
        disposition: ReplaySimulationLabDisposition.denied,
        operatorRationale:
            'Hold for bounded review before broadening this mitigation lane.',
        operatorNotes: <String>['Need better corridor realism.'],
        trainingGrade: 'review',
        suggestedTrainingUse: 'bounded_reality_model_review',
        shareWithRealityModelAllowed: false,
        scenarioCount: 3,
        comparisonCount: 2,
        receiptCount: 1,
        contradictionCount: 1,
        overlayCount: 1,
        requestPreviewCount: 1,
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>[
          'city_packs/atx/2024_manifest.json',
          'world_models/atx/jepa_geo_realism_v2.json',
        ],
        realismProvenance: const ReplaySimulationRealismProvenanceSummary(
          simulationMode: 'generic_city_pack',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>[
            'city_packs/atx/2024_manifest.json',
            'world_models/atx/jepa_geo_realism_v2.json',
          ],
          trainingArtifactFamilies: <String>['simulation_snapshot'],
        ),
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        trainingArtifactFamilies: <String>['simulation_snapshot'],
        variantId: 'variant-heatwave-lane',
        variantLabel: 'Heatwave mitigation lane',
      );
      final previousOutcome = ReplaySimulationLabOutcomeRecord(
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        labRoot: '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0',
        snapshotJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0/simulation_snapshot.json',
        learningBundleJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0/learning_bundle.json',
        realityModelRequestJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0/reality_model_request.json',
        outcomeJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0/lab_outcome.json',
        readmePath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/outcomes/outcome-0/README.md',
        recordedAt: DateTime.utc(2026, 4, 2, 6, 45),
        disposition: ReplaySimulationLabDisposition.denied,
        operatorRationale: 'Earlier pass remained denied.',
        operatorNotes: <String>['Need better corridor realism.'],
        trainingGrade: 'review',
        suggestedTrainingUse: 'bounded_reality_model_review',
        shareWithRealityModelAllowed: false,
        scenarioCount: 3,
        comparisonCount: 2,
        receiptCount: 0,
        contradictionCount: 2,
        overlayCount: 1,
        requestPreviewCount: 0,
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>[
          'city_packs/atx/2024_manifest.json',
          'world_models/atx/jepa_geo_realism_v2.json',
        ],
        realismProvenance: const ReplaySimulationRealismProvenanceSummary(
          simulationMode: 'generic_city_pack',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
          trainingArtifactFamilies: <String>['simulation_snapshot'],
        ),
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        trainingArtifactFamilies: <String>['simulation_snapshot'],
        variantId: 'variant-heatwave-lane',
        variantLabel: 'Heatwave mitigation lane',
      );
      final latestRequest = ReplaySimulationLabRerunRequest(
        requestId: 'rerun-request-1',
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        requestedAt: DateTime.utc(2026, 4, 2, 7, 45),
        requestStatus: 'completed',
        requestRoot: '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1',
        requestJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/request.json',
        readmePath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/README.md',
        requestNotes: <String>['Run after corridor sidecar refresh.'],
        sidecarRefs: <String>[
          'city_packs/atx/2024_manifest.json',
          'world_models/atx/jepa_geo_realism_v2.json',
        ],
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        variantId: 'variant-heatwave-lane',
        variantLabel: 'Heatwave mitigation lane',
        latestJobId: 'rerun-job-1',
        latestJobJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job.json',
        latestJobStatus: 'completed',
        latestJobStartedAt: DateTime.utc(2026, 4, 2, 7, 46),
        latestJobCompletedAt: DateTime.utc(2026, 4, 2, 7, 55),
        latestJobSnapshotJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/simulation_snapshot.json',
      );
      final latestJob = ReplaySimulationLabRerunJob(
        jobId: 'rerun-job-1',
        requestId: 'rerun-request-1',
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        jobStatus: 'completed',
        jobRoot: '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job-1',
        jobJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job-1/job.json',
        readmePath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job-1/README.md',
        startedAt: DateTime.utc(2026, 4, 2, 7, 46),
        variantId: 'variant-heatwave-lane',
        variantLabel: 'Heatwave mitigation lane',
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        snapshotJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job-1/simulation_snapshot.json',
        learningBundleJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-1/job-1/learning_bundle.json',
        completedAt: DateTime.utc(2026, 4, 2, 7, 55),
        scenarioCount: 4,
        comparisonCount: 2,
        receiptCount: 0,
        contradictionCount: 4,
        overlayCount: 1,
        requestPreviewCount: 0,
        realismProvenance: const ReplaySimulationRealismProvenanceSummary(
          simulationMode: 'generic_city_pack',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>[
            'city_packs/atx/2024_manifest.json',
            'world_models/atx/jepa_geo_realism_v2.json',
          ],
          trainingArtifactFamilies: <String>[
            'simulation_snapshot',
            'replay_learning_bundle',
          ],
        ),
      );
      final previousJob = ReplaySimulationLabRerunJob(
        jobId: 'rerun-job-0',
        requestId: 'rerun-request-0',
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        replayYear: 2024,
        jobStatus: 'completed',
        jobRoot: '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-0/job-0',
        jobJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-0/job-0/job.json',
        readmePath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-0/job-0/README.md',
        startedAt: DateTime.utc(2026, 4, 2, 6, 46),
        variantId: 'variant-heatwave-lane',
        variantLabel: 'Heatwave mitigation lane',
        cityPackStructuralRef: 'city_pack:atx_core_2024',
        snapshotJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-0/job-0/simulation_snapshot.json',
        learningBundleJsonPath:
            '/tmp/AVRAI/world_sim_lab/atx/2024/reruns/request-0/job-0/learning_bundle.json',
        completedAt: DateTime.utc(2026, 4, 2, 6, 55),
        scenarioCount: 4,
        comparisonCount: 2,
        receiptCount: 1,
        contradictionCount: 2,
        overlayCount: 1,
        requestPreviewCount: 1,
        realismProvenance: const ReplaySimulationRealismProvenanceSummary(
          simulationMode: 'generic_city_pack',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
          trainingArtifactFamilies: <String>['simulation_snapshot'],
        ),
      );

      when(() => replayService.listAvailableEnvironments()).thenAnswer(
        (_) async => <ReplaySimulationAdminEnvironmentDescriptor>[environment],
      );
      when(
        () => replayService.getServedBasisState(
          environmentId: 'atx-replay-world-2024',
        ),
      ).thenAnswer(
        (_) async => ReplaySimulationLabServedBasisState(
          environmentId: 'atx-replay-world-2024',
          supportedPlaceRef: 'place:atx',
          stagedAt: DateTime.utc(2026, 4, 2, 9, 5),
          servedBasisRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
          cityPackStructuralRef: 'city_pack:atx_core_2024',
          latestStateEvidenceRefsByFamily: const <String, String>{
            'app_observations':
                'world_simulation_lab/registered_environments/atx-replay-world-2024/latest_state/app_observations.current.json',
          },
          latestStateRefreshReceiptRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_refresh_receipts.refresh.json',
          latestStateDecisionStatus: 'promoted',
          latestStateRevalidationStatus: 'current',
          latestStateRevalidationReceiptRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_revalidation_receipts.revalidation.json',
          latestStateRecoveryDecisionStatus: 'restored_after_review',
          latestStateRecoveryDecisionArtifactRef:
              'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_restore_decision.restored.json',
          currentBasisStatus: 'latest_state_served_basis',
          latestStateHydrationStatus:
              'latest_state_basis_restored_after_review',
          latestStatePromotionReadiness:
              'restored_to_served_basis_after_review',
          hydrationFreshnessPosture:
              'served_basis_restored_from_revalidated_receipts',
        ),
      );
      when(
        () => replayService.getLabRuntimeState(
          environmentId: 'atx-replay-world-2024',
        ),
      ).thenAnswer((_) async => runtimeState);
      when(
        () => replayService.listLabOutcomes(
          environmentId: 'atx-replay-world-2024',
          limit: 0,
        ),
      ).thenAnswer(
        (_) async => <ReplaySimulationLabOutcomeRecord>[
          latestOutcome,
          previousOutcome,
        ],
      );
      when(
        () => replayService.listLabRerunRequests(
          environmentId: 'atx-replay-world-2024',
          limit: 0,
        ),
      ).thenAnswer(
          (_) async => <ReplaySimulationLabRerunRequest>[latestRequest]);
      when(
        () => replayService.listLabRerunJobs(
          environmentId: 'atx-replay-world-2024',
          limit: 0,
        ),
      ).thenAnswer(
        (_) async => <ReplaySimulationLabRerunJob>[
          latestJob,
          previousJob,
        ],
      );
      when(
        () => replayService.listLabFamilyRestageReviewItems(
          environmentId: 'atx-replay-world-2024',
          limit: 0,
        ),
      ).thenAnswer(
        (_) async => <ReplaySimulationLabFamilyRestageReviewItem>[
          ReplaySimulationLabFamilyRestageReviewItem(
            itemId: 'atx-replay-world-2024-family-restage-app-observations',
            environmentId: 'atx-replay-world-2024',
            supportedPlaceRef: 'place:atx',
            evidenceFamily: 'app_observations',
            restageTarget: 'restage_input_family:app_observations',
            restageTargetSummary:
                'app observations: route to restage input family `app observations` because this family is repeatedly degrading.',
            policyAction: 'force_restaged_inputs',
            policyActionSummary:
                'app observations now needs bounded restage intake review.',
            queuedAt: DateTime.utc(2026, 4, 2, 10, 0),
            queueStatus: 'restage_intake_review_approved',
            itemRoot:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations',
            itemJsonPath:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_review_item.current.json',
            readmePath:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_REVIEW_ITEM_README.md',
            servedBasisRef:
                'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/served_city_pack_basis.refresh.json',
            currentBasisStatus: 'latest_state_served_basis',
            queueDecisionArtifactRef:
                'world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_review_decision.restage_intake_requested.json',
            queueDecisionRationale:
                'Requested bounded restage intake review for this evidence family from World Simulation Lab.',
            queueDecisionRecordedAt: DateTime.utc(2026, 4, 2, 10, 15),
            restageIntakeQueueJsonPath:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_intake_review.current.json',
            restageIntakeReadmePath:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/FAMILY_RESTAGE_INTAKE_REVIEW_README.md',
            restageIntakeSourceId:
                'family_restage_source_atx-replay-world-2024_app_observations_2026-04-02T10-15-00.000Z',
            restageIntakeJobId:
                'family_restage_job_atx-replay-world-2024_app_observations_2026-04-02T10-15-00.000Z',
            restageIntakeReviewItemId:
                'family_restage_review_atx-replay-world-2024_app_observations',
            restageIntakeResolutionStatus: 'approved',
            restageIntakeResolutionArtifactRef:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_intake_resolution.approved.json',
            restageIntakeResolutionRationale:
                'Approved bounded family restage intake review for this evidence family.',
            followUpQueueStatus: 'queued_for_family_restage_follow_up_review',
            followUpQueueJsonPath:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_review.current.json',
            followUpReviewItemId:
                'family_restage_follow_up_review_atx-replay-world-2024_app_observations',
            followUpResolutionStatus: 'approved',
            followUpResolutionArtifactRef:
                '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_follow_up_resolution.approved.json',
            followUpResolutionRationale:
                'Approved bounded family restage follow-up review for this evidence family.',
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
            restageExecutionResolutionRationale:
                'Approved bounded family restage execution review for this evidence family.',
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
            restageApplyResolutionRationale:
                'Approved bounded family restage apply review for this evidence family.',
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
            restageServedBasisUpdateResolutionRationale:
                'Approved bounded family restage served-basis update review for this evidence family.',
            cityPackStructuralRef: 'city_pack:atx_core_2024',
            latestStateRefreshReceiptRef:
                'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_refresh_receipts.refresh.json',
            latestStateRevalidationReceiptRef:
                'world_simulation_lab/registered_environments/atx-replay-world-2024/basis_refreshes/demo_refresh/basis_revalidation_receipts.revalidation.json',
          ),
        ],
      );

      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        replaySimulationAdminService: replayService,
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.servedBasisSummaries, hasLength(1));
      final servedBasis = snapshot.servedBasisSummaries.single;
      expect(servedBasis.environmentId, 'atx-replay-world-2024');
      expect(servedBasis.currentBasisStatus, 'latest_state_served_basis');
      expect(
        servedBasis.latestStateRecoveryDecisionStatus,
        'restored_after_review',
      );
      expect(
        servedBasis.latestStateRecoveryDecisionArtifactRef,
        contains('basis_restore_decision.restored.json'),
      );
      expect(snapshot.labTargetActionItems, hasLength(1));
      expect(snapshot.familyRestageIntakeReviewSummaries, hasLength(1));
      final familyRestageSummary =
          snapshot.familyRestageIntakeReviewSummaries.single;
      expect(
        familyRestageSummary.environmentId,
        'atx-replay-world-2024',
      );
      expect(
        familyRestageSummary.queueStatus,
        'restage_intake_review_approved',
      );
      expect(
        familyRestageSummary.followUpReviewItemId,
        'family_restage_follow_up_review_atx-replay-world-2024_app_observations',
      );
      expect(familyRestageSummary.followUpResolutionStatus, 'approved');
      expect(
        familyRestageSummary.restageResolutionQueueStatus,
        'queued_for_family_restage_resolution_review',
      );
      expect(
        familyRestageSummary.restageResolutionQueueJsonPath,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_resolution_review.current.json',
      );
      expect(
        familyRestageSummary.restageResolutionReviewItemId,
        'family_restage_resolution_review_atx-replay-world-2024_app_observations',
      );
      expect(
        familyRestageSummary.restageResolutionResolutionStatus,
        'approved_for_bounded_family_restage_execution',
      );
      expect(
        familyRestageSummary.restageExecutionQueueStatus,
        'queued_for_family_restage_execution_review',
      );
      expect(
        familyRestageSummary.restageExecutionQueueJsonPath,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution_review.current.json',
      );
      expect(
        familyRestageSummary.restageExecutionReviewItemId,
        'family_restage_execution_review_atx-replay-world-2024_app_observations',
      );
      expect(
        familyRestageSummary.restageExecutionResolutionStatus,
        'approved_for_bounded_family_restage_application',
      );
      expect(
        familyRestageSummary.restageExecutionResolutionArtifactRef,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_execution.approved.json',
      );
      expect(
        familyRestageSummary.restageApplicationQueueStatus,
        'queued_for_family_restage_application_review',
      );
      expect(
        familyRestageSummary.restageApplicationQueueJsonPath,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application_review.current.json',
      );
      expect(
        familyRestageSummary.restageApplicationReviewItemId,
        'family_restage_application_review_atx-replay-world-2024_app_observations',
      );
      expect(
        familyRestageSummary.restageApplicationResolutionStatus,
        'approved_for_bounded_family_restage_apply_to_served_basis',
      );
      expect(
        familyRestageSummary.restageApplicationResolutionArtifactRef,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_application.approved.json',
      );
      expect(
        familyRestageSummary.restageApplyQueueStatus,
        'queued_for_family_restage_apply_review',
      );
      expect(
        familyRestageSummary.restageApplyQueueJsonPath,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply_review.current.json',
      );
      expect(
        familyRestageSummary.restageApplyReviewItemId,
        'family_restage_apply_review_atx-replay-world-2024_app_observations',
      );
      expect(
        familyRestageSummary.restageApplyResolutionStatus,
        'approved_for_bounded_family_restage_served_basis_update',
      );
      expect(
        familyRestageSummary.restageApplyResolutionArtifactRef,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_apply.approved.json',
      );
      expect(
        familyRestageSummary.restageServedBasisUpdateQueueStatus,
        'queued_for_family_restage_served_basis_update_review',
      );
      expect(
        familyRestageSummary.restageServedBasisUpdateQueueJsonPath,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update_review.current.json',
      );
      expect(
        familyRestageSummary.restageServedBasisUpdateReviewItemId,
        'family_restage_served_basis_update_review_atx-replay-world-2024_app_observations',
      );
      expect(
        familyRestageSummary.restageServedBasisUpdateResolutionStatus,
        'approved_for_bounded_family_restage_served_basis_mutation',
      );
      expect(
        familyRestageSummary.restageServedBasisUpdateResolutionArtifactRef,
        '/tmp/AVRAI/world_simulation_lab/registered_environments/atx-replay-world-2024/family_restage_review/app_observations/family_restage_served_basis_update.approved.json',
      );
      final labTargetAction = snapshot.labTargetActionItems.single;
      expect(labTargetAction.environmentId, 'atx-replay-world-2024');
      expect(labTargetAction.targetLabel, 'Heatwave mitigation lane');
      expect(labTargetAction.selectedAction, 'candidate_for_bounded_review');
      expect(labTargetAction.acceptedSuggestion, isFalse);
      expect(labTargetAction.trendSummary, isNotNull);
      expect(labTargetAction.provenanceDeltaSummary, isNotNull);
      expect(labTargetAction.provenanceHistorySummary, isNotNull);
      expect(labTargetAction.provenanceHistorySummary!.sampleCount, 4);
      expect(labTargetAction.provenanceEmphasisSummary, isNotNull);
      expect(
        labTargetAction.provenanceEmphasisSummary!.severityCode,
        'elevated_churn',
      );
      expect(labTargetAction.boundedAlertSummary, isNotNull);
      expect(
        labTargetAction.boundedAlertSummary!.severityCode,
        'spiking',
      );
      expect(
          labTargetAction.alertAcknowledgedAt, DateTime.utc(2026, 4, 2, 8, 45));
      expect(labTargetAction.alertAcknowledgedSeverityCode, 'spiking');
      expect(labTargetAction.isCurrentBoundedAlertAcknowledged, isTrue);
      expect(labTargetAction.alertEscalatedAt, DateTime.utc(2026, 4, 2, 9));
      expect(labTargetAction.alertEscalatedSeverityCode, 'spiking');
      expect(labTargetAction.isCurrentBoundedAlertEscalated, isTrue);
      expect(
        labTargetAction.provenanceDeltaSummary!.details,
        contains('Added artifact families: replay_learning_bundle'),
      );
      expect(
        labTargetAction.provenanceHistorySummary!.entries.first.details,
        contains('Added artifact families: replay_learning_bundle'),
      );
      expect(labTargetAction.trendSummary!.completedRerunCount, 2);
      expect(
        labTargetAction.trendSummary!.runtimeTrendSeverityCode,
        'regressing',
      );
      expect(
        labTargetAction.trendSummary!.runtimeDeltaSummary,
        'Runtime delta vs prior completed rerun: contradictions up 2, receipts down 1, overlays stable, request previews down 1.',
      );
      expect(snapshot.boundedReviewCandidates, hasLength(1));
      final candidate = snapshot.boundedReviewCandidates.single;
      expect(candidate.environmentId, 'atx-replay-world-2024');
      expect(candidate.displayName, 'Austin Simulation Environment 2024');
      expect(candidate.targetLabel, 'Heatwave mitigation lane');
      expect(candidate.selectedAction, 'candidate_for_bounded_review');
      expect(candidate.acceptedSuggestion, isFalse);
      expect(candidate.cityPackStructuralRef, 'city_pack:atx_core_2024');
      expect(
        candidate.sidecarRefs,
        contains('world_models/atx/jepa_geo_realism_v2.json'),
      );
      expect(candidate.latestOutcomeDisposition, 'denied');
      expect(candidate.latestRerunRequestStatus, 'completed');
      expect(candidate.latestRerunJobStatus, 'completed');
      expect(candidate.provenanceDeltaSummary, isNotNull);
      expect(candidate.provenanceHistorySummary, isNotNull);
      expect(candidate.provenanceHistorySummary!.sampleCount, 4);
      expect(candidate.provenanceEmphasisSummary, isNotNull);
      expect(
        candidate.provenanceEmphasisSummary!.severityCode,
        'elevated_churn',
      );
      expect(candidate.boundedAlertSummary, isNotNull);
      expect(candidate.boundedAlertSummary!.severityCode, 'spiking');
      expect(candidate.alertAcknowledgedAt, DateTime.utc(2026, 4, 2, 8, 45));
      expect(candidate.alertAcknowledgedSeverityCode, 'spiking');
      expect(candidate.isCurrentBoundedAlertAcknowledged, isTrue);
      expect(candidate.alertEscalatedAt, DateTime.utc(2026, 4, 2, 9));
      expect(candidate.alertEscalatedSeverityCode, 'spiking');
      expect(candidate.isCurrentBoundedAlertEscalated, isTrue);
      expect(
        candidate.provenanceDeltaSummary!.details,
        contains('Added artifact families: replay_learning_bundle'),
      );
      expect(
        candidate.provenanceHistorySummary!.entries[1].details,
        contains('Added sidecars: world_models/atx/jepa_geo_realism_v2.json'),
      );
      expect(candidate.trendSummary, isNotNull);
      expect(
        candidate.trendSummary!.outcomeTrendSummary,
        'Outcome trend: repeated denials across the latest two runs.',
      );
    });
  });
}
