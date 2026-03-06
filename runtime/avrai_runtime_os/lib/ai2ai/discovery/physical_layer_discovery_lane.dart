// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:typed_data';

import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai_runtime_os/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_knot/services/knot/dna_encoder_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

class PhysicalLayerDiscoveryLane {
  const PhysicalLayerDiscoveryLane._();

  static Future<List<AIPersonalityNode>> discoverNodes({
    required List<DiscoveredDevice> devices,
    required bool allowBleSideEffects,
    required Future<void> Function(
            DiscoveredDevice device, BleGattSession session)
        primeOfflineSignalPreKeyBundleInSession,
    required Future<AnonymizedVibeData?> Function(DiscoveredDevice device)
        extractPersonalityData,
    required Future<Uint8List?> Function(DiscoveredDevice device)
        extractDnaPayload,
    required double Function(DiscoveredDevice device) calculateProximity,
    required AppLogger logger,
    required String logName,
  }) async {
    final nodes = <AIPersonalityNode>[];
    final dnaEncoder = DnaEncoderService();

    for (final device in devices) {
      AnonymizedVibeData? personalityData = device.personalityData;
      Uint8List? dnaPayload;
      PersonalityKnot? decodedKnot;
      BleGattSession? session;

      if (allowBleSideEffects && device.type == DeviceType.bluetooth) {
        try {
          session =
              await BleConnectionPool.instance.openSession(device: device);

          // Phase 0.1 Pivot: Read the binary DNA string payload
          final vibeBytes = await session.readStreamPayload(streamId: 0);
          if (vibeBytes != null && vibeBytes.isNotEmpty) {
            dnaPayload = vibeBytes;
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
      dnaPayload ??= await extractDnaPayload(device);

      if (personalityData == null && dnaPayload == null) {
        continue;
      }

      // Try decoding knot from binary payload
      if (dnaPayload != null) {
        try {
          decodedKnot = dnaEncoder.decode(dnaPayload);
        } catch (e) {
          logger.warn('Failed to decode DNA math string for ${device.deviceId}: $e',
              tag: logName);
        }
      }

      // Create a dummy/fallback Vibe if missing, since AIPersonalityNode expects one
      // The actual matching will happen using DeterministicMatcherService on the decodedKnot.
      final vibe = personalityData != null 
          ? AnonymizedVibeMapper.toUserVibe(personalityData)
          : UserVibe(
              hashedSignature: device.deviceId,
              anonymizedDimensions: {},
              overallEnergy: 0.5,
              socialPreference: 0.5,
              explorationTendency: 0.5,
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              privacyLevel: 1.0,
              temporalContext: 'unknown',
            );

      final proximityScore = calculateProximity(device);
      final node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: proximityScore,
      );

      // We need to pass the knot down so DeterministicMatcherService can score it
      final nodeWithKnot = AIPersonalityNode(
        nodeId: node.nodeId,
        vibe: node.vibe,
        knot: decodedKnot,
        lastSeen: node.lastSeen,
        trustScore: node.trustScore,
        learningHistory: node.learningHistory,
      );

      nodes.add(nodeWithKnot);
    }

    return nodes;
  }
}
