import 'dart:convert';
import 'dart:io';

const List<String> _requiredBundleFiles = <String>[
  'manifest.json',
  'ledger_rows.csv',
  'ledger_rows.jsonl',
  'background_wake_runs.json',
  'field_validation_proofs.json',
  'ambient_social_diagnostics.json',
];

const Set<String> _supportedScenarioProfiles = <String>{
  'baseline',
  'duplicate_wake_delivery',
  'restart_mid_headless_run',
  'trusted_route_unavailable_deferred',
  'multi_peer_single_confirmation',
};

const Set<String> _requiredWakeReasons = <String>{
  'ble_encounter',
  'trusted_announce_refresh',
  'significant_location',
  'background_task_window',
};

const Set<String> _requiredFieldScenarios = <String>{
  'trustedDirectAnnounceRecovery',
  'untrustedAnnounceRejected',
  'deferredRendezvousBlockedByTrustedRouteUnavailable',
  'trustedHeardForwardRoutable',
  'trustedRelayRefreshRoutable',
  'deferredExchangePeerTruthAfterRelease',
  'ambientPassiveNearbyCandidateOnly',
  'ambientTrustedInteractionPromotesConfirmedPresence',
  'ambientDuplicateEvidenceMerged',
  'ambientUntrustedInteractionNotPromoted',
};

const List<String> _requiredBackgroundRunKeys = <String>[
  'reason',
  'platform_source',
  'wake_timestamp_utc',
  'started_at_utc',
  'completed_at_utc',
  'bootstrap_success',
  'mesh_due_replay_count',
  'ai2ai_released_count',
  'passive_ingested_dwell_event_count',
  'ambient_candidate_observation_delta_count',
  'ambient_confirmed_promotion_delta_count',
  'segment_refresh_count',
];

const List<String> _requiredAmbientKeys = <String>[
  'captured_at_utc',
  'normalized_observation_count',
  'candidate_copresence_observation_count',
  'confirmed_interaction_promotion_count',
  'duplicate_merge_count',
  'rejected_interaction_promotion_count',
  'crowd_upgrade_count',
  'what_ingestion_count',
  'locality_vibe_update_count',
  'personal_dna_authorized_count',
  'personal_dna_applied_count',
  'latest_nearby_peer_count',
  'latest_confirmed_interactive_peer_count',
  'last_promotion_trace',
  'recent_promotion_traces',
];

const List<String> _requiredPromotionTraceKeys = <String>[
  'locality_stable_key',
  'source_kinds',
  'discovered_peer_ids',
  'confirmed_interactive_peer_ids',
  'social_context',
  'place_vibe_label',
  'lineage_refs',
  'promoted_at_utc',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run work/tools/validate_simulated_smoke_bundle.dart '
      '<bundle_dir> [--summary-path=/path/to/summary.json]',
    );
    exitCode = 64;
    return;
  }

  final bundleDir = Directory(args.first);
  String? summaryPath;
  for (final arg in args.skip(1)) {
    if (arg.startsWith('--summary-path=')) {
      summaryPath = arg.substring('--summary-path='.length);
    }
  }

  final result = _validateBundle(bundleDir);
  final encoded = const JsonEncoder.withIndent('  ').convert(result);
  if (summaryPath != null && summaryPath.isNotEmpty) {
    final summaryFile = File(summaryPath);
    await summaryFile.parent.create(recursive: true);
    await summaryFile.writeAsString(encoded);
  }
  stdout.writeln(encoded);
  if (result['is_valid'] != true) {
    exitCode = 1;
  }
}

Map<String, Object?> _validateBundle(Directory bundleDir) {
  final errors = <String>[];
  final warnings = <String>[];

  if (!bundleDir.existsSync()) {
    errors.add('Bundle directory does not exist: ${bundleDir.path}');
    return <String, Object?>{
      'is_valid': false,
      'bundle_dir': bundleDir.path,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final files = <String, File>{
    for (final name in _requiredBundleFiles)
      name: File('${bundleDir.path}/$name'),
  };
  for (final entry in files.entries) {
    if (!entry.value.existsSync()) {
      errors.add('Missing required file: ${entry.key}');
    }
  }
  if (errors.isNotEmpty) {
    return <String, Object?>{
      'is_valid': false,
      'bundle_dir': bundleDir.path,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final manifest =
      _readJsonMap(files['manifest.json']!, errors, label: 'manifest.json');
  final background = _readJsonMap(files['background_wake_runs.json']!, errors,
      label: 'background_wake_runs.json');
  final fieldProofs = _readJsonMap(
      files['field_validation_proofs.json']!, errors,
      label: 'field_validation_proofs.json');
  final ambient = _readJsonMap(
    files['ambient_social_diagnostics.json']!,
    errors,
    label: 'ambient_social_diagnostics.json',
  );

  if (manifest != null) {
    if (manifest['artifact_kind'] != 'simulated_headless_smoke') {
      errors
          .add('manifest.json artifact_kind must be simulated_headless_smoke');
    }
    if (manifest['simulated'] != true) {
      errors.add('manifest.json must label the run as simulated');
    }
    final platform = manifest['platform']?.toString() ?? '';
    if (!platform.endsWith('_simulator')) {
      errors.add('manifest.json platform must end with _simulator');
    }
    final scenarioProfile = manifest['scenario_profile']?.toString() ?? '';
    if (scenarioProfile.isEmpty) {
      errors.add('manifest.json must include scenario_profile');
    } else if (!_supportedScenarioProfiles.contains(scenarioProfile)) {
      errors.add(
        'manifest.json scenario_profile must be one of '
        '${_supportedScenarioProfiles.toList()..sort()}',
      );
    }
    final timestampUtc = manifest['timestamp_utc']?.toString() ?? '';
    if (timestampUtc.isEmpty) {
      errors.add('manifest.json must include timestamp_utc');
    } else if (DateTime.tryParse(timestampUtc) == null) {
      errors.add('manifest.json timestamp_utc must be an ISO-8601 timestamp');
    }
    final notes = manifest['notes']?.toString().toLowerCase() ?? '';
    if (!notes.contains('simulated')) {
      errors.add(
          'manifest.json notes must explicitly describe simulated coverage');
    }
  }

  if (background != null) {
    final runs =
        _readList(background['runs'], 'background_wake_runs.json.runs', errors);
    if (runs.isEmpty) {
      errors.add('background_wake_runs.json must contain at least one run');
    } else {
      final wakeReasons = <String>{};
      for (final run in runs) {
        final runMap = _asMap(run, 'background wake run', errors);
        if (runMap == null) {
          continue;
        }
        wakeReasons.add(runMap['reason']?.toString() ?? '');
        for (final key in _requiredBackgroundRunKeys) {
          if (!runMap.containsKey(key)) {
            errors.add('background wake run missing required key: $key');
          }
        }
      }
      final missingReasons = _requiredWakeReasons.difference(wakeReasons);
      if (missingReasons.isNotEmpty) {
        errors.add(
          'background_wake_runs.json missing required simulated wake reasons: '
          '${missingReasons.toList()..sort()}',
        );
      }
    }
  }

  if (fieldProofs != null) {
    final proofs = _readList(
        fieldProofs['proofs'], 'field_validation_proofs.json.proofs', errors);
    final scenarioNames = <String>{};
    for (final proof in proofs) {
      final proofMap = _asMap(proof, 'field validation proof', errors);
      if (proofMap == null) {
        continue;
      }
      final scenario = proofMap['scenario']?.toString();
      if (scenario != null && scenario.isNotEmpty) {
        scenarioNames.add(scenario);
      }
    }
    final missingScenarios = _requiredFieldScenarios.difference(scenarioNames);
    if (missingScenarios.isNotEmpty) {
      errors.add(
        'field_validation_proofs.json missing required scenarios: '
        '${missingScenarios.toList()..sort()}',
      );
    }
  }

  if (ambient != null) {
    for (final key in _requiredAmbientKeys) {
      if (!ambient.containsKey(key)) {
        errors
            .add('ambient_social_diagnostics.json missing required key: $key');
      }
    }
    final trace = ambient['last_promotion_trace'];
    if (trace is! Map) {
      errors.add(
          'ambient_social_diagnostics.json.last_promotion_trace must be present');
    } else {
      final traceMap = Map<String, dynamic>.from(trace);
      for (final key in _requiredPromotionTraceKeys) {
        if (!traceMap.containsKey(key)) {
          errors.add(
              'ambient_social_diagnostics.json.last_promotion_trace missing key: $key');
        }
      }
    }
  }

  final ledgerEvents = _readJsonLines(files['ledger_rows.jsonl']!, errors);
  final ledgerEventTypes = ledgerEvents
      .map((entry) => entry['event_type']?.toString() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toSet();
  if (!ledgerEventTypes.contains('proof_run_started')) {
    errors.add('ledger_rows.jsonl must contain proof_run_started');
  }
  if (!ledgerEventTypes.contains('proof_run_finished')) {
    errors.add('ledger_rows.jsonl must contain proof_run_finished');
  }

  return <String, Object?>{
    'is_valid': errors.isEmpty,
    'bundle_dir': bundleDir.path,
    'errors': errors,
    'warnings': warnings,
    'summary': <String, Object?>{
      'artifact_kind': manifest?['artifact_kind'],
      'run_id': manifest?['run_id'],
      'platform': manifest?['platform'],
      'scenario_profile': manifest?['scenario_profile'],
      'timestamp_utc': manifest?['timestamp_utc'],
      'smoke_response_success': manifest?['smoke_response_success'],
      'background_wake_run_count': (background?['runs'] as List?)?.length ?? 0,
      'field_validation_proof_count':
          (fieldProofs?['proofs'] as List?)?.length ?? 0,
      'ambient_candidate_count':
          ambient?['candidate_copresence_observation_count'],
      'ambient_confirmed_count':
          ambient?['confirmed_interaction_promotion_count'],
      'ambient_duplicate_merge_count': ambient?['duplicate_merge_count'],
      'ambient_rejected_promotion_count':
          ambient?['rejected_interaction_promotion_count'],
    },
  };
}

Map<String, dynamic>? _readJsonMap(
  File file,
  List<String> errors, {
  required String label,
}) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      errors.add('$label must decode to a JSON object');
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  } catch (error) {
    errors.add('Failed to parse $label: $error');
    return null;
  }
}

List<dynamic> _readList(
  Object? value,
  String label,
  List<String> errors,
) {
  if (value is List) {
    return value;
  }
  errors.add('$label must be a JSON list');
  return const <dynamic>[];
}

Map<String, dynamic>? _asMap(
  Object? value,
  String label,
  List<String> errors,
) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  errors.add('$label must be a JSON object');
  return null;
}

List<Map<String, dynamic>> _readJsonLines(File file, List<String> errors) {
  final lines = file.readAsLinesSync();
  final decoded = <Map<String, dynamic>>[];
  for (final line in lines) {
    if (line.trim().isEmpty) {
      continue;
    }
    try {
      final entry = jsonDecode(line);
      if (entry is Map) {
        decoded.add(Map<String, dynamic>.from(entry));
      } else {
        errors.add('ledger_rows.jsonl contained a non-object row');
      }
    } catch (error) {
      errors.add('Failed to parse ledger_rows.jsonl row: $error');
    }
  }
  return decoded;
}
