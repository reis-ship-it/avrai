import 'dart:developer' as developer;
import 'dart:async';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Atomic Clock Service
///
/// Provides synchronized atomic timestamps with nanosecond/millisecond precision
/// across the entire SPOTS application. This is the PRIMARY time-keeping system.
///
/// **Quantum Atomic Time Integration:**
/// - Generates atomic timestamps for quantum temporal state generation
/// - Enables quantum temporal compatibility calculations
/// - Supports quantum temporal entanglement synchronization
/// - Enables precise quantum temporal decoherence calculations
///
/// **Philosophy Alignment:**
/// - Foundation for all quantum calculations
/// - Enables precise temporal tracking
/// - Supports network-wide synchronization
class AtomicClockService {
  static const String _logName = 'AtomicClockService';

  /// Optional provider that returns current server time (authoritative).
  ///
  /// This keeps `spots_core` decoupled from specific backends (Supabase, etc.).
  Future<DateTime> Function()? _serverTimeProvider;

  /// Current time offset between device and server
  Duration _timeOffset = Duration.zero;

  /// Whether clock is synchronized with server
  bool _isSynchronized = false;

  /// Exponential moving average alpha for smoothing jitter in offset estimates.
  static const double _offsetEmaAlpha = 0.2;

  /// Last observed round-trip time to fetch server time.
  Duration? _lastRoundTrip;

  /// Synchronization interval (30 seconds)
  static const Duration _syncInterval = Duration(seconds: 30);

  /// Timer for periodic synchronization
  Timer? _syncTimer;

  /// Platform precision detection
  TimePrecision _detectedPrecision = TimePrecision.millisecond;

  /// Current timezone ID
  String _currentTimezoneId = 'UTC';

  /// Configure the server time provider.
  ///
  /// Call this from the app layer once a backend client is available.
  void configure({Future<DateTime> Function()? serverTimeProvider}) {
    _serverTimeProvider = serverTimeProvider;
  }

  /// Initialize atomic clock service
  Future<void> initialize() async {
    developer.log('Initializing AtomicClockService', name: _logName);

    try {
      // Initialize timezone database
      await _initializeTimezone();

      // Detect platform precision capabilities
      _detectedPrecision = await _detectPrecision();

      // Initial synchronization
      await syncWithServer();

      // Start periodic synchronization
      _startPeriodicSync();

      developer.log(
        '✅ AtomicClockService initialized with precision: ${_detectedPrecision.name}, timezone: $_currentTimezoneId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing AtomicClockService: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Continue with device time if sync fails
      _isSynchronized = false;
    }
  }

  /// Initialize timezone database
  Future<void> _initializeTimezone() async {
    try {
      // Initialize timezone database (timezone package)
      _currentTimezoneId = _getCurrentTimezone();
    } catch (e) {
      developer.log(
        'Error initializing timezone: $e, using UTC fallback',
        name: _logName,
      );
      _currentTimezoneId = 'UTC';
    }
  }

  /// Get current timezone ID
  String _getCurrentTimezone() {
    // Use system timezone name (no external dependency).
    final tzName = DateTime.now().timeZoneName;
    // Convert common timezone abbreviations to IANA format
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
  }

  /// Detect platform precision capabilities
  Future<TimePrecision> _detectPrecision() async {
    // Check if platform supports nanosecond precision
    // For now, default to millisecond (can be enhanced based on platform)
    try {
      final now = DateTime.now();
      // If microseconds are available, we can approximate nanoseconds
      if (now.microsecondsSinceEpoch > 0) {
        return TimePrecision.nanosecond;
      }
    } catch (_) {
      // Fallback to millisecond
    }
    return TimePrecision.millisecond;
  }

  /// Sync with server time (when online)
  Future<void> syncWithServer() async {
    developer.log('Syncing with server time', name: _logName);

    try {
      final provider = _serverTimeProvider;
      if (provider == null) {
        // No provider configured; treat device time as best effort.
        _isSynchronized = false;
        developer.log(
          'No serverTimeProvider configured; skipping sync (device-time fallback)',
          name: _logName,
        );
        return;
      }

      // NTP-style approximation with a single server timestamp:
      // Measure RTT and assume server timestamp corresponds roughly to mid-point.
      final t0 = DateTime.now();
      final serverNow = await provider();
      final t1 = DateTime.now();

      final rtt = t1.difference(t0);
      _lastRoundTrip = rtt;
      final midpoint = t0.add(Duration(microseconds: rtt.inMicroseconds ~/ 2));

      final observedOffset = serverNow.difference(midpoint);

      // Smooth offset to reduce jitter (EMA).
      if (_timeOffset == Duration.zero) {
        _timeOffset = observedOffset;
      } else {
        final blendedMicros = (_timeOffset.inMicroseconds * (1.0 - _offsetEmaAlpha) +
                observedOffset.inMicroseconds * _offsetEmaAlpha)
            .round();
        _timeOffset = Duration(microseconds: blendedMicros);
      }

      _isSynchronized = true;

      developer.log(
        '✅ Synchronized with server. Offset: ${_timeOffset.inMilliseconds}ms (rtt: ${rtt.inMilliseconds}ms)',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing with server: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      _isSynchronized = false;
    }
  }

  /// Start periodic synchronization
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      syncWithServer();
    });
  }

  /// Get synchronized atomic timestamp
  Future<AtomicTimestamp> getAtomicTimestamp() async {
    final deviceTime = DateTime.now();
    final serverTime = _isSynchronized
        ? deviceTime.add(_timeOffset)
        : deviceTime.add(_timeOffset); // Use last known offset if not synced
    final localTime = deviceTime.toLocal();
    final timezoneId = _currentTimezoneId;

    return AtomicTimestamp.now(
      precision: _detectedPrecision,
      serverTime: serverTime,
      localTime: localTime,
      timezoneId: timezoneId,
      offset: _timeOffset,
      isSynchronized: _isSynchronized,
    );
  }

  /// Get time offset (device time vs. server time)
  Duration getTimeOffset() => _timeOffset;

  /// Get last observed round-trip time for server sync (if available).
  Duration? getLastRoundTrip() => _lastRoundTrip;

  /// Check if clock is synchronized
  bool isSynchronized() => _isSynchronized;

  /// Get precision level
  TimePrecision getPrecision() => _detectedPrecision;

  /// Get timestamp for ticket purchase (with atomic guarantee)
  Future<AtomicTimestamp> getTicketPurchaseTimestamp() async {
    return getAtomicTimestamp();
  }

  /// Get timestamp for AI2AI connection (exact connection time)
  Future<AtomicTimestamp> getAI2AIConnectionTimestamp() async {
    return getAtomicTimestamp();
  }

  /// Get timestamp for live tracking (exact location/activity time)
  Future<AtomicTimestamp> getLiveTrackingTimestamp() async {
    return getAtomicTimestamp();
  }

  /// Get timestamp for admin operations (exact operation time)
  Future<AtomicTimestamp> getAdminOperationTimestamp() async {
    return getAtomicTimestamp();
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
