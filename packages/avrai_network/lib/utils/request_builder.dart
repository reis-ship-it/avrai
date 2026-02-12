/// Utility for building HTTP requests
class RequestBuilder {
  static Map<String, String> buildHeaders({
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }
  
  static Map<String, String> buildQueryParams(Map<String, dynamic> params) {
    return params.map((key, value) => MapEntry(key, value.toString()));
  }
}
