import 'dart:developer' as developer;

/// Reusable circuit breaker for backup/sync network calls.
///
/// After [failureThreshold] consecutive failures, the circuit opens and
/// [run] throws until [openDuration] has passed (half-open). One successful
/// call closes the circuit; one failure in half-open re-opens it.
class NetworkCircuitBreaker {
  static const String _logName = 'NetworkCircuitBreaker';

  final int failureThreshold;
  final Duration openDuration;

  int _consecutiveFailures = 0;
  DateTime? _openedAt;
  bool _open = false;

  NetworkCircuitBreaker({
    this.failureThreshold = 5,
    this.openDuration = const Duration(minutes: 5),
  });

  bool get isOpen => _open;

  /// Runs [action]. If the circuit is open and not yet in half-open window,
  /// throws. Otherwise executes [action]; on success closes the circuit,
  /// on failure records and may open it.
  Future<T> run<T>(Future<T> Function() action) async {
    if (_open) {
      final elapsed = _openedAt != null
          ? DateTime.now().difference(_openedAt!)
          : Duration.zero;
      if (elapsed < openDuration) {
        developer.log(
          'Circuit open, rejecting call (elapsed: ${elapsed.inSeconds}s)',
          name: _logName,
        );
        throw NetworkCircuitBreakerOpenException(
          'Backup temporarily unavailable. Retry later.',
        );
      }
      developer.log('Half-open: allowing one call', name: _logName);
      _open = false;
      _consecutiveFailures = 0;
    }

    try {
      final result = await action();
      _consecutiveFailures = 0;
      _openedAt = null;
      return result;
    } catch (e, st) {
      _consecutiveFailures++;
      developer.log(
        'Circuit breaker recorded failure ($_consecutiveFailures/$failureThreshold)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      if (_consecutiveFailures >= failureThreshold) {
        _open = true;
        _openedAt = DateTime.now();
        developer.log(
          'Circuit opened after $failureThreshold failures',
          name: _logName,
        );
      }
      rethrow;
    }
  }
}

class NetworkCircuitBreakerOpenException implements Exception {
  final String message;
  NetworkCircuitBreakerOpenException(this.message);
  @override
  String toString() => 'NetworkCircuitBreakerOpenException: $message';
}
