// String Evolution Widget
// 
// Widget for visualizing string evolution as animated curves
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:math' as math;
import 'package:flutter/material.dart' hide Colors;
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Widget for visualizing string evolution
/// 
/// Features:
/// - Animated curve visualization of knot evolution
/// - Time-based playback
/// - Multiple property visualization (crossing number, density, stability)
/// - Interactive timeline
class StringEvolutionWidget extends StatefulWidget {
  final String agentId;
  final double width;
  final double height;
  final KnotEvolutionStringService stringService;

  const StringEvolutionWidget({
    super.key,
    required this.agentId,
    required this.stringService,
    this.width = 400.0,
    this.height = 300.0,
  });

  @override
  State<StringEvolutionWidget> createState() => _StringEvolutionWidgetState();
}

class _StringEvolutionWidgetState extends State<StringEvolutionWidget>
    with TickerProviderStateMixin {
  KnotString? _string;
  bool _isLoading = true;
  String? _error;

  // Animation state
  bool _isPlaying = false;
  late AnimationController _animationController;
  double _animationProgress = 0.0;

  // Visualization properties
  String _selectedProperty = 'crossing_number'; // crossing_number, writhe, signature

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _animationProgress = _animationController.value;
          });
        }
      });
    _loadString();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadString() async {
    try {
      final string = await widget.stringService.createStringFromHistory(widget.agentId);

      if (mounted) {
        setState(() {
          _string = string;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _resetAnimation() {
    _animationController.reset();
    setState(() {
      _animationProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: widget.width * 0.1,
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading string',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    if (_string == null || _string!.snapshots.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline,
                size: widget.width * 0.1,
                color: AppColors.grey400,
              ),
              const SizedBox(height: 8),
              Text(
                'No string evolution data',
                style: TextStyle(color: AppColors.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visualization
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: StringEvolutionPainter(
              string: _string!,
              progress: _animationProgress,
              selectedProperty: _selectedProperty,
            ),
          ),
        ),

        // Controls
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnimation,
              tooltip: 'Reset',
            ),
          ],
        ),

        // Property selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButton<String>(
            value: _selectedProperty,
            items: const [
              DropdownMenuItem(
                value: 'crossing_number',
                child: Text('Crossing Number'),
              ),
              DropdownMenuItem(
                value: 'writhe',
                child: Text('Writhe'),
              ),
              DropdownMenuItem(
                value: 'signature',
                child: Text('Signature'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedProperty = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Custom painter for string evolution visualization
class StringEvolutionPainter extends CustomPainter {
  final KnotString string;
  final double progress;
  final String selectedProperty;

  StringEvolutionPainter({
    required this.string,
    required this.progress,
    required this.selectedProperty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (string.snapshots.isEmpty) return;

    final sorted = List.from(string.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Determine time range
    final startTime = sorted.first.timestamp;
    final endTime = sorted.last.timestamp;
    final timeSpan = endTime.difference(startTime);

    if (timeSpan.inMilliseconds == 0) return;

    // Calculate current time based on progress
    final currentTime = startTime.add(
      Duration(
        milliseconds: (timeSpan.inMilliseconds * progress).round(),
      ),
    );

    // Get property values
    final propertyValues = <double>[];
    final timePoints = <DateTime>[];

    // Add initial knot
    final initialValue = _getPropertyValue(string.initialKnot);
    propertyValues.add(initialValue);
    timePoints.add(startTime.subtract(const Duration(hours: 1))); // Before first snapshot

    // Add snapshots up to current time
    for (final snapshot in sorted) {
      if (snapshot.timestamp.isBefore(currentTime) ||
          snapshot.timestamp == currentTime) {
        final value = _getPropertyValue(snapshot.knot);
        propertyValues.add(value);
        timePoints.add(snapshot.timestamp);
      }
    }

    if (propertyValues.isEmpty) return;

    // Normalize values to 0-1 range for visualization
    final minValue = propertyValues.reduce(math.min);
    final maxValue = propertyValues.reduce(math.max);
    final range = maxValue - minValue;

    if (range == 0) return;

    // Draw axes
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.grey400;

    // X-axis (time)
    canvas.drawLine(
      Offset(40, size.height - 40),
      Offset(size.width - 20, size.height - 40),
      paint,
    );

    // Y-axis (property value)
    canvas.drawLine(
      Offset(40, 20),
      Offset(40, size.height - 40),
      paint,
    );

    // Draw curve
    if (propertyValues.length > 1) {
      final curvePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = AppColors.primary;

      final path = Path();

      for (int i = 0; i < propertyValues.length; i++) {
        final normalizedValue = (propertyValues[i] - minValue) / range;
        final x = 40 + (i / (propertyValues.length - 1)) * (size.width - 60);
        final y = size.height - 40 - (normalizedValue * (size.height - 60));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, curvePaint);

      // Draw points
      final pointPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary;

      for (int i = 0; i < propertyValues.length; i++) {
        final normalizedValue = (propertyValues[i] - minValue) / range;
        final x = 40 + (i / (propertyValues.length - 1)) * (size.width - 60);
        final y = size.height - 40 - (normalizedValue * (size.height - 60));

        canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
      }
    }
  }

  double _getPropertyValue(PersonalityKnot knot) {
    switch (selectedProperty) {
      case 'crossing_number':
        return knot.invariants.crossingNumber.toDouble();
      case 'writhe':
        return knot.invariants.writhe.toDouble();
      case 'signature':
        return knot.invariants.signature.toDouble();
      default:
        return 0.0;
    }
  }

  @override
  bool shouldRepaint(StringEvolutionPainter oldDelegate) {
    return oldDelegate.string != string ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedProperty != selectedProperty;
  }
}
