import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

/// Schedules nightly memory consolidation when device conditions are favorable.
///
/// Phase 1.1C.1:
/// - charging
/// - connected to Wi-Fi
/// - idle (screen off) for at least 30 minutes
class NightlyMemoryConsolidationScheduler with WidgetsBindingObserver {
  static const String _logName = 'NightlyConsolidationScheduler';
  static const String _prefsKeyLastScreenOffMs =
      'nightly_consolidation_last_screen_off_ms_v1';
  static const String _prefsKeyLastTriggerMs =
      'nightly_consolidation_last_trigger_ms_v1';

  final SharedPreferencesCompat _prefs;
  final ConsolidationBatteryGateway _battery;
  final ConsolidationConnectivityGateway _connectivity;
  final Future<void> Function() _onConsolidationRequested;
  final Duration _idleRequired;
  final Duration _minTriggerInterval;
  final DateTime Function() _now;

  StreamSubscription<BatteryState>? _batterySub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _pollTimer;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  DateTime? _lastScreenOffAt;
  DateTime? _lastTriggeredAt;

  NightlyMemoryConsolidationScheduler({
    required SharedPreferencesCompat prefs,
    required Future<void> Function() onConsolidationRequested,
    ConsolidationBatteryGateway? battery,
    ConsolidationConnectivityGateway? connectivity,
    Duration idleRequired = const Duration(minutes: 30),
    Duration minTriggerInterval = const Duration(hours: 10),
    DateTime Function()? now,
  })  : _prefs = prefs,
        _onConsolidationRequested = onConsolidationRequested,
        _battery = battery ?? BatteryPlusConsolidationGateway(),
        _connectivity = connectivity ?? ConnectivityPlusConsolidationGateway(),
        _idleRequired = idleRequired,
        _minTriggerInterval = minTriggerInterval,
        _now = now ?? DateTime.now;

  Future<void> start() async {
    if (kIsWeb) return;

    final storedScreenOffMs = _prefs.getInt(_prefsKeyLastScreenOffMs);
    if (storedScreenOffMs != null && storedScreenOffMs > 0) {
      _lastScreenOffAt = DateTime.fromMillisecondsSinceEpoch(
        storedScreenOffMs,
        isUtc: true,
      ).toLocal();
    }
    final storedTriggerMs = _prefs.getInt(_prefsKeyLastTriggerMs);
    if (storedTriggerMs != null && storedTriggerMs > 0) {
      _lastTriggeredAt = DateTime.fromMillisecondsSinceEpoch(
        storedTriggerMs,
        isUtc: true,
      ).toLocal();
    }

    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    } catch (_) {
      _lifecycleState = AppLifecycleState.resumed;
    }

    _batterySub?.cancel();
    _batterySub = _battery.onBatteryStateChanged.listen((_) {
      unawaited(_evaluateAndTrigger(reason: 'battery_changed'));
    });

    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) {
      unawaited(_evaluateAndTrigger(reason: 'connectivity_changed'));
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_evaluateAndTrigger(reason: 'poll'));
    });

    await _evaluateAndTrigger(reason: 'start');
  }

  Future<void> stop() async {
    await _batterySub?.cancel();
    _batterySub = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {
      // Ignore.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (_isScreenOff(state)) {
      _markScreenOff(_now());
    }
    if (state == AppLifecycleState.resumed) {
      // Screen-on state ends idle accumulation for this cycle.
      _lastScreenOffAt = null;
      unawaited(_prefs.remove(_prefsKeyLastScreenOffMs));
    }
    unawaited(_evaluateAndTrigger(reason: 'lifecycle'));
  }

  Future<ConsolidationEligibility> evaluateEligibility() async {
    final batteryState = await _battery.getBatteryState();
    final connectivity = await _connectivity.checkConnectivity();

    final isCharging = batteryState == BatteryState.charging ||
        batteryState == BatteryState.full;
    final isWifi = connectivity.contains(ConnectivityResult.wifi);

    final now = _now();
    final idleSince = _lastScreenOffAt;
    final isIdleLongEnough = idleSince != null &&
        _isScreenOff(_lifecycleState) &&
        now.difference(idleSince) >= _idleRequired;

    final lastTrigger = _lastTriggeredAt;
    final triggerCooldownSatisfied = lastTrigger == null ||
        now.difference(lastTrigger) >= _minTriggerInterval;

    return ConsolidationEligibility(
      isCharging: isCharging,
      isWifi: isWifi,
      isIdleLongEnough: isIdleLongEnough,
      triggerCooldownSatisfied: triggerCooldownSatisfied,
    );
  }

  Future<void> _evaluateAndTrigger({required String reason}) async {
    try {
      final eligibility = await evaluateEligibility();
      if (!eligibility.isEligible) return;

      _lastTriggeredAt = _now();
      await _prefs.setInt(
        _prefsKeyLastTriggerMs,
        _lastTriggeredAt!.toUtc().millisecondsSinceEpoch,
      );
      developer.log(
        'Consolidation trigger accepted ($reason)',
        name: _logName,
      );
      await _onConsolidationRequested();
    } catch (e, st) {
      developer.log(
        'Failed to evaluate nightly consolidation schedule',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _markScreenOff(DateTime timestamp) {
    if (_lastScreenOffAt != null) return;
    _lastScreenOffAt = timestamp;
    unawaited(
      _prefs.setInt(
        _prefsKeyLastScreenOffMs,
        timestamp.toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  bool _isScreenOff(AppLifecycleState state) {
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached;
  }
}

class ConsolidationEligibility {
  final bool isCharging;
  final bool isWifi;
  final bool isIdleLongEnough;
  final bool triggerCooldownSatisfied;

  const ConsolidationEligibility({
    required this.isCharging,
    required this.isWifi,
    required this.isIdleLongEnough,
    required this.triggerCooldownSatisfied,
  });

  bool get isEligible =>
      isCharging && isWifi && isIdleLongEnough && triggerCooldownSatisfied;
}

abstract class ConsolidationBatteryGateway {
  Future<BatteryState> getBatteryState();
  Stream<BatteryState> get onBatteryStateChanged;
}

class BatteryPlusConsolidationGateway implements ConsolidationBatteryGateway {
  BatteryPlusConsolidationGateway({Battery? battery})
      : _battery = battery ?? Battery();

  final Battery _battery;

  @override
  Future<BatteryState> getBatteryState() => _battery.batteryState;

  @override
  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;
}

abstract class ConsolidationConnectivityGateway {
  Future<List<ConnectivityResult>> checkConnectivity();
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class ConnectivityPlusConsolidationGateway
    implements ConsolidationConnectivityGateway {
  ConnectivityPlusConsolidationGateway({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
