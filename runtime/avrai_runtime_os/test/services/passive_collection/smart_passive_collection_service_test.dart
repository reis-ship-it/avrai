import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';

// A simple mock for the DeviceMotionService to avoid bringing in Mockito
class MockDeviceMotionService extends DeviceMotionService {
  MockDeviceMotionService()
      : super(filterAlpha: 0.15, skipInitForTesting: true);

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartPassiveCollectionService - Dwell Time Clustering', () {
    late SmartPassiveCollectionService service;

    setUp(() {
      service = SmartPassiveCollectionService(
        motionService: MockDeviceMotionService(), // Revert to using mock
      );
      service.start();
    });

    tearDown(() {
      service.stop();
    });

    test('should keep raw pings in buffer if they dont meet dwell threshold',
        () {
      final now = DateTime.now();

      // Ping 1
      service.recordPing(PassivePing(
        timestamp: now,
        latitude: 40.7128,
        longitude: -74.0060,
      ));

      // Ping 2, only 2 minutes later (threshold is 5 mins)
      service.recordPing(PassivePing(
        timestamp: now.add(const Duration(minutes: 2)),
        latitude: 40.7128,
        longitude: -74.0060,
      ));

      expect(service.rawBufferSize, equals(2));
      expect(service.dwellClusterCount, equals(0));
    });

    test('should cluster pings into a DwellEvent when time threshold is met',
        () {
      final now = DateTime.now();

      // Ping 1
      service.recordPing(PassivePing(
        timestamp: now,
        latitude: 40.7128,
        longitude: -74.0060,
      ));

      // Ping 2, 6 minutes later (crosses 5 min threshold)
      service.recordPing(PassivePing(
        timestamp: now.add(const Duration(minutes: 6)),
        latitude: 40.7128,
        longitude: -74.0060,
      ));

      expect(service.rawBufferSize, equals(0)); // Buffer should be cleared
      expect(service.dwellClusterCount, equals(1)); // One cluster created

      final clusters = service.flushForBatchProcessing();
      expect(clusters.length, equals(1));
      expect(clusters[0].startTime, equals(now));
      expect(clusters[0].endTime, equals(now.add(const Duration(minutes: 6))));
    });

    test('should extend existing DwellEvent and capture encounters', () {
      final now = DateTime.now();

      // 1. Establish the base dwell
      service.recordPing(
          PassivePing(timestamp: now, latitude: 40.0, longitude: -74.0));
      service.recordPing(PassivePing(
          timestamp: now.add(const Duration(minutes: 6)),
          latitude: 40.0,
          longitude: -74.0));

      expect(service.dwellClusterCount, equals(1));

      // 2. Add another ping 30 mins later, still at the same location, but with a BLE encounter!
      service.recordPing(PassivePing(
        timestamp: now.add(const Duration(minutes: 36)),
        latitude: 40.0,
        longitude: -74.0,
        encounterAgentId: 'magic_knot_123',
        encounterConfidence: 0.95,
      ));

      // Still only 1 cluster, but it has been extended
      expect(service.dwellClusterCount, equals(1));
      expect(service.rawBufferSize, equals(0));

      final clusters = service.flushForBatchProcessing();
      final dwell = clusters[0];

      // End time extended
      expect(dwell.endTime, equals(now.add(const Duration(minutes: 36))));
      // Encounter captured and associated with this specific location/dwell
      expect(dwell.encounteredAgentIds, contains('magic_knot_123'));
    });

    test('should capture discovery encounters against the active dwell anchor',
        () {
      final now = DateTime.now().toUtc();

      service.recordPing(
        PassivePing(
          timestamp: now,
          latitude: 40.0,
          longitude: -74.0,
        ),
      );
      service.recordPing(
        PassivePing(
          timestamp: now.add(const Duration(minutes: 6)),
          latitude: 40.0,
          longitude: -74.0,
        ),
      );

      service.recordEncounterFromDiscovery(
        DiscoveredDevice(
          deviceId: 'device-peer-1',
          deviceName: 'Peer One',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          discoveredAt: now.add(const Duration(minutes: 7)),
          signalStrength: -42,
        ),
      );

      final clusters = service.flushForBatchProcessing();
      expect(clusters, hasLength(1));
      expect(clusters.single.encounteredAgentIds, contains('device-peer-1'));
    });
  });
}
