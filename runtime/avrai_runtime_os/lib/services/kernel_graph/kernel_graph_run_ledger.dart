import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Local-first persistence for compiled KernelGraph execution receipts and
/// admin digests so operator surfaces can inspect recent runtime flows.
class KernelGraphRunLedger {
  KernelGraphRunLedger({StorageService? storageService})
      : _storage = storageService;

  static const String _logName = 'KernelGraphRunLedger';
  static const String _storageKey = 'kernel_graph:runs_v1';
  static const String _storageBox = 'spots_ai';

  final StorageService? _storage;
  final Map<String, KernelGraphRunRecord> _runs =
      <String, KernelGraphRunRecord>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  bool _hydrated = false;

  Future<void> recordRun(KernelGraphRunRecord run) async {
    await _hydrateIfNeeded();
    _runs[run.runId] = run;
    await _persistRuns();
    _changes.add(null);
  }

  Future<KernelGraphRunRecord?> getRun(String runId) async {
    await _hydrateIfNeeded();
    return _runs[runId];
  }

  Future<List<KernelGraphRunRecord>> listRuns({
    KernelGraphKind? kind,
    KernelGraphRunStatus? status,
    String? sourceId,
    int? limit,
  }) async {
    await _hydrateIfNeeded();
    final runs = _runs.values.where((run) {
      if (kind != null && run.kind != kind) {
        return false;
      }
      if (status != null && run.status != status) {
        return false;
      }
      if (sourceId != null && run.sourceId != sourceId) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    if (limit == null || limit >= runs.length) {
      return runs;
    }
    return runs.take(limit).toList(growable: false);
  }

  Stream<List<KernelGraphRunRecord>> watchRuns({
    KernelGraphKind? kind,
    KernelGraphRunStatus? status,
    String? sourceId,
    int? limit,
  }) async* {
    await _hydrateIfNeeded();
    yield await listRuns(
      kind: kind,
      status: status,
      sourceId: sourceId,
      limit: limit,
    );
    yield* _changes.stream.asyncMap((_) {
      return listRuns(
        kind: kind,
        status: status,
        sourceId: sourceId,
        limit: limit,
      );
    });
  }

  Future<void> _hydrateIfNeeded() async {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    if (_storage == null) {
      return;
    }

    try {
      final rawRuns =
          _storage.getObject<List<dynamic>>(_storageKey, box: _storageBox) ??
              const <dynamic>[];
      for (final item in rawRuns) {
        if (item is Map<String, dynamic>) {
          final run = KernelGraphRunRecord.fromJson(item);
          _runs[run.runId] = run;
        } else if (item is Map) {
          final run = KernelGraphRunRecord.fromJson(
            Map<String, dynamic>.from(item),
          );
          _runs[run.runId] = run;
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to hydrate KernelGraph run ledger: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistRuns() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    final serialized = _runs.values.toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    await storage.setObject(
      _storageKey,
      serialized.map((run) => run.toJson()).toList(growable: false),
      box: _storageBox,
    );
  }
}
