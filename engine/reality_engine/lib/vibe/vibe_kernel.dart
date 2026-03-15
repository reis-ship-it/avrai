import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:ffi/ffi.dart';
import '../trajectory/trajectory_kernel.dart';
import 'vibe_kernel_runtime_binding.dart';

typedef _NativeInvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InvokeJson = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFreeJsonString = Void Function(Pointer<Utf8>);
typedef _FreeJsonString = void Function(Pointer<Utf8>);

abstract class VibeKernelLibraryManager {
  DynamicLibrary getKernelLibrary();
}

class DefaultVibeKernelLibraryManager implements VibeKernelLibraryManager {
  @override
  DynamicLibrary getKernelLibrary() {
    final candidates = _candidatePaths();

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return DynamicLibrary.open(candidate);
      }
    }
    throw StateError(
      'Vibe kernel library not found in expected locations: ${candidates.join(', ')}',
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
        '$root/runtime/avrai_network/native/vibe_kernel/target/debug/libavrai_vibe_kernel.dylib',
        '$root/runtime/avrai_network/native/vibe_kernel/target/release/libavrai_vibe_kernel.dylib',
        '$root/runtime/avrai_network/native/vibe_kernel/macos/libavrai_vibe_kernel.dylib',
        '$root/runtime/avrai_network/native/vibe_kernel/target/debug/libavrai_vibe_kernel.so',
        '$root/runtime/avrai_network/native/vibe_kernel/target/release/libavrai_vibe_kernel.so',
      ]);
    }
    return candidates.toSet().toList(growable: false);
  }
}

class VibeKernelJsonNativeBridge {
  VibeKernelJsonNativeBridge({
    VibeKernelLibraryManager? libraryManager,
  }) : _libraryManager = libraryManager ?? DefaultVibeKernelLibraryManager();

  final VibeKernelLibraryManager _libraryManager;

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
          _lib =
              DynamicLibrary.open('AVRAIVibeKernel.framework/AVRAIVibeKernel');
        } catch (_) {
          _lib = DynamicLibrary.process();
        }
      } else if (Platform.isAndroid || Platform.isLinux) {
        _lib = DynamicLibrary.open('libavrai_vibe_kernel.so');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('avrai_vibe_kernel.dll');
      } else {
        _lib = _libraryManager.getKernelLibrary();
      }
      _invokeJson = _lib!
          .lookup<NativeFunction<_NativeInvokeJson>>(
            'avrai_vibe_kernel_invoke_json',
          )
          .asFunction<_InvokeJson>();
      _freeJsonString = _lib!
          .lookup<NativeFunction<_NativeFreeJsonString>>(
            'avrai_vibe_kernel_free_string',
          )
          .asFunction<_FreeJsonString>();
      _available = true;
      developer.log('VibeKernelJsonNativeBridge initialized',
          name: 'VibeKernelJsonNativeBridge');
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        'VibeKernelJsonNativeBridge unavailable: $error',
        name: 'VibeKernelJsonNativeBridge',
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
      throw StateError('Vibe native bridge is not available.');
    }

    final requestPtr = jsonEncode(<String, dynamic>{
      'syscall': syscall,
      'payload': payload,
    }).toNativeUtf8();

    Pointer<Utf8>? responsePtr;
    try {
      responsePtr = _invokeJson!(requestPtr);
      if (responsePtr.address == 0) {
        throw StateError('Vibe native bridge returned a null response.');
      }
      final decoded = jsonDecode(responsePtr.toDartString());
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Vibe native bridge returned a non-map response.');
      }
      if (decoded['ok'] == false) {
        throw StateError(
          (decoded['error'] as String?) ?? 'Unknown vibe native error',
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

class VibeKernel {
  VibeKernel({
    VibeKernelJsonNativeBridge? nativeBridge,
    TrajectoryKernel? trajectoryKernel,
  })  : _nativeBridge = nativeBridge ?? VibeKernelJsonNativeBridge(),
        _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel();

  final VibeKernelJsonNativeBridge _nativeBridge;
  final TrajectoryKernel _trajectoryKernel;

  VibeUpdateReceipt seedSubjectStateFromOnboarding({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    Map<String, double> dimensionConfidence = const <String, double>{},
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'seed_user_state_from_onboarding',
        payload: <String, dynamic>{
          'subject_id': subjectRef.subjectId,
          'subject_kind': subjectRef.kind.toWireValue(),
          'dimensions': dimensions,
          'dimension_confidence': dimensionConfidence,
          'provenance_tags': provenanceTags,
        },
      ),
    );
    _appendMutationRecord(
      category: 'seed_from_onboarding',
      subjectRef: subjectRef,
      receipt: receipt,
      evidenceSummary: 'Seeded canonical vibe state from onboarding.',
    );
    return receipt;
  }

  VibeUpdateReceipt seedUserStateFromOnboarding({
    required String subjectId,
    required Map<String, double> dimensions,
    Map<String, double> dimensionConfidence = const <String, double>{},
    List<String> provenanceTags = const <String>[],
  }) {
    return seedSubjectStateFromOnboarding(
      subjectRef: VibeSubjectRef.personal(subjectId),
      dimensions: dimensions,
      dimensionConfidence: dimensionConfidence,
      provenanceTags: provenanceTags,
    );
  }

  VibeUpdateReceipt ingestLanguageEvidence({
    required String subjectId,
    required VibeEvidence evidence,
    required VibeMutationDecision mutationDecision,
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'ingest_language_evidence',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': VibeSubjectKind.personalAgent.toWireValue(),
          'evidence': evidence.toJson(),
          'mutation_decision': mutationDecision.toJson(),
          'provenance_tags': provenanceTags,
        },
      ),
    );
    _appendMutationRecord(
      category: 'language_evidence',
      subjectRef: VibeSubjectRef.personal(subjectId),
      receipt: receipt,
      evidenceSummary: evidence.summary,
      governanceScope: mutationDecision.governanceScope,
    );
    return receipt;
  }

  VibeUpdateReceipt ingestBehaviorObservation({
    required String subjectId,
    required Map<String, double> behaviorSignals,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'ingest_behavior_observation',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': subjectKind.toWireValue(),
          'behavior_signals': behaviorSignals,
          'provenance_tags': provenanceTags,
        },
      ),
    );
    _appendMutationRecord(
      category: 'behavior_observation',
      subjectRef: VibeSubjectRef(
        subjectId: subjectId,
        kind: subjectKind,
      ),
      receipt: receipt,
      evidenceSummary: 'Behavior observation applied.',
    );
    return receipt;
  }

  VibeUpdateReceipt ingestEcosystemObservation({
    required String subjectId,
    required String source,
    required Map<String, double> dimensions,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'ingest_ecosystem_observation',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': subjectKind.toWireValue(),
          'source': source,
          'dimensions': dimensions,
          'provenance_tags': provenanceTags,
        },
      ),
    );
    _appendMutationRecord(
      category: 'ecosystem_observation',
      subjectRef: VibeSubjectRef(
        subjectId: subjectId,
        kind: subjectKind,
      ),
      receipt: receipt,
      evidenceSummary: 'Ecosystem observation from $source.',
    );
    return receipt;
  }

  VibeUpdateReceipt ingestEntityObservation({
    required String entityId,
    required String entityType,
    required Map<String, double> dimensions,
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'ingest_entity_observation',
        payload: <String, dynamic>{
          'entity_id': entityId,
          'entity_type': entityType,
          'dimensions': dimensions,
          'provenance_tags': provenanceTags,
        },
      ),
    );
    _appendMutationRecord(
      category: 'entity_observation',
      subjectRef: VibeSubjectRef.entity(
        entityId: entityId,
        entityType: entityType,
      ),
      receipt: receipt,
      evidenceSummary: 'Entity vibe synchronized for $entityType.',
    );
    return receipt;
  }

  VibeUpdateReceipt recordOutcome({
    required String subjectId,
    required String outcome,
    double outcomeScore = 0.5,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'record_outcome',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': subjectKind.toWireValue(),
          'outcome': outcome,
          'outcome_score': outcomeScore,
        },
      ),
    );
    _appendMutationRecord(
      category: 'outcome',
      subjectRef: VibeSubjectRef(
        subjectId: subjectId,
        kind: subjectKind,
      ),
      receipt: receipt,
      evidenceSummary: 'Outcome recorded: $outcome.',
    );
    return receipt;
  }

  VibeUpdateReceipt advanceDecayWindow({
    required String subjectId,
    double elapsedHours = 24.0,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
  }) {
    _ensureTrajectoryKernelAvailable();
    final receipt = VibeUpdateReceipt.fromJson(
      _invokeRequired(
        syscall: 'advance_decay_window',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': subjectKind.toWireValue(),
          'elapsed_hours': elapsedHours,
        },
      ),
    );
    _appendMutationRecord(
      category: 'decay_window',
      subjectRef: VibeSubjectRef(
        subjectId: subjectId,
        kind: subjectKind,
      ),
      receipt: receipt,
      evidenceSummary: 'Decay window advanced by $elapsedHours hours.',
    );
    return receipt;
  }

  VibeStateSnapshot getSnapshot(VibeSubjectRef subjectRef) {
    return VibeStateSnapshot.fromJson(
      _invokeRequired(
        syscall: 'get_user_snapshot',
        payload: <String, dynamic>{
          'subject_id': subjectRef.subjectId,
          'subject_kind': subjectRef.kind.toWireValue(),
        },
      ),
    );
  }

  VibeStateSnapshot getUserSnapshot(String subjectId) =>
      getSnapshot(VibeSubjectRef.personal(subjectId));

  EntityVibeSnapshot getEntitySnapshot({
    required String entityId,
    String entityType = 'entity',
  }) {
    return EntityVibeSnapshot.fromJson(
      _invokeRequired(
        syscall: 'get_entity_snapshot',
        payload: <String, dynamic>{
          'entity_id': entityId,
          'entity_type': entityType,
        },
      ),
    );
  }

  StateEncoderInputSnapshot getStateEncoderSnapshot({
    required String subjectId,
    String? entityId,
    String? entityType,
    GeographicVibeBinding? geographicBinding,
    List<ScopedVibeBinding> scopedBindings = const <ScopedVibeBinding>[],
    LocalityVibeBinding? localityBinding,
    List<VibeSubjectRef> higherAgentRefs = const <VibeSubjectRef>[],
    List<VibeSubjectRef> selectedEntityRefs = const <VibeSubjectRef>[],
  }) {
    final resolvedGeographicBinding =
        geographicBinding ?? localityBinding?.toGeographicBinding();
    return StateEncoderInputSnapshot.fromJson(
      _invokeRequired(
        syscall: 'get_state_encoder_snapshot',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          if (entityId != null) 'entity_id': entityId,
          if (entityType != null) 'entity_type': entityType,
          if (resolvedGeographicBinding != null)
            'geographic_binding': resolvedGeographicBinding.toJson(),
          if (localityBinding != null)
            'locality_binding': localityBinding.toJson(),
          'scoped_bindings':
              scopedBindings.map((entry) => entry.toJson()).toList(),
          'higher_agent_refs':
              higherAgentRefs.map((entry) => entry.toJson()).toList(),
          'selected_entity_refs':
              selectedEntityRefs.map((entry) => entry.toJson()).toList(),
        },
      ),
    );
  }

  HierarchicalVibeStack getHierarchicalStack({
    required VibeSubjectRef subjectRef,
    GeographicVibeBinding? geographicBinding,
    List<ScopedVibeBinding> scopedBindings = const <ScopedVibeBinding>[],
    LocalityVibeBinding? localityBinding,
    List<VibeSubjectRef> higherAgentRefs = const <VibeSubjectRef>[],
    List<VibeSubjectRef> selectedEntityRefs = const <VibeSubjectRef>[],
  }) {
    final resolvedGeographicBinding =
        geographicBinding ?? localityBinding?.toGeographicBinding();
    return HierarchicalVibeStack.fromJson(
      _invokeRequired(
        syscall: 'get_hierarchical_stack',
        payload: <String, dynamic>{
          'subject_ref': subjectRef.toJson(),
          if (resolvedGeographicBinding != null)
            'geographic_binding': resolvedGeographicBinding.toJson(),
          if (localityBinding != null)
            'locality_binding': localityBinding.toJson(),
          'scoped_bindings':
              scopedBindings.map((entry) => entry.toJson()).toList(),
          'higher_agent_refs':
              higherAgentRefs.map((entry) => entry.toJson()).toList(),
          'selected_entity_refs':
              selectedEntityRefs.map((entry) => entry.toJson()).toList(),
        },
      ),
    );
  }

  VibeExpressionContext getExpressionContext(String subjectId) {
    return VibeExpressionContext.fromJson(
      _invokeRequired(
        syscall: 'get_expression_context',
        payload: <String, dynamic>{
          'subject_id': subjectId,
          'subject_kind': VibeSubjectKind.personalAgent.toWireValue(),
        },
      ),
    );
  }

  VibeSnapshotEnvelope exportSnapshotEnvelope() {
    return VibeSnapshotEnvelope.fromJson(
      _invokeRequired(
        syscall: 'export_snapshot_envelope',
        payload: const <String, dynamic>{},
      ),
    );
  }

  void importSnapshotEnvelope(VibeSnapshotEnvelope envelope) {
    _invokeRequired(
      syscall: 'import_snapshot_envelope',
      payload: <String, dynamic>{'envelope': envelope.toJson()},
    );
  }

  Map<String, dynamic> diagnostics() {
    return _invokeRequired(
      syscall: 'diagnostics',
      payload: const <String, dynamic>{},
    );
  }

  Map<String, dynamic> _invokeRequired({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      throw StateError(
        'Native VibeKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native VibeKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
        'Native VibeKernel returned an invalid payload for "$syscall".');
  }

  void _ensureTrajectoryKernelAvailable() {
    _trajectoryKernel.diagnostics();
  }

  void _appendMutationRecord({
    required String category,
    required VibeSubjectRef subjectRef,
    required VibeUpdateReceipt receipt,
    String? evidenceSummary,
    String? governanceScope,
  }) {
    final record = TrajectoryMutationRecord(
        recordId:
            '$category:${subjectRef.subjectId}:${receipt.updatedAtUtc.microsecondsSinceEpoch}',
        subjectRef: subjectRef,
        category: category,
        occurredAtUtc: receipt.updatedAtUtc,
        accepted: receipt.accepted,
        reasonCodes: receipt.reasonCodes,
        governanceScope: governanceScope ?? _defaultGovernanceScope(subjectRef),
        evidenceSummary: evidenceSummary,
        snapshotUpdatedAtUtc: receipt.snapshot.updatedAtUtc,
        metadata: <String, dynamic>{
          'subject_kind': subjectRef.kind.toWireValue(),
        },
      );
    _trajectoryKernel.appendMutation(
      record: record,
      checkpointSnapshot: receipt.snapshot,
    );
    VibeKernelRuntimeBindings.publishMutationReceipt(record);
    final persistenceBridge = VibeKernelRuntimeBindings.persistenceBridge;
    if (persistenceBridge != null) {
      unawaited(
        persistenceBridge.persistCanonicalState(
          envelope: exportSnapshotEnvelope(),
          journalWindow: _trajectoryKernel.exportJournalWindow(limit: 2048),
        ),
      );
    }
  }

  String _defaultGovernanceScope(VibeSubjectRef subjectRef) {
    if (subjectRef.kind == VibeSubjectKind.personalAgent) {
      return 'personal';
    }
    if (subjectRef.kind == VibeSubjectKind.entity) {
      return 'entity';
    }
    if (subjectRef.kind == VibeSubjectKind.scopedAgent) {
      final scopedKind =
          subjectRef.scopedKind?.toWireValue() ?? 'organization';
      return 'scoped:$scopedKind';
    }
    final geographicLevel = subjectRef.effectiveGeographicLevel;
    if (subjectRef.kind == VibeSubjectKind.geographicAgent ||
        subjectRef.kind.isLegacyGeographicAlias ||
        geographicLevel != null) {
      final level = geographicLevel?.toWireValue() ?? 'locality';
      return 'geographic:$level';
    }
    return 'personal';
  }
}
