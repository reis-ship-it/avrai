import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Standardized API response wrapper
/// Provides consistent error handling and response structure across all backends
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> extends Equatable {
  final T? data;
  final bool success;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;
  final ResponseMetadata? metadata;
  
  const ApiResponse({
    this.data,
    required this.success,
    this.error,
    this.errorCode,
    this.errorDetails,
    this.metadata,
  });
  
  /// Create successful response
  factory ApiResponse.success(T data, {ResponseMetadata? metadata}) {
    return ApiResponse<T>(
      data: data,
      success: true,
      metadata: metadata,
    );
  }
  
  /// Create error response
  factory ApiResponse.error(
    String error, {
    String? errorCode,
    Map<String, dynamic>? errorDetails,
    ResponseMetadata? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      errorCode: errorCode,
      errorDetails: errorDetails,
      metadata: metadata,
    );
  }
  
  /// Create loading/pending response
  factory ApiResponse.loading({ResponseMetadata? metadata}) {
    return ApiResponse<T>(
      success: false,
      metadata: metadata,
    );
  }
  
  /// Check if response is successful and has data
  bool get hasData => success && data != null;
  
  /// Check if response has error
  bool get hasError => !success && error != null;
  
  /// Check if response is loading
  bool get isLoading => !success && error == null;
  
  /// Get data or throw exception if error
  T get dataOrThrow {
    if (hasError) {
      throw ApiException(error!, errorCode, errorDetails);
    }
    if (data == null) {
      throw StateError('Response data is null');
    }
    return data!;
  }
  
  /// Get data or return default value
  T dataOr(T defaultValue) => data ?? defaultValue;
  
  /// Transform the data using a mapper function
  ApiResponse<R> map<R>(R Function(T) mapper) {
    if (hasData) {
      try {
        return ApiResponse.success(mapper(data as T), metadata: metadata);
      } catch (e) {
        return ApiResponse.error(
          'Error transforming data: $e',
          metadata: metadata,
        );
      }
    }
    return ApiResponse<R>(
      success: success,
      error: error,
      errorCode: errorCode,
      errorDetails: errorDetails,
      metadata: metadata,
    );
  }
  
  /// Handle response with callbacks
  R when<R>({
    required R Function(T data) onData,
    required R Function(String error) onError,
    required R Function() onLoading,
  }) {
    if (hasData) {
      return onData(data as T);
    } else if (hasError) {
      return onError(error!);
    } else {
      return onLoading();
    }
  }
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
  
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
  
  @override
  List<Object?> get props => [
    data, success, error, errorCode, errorDetails, metadata,
  ];
}

/// Response metadata for pagination and additional info
@JsonSerializable()
class ResponseMetadata extends Equatable {
  final int? page;
  final int? limit;
  final int? total;
  final String? cursor;
  final String? nextCursor;
  final bool? hasMore;
  final Duration? requestDuration;
  final String? requestId;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;
  
  const ResponseMetadata({
    this.page,
    this.limit,
    this.total,
    this.cursor,
    this.nextCursor,
    this.hasMore,
    this.requestDuration,
    this.requestId,
    required this.timestamp,
    this.extra,
  });
  
  factory ResponseMetadata.fromJson(Map<String, dynamic> json) =>
      _$ResponseMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseMetadataToJson(this);
  
  @override
  List<Object?> get props => [
    page, limit, total, cursor, nextCursor, hasMore,
    requestDuration, requestId, timestamp, extra,
  ];
}

/// API exception for error handling
class ApiException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  
  const ApiException(this.message, [this.code, this.details]);
  
  @override
  String toString() {
    var result = 'ApiException: $message';
    if (code != null) result += ' (code: $code)';
    if (details != null) result += ' details: $details';
    return result;
  }
}
