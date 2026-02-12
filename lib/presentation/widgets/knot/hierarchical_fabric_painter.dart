// Hierarchical Fabric Painter
// 
// Custom painter for hierarchical fabric visualization
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/hierarchical_layout.dart';
import 'package:avrai_knot/services/knot/glue_visualization_service.dart';
import 'package:avrai_knot/models/entity_knot.dart';

/// Custom painter for hierarchical fabric visualization
class HierarchicalFabricPainter extends CustomPainter {
  /// The hierarchical layout to paint
  final HierarchicalLayout layout;
  
  /// The knot fabric
  final KnotFabric fabric;
  
  /// Whether to show glue (connection lines)
  final bool showGlue;
  
  /// Whether to show clusters
  final bool showClusters;
  
  /// Whether to show bridge strands
  final bool showBridgeStrands;
  
  /// Glue visualization service (optional)
  final GlueVisualizationService? glueVizService;

  HierarchicalFabricPainter({
    required this.layout,
    required this.fabric,
    required this.showGlue,
    required this.showClusters,
    required this.showBridgeStrands,
    this.glueVizService,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw center entity (larger, highlighted)
    _drawCenterEntity(canvas, layout.center, center, size);
    
    // Draw surrounding entities in radial positions
    for (final entry in layout.positions.entries) {
      final entity = entry.key;
      final position = entry.value;
      
      // Convert radial position to canvas coordinates
      final entityCenter = Offset(
        center.dx + position.x,
        center.dy + position.y,
      );
      
      _drawEntity(canvas, entity, entityCenter, size);
      
      // Draw glue (connection lines)
      if (showGlue) {
        _drawGlue(
          canvas,
          layout.center,
          entity,
          center,
          entityCenter,
          layout.connectionStrengths[entity] ?? 0.0,
          size,
        );
      }
    }
    
    // Draw cluster boundaries
    if (showClusters) {
      _drawClusterBoundaries(canvas, fabric, size);
    }
    
    // Draw bridge strands (highlighted)
    if (showBridgeStrands) {
      _drawBridgeStrands(canvas, fabric, size);
    }
  }

  /// Draw center entity (larger, highlighted)
  void _drawCenterEntity(
    Canvas canvas,
    EntityKnot center,
    Offset position,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    // Draw larger circle for center
    canvas.drawCircle(position, 20.0, paint);
    
    // Draw highlight ring
    final highlightPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(position, 25.0, highlightPaint);
  }

  /// Draw entity (smaller circle)
  void _drawEntity(
    Canvas canvas,
    EntityKnot entity,
    Offset position,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;
    
    // Draw smaller circle for entity
    canvas.drawCircle(position, 10.0, paint);
  }

  /// Draw glue (connection line)
  void _drawGlue(
    Canvas canvas,
    EntityKnot center,
    EntityKnot entity,
    Offset centerPos,
    Offset entityPos,
    double strength,
    Size size,
  ) {
    if (glueVizService == null) {
      // Fallback: simple line
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(centerPos, entityPos, paint);
      return;
    }
    
    // Generate glue visualization
    glueVizService!.generateGlueVisualization(
      center: center,
      entity: entity,
      glueStrength: strength,
    ).then((glueViz) {
      final paint = Paint()
        ..color = glueViz.color.withValues(alpha: glueViz.opacity)
        ..strokeWidth = glueViz.thickness
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(centerPos, entityPos, paint);
    });
    
    // For now, use synchronous fallback
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5 * strength)
      ..strokeWidth = 1.0 + (strength * 4.0)
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(centerPos, entityPos, paint);
  }

  /// Draw cluster boundaries
  void _drawClusterBoundaries(
    Canvas canvas,
    KnotFabric fabric,
    Size size,
  ) {
    // Simplified: draw a circle around the fabric
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * 0.8;
    
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, radius, paint);
  }

  /// Draw bridge strands (highlighted)
  void _drawBridgeStrands(
    Canvas canvas,
    KnotFabric fabric,
    Size size,
  ) {
    // TODO: Implement bridge strand visualization
    // This would highlight entities that connect multiple clusters
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is HierarchicalFabricPainter) {
      return layout != oldDelegate.layout ||
          fabric != oldDelegate.fabric ||
          showGlue != oldDelegate.showGlue ||
          showClusters != oldDelegate.showClusters ||
          showBridgeStrands != oldDelegate.showBridgeStrands;
    }
    return true;
  }
}
