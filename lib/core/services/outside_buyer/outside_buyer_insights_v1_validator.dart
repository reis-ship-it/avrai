/// Outside buyer insights (v1) contract validator.
///
/// This is used for automated tests and defense-in-depth assertions on any
/// export path that claims to follow:
/// `docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md`.
///
/// **Important:** Outside-buyer exports must never contain stable identifiers,
/// precise GPS, or joinable trajectories. This validator primarily enforces:
/// - deny-list key scan
/// - required schema shape + enums
/// - delay + DP metadata presence
library;

/// Validates rows in `spots_insights_v1`.
class OutsideBuyerInsightsV1Validator {
  /// Contract deny-list: keys that must never appear anywhere in a row.
  ///
  /// This is intentionally strict; add entries only when the contract expands.
  static const Set<String> forbiddenKeysLowercase = <String>{
    // Stable IDs / identifiers
    'user_id',
    'agent_id',
    'ai_signature',
    'device_id',
    'advertising_id',
    'ip_address',
    'session_id',

    // Precise GPS / trajectories
    'latitude',
    'longitude',
    'location_history',
    'visited_locations',
    'current_location',

    // Raw content / embeddings
    'message',
    'text',
    'transcript',
    'embedding',
    'embeddings',
    'vector',
    'vectors',
  };

  static const Set<String> allowedTimeGranularity = <String>{'hour', 'day', 'week'};

  static const Set<String> allowedDoorTypes = <String>{'spot', 'event', 'community'};

  static const Set<String> allowedContexts = <String>{
    'morning',
    'midday',
    'evening',
    'weekend',
    'unknown',
  };

  static const Set<String> allowedCategories = <String>{
    'coffee',
    'music',
    'sports',
    'art',
    'food',
    'outdoor',
    'tech',
    'community',
    'other',
  };

  /// Validates a single row. Throws [FormatException] if invalid.
  static void validateRow(
    Map<String, Object?> row, {
    int minimumReportingDelayHours = 72,
  }) {
    _denyListScan(row);

    _expectString(row, 'schema_version', equalsTo: '1.0');
    _expectString(row, 'dataset', equalsTo: 'spots_insights_v1');

    _expectString(row, 'time_bucket_start_utc');
    final timeGranularity = _expectString(row, 'time_granularity');
    if (!allowedTimeGranularity.contains(timeGranularity)) {
      throw FormatException('Invalid time_granularity: $timeGranularity');
    }

    final delayHours = _expectInt(row, 'reporting_delay_hours');
    if (delayHours < minimumReportingDelayHours) {
      throw FormatException(
          'reporting_delay_hours too small: $delayHours (min $minimumReportingDelayHours)');
    }

    final geoBucket = _expectMap(row, 'geo_bucket');
    _expectString(geoBucket, 'type');
    _expectString(geoBucket, 'id');

    final segment = _expectMap(row, 'segment');
    final doorType = _expectString(segment, 'door_type');
    if (!allowedDoorTypes.contains(doorType)) {
      throw FormatException('Invalid segment.door_type: $doorType');
    }
    final category = _expectString(segment, 'category');
    if (!allowedCategories.contains(category)) {
      throw FormatException('Invalid segment.category: $category');
    }
    final context = _expectString(segment, 'context');
    if (!allowedContexts.contains(context)) {
      throw FormatException('Invalid segment.context: $context');
    }

    final privacy = _expectMap(row, 'privacy');
    _expectInt(privacy, 'k_min_enforced');
    final suppressed = _expectBool(privacy, 'suppressed');
    // suppressed_reason may be null

    final dp = _expectMap(privacy, 'dp');
    final dpEnabled = _expectBool(dp, 'enabled');
    if (!dpEnabled) {
      throw const FormatException('privacy.dp.enabled must be true');
    }
    _expectString(dp, 'mechanism');
    _expectNum(dp, 'epsilon');
    _expectNum(dp, 'delta');
    _expectInt(dp, 'budget_window_days');

    final metrics = _expectMap(row, 'metrics');
    final uniqueParticipants = metrics['unique_participants_est'];
    final doorsOpened = metrics['doors_opened_est'];
    final repeatRate = metrics['repeat_rate_est'];
    final trendScore = metrics['trend_score_est'];

    if (suppressed) {
      // When suppressed, metrics may be omitted or null; we enforce "null or num" to keep schema stable.
      _expectNullOrNum(uniqueParticipants, 'metrics.unique_participants_est');
      _expectNullOrNum(doorsOpened, 'metrics.doors_opened_est');
      _expectNullOrNum(repeatRate, 'metrics.repeat_rate_est');
      _expectNullOrNum(trendScore, 'metrics.trend_score_est');
      return;
    }

    final uniqueNum = _expectNumValue(uniqueParticipants, 'metrics.unique_participants_est');
    final doorsNum = _expectNumValue(doorsOpened, 'metrics.doors_opened_est');
    final repeatNum = _expectNumValue(repeatRate, 'metrics.repeat_rate_est');
    final trendNum = _expectNumValue(trendScore, 'metrics.trend_score_est');

    if (uniqueNum < 0 || doorsNum < 0) {
      throw const FormatException('metrics counts must be >= 0');
    }
    if (repeatNum < 0 || repeatNum > 1) {
      throw const FormatException('repeat_rate_est must be in [0,1]');
    }
    if (trendNum < 0 || trendNum > 1) {
      throw const FormatException('trend_score_est must be in [0,1]');
    }
  }

  static void _denyListScan(Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = (entry.key ?? '').toString();
        final lower = key.toLowerCase();
        if (forbiddenKeysLowercase.contains(lower)) {
          throw FormatException('Forbidden key present: $key');
        }
        _denyListScan(entry.value);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        _denyListScan(item);
      }
    }
  }

  static Map<String, Object?> _expectMap(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw FormatException('Expected map for $key');
  }

  static String _expectString(
    Map<String, Object?> root,
    String key, {
    String? equalsTo,
  }) {
    final value = root[key];
    if (value is! String) {
      throw FormatException('Expected string for $key');
    }
    if (equalsTo != null && value != equalsTo) {
      throw FormatException('Expected $key="$equalsTo", got "$value"');
    }
    return value;
  }

  static int _expectInt(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected int for $key');
  }

  static bool _expectBool(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is bool) return value;
    throw FormatException('Expected bool for $key');
  }

  static num _expectNum(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is num) return value;
    throw FormatException('Expected num for $key');
  }

  static void _expectNullOrNum(Object? value, String label) {
    if (value == null) return;
    if (value is num) return;
    throw FormatException('Expected null or num for $label');
  }

  static num _expectNumValue(Object? value, String label) {
    if (value is num) return value;
    throw FormatException('Expected num for $label');
  }
}

