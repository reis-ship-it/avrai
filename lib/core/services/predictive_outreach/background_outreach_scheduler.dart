// ignore: dangling_library_doc_comments
/// Background Outreach Scheduler
/// 
/// Schedules and manages background jobs for proactive outreach processing.
/// Part of Predictive Proactive Outreach System - Phase 4.1
/// 
/// Runs outreach processing jobs every 3 hours (balanced frequency).
/// Manages job execution, failure handling, and retries.

import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai/core/services/predictive_outreach/outreach_queue_processor.dart';
import 'package:avrai/core/services/predictive_outreach/batch_outreach_processor.dart';

/// Background job status
enum BackgroundJobStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// Background job result
class BackgroundJobResult {
  final bool success;
  final int processedCount;
  final int successCount;
  final int failureCount;
  final DateTime startTime;
  final DateTime endTime;
  final String? error;
  final Map<String, dynamic>? metadata;
  
  BackgroundJobResult({
    required this.success,
    required this.processedCount,
    required this.successCount,
    required this.failureCount,
    required this.startTime,
    required this.endTime,
    this.error,
    this.metadata,
  });
  
  Duration get duration => endTime.difference(startTime);
}

/// Service for scheduling and managing background outreach jobs
class BackgroundOutreachScheduler {
  static const String _logName = 'BackgroundOutreachScheduler';
  
  // Balanced frequency: every 3 hours
  static const Duration _jobInterval = Duration(hours: 3);
  
  // Queue processor is used via batch processor
  // ignore: unused_field
  final OutreachQueueProcessor _queueProcessor;
  final BatchOutreachProcessor _batchProcessor;
  
  Timer? _scheduledTimer;
  BackgroundJobStatus _currentJobStatus = BackgroundJobStatus.pending;
  BackgroundJobResult? _lastJobResult;
  
  BackgroundOutreachScheduler({
    required OutreachQueueProcessor queueProcessor,
    required BatchOutreachProcessor batchProcessor,
  })  : _queueProcessor = queueProcessor,
        _batchProcessor = batchProcessor;
  
  /// Start the background scheduler
  /// 
  /// Begins periodic execution of outreach processing jobs.
  void start() {
    if (_scheduledTimer != null && _scheduledTimer!.isActive) {
      developer.log(
        '⚠️ Scheduler already running',
        name: _logName,
      );
      return;
    }
    
    developer.log(
      '🚀 Starting background outreach scheduler (interval: ${_jobInterval.inHours} hours)',
      name: _logName,
    );
    
    // Run immediately on start
    _runScheduledJob();
    
    // Schedule periodic execution
    _scheduledTimer = Timer.periodic(_jobInterval, (_) {
      _runScheduledJob();
    });
  }
  
  /// Stop the background scheduler
  void stop() {
    developer.log(
      '🛑 Stopping background outreach scheduler',
      name: _logName,
    );
    
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    
    if (_currentJobStatus == BackgroundJobStatus.running) {
      _currentJobStatus = BackgroundJobStatus.cancelled;
    }
  }
  
  /// Run a scheduled job immediately
  Future<BackgroundJobResult> runScheduledJob() async {
    return await _runScheduledJob();
  }
  
  /// Execute the scheduled outreach processing job
  Future<BackgroundJobResult> _runScheduledJob() async {
    if (_currentJobStatus == BackgroundJobStatus.running) {
      developer.log(
        '⚠️ Job already running, skipping',
        name: _logName,
      );
      return _lastJobResult ?? BackgroundJobResult(
        success: false,
        processedCount: 0,
        successCount: 0,
        failureCount: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        error: 'Job already running',
      );
    }
    
    _currentJobStatus = BackgroundJobStatus.running;
    final startTime = DateTime.now();
    
    developer.log(
      '📋 Starting scheduled outreach processing job',
      name: _logName,
    );
    
    try {
      // Process all outreach types in batches
      final result = await _batchProcessor.processAllOutreachTypes();
      
      final endTime = DateTime.now();
      _lastJobResult = BackgroundJobResult(
        success: result.success,
        processedCount: result.totalProcessed,
        successCount: result.totalSuccess,
        failureCount: result.totalFailures,
        startTime: startTime,
        endTime: endTime,
        error: result.error,
        metadata: {
          'communities_processed': result.communitiesProcessed,
          'groups_processed': result.groupsProcessed,
          'events_processed': result.eventsProcessed,
          'businesses_processed': result.businessesProcessed,
          'clubs_processed': result.clubsProcessed,
          'experts_processed': result.expertsProcessed,
          'lists_processed': result.listsProcessed,
        },
      );
      
      _currentJobStatus = BackgroundJobStatus.completed;
      
      developer.log(
        '✅ Scheduled job completed: ${result.totalProcessed} processed, '
        '${result.totalSuccess} succeeded, ${result.totalFailures} failed '
        '(duration: ${_lastJobResult!.duration.inSeconds}s)',
        name: _logName,
      );
      
      return _lastJobResult!;
    } catch (e, stackTrace) {
      final endTime = DateTime.now();
      _lastJobResult = BackgroundJobResult(
        success: false,
        processedCount: 0,
        successCount: 0,
        failureCount: 0,
        startTime: startTime,
        endTime: endTime,
        error: e.toString(),
      );
      
      _currentJobStatus = BackgroundJobStatus.failed;
      
      developer.log(
        '❌ Scheduled job failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      
      return _lastJobResult!;
    }
  }
  
  /// Get current job status
  BackgroundJobStatus get currentJobStatus => _currentJobStatus;
  
  /// Get last job result
  BackgroundJobResult? get lastJobResult => _lastJobResult;
  
  /// Check if scheduler is running
  bool get isRunning => _scheduledTimer != null && _scheduledTimer!.isActive;
  
  /// Get next scheduled run time
  DateTime? get nextRunTime {
    if (!isRunning) return null;
    
    // Calculate next run time based on last result
    if (_lastJobResult != null) {
      return _lastJobResult!.endTime.add(_jobInterval);
    }
    
    // If no previous run, next run is in 3 hours
    return DateTime.now().add(_jobInterval);
  }
}
