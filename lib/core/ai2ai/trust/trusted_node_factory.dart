import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/trust/trust_score_policy.dart';
import 'package:avrai/core/models/user/user_vibe.dart';

class TrustedNodeFactory {
  const TrustedNodeFactory._();

  static AIPersonalityNode fromProximity({
    required String nodeId,
    required UserVibe vibe,
    required DateTime lastSeen,
    required double proximityScore,
  }) {
    return AIPersonalityNode(
      nodeId: nodeId,
      vibe: vibe,
      lastSeen: lastSeen,
      trustScore: TrustScorePolicy.fromProximity(proximityScore),
      learningHistory: const <String, dynamic>{},
    );
  }
}
