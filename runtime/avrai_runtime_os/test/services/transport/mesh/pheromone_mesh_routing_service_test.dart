import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/pheromone_mesh_routing_service.dart';
import '../../../support/fake_kernel_governance.dart';

void main() {
  group('PheromoneMeshRoutingService', () {
    late GovernanceKernelService kernel;
    late PheromoneMeshRoutingService routingService;

    setUp(() {
      kernel = buildTestGovernanceKernelService();
      routingService = PheromoneMeshRoutingService(governanceKernel: kernel);
    });

    KnowledgeVector createValidVector() {
      return KnowledgeVector(
        senderAgentId: 'agent-123',
        insightWeights: [0.5, -0.2, 0.8],
        contextCategory: 'spot_affinity',
        timestamp: DateTime.now(),
      );
    }

    KnowledgeVector createInvalidVector() {
      return KnowledgeVector(
        senderAgentId: 'agent-bad',
        insightWeights: [1.5, 2.0], // Out of bounds
        contextCategory: 'unauthorized_category',
        timestamp: DateTime.now(),
      );
    }

    test('should enqueue valid vector to outbox', () {
      final vector = createValidVector();
      routingService.enqueueForBroadcast(vector);

      expect(routingService.outboxSize, equals(1));
    });

    test('should reject invalid vector from outbox', () {
      final vector = createInvalidVector();
      routingService.enqueueForBroadcast(vector);

      expect(routingService.outboxSize, equals(0));
    });

    test('should receive valid vector to inbox', () {
      final vector = createValidVector();
      routingService.receiveFromMesh(vector);

      expect(routingService.inboxSize, equals(1));
    });

    test('should reject invalid vector from mesh', () {
      final vector = createInvalidVector();
      routingService.receiveFromMesh(vector);

      expect(routingService.inboxSize, equals(0));
    });

    test('should flush inbox for batch processing', () {
      routingService.receiveFromMesh(createValidVector());
      routingService.receiveFromMesh(createValidVector());

      expect(routingService.inboxSize, equals(2));

      final vectors = routingService.flushInboxForBatchProcessing();

      expect(vectors.length, equals(2));
      expect(routingService.inboxSize, equals(0));
    });

    test('should provide vectors for swapping', () {
      routingService.enqueueForBroadcast(createValidVector());
      routingService.enqueueForBroadcast(createValidVector());

      final vectors = routingService.getVectorsForSwapping();
      expect(vectors.length, equals(2));
    });
  });
}
