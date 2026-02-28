import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';

void main() {
  group('AdaptiveMeshHopPolicy', () {
    test('calculateMaxHops returns at least 0 (direct connections always work)', () {
      final hops = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 5,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: true,
        networkDensity: 0,
        priority: MessagePriority.low,
        messageType: MessageType.compatibilityCheck,
        isCharging: false,
      );
      
      expect(hops, equals(0));  // Minimum: direct connections only
    });
    
    test('calculateMaxHops returns unlimited when conditions are perfect', () {
      final hops = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 90,
        batteryState: BatteryState.charging,
        isInBatterySaveMode: false,
        networkDensity: 15,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: true,
      );
      
      expect(hops, isNull);  // Unlimited hops
    });
    
    test('calculateMaxHops scales with battery level', () {
      final hops80 = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 80,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      final hops30 = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 30,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      expect(hops80, greaterThan(hops30!));
    });
    
    test('calculateMaxHops gives bonus for network density', () {
      final hopsDense = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 15,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      final hopsSparse = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 2,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      expect(hopsDense, greaterThan(hopsSparse!));
    });
    
    test('calculateMaxHops gives bonus for learning insights', () {
      final hopsLearning = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      final hopsCompatibility = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.compatibilityCheck,
        isCharging: false,
      );
      
      expect(hopsLearning, greaterThan(hopsCompatibility!));
    });
    
    test('calculateMaxHops respects power saver mode', () {
      final hopsPowerSaver = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 80,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: true,
        networkDensity: 15,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      final hopsNormal = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 80,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 15,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      expect(hopsPowerSaver, lessThan(hopsNormal!));
    });
    
    test('calculateMaxHops allows critical messages in power saver', () {
      final hopsCritical = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 80,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: true,
        networkDensity: 15,
        priority: MessagePriority.critical,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      final hopsNormal = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 80,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: true,
        networkDensity: 15,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
      );
      
      expect(hopsCritical, greaterThan(hopsNormal!));
    });

    // NEW: Expertise-based hop limits tests
    test('calculateMaxHops gives bonus for higher expertise levels', () {
      final hopsCity = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.city,
      );

      final hopsLocal = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.local,
      );

      expect(hopsCity, greaterThan(hopsLocal!));
    });

    test('calculateMaxHops gives extra bonus when learning from higher expertise', () {
      final hopsLearning = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.local,
        targetExpertiseLevel: ExpertiseLevel.city, // Learning from city expert
      );

      final hopsSame = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.local,
        targetExpertiseLevel: ExpertiseLevel.local, // Same level
      );

      expect(hopsLearning, greaterThan(hopsSame!));
    });

    test('calculateMaxHops allows unlimited for global+ experts with relaxed conditions', () {
      final hopsGlobal = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 70, // Lower than normal 80% requirement
        batteryState: BatteryState.charging,
        isInBatterySaveMode: false,
        networkDensity: 7, // Lower than normal 10 requirement
        priority: MessagePriority.medium,
        messageType: MessageType.learningInsight,
        isCharging: true,
        userExpertiseLevel: ExpertiseLevel.global,
      );

      // Global experts can get unlimited even with relaxed conditions
      expect(hopsGlobal, isNull);
    });

    test('calculateMaxHops gives priority boost for expert messages', () {
      final hopsExpertCritical = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.critical,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.city,
      );

      final hopsNonExpertCritical = AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: 50,
        batteryState: BatteryState.discharging,
        isInBatterySaveMode: false,
        networkDensity: 5,
        priority: MessagePriority.critical,
        messageType: MessageType.learningInsight,
        isCharging: false,
        userExpertiseLevel: ExpertiseLevel.local,
      );

      expect(hopsExpertCritical, greaterThan(hopsNonExpertCritical!));
    });
  });
}
