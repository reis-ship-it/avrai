import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_geofence_planner.dart';
import 'package:avrai_runtime_os/services/locality_agents/os_geofence_registrar.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

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
  });
}
