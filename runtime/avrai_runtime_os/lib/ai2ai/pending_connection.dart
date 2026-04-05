// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';

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
