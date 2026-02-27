import 'dart:convert';

import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai/core/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class PhysicalLayerDiscoveryLane {
  const PhysicalLayerDiscoveryLane._();

  static Future<List<AIPersonalityNode>> discoverNodes({
    required List<DiscoveredDevice> devices,
    required bool allowBleSideEffects,
    required Future<void> Function(DiscoveredDevice device, BleGattSession session)
        primeOfflineSignalPreKeyBundleInSession,
    required Future<AnonymizedVibeData?> Function(DiscoveredDevice device)
        extractPersonalityData,
    required double Function(DiscoveredDevice device) calculateProximity,
    required AppLogger logger,
    required String logName,
  }) async {
    final nodes = <AIPersonalityNode>[];
    for (final device in devices) {
      AnonymizedVibeData? personalityData = device.personalityData;
      BleGattSession? session;
      if (allowBleSideEffects && device.type == DeviceType.bluetooth) {
        try {
          session = await BleConnectionPool.instance.openSession(device: device);

          if (personalityData == null) {
            final vibeBytes = await session.readStreamPayload(streamId: 0);
            if (vibeBytes != null && vibeBytes.isNotEmpty) {
              final jsonString = utf8.decode(vibeBytes);
              personalityData = PersonalityDataCodec.decodeFromJson(jsonString);
            }
          }

          await primeOfflineSignalPreKeyBundleInSession(device, session);
        } catch (e) {
          logger.warn('BLE session failed for ${device.deviceId}: $e',
              tag: logName);
        } finally {
          try {
            await session?.close();
          } catch (_) {
            // Ignore.
          }
        }
      }

      personalityData ??= await extractPersonalityData(device);
      if (personalityData == null) {
        continue;
      }

      final vibe = AnonymizedVibeMapper.toUserVibe(personalityData);
      final proximityScore = calculateProximity(device);
      final node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: proximityScore,
      );

      nodes.add(node);
    }

    return nodes;
  }
}
