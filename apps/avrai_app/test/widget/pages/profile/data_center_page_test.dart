import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/profile/data_center_page.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat, StorageService;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('DataCenterPage Widget Tests', () {
    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    testWidgets('shows governed learning records and control context',
        (WidgetTester tester) async {
      final mintedAtUtc = DateTime.now().toUtc();
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
        occurredAtUtc: DateTime.utc(2026, 4, 4, 4),
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
          'accepted': true,
          'learning_allowed': true,
        },
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: mintedAtUtc,
          sanitizedPayload: <String, dynamic>{
            'chatId': 'chat_123',
            'messageId': 'message_123',
            'sourceOccurredAtUtc': '2026-04-04T04:00:00.000Z',
          },
          pseudonymousActorRef: 'anon_user',
        ),
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(projectionService: projectionService),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Data Center'), findsWidgets);
      expect(find.text('Governed Learning'), findsOneWidget);
      expect(
        find.textContaining('The user wants a quieter weeknight plan.'),
        findsWidgets,
      );
      expect(find.text('Latest summary'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recent records'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recent records'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('shows onboarding follow-up queue and completes a plan',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'data_center_onboarding_queue_prefs'),
      );
      final planner = OnboardingFollowUpPromptPlannerService(
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

      await planner.createPlan(
        ownerUserId: 'user_123',
        onboardingData: OnboardingData(
          agentId: 'agent_onboarding',
          homebase: 'Austin, TX',
          favoritePlaces: const <String>['Quiet cafe'],
          preferences: const <String, List<String>>{
            'Food & Drink': <String>['Coffee'],
          },
          completedAt: DateTime.utc(2026, 4, 5, 4),
          questionnaireVersion: 'v3',
        ),
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(
              projectionService: UserGovernedLearningProjectionService(
                intakeRepository: UniversalIntakeRepository(),
              ),
              onboardingFollowUpPlannerService: planner,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Onboarding follow-up queue'), findsOneWidget);
      expect(find.textContaining('Austin, TX'), findsWidgets);

      await tester.tap(find.text('Answer now').first);
      await tester.pumpAndSettle();

      expect(find.text('Onboarding follow-up'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Keep my Austin homebase durable, but treat nightlife preferences as exploratory.',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Onboarding follow-up queue'), findsNothing);
      final responses = await planner.listResponses('user_123');
      expect(responses, hasLength(1));
    });

    testWidgets('shows adoption state chips and surfaced timing',
        (WidgetTester tester) async {
      final repository = UniversalIntakeRepository();
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final intakeService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        adoptionService: adoptionService,
        observationService: observationService,
      );

      final accepted = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_accepted',
        messageId: 'message_accepted',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 1),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants calmer coffee seating.',
          'sanitized_summary': 'The user wants calmer coffee seating.',
          'accepted': true,
          'learning_allowed': true,
        },
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: DateTime.now().toUtc(),
          sanitizedPayload: <String, dynamic>{
            'chatId': 'chat_accepted',
            'messageId': 'message_accepted',
          },
          pseudonymousActorRef: 'anon_user',
        ),
      );
      final queued = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_queued',
        messageId: 'message_queued',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user wants louder nightlife scenes.',
          'sanitized_summary': 'The user wants louder nightlife scenes.',
          'accepted': true,
          'learning_allowed': true,
        },
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: DateTime.now().toUtc(),
          sanitizedPayload: <String, dynamic>{
            'chatId': 'chat_queued',
            'messageId': 'message_queued',
          },
          pseudonymousActorRef: 'anon_user',
        ),
      );
      final surfaced = await intakeService.stagePersonalAgentHumanIntake(
        ownerUserId: 'user_123',
        actorAgentId: 'agent_123',
        chatId: 'chat_surfaced',
        messageId: 'message_surfaced',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
        boundaryMetadata: const <String, dynamic>{
          'summary': 'The user likes live music events downtown.',
          'sanitized_summary': 'The user likes live music events downtown.',
          'accepted': true,
          'learning_allowed': true,
        },
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: DateTime.now().toUtc(),
          sanitizedPayload: <String, dynamic>{
            'chatId': 'chat_surfaced',
            'messageId': 'message_surfaced',
          },
          pseudonymousActorRef: 'anon_user',
        ),
      );

      await adoptionService.recordReceipts([
        GovernedLearningAdoptionReceipt(
          id: 'accepted_only',
          ownerUserId: 'user_123',
          envelopeId: accepted.envelope.id,
          sourceId: accepted.sourceId,
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 1, 5),
          reason: 'accepted',
        ),
        GovernedLearningAdoptionReceipt(
          id: 'queued_events',
          ownerUserId: 'user_123',
          envelopeId: queued.envelope.id,
          sourceId: queued.sourceId,
          status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 2, 5),
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          reason: 'queued',
        ),
        GovernedLearningAdoptionReceipt(
          id: 'surfaced_events',
          ownerUserId: 'user_123',
          envelopeId: surfaced.envelope.id,
          sourceId: surfaced.sourceId,
          status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 3, 30),
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          targetEntityId: 'event_123',
          targetEntityType: 'event',
          targetEntityTitle: 'Downtown Live Set',
          reason: 'surfaced',
        ),
      ]);
      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'governance_surface_obs',
          ownerUserId: 'user_123',
          envelopeId: surfaced.envelope.id,
          sourceId: surfaced.sourceId,
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 3, 35),
          chatId: 'chat_surfaced',
          userMessageId: 'message_surfaced',
          governanceStatus: GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance,
          governanceUpdatedAtUtc: DateTime.utc(2026, 4, 4, 3, 40),
          governanceStage: 'reality_model_truth_review',
          governanceReason: 'Promoted into bounded update candidate.',
        ),
      ]);
      final projectedRecords = await projectionService.listVisibleRecords(
        ownerUserId: 'user_123',
      );
      expect(projectedRecords, hasLength(3));
      expect(
        projectedRecords
            .where(
              (record) =>
                  record.currentAdoptionStatus ==
                  GovernedLearningAdoptionStatus.acceptedForLearning,
            )
            .single
            .pendingSurfaces,
        isEmpty,
      );
      expect(
        projectedRecords
            .where(
              (record) =>
                  record.currentAdoptionStatus ==
                  GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
            )
            .single
            .pendingSurfaces,
        contains('events_personalized'),
      );
      expect(
        projectedRecords
            .where(
              (record) =>
                  record.currentAdoptionStatus ==
                  GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
            )
            .single
            .firstSurfacedAtUtc,
        isNotNull,
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Material(
              child: DataCenterPage(projectionService: projectionService),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Recent records'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recent records'), findsOneWidget);
      expect(
        projectedRecords
            .where((record) => record.recentChatObservations.isNotEmpty)
            .single
            .recentChatObservations
            .single
            .governanceStatus,
        GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance,
      );
    });

    testWidgets('shows correction follow-up queue and completes a plan',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'data_center_correction_queue_prefs'),
      );
      final planner =
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

      await planner.createPlan(
        ownerUserId: 'user_123',
        targetEnvelopeId: 'env_123',
        targetSourceId: 'src_123',
        targetSummary: 'The user wants a quieter weeknight plan.',
        correctionText: 'Actually I only mean that on weekdays.',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 4),
        sourceSurface: 'data_center_correction',
        domainHints: const <String>['place'],
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(
              projectionService: UserGovernedLearningProjectionService(
                intakeRepository: UniversalIntakeRepository(),
              ),
              correctionFollowUpPlannerService: planner,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Correction follow-up queue'), findsOneWidget);
      expect(
        find.textContaining(
          'Should I treat your correction about "The user wants a quieter weeknight plan." as durable',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Answer now'));
      await tester.pumpAndSettle();

      expect(find.text('Correction follow-up'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Only when I am planning a worknight and need somewhere calmer.',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Correction follow-up queue'), findsNothing);
      final responses = await planner.listResponses('user_123');
      expect(responses, hasLength(1));
      expect(
        responses.single.responseText,
        'Only when I am planning a worknight and need somewhere calmer.',
      );
    });

    testWidgets('shows visit/locality follow-up queue and completes a plan',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'data_center_behavior_queue_prefs'),
      );
      final planner = VisitLocalityFollowUpPromptPlannerService(
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

      await planner.createLocalityPlan(
        ownerUserId: 'user_123',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 5),
        sourceKind: 'passive_dwell',
        localityStableKey: 'gh7:abc1234',
        structuredSignals: const <String, dynamic>{
          'dwellDurationMinutes': 52,
        },
        socialContext: 'social_cluster',
        activityContext: 'passive_dwell',
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(
              projectionService: UserGovernedLearningProjectionService(
                intakeRepository: UniversalIntakeRepository(),
              ),
              visitLocalityFollowUpPlannerService: planner,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Visit and locality follow-up queue'), findsOneWidget);
      expect(
        find.textContaining(
          'What was going on around "gh7:abc1234" that should shape future locality guidance?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Answer now'));
      await tester.pumpAndSettle();

      expect(find.text('Behavior follow-up'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'That area works when I want somewhere social enough to linger without planning a full event.',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Visit and locality follow-up queue'), findsNothing);
      final responses = await planner.listResponses('user_123');
      expect(responses, hasLength(1));
    });

    testWidgets('supports dont-ask-again on visit/locality follow-up queue',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'data_center_behavior_dont_ask_again_prefs',
        ),
      );
      final planner = VisitLocalityFollowUpPromptPlannerService(
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

      final plan = await planner.createLocalityPlan(
        ownerUserId: 'user_123',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 5),
        sourceKind: 'passive_dwell',
        localityStableKey: 'gh7:abc1234',
        structuredSignals: const <String, dynamic>{
          'dwellDurationMinutes': 52,
        },
        socialContext: 'social_cluster',
        activityContext: 'passive_dwell',
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(
              projectionService: UserGovernedLearningProjectionService(
                intakeRepository: UniversalIntakeRepository(),
              ),
              visitLocalityFollowUpPlannerService: planner,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Visit and locality follow-up queue'), findsOneWidget);
      await tester.tap(find.text("Don't ask again"));
      await tester.pumpAndSettle();

      expect(find.text('Visit and locality follow-up queue'), findsNothing);
      final updatedPlan = (await planner.listPlans('user_123'))
          .firstWhere((candidate) => candidate.planId == plan.planId);
      expect(updatedPlan.status, 'dont_ask_again_local_bounded_follow_up');
    });

    testWidgets('shows community follow-up queue and completes a plan',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'data_center_community_queue_prefs'),
      );
      final planner = CommunityFollowUpPromptPlannerService(
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

      await planner.createCoordinationPlan(
        community: Community(
          id: 'community_123',
          name: 'Night Owls',
          description: 'Late-night community',
          category: 'social',
          originatingEventId: 'event_123',
          originatingEventType: OriginatingEventType.communityEvent,
          memberIds: const <String>['user_123'],
          memberCount: 1,
          founderId: 'founder_1',
          eventIds: const <String>[],
          eventCount: 0,
          memberGrowthRate: 0,
          eventGrowthRate: 0,
          createdAt: DateTime.utc(2026, 4, 5, 4),
          lastEventAt: null,
          engagementScore: 0.2,
          diversityScore: 0.1,
          activityLevel: ActivityLevel.active,
          originalLocality: 'Downtown',
          currentLocalities: const <String>['Downtown'],
          localityCode: 'atx_downtown',
          updatedAt: DateTime.utc(2026, 4, 5, 4, 5),
        ),
        action: 'add_member',
        actorUserId: 'user_123',
        affectedRef: 'user_123',
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );
      final widget = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Material(
            child: DataCenterPage(
              projectionService: UserGovernedLearningProjectionService(
                intakeRepository: UniversalIntakeRepository(),
              ),
              communityFollowUpPlannerService: planner,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Community follow-up queue'), findsOneWidget);
      expect(
        find.textContaining(
          'What about "Night Owls" made joining feel right',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Answer now'));
      await tester.pumpAndSettle();

      expect(find.text('Community follow-up'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'It works when people want something social but still flexible.',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Community follow-up queue'), findsNothing);
      final responses = await planner.listResponses('user_123');
      expect(responses, hasLength(1));
    });

    testWidgets('shows recent recommendation feedback context in the ledger',
        (WidgetTester tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'data_center_feedback_prefs'),
      );
      final repository = UniversalIntakeRepository();
      final upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
      );
      final feedbackService = RecommendationFeedbackService(
        prefs: prefs,
        governedUpwardLearningIntakeService: upwardService,
      );

      await feedbackService.submitFeedback(
        userId: 'user_123',
        entity: const DiscoveryEntityReference(
          type: DiscoveryEntityType.list,
          id: 'list_456',
          title: 'Late Night Rooms',
          routePath: '/list/list_456',
          localityLabel: 'austin_downtown',
        ),
        action: RecommendationFeedbackAction.dismiss,
        sourceSurface: 'explore_discovery',
        attribution: const RecommendationAttribution(
          why:
              'A recent signal that you prefer louder late-night spots boosted this recommendation',
          whyDetails: 'Built from nightlife place signals near your homebase',
          projectedEnjoyabilityPercent: 81,
          recommendationSource: 'spot_discovery_lane',
          confidence: 0.78,
        ),
      );

      final authBloc = MockAuthBloc()
        ..setState(
          Authenticated(
            user: User(
              id: 'user_123',
              email: 'user_123@example.com',
              name: 'Test User',
              displayName: 'Test User',
              role: UserRole.user,
              createdAt: DateTime.utc(2026, 4, 4),
              updatedAt: DateTime.utc(2026, 4, 4),
            ),
          ),
        );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Material(
              child: DataCenterPage(
                projectionService: projectionService,
                feedbackService: feedbackService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Center'), findsWidgets);
      expect(find.text('Governed Learning'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Recent recommendation feedback'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recent recommendation feedback'), findsOneWidget);
      expect(find.text('Late Night Rooms'), findsOneWidget);
      expect(
        find.textContaining(
          'A recent signal that you prefer louder late-night spots boosted this recommendation',
        ),
        findsOneWidget,
      );
      expect(find.text('Open recommendation'), findsOneWidget);
      expect(find.text('Jump to related record'), findsOneWidget);
    });
  });
}
