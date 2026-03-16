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

const bool _isVibeKernelFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
const bool _isVibeKernelSimulatedSmoke =
    String.fromEnvironment('SIMULATED_SMOKE_PLATFORM') != '';

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
    bool? allowFallback,
  })  : _nativeBridge = nativeBridge ?? VibeKernelJsonNativeBridge(),
        _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel(),
        _allowFallback = allowFallback ??
            (_isVibeKernelFlutterTest || _isVibeKernelSimulatedSmoke);

  final VibeKernelJsonNativeBridge _nativeBridge;
  final TrajectoryKernel _trajectoryKernel;
  final bool _allowFallback;
  static final Map<String, VibeStateSnapshot> _fallbackSubjectSnapshots =
      <String, VibeStateSnapshot>{};
  static final Map<String, EntityVibeSnapshot> _fallbackEntitySnapshots =
      <String, EntityVibeSnapshot>{};
  static DateTime _fallbackExportedAtUtc =
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  static List<String> _fallbackMigrationReceipts = const <String>[];
  static Map<String, dynamic> _fallbackMetadata = const <String, dynamic>{};
  static int _fallbackSchemaVersion = 1;

  VibeUpdateReceipt seedSubjectStateFromOnboarding({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    Map<String, double> dimensionConfidence = const <String, double>{},
    List<String> provenanceTags = const <String>[],
  }) {
    _ensureTrajectoryKernelAvailable();
    if (_shouldUseFallback()) {
      final receipt = _seedFallbackSubjectState(
        subjectRef: subjectRef,
        dimensions: dimensions,
        dimensionConfidence: dimensionConfidence,
        provenanceTags: provenanceTags,
      );
      _appendMutationRecord(
        category: 'seed_from_onboarding',
        subjectRef: subjectRef,
        receipt: receipt,
        evidenceSummary: 'Seeded canonical vibe state from onboarding.',
      );
      return receipt;
    }
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackApplyLanguageEvidence(
        subjectId: subjectId,
        evidence: evidence,
        mutationDecision: mutationDecision,
        provenanceTags: provenanceTags,
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackApplyBehaviorObservation(
        subjectRef: VibeSubjectRef(
          subjectId: subjectId,
          kind: subjectKind,
        ),
        behaviorSignals: behaviorSignals,
        provenanceTags: provenanceTags,
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackApplyEcosystemObservation(
        subjectRef: VibeSubjectRef(
          subjectId: subjectId,
          kind: subjectKind,
        ),
        source: source,
        dimensions: dimensions,
        provenanceTags: provenanceTags,
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackApplyEntityObservation(
        entityId: entityId,
        entityType: entityType,
        dimensions: dimensions,
        provenanceTags: provenanceTags,
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackRecordOutcome(
        subjectRef: VibeSubjectRef(
          subjectId: subjectId,
          kind: subjectKind,
        ),
        outcome: outcome,
        outcomeScore: outcomeScore,
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
    if (_shouldUseFallback()) {
      final receipt = _fallbackAdvanceDecayWindow(
        subjectRef: VibeSubjectRef(
          subjectId: subjectId,
          kind: subjectKind,
        ),
        elapsedHours: elapsedHours,
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
    if (_shouldUseFallback()) {
      return _fallbackSubjectSnapshots[_subjectKey(subjectRef)] ??
          _defaultSnapshotFor(subjectRef);
    }
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
    if (_shouldUseFallback()) {
      final key = _entityKey(entityId, entityType);
      return _fallbackEntitySnapshots[key] ??
          _defaultEntitySnapshot(entityId: entityId, entityType: entityType);
    }
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
    if (_shouldUseFallback()) {
      final userSnapshot = getUserSnapshot(subjectId);
      final geographicSnapshots = resolvedGeographicBinding == null
          ? const <VibeStateSnapshot>[]
          : <VibeStateSnapshot>[
              getSnapshot(resolvedGeographicBinding.localityRef),
              ...resolvedGeographicBinding.higherGeographicRefs
                  .map(getSnapshot),
            ];
      final higherSnapshots = higherAgentRefs.map(getSnapshot).toList();
      final selectedSnapshots = selectedEntityRefs
          .where((entry) => entry.kind == VibeSubjectKind.entity)
          .map(
            (entry) => getEntitySnapshot(
              entityId: entry.subjectId,
              entityType: entry.entityType ?? 'entity',
            ),
          )
          .toList();
      final entitySnapshot = entityId == null
          ? null
          : getEntitySnapshot(
              entityId: entityId,
              entityType: entityType ?? 'entity',
            );
      final hierarchicalStack = getHierarchicalStack(
        subjectRef: VibeSubjectRef.personal(subjectId),
        geographicBinding: resolvedGeographicBinding,
        scopedBindings: scopedBindings,
        localityBinding: localityBinding,
        higherAgentRefs: higherAgentRefs,
        selectedEntityRefs: selectedEntityRefs,
      );
      return StateEncoderInputSnapshot.fromJson(<String, dynamic>{
        'user_snapshot': userSnapshot.toJson(),
        if (entitySnapshot != null) 'entity_snapshot': entitySnapshot.toJson(),
        'geographic_snapshots':
            geographicSnapshots.map((entry) => entry.toJson()).toList(),
        'scoped_context_snapshots': const <Map<String, dynamic>>[],
        if (resolvedGeographicBinding != null)
          'geographic_binding': resolvedGeographicBinding.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        if (geographicSnapshots.isNotEmpty)
          'active_locality_snapshot': geographicSnapshots.first.toJson(),
        'higher_agent_snapshots':
            higherSnapshots.map((entry) => entry.toJson()).toList(),
        'selected_entity_snapshots':
            selectedSnapshots.map((entry) => entry.toJson()).toList(),
        'hierarchical_stack': hierarchicalStack.toJson(),
        'metadata': const <String, dynamic>{'fallback_enabled': true},
      });
    }
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
    if (_shouldUseFallback()) {
      final primarySnapshot = getSnapshot(subjectRef);
      final geographicSnapshots = resolvedGeographicBinding == null
          ? const <VibeStateSnapshot>[]
          : <VibeStateSnapshot>[
              getSnapshot(resolvedGeographicBinding.localityRef),
              ...resolvedGeographicBinding.higherGeographicRefs
                  .map(getSnapshot),
            ];
      final higherSnapshots = higherAgentRefs.map(getSnapshot).toList();
      final selectedSnapshots = selectedEntityRefs
          .where((entry) => entry.kind == VibeSubjectKind.entity)
          .map(
            (entry) => getEntitySnapshot(
              entityId: entry.subjectId,
              entityType: entry.entityType ?? 'entity',
            ),
          )
          .toList();
      return HierarchicalVibeStack.fromJson(<String, dynamic>{
        'primary_snapshot': primarySnapshot.toJson(),
        'geographic_snapshots':
            geographicSnapshots.map((entry) => entry.toJson()).toList(),
        'scoped_context_snapshots': const <Map<String, dynamic>>[],
        if (resolvedGeographicBinding != null)
          'geographic_binding': resolvedGeographicBinding.toJson(),
        'scoped_bindings':
            scopedBindings.map((entry) => entry.toJson()).toList(),
        if (geographicSnapshots.isNotEmpty)
          'active_locality_snapshot': geographicSnapshots.first.toJson(),
        'higher_agent_snapshots':
            higherSnapshots.map((entry) => entry.toJson()).toList(),
        'selected_entity_snapshots':
            selectedSnapshots.map((entry) => entry.toJson()).toList(),
        if (localityBinding != null)
          'locality_binding': localityBinding.toJson(),
      });
    }
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
    if (_shouldUseFallback()) {
      return getUserSnapshot(subjectId).expressionContext;
    }
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
    if (_shouldUseFallback()) {
      _fallbackExportedAtUtc = DateTime.now().toUtc();
      return VibeSnapshotEnvelope(
        exportedAtUtc: _fallbackExportedAtUtc,
        subjectSnapshots: _fallbackSubjectSnapshots.values.toList()
          ..sort((a, b) => a.subjectId.compareTo(b.subjectId)),
        entitySnapshots: _fallbackEntitySnapshots.values.toList()
          ..sort((a, b) => a.entityId.compareTo(b.entityId)),
        migrationReceipts: _fallbackMigrationReceipts,
        metadata: _fallbackMetadata,
        schemaVersion: _fallbackSchemaVersion,
      );
    }
    return VibeSnapshotEnvelope.fromJson(
      _invokeRequired(
        syscall: 'export_snapshot_envelope',
        payload: const <String, dynamic>{},
      ),
    );
  }

  void importSnapshotEnvelope(VibeSnapshotEnvelope envelope) {
    if (_shouldUseFallback()) {
      _fallbackSubjectSnapshots
        ..clear()
        ..addEntries(
          envelope.subjectSnapshots.map(
            (entry) => MapEntry(_subjectKey(entry.subjectRef), entry),
          ),
        );
      _fallbackEntitySnapshots
        ..clear()
        ..addEntries(
          envelope.entitySnapshots.map(
            (entry) =>
                MapEntry(_entityKey(entry.entityId, entry.entityType), entry),
          ),
        );
      _fallbackExportedAtUtc = envelope.exportedAtUtc.toUtc();
      _fallbackMigrationReceipts =
          List<String>.from(envelope.migrationReceipts, growable: false);
      _fallbackMetadata = Map<String, dynamic>.from(envelope.metadata);
      _fallbackSchemaVersion = envelope.schemaVersion;
      return;
    }
    _invokeRequired(
      syscall: 'import_snapshot_envelope',
      payload: <String, dynamic>{'envelope': envelope.toJson()},
    );
  }

  Map<String, dynamic> diagnostics() {
    if (_shouldUseFallback()) {
      return <String, dynamic>{
        'status': 'ok',
        'kernel': 'vibe',
        'native_required': false,
        'native_available': false,
        'fallback_enabled': true,
        'subject_snapshot_count': _fallbackSubjectSnapshots.length,
        'entity_snapshot_count': _fallbackEntitySnapshots.length,
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

  VibeUpdateReceipt _seedFallbackSubjectState({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    required Map<String, double> dimensionConfidence,
    required List<String> provenanceTags,
  }) {
    final snapshot = _storeSubjectSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      dimensionConfidence: dimensionConfidence,
      provenanceTags: provenanceTags,
      replaceDimensions: true,
      behaviorObservationIncrement: 0,
    );
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackApplyLanguageEvidence({
    required String subjectId,
    required VibeEvidence evidence,
    required VibeMutationDecision mutationDecision,
    required List<String> provenanceTags,
  }) {
    final dimensions = <String, double>{
      for (final signal in <VibeSignal>[
        ...evidence.identitySignals,
        ...evidence.behaviorSignals,
        ...evidence.styleSignals,
      ])
        signal.key: signal.value.clamp(0.0, 1.0),
    };
    final snapshot = _storeSubjectSnapshot(
      subjectRef: VibeSubjectRef.personal(subjectId),
      dimensions: dimensions,
      dimensionConfidence: <String, double>{
        for (final entry in dimensions.entries) entry.key: 0.72,
      },
      provenanceTags: <String>[
        ...provenanceTags,
        'governance_scope:${mutationDecision.governanceScope}',
      ],
      replaceDimensions: false,
      behaviorObservationIncrement: evidence.behaviorSignals.isEmpty ? 0 : 1,
    );
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackApplyBehaviorObservation({
    required VibeSubjectRef subjectRef,
    required Map<String, double> behaviorSignals,
    required List<String> provenanceTags,
  }) {
    final snapshot = _storeSubjectSnapshot(
      subjectRef: subjectRef,
      dimensions: behaviorSignals,
      dimensionConfidence: <String, double>{
        for (final entry in behaviorSignals.entries) entry.key: 0.64,
      },
      provenanceTags: provenanceTags,
      replaceDimensions: false,
      behaviorObservationIncrement: 1,
      behaviorSignals: behaviorSignals,
    );
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackApplyEcosystemObservation({
    required VibeSubjectRef subjectRef,
    required String source,
    required Map<String, double> dimensions,
    required List<String> provenanceTags,
  }) {
    final snapshot = _storeSubjectSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      dimensionConfidence: <String, double>{
        for (final entry in dimensions.entries) entry.key: 0.68,
      },
      provenanceTags: <String>[...provenanceTags, 'source:$source'],
      replaceDimensions: false,
      behaviorObservationIncrement: 0,
    );
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackApplyEntityObservation({
    required String entityId,
    required String entityType,
    required Map<String, double> dimensions,
    required List<String> provenanceTags,
  }) {
    final subjectRef =
        VibeSubjectRef.entity(entityId: entityId, entityType: entityType);
    final snapshot = _storeSubjectSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      dimensionConfidence: <String, double>{
        for (final entry in dimensions.entries) entry.key: 0.7,
      },
      provenanceTags: provenanceTags,
      replaceDimensions: false,
      behaviorObservationIncrement: 0,
    );
    final entitySnapshot = EntityVibeSnapshot(
      entityId: entityId,
      entityType: entityType,
      vibe: snapshot,
    );
    _fallbackEntitySnapshots[_entityKey(entityId, entityType)] = entitySnapshot;
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackRecordOutcome({
    required VibeSubjectRef subjectRef,
    required String outcome,
    required double outcomeScore,
  }) {
    final snapshot = _storeSubjectSnapshot(
      subjectRef: subjectRef,
      dimensions: <String, double>{
        'community_orientation': outcomeScore.clamp(0.0, 1.0),
      },
      dimensionConfidence: const <String, double>{
        'community_orientation': 0.55,
      },
      provenanceTags: <String>['outcome:$outcome'],
      replaceDimensions: false,
      behaviorObservationIncrement: 1,
    );
    return _receiptForSnapshot(snapshot);
  }

  VibeUpdateReceipt _fallbackAdvanceDecayWindow({
    required VibeSubjectRef subjectRef,
    required double elapsedHours,
  }) {
    final existing = _fallbackSubjectSnapshots[_subjectKey(subjectRef)] ??
        _defaultSnapshotFor(subjectRef);
    final snapshotJson = existing.toJson();
    snapshotJson['freshness_hours'] =
        (((snapshotJson['freshness_hours'] as num?)?.toDouble() ?? 0.0) +
                elapsedHours)
            .clamp(0.0, 24 * 365);
    snapshotJson['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
    final snapshot = VibeStateSnapshot.fromJson(snapshotJson);
    _fallbackSubjectSnapshots[_subjectKey(subjectRef)] = snapshot;
    return _receiptForSnapshot(snapshot);
  }

  VibeStateSnapshot _storeSubjectSnapshot({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    required Map<String, double> dimensionConfidence,
    required List<String> provenanceTags,
    required bool replaceDimensions,
    required int behaviorObservationIncrement,
    Map<String, double>? behaviorSignals,
  }) {
    final current = _fallbackSubjectSnapshots[_subjectKey(subjectRef)] ??
        _defaultSnapshotFor(subjectRef);
    final snapshotJson = current.toJson();
    final currentDimensions = Map<String, dynamic>.from(
      (snapshotJson['core_dna'] as Map?)?['dimensions'] as Map? ??
          const <String, dynamic>{},
    );
    final currentConfidence = Map<String, dynamic>.from(
      (snapshotJson['core_dna'] as Map?)?['dimension_confidence'] as Map? ??
          const <String, dynamic>{},
    );
    final nextDimensions = replaceDimensions
        ? <String, dynamic>{
            for (final entry in dimensions.entries)
              entry.key: entry.value.clamp(0.0, 1.0),
          }
        : <String, dynamic>{...currentDimensions};
    if (!replaceDimensions) {
      for (final entry in dimensions.entries) {
        final existing = (nextDimensions[entry.key] as num?)?.toDouble();
        nextDimensions[entry.key] = existing == null
            ? entry.value.clamp(0.0, 1.0)
            : ((existing + entry.value) / 2).clamp(0.0, 1.0);
      }
    }
    for (final entry in dimensionConfidence.entries) {
      currentConfidence[entry.key] = entry.value.clamp(0.0, 1.0);
    }
    final behaviorJson = Map<String, dynamic>.from(
      snapshotJson['behavior_patterns'] as Map? ?? const <String, dynamic>{},
    );
    final patternWeights = Map<String, dynamic>.from(
      behaviorJson['pattern_weights'] as Map? ?? const <String, dynamic>{},
    );
    for (final entry in (behaviorSignals ?? dimensions).entries) {
      patternWeights[entry.key] = entry.value.clamp(0.0, 1.0);
    }
    behaviorJson['pattern_weights'] = patternWeights;
    behaviorJson['observation_count'] =
        ((behaviorJson['observation_count'] as num?)?.toInt() ?? 0) +
            behaviorObservationIncrement;
    final expressionContext = Map<String, dynamic>.from(
      snapshotJson['expression_context'] as Map? ?? const <String, dynamic>{},
    );
    if (nextDimensions.containsKey('energy_preference')) {
      expressionContext['energy'] =
          (nextDimensions['energy_preference'] as num?)?.toDouble() ?? 0.5;
    }
    if (nextDimensions.containsKey('community_orientation')) {
      expressionContext['social_cadence'] =
          (nextDimensions['community_orientation'] as num?)?.toDouble() ?? 0.5;
    }
    snapshotJson['core_dna'] = <String, dynamic>{
      ...(snapshotJson['core_dna'] as Map? ?? const <String, dynamic>{}),
      'dimensions': nextDimensions,
      'dimension_confidence': currentConfidence,
    };
    snapshotJson['behavior_patterns'] = behaviorJson;
    snapshotJson['expression_context'] = expressionContext;
    snapshotJson['provenance_tags'] = <String>{
      ...((snapshotJson['provenance_tags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString()),
      ...provenanceTags,
    }.toList(growable: false);
    snapshotJson['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
    snapshotJson['confidence'] = currentConfidence.isEmpty
        ? 0.5
        : currentConfidence.values
                .map((entry) => (entry as num?)?.toDouble() ?? 0.0)
                .fold<double>(0.0, (sum, entry) => sum + entry) /
            currentConfidence.length;
    final snapshot = VibeStateSnapshot.fromJson(snapshotJson);
    _fallbackSubjectSnapshots[_subjectKey(subjectRef)] = snapshot;
    if (subjectRef.kind == VibeSubjectKind.entity) {
      _fallbackEntitySnapshots[_entityKey(
        subjectRef.subjectId,
        subjectRef.entityType ?? 'entity',
      )] = EntityVibeSnapshot(
        entityId: subjectRef.subjectId,
        entityType: subjectRef.entityType ?? 'entity',
        vibe: snapshot,
      );
    }
    return snapshot;
  }

  VibeUpdateReceipt _receiptForSnapshot(VibeStateSnapshot snapshot) {
    return VibeUpdateReceipt(
      subjectId: snapshot.subjectId,
      accepted: true,
      reasonCodes: const <String>[],
      updatedAtUtc: snapshot.updatedAtUtc,
      snapshot: snapshot,
    );
  }

  VibeStateSnapshot _defaultSnapshotFor(VibeSubjectRef subjectRef) {
    return VibeStateSnapshot.fromJson(<String, dynamic>{
      'subject_id': subjectRef.subjectId,
      'subject_kind': subjectRef.kind.toWireValue(),
      'core_dna': const <String, dynamic>{
        'dimensions': <String, double>{},
        'dimension_confidence': <String, double>{},
        'drift_budget_remaining': 0.3,
      },
      'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'confidence': 0.5,
      'freshness_hours': 0.0,
      'provenance_tags': const <String>[],
    });
  }

  EntityVibeSnapshot _defaultEntitySnapshot({
    required String entityId,
    required String entityType,
  }) {
    return EntityVibeSnapshot(
      entityId: entityId,
      entityType: entityType,
      vibe: _defaultSnapshotFor(
        VibeSubjectRef.entity(entityId: entityId, entityType: entityType),
      ),
    );
  }

  String _subjectKey(VibeSubjectRef subjectRef) {
    return '${subjectRef.kind.toWireValue()}::${subjectRef.subjectId}';
  }

  String _entityKey(String entityId, String entityType) {
    return '$entityType::$entityId';
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
      final scopedKind = subjectRef.scopedKind?.toWireValue() ?? 'organization';
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
