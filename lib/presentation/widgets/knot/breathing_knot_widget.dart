import 'package:flutter/material.dart';
import 'package:avrai_knot/models/dynamic_knot.dart';
import 'package:avrai/presentation/widgets/knot/personality_knot_widget.dart';

/// Widget for visualizing a breathing knot for meditation
/// Phase 4: Dynamic Knots (Mood/Energy)
class BreathingKnotWidget extends StatefulWidget {
  /// Animated knot for breathing visualization
  final AnimatedKnot animatedKnot;
  
  /// Size of the widget
  final double size;
  
  const BreathingKnotWidget({
    super.key,
    required this.animatedKnot,
    this.size = 200.0,
  });
  
  @override
  State<BreathingKnotWidget> createState() => _BreathingKnotWidgetState();
}

class _BreathingKnotWidgetState extends State<BreathingKnotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Breathing animation: slow in, slow out (like breathing)
    _breathingController = AnimationController(
      duration: Duration(
        milliseconds: (3000 / widget.animatedKnot.animationSpeed).round(),
      ),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Color transition animation
    if (widget.animatedKnot.colorTransition.length >= 2) {
      _colorAnimation = ColorTween(
        begin: widget.animatedKnot.colorTransition[0],
        end: widget.animatedKnot.colorTransition[1],
      ).animate(
        CurvedAnimation(
          parent: _breathingController,
          curve: Curves.easeInOut,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        final currentColor = _colorAnimation.value ??
            widget.animatedKnot.colorTransition[0];
        
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                currentColor.withValues(alpha: 0.4),
                currentColor.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: _breathingAnimation.value,
              child: PersonalityKnotWidget(
                knot: widget.animatedKnot.knot,
                size: widget.size * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }
}
