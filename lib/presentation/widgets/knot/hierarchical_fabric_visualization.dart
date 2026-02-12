// Hierarchical Fabric Visualization Widget
// 
// Widget for visualizing hierarchical fabric layouts
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/hierarchical_layout.dart';
import 'package:avrai_knot/services/knot/hierarchical_layout_service.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai/presentation/widgets/knot/hierarchical_fabric_painter.dart';

/// Widget for visualizing hierarchical fabric layouts
class HierarchicalFabricVisualization extends StatefulWidget {
  /// The knot fabric to visualize
  final KnotFabric fabric;
  
  /// Whether to show glue (connection lines)
  final bool showGlue;
  
  /// Whether to show clusters
  final bool showClusters;
  
  /// Whether to show bridge strands
  final bool showBridgeStrands;
  
  /// Size of the visualization
  final double size;

  const HierarchicalFabricVisualization({
    super.key,
    required this.fabric,
    this.showGlue = true,
    this.showClusters = true,
    this.showBridgeStrands = true,
    this.size = 400.0,
  });

  @override
  State<HierarchicalFabricVisualization> createState() =>
      _HierarchicalFabricVisualizationState();
}

class _HierarchicalFabricVisualizationState
    extends State<HierarchicalFabricVisualization> {
  HierarchicalLayoutService? _layoutService;
  HierarchicalLayout? _layout;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    // TODO: Get layout service from DI
    // For now, this is a placeholder - the actual service should be injected
    // _layoutService = GetIt.instance<HierarchicalLayoutService>();
    
    // Convert PersonalityKnot to EntityKnot for layout generation
    // This is a simplified conversion - in production, you'd want proper conversion
    final entityKnots = widget.fabric.userKnots.map((knot) {
      return EntityKnot(
        entityId: knot.agentId,
        entityType: EntityType.person,
        knot: knot,
        metadata: {},
        createdAt: knot.createdAt,
        lastUpdated: knot.lastUpdated,
      );
    }).toList();

    // Generate layout (if service is available)
    if (_layoutService != null) {
      try {
        final layout = await _layoutService!.generateLayout(
          cluster: entityKnots,
          fabric: widget.fabric,
        );
        
        if (mounted) {
          setState(() {
            _layout = layout;
          });
        }
      } catch (e) {
        // Handle error
        developer.log('Error generating layout: $e', name: 'HierarchicalFabricVisualization');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_layout == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: HierarchicalFabricPainter(
          layout: _layout!,
          fabric: widget.fabric,
          showGlue: widget.showGlue,
          showClusters: widget.showClusters,
          showBridgeStrands: widget.showBridgeStrands,
        ),
        child: Container(),
      ),
    );
  }
}
