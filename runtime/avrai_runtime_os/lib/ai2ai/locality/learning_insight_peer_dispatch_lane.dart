// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_peer_send_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/avra_network.dart';
import 'package:uuid/uuid.dart';

class LearningInsightPeerDispatchLane {
  const LearningInsightPeerDispatchLane._();

  static Future<void> send({
    required bool allowBleSideEffects,
    required bool eventModeEnabled,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? deviceDiscovery,
    required String peerId,
    required SharedPreferencesCompat prefs,
    required String prefsKeyAi2AiLearningEnabled,
    required Map<String, String> peerNodeIdByDeviceId,
    required String localBleNodeId,
    required AI2AILearningInsight insight,
    required double learningQuality,
    required Future<void> Function(Map<String, dynamic> payload)
        enqueueFederatedDeltaForCloudFromInsightPayload,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!allowBleSideEffects) return;
    if (eventModeEnabled) return;
    if (protocol == null) return;

    final DiscoveredDevice? device = deviceDiscovery?.getDevice(peerId);
    if (device == null) return;
    if (device.type != DeviceType.bluetooth) return;

    final bool learningEnabled =
        prefs.getBool(prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;

    final String recipientId =
        peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
    final String insightId = const Uuid().v4();
    await LearningInsightPeerSendLane.send(
      protocol: protocol,
      device: device,
      peerId: peerId,
      localBleNodeId: localBleNodeId,
      recipientId: recipientId,
      insightId: insightId,
      learningQuality: learningQuality,
      insight: insight,
      enqueueFederatedDeltaForCloudFromInsightPayload:
          enqueueFederatedDeltaForCloudFromInsightPayload,
      logger: logger,
      logName: logName,
    );
  }
}
