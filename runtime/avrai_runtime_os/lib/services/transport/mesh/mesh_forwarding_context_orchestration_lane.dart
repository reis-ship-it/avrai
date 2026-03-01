import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshForwardingContextOrchestrationLane {
  const MeshForwardingContextOrchestrationLane._();

  static OptimizedBloomFilter getOrCreateBloomFilter({
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required String scope,
  }) {
    return bloomFilters.putIfAbsent(
      scope,
      () => OptimizedBloomFilter(geographicScope: scope),
    );
  }

  static Iterable<String> discoveredNodeIds({
    required Map<String, AIPersonalityNode> discoveredNodes,
  }) {
    return discoveredNodes.values.map((node) => node.nodeId);
  }

  static MeshForwardingContext? tryCreate({
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
  }) {
    return MeshForwardingContext.tryCreate(
      protocol: protocol,
      discovery: discovery,
    );
  }
}
