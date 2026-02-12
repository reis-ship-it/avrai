/// Validation utilities for SPOTS core models
class ValidationUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, contains letter and number
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }
  
  /// Validate coordinates
  static bool isValidLatitude(double latitude) {
    return latitude >= -90.0 && latitude <= 90.0;
  }
  
  static bool isValidLongitude(double longitude) {
    return longitude >= -180.0 && longitude <= 180.0;
  }
  
  /// Validate spot name
  static bool isValidSpotName(String name) {
    return name.trim().isNotEmpty && name.length <= 100;
  }
  
  /// Validate spot description
  static bool isValidSpotDescription(String description) {
    return description.trim().isNotEmpty && description.length <= 500;
  }
  
  /// Validate list title
  static bool isValidListTitle(String title) {
    return title.trim().isNotEmpty && title.length <= 100;
  }
  
  /// Validate list description
  static bool isValidListDescription(String description) {
    return description.trim().isNotEmpty && description.length <= 1000;
  }
  
  /// Validate user name
  static bool isValidUserName(String name) {
    return name.trim().isNotEmpty && name.length <= 50;
  }
  
  /// Validate user bio
  static bool isValidUserBio(String bio) {
    return bio.length <= 200;
  }
  
  /// Validate rating (0.0 to 5.0)
  static bool isValidRating(double rating) {
    return rating >= 0.0 && rating <= 5.0;
  }
  
  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Validate phone number (basic format)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }
  
  /// Validate that string is not empty or only whitespace
  static bool isNotEmptyOrWhitespace(String value) {
    return value.trim().isNotEmpty;
  }
  
  /// Validate string length is within range
  static bool isValidLength(String value, int minLength, int maxLength) {
    final length = value.trim().length;
    return length >= minLength && length <= maxLength;
  }
  
  /// Validate that list contains only unique items
  static bool hasUniqueItems<T>(List<T> list) {
    return list.toSet().length == list.length;
  }
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  final String field;
  
  const ValidationException(this.message, this.field);
  
  @override
  String toString() => 'ValidationException: $message (field: $field)';
}
