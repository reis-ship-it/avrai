import 'dart:developer' as developer;

/// Admin Privacy Filter
/// Ensures admins can only see AI-related data, never personal user information
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
class AdminPrivacyFilter {
  static const String _logName = 'AdminPrivacyFilter';
  
  // List of keys that contain personal data and must be filtered out
  // Note: Location data is allowed (core vibe indicator), but home address is forbidden
  static const List<String> _forbiddenKeys = [
    'name',
    'email',
    'phone',
    'home_address',
    'homeaddress',
    'home_address',
    'residential_address',
    'personal_address',
    'personal',
    'contact',
    'profile',
    'displayname',
    'username',
  ];
  
  // Specific keys that are forbidden even if they contain "location"
  static const List<String> _forbiddenLocationKeys = [
    'home_address',
    'homeaddress',
    'residential_address',
    'personal_address',
  ];
  
  // List of keys that are safe to show (AI-related and location data)
  // Location data is allowed as it's a core vibe indicator
  static const List<String> _allowedKeys = [
    'ai_signature',
    'user_id',
    'ai_personality',
    'ai_connections',
    'ai_metrics',
    'connection_id',
    'ai_status',
    'ai_activity',
    'location', // Location data is allowed (vibe indicator)
    'current_location',
    'visited_locations',
    'location_history',
    'geographic_data',
    'vibe_location',
    'spot_locations',
  ];
  
  /// Filter out personal data from a data map
  /// Returns AI-related data and location data (vibe indicators), but excludes home address
  static Map<String, dynamic> filterPersonalData(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      
      // First check for forbidden home address keys (highest priority)
      final isHomeAddress = _forbiddenLocationKeys.any((forbidden) => key.contains(forbidden));
      if (isHomeAddress) {
        developer.log('Filtered out home address key: ${entry.key}', name: _logName);
        continue;
      }
      
      // Check if key contains other forbidden personal data keywords
      final isForbidden = _forbiddenKeys.any((forbidden) => key.contains(forbidden));
      
      // Check if key is explicitly allowed (AI-related or location data)
      final isAllowed = _allowedKeys.any((allowed) => key.contains(allowed));
      
      if (!isForbidden && (isAllowed || _isSafeKey(key) || _isLocationKey(key))) {
        // Recursively filter nested maps
        if (entry.value is Map) {
          final nestedFiltered = filterPersonalData(entry.value as Map<String, dynamic>);
          if (nestedFiltered.isNotEmpty) {
            filtered[entry.key] = nestedFiltered;
          }
        } else {
          filtered[entry.key] = entry.value;
        }
      } else if (isForbidden) {
        developer.log('Filtered out personal data key: ${entry.key}', name: _logName);
      }
    }
    
    return filtered;
  }
  
  /// Check if a key represents location data (allowed as vibe indicator)
  /// but not home address (forbidden)
  static bool _isLocationKey(String key) {
    // Allow location-related keys but exclude home address
    if (key.contains('location') || 
        key.contains('geographic') ||
        key.contains('coordinates') ||
        key.contains('latitude') ||
        key.contains('longitude') ||
        key.contains('visited') ||
        key.contains('spot_location')) {
      // But exclude home address
      return !_forbiddenLocationKeys.any((forbidden) => key.contains(forbidden));
    }
    return false;
  }
  
  /// Check if a key is safe to include (doesn't contain personal data)
  static bool _isSafeKey(String key) {
    // Keys that are clearly AI/system related
    if (key.startsWith('ai_') || 
        key.startsWith('system_') ||
        key.startsWith('connection_') ||
        key == 'id' ||
        key == 'user_id' ||
        key == 'timestamp' ||
        key == 'created_at' ||
        key == 'updated_at') {
      return true;
    }
    
    return false;
  }
  
  /// Validate that a data map contains no personal information
  /// Location data is allowed, but home address is forbidden
  static bool isValid(Map<String, dynamic> data) {
    for (final key in data.keys) {
      final lowerKey = key.toLowerCase();
      
      // Check for forbidden home address keys
      if (_forbiddenLocationKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
      
      // Check for other forbidden personal data
      if (_forbiddenKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
    }
    return true;
  }
  
  /// Sanitize user search results to remove personal data
  /// Includes location data (vibe indicators) but excludes home address
  static Map<String, dynamic> sanitizeUserData(Map<String, dynamic> userData) {
    final sanitized = <String, dynamic>{};
    
    // Only include safe fields
    if (userData.containsKey('id')) {
      sanitized['id'] = userData['id'];
    }
    if (userData.containsKey('user_id')) {
      sanitized['user_id'] = userData['user_id'];
    }
    if (userData.containsKey('ai_signature')) {
      sanitized['ai_signature'] = userData['ai_signature'];
    }
    if (userData.containsKey('created_at')) {
      sanitized['created_at'] = userData['created_at'];
    }
    if (userData.containsKey('is_active')) {
      sanitized['is_active'] = userData['is_active'];
    }
    
    // Include location data (vibe indicators) but filter out home address
    if (userData.containsKey('current_location')) {
      sanitized['current_location'] = userData['current_location'];
    }
    if (userData.containsKey('visited_locations')) {
      sanitized['visited_locations'] = userData['visited_locations'];
    }
    if (userData.containsKey('location_history')) {
      sanitized['location_history'] = userData['location_history'];
    }
    
    // Filter any additional data (will include location but exclude home address)
    final filtered = filterPersonalData(userData);
    sanitized.addAll(filtered);
    
    return sanitized;
  }
}

