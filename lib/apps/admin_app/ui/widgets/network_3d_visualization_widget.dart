// Network 3D Visualization Widget
//
// Widget for 3D visualization of AI2AI network connections
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';
import 'package:avrai/core/models/misc/visualization_style.dart';
import 'package:avrai/core/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';

/// Data model for a network node
class AI2AINetworkNode {
  /// User ID for this node
  final String userId;

  /// Position in 3D space
  final Vector3 position;

  /// Optional color (hex string like 'hsl(180, 70%, 60%)')
  final String? color;

  /// Whether this is the center node (current user)
  final bool isCenter;

  /// Optional knot representation
  final dynamic knot;

  AI2AINetworkNode({
    required this.userId,
    required this.position,
    this.color,
    this.isCenter = false,
    this.knot,
  });
}

/// Data model for a network edge (connection between nodes)
class AI2AINetworkEdge {
  /// Index of the source node
  final int fromIndex;

  /// Index of the target node
  final int toIndex;

  /// Connection strength (0.0 to 1.0)
  final double strength;

  AI2AINetworkEdge({
    required this.fromIndex,
    required this.toIndex,
    this.strength = 1.0,
  });
}

/// Widget for 3D visualization of AI2AI network connections
///
/// **Features:**
/// - Force-directed graph layout in 3D
/// - Nodes rendered as simplified knot meshes
/// - Edges as glowing lines with particle flow
/// - Center node (user) emphasized
/// - Tap to select nodes
/// - Real-time edge pulse animation for data flow events
class Network3DVisualizationWidget extends StatefulWidget {
  /// List of nodes in the network
  final List<AI2AINetworkNode> nodes;

  /// List of edges connecting nodes
  final List<AI2AINetworkEdge> edges;

  /// Size of the visualization
  final double size;

  /// Width (overrides size if provided)
  final double? width;

  /// Height (overrides size if provided)
  final double? height;

  /// Callback when a node is tapped
  final void Function(String userId)? onNodeTapped;

  /// Whether to show controls
  final bool showControls;

  /// Whether to use Three.js WebView (true) or fallback (false)
  final bool useThreeJs;

  const Network3DVisualizationWidget({
    super.key,
    required this.nodes,
    required this.edges,
    this.size = 400.0,
    this.width,
    this.height,
    this.onNodeTapped,
    this.showControls = false,
    this.useThreeJs = true,
  });

  @override
  State<Network3DVisualizationWidget> createState() =>
      _Network3DVisualizationWidgetState();
}

class _Network3DVisualizationWidgetState
    extends State<Network3DVisualizationWidget> {
  static const String _logName = 'Network3DVisualizationWidget';

  ThreeJsBridgeService? _bridge;
  bool _threeJsReady = false;

  double get _width => widget.width ?? widget.size;
  double get _height => widget.height ?? widget.size;

  void _onThreeJsReady(ThreeJsBridgeService bridge) {
    developer.log('Three.js ready for network visualization', name: _logName);
    _bridge = bridge;
    _threeJsReady = true;
    _renderNetworkInThreeJs();
  }

  Future<void> _renderNetworkInThreeJs() async {
    if (_bridge == null) return;

    final networkNodes = widget.nodes
        .map((n) => NetworkNode(
              userId: n.userId,
              position: n.position,
              color: n.color,
              isCenter: n.isCenter,
            ))
        .toList();

    final networkEdges = widget.edges
        .map((e) => NetworkEdge(
              fromIndex: e.fromIndex,
              toIndex: e.toIndex,
            ))
        .toList();

    final style = NetworkVisualizationStyle.scifi(
      primaryColor: AppColors.electricGreen.toHex(),
    );

    await _bridge!.renderNetwork(
      nodes: networkNodes,
      edges: networkEdges,
      style: style,
    );
  }

  void _onObjectTapped(String objectId) {
    widget.onNodeTapped?.call(objectId);
  }

  /// Pulse an edge to show data flow
  Future<void> pulseEdge(int edgeIndex) async {
    if (_bridge == null || !_threeJsReady) {
      developer.log('Cannot pulse edge - not ready', name: _logName);
      return;
    }
    
    developer.log('Pulsing edge $edgeIndex', name: _logName);
    await _bridge!.evaluateJS('window.networkRenderer?.pulseEdge($edgeIndex)');
  }

  /// Highlight a specific node
  Future<void> highlightNode(String userId) async {
    if (_bridge == null || !_threeJsReady) return;
    // Use jsonEncode to safely escape the userId and prevent JS injection
    final safeUserId = jsonEncode(userId);
    await _bridge!.evaluateJS('window.networkRenderer?.highlightNode($safeUserId)');
  }

  /// Clear all highlights
  Future<void> clearHighlights() async {
    if (_bridge == null || !_threeJsReady) return;
    await _bridge!.evaluateJS('window.networkRenderer?.clearHighlights()');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useThreeJs) {
      return ThreeJsVisualizationWidget(
        width: _width,
        height: _height,
        onReady: _onThreeJsReady,
        onObjectTapped: _onObjectTapped,
        showControls: widget.showControls,
        backgroundColor: AppColors.black,
      );
    }

    // Fallback: Simple 2D representation
    return _buildFallbackVisualization();
  }

  Widget _buildFallbackVisualization() {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _NetworkFallbackPainter(
          nodes: widget.nodes,
          edges: widget.edges,
        ),
      ),
    );
  }
}

/// Fallback painter for 2D network visualization
class _NetworkFallbackPainter extends CustomPainter {
  final List<AI2AINetworkNode> nodes;
  final List<AI2AINetworkEdge> edges;

  _NetworkFallbackPainter({
    required this.nodes,
    required this.edges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 10; // Assume nodes are in -5 to 5 range

    // Draw edges
    final edgePaint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    for (final edge in edges) {
      if (edge.fromIndex >= nodes.length || edge.toIndex >= nodes.length) {
        continue;
      }

      final from = nodes[edge.fromIndex];
      final to = nodes[edge.toIndex];

      final fromPos =
          Offset(center.dx + from.position.x * scale, center.dy + from.position.y * scale);
      final toPos =
          Offset(center.dx + to.position.x * scale, center.dy + to.position.y * scale);

      canvas.drawLine(fromPos, toPos, edgePaint);
    }

    // Draw nodes
    for (final node in nodes) {
      final pos =
          Offset(center.dx + node.position.x * scale, center.dy + node.position.y * scale);

      final nodePaint = Paint()
        ..color = node.isCenter ? AppColors.white : AppColors.electricGreen
        ..style = PaintingStyle.fill;

      final radius = node.isCenter ? 8.0 : 5.0;
      canvas.drawCircle(pos, radius, nodePaint);

      // Glow for center node
      if (node.isCenter) {
        final glowPaint = Paint()
          ..color = AppColors.electricGreen.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
