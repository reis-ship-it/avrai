// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai/core/ai/knowledge_lifecycle/claim_lifecycle_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

enum ConvictionGateMode {
  shadow,
  enforce,
}

class ConvictionGateFeatureFlags {
  const ConvictionGateFeatureFlags._();

  static const String productionEnforcement =
      'conviction_gate_production_enforcement';
  static const String highImpactEnforcement =
      'conviction_gate_high_impact_enforcement';
}

class ConvictionGateRequest extends Equatable {
  const ConvictionGateRequest({
    required this.controllerName,
    required this.requestId,
    required this.claimState,
    required this.isHighImpact,
    required this.policyChecksPassed,
    this.subjectId,
  });

  final String controllerName;
  final String requestId;
  final ClaimLifecycleState claimState;
  final bool isHighImpact;
  final bool policyChecksPassed;
  final String? subjectId;

  @override
  List<Object?> get props => [
        controllerName,
        requestId,
        claimState,
        isHighImpact,
        policyChecksPassed,
        subjectId,
      ];
}

class ConvictionGateDecision extends Equatable {
  const ConvictionGateDecision({
    required this.mode,
    required this.requestId,
    required this.controllerName,
    required this.subjectId,
    required this.claimState,
    required this.isHighImpact,
    required this.policyChecksPassed,
    required this.wouldAllow,
    required this.servingAllowed,
    required this.shadowBypassApplied,
    required this.reasonCodes,
    required this.timestamp,
  });

  final ConvictionGateMode mode;
  final String requestId;
  final String controllerName;
  final String? subjectId;
  final ClaimLifecycleState claimState;
  final bool isHighImpact;
  final bool policyChecksPassed;
  final bool wouldAllow;
  final bool servingAllowed;
  final bool shadowBypassApplied;
  final List<String> reasonCodes;
  final DateTime timestamp;

  @override
  List<Object?> get props => [
        mode,
        requestId,
        controllerName,
        subjectId,
        claimState,
        isHighImpact,
        policyChecksPassed,
        wouldAllow,
        servingAllowed,
        shadowBypassApplied,
        reasonCodes,
        timestamp,
      ];
}

abstract class ConvictionGateTelemetrySink {
  Future<void> record(ConvictionGateDecision decision);
}

typedef ConvictionGateModeResolver = Future<ConvictionGateMode> Function(
  ConvictionGateRequest request,
);

abstract class ConvictionGateTelemetryStore {
  String? getString(String key);
  Future<bool> setString(String key, String value);
}

class SharedPreferencesConvictionGateTelemetryStore
    implements ConvictionGateTelemetryStore {
  SharedPreferencesConvictionGateTelemetryStore(this._prefs);

  final SharedPreferencesCompat _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
}

class SharedPrefsConvictionGateTelemetrySink
    implements ConvictionGateTelemetrySink {
  SharedPrefsConvictionGateTelemetrySink({
    required ConvictionGateTelemetryStore store,
    this.storageKey = _defaultStorageKey,
    this.maxEvents = 500,
    this.runtimeExportPath = _defaultRuntimeExportPath,
  }) : _store = store;

  static const String _defaultStorageKey =
      'conviction_gate_shadow_decisions_v1';
  static const String _defaultRuntimeExportPath =
      'runtime_exports/conviction_gate_shadow_decisions.json';

  final ConvictionGateTelemetryStore _store;
  final String storageKey;
  final int maxEvents;
  final String runtimeExportPath;

  @override
  Future<void> record(ConvictionGateDecision decision) async {
    final entries = _readEntries();
    entries.add(_toJson(decision));
    if (entries.length > maxEvents) {
      entries.removeRange(0, entries.length - maxEvents);
    }
    await _store.setString(storageKey, jsonEncode(entries));
    _tryWriteRuntimeExport(entries);
  }

  List<Map<String, dynamic>> _readEntries() {
    final encoded = _store.getString(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => entry.map((k, v) => MapEntry('$k', v)))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Map<String, dynamic> _toJson(ConvictionGateDecision decision) {
    return <String, dynamic>{
      'mode': decision.mode.name,
      'requestId': decision.requestId,
      'controllerName': decision.controllerName,
      'subjectId': decision.subjectId,
      'claimState': decision.claimState.name,
      'isHighImpact': decision.isHighImpact,
      'policyChecksPassed': decision.policyChecksPassed,
      'wouldAllow': decision.wouldAllow,
      'servingAllowed': decision.servingAllowed,
      'shadowBypassApplied': decision.shadowBypassApplied,
      'reasonCodes': decision.reasonCodes,
      'timestamp': decision.timestamp.toIso8601String(),
    };
  }

  void _tryWriteRuntimeExport(List<Map<String, dynamic>> entries) {
    try {
      final file = File(runtimeExportPath)..createSync(recursive: true);
      file.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(entries)}\n');
    } catch (_) {
      // Best-effort mirror export only; storage persistence remains source of truth.
    }
  }
}

ConvictionGateTelemetrySink? resolveDefaultConvictionGateTelemetrySink() {
  final sl = GetIt.instance;

  if (sl.isRegistered<ConvictionGateTelemetrySink>()) {
    return sl<ConvictionGateTelemetrySink>();
  }

  if (sl.isRegistered<SharedPreferencesCompat>()) {
    final prefs = sl<SharedPreferencesCompat>();
    return SharedPrefsConvictionGateTelemetrySink(
      store: SharedPreferencesConvictionGateTelemetryStore(prefs),
    );
  }

  return null;
}

ConvictionGateModeResolver? resolveDefaultConvictionGateModeResolver() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<FeatureFlagService>()) {
    return null;
  }

  final featureFlags = sl<FeatureFlagService>();
  return (request) async {
    final productionEnabled = await featureFlags.isEnabled(
      ConvictionGateFeatureFlags.productionEnforcement,
      userId: request.subjectId,
      defaultValue: false,
    );
    if (!productionEnabled) {
      return ConvictionGateMode.shadow;
    }

    if (!request.isHighImpact) {
      return ConvictionGateMode.shadow;
    }

    final highImpactEnabled = await featureFlags.isEnabled(
      ConvictionGateFeatureFlags.highImpactEnforcement,
      userId: request.subjectId,
      defaultValue: false,
    );
    return highImpactEnabled
        ? ConvictionGateMode.enforce
        : ConvictionGateMode.shadow;
  };
}

ConvictionGateEvaluator resolveDefaultConvictionGateEvaluator() {
  return ConvictionGateEvaluator(
    mode: ConvictionGateMode.shadow,
    modeResolver: resolveDefaultConvictionGateModeResolver(),
    telemetrySink: resolveDefaultConvictionGateTelemetrySink(),
    urkActivationDispatcher: resolveDefaultUrkRuntimeActivationDispatcher(),
  );
}

class InMemoryConvictionGateTelemetrySink
    implements ConvictionGateTelemetrySink {
  final List<ConvictionGateDecision> events = <ConvictionGateDecision>[];

  @override
  Future<void> record(ConvictionGateDecision decision) async {
    events.add(decision);
  }
}

class ConvictionGateEvaluator {
  ConvictionGateEvaluator({
    this.mode = ConvictionGateMode.shadow,
    ConvictionGateModeResolver? modeResolver,
    ConvictionGateTelemetrySink? telemetrySink,
    UrkRuntimeActivationReceiptDispatcher? urkActivationDispatcher,
    DateTime Function()? now,
  })  : _telemetrySink = telemetrySink,
        _modeResolver = modeResolver,
        _urkActivationDispatcher = urkActivationDispatcher,
        _now = now ?? DateTime.now;

  final ConvictionGateMode mode;
  final ConvictionGateModeResolver? _modeResolver;
  final ConvictionGateTelemetrySink? _telemetrySink;
  final UrkRuntimeActivationReceiptDispatcher? _urkActivationDispatcher;
  final DateTime Function() _now;

  Future<ConvictionGateDecision> evaluate(ConvictionGateRequest request) async {
    final reasonCodes = <String>[];
    final hasRequiredConviction =
        request.claimState == ClaimLifecycleState.canonical;

    if (request.isHighImpact && !hasRequiredConviction) {
      reasonCodes.add('high_impact_requires_canonical_conviction');
    }

    if (!request.policyChecksPassed) {
      reasonCodes.add('policy_checks_failed');
    }

    final modeResolver = _modeResolver;
    final effectiveMode =
        modeResolver != null ? await modeResolver(request) : mode;
    final wouldAllow = reasonCodes.isEmpty;
    final servingAllowed =
        effectiveMode == ConvictionGateMode.shadow ? true : wouldAllow;
    final shadowBypassApplied =
        effectiveMode == ConvictionGateMode.shadow && !wouldAllow;

    final decision = ConvictionGateDecision(
      mode: effectiveMode,
      requestId: request.requestId,
      controllerName: request.controllerName,
      subjectId: request.subjectId,
      claimState: request.claimState,
      isHighImpact: request.isHighImpact,
      policyChecksPassed: request.policyChecksPassed,
      wouldAllow: wouldAllow,
      servingAllowed: servingAllowed,
      shadowBypassApplied: shadowBypassApplied,
      reasonCodes: List<String>.unmodifiable(reasonCodes),
      timestamp: _now(),
    );

    if (_telemetrySink != null) {
      await _telemetrySink.record(decision);
    }
    if (_urkActivationDispatcher != null) {
      final trigger = _mapDecisionToUrkTrigger(decision);
      if (trigger != null) {
        await _urkActivationDispatcher.dispatch(
          requestId: decision.requestId,
          trigger: trigger,
          privacyMode: UrkPrivacyMode.multiMode,
          actor: decision.controllerName,
          reason: decision.reasonCodes.isEmpty
              ? 'conviction_gate_decision'
              : decision.reasonCodes.join(','),
        );
      }
    }

    return decision;
  }

  String? _mapDecisionToUrkTrigger(ConvictionGateDecision decision) {
    if (!decision.policyChecksPassed) {
      return 'policy_violation_detected';
    }
    if (decision.isHighImpact && !decision.wouldAllow) {
      return 'runtime_health_breach';
    }
    if (decision.isHighImpact && decision.wouldAllow) {
      return 'release_candidate_validation';
    }
    return null;
  }
}
