import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../errors/network_errors.dart';

/// Generic API client for HTTP requests
/// Provides standardized HTTP operations with error handling and retry logic
class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final http.Client _httpClient;
  
  ApiClient({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final requestHeaders = _buildHeaders(headers);
      
      final response = await _httpClient
          .get(uri, headers: requestHeaders)
          .timeout(timeout);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      final requestBody = body != null ? jsonEncode(body) : null;
      
      final response = await _httpClient
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(timeout);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      final requestBody = body != null ? jsonEncode(body) : null;
      
      final response = await _httpClient
          .put(uri, headers: requestHeaders, body: requestBody)
          .timeout(timeout);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      final requestBody = body != null ? jsonEncode(body) : null;
      
      final response = await _httpClient
          .patch(uri, headers: requestHeaders, body: requestBody)
          .timeout(timeout);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = _buildHeaders(headers);
      
      final response = await _httpClient
          .delete(uri, headers: requestHeaders)
          .timeout(timeout);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// Upload file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath,
    List<int> fileBytes, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_buildHeaders(headers));
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filePath.split('/').last,
      ));
      
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// Download file
  Future<ApiResponse<List<int>>> downloadFile(String endpoint) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _httpClient.get(uri).timeout(timeout);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(response.bodyBytes);
      } else {
        return ApiResponse.error(
          'Failed to download file: ${response.statusCode}',
        );
      }
    } catch (e) {
      return _handleError<List<int>>(e);
    }
  }
  
  /// Build URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final uri = Uri.parse('$baseUrl/$cleanEndpoint');
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    
    return uri;
  }
  
  /// Build headers with defaults
  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...defaultHeaders,
    };
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }
  
  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final metadata = ResponseMetadata(
      requestId: response.headers['x-request-id'],
      timestamp: DateTime.now(),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return ApiResponse.success(null as T, metadata: metadata);
        }
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (fromJson != null) {
          return ApiResponse.success(fromJson(data), metadata: metadata);
        } else {
          return ApiResponse.success(data as T, metadata: metadata);
        }
      } catch (e) {
        return ApiResponse.error(
          'Failed to parse response: $e',
          errorCode: 'PARSE_ERROR',
          metadata: metadata,
        );
      }
    } else {
      String errorMessage = 'HTTP ${response.statusCode}';
      String? errorCode;
      Map<String, dynamic>? errorDetails;
      
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorData['message'] as String? ?? errorMessage;
        errorCode = errorData['code'] as String?;
        errorDetails = errorData;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      
      return ApiResponse.error(
        errorMessage,
        errorCode: errorCode,
        errorDetails: errorDetails,
        metadata: metadata,
      );
    }
  }
  
  /// Handle request errors
  ApiResponse<T> _handleError<T>(Object error) {
    if (error is SocketException) {
      return ApiResponse.error(
        'No internet connection',
        errorCode: 'NO_CONNECTION',
      );
    } else if (error is TimeoutException) {
      return ApiResponse.error(
        'Request timeout',
        errorCode: 'TIMEOUT',
      );
    } else if (error is FormatException) {
      return ApiResponse.error(
        'Invalid response format',
        errorCode: 'FORMAT_ERROR',
      );
    } else {
      return ApiResponse.error(
        'Unexpected error: $error',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }
  
  /// Dispose client
  void dispose() {
    _httpClient.close();
  }
}
