import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'dart:math' as math;

/// A high-tech "Turbine" loading indicator.
///
/// It consists of two counter-rotating metallic rings and a "breathing" core.
/// Replaces the standard CircularProgressIndicator for the Portal Design System.
class TurbineLoader extends StatefulWidget {
  final double size;
  final bool isDark;

  const TurbineLoader({
    super.key,
    this.size = 64.0,
    this.isDark = true,
  });

  @override
  State<TurbineLoader> createState() => _TurbineLoaderState();
}

class _TurbineLoaderState extends State<TurbineLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor =
        widget.isDark ? const Color(0xFFE0E0E0) : const Color(0xFF404040);
    final coreColor = AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ring 1: Clockwise, Slow
              Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    color: ringColor.withValues(alpha: 0.8),
                    sweepAngle: 3 * math.pi / 2,
                    strokeWidth: 3,
                  ),
                ),
              ),

              // Ring 2: Counter-Clockwise, Fast
              Transform.rotate(
                angle: -_controller.value * 4 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.7, widget.size * 0.7),
                  painter: _RingPainter(
                    color: ringColor.withValues(alpha: 0.6),
                    sweepAngle: math.pi,
                    strokeWidth: 2,
                  ),
                ),
              ),

              // Core: Breathing Pulse
              Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coreColor.withValues(
                    alpha:
                        0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: coreColor.withValues(alpha: 0.6),
                      blurRadius:
                          10 + 5 * math.sin(_controller.value * 2 * math.pi),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double sweepAngle;
  final double strokeWidth;

  _RingPainter({
    required this.color,
    required this.sweepAngle,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw segmented ring
    canvas.drawArc(rect, 0, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}
