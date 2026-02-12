import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/battery_adaptive_ble_scheduler.dart';

void main() {
  test('Battery scan policy is aggressive when charging', () {
    final policy = BatteryScanPolicy.decide(
      batteryLevel: 5,
      state: BatteryState.charging,
    );

    expect(policy.scanInterval, Duration.zero);
    expect(policy.scanWindow, const Duration(seconds: 4));
  });

  test('Battery scan policy backs off when battery is low', () {
    final policy = BatteryScanPolicy.decide(
      batteryLevel: 10,
      state: BatteryState.discharging,
    );

    expect(policy.scanWindow, const Duration(seconds: 2));
    expect(policy.scanInterval, const Duration(seconds: 12));
  });

  test('Battery scan policy honors OS battery saver mode first', () {
    final policy = BatteryScanPolicy.decide(
      batteryLevel: 95,
      state: BatteryState.discharging,
      isInBatterySaveMode: true,
    );

    expect(policy.scanWindow, const Duration(seconds: 2));
    expect(policy.scanInterval, const Duration(seconds: 28));
  });

  test('Battery scan policy keeps <=5s cadence at 30%+ (walk-by budget)', () {
    final policy = BatteryScanPolicy.decide(
      batteryLevel: 30,
      state: BatteryState.discharging,
    );

    // Cadence ≈ scanWindow + scanInterval when scanInterval > 0.
    final cadence = policy.scanWindow + policy.scanInterval;
    expect(cadence, lessThanOrEqualTo(const Duration(seconds: 5)));
  });

  test('Battery scan policy uses continuous scanning only in burst/charging',
      () {
    final discharging = BatteryScanPolicy.decide(
      batteryLevel: 95,
      state: BatteryState.discharging,
    );
    expect(discharging.scanInterval, isNot(Duration.zero));

    final burst = BatteryScanPolicy.decide(
      batteryLevel: 95,
      state: BatteryState.discharging,
      burstMode: true,
    );
    expect(burst.scanInterval, Duration.zero);
  });
}
