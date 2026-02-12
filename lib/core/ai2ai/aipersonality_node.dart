import 'package:avrai/core/models/user/user_vibe.dart';

class AIPersonalityNode {
  final String nodeId;
  final UserVibe vibe;
  final DateTime lastSeen;
  final double trustScore;
  final Map<String, dynamic> learningHistory;

  AIPersonalityNode({
    required this.nodeId,
    required this.vibe,
    required this.lastSeen,
    required this.trustScore,
    required this.learningHistory,
  });

  String get vibeArchetype => vibe.getVibeArchetype();
  bool get isRecentlySeen => DateTime.now().difference(lastSeen).inMinutes < 5;

  // Compatibility helpers expected by realtime service
  String get vibeSignature => vibe.hashedSignature;
  double get compatibilityScore => trustScore; // placeholder proxy
  double get learningPotential => 0.5; // default stub value

  @override
  String toString() {
    return 'AIPersonalityNode(id: $nodeId, archetype: $vibeArchetype, trust: ${(trustScore * 100).round()}%)';
  }
}


