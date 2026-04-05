import 'package:avrai/presentation/models/daily_serendipity_drop.dart';
import 'package:avrai/presentation/pages/feed/daily_serendipity_drop_feed.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  testWidgets('shows learning context affordance on daily drop cards',
      (WidgetTester tester) async {
    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: DailySerendipityDropFeed(
          drop: _testDrop(),
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Night Shift Cafe'), findsOneWidget);
    expect(find.text('Learning context'), findsWidgets);
  });
}

DailySerendipityDrop _testDrop() {
  const attribution = RecommendationAttribution(
    why: 'A recent governed-learning signal helped boost this recommendation',
    whyDetails:
        'It stayed high because recent corrections kept reinforcing this style of recommendation',
    projectedEnjoyabilityPercent: 84,
    recommendationSource: 'daily_drop_lane',
    confidence: 0.82,
  );

  return DailySerendipityDrop(
    date: DateTime.utc(2026, 4, 5),
    cityName: 'Austin',
    llmContextualInsight:
        'Today skews toward lively evening doors and a calmer coffee reset.',
    generatedAtUtc: DateTime.utc(2026, 4, 5, 8),
    expiresAtUtc: DateTime.utc(2026, 4, 6, 8),
    refreshReason: 'scheduled_refresh',
    spot: DropSpot(
      id: 'spot_drop_1',
      title: 'Night Shift Cafe',
      subtitle: 'Late coffee and pastries',
      archetypeAffinity: 0.81,
      objectRef: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_drop_1',
        title: 'Night Shift Cafe',
        routePath: '/spot/spot_drop_1',
        localityLabel: 'austin_downtown',
      ),
      attribution: attribution,
      category: 'Coffee shop',
      distanceMiles: 1.2,
    ),
    list: DropList(
      id: 'list_drop_1',
      title: 'Late-night resets',
      subtitle: 'A calmer post-midnight shortlist',
      archetypeAffinity: 0.74,
      objectRef: const DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_drop_1',
        title: 'Late-night resets',
        routePath: '/lists/list_drop_1',
        localityLabel: 'austin_downtown',
      ),
      attribution: attribution,
      itemCount: 5,
      curatorNote: 'A saved list for quieter after-hours recovery.',
    ),
    event: DropEvent(
      id: 'event_drop_1',
      title: 'Austin After Dark',
      subtitle: 'Live set and crowded dance floor',
      archetypeAffinity: 0.88,
      objectRef: const DiscoveryEntityReference(
        type: DiscoveryEntityType.event,
        id: 'event_drop_1',
        title: 'Austin After Dark',
        routePath: '/events/event_drop_1',
        localityLabel: 'austin_downtown',
      ),
      attribution: attribution,
      time: DateTime.utc(2026, 4, 5, 23),
      locationName: 'Warehouse District',
    ),
    club: DropClub(
      id: 'club_drop_1',
      title: 'Night Logic Club',
      subtitle: 'Member-led after-hours scene',
      archetypeAffinity: 0.69,
      objectRef: const DiscoveryEntityReference(
        type: DiscoveryEntityType.club,
        id: 'club_drop_1',
        title: 'Night Logic Club',
        routePath: '/clubs/club_drop_1',
        localityLabel: 'austin_downtown',
      ),
      attribution: attribution,
      applicationStatus: 'Open',
      vibe: 'Bold, social, and late',
    ),
    community: DropCommunity(
      id: 'community_drop_1',
      title: 'After Hours Collective',
      subtitle: 'People comparing late-night city rituals',
      archetypeAffinity: 0.72,
      objectRef: const DiscoveryEntityReference(
        type: DiscoveryEntityType.community,
        id: 'community_drop_1',
        title: 'After Hours Collective',
        routePath: '/communities/community_drop_1',
        localityLabel: 'austin_downtown',
      ),
      attribution: attribution,
      memberCount: 128,
      commonInterests: const <String>['Nightlife', 'Coffee', 'Live music'],
    ),
  );
}
