import 'dart:convert';

import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

enum UrkKernelRuntimeState {
  active,
  shadow,
  paused,
  disabled,
}

enum UrkKernelHealthStatus {
  healthy,
  degraded,
  offline,
}

class UrkKernelRuntimeStateSnapshot {
  const UrkKernelRuntimeStateSnapshot({
    required this.kernelId,
    required this.state,
    required this.updatedAt,
    required this.updatedBy,
    required this.reason,
  });

  final String kernelId;
  final UrkKernelRuntimeState state;
  final DateTime updatedAt;
  final String updatedBy;
  final String reason;
}

class UrkKernelHealthSnapshot {
  const UrkKernelHealthSnapshot({
    required this.kernelId,
    required this.status,
    required this.scorePct,
    required this.checkedAt,
  });

  final String kernelId;
  final UrkKernelHealthStatus status;
  final double scorePct;
  final DateTime checkedAt;
}

class UrkKernelLineageEvent {
  const UrkKernelLineageEvent({
    required this.kernelId,
    required this.eventType,
    required this.actor,
    required this.reason,
    required this.timestamp,
    this.fromState,
    this.toState,
    this.requestId,
  });

  final String kernelId;
  final String eventType;
  final String actor;
  final String reason;
  final DateTime timestamp;
  final UrkKernelRuntimeState? fromState;
  final UrkKernelRuntimeState? toState;
  final String? requestId;
}

class UrkKernelControlPlaneRecord {
  const UrkKernelControlPlaneRecord({
    required this.kernel,
    required this.state,
    required this.health,
    required this.lineageEventCount,
  });

  final UrkKernelRecord kernel;
  final UrkKernelRuntimeStateSnapshot state;
  final UrkKernelHealthSnapshot health;
  final int lineageEventCount;
}

class UrkRuntimeObservabilityBucket {
  const UrkRuntimeObservabilityBucket({
    required this.runtimeLane,
    required this.privacyMode,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.optOutCount,
  });

  final String runtimeLane;
  final String privacyMode;
  final int acceptedCount;
  final int rejectedCount;
  final int optOutCount;

  int get totalCount => acceptedCount + rejectedCount;

  double get acceptanceRatePct {
    if (totalCount == 0) {
      return 0;
    }
    return (acceptedCount / totalCount) * 100.0;
  }

  double get optOutRatePct {
    if (totalCount == 0) {
      return 0;
    }
    return (optOutCount / totalCount) * 100.0;
  }
}

class UrkUserRuntimeLearningObservabilitySummary {
  const UrkUserRuntimeLearningObservabilitySummary({
    required this.totalAccepted,
    required this.totalRejected,
    required this.totalOptOut,
    required this.buckets,
  });

  final int totalAccepted;
  final int totalRejected;
  final int totalOptOut;
  final List<UrkRuntimeObservabilityBucket> buckets;

  int get totalEvents => totalAccepted + totalRejected;

  double get acceptanceRatePct {
    if (totalEvents == 0) {
      return 0;
    }
    return (totalAccepted / totalEvents) * 100.0;
  }

  double get optOutRatePct {
    if (totalEvents == 0) {
      return 0;
    }
    return (totalOptOut / totalEvents) * 100.0;
  }
}

class UrkKernelControlPlaneService {
  UrkKernelControlPlaneService({
    required SharedPreferencesCompat prefs,
    UrkKernelRegistryService registryService = const UrkKernelRegistryService(),
  })  : _prefs = prefs,
        _registryService = registryService;

  static const String _stateKey = 'urk_kernel_control_plane_state_v1';
  static const String _lineageKey = 'urk_kernel_control_plane_lineage_v1';

  final SharedPreferencesCompat _prefs;
  final UrkKernelRegistryService _registryService;

  Future<List<UrkKernelControlPlaneRecord>> listKernels() async {
    final snapshot = await _registryService.loadSnapshot();
    final states = await _readStateMap();
    final lineage = await _readLineage();
    final lineageCount = <String, int>{};
    for (final event in lineage) {
      lineageCount[event.kernelId] = (lineageCount[event.kernelId] ?? 0) + 1;
    }

    final now = DateTime.now().toUtc();
    return snapshot.kernels.map((kernel) {
      final state = states[kernel.kernelId] ?? _defaultStateForKernel(kernel);
      final health =
          _healthForState(kernelId: kernel.kernelId, state: state, now: now);
      return UrkKernelControlPlaneRecord(
        kernel: kernel,
        state: state,
        health: health,
        lineageEventCount: lineageCount[kernel.kernelId] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.kernel.kernelId.compareTo(b.kernel.kernelId));
  }

  Future<UrkKernelRuntimeStateSnapshot> getKernelState(String kernelId) async {
    final snapshot = await _registryService.loadSnapshot();
    final kernel =
        snapshot.kernels.where((k) => k.kernelId == kernelId).firstOrNull;
    if (kernel == null) {
      throw StateError('Unknown kernel id: $kernelId');
    }
    final states = await _readStateMap();
    return states[kernelId] ?? _defaultStateForKernel(kernel);
  }

  Future<UrkKernelHealthSnapshot> getKernelHealth(String kernelId) async {
    final state = await getKernelState(kernelId);
    return _healthForState(
      kernelId: kernelId,
      state: state,
      now: DateTime.now().toUtc(),
    );
  }

  Future<List<UrkKernelLineageEvent>> getKernelLineage(
    String kernelId, {
    int limit = 25,
  }) async {
    final lineage = await _readLineage();
    final filtered = lineage
        .where((event) => event.kernelId == kernelId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.sublist(0, limit);
  }

  Future<void> setKernelState({
    required String kernelId,
    required UrkKernelRuntimeState desiredState,
    required String actor,
    required String reason,
  }) async {
    final snapshot = await _registryService.loadSnapshot();
    final kernel =
        snapshot.kernels.where((k) => k.kernelId == kernelId).firstOrNull;
    if (kernel == null) {
      throw StateError('Unknown kernel id: $kernelId');
    }

    final stateMap = await _readStateMap();
    final current = stateMap[kernelId] ?? _defaultStateForKernel(kernel);
    if (!_isValidTransition(from: current.state, to: desiredState)) {
      throw StateError(
        'Invalid transition ${current.state.name} -> ${desiredState.name} for $kernelId',
      );
    }

    final updated = UrkKernelRuntimeStateSnapshot(
      kernelId: kernelId,
      state: desiredState,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: actor,
      reason: reason,
    );
    stateMap[kernelId] = updated;
    await _writeStateMap(stateMap);

    final lineage = await _readLineage();
    lineage.add(
      UrkKernelLineageEvent(
        kernelId: kernelId,
        eventType: 'state_change',
        actor: actor,
        reason: reason,
        timestamp: updated.updatedAt,
        fromState: current.state,
        toState: desiredState,
      ),
    );
    await _writeLineage(lineage);

    await UrkRuntimeActivationReceiptDispatcher(
      controlPlaneService: this,
      registryService: _registryService,
    ).dispatch(
      requestId:
          'admin_state_${kernelId}_${updated.updatedAt.millisecondsSinceEpoch}',
      trigger: 'admin_control_plane_state_change',
      privacyMode: UrkPrivacyMode.multiMode,
      actor: actor,
      reason: 'kernel_state_change:${current.state.name}->${desiredState.name}',
    );
  }

  Future<void> recordActivationReceipt({
    required String kernelId,
    required String requestId,
    required String actor,
    required String reason,
  }) async {
    final lineage = await _readLineage();
    lineage.add(
      UrkKernelLineageEvent(
        kernelId: kernelId,
        eventType: 'activation_receipt',
        actor: actor,
        reason: reason,
        timestamp: DateTime.now().toUtc(),
        requestId: requestId,
      ),
    );
    await _writeLineage(lineage);
  }

  Future<UrkUserRuntimeLearningObservabilitySummary>
      summarizeUserRuntimeLearning({
    Duration? window,
  }) async {
    final now = DateTime.now().toUtc();
    final lineage = await _readLineage();
    final threshold = window == null ? null : now.subtract(window);
    final buckets = <String, _MutableRuntimeBucket>{};
    var totalAccepted = 0;
    var totalRejected = 0;
    var totalOptOut = 0;

    for (final event in lineage) {
      if (event.eventType != 'activation_receipt') {
        continue;
      }
      if (threshold != null && event.timestamp.isBefore(threshold)) {
        continue;
      }
      final reason = event.reason;
      final isAccepted =
          reason.contains('user_runtime_learning_intake_accepted');
      final isRejected =
          reason.contains('user_runtime_learning_intake_rejected');
      if (!isAccepted && !isRejected) {
        continue;
      }

      final metadata = _parseReasonMetadata(reason);
      final runtimeLane = metadata['runtime_lane'] ?? 'user_runtime';
      final privacyMode = metadata['privacy_mode'] ?? 'local_sovereign';
      final key = '$runtimeLane|$privacyMode';
      final bucket = buckets.putIfAbsent(
        key,
        () => _MutableRuntimeBucket(
          runtimeLane: runtimeLane,
          privacyMode: privacyMode,
        ),
      );

      if (isAccepted) {
        totalAccepted += 1;
        bucket.accepted += 1;
      } else {
        totalRejected += 1;
        bucket.rejected += 1;
        final isOptOut = (metadata['reason_code'] ?? '')
                .contains('missing_user_runtime_learning_consent') ||
            reason.contains('missing_user_runtime_learning_consent');
        if (isOptOut) {
          totalOptOut += 1;
          bucket.optOut += 1;
        }
      }
    }

    final sortedBuckets = buckets.values
        .map(
          (bucket) => UrkRuntimeObservabilityBucket(
            runtimeLane: bucket.runtimeLane,
            privacyMode: bucket.privacyMode,
            acceptedCount: bucket.accepted,
            rejectedCount: bucket.rejected,
            optOutCount: bucket.optOut,
          ),
        )
        .toList()
      ..sort((a, b) {
        final runtimeCmp = a.runtimeLane.compareTo(b.runtimeLane);
        if (runtimeCmp != 0) {
          return runtimeCmp;
        }
        return a.privacyMode.compareTo(b.privacyMode);
      });

    return UrkUserRuntimeLearningObservabilitySummary(
      totalAccepted: totalAccepted,
      totalRejected: totalRejected,
      totalOptOut: totalOptOut,
      buckets: sortedBuckets,
    );
  }

  Map<String, String> _parseReasonMetadata(String reason) {
    final metadata = <String, String>{};
    final reasonSansActivationSuffix = reason.split(':').first;
    for (final part in reasonSansActivationSuffix.split(';')) {
      final idx = part.indexOf('=');
      if (idx <= 0 || idx >= part.length - 1) {
        continue;
      }
      final key = part.substring(0, idx).trim();
      final value = part.substring(idx + 1).trim();
      if (key.isEmpty || value.isEmpty) {
        continue;
      }
      metadata[key] = value;
    }
    return metadata;
  }

  bool _isValidTransition({
    required UrkKernelRuntimeState from,
    required UrkKernelRuntimeState to,
  }) {
    if (from == to) {
      return true;
    }
    switch (from) {
      case UrkKernelRuntimeState.active:
        return to == UrkKernelRuntimeState.shadow ||
            to == UrkKernelRuntimeState.paused ||
            to == UrkKernelRuntimeState.disabled;
      case UrkKernelRuntimeState.shadow:
        return to == UrkKernelRuntimeState.active ||
            to == UrkKernelRuntimeState.paused ||
            to == UrkKernelRuntimeState.disabled;
      case UrkKernelRuntimeState.paused:
        return to == UrkKernelRuntimeState.shadow ||
            to == UrkKernelRuntimeState.active ||
            to == UrkKernelRuntimeState.disabled;
      case UrkKernelRuntimeState.disabled:
        return to == UrkKernelRuntimeState.paused ||
            to == UrkKernelRuntimeState.shadow;
    }
  }

  UrkKernelRuntimeStateSnapshot _defaultStateForKernel(UrkKernelRecord kernel) {
    final state = switch (kernel.lifecycleState) {
      'draft' => UrkKernelRuntimeState.paused,
      'shadow' => UrkKernelRuntimeState.shadow,
      'enforced' => UrkKernelRuntimeState.active,
      'replicated' => UrkKernelRuntimeState.active,
      _ => UrkKernelRuntimeState.paused,
    };
    return UrkKernelRuntimeStateSnapshot(
      kernelId: kernel.kernelId,
      state: state,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: 'registry_bootstrap',
      reason: 'default_from_registry',
    );
  }

  UrkKernelHealthSnapshot _healthForState({
    required String kernelId,
    required UrkKernelRuntimeStateSnapshot state,
    required DateTime now,
  }) {
    final (status, score) = switch (state.state) {
      UrkKernelRuntimeState.active => (UrkKernelHealthStatus.healthy, 99.0),
      UrkKernelRuntimeState.shadow => (UrkKernelHealthStatus.healthy, 95.0),
      UrkKernelRuntimeState.paused => (UrkKernelHealthStatus.degraded, 70.0),
      UrkKernelRuntimeState.disabled => (UrkKernelHealthStatus.offline, 40.0),
    };
    return UrkKernelHealthSnapshot(
      kernelId: kernelId,
      status: status,
      scorePct: score,
      checkedAt: now,
    );
  }

  Future<Map<String, UrkKernelRuntimeStateSnapshot>> _readStateMap() async {
    final raw = _prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      return <String, UrkKernelRuntimeStateSnapshot>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, UrkKernelRuntimeStateSnapshot>{};
    decoded.forEach((kernelId, value) {
      final item = value as Map<String, dynamic>;
      out[kernelId] = UrkKernelRuntimeStateSnapshot(
        kernelId: kernelId,
        state: _stateFromString(item['state'] as String?),
        updatedAt: DateTime.parse(item['updated_at'] as String),
        updatedBy: item['updated_by'] as String? ?? 'unknown',
        reason: item['reason'] as String? ?? 'none',
      );
    });
    return out;
  }

  Future<void> _writeStateMap(
    Map<String, UrkKernelRuntimeStateSnapshot> stateMap,
  ) async {
    final jsonMap = <String, dynamic>{};
    stateMap.forEach((kernelId, state) {
      jsonMap[kernelId] = {
        'state': state.state.name,
        'updated_at': state.updatedAt.toUtc().toIso8601String(),
        'updated_by': state.updatedBy,
        'reason': state.reason,
      };
    });
    await _prefs.setString(_stateKey, jsonEncode(jsonMap));
  }

  Future<List<UrkKernelLineageEvent>> _readLineage() async {
    final raw = _prefs.getString(_lineageKey);
    if (raw == null || raw.isEmpty) {
      return <UrkKernelLineageEvent>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((row) {
      final item = row as Map<String, dynamic>;
      return UrkKernelLineageEvent(
        kernelId: item['kernel_id'] as String,
        eventType: item['event_type'] as String,
        actor: item['actor'] as String,
        reason: item['reason'] as String,
        timestamp: DateTime.parse(item['timestamp'] as String),
        fromState: item['from_state'] == null
            ? null
            : _stateFromString(item['from_state'] as String),
        toState: item['to_state'] == null
            ? null
            : _stateFromString(item['to_state'] as String),
        requestId: item['request_id'] as String?,
      );
    }).toList();
  }

  Future<void> _writeLineage(List<UrkKernelLineageEvent> lineage) async {
    final encoded = lineage
        .map(
          (event) => {
            'kernel_id': event.kernelId,
            'event_type': event.eventType,
            'actor': event.actor,
            'reason': event.reason,
            'timestamp': event.timestamp.toUtc().toIso8601String(),
            'from_state': event.fromState?.name,
            'to_state': event.toState?.name,
            'request_id': event.requestId,
          },
        )
        .toList(growable: false);
    await _prefs.setString(_lineageKey, jsonEncode(encoded));
  }

  UrkKernelRuntimeState _stateFromString(String? value) {
    switch (value) {
      case 'active':
        return UrkKernelRuntimeState.active;
      case 'shadow':
        return UrkKernelRuntimeState.shadow;
      case 'paused':
        return UrkKernelRuntimeState.paused;
      case 'disabled':
        return UrkKernelRuntimeState.disabled;
      default:
        return UrkKernelRuntimeState.paused;
    }
  }
}

class _MutableRuntimeBucket {
  _MutableRuntimeBucket({
    required this.runtimeLane,
    required this.privacyMode,
  });

  final String runtimeLane;
  final String privacyMode;
  int accepted = 0;
  int rejected = 0;
  int optOut = 0;
}
