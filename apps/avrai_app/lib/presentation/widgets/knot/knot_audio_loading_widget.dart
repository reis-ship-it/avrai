// Knot Audio Loading Widget
//
// Optional widget that plays knot-based audio during loading
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Audio Integration

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

/// Widget that optionally plays knot-based audio during loading
///
/// **Usage:**
/// ```dart
/// KnotAudioLoadingWidget(
///   userId: userId,
///   enabled: true, // Optional, defaults to false
/// )
/// ```
///
/// **Note:** Audio synthesis from frequencies requires additional work.
/// This widget is ready for integration but audio playback is simplified.
class KnotAudioLoadingWidget extends StatefulWidget {
  final String? userId;
  final bool enabled;

  const KnotAudioLoadingWidget({
    super.key,
    this.userId,
    this.enabled = false, // Default to false until audio synthesis is complete
  });

  @override
  State<KnotAudioLoadingWidget> createState() => _KnotAudioLoadingWidgetState();
}

class _KnotAudioLoadingWidgetState extends State<KnotAudioLoadingWidget> {
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled && widget.userId != null) {
      _startKnotAudio();
    }
  }

  @override
  void dispose() {
    if (_audioStarted) {
      // Audio is optional; avoid hard dependency on DI in tests/limited builds.
      final sl = GetIt.instance;
      if (sl.isRegistered<WavetableKnotAudioService>()) {
        sl<WavetableKnotAudioService>().stopAudio();
      }
    }
    super.dispose();
  }

  Future<void> _startKnotAudio() async {
    if (_audioStarted || widget.userId == null) return;

    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<AgentIdService>() ||
          !sl.isRegistered<KnotStorageService>() ||
          !sl.isRegistered<WavetableKnotAudioService>()) {
        // Fail silently - audio is optional.
        return;
      }

      final agentIdService = sl<AgentIdService>();
      final knotStorageService = sl<KnotStorageService>();
      final knotAudioService = sl<WavetableKnotAudioService>();

      // Get agent ID
      final agentId = await agentIdService.getUserAgentId(widget.userId!);

      // Load knot
      final knot = await knotStorageService.loadKnot(agentId);

      if (knot != null && mounted) {
        // Play audio (simplified - full synthesis requires additional work)
        await knotAudioService.playKnotLoadingSound(knot);

        setState(() {
          _audioStarted = true;
        });

        developer.log(
          'Started knot audio for loading',
          name: 'KnotAudioLoadingWidget',
        );
      }
    } catch (e) {
      developer.log(
        'Could not start knot audio: $e',
        name: 'KnotAudioLoadingWidget',
      );
      // Fail silently - audio is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything - it just plays audio in the background
    return const SizedBox.shrink();
  }
}
