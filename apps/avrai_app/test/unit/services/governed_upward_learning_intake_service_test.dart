import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/community/community_validation.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_core/models/reality/governed_learning_envelope.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/kernel_graph/kernel_graph_run_ledger.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UpwardAirGapArtifact issueTestAirGapArtifact({
    required String sourceKind,
    required String sourceScope,
    required DateTime issuedAtUtc,
    Map<String, dynamic> sanitizedPayload = const <String, dynamic>{},
    String originPlane = 'personal_device',
    String? pseudonymousActorRef,
  }) {
    final mintedAtUtc = DateTime.now().toUtc();
    return const UpwardAirGapService().issueArtifact(
      originPlane: originPlane,
      sourceKind: sourceKind,
      sourceScope: sourceScope,
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: mintedAtUtc,
      sanitizedPayload: <String, dynamic>{
        'sourceKind': sourceKind,
        'sourceScope': sourceScope,
        'sourceOccurredAtUtc': issuedAtUtc.toUtc().toIso8601String(),
        ...sanitizedPayload,
      },
      pseudonymousActorRef: pseudonymousActorRef,
    );
  }

  group('GovernedUpwardLearningIntakeService', () {
    test('stages personal-agent human intake with temporal lineage', () async {
      final repository = UniversalIntakeRepository();
      final kernelGraphRunLedger = KernelGraphRunLedger();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
        kernelGraphRunLedger: kernelGraphRunLedger,
      );
      final occurredAt = DateTime.utc(2026, 4, 2, 18, 0);

      final result = await service.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_123',
        occurredAtUtc: occurredAt,
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          issuedAtUtc: occurredAt,
          sanitizedPayload: const <String, dynamic>{
            'chatId': 'chat_123',
            'messageId': 'message_123',
          },
          pseudonymousActorRef: 'anon_user',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants a quieter weeknight plan.',
          'sanitized_summary': 'The user wants a quieter weeknight plan.',
          'referenced_entities': <String>['coffee shop list', 'downtown place'],
          'questions': <String>['Which place works best tonight?'],
          'preference_signals': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'pace',
              'value': 'calm local list',
              'confidence': 0.91,
            },
          ],
          'pseudonymous_actor_ref': 'anon_user',
          'accepted': true,
          'learning_allowed': true,
        },
        cityCode: 'bham',
        localityCode: 'downtown',
      );

      final sources = await repository.getAllSources();
      final reviews = await repository.getAllReviewItems();
      final kernelGraphRuns = await kernelGraphRunLedger.listRuns();

      expect(
        result.learningPathway,
        GovernedUpwardLearningIntakeService.learningPathway,
      );
      expect(result.kernelGraphSpecId, isNotEmpty);
      expect(result.kernelGraphRunId, isNotEmpty);
      expect(result.kernelGraphStatus, KernelGraphRunStatus.completed);
      expect(result.kernelGraphAdminDigest?.completedNodeCount, 3);
      expect(result.envelope.id, 'gle:${result.sourceId}');
      expect(result.envelope.kernelGraphRunId, result.kernelGraphRunId);
      expect(
        result.envelope.domainHints,
        containsAll(const <String>['locality', 'list', 'place']),
      );
      expect(result.envelope.surface, 'chat');
      expect(result.envelope.channel, 'personality_agent');
      expect(kernelGraphRuns, hasLength(1));
      expect(kernelGraphRuns.single.sourceId, result.sourceId);
      expect(kernelGraphRuns.single.reviewItemId, result.reviewItemId);
      expect(kernelGraphRuns.single.spec?.nodes, hasLength(3));
      expect(kernelGraphRuns.single.spec?.edges, hasLength(2));
      expect(kernelGraphRuns.single.compiledPlan?.steps, hasLength(3));
      expect(
        kernelGraphRuns.single.adminDigest.completedNodeCount,
        result.kernelGraphAdminDigest?.completedNodeCount,
      );
      expect(sources, hasLength(1));
      expect(reviews, hasLength(1));
      expect(
        sources.single.metadata['queueKind'],
        GovernedUpwardLearningIntakeService.upwardQueueKind,
      );
      expect(
        (sources.single.metadata['temporalLineage']
            as Map<String, dynamic>)['originOccurredAtUtc'],
        occurredAt.toIso8601String(),
      );
      expect(
        ((sources.single.metadata['temporalLineage']
                as Map<String, dynamic>)['atomicTimestamp']
            as Map<String, dynamic>)['timestampId'],
        isNotEmpty,
      );
      expect(
        sources.single.metadata['kernelGraphSpecId'],
        result.kernelGraphSpecId,
      );
      expect(
        sources.single.metadata['kernelGraphRunId'],
        result.kernelGraphRunId,
      );
      expect(
        sources.single.metadata['governedLearningEnvelopeId'],
        result.envelope.id,
      );
      final persistedEnvelope = GovernedLearningEnvelope.fromJson(
        Map<String, dynamic>.from(
          sources.single.metadata['governedLearningEnvelope'] as Map,
        ),
      );
      expect(persistedEnvelope.id, result.envelope.id);
      expect(persistedEnvelope.kernelGraphRunId, result.kernelGraphRunId);
      expect(
        persistedEnvelope.airGap?.receiptId,
        sources.single.metadata['airGapReceiptId'],
      );
      final reviewEnvelope = GovernedLearningEnvelope.fromJson(
        Map<String, dynamic>.from(
          reviews.single.payload['governedLearningEnvelope'] as Map,
        ),
      );
      expect(reviewEnvelope.id, result.envelope.id);
      expect(reviewEnvelope.safeSummary, result.envelope.safeSummary);
      expect(
        reviews.single.payload['convictionTier'],
        'personal_agent_human_observation',
      );
      expect(
        reviews.single.payload['hierarchyPath'],
        containsAll(
          const <String>['human', 'personal_agent', 'reality_model_agent'],
        ),
      );
      expect(
        sources.single.metadata['upwardDomainHints'],
        containsAll(const <String>['locality', 'list', 'place']),
      );
      expect(
        sources.single.metadata['upwardReferencedEntities'],
        contains('downtown place'),
      );
      expect(sources.single.metadata['airGapRequired'], isTrue);
      expect(
        sources.single.metadata['airGapArtifactVersion'],
        GovernedUpwardLearningIntakeService.upwardAirGapArtifactVersion,
      );
      expect(sources.single.metadata['airGapReceiptId'], isA<String>());
      expect(sources.single.metadata['airGapContentSha256'], isA<String>());
      expect(
        sources.single.metadata['airGapAllowedNextStages'],
        contains('governed_upward_learning_review'),
      );
      final airGapArtifact = UpwardAirGapArtifact.fromJson(
        Map<String, dynamic>.from(
          sources.single.metadata['airGapArtifact'] as Map,
        ),
      );
      expect(airGapArtifact.originPlane, 'personal_device');
      expect(airGapArtifact.destinationCeiling, 'reality_model_agent');
      expect(
        airGapArtifact.pseudonymousActorRef,
        'anon_user',
      );
      expect(
        airGapArtifact.sanitizedPayload['sourceKind'],
        'personal_agent_human_intake',
      );
      expect(
        (sources.single.metadata['upwardPreferenceSignals'] as List)
            .cast<Map<String, dynamic>>()
            .single['value'],
        'calm local list',
      );
      expect(sources.single.lifecycle, isNotNull);
      expect(sources.single.lifecycle?.artifactClass,
          ArtifactLifecycleClass.canonical);
      expect(sources.single.lifecycle?.artifactState,
          ArtifactLifecycleState.candidate);
      expect(sources.single.lifecycle?.containsRawPersonalPayload, isTrue);
      expect(sources.single.lifecycle?.containsMessageContent, isTrue);
      expect(
        sources.single.lifecycle?.retentionPolicy.mode,
        ArtifactRetentionMode.keepForever,
      );
      expect(reviews.single.lifecycle, isNotNull);
      expect(reviews.single.lifecycle?.artifactClass,
          ArtifactLifecycleClass.canonical);
      expect(reviews.single.lifecycle?.artifactState,
          ArtifactLifecycleState.candidate);
      expect(reviews.single.lifecycle?.containsRawPersonalPayload, isTrue);
      expect(reviews.single.lifecycle?.containsMessageContent, isTrue);
    });

    test('fails closed on malformed personal-agent human receipt binding',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final occurredAt = DateTime.utc(2026, 4, 2, 18, 0);

      await expectLater(
        () => service.stagePersonalAgentHumanIntake(
          ownerUserId: 'user_123',
          actorAgentId: 'agent_123',
          chatId: 'chat_123',
          messageId: 'message_123',
          occurredAtUtc: occurredAt,
          airGapArtifact: issueTestAirGapArtifact(
            sourceKind: 'personal_agent_human_intake',
            sourceScope: 'human',
            issuedAtUtc: occurredAt,
            sanitizedPayload: const <String, dynamic>{
              'chatId': 'chat_wrong',
              'messageId': 'message_123',
            },
            pseudonymousActorRef: 'anon_user',
          ),
          boundaryMetadata: const <String, dynamic>{
            'summary': 'The user wants a quieter weeknight plan.',
            'sanitized_summary': 'The user wants a quieter weeknight plan.',
            'accepted': true,
            'learning_allowed': true,
          },
          cityCode: 'bham',
          localityCode: 'downtown',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(
              'sanitizedPayload `chatId` does not match current request',
            ),
          ),
        ),
      );

      expect(await repository.getAllSources(), isEmpty);
      expect(await repository.getAllReviewItems(), isEmpty);
    });

    test('stages explicit human corrections as dedicated correction intake',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_123',
        messageId: 'message_correction_123',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 18, 15),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'explicit_correction_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 18, 15),
        ),
        boundaryMetadata: const <String, dynamic>{
          'intent': 'correct',
          'summary':
              'The venue is not in downtown and the line is usually short.',
          'sanitized_summary':
              'The venue is not in downtown and the line is usually short.',
          'referenced_entities': <String>['Late Night Venue'],
          'questions': <String>['Can you update that venue signal?'],
          'accepted': true,
          'learning_allowed': true,
        },
        cityCode: 'bham',
        localityCode: 'southside',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'explicit_correction_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'explicit_correction_signal',
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'correction:intent',
          'correction_source:human',
          'intent:correct',
        ]),
      );
      expect(
        reviews.single.payload['upwardQuestions'],
        contains(
          'What prior belief or recommendation should this correction challenge?',
        ),
      );
    });

    test('stages explicit AI2AI corrections as dedicated correction intake',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageAi2AiIntake(
        ownerUserId: 'user_123',
        localAgentId: 'agent_local_123',
        senderUserId: 'user_peer_456',
        remoteRef: 'user_peer_456',
        messageId: 'message_ai2ai_correction_123',
        scope: 'direct',
        direction: 'inbound',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 19, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'explicit_correction_intake',
          sourceScope: 'ai2ai',
          originPlane: 'ai2ai_peer',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 19, 0),
        ),
        boundaryMetadata: const <String, dynamic>{
          'intent': 'correct',
          'summary':
              'That venue business is not open late anymore and the crowd is quieter now.',
          'sanitized_summary':
              'That venue business is not open late anymore and the crowd is quieter now.',
          'referenced_entities': <String>['Night Owl Cafe'],
          'accepted': true,
          'learning_allowed': true,
          'channel': 'friend_chat',
          'surface': 'chat',
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'explicit_correction_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'ai2ai_explicit_correction_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['business', 'venue']),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'correction:intent',
          'correction_source:ai2ai',
          'intent:correct',
          'scope:direct',
        ]),
      );
    });

    test(
        'stages recommendation feedback intake with entity and attribution hints',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      final result = await service.stageRecommendationFeedbackIntake(
        ownerUserId: 'user_123',
        action: RecommendationFeedbackAction.lessLikeThis,
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_123',
          title: 'Late Night Venue',
          localityLabel: 'downtown',
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 3, 1, 0),
        sourceSurface: 'explore',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'recommendation_feedback_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 1, 0),
          sanitizedPayload: const <String, dynamic>{
            'action': 'lessLikeThis',
            'entity': <String, dynamic>{
              'type': 'spot',
              'id': 'spot_123',
              'title': 'Late Night Venue',
              'localityLabel': 'downtown',
            },
            'sourceSurface': 'explore',
          },
        ),
        attribution: const RecommendationAttribution(
          why: 'Popular nearby venue',
          whyDetails: 'Crowded venue with strong nightlife activity',
          projectedEnjoyabilityPercent: 61,
          recommendationSource: 'venue_intelligence_lane',
          confidence: 0.74,
        ),
        metadata: const <String, dynamic>{
          'domains': <String>['business'],
        },
      );

      final sources = await repository.getAllSources();
      final reviews = await repository.getAllReviewItems();

      expect(result.learningPathway,
          GovernedUpwardLearningIntakeService.learningPathway);
      expect(sources, hasLength(1));
      expect(reviews, hasLength(1));
      expect(result.envelope.surface, 'recommendation_feedback');
      expect(result.envelope.channel, 'explore');
      expect(
        result.envelope.domainHints,
        containsAll(const <String>['business', 'locality', 'place', 'venue']),
      );
      expect(reviews.single.payload['sourceKind'],
          'recommendation_feedback_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'recommendation_feedback_correction_signal',
      );
      expect(
        sources.single.metadata['upwardDomainHints'],
        containsAll(const <String>['business', 'locality', 'place', 'venue']),
      );
      expect(
        sources.single.metadata['upwardSignalTags'],
        containsAll(const <String>[
          'action:lessLikeThis',
          'surface:explore',
          'entity_type:spot',
        ]),
      );
    });

    test(
        'stages recommendation feedback follow-up response intake with bounded response context',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      final result =
          await service.stageRecommendationFeedbackFollowUpResponseIntake(
        ownerUserId: 'user_123',
        action: RecommendationFeedbackAction.lessLikeThis,
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_123',
          title: 'Late Night Venue',
          localityLabel: 'downtown',
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 3, 2, 0),
        sourceSurface: 'assistant_follow_up_chat',
        promptQuestion: 'What felt off about "Late Night Venue" for you?',
        promptRationale:
            'This follows an earlier lessLikeThis signal for the venue.',
        responseText: 'It was louder and busier than I wanted.',
        completionMode: 'assistant_follow_up_chat',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'recommendation_feedback_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 2, 0),
        ),
        metadata: const <String, dynamic>{
          'domains': <String>['business'],
          'signalTags': <String>[
            'domain:business',
            'feedback_action:lessLikeThis'
          ],
          'boundedContext': <String, dynamic>{
            'what': 'lessLikeThis on spot:spot_123:Late Night Venue',
            'where': 'downtown',
          },
        },
      );

      final sources = await repository.getAllSources();
      final reviews = await repository.getAllReviewItems();

      expect(result.envelope.surface, 'recommendation_feedback_follow_up');
      expect(result.envelope.channel, 'assistant_follow_up_chat');
      expect(
        result.envelope.domainHints,
        containsAll(const <String>['business', 'locality', 'place', 'venue']),
      );
      expect(reviews.single.payload['sourceKind'],
          'recommendation_feedback_follow_up_response_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'recommendation_feedback_follow_up_correction_signal',
      );
      expect(
        reviews.single.payload['completionMode'],
        'assistant_follow_up_chat',
      );
      expect(
        reviews.single.payload['responseText'],
        'It was louder and busier than I wanted.',
      );
      expect(
        sources.single.metadata['upwardSignalTags'],
        containsAll(const <String>[
          'source:recommendation_feedback_follow_up_response',
          'completion_mode:assistant_follow_up_chat',
          'feedback_action:lessLikeThis',
        ]),
      );
    });

    test('stages saved discovery curation intake with action and entity hints',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageSavedDiscoveryCurationIntake(
        ownerUserId: 'user_123',
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.list,
          id: 'list_123',
          title: 'Weekend Coffee List',
          localityLabel: 'downtown',
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 3, 12, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'saved_discovery_curation_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 12, 0),
          sanitizedPayload: const <String, dynamic>{
            'action': 'save',
            'sourceSurface': 'explore',
            'entityId': 'list_123',
            'entityType': 'list',
          },
        ),
        sourceSurface: 'explore',
        action: 'save',
        attribution: const RecommendationAttribution(
          why: 'Useful local curation shape',
          whyDetails: 'Public list with strong neighborhood fit',
          projectedEnjoyabilityPercent: 78,
          recommendationSource: 'public_lists',
          confidence: 0.79,
        ),
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'saved_discovery_curation_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'saved_discovery_positive_curation_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['list', 'locality']),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'action:save',
          'surface:explore',
          'entity_type:list',
        ]),
      );
    });

    test(
        'stages saved discovery follow-up responses into governed upward intake',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      final result = await service.stageSavedDiscoveryFollowUpResponseIntake(
        ownerUserId: 'user_saved',
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_saved',
          title: 'Night Owl Cafe',
          localityLabel: 'downtown',
        ),
        action: 'unsave',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 5, 0),
        sourceSurface: 'assistant_follow_up_chat',
        promptQuestion:
            'What changed about "Night Owl Cafe" enough for you to remove it from saved discovery?',
        promptRationale:
            'A bounded follow-up can clarify why Night Owl Cafe was removed from explore so future discovery curation stays grounded.',
        responseText:
            'It stopped matching what I actually wanted to keep around.',
        completionMode: 'assistant_follow_up_chat',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'saved_discovery_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 5, 5, 0),
        ),
        metadata: const <String, dynamic>{
          'domains': <String>['place'],
          'signalTags': <String>[
            'source:saved_discovery_follow_up_response',
            'action:unsave',
          ],
          'boundedContext': <String, dynamic>{
            'what': 'unsave on spot:spot_saved:Night Owl Cafe',
            'where': 'downtown',
          },
        },
      );

      final reviews = await repository.getAllReviewItems();
      final sources = await repository.getAllSources();

      expect(result.envelope.surface, 'saved_discovery_follow_up');
      expect(result.envelope.channel, 'assistant_follow_up_chat');
      expect(
        result.envelope.domainHints,
        containsAll(const <String>['locality', 'place']),
      );
      expect(
        reviews.single.payload['sourceKind'],
        'saved_discovery_follow_up_response_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'saved_discovery_follow_up_correction_signal',
      );
      expect(
        reviews.single.payload['completionMode'],
        'assistant_follow_up_chat',
      );
      expect(
        reviews.single.payload['responseText'],
        'It stopped matching what I actually wanted to keep around.',
      );
      expect(
        sources.single.metadata['upwardSignalTags'],
        containsAll(const <String>[
          'source:saved_discovery_follow_up_response',
          'completion_mode:assistant_follow_up_chat',
          'action:unsave',
        ]),
      );
    });

    test(
        'stages event feedback follow-up responses into governed upward intake',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      final result = await service.stageEventFeedbackFollowUpResponseIntake(
        ownerUserId: 'user_event',
        eventId: 'event_123',
        eventTitle: 'Rooftop Jazz Night',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 4, 0),
        sourceSurface: 'assistant_follow_up_chat',
        promptQuestion:
            'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
        promptRationale:
            'A bounded follow-up can clarify why Rooftop Jazz Night missed expectation after the post-event feedback signal.',
        responseText:
            'The crowding made it hard to settle into the music and stay long.',
        completionMode: 'assistant_follow_up_chat',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'event_feedback_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 5, 4, 0),
          sanitizedPayload: const <String, dynamic>{
            'eventId': 'event_123',
            'eventTitle': 'Rooftop Jazz Night',
            'promptQuestion':
                'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
            'responseText':
                'The crowding made it hard to settle into the music and stay long.',
            'sourceSurface': 'assistant_follow_up_chat',
            'completionMode': 'assistant_follow_up_chat',
          },
        ),
        metadata: const <String, dynamic>{
          'feedbackRole': 'attendee',
          'overallRating': 2.9,
          'wouldAttendAgain': false,
          'wouldRecommend': false,
          'eventCategory': 'Music',
          'localityCode': 'austin_east',
          'domains': <String>['venue'],
          'signalTags': <String>[
            'source:event_feedback_follow_up_response',
            'rating_category:venue',
          ],
          'boundedContext': <String, dynamic>{
            'what': 'event_feedback on event_123:Rooftop Jazz Night',
            'where': 'austin_east',
          },
        },
      );

      final reviews = await repository.getAllReviewItems();
      final sources = await repository.getAllSources();

      expect(result.envelope.surface, 'event_feedback_follow_up');
      expect(result.envelope.channel, 'assistant_follow_up_chat');
      expect(
        result.envelope.domainHints,
        containsAll(const <String>['community', 'event', 'locality', 'venue']),
      );
      expect(
        reviews.single.payload['sourceKind'],
        'event_feedback_follow_up_response_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'event_feedback_follow_up_correction_signal',
      );
      expect(
        reviews.single.payload['completionMode'],
        'assistant_follow_up_chat',
      );
      expect(
        reviews.single.payload['responseText'],
        'The crowding made it hard to settle into the music and stay long.',
      );
      expect(
        sources.single.metadata['upwardSignalTags'],
        containsAll(const <String>[
          'source:event_feedback_follow_up_response',
          'completion_mode:assistant_follow_up_chat',
          'role:attendee',
        ]),
      );
    });

    test('stages visit observation intake with locality hierarchy path',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final visit = Visit(
        id: 'visit_123',
        userId: 'user_123',
        locationId: 'venue_123',
        checkInTime: DateTime.utc(2026, 4, 3, 1, 0),
        checkOutTime: DateTime.utc(2026, 4, 3, 1, 42),
        dwellTime: const Duration(minutes: 42),
        qualityScore: 1.1,
        isAutomatic: true,
        isRepeatVisit: true,
        createdAt: DateTime.utc(2026, 4, 3, 1, 0),
        updatedAt: DateTime.utc(2026, 4, 3, 1, 42),
        metadata: const <String, dynamic>{
          'localityCode': 'downtown',
        },
      );

      await service.stageVisitObservationIntake(
        ownerUserId: 'user_123',
        visit: visit,
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'visit_observation_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 1, 42),
          sanitizedPayload: const <String, dynamic>{
            'triggerSource': 'geofence',
            'visitId': 'visit_123',
            'locationId': 'venue_123',
          },
        ),
        source: 'geofence',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(reviews.single.payload['sourceKind'], 'visit_observation_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'visit_behavior_confirmation',
      );
      expect(
        reviews.single.payload['hierarchyPath'],
        containsAll(
          const <String>[
            'human',
            'personal_agent',
            'locality',
            'reality_model_agent'
          ],
        ),
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['locality', 'place', 'venue']),
      );
    });

    test('stages locality observation intake from passive dwell signals',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageLocalityObservationIntake(
        ownerUserId: 'user_123',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 2, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'locality_observation_intake',
          sourceScope: 'personal_agent',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 2, 0),
          sanitizedPayload: const <String, dynamic>{
            'sourceKind': 'locality_observation_intake',
            'sensorSource': 'passive_dwell',
            'localityStableKey': 'gh7:abc1234',
          },
        ),
        sourceKind: 'passive_dwell',
        localityStableKey: 'gh7:abc1234',
        structuredSignals: const <String, dynamic>{
          'dwellDurationMinutes': 64,
          'coPresenceDetected': true,
          'placeVibeLabel': 'social_hub',
        },
        socialContext: 'social_cluster',
        activityContext: 'passive_dwell',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'locality_observation_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'locality_behavior_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['community', 'locality', 'place', 'venue']),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'source:passive_dwell',
          'activity:passive_dwell',
          'social:social_cluster',
        ]),
      );
    });

    test('stages visit/locality follow-up responses back into upward review',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageVisitLocalityFollowUpResponseIntake(
        ownerUserId: 'user_123',
        observationKind: 'visit',
        targetLabel: 'Night Owl Cafe',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 3, 0),
        sourceSurface: 'assistant_follow_up_chat',
        promptQuestion:
            'What about your visit to "Night Owl Cafe" should AVRAI remember for future place guidance?',
        promptRationale:
            'A completed visit can be strong evidence, but bounded follow-up keeps it scoped.',
        responseText:
            'It worked because I could stay there late without the room getting too loud.',
        completionMode: 'assistant_follow_up_chat',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'visit_locality_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 5, 3, 0),
          sanitizedPayload: const <String, dynamic>{
            'observationKind': 'visit',
            'targetLabel': 'Night Owl Cafe',
            'promptQuestion':
                'What about your visit to "Night Owl Cafe" should AVRAI remember for future place guidance?',
            'responseText':
                'It worked because I could stay there late without the room getting too loud.',
            'sourceSurface': 'assistant_follow_up_chat',
            'completionMode': 'assistant_follow_up_chat',
          },
        ),
        metadata: const <String, dynamic>{
          'boundedContext': <String, dynamic>{
            'where': 'downtown',
          },
          'domains': <String>['locality', 'place', 'venue'],
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'visit_locality_follow_up_response_intake',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['locality', 'place', 'venue']),
      );
      expect(
        reviews.single.payload['completionMode'],
        'assistant_follow_up_chat',
      );
    });

    test('stages community follow-up responses back into upward review',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageCommunityFollowUpResponseIntake(
        ownerUserId: 'user_community',
        followUpKind: 'community_coordination',
        targetLabel: 'Night Owls',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 4, 30),
        sourceSurface: 'assistant_follow_up_chat',
        promptQuestion:
            'What about "Night Owls" made joining feel right, and what should AVRAI remember from that?',
        promptRationale:
            'A bounded follow-up can clarify what the join action should mean before broader community learning.',
        responseText:
            'It works best for spontaneous late coffee plans with people who actually stay flexible.',
        completionMode: 'assistant_follow_up_chat',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'community_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 5, 4, 30),
          sanitizedPayload: const <String, dynamic>{
            'followUpKind': 'community_coordination',
            'targetLabel': 'Night Owls',
            'promptQuestion':
                'What about "Night Owls" made joining feel right, and what should AVRAI remember from that?',
            'responseText':
                'It works best for spontaneous late coffee plans with people who actually stay flexible.',
            'sourceSurface': 'assistant_follow_up_chat',
            'completionMode': 'assistant_follow_up_chat',
          },
        ),
        metadata: const <String, dynamic>{
          'boundedContext': <String, dynamic>{
            'where': 'atx_downtown',
            'communityName': 'Night Owls',
          },
          'domains': <String>['community', 'locality'],
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'community_follow_up_response_intake',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['community', 'locality']),
      );
      expect(
        reviews.single.payload['completionMode'],
        'assistant_follow_up_chat',
      );
    });

    test('stages business/operator input with changed field metadata',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageBusinessOperatorInputIntake(
        account: BusinessAccount(
          id: 'business_123',
          name: 'Night Owl Cafe',
          email: 'owner@nightowl.com',
          businessType: 'Restaurant',
          categories: const <String>['Coffee', 'Nightlife'],
          requiredExpertise: const <String>['Hospitality'],
          preferredCommunities: const <String>['community-nightlife'],
          location: 'downtown',
          createdAt: DateTime.utc(2026, 4, 3, 10, 0),
          updatedAt: DateTime.utc(2026, 4, 3, 11, 0),
          createdBy: 'user_owner_123',
        ),
        action: 'update',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 11, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'business_operator_input_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 11, 0),
          sanitizedPayload: const <String, dynamic>{
            'businessId': 'business_123',
            'action': 'update',
            'businessType': 'Restaurant',
          },
        ),
        changedFields: const <String>['categories', 'location'],
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'business_operator_input_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'business_operator_update_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>[
          'business',
          'community',
          'locality',
          'place',
          'venue',
        ]),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'action:update',
          'changed_field:categories',
          'changed_field:location',
          'surface:business_account',
        ]),
      );
    });

    test('stages business/operator follow-up responses back into upward review',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageBusinessOperatorFollowUpResponseIntake(
        ownerUserId: 'owner_123',
        businessId: 'business_123',
        businessName: 'Night Owl Cafe',
        action: 'update',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 5, 30),
        sourceSurface: 'business_dashboard_follow_up_queue',
        promptQuestion:
            'What about the updated location or footprint for "Night Owl Cafe" should AVRAI remember before it changes place or locality learning?',
        promptRationale:
            'A bounded follow-up can clarify what the location update should change before broader business learning.',
        responseText:
            'The new footprint matters because customers now stay longer for quieter late-night windows upstairs.',
        completionMode: 'business_in_app_follow_up_queue',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'business_operator_follow_up_response_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 5, 5, 30),
          sanitizedPayload: const <String, dynamic>{
            'businessId': 'business_123',
            'businessName': 'Night Owl Cafe',
            'action': 'update',
            'promptQuestion':
                'What about the updated location or footprint for "Night Owl Cafe" should AVRAI remember before it changes place or locality learning?',
            'responseText':
                'The new footprint matters because customers now stay longer for quieter late-night windows upstairs.',
            'sourceSurface': 'business_dashboard_follow_up_queue',
            'completionMode': 'business_in_app_follow_up_queue',
          },
        ),
        metadata: const <String, dynamic>{
          'boundedContext': <String, dynamic>{
            'where': 'atx_downtown',
            'businessType': 'Restaurant',
            'why': 'location,categories',
          },
          'domains': <String>['business', 'locality', 'place'],
          'signalTags': <String>[
            'source:business_operator_follow_up_response',
            'action:update',
          ],
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'business_operator_follow_up_response_intake',
      );
      expect(
        reviews.single.payload['completionMode'],
        'business_in_app_follow_up_queue',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['business', 'locality', 'place', 'venue']),
      );
    });

    test('stages community coordination intake with action metadata', () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageCommunityCoordinationIntake(
        community: Community(
          id: 'community_123',
          name: 'Downtown Coffee Club',
          description: 'Coffee people coordinating locally',
          category: 'Coffee',
          originatingEventId: 'event_123',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'host_123',
          memberIds: const <String>['host_123', 'user_2'],
          memberCount: 2,
          eventIds: const <String>['event_123'],
          eventCount: 1,
          memberGrowthRate: 0.2,
          eventGrowthRate: 0.1,
          createdAt: DateTime.utc(2026, 4, 3, 10, 0),
          updatedAt: DateTime.utc(2026, 4, 3, 11, 0),
          originalLocality: 'downtown',
          currentLocalities: const <String>['downtown'],
        ),
        action: 'add_member',
        actorUserId: 'user_2',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 11, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'community_coordination_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 11, 0),
          sanitizedPayload: const <String, dynamic>{
            'communityId': 'community_123',
            'action': 'add_member',
            'category': 'Coffee',
          },
        ),
        affectedRef: 'user_2',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'community_coordination_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'community_membership_positive_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['community', 'locality', 'place']),
      );
    });

    test('stages community validation intake with review metadata', () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final validation = CommunityValidation.fromCommunityMember(
        spotId: 'spot_123',
        memberId: 'validator_123',
        status: ValidationStatus.needsReview,
        feedback: 'Hours looked wrong and the place felt closed.',
        criteria: const <ValidationCriteria>[
          ValidationCriteria.locationAccuracy,
          ValidationCriteria.operatingHours,
        ],
      );

      await service.stageCommunityValidationIntake(
        validation: validation,
        occurredAtUtc: DateTime.utc(2026, 4, 3, 12, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'community_validation_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 12, 0),
          sanitizedPayload: <String, dynamic>{
            'validationId': validation.id,
            'spotId': 'spot_123',
            'status': 'needsReview',
            'level': 'community',
          },
        ),
        spotName: 'Night Owl Cafe',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'community_validation_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'community_validation_review_signal',
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'source:community_validation',
          'status:needsReview',
          'level:community',
        ]),
      );
    });

    test('stages reservation sharing intake with bounded sharing metadata',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageReservationSharingIntake(
        ownerUserId: 'user_123',
        reservation: Reservation(
          id: 'reservation_123',
          agentId: 'agent_123',
          type: ReservationType.spot,
          targetId: 'spot_123',
          reservationTime: DateTime.utc(2026, 4, 12, 19, 0),
          partySize: 2,
          ticketCount: 2,
          metadata: const <String, dynamic>{
            'cityCode': 'bham',
            'localityCode': 'downtown',
          },
          createdAt: DateTime.utc(2026, 4, 1, 12, 0),
          updatedAt: DateTime.utc(2026, 4, 1, 12, 0),
        ),
        action: 'share',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 12, 30),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'reservation_sharing_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 12, 30),
          sanitizedPayload: const <String, dynamic>{
            'reservationId': 'reservation_123',
            'targetId': 'spot_123',
            'action': 'share',
            'reservationType': 'spot',
          },
        ),
        counterpartUserId: 'user_456',
        permission: 'fullAccess',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'reservation_sharing_intake');
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_sharing_full_access_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['community', 'locality', 'place', 'venue']),
      );
    });

    test('stages reservation recurrence intake with pattern metadata',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageReservationRecurrenceIntake(
        ownerUserId: 'user_123',
        baseReservation: Reservation(
          id: 'reservation_123',
          agentId: 'agent_123',
          type: ReservationType.event,
          targetId: 'event_123',
          reservationTime: DateTime.utc(2026, 4, 12, 19, 0),
          partySize: 2,
          metadata: const <String, dynamic>{
            'cityCode': 'bham',
            'localityCode': 'downtown',
          },
          createdAt: DateTime.utc(2026, 4, 1, 12, 0),
          updatedAt: DateTime.utc(2026, 4, 1, 12, 0),
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 3, 13, 0),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'reservation_recurrence_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 13, 0),
          sanitizedPayload: const <String, dynamic>{
            'seriesId': 'series_123',
            'patternType': 'weekly',
            'interval': 1,
            'baseReservationId': 'reservation_123',
          },
        ),
        seriesId: 'series_123',
        patternType: 'weekly',
        interval: 1,
        createdReservationIds: const <String>['instance_1', 'instance_2'],
        maxOccurrences: 2,
        daysOfWeek: const <int>[5],
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'reservation_recurrence_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_recurrence_pattern_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['event', 'locality', 'venue']),
      );
    });

    test('stages reservation calendar sync intake with calendar metadata',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageReservationCalendarIntake(
        ownerUserId: 'user_123',
        reservation: Reservation(
          id: 'reservation_123',
          agentId: 'agent_123',
          type: ReservationType.business,
          targetId: 'business_123',
          reservationTime: DateTime.utc(2026, 4, 12, 19, 0),
          partySize: 4,
          calendarEventId: 'calendar_123',
          metadata: const <String, dynamic>{
            'cityCode': 'bham',
            'localityCode': 'downtown',
          },
          createdAt: DateTime.utc(2026, 4, 1, 12, 0),
          updatedAt: DateTime.utc(2026, 4, 1, 12, 0),
        ),
        occurredAtUtc: DateTime.utc(2026, 4, 3, 13, 30),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'reservation_calendar_sync_intake',
          sourceScope: 'human',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 13, 30),
          sanitizedPayload: const <String, dynamic>{
            'reservationId': 'reservation_123',
            'targetId': 'business_123',
            'calendarEventId': 'calendar_123',
            'calendarId': 'default',
          },
        ),
        calendarEventId: 'calendar_123',
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'reservation_calendar_sync_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_calendar_sync_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['business', 'locality', 'place']),
      );
    });

    test('stages supervisor bounded observations with caller-issued air gap',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageSupervisorAssistantObservationIntake(
        observerId: 'supervisor:atx-replay-world-2024',
        observerKind: 'supervisor',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 14, 0),
        summary:
            'Repeated negative validation outcomes suggest this lane should remain held for corroboration.',
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'supervisor_bounded_observation_intake',
          sourceScope: 'supervisor',
          originPlane: 'supervisor_daemon',
          issuedAtUtc: DateTime.utc(2026, 4, 3, 14, 0),
          sanitizedPayload: const <String, dynamic>{
            'environmentId': 'atx-replay-world-2024',
            'observationKind': 'validation_review',
            'summary':
                'Repeated negative validation outcomes suggest this lane should remain held for corroboration.',
          },
        ),
        environmentId: 'atx-replay-world-2024',
        cityCode: 'atx',
        observationKind: 'validation_review',
        upwardDomainHints: const <String>['simulation', 'validation'],
        upwardReferencedEntities: const <String>[
          'reality_model_update_validation_simulation_outcome.json',
        ],
        upwardQuestions: const <String>[
          'Should this lane remain held until a fresh corroborating simulation succeeds?',
        ],
        upwardSignalTags: const <String>['status:held_for_corroboration'],
        boundedMetadata: const <String, dynamic>{
          'validationStatus': 'needs_more_evidence',
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'supervisor_bounded_observation_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'supervisor_bounded_observation_signal',
      );
      expect(
        reviews.single.payload['hierarchyPath'],
        containsAll(const <String>['supervisor', 'reality_model_agent']),
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['simulation', 'supervisor', 'validation']),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'source:supervisor',
          'observation_kind:validation_review',
          'status:held_for_corroboration',
        ]),
      );
    });

    test('stages kernel/offline evidence receipts with caller-issued air gap',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageKernelOfflineEvidenceReceiptIntake(
        ownerUserId: 'user_123',
        receipt: KernelOfflineEvidenceReceipt(
          receiptId: 'receipt_kernel_offline_123',
          receiptKind: 'activation_receipt',
          sourceSystem: 'urk_runtime_activation_receipt_dispatcher',
          sourcePlane: 'offline_kernel',
          observedAtUtc: DateTime.utc(2026, 4, 4, 1, 0),
          kernelId: 'k_activation',
          requestId: 'req-42',
          lineageRef: 'activation:req-42',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          localityCode: 'downtown',
          actorScope: 'kernel',
          boundedEvidence: const <String, dynamic>{
            'activated': true,
            'reason': 'user_runtime_learning_intake_accepted',
          },
          temporalLineage: const <String, dynamic>{
            'originOccurredAtUtc': '2026-04-04T01:00:00.000Z',
            'syncObservedAtUtc': '2026-04-04T01:03:00.000Z',
          },
          signalTags: const <String>[
            'privacy_mode:local_sovereign',
            'runtime_lane:user_runtime',
          ],
        ),
        airGapArtifact: issueTestAirGapArtifact(
          sourceKind: 'kernel_offline_evidence_receipt_intake',
          sourceScope: 'kernel',
          originPlane: 'offline_kernel',
          issuedAtUtc: DateTime.utc(2026, 4, 4, 1, 3),
          sanitizedPayload: const <String, dynamic>{
            'receiptId': 'receipt_kernel_offline_123',
            'receiptKind': 'activation_receipt',
            'sourceSystem': 'urk_runtime_activation_receipt_dispatcher',
          },
        ),
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'kernel_offline_evidence_receipt_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'kernel_offline_evidence_receipt_signal',
      );
      expect(
        reviews.single.payload['hierarchyPath'],
        containsAll(const <String>['kernel', 'reality_model_agent']),
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['kernel', 'locality', 'offline']),
      );
      expect(
        reviews.single.payload['upwardSignalTags'],
        containsAll(const <String>[
          'source:kernel_offline_evidence_receipt',
          'receipt_kind:activation_receipt',
          'source_system:urk_runtime_activation_receipt_dispatcher',
          'source_plane:offline_kernel',
          'privacy_mode:local_sovereign',
        ]),
      );
    });

    test('stages external confirmation/import intake with source metadata',
        () async {
      final repository = UniversalIntakeRepository();
      final service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      await service.stageExternalConfirmationIntake(
        source: ExternalSourceDescriptor(
          id: 'source_123',
          ownerUserId: 'user_123',
          sourceProvider: 'calendar',
          sourceUrl: 'https://example.com/feed.ics',
          connectionMode: ExternalConnectionMode.feed,
          entityHint: IntakeEntityType.event,
          sourceLabel: 'Neighborhood Calendar',
          cityCode: 'us-bhm',
          localityCode: 'downtown',
          createdAt: DateTime.utc(2026, 4, 1),
          updatedAt: DateTime.utc(2026, 4, 1),
        ),
        metadata: ExternalSyncMetadata(
          sourceProvider: 'calendar',
          sourceUrl: 'https://example.com/feed.ics',
          externalId: 'evt_456',
          syncState: ExternalSyncState.active,
          connectionMode: ExternalConnectionMode.feed,
          importedAt: DateTime.utc(2026, 4, 3, 14, 0),
          lastSyncedAt: DateTime.utc(2026, 4, 3, 14, 0),
          ownerUserId: 'user_123',
          cityCode: 'us-bhm',
          localityCode: 'downtown',
          sourceLabel: 'Neighborhood Calendar',
        ),
        entityType: IntakeEntityType.event,
        entityId: 'imported_event_evt_456',
        occurredAtUtc: DateTime.utc(2026, 4, 3, 14, 0),
        action: 'materialized_import',
        boundedPayload: const <String, dynamic>{
          'candidateTitle': 'Neighborhood Run Club',
          'category': 'Fitness',
        },
      );

      final reviews = await repository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'external_confirmation_import_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'external_import_confirmation_signal',
      );
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(const <String>['event', 'locality']),
      );
    });
  });
}
