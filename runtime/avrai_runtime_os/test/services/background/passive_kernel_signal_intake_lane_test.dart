import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/passive_kernel_signal_intake_lane.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PassiveKernelSignalIntakeLane', () {
    test('starts collection and ingests dwell events on background wakes',
        () async {
      var started = 0;
      List<DwellEvent>? ingestedEvents;
      final lane = PassiveKernelSignalIntakeLane(
        passiveCollectionService: SmartPassiveCollectionService(
          motionService: DeviceMotionService(skipInitForTesting: true),
        ),
        dwellEventIntakeAdapter: DwellEventIntakeAdapter(_NoopAirGap()),
        startCollection: () {
          started += 1;
        },
        flushDwellEvents: () => <DwellEvent>[
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 11),
            endTime: DateTime.utc(2026, 3, 13, 12),
            latitude: 33.5,
            longitude: -86.8,
          ),
        ],
        ingestDwellEvents: (events) async {
          ingestedEvents = List<DwellEvent>.from(events);
        },
      );

      final result = await lane.handleWake(
        reason: BackgroundWakeReason.backgroundTaskWindow,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.backgroundTaskWindow,
          privacyMode: 'private_mesh',
          isWifiAvailable: false,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: true,
        ),
      );

      expect(started, 1);
      expect(result.ingestedDwellEventCount, 1);
      expect(ingestedEvents, isNotNull);
      expect(ingestedEvents!.single.latitude, 33.5);
    });

    test('ingests dwell events on BLE encounter wakes', () async {
      var started = 0;
      var ingestedCount = 0;
      final lane = PassiveKernelSignalIntakeLane(
        passiveCollectionService: SmartPassiveCollectionService(
          motionService: DeviceMotionService(skipInitForTesting: true),
        ),
        dwellEventIntakeAdapter: DwellEventIntakeAdapter(_NoopAirGap()),
        startCollection: () {
          started += 1;
        },
        flushDwellEvents: () => <DwellEvent>[
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 11, 30),
            endTime: DateTime.utc(2026, 3, 13, 11, 40),
            latitude: 33.51,
            longitude: -86.81,
            encounteredAgentIds: <String>['peer-1'],
          ),
        ],
        ingestDwellEvents: (events) async {
          ingestedCount = events.length;
        },
      );

      final result = await lane.handleWake(
        reason: BackgroundWakeReason.bleEncounter,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.bleEncounter,
          privacyMode: 'private_mesh',
          isWifiAvailable: false,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: true,
        ),
      );

      expect(started, 1);
      expect(result.ingestedDwellEventCount, 1);
      expect(ingestedCount, 1);
    });
  });
}

class _NoopAirGap implements AirGapContract {
  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async =>
      const <SemanticTuple>[];
}
