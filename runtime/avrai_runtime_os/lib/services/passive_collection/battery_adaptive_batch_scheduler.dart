import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';

/// Represents a batch processing job that requires LLM context/processing power.
abstract class MicroBatchJob {
  final String id;
  final String description;

  MicroBatchJob(this.id, this.description);

  /// Execute the heavy LLM job.
  Future<void> execute();
}

/// Service that schedules heavy LLM jobs (like processing dwells or updating Knots)
/// only when conditions are optimal, saving battery and preventing phone overheating.
///
/// Part of the v0.1 Reality Check pivot (Pillar 1).
class BatteryAdaptiveBatchScheduler {
  static const String _logName = 'BatteryAdaptiveBatchScheduler';

  final Battery _battery;
  StreamSubscription<BatteryState>? _batterySub;
  
  // Jobs waiting to be run
  final List<MicroBatchJob> _pendingJobs = [];
  
  // Config thresholds
  static const int _minBatteryPercent = 50; // Don't run on battery if below this
  
  bool _isProcessing = false;
  
  BatteryAdaptiveBatchScheduler({
    Battery? battery,
  }) : _battery = battery ?? Battery() {
    _initMonitoring();
  }

  void _initMonitoring() {
    _batterySub = _battery.onBatteryStateChanged.listen((state) {
      _evaluateConditionsAndRun();
    });
    
    // Also set up a periodic check just in case we hit the battery threshold 
    // while not charging (e.g. user puts down phone, screen off, 80% battery).
    Timer.periodic(const Duration(minutes: 15), (_) {
      _evaluateConditionsAndRun();
    });
  }

  /// Add a heavy job to the queue. It will not run immediately unless 
  /// battery/charging conditions are perfect.
  void scheduleJob(MicroBatchJob job) {
    _pendingJobs.add(job);
    developer.log('Job scheduled: ${job.description} (Queue size: ${_pendingJobs.length})', name: _logName);
    
    // Check if we can run it right now
    _evaluateConditionsAndRun();
  }

  /// Determines if current hardware conditions allow for heavy LLM inference.
  Future<bool> _areConditionsOptimal() async {
    try {
      final state = await _battery.batteryState;
      
      // If we are plugged in, we can always run batch jobs!
      if (state == BatteryState.charging || state == BatteryState.full) {
        return true;
      }
      
      // If not charging, we must be above the safety threshold.
      final level = await _battery.batteryLevel;
      if (level >= _minBatteryPercent) {
        // Here we could also check if screen is off via AppLifecycleState 
        // to ensure we don't lag the phone while the user is actively using it.
        return true;
      }
      
      return false;
    } catch (e) {
      // If battery check fails, fail safe (don't run)
      developer.log('Failed to check battery state: $e', name: _logName);
      return false;
    }
  }

  Future<void> _evaluateConditionsAndRun() async {
    if (_isProcessing || _pendingJobs.isEmpty) return;

    final canRun = await _areConditionsOptimal();
    if (!canRun) {
      developer.log('Conditions suboptimal. Deferring ${_pendingJobs.length} jobs.', name: _logName);
      return;
    }

    _isProcessing = true;
    developer.log('Conditions optimal! Starting micro-batch processing...', name: _logName);

    try {
      // Drain the queue
      while (_pendingJobs.isNotEmpty) {
        // Double check conditions haven't changed (e.g. user unplugged phone mid-batch)
        if (!await _areConditionsOptimal()) {
          developer.log('Conditions changed mid-batch. Halting.', name: _logName);
          break;
        }

        final job = _pendingJobs.removeAt(0);
        developer.log('Executing job: ${job.description}', name: _logName);
        
        await job.execute();
        
        // Brief pause between jobs to let device cool down
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e, st) {
      developer.log('Error during batch execution', error: e, stackTrace: st, name: _logName);
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _batterySub?.cancel();
  }
  
  // For testing
  int get pendingJobCount => _pendingJobs.length;
}
