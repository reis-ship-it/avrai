class RealtimeDiscoveredNode {
  final String nodeId;
  final String vibeSignature;
  final double compatibilityScore;
  final double learningPotential;
  final DateTime timestamp;

  const RealtimeDiscoveredNode({
    required this.nodeId,
    required this.vibeSignature,
    required this.compatibilityScore,
    required this.learningPotential,
    required this.timestamp,
  });

  factory RealtimeDiscoveredNode.fromPayload(Map<String, dynamic> payload) {
    return RealtimeDiscoveredNode(
      nodeId: payload['node_id'] as String,
      vibeSignature: payload['vibe_signature'] as String,
      compatibilityScore: (payload['compatibility_score'] as num?)?.toDouble() ?? 0.0,
      learningPotential: (payload['learning_potential'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(payload['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}


