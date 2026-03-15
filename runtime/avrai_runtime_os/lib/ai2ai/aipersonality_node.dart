import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';

class AIPersonalityNode {
  final String nodeId;
  final UserVibe vibe;
  final PersonalityKnot? knot; // Added for Hex Math Exchange
  final ResolvedPeerVibeContext? resolvedPeerContext;
  final DateTime lastSeen;
  final double trustScore;
  final Map<String, dynamic> learningHistory;

  AIPersonalityNode({
    required this.nodeId,
    required this.vibe,
    this.knot,
    this.resolvedPeerContext,
    required this.lastSeen,
    required this.trustScore,
    required this.learningHistory,
  });

  String get vibeArchetype =>
      resolvedPeerContext?.personalSurface.archetype ?? vibe.getVibeArchetype();
  bool get isRecentlySeen => DateTime.now().difference(lastSeen).inMinutes < 5;
  bool get hasResolvedPeerContext => resolvedPeerContext != null;
  String get compatibilitySignature =>
      resolvedPeerContext?.personalSurface.signatureHash ??
      vibe.hashedSignature;

  // Compatibility helpers expected by realtime service
  String get vibeSignature => compatibilitySignature;
  double get compatibilityScore => trustScore; // placeholder proxy
  double get learningPotential => 0.5; // default stub value

  @override
  String toString() {
    return 'AIPersonalityNode(id: $nodeId, archetype: $vibeArchetype, trust: ${(trustScore * 100).round()}%)';
  }
}
