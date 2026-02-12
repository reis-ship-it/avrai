// Knot 3D Animation Widget
// 
// Widget for animated 3D knot evolution visualization
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1: 3D Knot Visualization and Conversion

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_3d_converter_service.dart';
import 'package:avrai/presentation/widgets/knot/knot_3d_widget.dart';

/// Widget for animated 3D knot evolution
/// 
/// Features:
/// - Load knot evolution history
/// - Interpolate between snapshots in 3D space
/// - Smooth animation of knot transformation
/// - Timeline controls (play, pause, scrub)
class Knot3DAnimationWidget extends StatefulWidget {
  final String agentId;
  final double size;
  final Color? color;
  final KnotEvolutionStringService? stringService;
  final Knot3DConverterService? converterService;

  const Knot3DAnimationWidget({
    super.key,
    required this.agentId,
    this.size = 400.0,
    this.color,
    this.stringService,
    this.converterService,
  });

  @override
  State<Knot3DAnimationWidget> createState() => _Knot3DAnimationWidgetState();
}

class _Knot3DAnimationWidgetState extends State<Knot3DAnimationWidget>
    with TickerProviderStateMixin {
  List<PersonalityKnot> _evolutionKnots = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _loadEvolutionHistory();
  }

  Future<void> _loadEvolutionHistory() async {
    try {
      final stringService = widget.stringService;
      if (stringService == null) {
        setState(() {
          _error = 'String service not available';
          _isLoading = false;
        });
        return;
      }

      // Get evolution trajectory
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final trajectory = await stringService.getEvolutionTrajectory(
        agentId: widget.agentId,
        start: start,
        end: now,
        step: const Duration(days: 1),
      );

      if (mounted) {
        setState(() {
          _evolutionKnots = trajectory;
          _isLoading = false;
          
          if (_evolutionKnots.isEmpty) {
            _error = 'No evolution history found';
          }
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

  void _play() {
    if (_evolutionKnots.length < 2) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    _animationController.forward().then((_) {
      if (mounted && _currentIndex < _evolutionKnots.length - 1) {
        setState(() {
          _currentIndex++;
          _animationController.reset();
        });
        _play(); // Continue to next knot
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _pause() {
    _animationController.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _reset() {
    _animationController.reset();
    setState(() {
      _currentIndex = 0;
      _isPlaying = false;
    });
  }

  void _scrubTo(int index) {
    setState(() {
      _currentIndex = index.clamp(0, _evolutionKnots.length - 1);
      _animationController.value = 0.0;
    });
  }

  PersonalityKnot? _getCurrentKnot() {
    if (_evolutionKnots.isEmpty) return null;
    if (_currentIndex >= _evolutionKnots.length) return _evolutionKnots.last;
    
    final current = _evolutionKnots[_currentIndex];
    
    // If playing and not at last knot, interpolate to next
    if (_isPlaying && _currentIndex < _evolutionKnots.length - 1) {
      final next = _evolutionKnots[_currentIndex + 1];
      final factor = _animation.value;
      
      // Simple interpolation (would use polynomial in Phase 3)
      return _interpolateKnots(current, next, factor);
    }
    
    return current;
  }

  PersonalityKnot _interpolateKnots(
    PersonalityKnot knot1,
    PersonalityKnot knot2,
    double factor,
  ) {
    // Simple linear interpolation (will be enhanced with polynomial in Phase 3)
    final jones1 = knot1.invariants.jonesPolynomial;
    final jones2 = knot2.invariants.jonesPolynomial;
    final interpolatedJones = <double>[];
    
    final maxLength = jones1.length > jones2.length ? jones1.length : jones2.length;
    for (int i = 0; i < maxLength; i++) {
      final val1 = i < jones1.length ? jones1[i] : 0.0;
      final val2 = i < jones2.length ? jones2[i] : 0.0;
      interpolatedJones.add(val1 * (1 - factor) + val2 * factor);
    }
    
    // Interpolate other invariants
    final interpolatedCrossings = ((knot1.invariants.crossingNumber * (1 - factor)) +
            (knot2.invariants.crossingNumber * factor))
        .round();
    
    final interpolatedWrithe = ((knot1.invariants.writhe * (1 - factor)) +
            (knot2.invariants.writhe * factor))
        .round();
    
    return PersonalityKnot(
      agentId: knot1.agentId,
      invariants: KnotInvariants(
        jonesPolynomial: interpolatedJones,
        alexanderPolynomial: knot1.invariants.alexanderPolynomial, // Simplified
        crossingNumber: interpolatedCrossings,
        writhe: interpolatedWrithe,
        signature: knot1.invariants.signature, // Simplified
        unknottingNumber: knot1.invariants.unknottingNumber,
        bridgeNumber: knot1.invariants.bridgeNumber,
        braidIndex: knot1.invariants.braidIndex,
        determinant: knot1.invariants.determinant,
        arfInvariant: knot1.invariants.arfInvariant,
        hyperbolicVolume: knot1.invariants.hyperbolicVolume,
        homflyPolynomial: knot1.invariants.homflyPolynomial,
      ),
      braidData: knot1.braidData, // Simplified
      createdAt: knot1.createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    if (_evolutionKnots.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: Text('No evolution history'),
        ),
      );
    }

    final currentKnot = _getCurrentKnot();
    if (currentKnot == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: Text('No knot data'),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D visualization
        Knot3DWidget(
          knot: currentKnot,
          size: widget.size,
          showControls: false,
          color: widget.color,
          converterService: widget.converterService,
        ),
        
        // Timeline controls
        const SizedBox(height: 16),
        
        // Progress indicator
        Text(
          '${_currentIndex + 1} / ${_evolutionKnots.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        
        const SizedBox(height: 8),
        
        // Timeline slider
        Slider(
          value: _currentIndex.toDouble(),
          min: 0,
          max: (_evolutionKnots.length - 1).toDouble(),
          divisions: _evolutionKnots.length - 1,
          label: '${_currentIndex + 1}',
          onChanged: (value) {
            _scrubTo(value.round());
          },
        ),
        
        const SizedBox(height: 8),
        
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: _currentIndex > 0
                  ? () => _scrubTo(_currentIndex - 1)
                  : null,
              tooltip: 'Previous',
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _isPlaying ? _pause : _play,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _currentIndex < _evolutionKnots.length - 1
                  ? () => _scrubTo(_currentIndex + 1)
                  : null,
              tooltip: 'Next',
            ),
          ],
        ),
      ],
    );
  }
}
