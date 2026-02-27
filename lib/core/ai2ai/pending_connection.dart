import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';

class PendingConnection {
  final String localUserId;
  final AIPersonalityNode remoteNode;
  final VibeCompatibilityResult compatibility;
  final DateTime requestedAt;

  PendingConnection({
    required this.localUserId,
    required this.remoteNode,
    required this.compatibility,
    required this.requestedAt,
  });

  bool get isExpired => DateTime.now().difference(requestedAt).inMinutes > 2;
}
