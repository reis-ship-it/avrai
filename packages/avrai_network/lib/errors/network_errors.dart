/// Network-related exceptions and error handling
library;

/// Base class for all network-related exceptions
abstract class NetworkException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  
  const NetworkException(this.message, [this.code, this.details]);
  
  @override
  String toString() {
    var result = 'NetworkException: $message';
    if (code != null) result += ' (code: $code)';
    return result;
  }
}

/// Exception thrown when network is not available
class NoInternetException extends NetworkException {
  NoInternetException() : super(
    'No internet connection available',
    'NO_INTERNET',
  );
}

/// Exception thrown when request times out
class TimeoutException extends NetworkException {
  final Duration timeout;
  
  TimeoutException(this.timeout) : super(
    'Request timed out after ${timeout.inSeconds} seconds',
    'TIMEOUT',
  );
}

/// Exception thrown for HTTP errors
class HttpException extends NetworkException {
  final int statusCode;
  final String? response;
  
  const HttpException(
    this.statusCode,
    String message, [
    this.response,
    String? code,
  ]) : super(message, code);
  
  factory HttpException.fromResponse(int statusCode, String? response) {
    String message;
    String? code;
    
    switch (statusCode) {
      case 400:
        message = 'Bad Request';
        code = 'BAD_REQUEST';
        break;
      case 401:
        message = 'Unauthorized';
        code = 'UNAUTHORIZED';
        break;
      case 403:
        message = 'Forbidden';
        code = 'FORBIDDEN';
        break;
      case 404:
        message = 'Not Found';
        code = 'NOT_FOUND';
        break;
      case 409:
        message = 'Conflict';
        code = 'CONFLICT';
        break;
      case 422:
        message = 'Unprocessable Entity';
        code = 'VALIDATION_ERROR';
        break;
      case 429:
        message = 'Too Many Requests';
        code = 'RATE_LIMITED';
        break;
      case 500:
        message = 'Internal Server Error';
        code = 'SERVER_ERROR';
        break;
      case 502:
        message = 'Bad Gateway';
        code = 'BAD_GATEWAY';
        break;
      case 503:
        message = 'Service Unavailable';
        code = 'SERVICE_UNAVAILABLE';
        break;
      default:
        message = 'HTTP Error $statusCode';
        code = 'HTTP_ERROR';
    }
    
    return HttpException(statusCode, message, response, code);
  }
}

/// Exception thrown when API rate limit is exceeded
class RateLimitException extends NetworkException {
  final Duration retryAfter;
  
  RateLimitException(this.retryAfter) : super(
    'Rate limit exceeded. Retry after ${retryAfter.inSeconds} seconds',
    'RATE_LIMITED',
  );
}

/// Exception thrown for authentication errors
class AuthenticationException extends NetworkException {
  const AuthenticationException([String? message]) : super(
    message ?? 'Authentication failed',
    'AUTH_ERROR',
  );
}

/// Exception thrown for authorization errors
class AuthorizationException extends NetworkException {
  const AuthorizationException([String? message]) : super(
    message ?? 'Insufficient permissions',
    'AUTHORIZATION_ERROR',
  );
}

/// Exception thrown when parsing response fails
class ParseException extends NetworkException {
  final String originalResponse;
  
  const ParseException(this.originalResponse, [String? message]) : super(
    message ?? 'Failed to parse response',
    'PARSE_ERROR',
  );
}

/// Exception thrown for validation errors
class ValidationException extends NetworkException {
  final Map<String, List<String>> validationErrors;
  
  const ValidationException(this.validationErrors, [String? message]) : super(
    message ?? 'Validation failed',
    'VALIDATION_ERROR',
    validationErrors,
  );
}

/// Exception thrown when resource is not found
class NotFoundException extends NetworkException {
  final String resourceType;
  final String resourceId;
  
  const NotFoundException(this.resourceType, this.resourceId) : super(
    '$resourceType with ID $resourceId not found',
    'NOT_FOUND',
  );
}

/// Exception thrown for conflict errors (e.g., duplicate resources)
class ConflictException extends NetworkException {
  final String conflictReason;
  
  const ConflictException(this.conflictReason) : super(
    'Conflict: $conflictReason',
    'CONFLICT',
  );
}

/// Exception thrown for server errors
class ServerException extends NetworkException {
  const ServerException([String? message]) : super(
    message ?? 'Internal server error',
    'SERVER_ERROR',
  );
}

/// Exception thrown when service is unavailable
class ServiceUnavailableException extends NetworkException {
  final Duration? retryAfter;
  
  const ServiceUnavailableException([this.retryAfter]) : super(
    'Service temporarily unavailable',
    'SERVICE_UNAVAILABLE',
  );
}

/// Exception thrown for unknown network errors
class UnknownNetworkException extends NetworkException {
  final Object originalError;
  
  const UnknownNetworkException(this.originalError) : super(
    'Unknown network error: $originalError',
    'UNKNOWN_ERROR',
  );
}

/// Utility class for handling network errors
class NetworkErrorHandler {
  /// Convert various error types to NetworkException
  static NetworkException handleError(Object error) {
    if (error is NetworkException) {
      return error;
    }
    
    // Handle specific error types
    if (error.toString().contains('SocketException')) {
      return NoInternetException();
    }
    
    if (error.toString().contains('TimeoutException')) {
      return TimeoutException(const Duration(seconds: 30));
    }
    
    if (error.toString().contains('FormatException')) {
      return ParseException(error.toString());
    }
    
    return UnknownNetworkException(error);
  }
  
  /// Check if error is retryable
  static bool isRetryable(NetworkException error) {
    switch (error.code) {
      case 'NO_INTERNET':
      case 'TIMEOUT':
      case 'SERVER_ERROR':
      case 'BAD_GATEWAY':
      case 'SERVICE_UNAVAILABLE':
        return true;
      default:
        return false;
    }
  }
  
  /// Get retry delay for retryable errors
  static Duration getRetryDelay(NetworkException error, int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 1 << retryCount); // 1s, 2s, 4s, 8s...
    final jitter = Duration(milliseconds: (baseDelay.inMilliseconds * 0.1).round());
    
    return baseDelay + jitter;
  }
  
  /// Get user-friendly error message
  static String getUserMessage(NetworkException error) {
    switch (error.code) {
      case 'NO_INTERNET':
        return 'Please check your internet connection and try again.';
      case 'TIMEOUT':
        return 'Request took too long. Please try again.';
      case 'UNAUTHORIZED':
        return 'Please log in to continue.';
      case 'FORBIDDEN':
        return 'You don\'t have permission to perform this action.';
      case 'NOT_FOUND':
        return 'The requested item could not be found.';
      case 'VALIDATION_ERROR':
        return 'Please check your input and try again.';
      case 'RATE_LIMITED':
        return 'Too many requests. Please wait a moment and try again.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'SERVICE_UNAVAILABLE':
        return 'Service is temporarily unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
