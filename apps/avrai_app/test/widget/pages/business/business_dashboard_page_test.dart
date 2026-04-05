import 'package:avrai/presentation/pages/business/business_dashboard_page.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_auth_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/model_factories.dart';
import '../../../helpers/platform_channel_helper.dart';
import '../../helpers/widget_test_helpers.dart';

class _FakeBusinessAuthService extends BusinessAuthService {
  _FakeBusinessAuthService({
    required this.businessId,
    required SharedPreferencesCompat prefs,
  }) : super(prefs);

  final String businessId;

  @override
  bool isAuthenticated() => true;

  @override
  String? getCurrentBusinessId() => businessId;
}

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  testWidgets('shows bounded business follow-up queue on dashboard',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'business_dashboard_page_test_prefs'),
    );
    final plannerService = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
    );
    final businessService = BusinessAccountService();
    final creator = ModelFactories.createTestUser(
      id: 'owner_123',
      email: 'owner@nightowl.com',
      displayName: 'Night Owl Owner',
      tags: const <String>['business_owner'],
    );
    final business = await businessService.createBusinessAccount(
      creator: creator,
      name: 'Night Owl Cafe',
      email: 'owner@nightowl.com',
      businessType: 'Restaurant',
      location: 'downtown',
      categories: const <String>['Coffee'],
    );
    await plannerService.createPlan(
      account: business,
      action: 'update',
      occurredAtUtc: business.updatedAt.toUtc(),
      changedFields: const <String>['location'],
    );
    final authService = _FakeBusinessAuthService(
      businessId: business.id,
      prefs: prefs,
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      child: BusinessDashboardPage(
        businessAuthService: authService,
        businessAccountService: businessService,
        businessFollowUpPlannerService: plannerService,
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Business follow-up queue'), findsOneWidget);
    expect(
      find.textContaining(
        'What about the updated location or footprint for "Night Owl Cafe"',
      ),
      findsOneWidget,
    );
    expect(find.text('Answer now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('supports dont-ask-again on the business follow-up queue',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'business_dashboard_page_dont_ask_again_prefs',
      ),
    );
    final plannerService = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
    );
    final businessService = BusinessAccountService();
    final creator = ModelFactories.createTestUser(
      id: 'owner_123',
      email: 'owner@nightowl.com',
      displayName: 'Night Owl Owner',
      tags: const <String>['business_owner'],
    );
    final business = await businessService.createBusinessAccount(
      creator: creator,
      name: 'Night Owl Cafe',
      email: 'owner@nightowl.com',
      businessType: 'Restaurant',
      location: 'downtown',
      categories: const <String>['Coffee'],
    );
    final plan = await plannerService.createPlan(
      account: business,
      action: 'update',
      occurredAtUtc: business.updatedAt.toUtc(),
      changedFields: const <String>['location'],
    );
    final authService = _FakeBusinessAuthService(
      businessId: business.id,
      prefs: prefs,
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      child: BusinessDashboardPage(
        businessAuthService: authService,
        businessAccountService: businessService,
        businessFollowUpPlannerService: plannerService,
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);
    expect(find.text('Business follow-up queue'), findsOneWidget);

    final dontAskAgainButton = find.widgetWithText(
      TextButton,
      "Don't ask again",
    );
    await tester.ensureVisible(dontAskAgainButton);
    await tester.tap(dontAskAgainButton);
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Business follow-up queue'), findsNothing);
    final updatedPlan = (await plannerService.listPlans(business.ownerId))
        .firstWhere((candidate) => candidate.planId == plan.planId);
    expect(updatedPlan.status, 'dont_ask_again_local_bounded_follow_up');
  });
}
