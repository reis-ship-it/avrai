import 'dart:async';
import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:sensors_plus/sensors_plus.dart';

/// Text that looks like Satin Titanium with a live gyro-reactive shimmer.
class MetallicText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool isDayMode;

  const MetallicText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.isDayMode = true,
  });

  @override
  State<MetallicText> createState() => _MetallicTextState();
}

class _MetallicTextState extends State<MetallicText> {
  // Gradient Stops alignment
  // Default is TopLeft (-1, -1) to BottomRight (1, 1)
  Alignment _gradientBegin = Alignment.topLeft;
  Alignment _gradientEnd = Alignment.bottomRight;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  @override
  void initState() {
    super.initState();
    _startGyroShimmer();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    super.dispose();
  }

  void _startGyroShimmer() {
    try {
      // Use accelerometer to detect tilt (gravity vector)
      // Gravity z ~ 9.8 when flat. x/y vary with tilt.
      _accelSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;

        // Normalize x/y to -1..1 range roughly (gravity is ~10)
        // Invert X because tilting left (positive X? No, Android X is right)
        // Actually, let's just do a simple mapping.

        // Tilt X (Left/Right) -> Shift Horizontal Alignment
        // Tilt Y (Up/Down) -> Shift Vertical Alignment

        // Sensitivity factor
        const double sensitivity = 0.1;

        // Base alignment is (-1, -1) to (1, 1)
        // We add the tilt offset

        setState(() {
          // X: -10 (Left) to 10 (Right) -> Map to -1..1
          double dx = -event.x * sensitivity;
          double dy = event.y * sensitivity; // Y is Up on Android?

          // Clamp
          dx = dx.clamp(-0.5, 0.5);
          dy = dy.clamp(-0.5, 0.5);

          _gradientBegin = Alignment(-1.0 + dx, -1.0 + dy);
          _gradientEnd = Alignment(1.0 + dx, 1.0 + dy);
        });
      });
    } catch (e) {
      debugPrint('Gyro shimmer failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Satin Titanium Gradients
    final gradientColors = widget.isDayMode
        ? const [
            Color(0xFFE0E0E0), // Light Platinum
            Color(0xFFB0B0B0), // Mid Grey
            Color(0xFFE0E0E0), // Light Platinum (Reflection)
            Color(0xFF909090), // Darker Steel
          ]
        : const [
            Color(0xFF707070), // Gunmetal Light
            Color(0xFF404040), // Charcoal
            Color(0xFF707070), // Gunmetal Light (Reflection)
            Color(0xFF303030), // Deep Graphite
          ];

    final stops = [0.0, 0.4, 0.6, 1.0];

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: _gradientBegin,
          end: _gradientEnd,
          colors: gradientColors,
          stops: stops,
        ).createShader(bounds);
      },
      child: Text(
        widget.text,
        textAlign: widget.textAlign,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: AppColors.white, // Required for shader mask to work
          shadows: [
            Shadow(
              offset: const Offset(0, 2),
              blurRadius: 4,
              color: AppColors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
