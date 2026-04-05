import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _MetallicTextState extends State<MetallicText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<({Alignment begin, Alignment end})> _alignments =
      ValueNotifier((
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ));

  double _targetDx = 0.0;
  double _targetDy = 0.0;
  double _currentDx = 0.0;
  double _currentDy = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _startGyroShimmer();
  }

  void _onTick(Duration elapsed) {
    // Damping factor for heavy, premium feel
    const double damping = 0.08;

    // Only update if there is a meaningful difference
    if ((_targetDx - _currentDx).abs() > 0.001 ||
        (_targetDy - _currentDy).abs() > 0.001) {
      _currentDx += (_targetDx - _currentDx) * damping;
      _currentDy += (_targetDy - _currentDy) * damping;

      _alignments.value = (
        begin: Alignment(-1.0 + _currentDx, -1.0 + _currentDy),
        end: Alignment(1.0 + _currentDx, 1.0 + _currentDy),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _alignments.dispose();
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
        // Sensitivity factor
        const double sensitivity = 0.1;

        double dx = -event.x * sensitivity;
        double dy = event.y * sensitivity; // Y is Up on Android?

        // Clamp
        _targetDx = dx.clamp(-0.5, 0.5);
        _targetDy = dy.clamp(-0.5, 0.5);
      });
    } catch (e) {
      debugPrint('Gyro shimmer failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Soft Brushed Metal Gradients
    final gradientColors = widget.isDayMode
        ? const [
            Color(0xFFF5F5F0), // Soft Pearl
            Color(0xFFD5D5D0), // Warm Silver
            Color(0xFFF0F0EB), // Pearl Reflection
            Color(0xFFB5B5B0), // Brushed Nickel
          ]
        : const [
            Color(0xFFA09A95), // Warm Gunmetal
            Color(0xFF706A65), // Soft Charcoal
            Color(0xFF958F8A), // Warm Reflection
            Color(0xFF504A45), // Deep Bronze
          ];

    final stops = const [0.0, 0.4, 0.6, 1.0];

    return ValueListenableBuilder<({Alignment begin, Alignment end})>(
      valueListenable: _alignments,
      builder: (context, alignments, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: alignments.begin,
              end: alignments.end,
              colors: gradientColors,
              stops: stops,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        textAlign: widget.textAlign,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: AppColors.white, // Required for shader mask to work
          shadows: [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 2,
              color: AppColors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
