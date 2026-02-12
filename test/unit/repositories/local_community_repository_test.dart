import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/data/repositories/local_community_repository.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('LocalCommunityRepository', () {
    test('upsertCommunity then getAllCommunities returns stored community',
        () async {
      final repo = LocalCommunityRepository(storageService: StorageService.instance);

      final c = Community(
        id: 'c_repo_1',
        name: 'Repo Community',
        description: 'Test community',
        category: 'Test',
        originatingEventId: 'e1',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'u_founder',
        createdAt: DateTime.now(),
        originalLocality: 'Testville',
        updatedAt: DateTime.now(),
      );

      await repo.upsertCommunity(c);
      final all = await repo.getAllCommunities();

      expect(all.any((x) => x.id == 'c_repo_1'), isTrue);
    });

    test('joinCommunity then leaveCommunity updates membership locally', () async {
      final repo = LocalCommunityRepository(storageService: StorageService.instance);

      final c = Community(
        id: 'c_repo_membership',
        name: 'Membership Community',
        description: 'Test community',
        category: 'Test',
        originatingEventId: 'e1',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'u_founder',
        createdAt: DateTime.now(),
        originalLocality: 'Testville',
        updatedAt: DateTime.now(),
        memberIds: const [],
        memberCount: 0,
      );
      await repo.upsertCommunity(c);

      await repo.joinCommunity(communityId: c.id, userId: 'u1');
      final afterJoin = await repo.getCommunityById(c.id);
      expect(afterJoin, isNotNull);
      expect(afterJoin!.memberIds, contains('u1'));
      expect(afterJoin.memberCount, equals(1));

      await repo.leaveCommunity(communityId: c.id, userId: 'u1');
      final afterLeave = await repo.getCommunityById(c.id);
      expect(afterLeave, isNotNull);
      expect(afterLeave!.memberIds, isNot(contains('u1')));
      expect(afterLeave.memberCount, equals(0));
    });

    test('upsertVibeContribution stores quantized 12D dimensions by agentId',
        () async {
      final repo = LocalCommunityRepository(storageService: StorageService.instance);

      final c = Community(
        id: 'c_repo_vibe',
        name: 'Vibe Community',
        description: 'Test community',
        category: 'Test',
        originatingEventId: 'e1',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'u_founder',
        createdAt: DateTime.now(),
        originalLocality: 'Testville',
        updatedAt: DateTime.now(),
      );
      await repo.upsertCommunity(c);

      final dims = <String, double>{
        for (final d in VibeConstants.coreDimensions)
          d: d == VibeConstants.coreDimensions.first ? 0.8 : 0.2,
      };

      await repo.upsertVibeContribution(
        communityId: c.id,
        userId: 'u1',
        agentId: 'agent_u1',
        dimensions: dims,
        quantizationBins: 2,
      );

      final contribs = await repo.getVibeContributions(communityId: c.id);
      expect(contribs.containsKey('agent_u1'), isTrue);
      final stored = contribs['agent_u1']!;
      expect(stored.keys.toSet(), equals(VibeConstants.coreDimensions.toSet()));
      // With 2 bins, values quantize to 0.0 or 1.0.
      expect(stored[VibeConstants.coreDimensions.first], equals(1.0));
      expect(stored[VibeConstants.coreDimensions[1]], equals(0.0));
    });
  });
}

