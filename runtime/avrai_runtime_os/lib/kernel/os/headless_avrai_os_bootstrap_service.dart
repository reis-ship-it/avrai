import 'dart:async';
import 'dart:convert';

import 'package:avrai_core/services/logger.dart';

import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class HeadlessAvraiOsBootstrapSnapshot {
  const HeadlessAvraiOsBootstrapSnapshot({
    required this.state,
    required this.healthReports,
    required this.startedAtUtc,
    this.restoredFromPersistence = false,
  });

  final HeadlessAvraiOsHostState state;
  final List<KernelHealthReport> healthReports;
  final DateTime startedAtUtc;
  final bool restoredFromPersistence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'state': state.toJson(),
        'health_reports': healthReports.map((entry) => entry.toJson()).toList(),
        'started_at_utc': startedAtUtc.toUtc().toIso8601String(),
        'restored_from_persistence': restoredFromPersistence,
      };

  factory HeadlessAvraiOsBootstrapSnapshot.fromJson(Map<String, dynamic> json) {
    final rawHealthReports =
        json['health_reports'] as List? ?? const <dynamic>[];
    return HeadlessAvraiOsBootstrapSnapshot(
      state: HeadlessAvraiOsHostState.fromJson(
        Map<String, dynamic>.from(
          json['state'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      healthReports: rawHealthReports
          .whereType<Map>()
          .map((entry) => KernelHealthReport.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList(),
      startedAtUtc:
          DateTime.tryParse(json['started_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      restoredFromPersistence:
          json['restored_from_persistence'] as bool? ?? false,
    );
  }
}

class HeadlessAvraiOsBootstrapService {
  HeadlessAvraiOsBootstrapService({
    required HeadlessAvraiOsHost host,
    SharedPreferencesCompat? prefs,
    AppLogger? logger,
  })  : _host = host,
        _prefs = prefs,
        _logger = logger ??
            const AppLogger(
              defaultTag: 'HeadlessAvraiOsBootstrap',
              minimumLevel: LogLevel.debug,
            );

  static const String _snapshotStorageKey =
      'headless_avrai_os_bootstrap_snapshot_v1';

  final HeadlessAvraiOsHost _host;
  final SharedPreferencesCompat? _prefs;
  final AppLogger _logger;
  final StreamController<HeadlessAvraiOsBootstrapSnapshot?>
      _snapshotController =
      StreamController<HeadlessAvraiOsBootstrapSnapshot?>.broadcast();

  HeadlessAvraiOsBootstrapSnapshot? _snapshot;
  HeadlessAvraiOsBootstrapSnapshot? _restoredSnapshot;
  Object? _lastError;

  HeadlessAvraiOsBootstrapSnapshot? get snapshot =>
      _snapshot ?? _restoredSnapshot;
  HeadlessAvraiOsBootstrapSnapshot? get liveSnapshot => _snapshot;
  HeadlessAvraiOsBootstrapSnapshot? get restoredSnapshot =>
      _restoredSnapshot?.restoredFromPersistence == true
          ? _restoredSnapshot
          : null;
  Stream<HeadlessAvraiOsBootstrapSnapshot?> get snapshotStream =>
      _snapshotController.stream;
  Object? get lastError => _lastError;
  bool get isInitialized => snapshot != null;

  Future<HeadlessAvraiOsBootstrapSnapshot> initialize() async {
    if (_snapshot != null) {
      return _snapshot!;
    }

    _logger.info('🚀 Starting headless AVRAI OS bootstrap');
    final state = await _host.start();
    final healthReports = await _host.healthCheck();
    final snapshot = HeadlessAvraiOsBootstrapSnapshot(
      state: state,
      healthReports: healthReports,
      startedAtUtc: DateTime.now().toUtc(),
    );
    _snapshot = snapshot;
    if (_restoredSnapshot == null ||
        _restoredSnapshot!.restoredFromPersistence == false) {
      _restoredSnapshot = snapshot;
    }
    _lastError = null;
    await _persistSnapshot(snapshot);
    _emitSnapshot();
    _logger.info(
      '✅ Headless AVRAI OS bootstrap ready '
      '(kernels=${healthReports.length}, localityInWhere=${state.localityContainedInWhere})',
    );
    return snapshot;
  }

  Future<HeadlessAvraiOsBootstrapSnapshot?> tryInitialize() async {
    try {
      return await initialize();
    } catch (error, stackTrace) {
      _lastError = error;
      _logger.warning(
        '⚠️ Headless AVRAI OS bootstrap failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<HeadlessAvraiOsBootstrapSnapshot?> restorePersistedSnapshot() async {
    if (_snapshot != null) {
      return _snapshot;
    }
    if (_restoredSnapshot != null) {
      return _restoredSnapshot;
    }
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return null;
    }
    final raw = prefs.getString(_snapshotStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final restored = HeadlessAvraiOsBootstrapSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _restoredSnapshot = HeadlessAvraiOsBootstrapSnapshot(
        state: restored.state,
        healthReports: restored.healthReports,
        startedAtUtc: restored.startedAtUtc,
        restoredFromPersistence: true,
      );
      _logger.info(
        '♻️ Restored persisted headless AVRAI OS bootstrap snapshot '
        '(kernels=${_restoredSnapshot!.healthReports.length})',
      );
      _emitSnapshot();
      return _restoredSnapshot;
    } catch (error, stackTrace) {
      _lastError = error;
      _logger.warning(
        '⚠️ Failed to restore persisted headless AVRAI OS bootstrap snapshot',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clearPersistedSnapshot() async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return;
    }
    await prefs.remove(_snapshotStorageKey);
    _snapshot = null;
    _restoredSnapshot = null;
    _emitSnapshot();
  }

  Future<void> _persistSnapshot(
    HeadlessAvraiOsBootstrapSnapshot snapshot,
  ) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return;
    }
    await prefs.setString(_snapshotStorageKey, jsonEncode(snapshot.toJson()));
  }

  Future<SharedPreferencesCompat?> _resolvePrefs() async {
    if (_prefs != null) {
      return _prefs;
    }
    try {
      return await SharedPreferencesCompat.getInstance();
    } catch (_) {
      return null;
    }
  }

  void _emitSnapshot() {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }
}
