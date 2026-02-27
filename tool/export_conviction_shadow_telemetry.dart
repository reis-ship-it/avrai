import 'dart:convert';
import 'dart:io';

const _defaultInputPath =
    'runtime_exports/conviction_gate_shadow_decisions.json';
const _defaultOutputPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_WEEKLY.md';
const _defaultSummaryJsonPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_WEEKLY.json';

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final outputPath = _readFlag(args, '--output') ?? _defaultOutputPath;
  final summaryJsonPath =
      _readFlag(args, '--summary-out') ?? _defaultSummaryJsonPath;
  final summary = _buildSummary(inputPath);
  final markdown = _buildReport(
    summary,
    outputPath: outputPath,
    summaryJsonPath: summaryJsonPath,
  );
  final summaryJson = const JsonEncoder.withIndent('  ').convert(summary);

  if (checkOnly) {
    final markdownMismatch = _safeRead(outputPath) != markdown;
    final jsonMismatch = _safeRead(summaryJsonPath) != '$summaryJson\n';
    if (markdownMismatch || jsonMismatch) {
      stderr.writeln('Conviction shadow telemetry report is out of date.');
      stderr.writeln(
          'Run: dart run tool/export_conviction_shadow_telemetry.dart');
      exit(1);
    }
    stdout.writeln('OK: conviction shadow telemetry report is in sync.');
    return;
  }

  final out = File(outputPath)..createSync(recursive: true);
  out.writeAsStringSync(markdown);
  final summaryOut = File(summaryJsonPath)..createSync(recursive: true);
  summaryOut.writeAsStringSync('$summaryJson\n');
  stdout.writeln('Updated $outputPath and $summaryJsonPath');
}

Map<String, dynamic> _buildSummary(String inputPath) {
  final input = File(inputPath);
  if (!input.existsSync()) {
    return _buildMissingSummary(
      inputPath,
      reason: 'Input file does not exist.',
    );
  }

  final raw = input.readAsStringSync().trim();
  if (raw.isEmpty) {
    return _buildMissingSummary(inputPath, reason: 'Input file is empty.');
  }

  late final List<Map<String, dynamic>> rows;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return _buildMissingSummary(
        inputPath,
        reason: 'Input is not a JSON list of decision objects.',
      );
    }
    rows = decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry('$k', v)))
        .toList();
  } catch (e) {
    return _buildMissingSummary(
      inputPath,
      reason: 'Input JSON failed to parse: $e',
    );
  }

  if (rows.isEmpty) {
    return _buildMissingSummary(inputPath,
        reason: 'Input list has no entries.');
  }

  int shadowBypassCount = 0;
  int enforceDecisionCount = 0;
  int enforceBlockedCount = 0;
  int highImpactEnforceDecisionCount = 0;
  int highImpactEnforceBlockedCount = 0;
  final byController = <String, int>{};
  final byMode = <String, int>{};
  final byReason = <String, int>{};
  DateTime? minTs;
  DateTime? maxTs;

  for (final row in rows) {
    final controller = (row['controllerName'] ?? 'unknown').toString();
    byController.update(controller, (v) => v + 1, ifAbsent: () => 1);

    final shadowBypass = row['shadowBypassApplied'] == true;
    if (shadowBypass) {
      shadowBypassCount += 1;
    }

    final mode = (row['mode'] ?? 'unknown').toString();
    byMode.update(mode, (v) => v + 1, ifAbsent: () => 1);
    final isEnforce = mode == 'enforce';
    final servingAllowed = row['servingAllowed'] == true;
    final isHighImpact = row['isHighImpact'] == true;
    if (isEnforce) {
      enforceDecisionCount += 1;
      if (!servingAllowed) {
        enforceBlockedCount += 1;
      }
      if (isHighImpact) {
        highImpactEnforceDecisionCount += 1;
        if (!servingAllowed) {
          highImpactEnforceBlockedCount += 1;
        }
      }
    }

    final reasons = row['reasonCodes'];
    if (reasons is List) {
      for (final reason in reasons) {
        final key = '$reason';
        if (key.isEmpty) continue;
        byReason.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final tsRaw = row['timestamp']?.toString();
    if (tsRaw != null && tsRaw.isNotEmpty) {
      final ts = DateTime.tryParse(tsRaw);
      if (ts != null) {
        minTs = (minTs == null || ts.isBefore(minTs)) ? ts : minTs;
        maxTs = (maxTs == null || ts.isAfter(maxTs)) ? ts : maxTs;
      }
    }
  }

  final sortedControllers = byController.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final sortedReasons = byReason.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final bypassRate = rows.isEmpty
      ? 0.0
      : (shadowBypassCount.toDouble() / rows.length.toDouble());
  final enforceBlockRate = enforceDecisionCount == 0
      ? 0.0
      : (enforceBlockedCount.toDouble() / enforceDecisionCount.toDouble());
  final highImpactEnforceBlockRate = highImpactEnforceDecisionCount == 0
      ? 0.0
      : (highImpactEnforceBlockedCount.toDouble() /
          highImpactEnforceDecisionCount.toDouble());

  final recent = rows.toList()
    ..sort(
      (a, b) => (a['timestamp'] ?? '')
          .toString()
          .compareTo((b['timestamp'] ?? '').toString()),
    );

  return <String, dynamic>{
    'source_input': inputPath,
    'has_data': true,
    'reason': null,
    'total_decisions': rows.length,
    'shadow_bypass_decisions': shadowBypassCount,
    'shadow_bypass_rate': bypassRate,
    'enforce_decisions': enforceDecisionCount,
    'enforce_blocked_decisions': enforceBlockedCount,
    'enforce_block_rate': enforceBlockRate,
    'high_impact_enforce_decisions': highImpactEnforceDecisionCount,
    'high_impact_enforce_blocked_decisions': highImpactEnforceBlockedCount,
    'high_impact_enforce_block_rate': highImpactEnforceBlockRate,
    'window_start': minTs?.toIso8601String(),
    'window_end': maxTs?.toIso8601String(),
    'by_controller': {
      for (final e in sortedControllers) e.key: e.value,
    },
    'by_mode': {
      for (final e in byMode.entries) e.key: e.value,
    },
    'by_reason': {
      for (final e in sortedReasons) e.key: e.value,
    },
    'recent_decisions': recent.reversed.take(20).toList(),
  };
}

String _buildReport(
  Map<String, dynamic> summary, {
  required String outputPath,
  required String summaryJsonPath,
}) {
  final hasData = summary['has_data'] == true;
  if (!hasData) {
    return _buildMissingReport(
      summary,
      outputPath: outputPath,
      summaryJsonPath: summaryJsonPath,
    );
  }

  final sourceInput = (summary['source_input'] ?? _defaultInputPath).toString();
  final totalDecisions = _intValue(summary['total_decisions']);
  final bypassDecisions = _intValue(summary['shadow_bypass_decisions']);
  final bypassRatePct =
      (_doubleValue(summary['shadow_bypass_rate']) * 100.0).toStringAsFixed(2);
  final enforceDecisions = _intValue(summary['enforce_decisions']);
  final enforceBlocked = _intValue(summary['enforce_blocked_decisions']);
  final enforceBlockRatePct =
      (_doubleValue(summary['enforce_block_rate']) * 100.0).toStringAsFixed(2);
  final highImpactEnforceDecisions =
      _intValue(summary['high_impact_enforce_decisions']);
  final highImpactEnforceBlocked =
      _intValue(summary['high_impact_enforce_blocked_decisions']);
  final highImpactEnforceBlockRatePct =
      (_doubleValue(summary['high_impact_enforce_block_rate']) * 100.0)
          .toStringAsFixed(2);
  final windowStart = (summary['window_start'] ?? '-').toString();
  final windowEnd = (summary['window_end'] ?? '-').toString();
  final byController =
      (summary['by_controller'] as Map?)?.map((k, v) => MapEntry('$k', v));
  final byMode = (summary['by_mode'] as Map?)?.map((k, v) => MapEntry('$k', v));
  final byReason =
      (summary['by_reason'] as Map?)?.map((k, v) => MapEntry('$k', v));
  final recent = (summary['recent_decisions'] as List?) ?? const <dynamic>[];

  final b = StringBuffer();
  b.writeln('# 3-Prong Shadow Gate Telemetry Weekly Export\n');
  b.writeln('**Source input:** `$sourceInput`  ');
  b.writeln('**Export target:** `$outputPath`  ');
  b.writeln('**Summary JSON:** `$summaryJsonPath`  ');
  b.writeln('**Total decisions:** $totalDecisions  ');
  b.writeln('**Shadow bypass decisions:** $bypassDecisions  ');
  b.writeln('**Shadow bypass rate:** $bypassRatePct%  ');
  b.writeln(
      '**Enforce decisions blocked:** $enforceBlocked/$enforceDecisions ($enforceBlockRatePct%)  ');
  b.writeln(
      '**High-impact enforce blocked:** $highImpactEnforceBlocked/$highImpactEnforceDecisions ($highImpactEnforceBlockRatePct%)  ');
  b.writeln('**Window:** $windowStart -> $windowEnd  ');
  b.writeln();
  b.writeln('## Mode Volume\n');
  b.writeln('| Mode | Decisions |');
  b.writeln('|------|-----------|');
  if (byMode == null || byMode.isEmpty) {
    b.writeln('| _(none)_ | 0 |');
  } else {
    for (final e in byMode.entries) {
      b.writeln('| ${e.key} | ${e.value} |');
    }
  }
  b.writeln();
  b.writeln('## Controller Volume\n');
  b.writeln('| Controller | Decisions |');
  b.writeln('|------------|-----------|');
  if (byController == null || byController.isEmpty) {
    b.writeln('| _(none)_ | 0 |');
  } else {
    for (final e in byController.entries) {
      b.writeln('| ${e.key} | ${e.value} |');
    }
  }
  b.writeln();
  b.writeln('## Top Reason Codes\n');
  b.writeln('| Reason Code | Count |');
  b.writeln('|-------------|-------|');
  if (byReason == null || byReason.isEmpty) {
    b.writeln('| _(none)_ | 0 |');
  } else {
    for (final e in byReason.entries.take(20)) {
      b.writeln('| ${e.key} | ${e.value} |');
    }
  }
  b.writeln();
  b.writeln('## Recent Decisions (Last 20)\n');
  b.writeln(
      '| Timestamp | Mode | Controller | Subject | Request | Claim State | Bypass | Allowed | Reasons |');
  b.writeln(
      '|-----------|------|------------|---------|---------|-------------|--------|---------|---------|');
  for (final rawRow in recent) {
    if (rawRow is! Map) continue;
    final row = rawRow.map((k, v) => MapEntry('$k', v));
    final reasons = (row['reasonCodes'] is List)
        ? (row['reasonCodes'] as List).map((e) => '$e').join(', ')
        : '';
    b.writeln(
      '| ${(row['timestamp'] ?? '-')} | ${(row['mode'] ?? '-')} | ${(row['controllerName'] ?? '-')} | ${(row['subjectId'] ?? '-')} | ${(row['requestId'] ?? '-')} | ${(row['claimState'] ?? '-')} | ${(row['shadowBypassApplied'] ?? false)} | ${(row['servingAllowed'] ?? '-')} | ${reasons.isEmpty ? '-' : reasons} |',
    );
  }

  return '${b.toString().trimRight()}\n';
}

Map<String, dynamic> _buildMissingSummary(
  String inputPath, {
  required String reason,
}) {
  return <String, dynamic>{
    'source_input': inputPath,
    'has_data': false,
    'reason': reason,
    'total_decisions': 0,
    'shadow_bypass_decisions': 0,
    'shadow_bypass_rate': 0.0,
    'enforce_decisions': 0,
    'enforce_blocked_decisions': 0,
    'enforce_block_rate': 0.0,
    'high_impact_enforce_decisions': 0,
    'high_impact_enforce_blocked_decisions': 0,
    'high_impact_enforce_block_rate': 0.0,
    'window_start': null,
    'window_end': null,
    'by_controller': <String, int>{},
    'by_mode': <String, int>{},
    'by_reason': <String, int>{},
    'recent_decisions': <Map<String, dynamic>>[],
  };
}

String _buildMissingReport(
  Map<String, dynamic> summary, {
  required String outputPath,
  required String summaryJsonPath,
}) {
  final inputPath = (summary['source_input'] ?? _defaultInputPath).toString();
  final reason = (summary['reason'] ?? '').toString();
  final b = StringBuffer();
  b.writeln('# 3-Prong Shadow Gate Telemetry Weekly Export\n');
  b.writeln('**Status:** No runtime export available yet.');
  b.writeln('**Expected input:** `$inputPath`');
  b.writeln('**Summary JSON:** `$summaryJsonPath`');
  if (reason.isNotEmpty) {
    b.writeln('**Note:** $reason');
  }
  b.writeln();
  b.writeln('## How To Populate\n');
  b.writeln(
      '1. Export persisted decisions from storage key `conviction_gate_shadow_decisions_v1` into JSON list format.');
  b.writeln(
      '2. Save to the expected input path or pass `--input <path>` when running the exporter.');
  b.writeln(
      '3. Run `dart run tool/export_conviction_shadow_telemetry.dart` to regenerate this report.');
  return '${b.toString().trimRight()}\n';
}

String? _readFlag(List<String> args, String flag) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == flag && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String _safeRead(String path) {
  final f = File(path);
  if (!f.existsSync()) return '';
  return f.readAsStringSync();
}

int _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

double _doubleValue(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse('$value') ?? 0.0;
}
