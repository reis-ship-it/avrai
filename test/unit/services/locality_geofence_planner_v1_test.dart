import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/locality_agents/locality_geofence_planner.dart';
import 'package:avrai/core/services/locality_agents/os_geofence_registrar.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_capability_profile.dart';

import '../../mocks/mock_storage_service.dart';

class _RecordingRegistrar implements OsGeofenceRegistrarV1 {
  List<PlannedOsGeofenceV1> last = const [];

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> registerGeofences(List<PlannedOsGeofenceV1> geofences) async {
    last = geofences;
  }
}

void main() {
  group('LocalityGeofencePlannerV1', () {
    setUpAll(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
    });

    test('plans a bounded set including the current geohash', () async {
      final registrar = _RecordingRegistrar();
      final planner = LocalityGeofencePlannerV1(
        storage: StorageService.instance,
        registrar: registrar,
      );

      final planned = await planner.planAndRegister(
        agentId: 'agent_abc',
        latitude: 40.7128,
        longitude: -74.0060,
        precision: 7,
        maxGeofences: 8,
      );

      expect(planned.length, lessThanOrEqualTo(8));
      expect(planned.map((g) => g.id).toSet().length, equals(planned.length));
      expect(registrar.last.length, equals(planned.length));
    });

    test('degrades precision and geofence count by capability profile',
        () async {
      final registrar = _RecordingRegistrar();
      final planner = LocalityGeofencePlannerV1(
        storage: StorageService.instance,
        registrar: registrar,
      );

      const profile = RuntimeCapabilityProfile(
        platform: 'android',
        tier: RuntimeCapabilityTier.minimal,
        supportsBle: false,
        supportsWifi: true,
        supportsP2p: false,
        supportsAi2AiMesh: false,
        maxConcurrentGeofences: 4,
        maxPlannerCandidates: 16,
        geohashPrecisionCap: 5,
      );

      final planned = await planner.planAndRegister(
        agentId: 'agent_low_cap',
        latitude: 40.7128,
        longitude: -74.0060,
        precision: 8,
        maxGeofences: 12,
        capabilityProfile: profile,
      );

      expect(planned.length, lessThanOrEqualTo(4));
      expect(
          planned.every((g) => (g.metadata['precision'] as int) <= 5), isTrue);
      expect(registrar.last.length, equals(planned.length));
    });
  });
}
