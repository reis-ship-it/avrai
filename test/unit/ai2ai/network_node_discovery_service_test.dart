import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/network_node_discovery_service.dart';
import 'package:avrai_network/avra_network.dart';

void main() {
  group('NetworkNodeDiscoveryService', () {
    late DeviceDiscoveryService deviceDiscovery;
    late NetworkNodeDiscoveryService service;

    setUp(() {
      // Create mock device discovery service
      deviceDiscovery = DeviceDiscoveryService();
      service = NetworkNodeDiscoveryService(
        deviceDiscovery: deviceDiscovery,
        adaptiveMeshService: null,
      );
    });

    test('should initialize successfully', () async {
      await service.initialize();
      // Service should be initialized without errors
      expect(service, isNotNull);
    });

    test('should get available routing nodes', () async {
      await service.initialize();

      final nodes = await service.getAvailableRoutingNodes();

      // Should return a list (may be empty if no nodes discovered)
      expect(nodes, isA<List<RoutingNode>>());
    });

    test('should select optimal nodes for routing', () async {
      await service.initialize();

      final selectedNodes = await service.selectOptimalNodes(
        maxHops: 3,
        ensureDiversity: true,
      );

      // Should return a list (may be empty if no nodes available)
      expect(selectedNodes, isA<List<RoutingNode>>());
      expect(selectedNodes.length, lessThanOrEqualTo(3));
    });

    test('should update node reliability metrics', () {
      // Create a test node ID
      const nodeId = 'test-node-123';

      // Update reliability (success)
      service.updateNodeReliability(nodeId, true);

      // Update reliability (failure)
      service.updateNodeReliability(nodeId, false);

      // Should not throw
      expect(service, isNotNull);
    });

    test('should handle empty node list gracefully', () async {
      await service.initialize();

      final nodes = await service.getAvailableRoutingNodes(maxNodes: 0);

      expect(nodes, isEmpty);
    });

    test('should filter nodes by minimum capability', () async {
      await service.initialize();

      final nodes = await service.getAvailableRoutingNodes(
        minCapability: RoutingCapability.high,
      );

      // All returned nodes should meet minimum capability
      for (final node in nodes) {
        expect(
          node.routingCapability == RoutingCapability.high,
          isTrue,
          reason: 'Node ${node.nodeId} should have high capability',
        );
      }
    });

    tearDown(() {
      service.dispose();
    });
  });
}
