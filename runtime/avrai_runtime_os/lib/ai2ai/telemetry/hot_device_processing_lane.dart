// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';
import 'dart:convert';

import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai_runtime_os/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class HotDeviceProcessingLane {
  const HotDeviceProcessingLane._();

  static Future<void> process({
    required DiscoveredDevice device,
    required String? currentUserId,
    required PersonalityProfile? currentPersonality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool allowBleSideEffects,
    required DeviceDiscoveryService? deviceDiscovery,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required Future<void> Function({
      required String userId,
      required PersonalityProfile localPersonality,
      required List<AIPersonalityNode> nodes,
      required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    }) maybeApplyPassiveAi2AiLearning,
    required AppLogger logger,
    required String logName,
    required void Function(int valueMs) onSessionOpenMs,
    required void Function(int valueMs) onVibeReadMs,
    required void Function(int valueMs) onCompatMs,
    required void Function(int valueMs) onTotalMs,
    required void Function() maybeLogHotMetrics,
  }) async {
    final String? userId = currentUserId;
    final PersonalityProfile? personality = currentPersonality;
    if (userId == null || personality == null) return;

    final Stopwatch totalSw = Stopwatch()..start();
    try {
      final UserVibe localVibe =
          await vibeAnalyzer.compileUserVibe(userId, personality);

      AnonymizedVibeData? personalityData = device.personalityData;

      BleGattSession? session;
      if (allowBleSideEffects && device.type == DeviceType.bluetooth) {
        try {
          final Stopwatch openSw = Stopwatch()..start();
          session =
              await BleConnectionPool.instance.openSession(device: device);
          openSw.stop();
          onSessionOpenMs(openSw.elapsedMilliseconds);

          if (personalityData == null) {
            final Stopwatch vibeReadSw = Stopwatch()..start();
            final List<int>? vibeBytes =
                await session.readStreamPayload(streamId: 0);
            vibeReadSw.stop();
            onVibeReadMs(vibeReadSw.elapsedMilliseconds);
            if (vibeBytes != null && vibeBytes.isNotEmpty) {
              final String jsonString = utf8.decode(vibeBytes);
              personalityData = PersonalityDataCodec.decodeFromJson(jsonString);
            }
          }

          await primeOfflineSignalPreKeyBundleInSession(
            device: device,
            session: session,
          );
        } catch (e) {
          logger.debug(
            'Hot-path BLE session failed for ${device.deviceId}: $e',
            tag: logName,
          );
        } finally {
          try {
            await session?.close();
          } catch (_) {
            // Ignore.
          }
        }
      }

      personalityData ??= await deviceDiscovery?.extractPersonalityData(device);
      if (personalityData == null) return;

      final UserVibe vibe = AnonymizedVibeMapper.toUserVibe(personalityData);

      final double proximityScore =
          deviceDiscovery?.calculateProximity(device) ?? 0.5;
      final AIPersonalityNode node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: proximityScore,
      );

      final Stopwatch compatSw = Stopwatch()..start();
      final VibeCompatibilityResult compatibility =
          await vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
      compatSw.stop();
      onCompatMs(compatSw.elapsedMilliseconds);
      if (!isConnectionWorthy(compatibility)) return;

      updateDiscoveredNodes(<AIPersonalityNode>[node]);

      unawaited(maybeApplyPassiveAi2AiLearning(
        userId: userId,
        localPersonality: personality,
        nodes: <AIPersonalityNode>[node],
        compatibilityByNodeId: <String, VibeCompatibilityResult>{
          node.nodeId: compatibility,
        },
      ));
    } catch (e) {
      logger.debug(
        'Hot-path processing failed for ${device.deviceId}: $e',
        tag: logName,
      );
    } finally {
      totalSw.stop();
      onTotalMs(totalSw.elapsedMilliseconds);
      maybeLogHotMetrics();
    }
  }
}
