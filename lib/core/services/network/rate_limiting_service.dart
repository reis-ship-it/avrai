/// Rate Limiting Service
/// 
/// Phase 7, Section 41 (7.4.3): Backend Completion
/// 
/// Provides rate limiting functionality to prevent abuse and protect sensitive operations.
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// Features:
/// - Per-user, per-operation rate limiting
/// - Different limits for different operations (sensitive operations have lower limits)
/// - Time-window based rate limit reset
/// - Rate limit information retrieval
library;

/// Rate limit information for a user-operation pair
class RateLimitInfo {
  final String userId;
  final String operation;
  final int count;
  final int limit;
  final DateTime resetAt;

  RateLimitInfo({
    required this.userId,
    required this.operation,
    required this.count,
    required this.limit,
    required this.resetAt,
  });

  /// Remaining requests in the current window
  int get remaining => (limit - count).clamp(0, limit);
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

/// Service for managing rate limits
class RateLimitingService {
  final Map<String, RateLimitInfo> _rateLimits = {};
  final Map<String, int> _operationLimits = {
    'data_access': 100,
    'decrypt_email': 10, // Lower limit for sensitive operations
    'decrypt_name': 10,
    'decrypt_location': 10,
    'decrypt_phone': 10,
  };
  final Duration _windowDuration = const Duration(minutes: 15);

  /// Check if a request is within rate limit
  /// 
  /// Returns `true` if request is allowed, `false` if rate limit exceeded.
  /// If `throwOnLimit` is `true`, throws `RateLimitException` instead of returning `false`.
  Future<bool> checkRateLimit(
    String userId,
    String operation, {
    bool throwOnLimit = false,
  }) async {
    final key = '$userId:$operation';
    final limit = _operationLimits[operation] ?? 100;

    final info = _rateLimits[key];
    final now = DateTime.now();

    if (info == null || now.isAfter(info.resetAt)) {
      // Reset or create new
      _rateLimits[key] = RateLimitInfo(
        userId: userId,
        operation: operation,
        count: 1,
        limit: limit,
        resetAt: now.add(_windowDuration),
      );
      return true;
    }

    if (info.count >= info.limit) {
      if (throwOnLimit) {
        throw RateLimitException(
          'Rate limit exceeded for $operation. Reset at ${info.resetAt}',
        );
      }
      return false;
    }

    // Increment count
    _rateLimits[key] = RateLimitInfo(
      userId: userId,
      operation: operation,
      count: info.count + 1,
      limit: info.limit,
      resetAt: info.resetAt,
    );

    return true;
  }

  /// Reset rate limit for a specific user-operation pair
  Future<void> resetRateLimit(String userId, String operation) async {
    final key = '$userId:$operation';
    _rateLimits.remove(key);
  }

  /// Reset all rate limits for a user
  Future<void> resetAllRateLimits(String userId) async {
    _rateLimits.removeWhere((key, _) => key.startsWith('$userId:'));
  }

  /// Get rate limit information for a user-operation pair
  Future<RateLimitInfo> getRateLimitInfo(String userId, String operation) async {
    final key = '$userId:$operation';
    final info = _rateLimits[key];
    final limit = _operationLimits[operation] ?? 100;

    if (info == null) {
      return RateLimitInfo(
        userId: userId,
        operation: operation,
        count: 0,
        limit: limit,
        resetAt: DateTime.now().add(_windowDuration),
      );
    }

    return info;
  }
}

