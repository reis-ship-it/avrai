// Knot Formation Sync Widget
//
// Synchronized audio-visual knot formation animation
// Combines KnotFormationWidget with evolving audio
//
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Onboarding: AI Loading Page Enhancement

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai/presentation/widgets/knot/knot_formation_widget.dart';

/// Synchronized audio-visual knot formation widget
///
/// Displays the knot forming animation while playing evolving audio
/// that transitions from cacophony (chaos) to harmony (complete knot).
///
/// **Usage (auto-timed):**
/// ```dart
/// KnotFormationSyncWidget(
///   userId: userId,
///   size: 200,
///   onComplete: () => navigateToHome(),
/// )
/// ```
///
/// **Usage (externally controlled - synced to actual work):**
/// ```dart
/// KnotFormationSyncWidget(
///   userId: userId,
///   size: 200,
///   externalProgress: _workProgress, // 0.0 to 1.0
///   onComplete: () => navigateToHome(),
/// )
/// ```
class KnotFormationSyncWidget extends StatefulWidget {
  /// User ID to load/generate knot for
  final String? userId;

  /// Pre-loaded knot (optional, will generate if not provided)
  final PersonalityKnot? knot;

  /// Size of the visualization
  final double size;

  /// Duration of the formation animation (used when not externally controlled)
  final Duration duration;

  /// Called when formation is complete
  final VoidCallback? onComplete;

  /// Called with progress updates (0.0 to 1.0)
  final ValueChanged<double>? onProgress;

  /// Called when phase changes
  final ValueChanged<KnotFormationPhase>? onPhaseChange;

  /// Whether to auto-start when mounted (ignored if externalProgress provided)
  final bool autoStart;

  /// Whether to enable audio (default true)
  final bool enableAudio;

  /// Base color override
  final Color? baseColor;

  /// External progress value (0.0 to 1.0) to drive animation
  /// When provided, animation is synced to this value (e.g., actual work progress)
  final double? externalProgress;

  const KnotFormationSyncWidget({
    super.key,
    this.userId,
    this.knot,
    this.size = 200.0,
    this.duration = const Duration(seconds: 8),
    this.onComplete,
    this.onProgress,
    this.onPhaseChange,
    this.autoStart = true,
    this.enableAudio = true,
    this.baseColor,
    this.externalProgress,
  });

  @override
  State<KnotFormationSyncWidget> createState() =>
      _KnotFormationSyncWidgetState();
}

class _KnotFormationSyncWidgetState extends State<KnotFormationSyncWidget> {
  static const String _logName = 'KnotFormationSyncWidget';

  PersonalityKnot? _knot;
  bool _isLoading = true;
  bool _audioStarted = false;
  String? _error;

  final GlobalKey<KnotFormationWidgetState> _formationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeKnot();
  }

  Future<void> _initializeKnot() async {
    if (widget.knot != null) {
      // Use provided knot
      setState(() {
        _knot = widget.knot;
        _isLoading = false;
      });
      _startFormation();
      return;
    }

    // Start formation immediately with placeholder animation
    // Don't wait for knot to load - show particles right away
    setState(() {
      _isLoading = false;
    });
    _startFormation();

    if (widget.userId == null) {
      // No user ID, use placeholder formation only
      return;
    }

    // Try to load knot from storage (with polling for generation) in background
    // When knot becomes available, it will update the animation
    _loadKnotInBackground();
  }

  Future<void> _loadKnotInBackground() async {
    const maxAttempts = 20;
    const delayBetweenAttempts = Duration(milliseconds: 500);

    for (int attempt = 0; attempt < maxAttempts && mounted; attempt++) {
      try {
        final sl = GetIt.instance;

        if (!sl.isRegistered<AgentIdService>() ||
            !sl.isRegistered<KnotStorageService>()) {
          break;
        }

        final agentIdService = sl<AgentIdService>();
        final knotStorageService = sl<KnotStorageService>();

        final agentId = await agentIdService.getUserAgentId(widget.userId!);
        final knot = await knotStorageService.loadKnot(agentId);

        if (knot != null && mounted) {
          developer.log(
            'Loaded knot for formation (attempt ${attempt + 1})',
            name: _logName,
          );
          setState(() {
            _knot = knot;
          });
          // Start audio now that we have the real knot
          if (widget.enableAudio && !_audioStarted) {
            _startFormationAudio();
          }
          return;
        }
      } catch (e) {
        developer.log(
          'Knot load attempt ${attempt + 1} failed: $e',
          name: _logName,
        );
      }

      await Future.delayed(delayBetweenAttempts);
    }

    developer.log(
      'Knot not available after polling, continuing with generic formation',
      name: _logName,
    );
  }

  void _startFormation() {
    if (!widget.autoStart) return;

    // Start audio if available and enabled
    if (widget.enableAudio && _knot != null) {
      _startFormationAudio();
    }
  }

  Future<void> _startFormationAudio() async {
    if (_audioStarted || _knot == null) return;

    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<WavetableKnotAudioService>()) {
        developer.log(
          'WavetableKnotAudioService not registered, skipping audio',
          name: _logName,
        );
        return;
      }

      final audioService = sl<WavetableKnotAudioService>();
      await audioService.playFormationSound(_knot!);
      _audioStarted = true;

      developer.log(
        'Started formation audio',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Failed to start formation audio: $e',
        name: _logName,
      );
    }
  }

  void _onPhaseChange(KnotFormationPhase phase) {
    widget.onPhaseChange?.call(phase);

    developer.log(
      'Formation phase: ${phase.name}',
      name: _logName,
    );
  }

  void _onProgress(double progress) {
    widget.onProgress?.call(progress);
  }

  void _onComplete() {
    developer.log(
      'Formation complete',
      name: _logName,
    );

    // Stop audio
    _stopAudio();

    widget.onComplete?.call();
  }

  Future<void> _stopAudio() async {
    if (!_audioStarted) return;

    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<WavetableKnotAudioService>()) {
        await sl<WavetableKnotAudioService>().stopAudio();
      }
    } catch (e) {
      developer.log(
        'Failed to stop audio: $e',
        name: _logName,
      );
    }
  }

  @override
  void dispose() {
    _stopAudio();
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
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    return KnotFormationWidget(
      key: _formationKey,
      targetKnot: _knot,
      size: widget.size,
      duration: widget.duration,
      autoStart: widget.externalProgress == null && widget.autoStart,
      baseColor: widget.baseColor,
      externalProgress: widget.externalProgress,
      onPhaseChange: _onPhaseChange,
      onProgress: _onProgress,
      onComplete: _onComplete,
    );
  }
}

/// Phase description widget (optional overlay)
class KnotFormationPhaseLabel extends StatelessWidget {
  final KnotFormationPhase phase;
  final Color? textColor;

  const KnotFormationPhaseLabel({
    super.key,
    required this.phase,
    this.textColor,
  });

  String get _phaseLabel {
    switch (phase) {
      case KnotFormationPhase.quantumChaos:
        return 'Quantum particles emerging...';
      case KnotFormationPhase.stringFormation:
        return 'Strings forming...';
      case KnotFormationPhase.knotWeaving:
        return 'Weaving your personality...';
      case KnotFormationPhase.complete:
        return 'Your unique knot is ready!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _phaseLabel,
        key: ValueKey(phase),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor ?? Colors.white70,
              fontStyle: FontStyle.italic,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
