import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai/core/ai2ai/discovery/deterministic_test_vibe_builder_lane.dart';
import 'package:avrai/core/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class DebugHotPathSimulationLane {
  const DebugHotPathSimulationLane._();

  static Future<void> run({
    required String userId,
    required PersonalityProfile personality,
    required List<DiscoveredDevice> devices,
    required SharedPreferencesCompat prefs,
    required UserVibeAnalyzer vibeAnalyzer,
    required int hotRssiThresholdDbm,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required void Function(String userId) setCurrentUser,
    required void Function(PersonalityProfile personality) setCurrentPersonality,
  }) async {
    setCurrentUser(userId);
    setCurrentPersonality(personality);

    final bool discoveryEnabled = prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    final localVibe = DeterministicTestVibeBuilderLane.build(
      userId: userId,
      personality: personality,
    );

    for (final DiscoveredDevice device in devices) {
      if (device.type != DeviceType.bluetooth) continue;
      final int? rssi = device.signalStrength;
      if (rssi == null || rssi < hotRssiThresholdDbm) continue;
      final personalityData = device.personalityData;
      if (personalityData == null) continue;

      final vibe = AnonymizedVibeMapper.toUserVibe(personalityData);
      final node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: device.proximityScore,
      );

      final compatibility =
          await vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
      if (!isConnectionWorthy(compatibility)) continue;

      updateDiscoveredNodes(<AIPersonalityNode>[node]);
    }
  }
}
