import 'dart:convert';

import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class BackgroundWakeExecutionRunRecordStore {
  BackgroundWakeExecutionRunRecordStore({
    StorageService? storageService,
    DateTime Function()? nowUtc,
    List<BackgroundWakeExecutionRunRecord>? seededRecords,
  })  : _storageService = storageService,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _memoryRecords = List<BackgroundWakeExecutionRunRecord>.from(
          seededRecords ?? const <BackgroundWakeExecutionRunRecord>[],
        );

  static const String _storageKey = 'background_wake_execution_run_records_v1';
  static const int _maxStoredRecords = 48;

  final StorageService? _storageService;
  final DateTime Function() _nowUtc;
  final List<BackgroundWakeExecutionRunRecord> _memoryRecords;

  List<BackgroundWakeExecutionRunRecord> recentRecords({int limit = 8}) {
    final records = _readRecords();
    final normalizedLimit = limit.clamp(0, records.length);
    if (normalizedLimit == 0) {
      return const <BackgroundWakeExecutionRunRecord>[];
    }
    return records.take(normalizedLimit).toList(growable: false);
  }

  Future<void> record(BackgroundWakeExecutionRunRecord record) async {
    final records = _readRecords().toList(growable: true);
    records.insert(0, record);
    if (records.length > _maxStoredRecords) {
      records.removeRange(_maxStoredRecords, records.length);
    }
    _memoryRecords
      ..clear()
      ..addAll(records);
    final storage = _storageService;
    if (storage == null) {
      return;
    }
    try {
      await storage.setObject(
        _storageKey,
        records.map((entry) => entry.toJson()).toList(growable: false),
        box: 'spots_ai',
      );
    } on StateError {
      // Fall back to in-memory storage until StorageService is initialized.
    }
  }

  String exportRecentRuns({int limit = 8}) {
    final payload = <String, dynamic>{
      'exported_at_utc': _nowUtc().toIso8601String(),
      'runs': recentRecords(limit: limit)
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  List<BackgroundWakeExecutionRunRecord> _readRecords() {
    final storage = _storageService;
    if (storage != null) {
      try {
        final raw =
            storage.getObject<List<dynamic>>(_storageKey, box: 'spots_ai');
        if (raw != null) {
          return raw
              .whereType<Map>()
              .map(
                (entry) => BackgroundWakeExecutionRunRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false);
        }
      } on StateError {
        // Fall back to in-memory storage until StorageService is initialized.
      }
    }
    return List<BackgroundWakeExecutionRunRecord>.from(_memoryRecords);
  }
}
