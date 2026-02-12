import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/communities/communities_discover_page.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for CommunitiesDiscoverPage
///
/// Focus: discover rendering + join action updates.
void main() {
  group('CommunitiesDiscoverPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    late CommunityService communityService;

    setUp(() async {
      mockAuthBloc = MockAuthBloc();
      mockAuthBloc.setState(
        Authenticated(user: WidgetTestHelpers.createTestUserForAuth(id: 'u1')),
      );

      // Register a real CommunityService instance for the page to resolve.
      if (GetIt.instance.isRegistered<CommunityService>()) {
        GetIt.instance.unregister<CommunityService>();
      }
      communityService = CommunityService();
      GetIt.instance.registerSingleton<CommunityService>(communityService);

      // Seed a community that the user is not yet a member of.
      await communityService.upsertCommunity(
        Community(
          id: 'c1',
          name: 'Test Community',
          description: 'A community for testing',
          category: 'Test',
          originatingEventId: 'e1',
          originatingEventType: OriginatingEventType.expertiseEvent,
          memberIds: const [],
          memberCount: 0,
          founderId: 'founder',
          eventIds: const [],
          eventCount: 0,
          memberGrowthRate: 0.0,
          eventGrowthRate: 0.0,
          createdAt: DateTime.now(),
          lastEventAt: null,
          engagementScore: 0.0,
          diversityScore: 0.0,
          activityLevel: ActivityLevel.active,
          originalLocality: 'Testville',
          currentLocalities: const ['Testville'],
          updatedAt: DateTime.now(),
          vibeCentroidDimensions: null,
          vibeCentroidContributors: 0,
        ),
      );
    });

    tearDown(() {
      if (GetIt.instance.isRegistered<CommunityService>()) {
        GetIt.instance.unregister<CommunityService>();
      }
    });

    testWidgets('renders discover list and join removes community',
        (WidgetTester tester) async {
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CommunitiesDiscoverPage(),
        authBloc: mockAuthBloc,
      );
      await tester.pumpWidget(widget);

      // Allow async load to run.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));

      // Community card shows up.
      expect(find.text('Test Community'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);

      // Tap Join.
      await tester.tap(find.text('Join'));
      await tester.pump(const Duration(milliseconds: 50));

      // After join completes, the card is removed from the list.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Test Community'), findsNothing);
    });
  });
}

