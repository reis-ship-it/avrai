import 'package:flutter/material.dart';
import 'package:avrai_knot/models/dynamic_knot.dart';
import 'package:avrai/presentation/widgets/knot/personality_knot_widget.dart';

/// Widget for visualizing a dynamic knot with mood/energy/stress-based properties
/// Phase 4: Dynamic Knots (Mood/Energy)
class DynamicKnotWidget extends StatefulWidget {
  /// Dynamic knot to visualize
  final DynamicKnot knot;
  
  /// Size of the widget
  final double size;
  
  /// Whether to animate the knot
  final bool animated;
  
  const DynamicKnotWidget({
    super.key,
    required this.knot,
    this.size = 100.0,
    this.animated = true,
  });
  
  @override
  State<DynamicKnotWidget> createState() => _DynamicKnotWidgetState();
}

class _DynamicKnotWidgetState extends State<DynamicKnotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.animated) {
      // Pulse animation based on stress (pulse rate)
      _animationController = AnimationController(
        duration: Duration(
          milliseconds: (1000 / widget.knot.pulseRate).round(),
        ),
        vsync: this,
      )..repeat(reverse: true);
      
      _pulseAnimation = Tween<double>(
        begin: 0.95,
        end: 1.05,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
      
      // Rotation animation based on energy (animation speed)
      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 2 * 3.14159, // Full rotation
      ).animate(
        AnimationController(
          duration: Duration(
            milliseconds: (2000 / widget.knot.animationSpeed).round(),
          ),
          vsync: this,
        )..repeat(),
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.knot.colorScheme['primary'] ?? Colors.blue;
    final secondaryColor = widget.knot.colorScheme['secondary'] ?? Colors.teal;
    
    Widget knotVisualization = PersonalityKnotWidget(
      knot: widget.knot.baseKnot,
      size: widget.size,
    );
    
    if (widget.animated) {
      // Apply pulse animation
      knotVisualization = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: knotVisualization,
      );
      
      // Apply rotation animation
      knotVisualization = AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          );
        },
        child: knotVisualization,
      );
    }
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.3),
            secondaryColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(child: knotVisualization),
    );
  }
}
