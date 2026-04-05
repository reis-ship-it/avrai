import 'package:avrai_runtime_os/config/ai2ai_retention_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ai2AiRetentionConfig', () {
    test('declares queue, transport, delivered-history, and locality policies',
        () {
      expect(
        Ai2AiRetentionConfig.wormholeQueue.mode,
        Ai2AiRetentionMode.ephemeralQueue,
      );
      expect(
        Ai2AiRetentionConfig.wormholeQueue.ttl,
        const Duration(minutes: 60),
      );
      expect(
        Ai2AiRetentionConfig.wormholeQueue.cleanupGrace,
        const Duration(days: 7),
      );

      expect(
        Ai2AiRetentionConfig.dmTransportBlob.deleteOnConsume,
        isTrue,
      );
      expect(
        Ai2AiRetentionConfig.communityTransportBlob.deleteOnConsume,
        isTrue,
      );

      expect(
        Ai2AiRetentionConfig.localDeliveredHistory.ttl,
        const Duration(days: 30),
      );
      expect(
        Ai2AiRetentionConfig.localityMeshHotCache.ttl,
        const Duration(hours: 6),
      );
    });

    test('serializes policy metadata for admin and lifecycle surfaces', () {
      final json = Ai2AiRetentionConfig.localDeliveredHistory.toJson();

      expect(json['policyId'], 'ai2ai_local_delivered_history_ttl');
      expect(json['mode'], 'localHistoryTtl');
      expect(json['ttlSeconds'], const Duration(days: 30).inSeconds);
      expect(json['deleteOnConsume'], isFalse);
      expect(json['trainingEligible'], isFalse);
    });

    test('keeps raw transport and local history artifacts out of training', () {
      expect(Ai2AiRetentionConfig.wormholeQueue.trainingEligible, isFalse);
      expect(Ai2AiRetentionConfig.dmTransportBlob.trainingEligible, isFalse);
      expect(
        Ai2AiRetentionConfig.communityTransportBlob.trainingEligible,
        isFalse,
      );
      expect(
        Ai2AiRetentionConfig.localDeliveredHistory.trainingEligible,
        isFalse,
      );
      expect(
        Ai2AiRetentionConfig.localityMeshHotCache.trainingEligible,
        isFalse,
      );
    });
  });
}
