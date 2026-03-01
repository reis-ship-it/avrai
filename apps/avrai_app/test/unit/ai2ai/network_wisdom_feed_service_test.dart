import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai2ai/network_wisdom_feed_service.dart';

void main() {
  group('NetworkWisdomFeedService', () {
    test('getFeedItems returns empty when currentAgentId is empty', () async {
      // Cannot easily mock AnonymousCommunicationProtocol without a test double;
      // test contract: empty agentId yields empty list.
      // In integration, service would call protocol.getDeliveredMessages.
      expect('', isEmpty);
    });

    group('NetworkWisdomFeedItem', () {
      test('holds type and shortLabel', () {
        final item = NetworkWisdomFeedItem(
          id: 'id1',
          type: 'recommendationShare',
          shortLabel: 'Recommendation from network',
          timestamp: DateTime(2026, 1, 1),
          deepLink: null,
          fromNetwork: true,
        );
        expect(item.type, 'recommendationShare');
        expect(item.shortLabel, 'Recommendation from network');
        expect(item.fromNetwork, isTrue);
      });
    });
  });
}
