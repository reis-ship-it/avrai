// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/discovery_postprocess_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_routing_policy.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NearbyDiscoveryOrchestrationLane {
  const NearbyDiscoveryOrchestrationLane._();

  static Future<List<AIPersonalityNode>> run({
    required bool isDiscovering,
    required void Function(bool value) setIsDiscovering,
    required List<AIPersonalityNode> Function() getCachedNodes,
    required Future<List<ConnectivityResult>> Function() checkConnectivity,
    required Future<List<AIPersonalityNode>> Function() performDiscovery,
    required bool throwOnError,
    required Object Function(Object error) buildDiscoveryException,
    required AppLogger logger,
    required String logName,
  }) async {
    if (isDiscovering) {
      logger.debug('Discovery already in progress, returning cached results',
          tag: logName);
      return getCachedNodes();
    }

    try {
      final connectivityResults = await checkConnectivity();
      if (!ConnectionRoutingPolicy.isConnected(connectivityResults)) {
        logger.info(
            'No connectivity available, proceeding with offline discovery',
            tag: logName);
      }
    } catch (e) {
      logger.warn('Error checking connectivity: $e, proceeding with discovery',
          tag: logName);
    }

    setIsDiscovering(true);
    try {
      logger.info('Discovering nearby AI personalities', tag: logName);
      return await performDiscovery();
    } catch (e) {
      logger.error('Error discovering AI personalities',
          error: e, tag: logName);
      if (throwOnError) {
        throw buildDiscoveryException(e);
      }
      return <AIPersonalityNode>[];
    } finally {
      setIsDiscovering(false);
    }
  }

  static Future<List<AIPersonalityNode>> runForOrchestrator({
    required bool isDiscovering,
    required void Function(bool value) setIsDiscovering,
    required List<AIPersonalityNode> Function() getCachedNodes,
    required Future<List<ConnectivityResult>> Function() checkConnectivity,
    required Future<List<AIPersonalityNode>> Function() performRawDiscovery,
    required String userId,
    required PersonalityProfile personality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required void Function(
      List<AIPersonalityNode> worthyNodes,
      Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    ) onWorthyNodes,
    required bool throwOnError,
    required Object Function(Object error) buildDiscoveryException,
    required AppLogger logger,
    required String logName,
  }) {
    return run(
      isDiscovering: isDiscovering,
      setIsDiscovering: setIsDiscovering,
      getCachedNodes: getCachedNodes,
      checkConnectivity: checkConnectivity,
      performDiscovery: () async {
        final nodes = await performRawDiscovery();
        return DiscoveryPostprocessLane.process(
          nodes: nodes,
          userId: userId,
          personality: personality,
          vibeAnalyzer: vibeAnalyzer,
          isConnectionWorthy: isConnectionWorthy,
          updateDiscoveredNodes: updateDiscoveredNodes,
          onWorthyNodes: onWorthyNodes,
          logger: logger,
          logName: logName,
        );
      },
      throwOnError: throwOnError,
      buildDiscoveryException: buildDiscoveryException,
      logger: logger,
      logName: logName,
    );
  }
}
