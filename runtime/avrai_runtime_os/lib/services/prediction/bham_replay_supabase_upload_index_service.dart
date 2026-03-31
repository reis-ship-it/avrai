import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_supabase_storage_gateway.dart';
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart';

class BhamReplaySupabaseUploadIndexService {
  const BhamReplaySupabaseUploadIndexService({
    ReplaySupabaseStorageGateway Function({
      required SupabaseClient client,
      required String schema,
    })? gatewayFactory,
  }) : _gatewayFactory = gatewayFactory;

  final ReplaySupabaseStorageGateway Function({
    required SupabaseClient client,
    required String schema,
  })? _gatewayFactory;

  ReplayStorageUploadManifest buildUploadManifest({
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
    bool dryRun = true,
  }) {
    _validateBuildUploadManifestContract(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
    );
    final boundaryReport = const BhamReplayStorageBoundaryService().buildReport(
      environmentId: exportManifest.environmentId,
      replayYear: exportManifest.replayYear,
    );
    if (!boundaryReport.passed) {
      throw StateError(
        'Replay storage boundary failed: ${boundaryReport.violations.join(' | ')}',
      );
    }

    final partitionGroups = <String, List<ReplayStoragePartitionEntry>>{};
    for (final entry in partitionManifest.entries) {
      partitionGroups
          .putIfAbsent(entry.artifactRef, () => <ReplayStoragePartitionEntry>[])
          .add(entry);
    }

    final uploadEntries = <ReplayStorageUploadEntry>[];
    for (final exportEntry in exportManifest.entries) {
      final partitions = partitionGroups[exportEntry.artifactRef];
      if (partitions != null && partitions.isNotEmpty) {
        final baseDir = p.dirname(exportEntry.objectPath);
        for (final partitionEntry in partitions) {
          uploadEntries.add(
            ReplayStorageUploadEntry(
              artifactRef: exportEntry.artifactRef,
              bucket: exportEntry.bucket,
              objectPath: '$baseDir/partitions/${partitionEntry.objectPath}',
              localPath:
                  '${partitionManifest.partitionRoot}/${partitionEntry.objectPath}',
              representation: 'partitioned_ndjson',
              byteSize: partitionEntry.byteSize,
              section: partitionEntry.section,
              chunkIndex: partitionEntry.chunkIndex,
              recordCount: partitionEntry.recordCount,
            ),
          );
        }
        continue;
      }

      uploadEntries.add(
        ReplayStorageUploadEntry(
          artifactRef: exportEntry.artifactRef,
          bucket: exportEntry.bucket,
          objectPath: exportEntry.objectPath,
          localPath:
              '${exportManifest.exportRoot}/${exportEntry.bucket}/${exportEntry.objectPath}',
          representation: 'single_object',
          byteSize: exportEntry.byteSize,
        ),
      );
    }

    final representationCounts = <String, int>{};
    final bucketCounts = <String, int>{};
    for (final entry in uploadEntries) {
      representationCounts.update(
        entry.representation,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      bucketCounts.update(entry.bucket, (value) => value + 1,
          ifAbsent: () => 1);
    }

    return ReplayStorageUploadManifest(
      environmentId: exportManifest.environmentId,
      replayYear: exportManifest.replayYear,
      status: exportManifest.status,
      dryRun: dryRun,
      projectIsolationMode: boundaryReport.projectIsolationMode,
      replaySchema: boundaryReport.replaySchema,
      entries: uploadEntries,
      notes: <String>[
        if (dryRun)
          'This upload/index manifest was generated in dry-run mode.'
        else
          'This upload/index manifest was generated for live replay-only Supabase upload.',
        'Replay objects target replay-prefixed buckets only.',
        'Partitioned artifacts are uploaded as NDJSON chunks under replay-only partition paths.',
        'Required replay schema migrations: work/supabase/migrations/091_replay_simulation_storage_v1.sql, work/supabase/migrations/092_replay_simulation_training_indices_v1.sql, and work/supabase/migrations/093_replay_simulation_training_grade_v1.sql',
      ],
      metadata: <String, dynamic>{
        'bucketCounts': bucketCounts,
        'representationCounts': representationCounts,
        'stagedArtifactCount': exportManifest.entries.length,
        'partitionedArtifactCount': partitionGroups.length,
        'partitionEntryCount': partitionManifest.entries.length,
      },
    );
  }

  Future<ReplayStorageUploadManifest> uploadAndIndex({
    required ReplayStorageUploadManifest uploadManifest,
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
    String? replayUrl,
    String? replayAnonKey,
    String? replayServiceRoleKey,
    bool? dryRun,
  }) async {
    _validateUploadAndIndexContract(
      uploadManifest: uploadManifest,
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
    );
    final plannedIndexedTables = _buildPlannedIndexedTableCounts(
      runId: _buildRunId(
        environmentId: uploadManifest.environmentId,
        replayYear: uploadManifest.replayYear,
      ),
      exportManifest: exportManifest,
    );
    final effectiveDryRun = dryRun ??
        replayUrl == null ||
            replayUrl.isEmpty ||
            replayServiceRoleKey == null ||
            replayServiceRoleKey.isEmpty;
    if (effectiveDryRun) {
      return ReplayStorageUploadManifest(
        environmentId: uploadManifest.environmentId,
        replayYear: uploadManifest.replayYear,
        status: uploadManifest.status,
        dryRun: true,
        projectIsolationMode: uploadManifest.projectIsolationMode,
        replaySchema: uploadManifest.replaySchema,
        entries: uploadManifest.entries,
        notes: <String>[
          ...uploadManifest.notes,
          'Live upload/index was not attempted because replay Supabase credentials were not supplied.',
        ],
        metadata: <String, dynamic>{
          ...uploadManifest.metadata,
          'liveUploadAttempted': false,
          'liveUploadSucceeded': false,
          'indexedTables': const <String, int>{},
          'plannedIndexedTables': plannedIndexedTables,
        },
      );
    }

    final replayUrlValue = replayUrl!;
    final replayServiceRoleKeyValue = replayServiceRoleKey!;

    final boundaryReport = const BhamReplayStorageBoundaryService().buildReport(
      environmentId: uploadManifest.environmentId,
      replayYear: uploadManifest.replayYear,
      replayUrl: replayUrlValue,
    );
    if (!boundaryReport.passed) {
      throw StateError(
        'Replay storage boundary failed: ${boundaryReport.violations.join(' | ')}',
      );
    }

    final client = SupabaseClient(
      replayUrlValue,
      replayServiceRoleKeyValue,
      postgrestOptions:
          PostgrestClientOptions(schema: ReplayStorageConfig.schema),
    );
    final gateway = _gatewayFactory?.call(
            client: client, schema: ReplayStorageConfig.schema) ??
        ReplaySupabaseStorageGatewayImpl(
          client: client,
          schema: ReplayStorageConfig.schema,
        );

    for (final entry in uploadManifest.entries) {
      final file = File(entry.localPath);
      if (!file.existsSync()) {
        throw StateError('Replay upload source file not found: ${file.path}');
      }
      await gateway.uploadObject(
        bucket: entry.bucket,
        objectPath: entry.objectPath,
        bytes: Uint8List.fromList(file.readAsBytesSync()),
        contentType: _contentTypeForPath(entry.objectPath),
      );
    }

    final runId = _buildRunId(
      environmentId: uploadManifest.environmentId,
      replayYear: uploadManifest.replayYear,
    );
    final indexedTables = <String, int>{};

    Future<void> upsertTable({
      required String table,
      required List<Map<String, dynamic>> rows,
      String? onConflict,
    }) async {
      if (rows.isEmpty) {
        return;
      }
      await gateway.upsertRows(
        table: table,
        rows: rows,
        onConflict: onConflict,
      );
      indexedTables[table] = rows.length;
    }

    await upsertTable(
      table: 'replay_runs',
      rows: <Map<String, dynamic>>[
        _buildRunRow(
          runId: runId,
          uploadManifest: uploadManifest,
          exportManifest: exportManifest,
          partitionManifest: partitionManifest,
        ),
      ],
      onConflict: 'run_id',
    );

    await upsertTable(
      table: 'replay_artifacts',
      rows: _buildArtifactRows(
        runId: runId,
        uploadManifest: uploadManifest,
      ),
      onConflict: 'run_id,artifact_ref',
    );

    await upsertTable(
      table: 'replay_artifact_partitions',
      rows: _buildPartitionRows(
        runId: runId,
        uploadManifest: uploadManifest,
      ),
      onConflict: 'run_id,artifact_ref,section,chunk_index',
    );

    await upsertTable(
      table: 'replay_lineage',
      rows: <Map<String, dynamic>>[
        <String, dynamic>{
          'run_id': runId,
          'environment_id': uploadManifest.environmentId,
          'replay_year': uploadManifest.replayYear,
          'lineage_role': 'single_year_base',
          'source_artifact_ref': '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          'upstream_artifact_refs':
              exportManifest.entries.map((entry) => entry.artifactRef).toList(),
          'metadata': <String, dynamic>{
            'status': uploadManifest.status,
            'partitionedArtifactCount':
                uploadManifest.metadata['partitionedArtifactCount'] ?? 0,
          },
        },
      ],
      onConflict: 'run_id,lineage_role',
    );

    await upsertTable(
      table: 'replay_calibration_reports',
      rows: _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
        targetColumn: 'report_json',
      ),
      onConflict: 'run_id',
    );

    await upsertTable(
      table: 'replay_realism_gate_reports',
      rows: _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
        targetColumn: 'report_json',
      ),
      onConflict: 'run_id',
    );

    await upsertTable(
      table: 'replay_training_exports',
      rows: _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
        targetColumn: 'manifest_json',
      ),
      onConflict: 'run_id',
    );

    await upsertTable(
      table: 'replay_actor_profiles',
      rows: _buildActorProfileRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,actor_id',
    );

    await upsertTable(
      table: 'replay_actor_kernel_bundles',
      rows: _buildActorKernelBundleRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,actor_id',
    );

    await upsertTable(
      table: 'replay_kernel_activation_traces',
      rows: _buildKernelActivationTraceRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,trace_id',
    );

    await upsertTable(
      table: 'replay_actor_connectivity_profiles',
      rows: _buildConnectivityProfileRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,actor_id',
    );

    await upsertTable(
      table: 'replay_actor_connectivity_transitions',
      rows: _buildConnectivityTransitionRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,transition_id',
    );

    await upsertTable(
      table: 'replay_actor_tracked_locations',
      rows: _buildTrackedLocationRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,location_record_id',
    );

    await upsertTable(
      table: 'replay_actor_untracked_windows',
      rows: _buildUntrackedWindowRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,window_id',
    );

    await upsertTable(
      table: 'replay_actor_movements',
      rows: _buildMovementRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,movement_id',
    );

    await upsertTable(
      table: 'replay_actor_flights',
      rows: _buildFlightRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,flight_id',
    );

    await upsertTable(
      table: 'replay_exchange_threads',
      rows: _buildExchangeThreadRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,thread_id',
    );

    await upsertTable(
      table: 'replay_exchange_participations',
      rows: _buildExchangeParticipationRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,actor_id,thread_id',
    );

    await upsertTable(
      table: 'replay_exchange_events',
      rows: _buildExchangeEventRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,event_id',
    );

    await upsertTable(
      table: 'replay_ai2ai_exchange_records',
      rows: _buildAi2AiExchangeRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,record_id',
    );

    await upsertTable(
      table: 'replay_action_training_records',
      rows: _buildActionTrainingRecordRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,record_id',
    );

    await upsertTable(
      table: 'replay_counterfactual_choices',
      rows: _buildCounterfactualChoiceRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,record_id,ordinal_index',
    );

    await upsertTable(
      table: 'replay_outcome_labels',
      rows: _buildOutcomeLabelRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,label_id',
    );

    await upsertTable(
      table: 'replay_truth_decision_history',
      rows: _buildTruthDecisionRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,record_id',
    );

    await upsertTable(
      table: 'replay_higher_agent_intervention_traces',
      rows: _buildHigherAgentInterventionRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,trace_id',
    );

    await upsertTable(
      table: 'replay_run_variation_profiles',
      rows: _buildVariationProfileRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id',
    );

    await upsertTable(
      table: 'replay_holdout_evaluations',
      rows: _buildHoldoutEvaluationRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
      onConflict: 'run_id,metric_id',
    );

    return ReplayStorageUploadManifest(
      environmentId: uploadManifest.environmentId,
      replayYear: uploadManifest.replayYear,
      status: uploadManifest.status,
      dryRun: false,
      projectIsolationMode: uploadManifest.projectIsolationMode,
      replaySchema: uploadManifest.replaySchema,
      entries: uploadManifest.entries,
      notes: <String>[
        ...uploadManifest.notes,
        'Live replay-only Supabase upload/index completed successfully.',
      ],
      metadata: <String, dynamic>{
        ...uploadManifest.metadata,
        'liveUploadAttempted': true,
        'liveUploadSucceeded': true,
        'indexedTables': indexedTables,
        'runId': runId,
        'replayUrl': replayUrlValue,
        'usedServiceRoleKey': replayServiceRoleKeyValue.isNotEmpty,
        'usedAnonKeyFallback': replayServiceRoleKeyValue.isEmpty &&
            replayAnonKey != null &&
            replayAnonKey.isNotEmpty,
      },
    );
  }

  String _buildRunId({
    required String environmentId,
    required int replayYear,
  }) {
    return '${environmentId}_$replayYear';
  }

  void _validateBuildUploadManifestContract({
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
  }) {
    final violations = <String>[
      ..._collectSharedManifestViolations(
        exportEnvironmentId: exportManifest.environmentId,
        exportReplayYear: exportManifest.replayYear,
        partitionEnvironmentId: partitionManifest.environmentId,
        partitionReplayYear: partitionManifest.replayYear,
      ),
      ..._collectExportEntryViolations(exportManifest.entries),
    ];

    final exportArtifactRefs = exportManifest.entries
        .map((entry) => entry.artifactRef.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final orphanPartitionArtifactRefs = partitionManifest.entries
        .map((entry) => entry.artifactRef.trim())
        .where(
          (artifactRef) =>
              artifactRef.isNotEmpty &&
              !exportArtifactRefs.contains(artifactRef),
        )
        .toSet()
        .toList()
      ..sort();
    if (orphanPartitionArtifactRefs.isNotEmpty) {
      violations.add(
        'Replay partition manifest references unknown export artifacts: '
        '${orphanPartitionArtifactRefs.join(', ')}.',
      );
    }

    _throwIfContractViolations(
      stage: 'Replay upload manifest contract failed',
      violations: violations,
    );
  }

  void _validateUploadAndIndexContract({
    required ReplayStorageUploadManifest uploadManifest,
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
  }) {
    final violations = <String>[
      ..._collectSharedManifestViolations(
        exportEnvironmentId: exportManifest.environmentId,
        exportReplayYear: exportManifest.replayYear,
        partitionEnvironmentId: partitionManifest.environmentId,
        partitionReplayYear: partitionManifest.replayYear,
      ),
      ..._collectExportEntryViolations(exportManifest.entries),
    ];

    final uploadEnvironmentId = uploadManifest.environmentId.trim();
    if (uploadEnvironmentId.isEmpty) {
      violations.add('Replay upload manifest environment id may not be empty.');
    }
    final exportEnvironmentId = exportManifest.environmentId.trim();
    final partitionEnvironmentId = partitionManifest.environmentId.trim();
    if (uploadEnvironmentId.isNotEmpty &&
        uploadEnvironmentId != exportEnvironmentId) {
      violations.add(
        'Replay upload manifest environment id must match export manifest '
        'environment id.',
      );
    }
    if (uploadEnvironmentId.isNotEmpty &&
        uploadEnvironmentId != partitionEnvironmentId) {
      violations.add(
        'Replay upload manifest environment id must match partition manifest '
        'environment id.',
      );
    }
    if (uploadManifest.replayYear <= 0) {
      violations.add('Replay upload manifest replay year must be positive.');
    }
    if (uploadManifest.replayYear > 0 &&
        uploadManifest.replayYear != exportManifest.replayYear) {
      violations.add(
        'Replay upload manifest replay year must match export manifest '
        'replay year.',
      );
    }
    if (uploadManifest.replayYear > 0 &&
        uploadManifest.replayYear != partitionManifest.replayYear) {
      violations.add(
        'Replay upload manifest replay year must match partition manifest '
        'replay year.',
      );
    }
    if (uploadManifest.replaySchema.trim().isEmpty) {
      violations.add('Replay upload manifest replay schema may not be empty.');
    }
    violations.addAll(_collectUploadEntryViolations(uploadManifest.entries));

    _throwIfContractViolations(
      stage: 'Replay upload/index contract failed',
      violations: violations,
    );
  }

  List<String> _collectSharedManifestViolations({
    required String exportEnvironmentId,
    required int exportReplayYear,
    required String partitionEnvironmentId,
    required int partitionReplayYear,
  }) {
    final violations = <String>[];
    final normalizedExportEnvironmentId = exportEnvironmentId.trim();
    final normalizedPartitionEnvironmentId = partitionEnvironmentId.trim();
    if (normalizedExportEnvironmentId.isEmpty) {
      violations.add('Replay export manifest environment id may not be empty.');
    }
    if (normalizedPartitionEnvironmentId.isEmpty) {
      violations.add(
        'Replay partition manifest environment id may not be empty.',
      );
    }
    if (normalizedExportEnvironmentId.isNotEmpty &&
        normalizedPartitionEnvironmentId.isNotEmpty &&
        normalizedExportEnvironmentId != normalizedPartitionEnvironmentId) {
      violations.add(
        'Replay export and partition manifests must target the same '
        'environment id.',
      );
    }
    if (exportReplayYear <= 0) {
      violations.add('Replay export manifest replay year must be positive.');
    }
    if (partitionReplayYear <= 0) {
      violations.add('Replay partition manifest replay year must be positive.');
    }
    if (exportReplayYear > 0 &&
        partitionReplayYear > 0 &&
        exportReplayYear != partitionReplayYear) {
      violations.add(
        'Replay export and partition manifests must target the same replay '
        'year.',
      );
    }
    return violations;
  }

  List<String> _collectExportEntryViolations(
    List<ReplayStorageExportEntry> entries,
  ) {
    final violations = <String>[];
    final duplicateArtifactRefs = _findDuplicateKeys(
      entries.map((entry) => entry.artifactRef),
    );
    if (duplicateArtifactRefs.isNotEmpty) {
      violations.add(
        'Replay export manifest contains duplicate artifact refs: '
        '${duplicateArtifactRefs.join(', ')}.',
      );
    }

    for (final entry in entries) {
      final artifactRef = entry.artifactRef.trim();
      final label = artifactRef.isEmpty ? '<empty-artifact-ref>' : artifactRef;
      if (artifactRef.isEmpty) {
        violations
            .add('Replay export entries may not use empty artifact refs.');
      }
      if (entry.bucket.trim().isEmpty) {
        violations.add('Replay export artifact $label must declare a bucket.');
      } else if (!entry.bucket.startsWith('replay-')) {
        violations.add(
          'Replay export artifact $label must target a replay-prefixed '
          'bucket.',
        );
      }
      if (entry.objectPath.trim().isEmpty) {
        violations.add(
          'Replay export artifact $label must declare an object path.',
        );
      }
      if (entry.sourcePath.trim().isEmpty) {
        violations.add(
          'Replay export artifact $label must declare a source path.',
        );
      }
      if (entry.byteSize < 0) {
        violations.add(
          'Replay export artifact $label may not use a negative byte size.',
        );
      }
    }
    return violations;
  }

  List<String> _collectUploadEntryViolations(
    List<ReplayStorageUploadEntry> entries,
  ) {
    final violations = <String>[];
    final duplicateObjectTargets = _findDuplicateKeys(
      entries
          .map((entry) => '${entry.bucket.trim()}:${entry.objectPath.trim()}'),
    );
    if (duplicateObjectTargets.isNotEmpty) {
      violations.add(
        'Replay upload manifest contains duplicate bucket/object targets: '
        '${duplicateObjectTargets.join(', ')}.',
      );
    }

    for (final entry in entries) {
      final artifactRef = entry.artifactRef.trim();
      final label = artifactRef.isEmpty ? '<empty-artifact-ref>' : artifactRef;
      if (artifactRef.isEmpty) {
        violations
            .add('Replay upload entries may not use empty artifact refs.');
      }
      if (entry.bucket.trim().isEmpty) {
        violations.add('Replay upload artifact $label must declare a bucket.');
      } else if (!entry.bucket.startsWith('replay-')) {
        violations.add(
          'Replay upload artifact $label must target a replay-prefixed bucket.',
        );
      }
      if (entry.objectPath.trim().isEmpty) {
        violations.add(
          'Replay upload artifact $label must declare an object path.',
        );
      }
      if (entry.localPath.trim().isEmpty) {
        violations.add(
          'Replay upload artifact $label must declare a local path.',
        );
      }
      if (entry.byteSize < 0) {
        violations.add(
          'Replay upload artifact $label may not use a negative byte size.',
        );
      }
    }
    return violations;
  }

  List<String> _findDuplicateKeys(Iterable<String> values) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final rawValue in values) {
      final normalizedValue = rawValue.trim();
      if (normalizedValue.isEmpty) {
        continue;
      }
      if (!seen.add(normalizedValue)) {
        duplicates.add(normalizedValue);
      }
    }
    return duplicates.toList()..sort();
  }

  void _throwIfContractViolations({
    required String stage,
    required List<String> violations,
  }) {
    if (violations.isEmpty) {
      return;
    }
    throw StateError('$stage: ${violations.join(' | ')}');
  }

  Map<String, dynamic> _buildRunRow({
    required String runId,
    required ReplayStorageUploadManifest uploadManifest,
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
  }) {
    return <String, dynamic>{
      'run_id': runId,
      'environment_id': uploadManifest.environmentId,
      'replay_year': uploadManifest.replayYear,
      'status': uploadManifest.status,
      'export_root': exportManifest.exportRoot,
      'partition_root': partitionManifest.partitionRoot,
      'project_isolation_mode': uploadManifest.projectIsolationMode,
      'replay_schema': uploadManifest.replaySchema,
      'artifact_count': exportManifest.entries.length,
      'partition_entry_count': partitionManifest.entries.length,
      'total_bytes': uploadManifest.totalBytes,
      'metadata': <String, dynamic>{
        ...uploadManifest.metadata,
        'dryRun': uploadManifest.dryRun,
      },
    };
  }

  List<Map<String, dynamic>> _buildArtifactRows({
    required String runId,
    required ReplayStorageUploadManifest uploadManifest,
  }) {
    final grouped = <String, List<ReplayStorageUploadEntry>>{};
    for (final entry in uploadManifest.entries) {
      grouped
          .putIfAbsent(entry.artifactRef, () => <ReplayStorageUploadEntry>[])
          .add(entry);
    }

    return grouped.entries.map((group) {
      final first = group.value.first;
      final partitionCount = group.value.length;
      final representation = group.value.any(
        (entry) => entry.representation == 'partitioned_ndjson',
      )
          ? 'partitioned_ndjson'
          : 'single_object';
      final primaryObjectPath = representation == 'single_object'
          ? first.objectPath
          : p.dirname(first.objectPath);

      return <String, dynamic>{
        'run_id': runId,
        'artifact_ref': group.key,
        'bucket_id': first.bucket,
        'object_path': primaryObjectPath,
        'representation': representation,
        'byte_size':
            group.value.fold<int>(0, (sum, entry) => sum + entry.byteSize),
        'partition_count':
            representation == 'partitioned_ndjson' ? partitionCount : 0,
        'metadata': <String, dynamic>{
          'sections': group.value
              .map((entry) => entry.section)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort(),
        },
      };
    }).toList()
      ..sort(
        (a, b) => (a['artifact_ref'] as String)
            .compareTo(b['artifact_ref'] as String),
      );
  }

  List<Map<String, dynamic>> _buildPartitionRows({
    required String runId,
    required ReplayStorageUploadManifest uploadManifest,
  }) {
    return uploadManifest.entries
        .where((entry) => entry.representation == 'partitioned_ndjson')
        .map(
          (entry) => <String, dynamic>{
            'run_id': runId,
            'artifact_ref': entry.artifactRef,
            'section': entry.section,
            'chunk_index': entry.chunkIndex,
            'bucket_id': entry.bucket,
            'object_path': entry.objectPath,
            'record_count': entry.recordCount,
            'byte_size': entry.byteSize,
          },
        )
        .toList()
      ..sort((a, b) {
        final artifactCompare = (a['artifact_ref'] as String)
            .compareTo(b['artifact_ref'] as String);
        if (artifactCompare != 0) {
          return artifactCompare;
        }
        final sectionCompare =
            (a['section'] as String).compareTo(b['section'] as String);
        if (sectionCompare != 0) {
          return sectionCompare;
        }
        return (a['chunk_index'] as int).compareTo(b['chunk_index'] as int);
      });
  }

  List<Map<String, dynamic>> _buildSingleArtifactReportRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
    required String artifactRef,
    required String targetColumn,
  }) {
    ReplayStorageExportEntry? entry;
    for (final candidate in exportManifest.entries) {
      if (candidate.artifactRef == artifactRef) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      return const <Map<String, dynamic>>[];
    }
    final file = File(
        '${exportManifest.exportRoot}/${entry.bucket}/${entry.objectPath}');
    if (!file.existsSync()) {
      return const <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'run_id': runId,
        'artifact_ref': artifactRef,
        targetColumn: decoded,
      },
    ];
  }

  Map<String, int> _buildPlannedIndexedTableCounts({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final planned = <String, int>{
      'replay_runs': 1,
      'replay_artifacts': exportManifest.entries.length,
      'replay_lineage': 1,
    };

    void addCount(String table, List<Map<String, dynamic>> rows) {
      if (rows.isNotEmpty) {
        planned[table] = rows.length;
      }
    }

    addCount(
      'replay_calibration_reports',
      _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
        targetColumn: 'report_json',
      ),
    );
    addCount(
      'replay_realism_gate_reports',
      _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
        targetColumn: 'report_json',
      ),
    );
    addCount(
      'replay_training_exports',
      _buildSingleArtifactReportRows(
        runId: runId,
        exportManifest: exportManifest,
        artifactRef: '58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
        targetColumn: 'manifest_json',
      ),
    );
    addCount(
      'replay_actor_profiles',
      _buildActorProfileRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_actor_kernel_bundles',
      _buildActorKernelBundleRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_kernel_activation_traces',
      _buildKernelActivationTraceRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_actor_connectivity_profiles',
      _buildConnectivityProfileRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_actor_connectivity_transitions',
      _buildConnectivityTransitionRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_actor_tracked_locations',
      _buildTrackedLocationRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_actor_untracked_windows',
      _buildUntrackedWindowRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_actor_movements',
      _buildMovementRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_actor_flights',
      _buildFlightRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_exchange_threads',
      _buildExchangeThreadRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_exchange_participations',
      _buildExchangeParticipationRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_exchange_events',
      _buildExchangeEventRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_ai2ai_exchange_records',
      _buildAi2AiExchangeRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_action_training_records',
      _buildActionTrainingRecordRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_counterfactual_choices',
      _buildCounterfactualChoiceRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_outcome_labels',
      _buildOutcomeLabelRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_truth_decision_history',
      _buildTruthDecisionRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_higher_agent_intervention_traces',
      _buildHigherAgentInterventionRows(
        runId: runId,
        exportManifest: exportManifest,
      ),
    );
    addCount(
      'replay_run_variation_profiles',
      _buildVariationProfileRows(runId: runId, exportManifest: exportManifest),
    );
    addCount(
      'replay_holdout_evaluations',
      _buildHoldoutEvaluationRows(runId: runId, exportManifest: exportManifest),
    );

    return planned;
  }

  Map<String, dynamic>? _readArtifactMap({
    required ReplayStorageExportManifest exportManifest,
    required String artifactRef,
  }) {
    final decoded = _readArtifactJson(
      exportManifest: exportManifest,
      artifactRef: artifactRef,
    );
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Object? _readArtifactJson({
    required ReplayStorageExportManifest exportManifest,
    required String artifactRef,
  }) {
    ReplayStorageExportEntry? entry;
    for (final candidate in exportManifest.entries) {
      if (candidate.artifactRef == artifactRef) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      return null;
    }
    final file = File(
        '${exportManifest.exportRoot}/${entry.bucket}/${entry.objectPath}');
    if (!file.existsSync()) {
      return null;
    }
    return jsonDecode(file.readAsStringSync());
  }

  List<Map<String, dynamic>> _buildActorProfileRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final profile = ReplayPopulationProfile.fromJson(artifact);
    return profile.actors
        .map(
          (actor) => <String, dynamic>{
            'run_id': runId,
            'actor_id': actor.actorId,
            'locality_anchor': actor.localityAnchor,
            'represented_population_count': actor.representedPopulationCount,
            'population_role': actor.populationRole.name,
            'lifecycle_state': actor.lifecycleState.name,
            'age_band': actor.ageBand,
            'life_stage': actor.lifeStage,
            'household_type': actor.householdType,
            'work_student_status': actor.workStudentStatus,
            'has_personal_agent': actor.hasPersonalAgent,
            'preferred_entity_types': actor.preferredEntityTypes,
            'kernel_bundle_json':
                actor.kernelBundle?.toJson() ?? const <String, dynamic>{},
            'metadata': actor.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildActorKernelBundleRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayActorKernelCoverageReport.fromJson(artifact);
    return report.records
        .map(
          (record) => <String, dynamic>{
            'run_id': runId,
            'actor_id': record.actorId,
            'locality_anchor': record.localityAnchor,
            'has_full_bundle': record.hasFullBundle,
            'attached_kernel_ids': record.attachedKernelIds,
            'ready_kernel_ids': record.readyKernelIds,
            'activation_count_by_kernel': record.activationCountByKernel,
            'higher_agent_guidance_count': record.higherAgentGuidanceCount,
            'metadata': record.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildKernelActivationTraceRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayActorKernelCoverageReport.fromJson(artifact);
    return report.traces
        .map(
          (trace) => <String, dynamic>{
            'run_id': runId,
            'trace_id': trace.traceId,
            'actor_id': trace.actorId,
            'context_type': trace.contextType,
            'context_id': trace.contextId,
            'activated_kernel_ids': trace.activatedKernelIds,
            'higher_agent_guidance_ids': trace.higherAgentGuidanceIds,
            'metadata': trace.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildConnectivityProfileRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactJson(
      exportManifest: exportManifest,
      artifactRef: '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final profiles = _readConnectivityProfiles(artifact);
    return profiles
        .map(
          (profile) => <String, dynamic>{
            'run_id': runId,
            'actor_id': profile.actorId,
            'locality_anchor': profile.localityAnchor,
            'dominant_mode': profile.dominantMode.name,
            'device_profile_json': profile.deviceProfile.toJson(),
            'metadata': profile.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildConnectivityTransitionRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactJson(
      exportManifest: exportManifest,
      artifactRef: '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final profiles = _readConnectivityProfiles(artifact);
    return profiles
        .expand(
          (profile) => profile.transitions.map(
            (transition) => <String, dynamic>{
              'run_id': runId,
              'transition_id': transition.transitionId,
              'actor_id': profile.actorId,
              'schedule_surface': transition.scheduleSurface,
              'window_label': transition.windowLabel,
              'locality_anchor': transition.localityAnchor,
              'mode': transition.mode.name,
              'reachable': transition.reachable,
              'reason': transition.reason,
              'metadata': transition.metadata,
            },
          ),
        )
        .toList(growable: false);
  }

  List<ReplayConnectivityProfile> _readConnectivityProfiles(Object artifact) {
    final rawEntries = artifact is List
        ? artifact
        : (artifact is Map
            ? artifact['profiles'] as List? ?? const <dynamic>[]
            : const <dynamic>[]);
    return rawEntries
        .whereType<Map>()
        .map(
          (entry) => ReplayConnectivityProfile.fromJson(
              Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildTrackedLocationRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayPhysicalMovementReport.fromJson(artifact);
    return report.trackedLocations
        .map(
          (record) => <String, dynamic>{
            'run_id': runId,
            'location_record_id': record.locationRecordId,
            'actor_id': record.actorId,
            'month_key': record.monthKey,
            'locality_anchor': record.localityAnchor,
            'tracking_state': record.trackingState.name,
            'location_kind': record.locationKind,
            'physical_ref': record.physicalRef,
            'entity_id': record.entityId,
            'entity_type': record.entityType,
            'place_node_id': record.placeNodeId,
            'reason': record.reason,
            'metadata': record.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildUntrackedWindowRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayPhysicalMovementReport.fromJson(artifact);
    return report.untrackedWindows
        .map(
          (window) => <String, dynamic>{
            'run_id': runId,
            'window_id': window.windowId,
            'actor_id': window.actorId,
            'month_key': window.monthKey,
            'locality_anchor': window.localityAnchor,
            'window_label': window.windowLabel,
            'reason': window.reason,
            'metadata': window.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildMovementRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayPhysicalMovementReport.fromJson(artifact);
    return report.movements
        .map(
          (movement) => <String, dynamic>{
            'run_id': runId,
            'movement_id': movement.movementId,
            'actor_id': movement.actorId,
            'month_key': movement.monthKey,
            'origin_physical_ref': movement.originPhysicalRef,
            'destination_physical_ref': movement.destinationPhysicalRef,
            'origin_locality_anchor': movement.originLocalityAnchor,
            'destination_locality_anchor': movement.destinationLocalityAnchor,
            'mode': movement.mode.name,
            'tracked': movement.tracked,
            'source_action_id': movement.sourceActionId,
            'metadata': movement.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildFlightRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    final report = ReplayPhysicalMovementReport.fromJson(artifact);
    return report.flights
        .map(
          (flight) => <String, dynamic>{
            'run_id': runId,
            'flight_id': flight.flightId,
            'actor_id': flight.actorId,
            'month_key': flight.monthKey,
            'airport_node_id': flight.airportNodeId,
            'airport_physical_ref': flight.airportPhysicalRef,
            'destination_region': flight.destinationRegion,
            'reason': flight.reason,
            'source_action_id': flight.sourceActionId,
            'metadata': flight.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildExchangeThreadRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    return (artifact['threads'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) =>
              ReplayExchangeThread.fromJson(Map<String, dynamic>.from(entry)),
        )
        .map(
          (thread) => <String, dynamic>{
            'run_id': runId,
            'thread_id': thread.threadId,
            'kind': thread.kind.name,
            'locality_anchor': thread.localityAnchor,
            'associated_entity_id': thread.associatedEntityId,
            'participant_actor_ids': thread.participantActorIds,
            'metadata': thread.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildExchangeParticipationRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    return (artifact['participations'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) => ReplayExchangeParticipation.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .map(
          (participation) => <String, dynamic>{
            'run_id': runId,
            'actor_id': participation.actorId,
            'thread_id': participation.threadId,
            'participation_state': participation.participationState,
            'access_granted': participation.accessGranted,
            'message_count': participation.messageCount,
            'metadata': participation.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildExchangeEventRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    return (artifact['events'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) =>
              ReplayExchangeEvent.fromJson(Map<String, dynamic>.from(entry)),
        )
        .map(
          (event) => <String, dynamic>{
            'run_id': runId,
            'event_id': event.eventId,
            'thread_id': event.threadId,
            'kind': event.kind.name,
            'month_key': event.monthKey,
            'locality_anchor': event.localityAnchor,
            'sender_actor_id': event.senderActorId,
            'recipient_actor_ids': event.recipientActorIds,
            'interaction_type': event.interactionType,
            'connectivity_receipt_json': event.connectivityReceipt.toJson(),
            'activated_kernel_ids': event.activatedKernelIds,
            'higher_agent_guidance_ids': event.higherAgentGuidanceIds,
            'metadata': event.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildAi2AiExchangeRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    );
    if (artifact == null) {
      return const <Map<String, dynamic>>[];
    }
    return (artifact['ai2aiRecords'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) => ReplayAi2AiExchangeRecord.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .map(
          (record) => <String, dynamic>{
            'run_id': runId,
            'record_id': record.recordId,
            'actor_id': record.actorId,
            'thread_id': record.threadId,
            'month_key': record.monthKey,
            'locality_anchor': record.localityAnchor,
            'route_mode': record.routeMode.name,
            'status': record.status,
            'queued_offline': record.queuedOffline,
            'metadata': record.metadata,
          },
        )
        .toList(growable: false);
  }

  BhamReplayActionTrainingBundle? _readTrainingBundle({
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json',
    );
    if (artifact == null) {
      return null;
    }
    return BhamReplayActionTrainingBundle.fromJson(artifact);
  }

  ReplayHoldoutEvaluationReport? _readHoldoutReport({
    required ReplayStorageExportManifest exportManifest,
  }) {
    final artifact = _readArtifactMap(
      exportManifest: exportManifest,
      artifactRef: '69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json',
    );
    if (artifact == null) {
      return null;
    }
    return ReplayHoldoutEvaluationReport.fromJson(artifact);
  }

  List<Map<String, dynamic>> _buildActionTrainingRecordRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    return bundle.records
        .map(
          (record) => <String, dynamic>{
            'run_id': runId,
            'record_id': record.recordId,
            'actor_id': record.actorId,
            'kind': record.kind.name,
            'context_window': record.contextWindow,
            'context_id': record.contextId,
            'month_key': record.monthKey,
            'locality_anchor': record.localityAnchor,
            'chosen_id': record.chosenId,
            'chosen_type': record.chosenType,
            'outcome_ref': record.outcomeRef,
            'source_provenance_refs': record.sourceProvenanceRefs,
            'confidence': record.confidence,
            'uncertainty': record.uncertainty,
            'active_kernel_ids': record.activeKernelIds,
            'higher_agent_guidance_ids': record.higherAgentGuidanceIds,
            'governance_disposition': record.governanceDisposition,
            'metadata': record.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildCounterfactualChoiceRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    final rows = <Map<String, dynamic>>[];
    for (final record in bundle.records) {
      for (var index = 0; index < record.counterfactuals.length; index++) {
        final candidate = record.counterfactuals[index];
        rows.add(
          <String, dynamic>{
            'run_id': runId,
            'record_id': record.recordId,
            'ordinal_index': index,
            'candidate_id': candidate.candidateId,
            'candidate_type': candidate.candidateType,
            'score': candidate.score,
            'confidence': candidate.confidence,
            'rejection_reason': candidate.rejectionReason,
            'blocking_lane': candidate.blockingLane,
            'metadata': candidate.metadata,
          },
        );
      }
    }
    return rows;
  }

  List<Map<String, dynamic>> _buildOutcomeLabelRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    return bundle.outcomeLabels
        .map(
          (label) => <String, dynamic>{
            'run_id': runId,
            'label_id': label.labelId,
            'actor_id': label.actorId,
            'context_id': label.contextId,
            'context_type': label.contextType,
            'month_key': label.monthKey,
            'outcome_kind': label.outcomeKind,
            'outcome_value': label.outcomeValue,
            'metadata': label.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildTruthDecisionRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    return bundle.truthDecisionRecords
        .map(
          (record) => <String, dynamic>{
            'run_id': runId,
            'record_id': record.recordId,
            'subject_id': record.subjectId,
            'subject_type': record.subjectType,
            'month_key': record.monthKey,
            'locality_anchor': record.localityAnchor,
            'decision_kind': record.decisionKind,
            'decision_status': record.decisionStatus,
            'reason': record.reason,
            'source_refs': record.sourceRefs,
            'metadata': record.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildHigherAgentInterventionRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    return bundle.higherAgentInterventionTraces
        .map(
          (trace) => <String, dynamic>{
            'run_id': runId,
            'trace_id': trace.traceId,
            'actor_id': trace.actorId,
            'action_record_id': trace.actionRecordId,
            'locality_anchor': trace.localityAnchor,
            'month_key': trace.monthKey,
            'guidance_state': trace.guidanceState,
            'guidance_ids': trace.guidanceIds,
            'reason': trace.reason,
            'metadata': trace.metadata,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildVariationProfileRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final bundle = _readTrainingBundle(exportManifest: exportManifest);
    if (bundle == null) {
      return const <Map<String, dynamic>>[];
    }
    final profile = bundle.variationProfile;
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'run_id': runId,
        'environment_id': profile.environmentId,
        'replay_year': profile.replayYear,
        'run_config_json': profile.runConfig.toJson(),
        'same_seed_reproducible': profile.sameSeedReproducible,
        'untracked_window_count': profile.untrackedWindowCount,
        'offline_queued_count': profile.offlineQueuedCount,
        'attendance_variation_count': profile.attendanceVariationCount,
        'connectivity_variation_count': profile.connectivityVariationCount,
        'route_variation_count': profile.routeVariationCount,
        'exchange_timing_variation_count': profile.exchangeTimingVariationCount,
        'month_variation_counts': profile.monthVariationCounts,
        'notes': profile.notes,
        'metadata': profile.metadata,
      },
    ];
  }

  List<Map<String, dynamic>> _buildHoldoutEvaluationRows({
    required String runId,
    required ReplayStorageExportManifest exportManifest,
  }) {
    final report = _readHoldoutReport(exportManifest: exportManifest);
    if (report == null) {
      return const <Map<String, dynamic>>[];
    }
    return report.metrics
        .map(
          (metric) => <String, dynamic>{
            'run_id': runId,
            'metric_id': metric.metricId,
            'environment_id': report.environmentId,
            'replay_year': report.replayYear,
            'metric_name': metric.metricName,
            'training_value': metric.trainingValue,
            'validation_value': metric.validationValue,
            'holdout_value': metric.holdoutValue,
            'threshold': metric.threshold,
            'passed': metric.passed,
            'metadata': <String, dynamic>{
              ...metric.metadata,
              'trainingMonths': report.trainingMonths,
              'validationMonths': report.validationMonths,
              'holdoutMonths': report.holdoutMonths,
              'reportPassed': report.passed,
            },
          },
        )
        .toList(growable: false);
  }

  String _contentTypeForPath(String objectPath) {
    if (objectPath.endsWith('.ndjson')) {
      return 'application/x-ndjson';
    }
    if (objectPath.endsWith('.json')) {
      return 'application/json';
    }
    return 'application/octet-stream';
  }
}
