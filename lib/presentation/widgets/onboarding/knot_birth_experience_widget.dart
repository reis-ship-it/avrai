// Knot Birth Experience Widget
//
// Full-screen immersive experience for the birth of a user's personality knot
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/audio/wavetable_knot_audio_service.dart';
import 'package:avrai/core/models/misc/visualization_style.dart';
import 'package:avrai/core/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/core/services/visualization/visualization_prewarmer.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';

/// Callback for phase changes during birth experience
typedef OnPhaseChangeCallback = void Function(BirthPhase phase);

/// Callback for birth experience completion
typedef OnBirthCompleteCallback = void Function();

/// Phases of the birth experience
enum BirthPhase {
  /// Initial fade to black (0-5s)
  transition,

  /// Single spark appears and pulses (5-10s)
  void_,

  /// Spark explodes to particles, swirl, gather (10-25s)
  emergence,

  /// Particles crystallize, tube materializes (25-45s)
  formation,

  /// Full glow, camera pullback, text overlay (45-60s)
  harmony,

  /// Experience complete
  complete,
}

/// Full-screen immersive experience for the birth of a user's personality knot
///
/// **Experience Flow:**
/// 1. **Transition** (0-5s): Screen fades to black
/// 2. **Void** (5-10s): Single spark appears, pulses
/// 3. **Emergence** (10-25s): Spark explodes to particles, swirl, gather
/// 4. **Formation** (25-45s): Particles crystallize into tube geometry
/// 5. **Harmony** (45-60s): Full glow, camera pullback, text reveals
///
/// **Audio Synchronization:**
/// - Rumble during transition
/// - First tone (knot frequency) during void
/// - Harmonics emerge during emergence
/// - Chord builds during formation
/// - Full resolution during harmony
class KnotBirthExperienceWidget extends StatefulWidget {
  /// The personality knot being born
  final PersonalityKnot knot;

  /// Callback when experience completes
  final OnBirthCompleteCallback? onComplete;

  /// Callback when phase changes
  final OnPhaseChangeCallback? onPhaseChange;

  /// Whether to show text overlays
  final bool showTextOverlays;

  /// Custom text for the "This is you" reveal
  final String? customRevealText;

  /// Whether to auto-dismiss after completion
  final bool autoDismiss;

  /// Delay before auto-dismiss (after harmony phase)
  final Duration autoDismissDelay;

  const KnotBirthExperienceWidget({
    super.key,
    required this.knot,
    this.onComplete,
    this.onPhaseChange,
    this.showTextOverlays = true,
    this.customRevealText,
    this.autoDismiss = false,
    this.autoDismissDelay = const Duration(seconds: 2),
  });

  @override
  State<KnotBirthExperienceWidget> createState() =>
      _KnotBirthExperienceWidgetState();
}

class _KnotBirthExperienceWidgetState extends State<KnotBirthExperienceWidget>
    with TickerProviderStateMixin {
  static const String _logName = 'KnotBirthExperienceWidget';

  ThreeJsBridgeService? _bridge;
  WavetableKnotAudioService? _audioService;
  BirthPhase _currentPhase = BirthPhase.transition;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;

  // Subscriptions
  StreamSubscription<String>? _phaseSubscription;
  StreamSubscription<Map<String, dynamic>>? _completeSubscription;

  @override
  void initState() {
    super.initState();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Start with fade to black
    _fadeController.forward();

    // Initialize audio service for birth harmony
    _initAudioService();

    // Try to use prewarmed birth experience
    _checkPrewarmed();
  }

  void _initAudioService() {
    try {
      if (GetIt.instance.isRegistered<WavetableKnotAudioService>()) {
        _audioService = GetIt.instance<WavetableKnotAudioService>();
        developer.log('WavetableKnotAudioService initialized for birth harmony',
            name: _logName);
      }
    } catch (e) {
      developer.log('WavetableKnotAudioService not available: $e',
          name: _logName);
      // Continue without audio - visual experience still works
    }
  }

  void _checkPrewarmed() {
    final prewarmer = VisualizationPrewarmer();
    if (prewarmer.isReady) {
      final bridge = prewarmer.getPrewarmedBridge();
      if (bridge != null) {
        developer.log('Using prewarmed birth experience', name: _logName);
        _bridge = bridge;
        _subscribeToEvents();
        _startBirthExperience();
        return;
      }
    }

    // Fall through to create new WebView
    developer.log('Creating new birth experience WebView', name: _logName);
  }

  void _onWebViewReady(ThreeJsBridgeService bridge) {
    developer.log('Birth experience WebView ready', name: _logName);
    _bridge = bridge;
    _subscribeToEvents();
    _startBirthExperience();
  }

  void _subscribeToEvents() {
    if (_bridge == null) return;

    _phaseSubscription = _bridge!.onPhaseChange.listen((phase) {
      _onPhaseChanged(phase);
    });

    _completeSubscription = _bridge!.onBirthComplete.listen((data) {
      _onBirthComplete();
    });
  }

  void _onPhaseChanged(String phaseName) {
    final phase = _parsePhase(phaseName);
    developer.log('Birth phase changed: $phase', name: _logName);

    setState(() {
      _currentPhase = phase;
    });

    widget.onPhaseChange?.call(phase);

    // Show text overlay during harmony phase
    if (phase == BirthPhase.harmony && widget.showTextOverlays) {
      _textController.forward();
    }
  }

  BirthPhase _parsePhase(String phaseName) {
    switch (phaseName.toLowerCase()) {
      case 'void':
        return BirthPhase.void_;
      case 'emergence':
        return BirthPhase.emergence;
      case 'formation':
        return BirthPhase.formation;
      case 'harmony':
        return BirthPhase.harmony;
      default:
        return BirthPhase.transition;
    }
  }

  void _onBirthComplete() {
    developer.log('Birth experience complete', name: _logName);

    setState(() {
      _currentPhase = BirthPhase.complete;
    });

    widget.onPhaseChange?.call(BirthPhase.complete);

    if (widget.autoDismiss) {
      Future.delayed(widget.autoDismissDelay, () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    }
  }

  Future<void> _startBirthExperience() async {
    if (_bridge == null) return;

    // Wait for fade to black
    await _fadeController.forward();

    // Start synchronized audio (60-second birth harmony)
    if (_audioService != null) {
      try {
        await _audioService!.playBirthHarmony(widget.knot);
        developer.log('Birth harmony audio started', name: _logName);
      } catch (e) {
        developer.log('Failed to start birth harmony audio: $e',
            name: _logName);
        // Continue without audio - visual experience still works
      }
    }

    // Start the birth experience in Three.js
    final style = KnotVisualizationStyle.birthExperience(
      primaryColor: AppColors.electricGreen.toHex(),
    );

    await _bridge!.startBirthExperience(
      knot: widget.knot,
      style: style,
    );

    // Update phase to void
    setState(() {
      _currentPhase = BirthPhase.void_;
    });
    widget.onPhaseChange?.call(BirthPhase.void_);
  }

  @override
  void dispose() {
    _phaseSubscription?.cancel();
    _completeSubscription?.cancel();
    _fadeController.dispose();
    _textController.dispose();

    // Stop any playing birth harmony audio
    _audioService?.stopAudio();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      child: Stack(
        children: [
          // Fade overlay (for transition)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: AppColors.black.withValues(alpha: _fadeAnimation.value),
              );
            },
          ),

          // Three.js visualization
          if (_fadeAnimation.value >= 0.8)
            Positioned.fill(
              child: BirthExperienceVisualizationWidget(
                onReady: _onWebViewReady,
                onPhaseChange: _onPhaseChanged,
                onBirthComplete: (_) => _onBirthComplete(),
              ),
            ),

          // Text overlays
          if (widget.showTextOverlays) _buildTextOverlay(),

          // Continue button (shown after complete)
          if (_currentPhase == BirthPhase.complete) _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: AnimatedBuilder(
        animation: _textController,
        builder: (context, child) {
          return Opacity(
            opacity: _textOpacity.value,
            child: Transform.scale(
              scale: _textScale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.customRevealText ?? 'This is you.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getKnotDescription(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w300,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getKnotDescription() {
    final invariants = widget.knot.invariants;
    final crossings = invariants.crossingNumber;
    final writhe = invariants.writhe;

    if (crossings <= 3) {
      return 'Simple. Elegant. True.';
    } else if (crossings <= 6) {
      return 'Complex. Interconnected. Unique.';
    } else {
      if (writhe > 0) {
        return 'Rich. Expansive. Boundless.';
      } else {
        return 'Deep. Intricate. Profound.';
      }
    }
  }

  Widget _buildContinueButton() {
    return Positioned(
      left: 40,
      right: 40,
      bottom: 40,
      child: AnimatedOpacity(
        opacity: _currentPhase == BirthPhase.complete ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: ElevatedButton(
          onPressed: widget.onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.black,
            padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Begin Your Journey',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
