import 'package:avrai_runtime_os/kernel/service_contracts/urk_user_runtime_observability_threshold_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../../mocks/mock_storage_service.dart';

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw Exception('Missing asset: $key');
    }
    return value;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

void main() {
  group('UrkUserRuntimeObservabilityThresholdService', () {
    test('loads thresholds from runtime controls asset', () async {
      final service = UrkUserRuntimeObservabilityThresholdService(
        assetBundle: _StringAssetBundle({
          UrkUserRuntimeObservabilityThresholdService.configPath: '''
{
  "validation": {
    "warn_opt_out_rate_pct": { "min": 1.0, "max": 90.0 },
    "critical_opt_out_rate_pct": { "min": 2.0, "max": 95.0 },
    "warn_rejection_rate_pct": { "min": 3.0, "max": 96.0 },
    "critical_rejection_rate_pct": { "min": 4.0, "max": 97.0 },
    "require_critical_gte_warn": true
  },
  "windows": {
    "1h": {
      "warn_opt_out_rate_pct": 5.0,
      "critical_opt_out_rate_pct": 10.0,
      "warn_rejection_rate_pct": 7.0,
      "critical_rejection_rate_pct": 14.0
    },
    "24h": {
      "warn_opt_out_rate_pct": 9.0,
      "critical_opt_out_rate_pct": 13.0,
      "warn_rejection_rate_pct": 11.0,
      "critical_rejection_rate_pct": 17.0
    }
  }
}
''',
        }),
      );

      final thresholds = await service.load();
      final oneHour =
          thresholds.forWindow(UrkUserRuntimeObservabilityWindow.last1h);
      final oneDay =
          thresholds.forWindow(UrkUserRuntimeObservabilityWindow.last24h);

      expect(oneHour.warnOptOutRatePct, 5.0);
      expect(oneHour.criticalRejectionRatePct, 14.0);
      expect(oneDay.warnOptOutRatePct, 9.0);
      expect(oneDay.criticalOptOutRatePct, 13.0);
      expect(thresholds.validation.warnOptOutRatePct.min, 1.0);
      expect(thresholds.validation.warnOptOutRatePct.max, 90.0);
      expect(thresholds.validation.criticalRejectionRatePct.min, 4.0);
      expect(thresholds.validation.criticalRejectionRatePct.max, 97.0);
      expect(thresholds.validation.requireCriticalGteWarn, isTrue);
    });

    test('falls back to defaults when asset is missing', () async {
      final service = UrkUserRuntimeObservabilityThresholdService(
        assetBundle: _StringAssetBundle({}),
      );

      final thresholds = await service.load();
      final defaults =
          UrkUserRuntimeObservabilityThresholds.defaultThresholds();

      expect(
        thresholds
            .forWindow(UrkUserRuntimeObservabilityWindow.last6h)
            .warnOptOutRatePct,
        defaults
            .forWindow(UrkUserRuntimeObservabilityWindow.last6h)
            .warnOptOutRatePct,
      );
      expect(
        thresholds
            .forWindow(UrkUserRuntimeObservabilityWindow.last7d)
            .criticalRejectionRatePct,
        defaults
            .forWindow(UrkUserRuntimeObservabilityWindow.last7d)
            .criticalRejectionRatePct,
      );
      expect(
        thresholds.validation.warnOptOutRatePct.min,
        defaults.validation.warnOptOutRatePct.min,
      );
      expect(
        thresholds.validation.warnOptOutRatePct.max,
        defaults.validation.warnOptOutRatePct.max,
      );
    });

    test('merges partial config with defaults', () async {
      final service = UrkUserRuntimeObservabilityThresholdService(
        assetBundle: _StringAssetBundle({
          UrkUserRuntimeObservabilityThresholdService.configPath: '''
{
  "windows": {
    "6h": {
      "warn_opt_out_rate_pct": 6.0,
      "critical_opt_out_rate_pct": 11.0,
      "warn_rejection_rate_pct": 8.0,
      "critical_rejection_rate_pct": 15.0
    }
  }
}
''',
        }),
      );

      final thresholds = await service.load();
      final sixHour =
          thresholds.forWindow(UrkUserRuntimeObservabilityWindow.last6h);
      final oneHour =
          thresholds.forWindow(UrkUserRuntimeObservabilityWindow.last1h);

      expect(sixHour.warnOptOutRatePct, 6.0);
      expect(sixHour.criticalOptOutRatePct, 11.0);
      expect(oneHour.warnOptOutRatePct, 15.0);
      expect(oneHour.criticalRejectionRatePct, 30.0);
    });

    test('falls back to default validation when validation section is invalid',
        () async {
      final service = UrkUserRuntimeObservabilityThresholdService(
        assetBundle: _StringAssetBundle({
          UrkUserRuntimeObservabilityThresholdService.configPath: '''
{
  "validation": {
    "warn_opt_out_rate_pct": { "min": 80.0, "max": 10.0 }
  },
  "windows": {
    "1h": {
      "warn_opt_out_rate_pct": 5.0,
      "critical_opt_out_rate_pct": 10.0,
      "warn_rejection_rate_pct": 7.0,
      "critical_rejection_rate_pct": 14.0
    }
  }
}
''',
        }),
      );

      final thresholds = await service.load();
      expect(thresholds.validation.warnOptOutRatePct.min, 0.0);
      expect(thresholds.validation.warnOptOutRatePct.max, 100.0);
      expect(thresholds.validation.requireCriticalGteWarn, isTrue);
    });
  });

  group('UrkUserRuntimeObservabilityThresholdOverrideService', () {
    late SharedPreferencesCompat prefs;

    setUp(() async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'urk_threshold_override_test');
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    });

    test('loads effective thresholds with persisted window override', () async {
      final service = UrkUserRuntimeObservabilityThresholdOverrideService(
        prefs: prefs,
        baseService: UrkUserRuntimeObservabilityThresholdService(
          assetBundle: _StringAssetBundle({
            UrkUserRuntimeObservabilityThresholdService.configPath: '''
{
  "windows": {
    "24h": {
      "warn_opt_out_rate_pct": 10.0,
      "critical_opt_out_rate_pct": 16.0,
      "warn_rejection_rate_pct": 14.0,
      "critical_rejection_rate_pct": 20.0
    }
  }
}
''',
          }),
        ),
      );

      await service.upsertWindowOverride(
        window: UrkUserRuntimeObservabilityWindow.last24h,
        entry: const UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 11.0,
          criticalOptOutRatePct: 17.0,
          warnRejectionRatePct: 15.0,
          criticalRejectionRatePct: 21.0,
        ),
        actor: 'admin:test',
      );

      final effective = await service.loadEffective();
      final last24h =
          effective.forWindow(UrkUserRuntimeObservabilityWindow.last24h);
      expect(last24h.warnOptOutRatePct, 11.0);
      expect(last24h.criticalOptOutRatePct, 17.0);
      expect(last24h.warnRejectionRatePct, 15.0);
      expect(last24h.criticalRejectionRatePct, 21.0);
    });

    test('records audit events for update and reset', () async {
      final service = UrkUserRuntimeObservabilityThresholdOverrideService(
        prefs: prefs,
      );

      await service.upsertWindowOverride(
        window: UrkUserRuntimeObservabilityWindow.last6h,
        entry: const UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 12.0,
          criticalOptOutRatePct: 19.0,
          warnRejectionRatePct: 16.0,
          criticalRejectionRatePct: 23.0,
        ),
        actor: 'admin:test',
        reason: 'tune_for_local_env',
      );
      await service.clearOverrides(
        actor: 'admin:test',
        reason: 'reset',
      );

      final audit = service.listRecentAudit(limit: 5);
      expect(audit, isNotEmpty);
      expect(
        audit.first.action,
        UrkUserRuntimeObservabilityThresholdAuditAction.overridesCleared,
      );
      expect(
        audit.skip(1).first.action,
        UrkUserRuntimeObservabilityThresholdAuditAction.windowUpsert,
      );
    });

    test('rejects override entries that violate configured bounds', () async {
      final service = UrkUserRuntimeObservabilityThresholdOverrideService(
        prefs: prefs,
      );

      expect(
        () => service.upsertWindowOverride(
          window: UrkUserRuntimeObservabilityWindow.last1h,
          entry: const UrkUserRuntimeObservabilityThresholdEntry(
            warnOptOutRatePct: -1.0,
            criticalOptOutRatePct: 30.0,
            warnRejectionRatePct: 20.0,
            criticalRejectionRatePct: 40.0,
          ),
          actor: 'admin:test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects override entries when critical threshold is below warning',
        () async {
      final service = UrkUserRuntimeObservabilityThresholdOverrideService(
        prefs: prefs,
      );

      expect(
        () => service.upsertWindowOverride(
          window: UrkUserRuntimeObservabilityWindow.last24h,
          entry: const UrkUserRuntimeObservabilityThresholdEntry(
            warnOptOutRatePct: 25.0,
            criticalOptOutRatePct: 20.0,
            warnRejectionRatePct: 30.0,
            criticalRejectionRatePct: 15.0,
          ),
          actor: 'admin:test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
