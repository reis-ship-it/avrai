import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/consolidation/nightly_memory_consolidation_scheduler.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('NightlyMemoryConsolidationScheduler', () {
    test('does not trigger unless charging + wifi + idle>=30m', () async {
      final prefs = await SharedPreferencesCompat.getInstance();
      await prefs.clear();

      DateTime now = DateTime(2026, 2, 20, 0, 0, 0);
      final battery = _FakeBatteryGateway(BatteryState.discharging);
      final connectivity =
          _FakeConnectivityGateway(const [ConnectivityResult.mobile]);
      var triggers = 0;

      final scheduler = NightlyMemoryConsolidationScheduler(
        prefs: prefs,
        battery: battery,
        connectivity: connectivity,
        onConsolidationRequested: () async {
          triggers += 1;
        },
        now: () => now,
      );

      await scheduler.start();
      expect(triggers, 0);

      scheduler.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 40));

      // Not charging + not wifi => still blocked.
      battery.emit(BatteryState.discharging);
      connectivity.emit(const [ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);
      expect(triggers, 0);

      // Become charging + wifi and emit a state change to evaluate.
      battery.emit(BatteryState.charging);
      connectivity.emit(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(triggers, 1);

      await scheduler.stop();
    });

    test('respects trigger cooldown before firing again', () async {
      final prefs = await SharedPreferencesCompat.getInstance();
      await prefs.clear();

      DateTime now = DateTime(2026, 2, 20, 1, 0, 0);
      final battery = _FakeBatteryGateway(BatteryState.charging);
      final connectivity =
          _FakeConnectivityGateway(const [ConnectivityResult.wifi]);
      var triggers = 0;

      final scheduler = NightlyMemoryConsolidationScheduler(
        prefs: prefs,
        battery: battery,
        connectivity: connectivity,
        onConsolidationRequested: () async {
          triggers += 1;
        },
        now: () => now,
      );

      await scheduler.start();
      scheduler.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 31));

      battery.emit(BatteryState.charging);
      await Future<void>.delayed(Duration.zero);
      expect(triggers, 1);

      // Within cooldown window: no second trigger.
      now = now.add(const Duration(hours: 2));
      battery.emit(BatteryState.charging);
      await Future<void>.delayed(Duration.zero);
      expect(triggers, 1);

      // Past default cooldown (10h): trigger again.
      now = now.add(const Duration(hours: 9));
      connectivity.emit(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(triggers, 2);

      await scheduler.stop();
    });
  });
}

class _FakeBatteryGateway implements ConsolidationBatteryGateway {
  _FakeBatteryGateway(this._state);

  BatteryState _state;
  final _controller = StreamController<BatteryState>.broadcast();

  @override
  Future<BatteryState> getBatteryState() async => _state;

  @override
  Stream<BatteryState> get onBatteryStateChanged => _controller.stream;

  void emit(BatteryState state) {
    _state = state;
    _controller.add(state);
  }
}

class _FakeConnectivityGateway implements ConsolidationConnectivityGateway {
  _FakeConnectivityGateway(this._state);

  List<ConnectivityResult> _state;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _state;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> state) {
    _state = state;
    _controller.add(state);
  }
}
