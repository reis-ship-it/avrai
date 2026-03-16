import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:ffi/ffi.dart';

typedef _NativeInvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFreeJsonString = Void Function(Pointer<Utf8>);
typedef _FreeJsonString = void Function(Pointer<Utf8>);

const bool _isTrajectoryKernelFlutterTest =
    bool.fromEnvironment('FLUTTER_TEST');
const bool _isTrajectoryKernelSimulatedSmoke =
    String.fromEnvironment('SIMULATED_SMOKE_PLATFORM') != '';

abstract class TrajectoryKernelLibraryManager {
  DynamicLibrary getKernelLibrary();
}

class DefaultTrajectoryKernelLibraryManager
    implements TrajectoryKernelLibraryManager {
  @override
  DynamicLibrary getKernelLibrary() {
    final candidates = _candidatePaths();
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return DynamicLibrary.open(candidate);
      }
    }
    throw StateError(
      'Trajectory kernel library not found in expected locations: '
      '${candidates.join(', ')}',
    );
  }

  List<String> _candidatePaths() {
    final roots = <String>{};
    var cursor = Directory.current.absolute;
    for (var depth = 0; depth < 6; depth++) {
      roots.add(cursor.path);
      final parent = cursor.parent;
      if (parent.path == cursor.path) {
        break;
      }
      cursor = parent;
    }

    final candidates = <String>[];
    for (final root in roots) {
      candidates.addAll(<String>[
        '$root/runtime/avrai_network/native/trajectory_kernel/target/debug/libavrai_trajectory_kernel.dylib',
        '$root/runtime/avrai_network/native/trajectory_kernel/target/release/libavrai_trajectory_kernel.dylib',
        '$root/runtime/avrai_network/native/trajectory_kernel/macos/libavrai_trajectory_kernel.dylib',
        '$root/runtime/avrai_network/native/trajectory_kernel/target/debug/libavrai_trajectory_kernel.so',
        '$root/runtime/avrai_network/native/trajectory_kernel/target/release/libavrai_trajectory_kernel.so',
      ]);
    }
    return candidates.toSet().toList(growable: false);
  }
}

class TrajectoryKernelJsonNativeBridge {
  TrajectoryKernelJsonNativeBridge({
    TrajectoryKernelLibraryManager? libraryManager,
  }) : _libraryManager =
            libraryManager ?? DefaultTrajectoryKernelLibraryManager();

  final TrajectoryKernelLibraryManager _libraryManager;

  DynamicLibrary? _lib;
  _InvokeJson? _invokeJson;
  _FreeJsonString? _freeJsonString;
  bool _attemptedInitialization = false;
  bool _available = false;

  bool get isAvailable => _available;

  void initialize() {
    if (_attemptedInitialization) {
      return;
    }
    _attemptedInitialization = true;
    try {
      if (Platform.isIOS) {
        try {
          _lib = DynamicLibrary.open(
            'AVRAITrajectoryKernel.framework/AVRAITrajectoryKernel',
          );
        } catch (_) {
          _lib = DynamicLibrary.process();
        }
      } else if (Platform.isAndroid || Platform.isLinux) {
        _lib = DynamicLibrary.open('libavrai_trajectory_kernel.so');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('avrai_trajectory_kernel.dll');
      } else {
        _lib = _libraryManager.getKernelLibrary();
      }
      _invokeJson = _lib!
          .lookup<NativeFunction<_NativeInvokeJson>>(
            'avrai_trajectory_kernel_invoke_json',
          )
          .asFunction<_InvokeJson>();
      _freeJsonString = _lib!
          .lookup<NativeFunction<_NativeFreeJsonString>>(
            'avrai_trajectory_kernel_free_string',
          )
          .asFunction<_FreeJsonString>();
      _available = true;
      developer.log(
        'TrajectoryKernelJsonNativeBridge initialized',
        name: 'TrajectoryKernelJsonNativeBridge',
      );
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        'TrajectoryKernelJsonNativeBridge unavailable: $error',
        name: 'TrajectoryKernelJsonNativeBridge',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    if (!_attemptedInitialization) {
      initialize();
    }
    if (!_available || _invokeJson == null) {
      throw StateError('Trajectory native bridge is not available.');
    }

    final requestPtr = jsonEncode(<String, dynamic>{
      'syscall': syscall,
      'payload': payload,
    }).toNativeUtf8();

    Pointer<Utf8>? responsePtr;
    try {
      responsePtr = _invokeJson!(requestPtr);
      if (responsePtr.address == 0) {
        throw StateError('Trajectory native bridge returned a null response.');
      }
      final decoded = jsonDecode(responsePtr.toDartString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError(
            'Trajectory native bridge returned a non-map response.');
      }
      if (decoded['ok'] == false) {
        throw StateError(
          (decoded['error'] as String?) ?? 'Unknown trajectory native error',
        );
      }
      return decoded;
    } finally {
      malloc.free(requestPtr);
      if (responsePtr != null &&
          responsePtr.address != 0 &&
          _freeJsonString != null) {
        _freeJsonString!(responsePtr);
      }
    }
  }
}

class TrajectoryKernel {
  TrajectoryKernel({
    TrajectoryKernelJsonNativeBridge? nativeBridge,
    bool? allowFallback,
  })  : _nativeBridge = nativeBridge ?? TrajectoryKernelJsonNativeBridge(),
        _allowFallback = allowFallback ??
            (_isTrajectoryKernelFlutterTest ||
                _isTrajectoryKernelSimulatedSmoke);

  final TrajectoryKernelJsonNativeBridge _nativeBridge;
  final bool _allowFallback;
  static final Map<String, List<TrajectoryMutationRecord>> _fallbackJournals =
      <String, List<TrajectoryMutationRecord>>{};
  static final Map<String, TrajectoryHydrationCheckpoint> _fallbackCheckpoints =
      <String, TrajectoryHydrationCheckpoint>{};

  void appendMutation({
    required TrajectoryMutationRecord record,
    VibeStateSnapshot? checkpointSnapshot,
  }) {
    if (_shouldUseFallback()) {
      _appendFallbackMutation(
        record: record,
        checkpointSnapshot: checkpointSnapshot,
      );
      return;
    }
    _invokeRequired(
      syscall: 'append_mutation',
      payload: <String, dynamic>{
        'record': record.toJson(),
        if (checkpointSnapshot != null)
          'checkpoint_snapshot': checkpointSnapshot.toJson(),
      },
    );
  }

  List<TrajectoryMutationRecord> replaySubject({
    required VibeSubjectRef subjectRef,
    int limit = 256,
  }) {
    if (_shouldUseFallback()) {
      final records = List<TrajectoryMutationRecord>.from(
        _fallbackJournals[_subjectKey(subjectRef)] ??
            const <TrajectoryMutationRecord>[],
      );
      return _takeTail(records, limit);
    }
    return _invokeList(
      syscall: 'replay_subject',
      payload: <String, dynamic>{
        'subject_ref': subjectRef.toJson(),
        'limit': limit,
      },
    ).map(TrajectoryMutationRecord.fromJson).toList();
  }

  TrajectoryHydrationCheckpoint? hydrateVibeSnapshot({
    required VibeSubjectRef subjectRef,
  }) {
    if (_shouldUseFallback()) {
      return _fallbackCheckpoints[_subjectKey(subjectRef)];
    }
    final payload = _invokeOptionalMap(
      syscall: 'hydrate_vibe_snapshot',
      payload: <String, dynamic>{'subject_ref': subjectRef.toJson()},
    );
    if (payload == null) {
      return null;
    }
    return TrajectoryHydrationCheckpoint.fromJson(payload);
  }

  List<TrajectoryMutationRecord> exportJournalWindow({
    VibeSubjectRef? subjectRef,
    int limit = 512,
  }) {
    if (_shouldUseFallback()) {
      if (subjectRef != null) {
        return replaySubject(subjectRef: subjectRef, limit: limit);
      }
      final records = _fallbackJournals.values
          .expand((entries) => entries)
          .toList(growable: false)
        ..sort(
            (left, right) => left.occurredAtUtc.compareTo(right.occurredAtUtc));
      return _takeTail(records, limit);
    }
    return _invokeList(
      syscall: 'export_journal_window',
      payload: <String, dynamic>{
        if (subjectRef != null) 'subject_ref': subjectRef.toJson(),
        'limit': limit,
      },
    ).map(TrajectoryMutationRecord.fromJson).toList();
  }

  void importJournalWindow({
    required List<TrajectoryMutationRecord> records,
    bool resetExisting = true,
  }) {
    if (_shouldUseFallback()) {
      if (resetExisting) {
        _fallbackJournals.clear();
        _fallbackCheckpoints.clear();
      }
      for (final record in records) {
        _fallbackJournals
            .putIfAbsent(
              _subjectKey(record.subjectRef),
              () => <TrajectoryMutationRecord>[],
            )
            .add(record);
      }
      return;
    }
    _invokeRequired(
      syscall: 'import_journal_window',
      payload: <String, dynamic>{
        'reset_existing': resetExisting,
        'records': records.map((entry) => entry.toJson()).toList(),
      },
    );
  }

  Map<String, dynamic> diagnostics() {
    if (_shouldUseFallback()) {
      return <String, dynamic>{
        'status': 'ok',
        'kernel': 'trajectory',
        'native_required': false,
        'native_available': false,
        'fallback_enabled': true,
        'journal_subject_count': _fallbackJournals.length,
        'mutation_count': _fallbackJournals.values
            .fold<int>(0, (sum, entries) => sum + entries.length),
        'checkpoint_count': _fallbackCheckpoints.length,
      };
    }
    return _invokeRequired(
      syscall: 'diagnostics',
      payload: const <String, dynamic>{},
    );
  }

  bool _shouldUseFallback() {
    _nativeBridge.initialize();
    return _allowFallback && !_nativeBridge.isAvailable;
  }

  void _appendFallbackMutation({
    required TrajectoryMutationRecord record,
    VibeStateSnapshot? checkpointSnapshot,
  }) {
    final subjectKey = _subjectKey(record.subjectRef);
    final journal = _fallbackJournals.putIfAbsent(
      subjectKey,
      () => <TrajectoryMutationRecord>[],
    );
    journal.removeWhere((entry) => entry.recordId == record.recordId);
    journal.add(record);
    journal.sort(
        (left, right) => left.occurredAtUtc.compareTo(right.occurredAtUtc));
    if (checkpointSnapshot != null) {
      _fallbackCheckpoints[subjectKey] = TrajectoryHydrationCheckpoint(
        checkpointId: 'checkpoint:${record.recordId}',
        subjectRef: record.subjectRef,
        snapshot: checkpointSnapshot,
        recordedAtUtc: record.occurredAtUtc,
        sourceRecordIds: <String>[record.recordId],
        metadata: const <String, dynamic>{'fallback_enabled': true},
      );
    }
  }

  String _subjectKey(VibeSubjectRef subjectRef) {
    return '${subjectRef.kind.toWireValue()}::${subjectRef.subjectId}';
  }

  List<TrajectoryMutationRecord> _takeTail(
    List<TrajectoryMutationRecord> records,
    int limit,
  ) {
    if (records.length <= limit) {
      return records;
    }
    return records.sublist(records.length - limit);
  }

  Map<String, dynamic> _invokeRequired({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      throw StateError(
        'Native TrajectoryKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native TrajectoryKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
      'Native TrajectoryKernel returned an invalid payload for "$syscall".',
    );
  }

  Map<String, dynamic>? _invokeOptionalMap({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      throw StateError(
        'Native TrajectoryKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native TrajectoryKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload == null) {
      return null;
    }
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    return null;
  }

  List<Map<String, dynamic>> _invokeList({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      throw StateError(
        'Native TrajectoryKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native TrajectoryKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is! List) {
      return const <Map<String, dynamic>>[];
    }
    return nativePayload
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }
}
