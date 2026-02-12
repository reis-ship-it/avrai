// Knot Fabric Widget
// 
// Widget for visualizing a knot fabric
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';

/// Widget for visualizing a knot fabric
class KnotFabricWidget extends StatelessWidget {
  final KnotFabric fabric;
  final bool showClusters;
  final bool showBridges;
  final double size;
  
  const KnotFabricWidget({
    super.key,
    required this.fabric,
    this.showClusters = true,
    this.showBridges = true,
    this.size = 300.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: KnotFabricPainter(
        fabric: fabric,
        showClusters: showClusters,
        showBridges: showBridges,
      ),
    );
  }
}

/// Custom painter for drawing knot fabric
class KnotFabricPainter extends CustomPainter {
  final KnotFabric fabric;
  final bool showClusters;
  final bool showBridges;
  
  KnotFabricPainter({
    required this.fabric,
    required this.showClusters,
    required this.showBridges,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    // Draw fabric background
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw fabric strands (simplified representation)
    final strandCount = fabric.braid.strandCount;
    final angleStep = (2 * 3.14159) / strandCount;
    
    for (int i = 0; i < strandCount; i++) {
      final angle = i * angleStep;
      final startX = center.dx + radius * 0.3 * math.cos(angle);
      final startY = center.dy + radius * 0.3 * math.sin(angle);
      final endX = center.dx + radius * 0.9 * math.cos(angle);
      final endY = center.dy + radius * 0.9 * math.sin(angle);
      
      final strandPaint = Paint()
        ..color = Colors.blue.shade300
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        strandPaint,
      );
    }
    
    // Draw crossings (simplified)
    final crossingPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;
    
    // Draw a few representative crossings
    for (int i = 0; i < fabric.invariants.crossingNumber && i < 10; i++) {
      final angle = (i * 2 * math.pi) / 10;
      final x = center.dx + radius * 0.6 * math.cos(angle);
      final y = center.dy + radius * 0.6 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3.0, crossingPaint);
    }
    
    // Draw stability indicator
    final stabilityRadius = radius * 0.15;
    final stabilityPaint = Paint()
      ..color = _getStabilityColor(fabric.stability)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, stabilityRadius, stabilityPaint);
    
    // Draw stability text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(fabric.stability * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
  
  Color _getStabilityColor(double stability) {
    if (stability > 0.7) {
      return Colors.green;
    } else if (stability > 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
