import 'dart:convert';

/// Utility for parsing HTTP responses
class ResponseParser {
  static T parseJson<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return fromJson(data);
  }
  
  static List<T> parseJsonList<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    final data = jsonDecode(jsonString) as List;
    return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }
  
  static Map<String, dynamic> parseJsonMap(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
