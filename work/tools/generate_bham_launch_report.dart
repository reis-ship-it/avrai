import 'dart:convert';
import 'dart:io';

const _defaultInputPath = 'runtime_exports/bham_launch_snapshot.json';
const _defaultMarkdownOutPath =
    'work/reports/bham_launch/launch_gate_report.md';
const _defaultJsonOutPath = 'work/reports/bham_launch/launch_gate_report.json';
const _staleAfter = Duration(hours: 24);

void main(List<String> args) {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final snapshot = _loadSnapshot(inputPath);
  final validationErrors = _validateSnapshot(snapshot);
  if (validationErrors.isNotEmpty) {
    stderr.writeln('BHAM launch snapshot is invalid:');
    for (final error in validationErrors) {
      stderr.writeln('- $error');
    }
    exit(1);
  }

  final markdown = _buildMarkdown(snapshot);
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(snapshot);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

Map<String, dynamic> _loadSnapshot(String inputPath) {
  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Missing launch snapshot: $inputPath');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('Launch snapshot is empty: $inputPath');
    exit(1);
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    stderr.writeln('Launch snapshot must be a JSON object.');
    exit(1);
  }
  return decoded.map((key, value) => MapEntry('$key', value));
}

List<String> _validateSnapshot(Map<String, dynamic> snapshot) {
  final errors = <String>[];
  const requiredTopLevel = <String>[
    'generated_at_utc',
    'status',
    'evidence_snapshot',
    'fallback_states',
    'critical_flow_checks',
    'expansion_gates',
    'unresolved_blockers',
  ];
  for (final key in requiredTopLevel) {
    if (!snapshot.containsKey(key)) {
      errors.add('Missing required top-level field: $key');
    }
  }
  final generatedAt =
      DateTime.tryParse(snapshot['generated_at_utc'] as String? ?? '')?.toUtc();
  if (generatedAt == null) {
    errors.add('generated_at_utc is missing or invalid.');
  } else if (DateTime.now().toUtc().difference(generatedAt) > _staleAfter) {
    errors.add(
      'generated_at_utc is older than ${_staleAfter.inHours} hours and is stale.',
    );
  }

  final evidence = snapshot['evidence_snapshot'];
  if (evidence is! Map) {
    errors.add('evidence_snapshot must be an object.');
  } else {
    const requiredEvidence = <String>[
      'generated_at_utc',
      'admin_availability',
      'route_delivery_health',
      'moderation_queue_health',
      'quarantine_count',
      'break_glass_count',
      'platform_health',
      'manual_evidence_slots',
    ];
    for (final key in requiredEvidence) {
      if (!evidence.containsKey(key)) {
        errors.add('evidence_snapshot is missing $key');
      }
    }
  }

  if (snapshot['fallback_states'] is! List) {
    errors.add('fallback_states must be a list.');
  }
  if (snapshot['critical_flow_checks'] is! List) {
    errors.add('critical_flow_checks must be a list.');
  }
  if (snapshot['expansion_gates'] is! List) {
    errors.add('expansion_gates must be a list.');
  }
  if (snapshot['unresolved_blockers'] is! List) {
    errors.add('unresolved_blockers must be a list.');
  }
  return errors;
}

String _buildMarkdown(Map<String, dynamic> snapshot) {
  final evidence =
      Map<String, dynamic>.from(snapshot['evidence_snapshot'] as Map);
  final blockers =
      List<String>.from(snapshot['unresolved_blockers'] as List? ?? const []);
  final fallbackStates = List<Map<String, dynamic>>.from(
    (snapshot['fallback_states'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value))),
  );
  final flows = List<Map<String, dynamic>>.from(
    (snapshot['critical_flow_checks'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value))),
  );
  final expansionGates = List<Map<String, dynamic>>.from(
    (snapshot['expansion_gates'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value))),
  );
  final manualEvidence = List<Map<String, dynamic>>.from(
    (evidence['manual_evidence_slots'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value))),
  );

  final buffer = StringBuffer()
    ..writeln('# BHAM Launch Gate Report')
    ..writeln()
    ..writeln('- Generated at: `${snapshot['generated_at_utc']}`')
    ..writeln('- Gate status: `${snapshot['status']}`')
    ..writeln('- Admin availability: `${evidence['admin_availability']}`')
    ..writeln(
        '- Route delivery health: `${(((evidence['route_delivery_health'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%`')
    ..writeln()
    ..writeln('## Launch Blockers')
    ..writeln();

  if (blockers.isEmpty) {
    buffer.writeln('- None recorded');
  } else {
    for (final blocker in blockers) {
      buffer.writeln('- $blocker');
    }
  }

  buffer
    ..writeln()
    ..writeln('## Fallback States')
    ..writeln();
  for (final item in fallbackStates) {
    buffer.writeln(
      '- `${item['area']}`: `${item['status']}` — ${item['summary']}',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Critical Flow Matrix')
    ..writeln();
  for (final item in flows) {
    buffer.writeln(
      '- `${item['label']}`: `${item['status']}` — ${item['evidence_summary']}',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Expansion Gates')
    ..writeln();
  for (final item in expansionGates) {
    buffer.writeln(
      '- `${item['gate_id']}`: `${item['status']}` — ${item['summary']}',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Manual Evidence Slots')
    ..writeln();
  for (final item in manualEvidence) {
    buffer.writeln(
      '- `${item['label']}`: `${item['status']}`'
      '${item['summary'] == null ? '' : ' — ${item['summary']}'}',
    );
  }

  return '$buffer';
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}
