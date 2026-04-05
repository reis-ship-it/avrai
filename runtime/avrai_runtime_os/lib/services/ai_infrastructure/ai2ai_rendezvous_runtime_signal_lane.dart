import 'dart:async';

import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:flutter/widgets.dart';

class Ai2AiRendezvousRuntimeSignalLane with WidgetsBindingObserver {
  Ai2AiRendezvousRuntimeSignalLane({
    required Ai2AiRendezvousScheduler scheduler,
    WidgetsBinding? binding,
  })  : _scheduler = scheduler,
        _binding = binding ?? WidgetsBinding.instance;

  final Ai2AiRendezvousScheduler _scheduler;
  final WidgetsBinding _binding;

  bool _started = false;
  bool _isIdleState = false;

  bool get isIdle => _isIdleState;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _binding.addObserver(this);
    await _scheduler.start();
    _isIdleState = _isIdle(_binding.lifecycleState);
    await _scheduler.setIdleState(_isIdleState);
  }

  Future<void> dispose() async {
    if (!_started) {
      return;
    }
    _started = false;
    _binding.removeObserver(this);
    await _scheduler.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isIdleState = _isIdle(state);
    unawaited(_scheduler.setIdleState(_isIdleState));
  }

  bool _isIdle(AppLifecycleState? state) {
    return state != AppLifecycleState.resumed;
  }
}
