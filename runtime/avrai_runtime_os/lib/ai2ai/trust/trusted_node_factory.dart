// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/trust/trust_score_policy.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

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
