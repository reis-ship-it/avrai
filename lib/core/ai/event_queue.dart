// Event Queue for Phase 11: User-AI Interaction Update
// Offline-capable event queue for batching and retrying event submissions

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Event queue for offline event storage and batch submission
/// 
/// Features:
/// - Offline support: Events are queued locally when offline
/// - Batch submission: Events are submitted in batches when online
/// - Automatic retry: Failed submissions are retried
/// - Persistent storage: Events survive app restarts
class EventQueue {
  static const String _logName = 'EventQueue';
  static const String _storageKey = 'interaction_events_queue';
  static const int _maxQueueSize = 1000; // Maximum events in queue
  static const int _batchSize = 50; // Events per batch
  static const Duration _retryInterval = Duration(seconds: 30);
  static const Duration _batchInterval = Duration(seconds: 10);

  final StorageService _storageService;
  final Connectivity _connectivity;
  final List<InteractionEvent> _queue = [];
  Timer? _batchTimer;
  Timer? _retryTimer;
  bool _isProcessing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Callback for submitting events to server
  /// Should return true on success, false on failure
  Future<bool> Function(List<InteractionEvent> events)? onSubmitEvents;

  EventQueue({
    StorageService? storageService,
    Connectivity? connectivity,
    this.onSubmitEvents,
  })  : _storageService = storageService ?? StorageService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Initialize event queue
  /// Loads queued events from storage and starts processing
  Future<void> initialize() async {
    try {
      developer.log('Initializing EventQueue', name: _logName);
      
      // Load queued events from storage
      await _loadQueueFromStorage();
      
      // Start batch processing timer
      _startBatchTimer();
      
      // Start retry timer
      _startRetryTimer();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final hasConnection = results.any(
            (result) => result != ConnectivityResult.none,
          );
          if (hasConnection) {
            developer.log('Connectivity restored, processing queue', name: _logName);
            _processQueue();
          }
        },
      );
      
      developer.log('✅ EventQueue initialized with ${_queue.length} queued events', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing EventQueue: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add event to queue
  /// Events are stored locally and submitted when online
  Future<void> enqueue(InteractionEvent event) async {
    try {
      // Prevent queue overflow
      if (_queue.length >= _maxQueueSize) {
        developer.log(
          '⚠️ Event queue full, dropping oldest event',
          name: _logName,
        );
        _queue.removeAt(0);
      }
      
      _queue.add(event);
      
      // Save to persistent storage
      await _saveQueueToStorage();
      
      // Try to process immediately if online
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection) {
        _processQueue();
      }
      
      developer.log(
        'Event queued: ${event.eventType} (queue size: ${_queue.length})',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error enqueueing event: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Public API for [BackupSyncCoordinator] – processes the event queue.
  Future<void> tryProcessQueue() => _processQueue();

  /// Process queue (submit events in batches)
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }
    
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasConnection) {
      developer.log('Offline, skipping queue processing', name: _logName);
      return;
    }
    
    if (onSubmitEvents == null) {
      developer.log('⚠️ No submit callback registered', name: _logName);
      return;
    }
    
    _isProcessing = true;
    
    try {
      // Process in batches
      while (_queue.isNotEmpty) {
        final batch = _queue.take(_batchSize).toList();
        _queue.removeRange(0, batch.length);
        
        developer.log(
          'Submitting batch of ${batch.length} events',
          name: _logName,
        );
        
        final success = await onSubmitEvents!(batch);
        
        if (success) {
          developer.log(
            '✅ Successfully submitted batch of ${batch.length} events',
            name: _logName,
          );
          // Save updated queue (with removed events)
          await _saveQueueToStorage();
        } else {
          developer.log(
            '❌ Failed to submit batch, re-queuing events',
            name: _logName,
          );
          // Re-queue failed events at the front
          _queue.insertAll(0, batch);
          await _saveQueueToStorage();
          break; // Stop processing on failure
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error processing queue: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Load queue from persistent storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final queueJson = _storageService.getString(_storageKey);
      if (queueJson == null || queueJson.isEmpty) {
        return;
      }
      
      final List<dynamic> queueList = jsonDecode(queueJson) as List<dynamic>;
      _queue.clear();
      _queue.addAll(
        queueList.map((json) => InteractionEvent.fromJson(json as Map<String, dynamic>)),
      );
      
      developer.log(
        'Loaded ${_queue.length} events from storage',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error loading queue from storage: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Clear corrupted queue
      _queue.clear();
      await _storageService.remove(_storageKey);
    }
  }

  /// Save queue to persistent storage
  Future<void> _saveQueueToStorage() async {
    try {
      final queueJson = jsonEncode(
        _queue.map((event) => event.toJson()).toList(),
      );
      await _storageService.setString(_storageKey, queueJson);
    } catch (e, stackTrace) {
      developer.log(
        'Error saving queue to storage: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _processQueue();
    });
  }

  /// Start retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      _processQueue();
    });
  }

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Check if queue is processing
  bool get isProcessing => _isProcessing;

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _queue.clear();
  }
}
