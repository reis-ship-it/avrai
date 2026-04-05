import 'package:avrai/presentation/pages/explore/explore_page.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/explore_discovery_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

final _testPromptPolicyService = BoundedFollowUpPromptPolicyService(
  policy: BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay: 10,
    quietHoursStartHour: 0,
    quietHoursEndHour: 0,
    suggestionFamilyCooldown: Duration(seconds: 1),
    eventFamilyCooldown: Duration(seconds: 1),
  ),
);

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  testWidgets('shows bounded in-app follow-up queue and completes a plan',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'explore_follow_up_queue_prefs'),
    );
    final planner = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final feedbackService = RecommendationFeedbackService(
      prefs: prefs,
      promptPlannerService: planner,
    );

    await planner.createPlan(
      ownerUserId: 'test-user-id',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_queue',
        title: 'Heatwave Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 12, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why: 'Matches your current coffee and remote-work pattern',
        whyDetails: 'It ranked because you kept saving indoor daytime places',
        projectedEnjoyabilityPercent: 79,
        recommendationSource: 'place_intelligence_lane',
        confidence: 0.8,
      ),
      metadata: const <String, dynamic>{
        'domains': <String>['place', 'coffee'],
      },
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: ExplorePage(
          feedbackService: feedbackService,
          feedbackPromptPlannerService: planner,
          loadExploreOverride: (UnifiedUser user) async {
            return const ExploreDiscoveryResult(
              byType: <DiscoveryEntityType, List<ExploreDiscoveryItem>>{
                DiscoveryEntityType.spot: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.list: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.event: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.club: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.community: <ExploreDiscoveryItem>[],
              },
            );
          },
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Follow-up queue'), findsOneWidget);
    expect(
      find.textContaining(
        'What felt off about "Heatwave Cafe" for you right then?',
      ),
      findsOneWidget,
    );
    expect(find.text('Answer now'), findsOneWidget);

    await tester.tap(find.text('Answer now'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up question'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'It seemed too busy and louder than I wanted.',
    );
    await WidgetTestHelpers.safePumpAndSettle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up queue'), findsNothing);
    expect(
      find.textContaining('No spots are ready right now.'),
      findsOneWidget,
    );

    final pendingPlans = await planner.listPendingPlans('test-user-id');
    final responses = await planner.listResponses('test-user-id');
    expect(pendingPlans, isEmpty);
    expect(responses, hasLength(1));
    expect(
      responses.single.responseText,
      'It seemed too busy and louder than I wanted.',
    );
  });

  testWidgets('shows saved-item follow-up queue and completes a plan',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'explore_saved_follow_up_queue_prefs'),
    );
    final planner = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    await planner.createPlan(
      ownerUserId: 'test-user-id',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_saved_queue',
        title: 'Night Owl Cafe',
        localityLabel: 'birmingham_downtown',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 12, 0),
      sourceSurface: 'explore',
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: ExplorePage(
          savedDiscoveryFollowUpPlannerService: planner,
          loadExploreOverride: (UnifiedUser user) async {
            return const ExploreDiscoveryResult(
              byType: <DiscoveryEntityType, List<ExploreDiscoveryItem>>{
                DiscoveryEntityType.spot: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.list: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.event: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.club: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.community: <ExploreDiscoveryItem>[],
              },
            );
          },
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Saved-item follow-up queue'), findsOneWidget);
    expect(
      find.textContaining('What made "Night Owl Cafe" worth saving for later?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Answer now'));
    await WidgetTestHelpers.safePumpAndSettle(tester);
    expect(find.text('Saved-item follow-up'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'It looked like a place I would actually keep coming back to.',
    );
    await WidgetTestHelpers.safePumpAndSettle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Saved-item follow-up queue'), findsNothing);
    final responses = await planner.listResponses('test-user-id');
    expect(responses, hasLength(1));
    expect(
      responses.single.responseText,
      'It looked like a place I would actually keep coming back to.',
    );
  });

  testWidgets('supports dont-ask-again on the bounded in-app follow-up queue',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'explore_follow_up_dont_ask_again_prefs',
      ),
    );
    final planner = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await planner.createPlan(
      ownerUserId: 'test-user-id',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_queue_block',
        title: 'Heatwave Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 12, 0),
      sourceSurface: 'explore',
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: ExplorePage(
          feedbackPromptPlannerService: planner,
          loadExploreOverride: (UnifiedUser user) async {
            return const ExploreDiscoveryResult(
              byType: <DiscoveryEntityType, List<ExploreDiscoveryItem>>{
                DiscoveryEntityType.spot: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.list: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.event: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.club: <ExploreDiscoveryItem>[],
                DiscoveryEntityType.community: <ExploreDiscoveryItem>[],
              },
            );
          },
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);
    expect(find.text('Follow-up queue'), findsOneWidget);

    await tester.tap(find.text("Don't ask again").first);
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up queue'), findsNothing);
    final updatedPlan = (await planner.listPlans('test-user-id'))
        .firstWhere((candidate) => candidate.planId == plan.planId);
    expect(updatedPlan.status, 'dont_ask_again_local_bounded_follow_up');
  });

  testWidgets('shows learning context affordance on recommendation cards',
      (WidgetTester tester) async {
    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: ExplorePage(
          loadExploreOverride: (UnifiedUser user) async {
            return ExploreDiscoveryResult(
              byType: <DiscoveryEntityType, List<ExploreDiscoveryItem>>{
                DiscoveryEntityType.spot: const <ExploreDiscoveryItem>[
                  ExploreDiscoveryItem(
                    entity: DiscoveryEntityReference(
                      type: DiscoveryEntityType.spot,
                      id: 'spot_context',
                      title: 'Night Shift Cafe',
                      routePath: '/spot/spot_context',
                      localityLabel: 'austin_downtown',
                    ),
                    attribution: RecommendationAttribution(
                      why:
                          'A recent signal that you prefer quieter coffee spots helped boost this spot',
                      whyDetails:
                          'It ranked because your recent coffee signals kept favoring calmer late-evening places',
                      projectedEnjoyabilityPercent: 82,
                      recommendationSource: 'spot_discovery_lane',
                      confidence: 0.79,
                    ),
                    title: 'Night Shift Cafe',
                    subtitle: 'Coffee shop',
                    scoreLabel: '82%',
                    score: 0.82,
                    isLiveNow: false,
                    isSaved: false,
                    canRenderOnMap: false,
                  ),
                ],
                DiscoveryEntityType.list: const <ExploreDiscoveryItem>[],
                DiscoveryEntityType.event: const <ExploreDiscoveryItem>[],
                DiscoveryEntityType.club: const <ExploreDiscoveryItem>[],
                DiscoveryEntityType.community: const <ExploreDiscoveryItem>[],
              },
            );
          },
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Night Shift Cafe'), findsOneWidget);
    expect(find.text('Learning context'), findsOneWidget);
  });
}
