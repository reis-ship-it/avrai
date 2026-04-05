import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_contract.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  UpwardAirGapArtifact issueTestAirGapArtifact({
    required String sourceKind,
    required String sourceScope,
    required DateTime issuedAtUtc,
    String chatId = 'chat_123',
    String messageId = 'message_123',
  }) {
    final mintedAtUtc = DateTime.now().toUtc();
    return const UpwardAirGapService().issueArtifact(
      originPlane: 'personal_device',
      sourceKind: sourceKind,
      sourceScope: sourceScope,
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: mintedAtUtc,
      sanitizedPayload: <String, dynamic>{
        'sourceKind': sourceKind,
        'sourceScope': sourceScope,
        'sourceOccurredAtUtc': issuedAtUtc.toUtc().toIso8601String(),
        if (sourceKind == 'personal_agent_human_intake') 'chatId': chatId,
        if (sourceKind == 'personal_agent_human_intake') 'messageId': messageId,
      },
      pseudonymousActorRef: 'anon_user',
    );
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestStorage();
  });

  setUp(() async {
    await StorageService.instance.clear();
    await StorageService.instance.clear(box: 'spots_user');
    await StorageService.instance.clear(box: 'spots_ai');
    await StorageService.instance.clear(box: 'spots_analytics');
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('UserGovernedLearningControlService', () {
    test('forgetRecord tombstones record and removes it from projection',
        () async {
      final repository = UniversalIntakeRepository();
      final policyService = UserGovernedLearningSignalPolicyService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
        signalPolicyService: policyService,
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        signalPolicyService: policyService,
      );
      final controlService = UserGovernedLearningControlService(
        intakeRepository: repository,
        governedUpwardLearningIntakeService: intakeService,
        agentIdService: AgentIdService(),
        signalPolicyService: policyService,
        correctionFollowUpPlannerService:
            UserGovernedLearningCorrectionFollowUpPromptPlannerService(
          promptPolicyService: BoundedFollowUpPromptPolicyService(
            policy: BoundedFollowUpPromptPolicy(
              maxPromptPlansPerDay: 10,
              quietHoursStartHour: 0,
              quietHoursEndHour: 0,
              suggestionFamilyCooldown: Duration(seconds: 1),
              eventFamilyCooldown: Duration(seconds: 1),
            ),
          ),
        ),
      );

      final result = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 1),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 1),
          messageId: 'message_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan.',
          'sanitized_summary': 'The user wants a quieter weeknight plan.',
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final forgotten = await controlService.forgetRecord(
        ownerUserId: 'user_123',
        envelopeId: result.envelope.id,
      );

      final records = await projectionService.listVisibleRecords(
        ownerUserId: 'user_123',
      );
      final reviews = await repository.getAllReviewItems();
      final sources = await repository.getAllSources();

      expect(forgotten, isTrue);
      expect(records, isEmpty);
      expect(reviews, isEmpty);
      expect(
        ((sources.single.metadata[governedLearningControlMetadataKey] as Map)
            .cast<String, dynamic>())[governedLearningControlStateKey],
        governedLearningControlStateForgotten,
      );
    });

    test('submitCorrection stages explicit correction intake linked to source',
        () async {
      final repository = UniversalIntakeRepository();
      final prefs = await SharedPreferencesCompat.getInstance();
      final correctionPlanner =
          UserGovernedLearningCorrectionFollowUpPromptPlannerService(
        prefs: prefs,
        promptPolicyService: BoundedFollowUpPromptPolicyService(
          policy: BoundedFollowUpPromptPolicy(
            maxPromptPlansPerDay: 10,
            quietHoursStartHour: 0,
            quietHoursEndHour: 0,
            suggestionFamilyCooldown: Duration(seconds: 1),
            eventFamilyCooldown: Duration(seconds: 1),
          ),
        ),
      );
      final policyService = UserGovernedLearningSignalPolicyService(
        storageService: StorageService.instance,
      );
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
        signalPolicyService: policyService,
      );
      final controlService = UserGovernedLearningControlService(
        intakeRepository: repository,
        governedUpwardLearningIntakeService: intakeService,
        agentIdService: AgentIdService(),
        signalPolicyService: policyService,
        adoptionService: adoptionService,
        correctionFollowUpPlannerService: correctionPlanner,
      );

      final initialResult = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 2),
          messageId: 'message_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan.',
          'sanitized_summary': 'The user wants a quieter weeknight plan.',
          'referenced_entities': <String>['coffee shop list'],
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final correctionResult = await controlService.submitCorrection(
        ownerUserId: 'user_123',
        envelopeId: initialResult.envelope.id,
        correctionText: 'Actually I want a louder place with more activity.',
      );

      final reviews = await repository.getAllReviewItems();
      final newestReview = reviews.first;
      final boundary =
          Map<String, dynamic>.from(newestReview.payload['boundary'] as Map);
      final plans = await correctionPlanner.listPlans('user_123');
      final adoptionReceipts = await adoptionService.listReceiptsForEnvelope(
        ownerUserId: 'user_123',
        envelopeId: correctionResult!.envelope.id,
      );

      expect(correctionResult.convictionTier, 'explicit_correction_signal');
      expect(reviews, hasLength(2));
      expect(newestReview.payload['sourceKind'], 'explicit_correction_intake');
      expect(
        boundary['correction_target_envelope_id'],
        initialResult.envelope.id,
      );
      expect(
        boundary['correction_target_source_id'],
        initialResult.sourceId,
      );
      expect(
        newestReview.payload['safeSummary'],
        contains('Actually I want a louder place with more activity.'),
      );
      expect(plans, isNotEmpty);
      expect(adoptionReceipts, hasLength(1));
      expect(
        adoptionReceipts.single.status.name,
        'acceptedForLearning',
      );
    });

    test(
        'submitCorrection queues personalized events adoption for event-eligible corrections',
        () async {
      final repository = UniversalIntakeRepository();
      final policyService = UserGovernedLearningSignalPolicyService(
        storageService: StorageService.instance,
      );
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
        signalPolicyService: policyService,
      );
      final controlService = UserGovernedLearningControlService(
        intakeRepository: repository,
        governedUpwardLearningIntakeService: intakeService,
        agentIdService: AgentIdService(),
        signalPolicyService: policyService,
        adoptionService: adoptionService,
      );

      final initialResult = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_nightlife_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 2),
          messageId: 'message_nightlife_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants louder nightlife scenes.',
          'sanitized_summary': 'The user wants louder nightlife scenes.',
          'referenced_entities': <String>['Austin After Dark', 'nightlife'],
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final correctionResult = await controlService.submitCorrection(
        ownerUserId: 'user_123',
        envelopeId: initialResult.envelope.id,
        correctionText:
            'Actually I want louder nightlife and more social energy.',
      );
      final adoptionReceipts = await adoptionService.listReceiptsForEnvelope(
        ownerUserId: 'user_123',
        envelopeId: correctionResult!.envelope.id,
      );

      expect(adoptionReceipts, hasLength(2));
      expect(
        adoptionReceipts.map((entry) => entry.status.name),
        containsAll(const <String>[
          'acceptedForLearning',
          'queuedForSurfaceRefresh',
        ]),
      );
      expect(
        adoptionReceipts
            .where((entry) => entry.surface == 'events_personalized')
            .single
            .decisionFamily,
        'event_recommendation',
      );
    });

    test('stopUsingSignal blocks future matching intake and withdraws review',
        () async {
      final repository = UniversalIntakeRepository();
      final policyService = UserGovernedLearningSignalPolicyService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
        signalPolicyService: policyService,
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        signalPolicyService: policyService,
      );
      final controlService = UserGovernedLearningControlService(
        intakeRepository: repository,
        governedUpwardLearningIntakeService: intakeService,
        agentIdService: AgentIdService(),
        signalPolicyService: policyService,
      );

      final initialResult = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 3),
          messageId: 'message_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan.',
          'sanitized_summary': 'The user wants a quieter weeknight plan.',
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final stopped = await controlService.stopUsingSignal(
        ownerUserId: 'user_123',
        envelopeId: initialResult.envelope.id,
      );

      final records = await projectionService.listVisibleRecords(
        ownerUserId: 'user_123',
      );
      final reviewsAfterStop = await repository.getAllReviewItems();

      final suppressedResult =
          await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_456',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 4),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 4),
          messageId: 'message_456',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan again.',
          'sanitized_summary': 'The user wants a quieter weeknight plan again.',
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final sources = await repository.getAllSources();
      final reviewsAfterSuppression = await repository.getAllReviewItems();

      expect(stopped, isTrue);
      expect(records, hasLength(1));
      expect(records.single.futureSignalUseBlocked, isTrue);
      expect(
        records.single.availableActions,
        isNot(contains(UserGovernedLearningAction.stopUsingSignal)),
      );
      expect(reviewsAfterStop, isEmpty);
      expect(sources, hasLength(1));
      expect(reviewsAfterSuppression, isEmpty);
      expect(
        suppressedResult.envelope.metadata['signalSuppressedByUserPolicy'],
        isTrue,
      );
      expect(suppressedResult.kernelGraphRunId, isNull);
    });
  });
}
