import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/network/device_discovery.dart';

import '../../fixtures/model_factories.dart';
import '../../mocks/mock_storage_service.dart';

AnonymizedVibeData _buildDeterministicAnonVibe({
  required Map<String, double> dims,
  required String signature,
}) {
  final now = DateTime.now();

  // Keep metrics consistent with UserVibe formulas.
  final energy = ((dims['exploration_eagerness'] ?? 0.5) +
          (dims['temporal_flexibility'] ?? 0.5) +
          (dims['location_adventurousness'] ?? 0.5)) /
      3.0;
  final social = ((dims['community_orientation'] ?? 0.5) +
          (dims['social_discovery_style'] ?? 0.5) +
          (dims['trust_network_reliance'] ?? 0.5)) /
      3.0;
  final exploration = ((dims['exploration_eagerness'] ?? 0.5) +
          (dims['location_adventurousness'] ?? 0.5) +
          (1.0 - (dims['authenticity_preference'] ?? 0.5))) /
      3.0;

  return AnonymizedVibeData(
    noisyDimensions: dims,
    anonymizedMetrics: AnonymizedVibeMetrics(
      energy: energy.clamp(0.0, 1.0),
      social: social.clamp(0.0, 1.0),
      exploration: exploration.clamp(0.0, 1.0),
    ),
    temporalContextHash: 'test_ctx',
    vibeSignature: signature,
    privacyLevel: 'test',
    anonymizationQuality: 1.0,
    salt: 'test_salt',
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
  );
}

void main() {
  test('Walk-by hot path simulation processes within 5s budget (no real BLE)',
      () async {
    final mockStorage = MockGetStorage.getInstance();
    MockGetStorage.reset();
    final prefs =
        await SharedPreferencesCompat.getInstance(storage: mockStorage);

    await prefs.setBool('discovery_enabled', true);

    final analyzer = UserVibeAnalyzer(prefs: prefs);
    final orchestrator = VibeConnectionOrchestrator(
      vibeAnalyzer: analyzer,
      connectivity: Connectivity(),
      prefs: prefs,
    );

    // Local personality: stable 0.5 baseline across all core dimensions.
    final localDims = <String, double>{
      for (final d in VibeConstants.coreDimensions) d: 0.5,
    };
    final localProfile = ModelFactories.createTestPersonalityProfile(
      userId: 'user_local',
      agentId: 'agent_user_local',
      dimensions: localDims,
    );

    // Remote “advertised” vibe: mostly identical, with one dimension shifted by 0.4
    // so that learning opportunities exist (difference in [0.3, 0.7]).
    final remoteDims = <String, double>{
      for (final d in VibeConstants.coreDimensions) d: 0.5,
    };
    remoteDims['community_orientation'] = 0.9; // diff 0.4

    final remoteAnon = _buildDeterministicAnonVibe(
      dims: remoteDims,
      signature: 'remote_sig',
    );

    final device = DiscoveredDevice(
      deviceId: 'device_remote',
      deviceName: 'Remote',
      type: DeviceType.bluetooth,
      isSpotsEnabled: true,
      personalityData: remoteAnon,
      signalStrength: -60, // hot path threshold is -75
      discoveredAt: DateTime.now(),
    );

    final sw = Stopwatch()..start();
    await orchestrator.debugSimulateWalkByHotPath(
      userId: 'user_local',
      personality: localProfile,
      devices: <DiscoveredDevice>[device],
    );
    sw.stop();

    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));

    final nodes = orchestrator.debugDiscoveredNodesSnapshot();
    expect(nodes.where((n) => n.nodeId == 'device_remote'), isNotEmpty);
  });
}
