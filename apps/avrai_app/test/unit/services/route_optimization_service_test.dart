import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/geographic/route_optimization_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('RouteOptimizationService', () {
    late GovernedDomainConsumerStateService governedStateService;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
    });

    test(
      'uses governed mobility guidance to keep near-tie routing within locality clusters',
      () async {
        final places = <Spot>[
          _spot(
            id: 'place-a',
            latitude: 30.0000,
            longitude: -97.0100,
            cityCode: 'atx',
            localityCode: 'downtown',
          ),
          _spot(
            id: 'place-b',
            latitude: 30.0000,
            longitude: -97.0280,
            cityCode: 'atx',
            localityCode: 'downtown',
          ),
          _spot(
            id: 'place-c',
            latitude: 30.0000,
            longitude: -97.0270,
            cityCode: 'atx',
            localityCode: 'east-side',
          ),
        ];

        final baselineService = RouteOptimizationService();
        final baselineRoute = baselineService.optimizeRoute(
          places: places,
          startLatitude: 30.0000,
          startLongitude: -97.0000,
        );

        expect(
          baselineRoute.map((place) => place.id).toList(),
          <String>['place-a', 'place-c', 'place-b'],
        );

        await governedStateService.upsertState(
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_atx',
            domainId: 'mobility',
            consumerId: 'mobility_guidance_lane',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            generatedAt: DateTime.utc(2026, 4, 1, 15),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary:
                'Favor bounded same-locality movement when distances are nearly tied.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['route_guidance'],
            requestCount: 4,
            averageConfidence: 0.92,
          ),
        );

        final governedService = RouteOptimizationService(
          governedDomainConsumerStateService: governedStateService,
        );
        final governedRoute = governedService.optimizeRoute(
          places: places,
          startLatitude: 30.0000,
          startLongitude: -97.0000,
        );
        final statistics = governedService.getRouteStatistics(
          places: places,
          startLatitude: 30.0000,
          startLongitude: -97.0000,
        );

        expect(
          governedRoute.map((place) => place.id).toList(),
          <String>['place-a', 'place-b', 'place-c'],
        );
        expect(statistics.governedMobilityGuidanceApplied, isTrue);
      },
    );

    test('ignores stale governed mobility guidance in live routing', () async {
      final places = <Spot>[
        _spot(
          id: 'place-a',
          latitude: 30.0000,
          longitude: -97.0100,
          cityCode: 'atx',
          localityCode: 'downtown',
        ),
        _spot(
          id: 'place-b',
          latitude: 30.0000,
          longitude: -97.0280,
          cityCode: 'atx',
          localityCode: 'downtown',
        ),
        _spot(
          id: 'place-c',
          latitude: 30.0000,
          longitude: -97.0270,
          cityCode: 'atx',
          localityCode: 'east-side',
        ),
      ];

      final baselineService = RouteOptimizationService();
      final baselineRoute = baselineService.optimizeRoute(
        places: places,
        startLatitude: 30.0000,
        startLongitude: -97.0000,
      );

      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'stale_simulation_training_source_atx',
          domainId: 'mobility',
          consumerId: 'mobility_guidance_lane',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          generatedAt: DateTime.utc(2026, 1, 1, 15),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Old mobility guidance should not affect live routing.',
          boundedUse: 'Bounded only.',
          targetedSystems: const <String>['route_guidance'],
          requestCount: 4,
          averageConfidence: 0.92,
        ),
      );

      final governedService = RouteOptimizationService(
        governedDomainConsumerStateService: governedStateService,
      );
      final governedRoute = governedService.optimizeRoute(
        places: places,
        startLatitude: 30.0000,
        startLongitude: -97.0000,
      );
      final statistics = governedService.getRouteStatistics(
        places: places,
        startLatitude: 30.0000,
        startLongitude: -97.0000,
      );

      expect(
        governedRoute.map((place) => place.id).toList(),
        baselineRoute.map((place) => place.id).toList(),
      );
      expect(statistics.governedMobilityGuidanceApplied, isFalse);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

Spot _spot({
  required String id,
  required double latitude,
  required double longitude,
  required String cityCode,
  required String localityCode,
}) {
  final now = DateTime.utc(2026, 4, 1, 15);
  return Spot(
    id: id,
    name: id,
    description: 'test spot',
    latitude: latitude,
    longitude: longitude,
    category: 'venue',
    rating: 4.5,
    createdBy: 'tester',
    createdAt: now,
    updatedAt: now,
    cityCode: cityCode,
    localityCode: localityCode,
  );
}
