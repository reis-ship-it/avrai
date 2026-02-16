import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/social_media/social_media_connection_service.dart';
import 'package:avrai/core/services/social_media/social_media_sharing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocialMediaConnectionService extends Mock
    implements SocialMediaConnectionService {}

void main() {
  group('SocialMediaSharingService Phase 1.2.10', () {
    test('shareList records episodic tuple with recipient and list features',
        () async {
      final connectionService = _MockSocialMediaConnectionService();
      final episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();

      when(() => connectionService.getActiveConnections('user-1'))
          .thenAnswer((_) async => const []);

      final service = SocialMediaSharingService(
        connectionService: connectionService,
        episodicMemoryStore: episodicStore,
      );

      final results = await service.shareList(
        agentId: 'agent-1',
        userId: 'user-1',
        listId: 'list-1',
        listName: 'Weekend Spots',
        listDescription: 'Places I want to visit',
        spotCount: 3,
        isPublic: true,
        tags: const ['weekend', 'food'],
        platforms: const ['instagram', 'twitter'],
      );

      expect(results, isEmpty);
      final tuples = await episodicStore.replay(agentId: 'agent-1');
      expect(tuples, hasLength(1));
      expect(tuples.first.actionType, 'share_list');
      expect(
        tuples.first.actionPayload['recipient_features']['requested_platforms'],
        ['instagram', 'twitter'],
      );
      expect(
        tuples.first.actionPayload['list_features']['spot_count'],
        3,
      );
      expect(
        tuples.first.metadata['phase_ref'],
        '1.2.10',
      );
    });
  });
}
