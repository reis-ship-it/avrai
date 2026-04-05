import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
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

  group('UserGovernedLearningProjectionService', () {
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

    test('projects visible records from governed learning envelopes', () async {
      final repository = UniversalIntakeRepository();
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
      );

      await intakeService.stagePersonalAgentHumanIntake(
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
          'referenced_entities': <String>['coffee shop list', 'downtown place'],
          'preference_signals': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'pace',
              'value': 'calm local list',
              'confidence': 0.91,
            },
          ],
          'questions': <String>['Which place works best tonight?'],
          'accepted': true,
          'learning_allowed': true,
        },
        cityCode: 'bham',
        localityCode: 'downtown',
      );

      final records = await projectionService.listVisibleRecords(
        ownerUserId: 'user_123',
      );

      expect(records, hasLength(1));
      expect(records.single.safeSummary,
          'The user wants a quieter weeknight plan.');
      expect(
        records.single.domainHints,
        containsAll(const <String>['locality', 'list', 'place']),
      );
      expect(
        records.single.availableActions,
        containsAll(const <UserGovernedLearningAction>[
          UserGovernedLearningAction.showDetails,
          UserGovernedLearningAction.openDataCenter,
          UserGovernedLearningAction.correctRecord,
        ]),
      );
    });

    test('builds a bounded chat explanation from latest learning record',
        () async {
      final repository = UniversalIntakeRepository();
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
      );

      await intakeService.stageRecommendationFeedbackIntake(
        ownerUserId: 'user_123',
        action: RecommendationFeedbackAction.lessLikeThis,
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_123',
          title: 'Late Night Venue',
          localityLabel: 'downtown',
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
        sourceSurface: 'explore',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'recommendation_feedback_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 2),
        ),
        metadata: const <String, dynamic>{
          'domains': <String>['business'],
        },
      );

      final explanation = await projectionService.buildChatExplanation(
        ownerUserId: 'user_123',
      );

      expect(
        explanation.summary,
        contains('The latest thing I learned from you was:'),
      );
      expect(explanation.summary, contains('Late Night Venue'));
      expect(explanation.selectedRecord, isNotNull);
      expect(explanation.selectedRecord!.safeSummary,
          contains('Late Night Venue'));
      expect(
        explanation.details.join(' '),
        contains('human review'),
      );
      expect(
        explanation.suggestedActions,
        contains(UserGovernedLearningAction.openDataCenter),
      );
    });

    test('resolves the most relevant record from a targeted query', () async {
      final repository = UniversalIntakeRepository();
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
      );

      await intakeService.stageRecommendationFeedbackIntake(
        ownerUserId: 'user_123',
        action: RecommendationFeedbackAction.lessLikeThis,
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_123',
          title: 'Late Night Venue',
          localityLabel: 'downtown',
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 4, 1),
        sourceSurface: 'explore',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'recommendation_feedback_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 1),
        ),
      );
      await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_latest_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 2),
          messageId: 'message_latest_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan.',
          'sanitized_summary': 'The user wants a quieter weeknight plan.',
          'accepted': true,
          'learning_allowed': true,
        },
      );

      final selected = await projectionService.resolveRelevantRecord(
        ownerUserId: 'user_123',
        query: 'What did you learn about Late Night Venue?',
      );
      final explanation = await projectionService.buildChatExplanation(
        ownerUserId: 'user_123',
        query: 'What did you learn about Late Night Venue?',
      );

      expect(selected, isNotNull);
      expect(selected!.safeSummary, contains('Late Night Venue'));
      expect(
        explanation.summary,
        contains('best matches your question'),
      );
      expect(explanation.summary, contains('Late Night Venue'));
      expect(explanation.selectedRecord, isNotNull);
      expect(explanation.selectedRecord!.safeSummary,
          contains('Late Night Venue'));
    });

    test('projects usage receipts back into visible records', () async {
      final repository = UniversalIntakeRepository();
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final usageService = UserGovernedLearningUsageService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        adoptionService: adoptionService,
        usageService: usageService,
      );

      final intakeResult = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_usage_123',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 3),
          messageId: 'message_usage_123',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants louder nightlife scenes.',
          'sanitized_summary': 'The user wants louder nightlife scenes.',
          'accepted': true,
          'learning_allowed': true,
        },
      );
      await usageService.recordReceipts([
        GovernedLearningUsageReceipt(
          id: 'receipt_usage_1',
          ownerUserId: 'user_123',
          envelopeId: intakeResult.envelope.id,
          sourceId: intakeResult.sourceId,
          decisionFamily: 'event_recommendation',
          decisionId: 'decision_usage_1',
          domainId: 'nightlife',
          domainLabel: 'Nightlife',
          targetEntityId: 'event-nightlife-1',
          targetEntityType: 'event',
          targetEntityTitle: 'Austin After Dark',
          usedAtUtc: DateTime.utc(2026, 4, 4, 4),
          influenceKind: GovernedLearningUsageInfluenceKind.boost,
          influenceScoreDelta: 0.08,
          influenceReason: 'Nightlife preference boosted this recommendation.',
          surface: 'events_personalized',
        ),
      ]);

      final records = await projectionService.listVisibleRecords(
        ownerUserId: 'user_123',
      );

      expect(records, hasLength(1));
      expect(records.single.envelopeId, intakeResult.envelope.id);
      expect(records.single.usageCount, 1);
      expect(records.single.lastUsedAtUtc, DateTime.utc(2026, 4, 4, 4));
      expect(records.single.appliedDomains, contains('Nightlife'));
      expect(records.single.recentUsageReceipts, isNotEmpty);
      expect(records.single.recentUsageReceipts.first.targetEntityTitle,
          'Austin After Dark');
    });

    test('derives adoption precedence from surfaced to queued to accepted',
        () async {
      final repository = UniversalIntakeRepository();
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        adoptionService: adoptionService,
      );

      final acceptedOnly = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_accepted',
        actorAgentId: 'agent_accepted',
        chatId: 'chat_accepted',
        messageId: 'message_accepted',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 3),
          chatId: 'chat_accepted',
          messageId: 'message_accepted',
        ),
        boundaryMetadata: const <String, dynamic>{
          'intent': 'correct',
          'summary': 'I want more outdoor concerts.',
          'sanitized_summary': 'I want more outdoor concerts.',
          'accepted': true,
          'learning_allowed': true,
        },
      );
      final queued = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_queued',
        actorAgentId: 'agent_queued',
        chatId: 'chat_queued',
        messageId: 'message_queued',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 4),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 4),
          chatId: 'chat_queued',
          messageId: 'message_queued',
        ),
        boundaryMetadata: const <String, dynamic>{
          'intent': 'correct',
          'summary': 'I want louder nightlife scenes.',
          'sanitized_summary': 'I want louder nightlife scenes.',
          'accepted': true,
          'learning_allowed': true,
        },
      );
      final surfaced = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_surfaced',
        actorAgentId: 'agent_surfaced',
        chatId: 'chat_surfaced',
        messageId: 'message_surfaced',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 5),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 5),
          chatId: 'chat_surfaced',
          messageId: 'message_surfaced',
        ),
        boundaryMetadata: const <String, dynamic>{
          'intent': 'correct',
          'summary': 'I want louder nightlife scenes.',
          'sanitized_summary': 'I want louder nightlife scenes.',
          'accepted': true,
          'learning_allowed': true,
        },
      );

      await adoptionService.recordReceipts([
        GovernedLearningAdoptionReceipt(
          id: '${acceptedOnly.envelope.id}:accepted',
          ownerUserId: 'user_accepted',
          envelopeId: acceptedOnly.envelope.id,
          sourceId: acceptedOnly.sourceId,
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 3, 1),
          reason: 'accepted',
        ),
        GovernedLearningAdoptionReceipt(
          id: '${queued.envelope.id}:accepted',
          ownerUserId: 'user_queued',
          envelopeId: queued.envelope.id,
          sourceId: queued.sourceId,
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 4, 1),
          reason: 'accepted',
        ),
        GovernedLearningAdoptionReceipt(
          id: '${queued.envelope.id}:queued',
          ownerUserId: 'user_queued',
          envelopeId: queued.envelope.id,
          sourceId: queued.sourceId,
          status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 4, 2),
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          reason: 'queued',
        ),
        GovernedLearningAdoptionReceipt(
          id: '${surfaced.envelope.id}:accepted',
          ownerUserId: 'user_surfaced',
          envelopeId: surfaced.envelope.id,
          sourceId: surfaced.sourceId,
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 5, 1),
          reason: 'accepted',
        ),
        GovernedLearningAdoptionReceipt(
          id: '${surfaced.envelope.id}:queued',
          ownerUserId: 'user_surfaced',
          envelopeId: surfaced.envelope.id,
          sourceId: surfaced.sourceId,
          status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 5, 2),
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          reason: 'queued',
        ),
        GovernedLearningAdoptionReceipt(
          id: '${surfaced.envelope.id}:surfaced',
          ownerUserId: 'user_surfaced',
          envelopeId: surfaced.envelope.id,
          sourceId: surfaced.sourceId,
          status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 5, 3),
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          targetEntityId: 'event_123',
          targetEntityType: 'event',
          targetEntityTitle: 'Austin After Dark',
          reason: 'surfaced',
        ),
      ]);

      final acceptedRecords = await projectionService.listVisibleRecords(
        ownerUserId: 'user_accepted',
      );
      final queuedRecords = await projectionService.listVisibleRecords(
        ownerUserId: 'user_queued',
      );
      final surfacedRecords = await projectionService.listVisibleRecords(
        ownerUserId: 'user_surfaced',
      );

      expect(
        acceptedRecords.single.currentAdoptionStatus,
        GovernedLearningAdoptionStatus.acceptedForLearning,
      );
      expect(acceptedRecords.single.pendingSurfaces, isEmpty);
      expect(
        queuedRecords.single.currentAdoptionStatus,
        GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
      );
      expect(
        queuedRecords.single.pendingSurfaces,
        contains('events_personalized'),
      );
      expect(
        surfacedRecords.single.currentAdoptionStatus,
        GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
      );
      expect(
        surfacedRecords.single.surfacedSurfaces,
        contains('events_personalized'),
      );
      expect(
        surfacedRecords.single.firstSurfacedAtUtc,
        DateTime.utc(2026, 4, 4, 5, 3),
      );
    });
  });
}
