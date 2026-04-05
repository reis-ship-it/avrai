/// Central retention policy surface for AI2AI transport, delivered content,
/// and temporary locality exchange artifacts.
class Ai2AiRetentionConfig {
  const Ai2AiRetentionConfig._();

  static const Ai2AiRetentionPolicy wormholeQueue = Ai2AiRetentionPolicy(
    policyId: 'wormhole_queue_ephemeral_delivery',
    mode: Ai2AiRetentionMode.ephemeralQueue,
    ttl: Duration(minutes: 60),
    cleanupGrace: Duration(days: 7),
    deleteOnConsume: false,
    trainingEligible: false,
  );

  static const Ai2AiRetentionPolicy dmTransportBlob = Ai2AiRetentionPolicy(
    policyId: 'dm_transport_blob_consume_on_read',
    mode: Ai2AiRetentionMode.consumeOnRead,
    deleteOnConsume: true,
    trainingEligible: false,
  );

  static const Ai2AiRetentionPolicy communityTransportBlob =
      Ai2AiRetentionPolicy(
    policyId: 'community_transport_blob_consume_on_read',
    mode: Ai2AiRetentionMode.consumeOnRead,
    deleteOnConsume: true,
    trainingEligible: false,
  );

  static const Ai2AiRetentionPolicy localDeliveredHistory =
      Ai2AiRetentionPolicy(
    policyId: 'ai2ai_local_delivered_history_ttl',
    mode: Ai2AiRetentionMode.localHistoryTtl,
    ttl: Duration(days: 30),
    deleteOnConsume: false,
    trainingEligible: false,
  );

  static const Ai2AiRetentionPolicy localityMeshHotCache = Ai2AiRetentionPolicy(
    policyId: 'locality_mesh_hot_cache_ttl',
    mode: Ai2AiRetentionMode.ttlDelete,
    ttl: Duration(hours: 6),
    deleteOnConsume: false,
    trainingEligible: false,
  );
}

enum Ai2AiRetentionMode {
  ephemeralQueue,
  consumeOnRead,
  localHistoryTtl,
  ttlDelete,
}

class Ai2AiRetentionPolicy {
  final String policyId;
  final Ai2AiRetentionMode mode;
  final Duration? ttl;
  final Duration? cleanupGrace;
  final bool deleteOnConsume;
  final bool trainingEligible;

  const Ai2AiRetentionPolicy({
    required this.policyId,
    required this.mode,
    this.ttl,
    this.cleanupGrace,
    required this.deleteOnConsume,
    required this.trainingEligible,
  });

  Map<String, Object?> toJson() {
    return {
      'policyId': policyId,
      'mode': mode.name,
      'ttlSeconds': ttl?.inSeconds,
      'cleanupGraceSeconds': cleanupGrace?.inSeconds,
      'deleteOnConsume': deleteOnConsume,
      'trainingEligible': trainingEligible,
    };
  }
}
