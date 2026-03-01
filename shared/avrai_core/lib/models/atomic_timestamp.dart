/// Atomic Timestamp Model
///
/// Represents a synchronized atomic timestamp with nanosecond/millisecond precision.
/// Used for quantum temporal state generation and precise temporal calculations.
///
/// **Quantum Atomic Time Integration:**
/// - Provides atomic timestamp quantum state `|t_atomic⟩`
/// - Enables quantum temporal state generation
/// - Supports quantum temporal compatibility calculations
/// - Enables quantum temporal entanglement and decoherence
/// - **Timezone-Aware:** Enables cross-timezone quantum temporal matching
class AtomicTimestamp {
  /// Server-synchronized time (nanosecond/millisecond precision)
  final DateTime serverTime;

  /// Device time (nanosecond/millisecond precision)
  final DateTime deviceTime;

  /// Local time (timezone-aware) - Used for cross-timezone quantum temporal matching
  final DateTime localTime;

  /// Timezone ID (e.g., "America/Los_Angeles", "Asia/Tokyo")
  final String timezoneId;

  /// Offset between device and server
  final Duration offset;

  /// Unique ID for this timestamp
  final String timestampId;

  /// Whether clock is synchronized with server
  final bool isSynchronized;

  /// Precision level (nanosecond or millisecond)
  final TimePrecision precision;

  /// Nanoseconds component (if available)
  final int? nanoseconds;

  /// Milliseconds component (always available)
  final int milliseconds;

  AtomicTimestamp({
    required this.serverTime,
    required this.deviceTime,
    required this.localTime,
    required this.timezoneId,
    required this.offset,
    required this.timestampId,
    required this.isSynchronized,
    required this.precision,
    this.nanoseconds,
    required this.milliseconds,
  });

  /// Create AtomicTimestamp from current time
  factory AtomicTimestamp.now({
    required TimePrecision precision,
    DateTime? serverTime,
    DateTime? localTime,
    String? timezoneId,
    Duration? offset,
    bool isSynchronized = false,
  }) {
    final deviceTime = DateTime.now();
    final actualServerTime = serverTime ?? deviceTime;
    final actualLocalTime = localTime ?? deviceTime.toLocal();
    final actualTimezoneId = timezoneId ?? _getSystemTimezone();
    final actualOffset = offset ?? Duration.zero;

    // Extract nanoseconds/milliseconds based on precision
    int? nanoseconds;
    int milliseconds;

    if (precision == TimePrecision.nanosecond) {
      // Try to get nanoseconds (platform-dependent)
      nanoseconds = deviceTime.microsecondsSinceEpoch * 1000; // Approximate
      milliseconds = deviceTime.millisecondsSinceEpoch;
    } else {
      milliseconds = deviceTime.millisecondsSinceEpoch;
    }

    return AtomicTimestamp(
      serverTime: actualServerTime,
      deviceTime: deviceTime,
      localTime: actualLocalTime,
      timezoneId: actualTimezoneId,
      offset: actualOffset,
      timestampId:
          'atomic_${deviceTime.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
      isSynchronized: isSynchronized,
      precision: precision,
      nanoseconds: nanoseconds,
      milliseconds: milliseconds,
    );
  }

  /// Get system timezone ID
  static String _getSystemTimezone() {
    try {
      // Use DateTime's timeZoneName as fallback
      // In production, this could use timezone package for IANA timezone IDs
      final tzName = DateTime.now().timeZoneName;
      // Convert common timezone names to IANA format
      if (tzName.contains('PST') || tzName.contains('PDT')) {
        return 'America/Los_Angeles';
      } else if (tzName.contains('EST') || tzName.contains('EDT')) {
        return 'America/New_York';
      } else if (tzName.contains('JST')) {
        return 'Asia/Tokyo';
      } else if (tzName.contains('UTC') || tzName.contains('GMT')) {
        return 'UTC';
      }
      return tzName.isNotEmpty ? tzName : 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'serverTime': serverTime.toIso8601String(),
      'deviceTime': deviceTime.toIso8601String(),
      'localTime': localTime.toIso8601String(),
      'timezoneId': timezoneId,
      'offset': offset.inMicroseconds,
      'timestampId': timestampId,
      'isSynchronized': isSynchronized,
      'precision': precision.name,
      'nanoseconds': nanoseconds,
      'milliseconds': milliseconds,
    };
  }

  /// Create from JSON
  factory AtomicTimestamp.fromJson(Map<String, dynamic> json) {
    return AtomicTimestamp(
      serverTime: DateTime.parse(json['serverTime'] as String),
      deviceTime: DateTime.parse(json['deviceTime'] as String),
      localTime: json['localTime'] != null
          ? DateTime.parse(json['localTime'] as String)
          : DateTime.parse(json['deviceTime'] as String).toLocal(),
      timezoneId: json['timezoneId'] as String? ?? 'UTC',
      offset: Duration(microseconds: json['offset'] as int),
      timestampId: json['timestampId'] as String,
      isSynchronized: json['isSynchronized'] as bool,
      precision: TimePrecision.values.firstWhere(
        (e) => e.name == json['precision'],
        orElse: () => TimePrecision.millisecond,
      ),
      nanoseconds: json['nanoseconds'] as int?,
      milliseconds: json['milliseconds'] as int,
    );
  }

  /// Get time difference between two atomic timestamps
  Duration difference(AtomicTimestamp other) {
    return serverTime.difference(other.serverTime);
  }

  /// Check if this timestamp is before another
  bool isBefore(AtomicTimestamp other) {
    return serverTime.isBefore(other.serverTime);
  }

  /// Check if this timestamp is after another
  bool isAfter(AtomicTimestamp other) {
    return serverTime.isAfter(other.serverTime);
  }

  @override
  String toString() {
    return 'AtomicTimestamp(id: $timestampId, serverTime: $serverTime, localTime: $localTime, timezone: $timezoneId, precision: $precision, synchronized: $isSynchronized)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AtomicTimestamp && other.timestampId == timestampId;
  }

  @override
  int get hashCode => timestampId.hashCode;
}

/// Time precision level
enum TimePrecision {
  /// Nanosecond precision available
  nanosecond,

  /// Millisecond precision (fallback)
  millisecond,
}
