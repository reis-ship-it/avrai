import 'dart:convert';

import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

enum UrkUserRuntimeObservabilityWindow {
  last1h,
  last6h,
  last24h,
  last7d,
}

class UrkUserRuntimeObservabilityThresholdEntry {
  const UrkUserRuntimeObservabilityThresholdEntry({
    required this.warnOptOutRatePct,
    required this.criticalOptOutRatePct,
    required this.warnRejectionRatePct,
    required this.criticalRejectionRatePct,
  });

  final double warnOptOutRatePct;
  final double criticalOptOutRatePct;
  final double warnRejectionRatePct;
  final double criticalRejectionRatePct;
}

class UrkUserRuntimeObservabilityValueBounds {
  const UrkUserRuntimeObservabilityValueBounds({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;
}

class UrkUserRuntimeObservabilityValidationRules {
  const UrkUserRuntimeObservabilityValidationRules({
    required this.warnOptOutRatePct,
    required this.criticalOptOutRatePct,
    required this.warnRejectionRatePct,
    required this.criticalRejectionRatePct,
    required this.requireCriticalGteWarn,
  });

  final UrkUserRuntimeObservabilityValueBounds warnOptOutRatePct;
  final UrkUserRuntimeObservabilityValueBounds criticalOptOutRatePct;
  final UrkUserRuntimeObservabilityValueBounds warnRejectionRatePct;
  final UrkUserRuntimeObservabilityValueBounds criticalRejectionRatePct;
  final bool requireCriticalGteWarn;
}

class UrkUserRuntimeObservabilityThresholds {
  const UrkUserRuntimeObservabilityThresholds({
    required this.byWindow,
    required this.validation,
  });

  final Map<UrkUserRuntimeObservabilityWindow,
      UrkUserRuntimeObservabilityThresholdEntry> byWindow;
  final UrkUserRuntimeObservabilityValidationRules validation;

  UrkUserRuntimeObservabilityThresholdEntry forWindow(
    UrkUserRuntimeObservabilityWindow window,
  ) {
    return byWindow[window] ?? defaultThresholds().byWindow[window]!;
  }

  static UrkUserRuntimeObservabilityThresholds defaultThresholds() {
    return const UrkUserRuntimeObservabilityThresholds(
      byWindow: {
        UrkUserRuntimeObservabilityWindow.last1h:
            UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 15.0,
          criticalOptOutRatePct: 25.0,
          warnRejectionRatePct: 20.0,
          criticalRejectionRatePct: 30.0,
        ),
        UrkUserRuntimeObservabilityWindow.last6h:
            UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 12.0,
          criticalOptOutRatePct: 20.0,
          warnRejectionRatePct: 16.0,
          criticalRejectionRatePct: 24.0,
        ),
        UrkUserRuntimeObservabilityWindow.last24h:
            UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 10.0,
          criticalOptOutRatePct: 16.0,
          warnRejectionRatePct: 14.0,
          criticalRejectionRatePct: 20.0,
        ),
        UrkUserRuntimeObservabilityWindow.last7d:
            UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: 8.0,
          criticalOptOutRatePct: 12.0,
          warnRejectionRatePct: 10.0,
          criticalRejectionRatePct: 16.0,
        ),
      },
      validation: UrkUserRuntimeObservabilityValidationRules(
        warnOptOutRatePct: UrkUserRuntimeObservabilityValueBounds(
          min: 0.0,
          max: 100.0,
        ),
        criticalOptOutRatePct: UrkUserRuntimeObservabilityValueBounds(
          min: 0.0,
          max: 100.0,
        ),
        warnRejectionRatePct: UrkUserRuntimeObservabilityValueBounds(
          min: 0.0,
          max: 100.0,
        ),
        criticalRejectionRatePct: UrkUserRuntimeObservabilityValueBounds(
          min: 0.0,
          max: 100.0,
        ),
        requireCriticalGteWarn: true,
      ),
    );
  }
}

class UrkUserRuntimeObservabilityThresholdService {
  const UrkUserRuntimeObservabilityThresholdService({
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle;

  static const String configPath =
      'configs/runtime/urk_user_runtime_observability_thresholds.json';

  final AssetBundle? _assetBundle;

  Future<UrkUserRuntimeObservabilityThresholds> load() async {
    try {
      final bundle = _assetBundle ?? rootBundle;
      final raw = await bundle.loadString(configPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return UrkUserRuntimeObservabilityThresholds.defaultThresholds();
      }
      final windows = decoded['windows'];
      if (windows is! Map<String, dynamic>) {
        return UrkUserRuntimeObservabilityThresholds.defaultThresholds();
      }

      final out = <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{};
      windows.forEach((key, value) {
        final window = _windowFromKey(key);
        if (window == null || value is! Map<String, dynamic>) {
          return;
        }
        final warnOptOut = _asDouble(value['warn_opt_out_rate_pct']);
        final criticalOptOut = _asDouble(value['critical_opt_out_rate_pct']);
        final warnRejection = _asDouble(value['warn_rejection_rate_pct']);
        final criticalRejection =
            _asDouble(value['critical_rejection_rate_pct']);
        if (warnOptOut == null ||
            criticalOptOut == null ||
            warnRejection == null ||
            criticalRejection == null) {
          return;
        }
        out[window] = UrkUserRuntimeObservabilityThresholdEntry(
          warnOptOutRatePct: warnOptOut,
          criticalOptOutRatePct: criticalOptOut,
          warnRejectionRatePct: warnRejection,
          criticalRejectionRatePct: criticalRejection,
        );
      });

      if (out.isEmpty) {
        return UrkUserRuntimeObservabilityThresholds.defaultThresholds();
      }
      final defaults =
          UrkUserRuntimeObservabilityThresholds.defaultThresholds().byWindow;
      final validation = _parseValidation(decoded['validation']) ??
          UrkUserRuntimeObservabilityThresholds.defaultThresholds().validation;
      final merged = <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{
        ...defaults,
        ...out,
      };
      return UrkUserRuntimeObservabilityThresholds(
        byWindow: merged,
        validation: validation,
      );
    } catch (_) {
      return UrkUserRuntimeObservabilityThresholds.defaultThresholds();
    }
  }

  UrkUserRuntimeObservabilityWindow? _windowFromKey(String key) {
    switch (key) {
      case '1h':
        return UrkUserRuntimeObservabilityWindow.last1h;
      case '6h':
        return UrkUserRuntimeObservabilityWindow.last6h;
      case '24h':
        return UrkUserRuntimeObservabilityWindow.last24h;
      case '7d':
        return UrkUserRuntimeObservabilityWindow.last7d;
      default:
        return null;
    }
  }

  double? _asDouble(Object? value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    return null;
  }

  UrkUserRuntimeObservabilityValidationRules? _parseValidation(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final warnOptOut = _parseBounds(value['warn_opt_out_rate_pct']);
    final criticalOptOut = _parseBounds(value['critical_opt_out_rate_pct']);
    final warnRejection = _parseBounds(value['warn_rejection_rate_pct']);
    final criticalRejection =
        _parseBounds(value['critical_rejection_rate_pct']);
    final requireCriticalGteWarn =
        value['require_critical_gte_warn'] as bool? ?? true;
    if (warnOptOut == null ||
        criticalOptOut == null ||
        warnRejection == null ||
        criticalRejection == null) {
      return null;
    }
    return UrkUserRuntimeObservabilityValidationRules(
      warnOptOutRatePct: warnOptOut,
      criticalOptOutRatePct: criticalOptOut,
      warnRejectionRatePct: warnRejection,
      criticalRejectionRatePct: criticalRejection,
      requireCriticalGteWarn: requireCriticalGteWarn,
    );
  }

  UrkUserRuntimeObservabilityValueBounds? _parseBounds(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final min = _asDouble(value['min']);
    final max = _asDouble(value['max']);
    if (min == null || max == null || min > max) {
      return null;
    }
    return UrkUserRuntimeObservabilityValueBounds(min: min, max: max);
  }
}

enum UrkUserRuntimeObservabilityThresholdAuditAction {
  windowUpsert,
  overridesCleared,
}

class UrkUserRuntimeObservabilityThresholdAuditEvent {
  const UrkUserRuntimeObservabilityThresholdAuditEvent({
    required this.timestamp,
    required this.actor,
    required this.action,
    this.window,
    this.before,
    this.after,
    this.reason,
  });

  final DateTime timestamp;
  final String actor;
  final UrkUserRuntimeObservabilityThresholdAuditAction action;
  final UrkUserRuntimeObservabilityWindow? window;
  final UrkUserRuntimeObservabilityThresholdEntry? before;
  final UrkUserRuntimeObservabilityThresholdEntry? after;
  final String? reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ts': timestamp.toUtc().toIso8601String(),
        'actor': actor,
        'action': action.name,
        if (window != null) 'window': _windowKey(window!),
        if (before != null) 'before': _entryToJson(before!),
        if (after != null) 'after': _entryToJson(after!),
        if (reason != null) 'reason': reason,
      };

  static UrkUserRuntimeObservabilityThresholdAuditEvent? fromJson(
    Map<String, dynamic> json,
  ) {
    final actionName = json['action'] as String?;
    UrkUserRuntimeObservabilityThresholdAuditAction? action;
    if (actionName != null) {
      for (final value
          in UrkUserRuntimeObservabilityThresholdAuditAction.values) {
        if (value.name == actionName) {
          action = value;
          break;
        }
      }
    }
    if (action == null) {
      return null;
    }
    return UrkUserRuntimeObservabilityThresholdAuditEvent(
      timestamp: DateTime.tryParse(json['ts'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      actor: json['actor'] as String? ?? 'unknown_actor',
      action: action,
      window: _windowFromKey(json['window'] as String?),
      before: _entryFromJson(json['before']),
      after: _entryFromJson(json['after']),
      reason: json['reason'] as String?,
    );
  }
}

class UrkUserRuntimeObservabilityThresholdOverrideService {
  UrkUserRuntimeObservabilityThresholdOverrideService({
    required SharedPreferencesCompat prefs,
    UrkUserRuntimeObservabilityThresholdService baseService =
        const UrkUserRuntimeObservabilityThresholdService(),
  })  : _prefs = prefs,
        _baseService = baseService;

  static const String _overrideKey =
      'urk_user_runtime_observability_threshold_overrides_v1';
  static const String _auditKey =
      'urk_user_runtime_observability_threshold_audit_v1';
  static const int _maxAuditEvents = 200;

  final SharedPreferencesCompat _prefs;
  final UrkUserRuntimeObservabilityThresholdService _baseService;

  Future<UrkUserRuntimeObservabilityThresholds> loadEffective() async {
    final base = await _baseService.load();
    final overrides = _readOverrides();
    if (overrides.isEmpty) {
      return base;
    }
    return UrkUserRuntimeObservabilityThresholds(
      byWindow: <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{
        ...base.byWindow,
        ...overrides,
      },
      validation: base.validation,
    );
  }

  Future<void> upsertWindowOverride({
    required UrkUserRuntimeObservabilityWindow window,
    required UrkUserRuntimeObservabilityThresholdEntry entry,
    required String actor,
    String? reason,
  }) async {
    final effective = await loadEffective();
    final before = effective.forWindow(window);
    final overrides = _readOverrides();
    overrides[window] = entry;
    await _writeOverrides(overrides);
    await _appendAudit(
      UrkUserRuntimeObservabilityThresholdAuditEvent(
        timestamp: DateTime.now().toUtc(),
        actor: actor,
        action: UrkUserRuntimeObservabilityThresholdAuditAction.windowUpsert,
        window: window,
        before: before,
        after: entry,
        reason: reason,
      ),
    );
  }

  Future<void> clearOverrides({
    required String actor,
    String? reason,
  }) async {
    await _prefs.remove(_overrideKey);
    await _appendAudit(
      UrkUserRuntimeObservabilityThresholdAuditEvent(
        timestamp: DateTime.now().toUtc(),
        actor: actor,
        action:
            UrkUserRuntimeObservabilityThresholdAuditAction.overridesCleared,
        reason: reason,
      ),
    );
  }

  List<UrkUserRuntimeObservabilityThresholdAuditEvent> listRecentAudit({
    int limit = 10,
  }) {
    final raw = _prefs.getStringList(_auditKey) ?? const <String>[];
    final events = <UrkUserRuntimeObservabilityThresholdAuditEvent>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final event =
            UrkUserRuntimeObservabilityThresholdAuditEvent.fromJson(decoded);
        if (event != null) {
          events.add(event);
        }
      } catch (_) {
        // Best effort.
      }
    }
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (events.length <= limit) {
      return events;
    }
    return events.sublist(0, limit);
  }

  Map<UrkUserRuntimeObservabilityWindow,
      UrkUserRuntimeObservabilityThresholdEntry> _readOverrides() {
    final raw = _prefs.getString(_overrideKey);
    if (raw == null || raw.isEmpty) {
      return <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <UrkUserRuntimeObservabilityWindow,
            UrkUserRuntimeObservabilityThresholdEntry>{};
      }
      final windows = decoded['windows'];
      if (windows is! Map<String, dynamic>) {
        return <UrkUserRuntimeObservabilityWindow,
            UrkUserRuntimeObservabilityThresholdEntry>{};
      }
      final out = <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{};
      windows.forEach((key, value) {
        final window = _windowFromKey(key);
        final entry = _entryFromJson(value);
        if (window != null && entry != null) {
          out[window] = entry;
        }
      });
      return out;
    } catch (_) {
      return <UrkUserRuntimeObservabilityWindow,
          UrkUserRuntimeObservabilityThresholdEntry>{};
    }
  }

  Future<void> _writeOverrides(
    Map<UrkUserRuntimeObservabilityWindow,
            UrkUserRuntimeObservabilityThresholdEntry>
        overrides,
  ) async {
    final windows = <String, dynamic>{};
    overrides.forEach((window, entry) {
      windows[_windowKey(window)] = _entryToJson(entry);
    });
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'windows': windows,
    };
    await _prefs.setString(_overrideKey, jsonEncode(payload));
  }

  Future<void> _appendAudit(
    UrkUserRuntimeObservabilityThresholdAuditEvent event,
  ) async {
    final existing = _prefs.getStringList(_auditKey) ?? const <String>[];
    final next = <String>[...existing, jsonEncode(event.toJson())];
    final capped = next.length <= _maxAuditEvents
        ? next
        : next.sublist(next.length - _maxAuditEvents);
    await _prefs.setStringList(_auditKey, capped);
  }
}

String _windowKey(UrkUserRuntimeObservabilityWindow window) {
  switch (window) {
    case UrkUserRuntimeObservabilityWindow.last1h:
      return '1h';
    case UrkUserRuntimeObservabilityWindow.last6h:
      return '6h';
    case UrkUserRuntimeObservabilityWindow.last24h:
      return '24h';
    case UrkUserRuntimeObservabilityWindow.last7d:
      return '7d';
  }
}

UrkUserRuntimeObservabilityWindow? _windowFromKey(String? key) {
  switch (key) {
    case '1h':
      return UrkUserRuntimeObservabilityWindow.last1h;
    case '6h':
      return UrkUserRuntimeObservabilityWindow.last6h;
    case '24h':
      return UrkUserRuntimeObservabilityWindow.last24h;
    case '7d':
      return UrkUserRuntimeObservabilityWindow.last7d;
    default:
      return null;
  }
}

Map<String, dynamic> _entryToJson(
  UrkUserRuntimeObservabilityThresholdEntry entry,
) {
  return <String, dynamic>{
    'warn_opt_out_rate_pct': entry.warnOptOutRatePct,
    'critical_opt_out_rate_pct': entry.criticalOptOutRatePct,
    'warn_rejection_rate_pct': entry.warnRejectionRatePct,
    'critical_rejection_rate_pct': entry.criticalRejectionRatePct,
  };
}

UrkUserRuntimeObservabilityThresholdEntry? _entryFromJson(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }
  final warnOptOut = value['warn_opt_out_rate_pct'];
  final criticalOptOut = value['critical_opt_out_rate_pct'];
  final warnRejection = value['warn_rejection_rate_pct'];
  final criticalRejection = value['critical_rejection_rate_pct'];
  if (warnOptOut is! num ||
      criticalOptOut is! num ||
      warnRejection is! num ||
      criticalRejection is! num) {
    return null;
  }
  return UrkUserRuntimeObservabilityThresholdEntry(
    warnOptOutRatePct: warnOptOut.toDouble(),
    criticalOptOutRatePct: criticalOptOut.toDouble(),
    warnRejectionRatePct: warnRejection.toDouble(),
    criticalRejectionRatePct: criticalRejection.toDouble(),
  );
}
