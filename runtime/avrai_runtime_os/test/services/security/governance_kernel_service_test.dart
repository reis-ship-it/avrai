import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';

void main() {
  group('GovernanceKernelService (Knowledge Vectors)', () {
    late GovernanceKernelService kernel;

    setUp(() {
      kernel = GovernanceKernelService();
    });

    KnowledgeVector createVector({
      required String category,
      required List<double> weights,
      DateTime? timestamp,
    }) {
      return KnowledgeVector(
        senderAgentId: 'test_id',
        insightWeights: weights,
        contextCategory: category,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    group('Outgoing Interception (Structure & Category Enforcement)', () {
      test('should allow valid vectors from approved categories', () {
        final vector = createVector(category: 'spot_affinity', weights: [0.5, -0.2, 0.9]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isTrue);
        expect(result.sanitizedVector, isNotNull);
        expect(result.sanitizedVector!.insightWeights, equals([0.5, -0.2, 0.9]));
      });

      test('should reject unauthorized categories (preventing data tunnels)', () {
        final vector = createVector(category: 'custom_chat_tunnel', weights: [0.1]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('Unauthorized'));
      });

      test('should clamp outgoing weights to prevent extreme values', () {
        final vector = createVector(category: 'event_resonance', weights: [0.5, 50.0, -100.0]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isTrue);
        // 50.0 clamps to 1.0, -100.0 clamps to -1.0
        expect(result.sanitizedVector!.insightWeights, equals([0.5, 1.0, -1.0]));
      });

      test('should reject excessively large vectors', () {
        final vector = createVector(
          category: 'spot_affinity', 
          weights: List.generate(600, (i) => 0.1),
        );
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('maximum dimensionality'));
      });
    });

    group('Incoming Interception (Poisoning Defense)', () {
      test('should allow normal incoming vectors', () {
        final vector = createVector(category: 'spot_affinity', weights: [0.2, -0.8, 0.0]);
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isTrue);
      });

      test('should reject vectors with out-of-bounds weights (Data Poisoning)', () {
        final vector = createVector(category: 'spot_affinity', weights: [0.5, 2.5]);
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('poisoning attempt'));
      });

      test('should reject expired vectors (Replay Attack)', () {
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 10));
        final vector = createVector(
          category: 'spot_affinity', 
          weights: [0.5],
          timestamp: oldTimestamp,
        );
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('expired'));
      });
    });
  });
}
