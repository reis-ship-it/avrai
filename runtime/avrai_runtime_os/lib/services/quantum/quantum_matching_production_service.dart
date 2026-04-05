// Quantum Matching Production Service
//
// Production enhancements for Phase 19: Multi-Entity Quantum Entanglement Matching System
// Part of Phase 19.17: Testing, Documentation, and Production Readiness
//
// Provides:
// - Error handling and recovery strategies
// - Monitoring and observability (metrics, logging, tracing)
// - Caching strategies (with TTL)
// - Rate limiting and abuse prevention
// - Circuit breakers for service failures
// - Retry logic for transient failures
// - Health checks and readiness probes

import 'dart:async';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:injectable/injectable.dart';

part 'quantum_matching_production_models.dart';

/// Circuit breaker state
enum CircuitBreakerState {
  closed, // Normal operation
  open, // Failing, reject requests
  halfOpen, // Testing if service recovered
}

/// Production service for Phase 19 quantum matching
///
/// **Features:**
/// - Circuit breaker pattern for service failures
/// - Retry logic with exponential backoff
/// - Rate limiting
/// - Caching with TTL
/// - Health checks
/// - Error monitoring
@lazySingleton
class QuantumMatchingProductionService {
  static const String _logName = 'QuantumMatchingProductionService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final AtomicClockService _atomicClock;
  final StorageService _storageService;

  // Circuit breaker configuration
  static const int _circuitBreakerFailureThreshold = 5;
  static const Duration _circuitBreakerTimeout = Duration(minutes: 1);
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenedAt;
  CircuitBreakerState _circuitBreakerState = CircuitBreakerState.closed;

  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 100;
  final Map<String, List<DateTime>> _requestHistory = {};

  // Cache configuration
  static const Duration _cacheTTL = Duration(minutes: 5);
  final Map<String, _CachedResult> _cache = {};
  static const int _maxCacheSize = 1000;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 100);

  QuantumMatchingProductionService({
    required AtomicClockService atomicClock,
    required StorageService storageService,
  })  : _atomicClock = atomicClock,
        _storageService = storageService;

  /// Execute operation with production enhancements
  ///
  /// **Features:**
  /// - Circuit breaker check
  /// - Rate limiting
  /// - Caching
  /// - Retry logic
  /// - Error handling
  Future<T?> executeWithProductionEnhancements<T>({
    required String operationKey,
    required Future<T> Function() operation,
    bool useCache = true,
    bool useRetry = true,
  }) async {
    try {
      // 1. Check circuit breaker
      if (_circuitBreakerState == CircuitBreakerState.open) {
        if (_shouldAttemptHalfOpen()) {
          _circuitBreakerState = CircuitBreakerState.halfOpen;
          _logger.info('Circuit breaker entering half-open state',
              tag: _logName);
        } else {
          _logger.warn('Circuit breaker is open, rejecting request',
              tag: _logName);
          throw Exception(
              'Service temporarily unavailable (circuit breaker open)');
        }
      }

      // 2. Check rate limit
      if (!_checkRateLimit(operationKey)) {
        _logger.warn('Rate limit exceeded for operation: $operationKey',
            tag: _logName);
        throw Exception('Rate limit exceeded');
      }

      // 3. Check cache
      if (useCache) {
        final cached = _getCachedResult<T>(operationKey);
        if (cached != null) {
          _logger.debug('Cache hit for operation: $operationKey',
              tag: _logName);
          return cached;
        }
      }

      // 4. Execute operation with retry logic
      T? result;
      if (useRetry) {
        result = await _executeWithRetry(operation);
      } else {
        result = await operation();
      }

      // 5. Cache result
      if (useCache && result != null) {
        _cacheResult(operationKey, result);
      }

      // 6. Reset circuit breaker on success
      if (_circuitBreakerState == CircuitBreakerState.halfOpen) {
        _circuitBreakerState = CircuitBreakerState.closed;
        _consecutiveFailures = 0;
        _logger.info('Circuit breaker closed after successful operation',
            tag: _logName);
      } else if (_circuitBreakerState == CircuitBreakerState.closed) {
        _consecutiveFailures = 0;
      }

      return result;
    } catch (e, st) {
      _handleError(operationKey, e, st);
      rethrow;
    }
  }

  /// Execute operation with retry logic
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < _maxRetries - 1) {
          final delay = Duration(
            milliseconds: _initialRetryDelay.inMilliseconds * (1 << attempt),
          );
          _logger.debug(
            'Operation failed, retrying after ${delay.inMilliseconds}ms (attempt ${attempt + 1}/$_maxRetries)',
            tag: _logName,
          );
          await Future.delayed(delay);
        }
      }
    }
    throw lastException ??
        Exception('Operation failed after $_maxRetries attempts');
  }

  /// Check rate limit
  bool _checkRateLimit(String operationKey) {
    final now = DateTime.now();
    final key = operationKey;
    final requests = _requestHistory[key] ?? [];

    // Remove requests older than 1 minute
    final recentRequests = requests
        .where((time) => now.difference(time) < const Duration(minutes: 1))
        .toList();

    if (recentRequests.length >= _maxRequestsPerMinute) {
      return false;
    }

    recentRequests.add(now);
    _requestHistory[key] = recentRequests;
    return true;
  }

  /// Get cached result
  T? _getCachedResult<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    final now = DateTime.now();
    if (now.difference(cached.cachedAt) > _cacheTTL) {
      _cache.remove(key);
      return null;
    }

    return cached.result as T?;
  }

  /// Cache result
  void _cacheResult<T>(String key, T result) {
    // Evict oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.cachedAt.isBefore(b.value.cachedAt) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }

    _cache[key] = _CachedResult(
      result: result,
      cachedAt: DateTime.now(),
    );
  }

  /// Handle error
  void _handleError(String operationKey, Object error, StackTrace stackTrace) {
    _logger.error(
      'Operation failed: $operationKey',
      error: error,
      stackTrace: stackTrace,
      tag: _logName,
    );

    _consecutiveFailures++;

    // Open circuit breaker if threshold reached
    if (_consecutiveFailures >= _circuitBreakerFailureThreshold) {
      _circuitBreakerState = CircuitBreakerState.open;
      _circuitBreakerOpenedAt = DateTime.now();
      _logger.warn(
        'Circuit breaker opened after $_consecutiveFailures consecutive failures',
        tag: _logName,
      );
    }
  }

  /// Check if circuit breaker should attempt half-open
  bool _shouldAttemptHalfOpen() {
    if (_circuitBreakerOpenedAt == null) return false;
    return DateTime.now().difference(_circuitBreakerOpenedAt!) >=
        _circuitBreakerTimeout;
  }

  /// Health check
  Future<HealthCheckResult> performHealthCheck() async {
    try {
      final checks = <String, bool>{};

      // Check atomic clock
      await _atomicClock.getAtomicTimestamp();
      checks['atomicClock'] = true;

      // Check storage
      try {
        _storageService.getString('health_check');
        checks['storage'] = true;
      } catch (e) {
        checks['storage'] = false;
      }

      // Check circuit breaker
      checks['circuitBreaker'] =
          _circuitBreakerState != CircuitBreakerState.open;

      final allHealthy = checks.values.every((healthy) => healthy);

      return HealthCheckResult(
        isHealthy: allHealthy,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      _logger.error('Health check failed',
          error: e, stackTrace: st, tag: _logName);
      return HealthCheckResult(
        isHealthy: false,
        checks: {'healthCheck': false},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _logger.info('Cache cleared', tag: _logName);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'ttlMinutes': _cacheTTL.inMinutes,
    };
  }

  /// Get circuit breaker status
  Map<String, dynamic> getCircuitBreakerStatus() {
    return {
      'state': _circuitBreakerState.name,
      'consecutiveFailures': _consecutiveFailures,
      'openedAt': _circuitBreakerOpenedAt?.toIso8601String(),
    };
  }
}

/// Health check result
class HealthCheckResult {
  final bool isHealthy;
  final Map<String, bool> checks;
  final DateTime timestamp;

  HealthCheckResult({
    required this.isHealthy,
    required this.checks,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'HealthCheckResult(isHealthy: $isHealthy, checks: $checks, timestamp: $timestamp)';
  }
}
