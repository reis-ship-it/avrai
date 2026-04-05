import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  group('GovernedDomainConsumerStateService', () {
    late GovernedDomainConsumerStateService service;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      service = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
    });

    test('latestLiveStateFor ignores stale propagated state', () async {
      final now = DateTime.utc(2026, 4, 2, 12);

      await service.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'stale-source',
          domainId: 'venue',
          consumerId: 'venue_intelligence_lane',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          generatedAt: now.subtract(const Duration(days: 45)),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Stale venue state',
          boundedUse: 'Bounded only.',
          targetedSystems: const <String>['venue_ranking'],
          requestCount: 4,
          averageConfidence: 0.9,
        ),
      );

      await service.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'fresh-source',
          domainId: 'venue',
          consumerId: 'venue_intelligence_lane',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          generatedAt: now.subtract(const Duration(hours: 2)),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Fresh venue state',
          boundedUse: 'Bounded only.',
          targetedSystems: const <String>['venue_ranking'],
          requestCount: 4,
          averageConfidence: 0.9,
        ),
      );

      final latest = service.latestStateFor(cityCode: 'atx', domainId: 'venue');
      final latestLive = service.latestLiveStateFor(
        cityCode: 'atx',
        domainId: 'venue',
        now: now,
      );

      expect(latest, isNotNull);
      expect(latestLive, isNotNull);
      expect(latestLive!.sourceId, 'fresh-source');
      expect(
        latestLive.temporalFreshnessWeight(now: now),
        greaterThan(0.0),
      );
    });
  });
}
