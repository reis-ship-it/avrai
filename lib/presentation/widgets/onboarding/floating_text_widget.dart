/// Floating Text Widget
/// 
/// Displays text with individual letter animations that float gently.
/// Each letter has a staggered entrance with a bubbly elastic curve,
/// followed by a continuous gentle floating motion.
/// 
/// Features:
/// - Bubbly entrance animation (elasticOut curve)
/// - Continuous floating motion (sine wave)
/// - Staggered timing for each letter
/// - 60fps performance target
/// - Reduced motion support
/// 
/// Uses AppColors for 100% design token adherence.
library;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:avrai/core/theme/colors.dart';

class FloatingTextWidget extends StatefulWidget {
  /// The text to display with floating animation
  final String text;
  
  /// Text style (defaults to large display style)
  final TextStyle? textStyle;
  
  /// Duration of entrance animation per letter
  final Duration entranceDuration;
  
  /// Duration of one float cycle
  final Duration floatDuration;
  
  /// Distance letters float up/down (in pixels)
  final double floatDistance;
  
  /// Delay between each letter's entrance
  final Duration staggerDelay;
  
  const FloatingTextWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.entranceDuration = const Duration(milliseconds: 800),
    this.floatDuration = const Duration(milliseconds: 2500),
    this.floatDistance = 8.0,
    this.staggerDelay = const Duration(milliseconds: 50),
  });
  
  @override
  State<FloatingTextWidget> createState() => _FloatingTextWidgetState();
}

class _FloatingTextWidgetState extends State<FloatingTextWidget>
    with TickerProviderStateMixin {
  final List<AnimationController> _entranceControllers = [];
  final List<AnimationController> _floatControllers = [];
  final List<Animation<double>> _entranceAnimations = [];
  final List<Animation<double>> _floatAnimations = [];
  final List<Timer> _staggerTimers = [];
  
  bool _reducedMotion = false;
  bool _disposed = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for reduced motion preference
    _reducedMotion = MediaQuery.of(context).disableAnimations;
  }
  
  void _initAnimations() {
    final letters = widget.text.split('');
    
    for (int i = 0; i < letters.length; i++) {
      // Skip animation setup for spaces
      if (letters[i] == ' ') {
        _entranceControllers.add(AnimationController(vsync: this));
        _floatControllers.add(AnimationController(vsync: this));
        _entranceAnimations.add(const AlwaysStoppedAnimation(1.0));
        _floatAnimations.add(const AlwaysStoppedAnimation(0.0));
        continue;
      }
      
      // Entrance animation controller
      final entranceController = AnimationController(
        duration: widget.entranceDuration,
        vsync: this,
      );
      
      // Entrance animation: fade + scale with elastic curve
      final entranceAnimation = CurvedAnimation(
        parent: entranceController,
        curve: Curves.elasticOut,
      );
      
      _entranceControllers.add(entranceController);
      _entranceAnimations.add(entranceAnimation);
      
      // Float animation controller (loops continuously)
      final floatController = AnimationController(
        duration: widget.floatDuration,
        vsync: this,
      );
      
      // Float animation: gentle sine wave motion
      final floatAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: floatController,
        curve: Curves.easeInOut,
      ));
      
      _floatControllers.add(floatController);
      _floatAnimations.add(floatAnimation);
      
      // Start entrance with stagger using Timer instead of Future.delayed
      // This allows proper cleanup in tests
      final staggerTimer = Timer(widget.staggerDelay * i, () {
        if (!_disposed && mounted && !_reducedMotion) {
          entranceController.forward().then((_) {
            // Start float loop after entrance completes
            if (!_disposed && mounted && !_reducedMotion) {
              floatController.repeat();
            }
          });
        } else if (!_disposed && mounted && _reducedMotion) {
          // Skip animations if reduced motion
          entranceController.value = 1.0;
        }
      });
      _staggerTimers.add(staggerTimer);
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    
    // Cancel all stagger timers
    for (final timer in _staggerTimers) {
      timer.cancel();
    }
    _staggerTimers.clear();
    
    // Dispose all animation controllers
    for (final controller in _entranceControllers) {
      controller.dispose();
    }
    for (final controller in _floatControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');
    const defaultStyle = TextStyle(
      fontSize: 42,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.4,
      letterSpacing: 1.0,
    );
    
    final textStyle = widget.textStyle ?? defaultStyle;
    
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        
        // Handle spaces without animation
        if (letter == ' ') {
          return SizedBox(
            width: textStyle.fontSize != null ? textStyle.fontSize! * 0.3 : 12,
            height: textStyle.fontSize ?? 42,
          );
        }
        
        return AnimatedBuilder(
          animation: Listenable.merge([
            _entranceAnimations[index],
            _floatAnimations[index],
          ]),
          builder: (context, child) {
            final entrance = _entranceAnimations[index].value;
            final float = _floatAnimations[index].value;
            
            // Calculate float offset using sine wave
            final floatOffset = math.sin(float * 2 * math.pi) * widget.floatDistance;
            
            return Transform.translate(
              offset: Offset(0, -floatOffset),
              child: Transform.scale(
                scale: entrance.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: entrance.clamp(0.0, 1.0),
                  child: Text(
                    letter,
                    style: textStyle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Simple typing indicator for "tap to continue" hint
class PulsingHintWidget extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  
  const PulsingHintWidget({
    super.key,
    required this.text,
    this.textStyle,
  });
  
  @override
  State<PulsingHintWidget> createState() => _PulsingHintWidgetState();
}

class _PulsingHintWidgetState extends State<PulsingHintWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    const defaultStyle = TextStyle(
      fontSize: 16,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            widget.text,
            style: widget.textStyle ?? defaultStyle,
          ),
        );
      },
    );
  }
}

