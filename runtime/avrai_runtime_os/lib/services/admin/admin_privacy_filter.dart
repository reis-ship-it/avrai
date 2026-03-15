import 'dart:developer' as developer;

/// Admin Privacy Filter
/// Ensures admin oversight surfaces expose only redacted AI/system data.
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
class AdminPrivacyFilter {
  static const String _logName = 'AdminPrivacyFilter';

  // List of keys that contain personal data and must be filtered out
  // Consumer identifiers and location-bearing fields are forbidden on admin
  // oversight surfaces unless they are represented as bounded aggregates.
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
    'user_id',
    'external_payload',
    'raw_payload',
    'source_html',
    'source_body',
  ];

  // Specific keys that are forbidden even if they contain "location"
  static const List<String> _forbiddenLocationKeys = [
    'home_address',
    'homeaddress',
    'residential_address',
    'personal_address',
  ];

  // List of keys that are safe to show on admin oversight surfaces.
  // Consumer identifiers and raw location history remain forbidden.
  static const List<String> _allowedKeys = [
    'ai_signature',
    'ai_personality',
    'ai_connections',
    'ai_metrics',
    'connection_id',
    'ai_status',
    'ai_activity',
    'agent_alias',
    'run_id',
    'checkpoint_id',
    'research_state',
    'research_metrics',
    'aggregate_counts',
    'summary',
  ];

  /// Filter out personal data from a data map
  /// Returns only admin-safe AI/system data and bounded aggregates.
  static Map<String, dynamic> filterPersonalData(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();

      // First check for forbidden home address keys (highest priority)
      final isHomeAddress =
          _forbiddenLocationKeys.any((forbidden) => key.contains(forbidden));
      if (isHomeAddress) {
        developer.log('Filtered out home address key: ${entry.key}',
            name: _logName);
        continue;
      }

      // Check if key contains other forbidden personal data keywords
      final isForbidden =
          _forbiddenKeys.any((forbidden) => key.contains(forbidden));

      // Check if key is explicitly allowed (AI-related or location data)
      final isAllowed = _allowedKeys.any((allowed) => key.contains(allowed));

      if (!isForbidden && (isAllowed || _isSafeKey(key))) {
        // Recursively filter nested maps
        if (entry.value is Map) {
          final nestedFiltered = isAllowed
              ? _filterAllowedAggregateMap(entry.value as Map<String, dynamic>)
              : filterPersonalData(entry.value as Map<String, dynamic>);
          if (nestedFiltered.isNotEmpty) {
            filtered[entry.key] = nestedFiltered;
          }
        } else {
          filtered[entry.key] = entry.value;
        }
      } else if (isForbidden) {
        developer.log('Filtered out personal data key: ${entry.key}',
            name: _logName);
      }
    }

    return filtered;
  }

  /// Check if a key is safe to include (doesn't contain personal data)
  static bool _isSafeKey(String key) {
    // Keys that are clearly AI/system related
    if (key.startsWith('ai_') ||
        key.startsWith('system_') ||
        key.startsWith('research_') ||
        key.startsWith('aggregate_') ||
        key.startsWith('checkpoint_') ||
        key.startsWith('connection_') ||
        key == 'id' ||
        key == 'timestamp' ||
        key == 'created_at' ||
        key == 'updated_at') {
      return true;
    }

    return false;
  }

  static Map<String, dynamic> _filterAllowedAggregateMap(
    Map<String, dynamic> data,
  ) {
    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final isForbidden = _forbiddenKeys
              .any((forbidden) => key.contains(forbidden)) ||
          _forbiddenLocationKeys.any((forbidden) => key.contains(forbidden)) ||
          key.contains('location') ||
          key.contains('geographic') ||
          key.contains('coordinates') ||
          key.contains('latitude') ||
          key.contains('longitude') ||
          key.contains('visited');
      if (isForbidden) {
        continue;
      }
      if (entry.value is Map<String, dynamic>) {
        final nested =
            _filterAllowedAggregateMap(entry.value as Map<String, dynamic>);
        if (nested.isNotEmpty) {
          filtered[entry.key] = nested;
        }
      } else {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  /// Validate that a data map contains no personal information.
  static bool isValid(Map<String, dynamic> data) {
    for (final key in data.keys) {
      final lowerKey = key.toLowerCase();

      // Check for forbidden home address keys
      if (_forbiddenLocationKeys
          .any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }

      if (_forbiddenKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }

      if (lowerKey.contains('location') ||
          lowerKey.contains('geographic') ||
          lowerKey.contains('coordinates') ||
          lowerKey.contains('latitude') ||
          lowerKey.contains('longitude') ||
          lowerKey.contains('visited')) {
        return false;
      }
    }
    return true;
  }

  /// Sanitize user search results to remove personal data and fine-grained
  /// location history.
  static Map<String, dynamic> sanitizeUserData(Map<String, dynamic> userData) {
    final sanitized = <String, dynamic>{};

    // Only include safe fields
    if (userData.containsKey('id')) {
      sanitized['id'] = userData['id'];
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

    // Filter any additional data and keep only admin-safe aggregates.
    final filtered = filterPersonalData(userData);
    sanitized.addAll(filtered);

    return sanitized;
  }
}
