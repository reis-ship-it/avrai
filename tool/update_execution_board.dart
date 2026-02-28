import 'dart:io';

/// Synchronizes and validates execution tracking docs.
///
/// Usage:
/// - Write mode (default): `dart run tool/update_execution_board.dart`
/// - Check mode: `dart run tool/update_execution_board.dart --check`
///
/// Invariants enforced:
/// 1) `docs/EXECUTION_BOARD.csv` is the source of truth for board rows.
/// 2) `docs/EXECUTION_BOARD.md` generated sections must match CSV.
/// 3) Phase rows in CSV must cover all `## Phase X:` sections in MASTER_PLAN.
/// 4) Milestone IDs, statuses, dependencies, and traceability metadata are validated.
/// 5) A phase marked `Ready` must have at least one active milestone
///    (`Ready`/`In Progress`/`Done`) in that same phase.
/// 6) Reopen-by-new-milestone events must declare reopening metadata and be
///    recorded in `docs/STATUS_WEEKLY.md`.
void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final cwd = Directory.current.path;
  final csvPath = '$cwd/docs/EXECUTION_BOARD.csv';
  final mdPath = '$cwd/docs/EXECUTION_BOARD.md';
  final masterPlanPath = '$cwd/docs/MASTER_PLAN.md';
  final statusWeeklyPath = '$cwd/docs/STATUS_WEEKLY.md';

  final csvFile = File(csvPath);
  final mdFile = File(mdPath);
  final masterPlanFile = File(masterPlanPath);
  final statusWeeklyFile = File(statusWeeklyPath);

  if (!csvFile.existsSync()) {
    _fail('Missing CSV: $csvPath');
  }
  if (!mdFile.existsSync()) {
    _fail('Missing Markdown board: $mdPath');
  }
  if (!masterPlanFile.existsSync()) {
    _fail('Missing master plan: $masterPlanPath');
  }
  if (!statusWeeklyFile.existsSync()) {
    _fail('Missing weekly status log: $statusWeeklyPath');
  }

  final csvText = csvFile.readAsStringSync();
  final mdText = mdFile.readAsStringSync();
  final masterPlanText = masterPlanFile.readAsStringSync();
  final statusWeeklyText = statusWeeklyFile.readAsStringSync();

  final rows = _parseCsv(csvText);
  if (rows.isEmpty) {
    _fail('CSV has no rows.');
  }

  final header = rows.first;
  final requiredHeaders = <String>[
    'type',
    'id',
    'phase',
    'name_or_scope',
    'wave',
    'status',
    'owner_r',
    'accountable_a',
    'consulted_c',
    'informed_i',
    'dependencies',
    'prd_ids',
    'master_plan_refs',
    'architecture_spot',
    'change_type',
    'reopens_milestone',
    'urk_runtime_type',
    'urk_prong',
    'privacy_mode_impact',
    'impact_tier_max',
    'risk_probability',
    'risk_impact',
    'risk_score',
    'priority',
    'target_window',
    'exit_criteria',
    'evidence',
    'notes',
  ];
  for (final h in requiredHeaders) {
    if (!header.contains(h)) {
      _fail('CSV missing required header: $h');
    }
  }

  final index = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    index[header[i]] = i;
  }

  final data = rows.skip(1).where((r) => r.isNotEmpty).toList(growable: false);
  final phaseRows = <Map<String, String>>[];
  final milestoneRows = <Map<String, String>>[];
  for (final row in data) {
    if (row.length < header.length) {
      _fail('CSV row has fewer columns than header: $row');
    }
    final map = <String, String>{};
    for (var i = 0; i < header.length; i++) {
      map[header[i]] = row[i];
    }
    final type = map['type']!.trim();
    if (type == 'phase') {
      phaseRows.add(map);
    } else if (type == 'milestone') {
      milestoneRows.add(map);
    } else {
      _fail('Unknown row type "$type" in row id=${map['id']}');
    }
  }

  _validateRows(
      phaseRows: phaseRows,
      milestoneRows: milestoneRows,
      masterPlanText: masterPlanText,
      statusWeeklyText: statusWeeklyText);

  final generatedPhaseTable = _buildPhaseTable(phaseRows);
  final generatedMilestoneTable = _buildMilestoneTable(milestoneRows);
  final generatedKanban = _buildKanbanSection(milestoneRows);

  var nextMd = mdText;
  nextMd = _replaceSection(
    nextMd,
    startMarker: '<!-- EXECUTION_BOARD:PHASE_PORTFOLIO_START -->',
    endMarker: '<!-- EXECUTION_BOARD:PHASE_PORTFOLIO_END -->',
    replacement: generatedPhaseTable,
  );
  nextMd = _replaceSection(
    nextMd,
    startMarker: '<!-- EXECUTION_BOARD:MILESTONE_BOARD_START -->',
    endMarker: '<!-- EXECUTION_BOARD:MILESTONE_BOARD_END -->',
    replacement: generatedMilestoneTable,
  );
  nextMd = _replaceSection(
    nextMd,
    startMarker: '<!-- EXECUTION_BOARD:URK_LANES_START -->',
    endMarker: '<!-- EXECUTION_BOARD:URK_LANES_END -->',
    replacement: _buildUrkLanesSection(milestoneRows),
  );
  nextMd = _replaceSection(
    nextMd,
    startMarker: '<!-- EXECUTION_BOARD:KANBAN_START -->',
    endMarker: '<!-- EXECUTION_BOARD:KANBAN_END -->',
    replacement: generatedKanban,
  );
  nextMd = _replaceLine(
    nextMd,
    prefix: 'Last updated:',
    next: 'Last updated: ${_todayIso()}',
  );

  if (checkOnly) {
    if (nextMd != mdText) {
      _fail(
        'Execution board is out of sync. Run: dart run tool/update_execution_board.dart',
      );
    }
    stdout.writeln('OK: execution board is valid and in sync.');
    return;
  }

  mdFile.writeAsStringSync(nextMd);
  stdout.writeln('Updated docs/EXECUTION_BOARD.md from CSV.');
  stdout.writeln('Validation passed.');
}

void _validateRows({
  required List<Map<String, String>> phaseRows,
  required List<Map<String, String>> milestoneRows,
  required String masterPlanText,
  required String statusWeeklyText,
}) {
  final allowedStatus = <String>{
    'Backlog',
    'Ready',
    'In Progress',
    'Blocked',
    'Done'
  };
  final activeMilestoneStatus = <String>{'Ready', 'In Progress', 'Done'};
  final milestoneIdPattern = RegExp(r'^M\d+-P\d+-\d+$');
  final phaseIdPattern = RegExp(r'^P\d+$');
  final prdPattern = RegExp(r'^PRD-\d{3}$');
  final masterRefPattern = RegExp(r'^\d+\.\d+\.\d+$');
  final allowedChangeTypes = <String>{'baseline', 'reopen'};
  final allowedUrkRuntimeTypes = <String>{
    'user_runtime',
    'event_ops_runtime',
    'business_ops_runtime',
    'expert_services_runtime',
    'shared',
  };
  final allowedUrkProngs = <String>{
    'model_core',
    'runtime_core',
    'governance_core',
    'cross_prong',
  };
  final allowedPrivacyModeImpact = <String>{
    'local_sovereign',
    'private_mesh',
    'federated_cloud',
    'multi_mode',
  };
  final allowedImpactTiers = <String>{'L1', 'L2', 'L3', 'L4'};
  final phaseNums = <int>{};
  final phaseIdSet = <String>{};
  final phaseStatusByNum = <int, String>{};

  for (final row in phaseRows) {
    final id = row['id']!.trim();
    if (!phaseIdPattern.hasMatch(id)) {
      _fail('Invalid phase id format: $id (expected P<phase>)');
    }
    if (!phaseIdSet.add(id)) {
      _fail('Duplicate phase id: $id');
    }
    final phase = int.tryParse(row['phase']!.trim());
    if (phase == null) {
      _fail('Invalid phase number for phase row $id: ${row['phase']}');
    }
    phaseNums.add(phase);
    final status = row['status']!.trim();
    if (!allowedStatus.contains(status)) {
      _fail('Invalid status "$status" for phase $id');
    }
    phaseStatusByNum[phase] = status;
  }

  final milestoneRowsById = <String, Map<String, String>>{};
  for (final row in milestoneRows) {
    final id = row['id']!.trim();
    if (!milestoneIdPattern.hasMatch(id)) {
      _fail('Invalid milestone id format: $id (expected Mx-Py-z)');
    }
    if (milestoneRowsById.containsKey(id)) {
      _fail('Duplicate milestone id: $id');
    }
    milestoneRowsById[id] = row;
  }

  final milestoneRowsByPhase = <int, List<Map<String, String>>>{};
  final reopenMilestones = <Map<String, String>>[];
  for (final row in milestoneRows) {
    final id = row['id']!.trim();
    final phase = int.tryParse(row['phase']!.trim());
    if (phase == null || !phaseNums.contains(phase)) {
      _fail('Milestone $id references unknown phase: ${row['phase']}');
    }
    milestoneRowsByPhase
        .putIfAbsent(phase, () => <Map<String, String>>[])
        .add(row);
    final status = row['status']!.trim();
    if (!allowedStatus.contains(status)) {
      _fail('Invalid status "$status" for milestone $id');
    }
    final prdIds = row['prd_ids']!.trim();
    if (prdIds.isEmpty || prdIds.toLowerCase() == 'none') {
      _fail('Milestone $id missing PRD IDs (expected one or more PRD-###).');
    }
    final prdCandidates = prdIds
        .split(RegExp(r'[;,]\s*|\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final prd in prdCandidates) {
      if (!prdPattern.hasMatch(prd)) {
        _fail(
            'Milestone $id has invalid PRD ID format: $prd (expected PRD-###).');
      }
    }

    final masterRefs = row['master_plan_refs']!.trim();
    if (masterRefs.isEmpty || masterRefs.toLowerCase() == 'none') {
      _fail(
          'Milestone $id missing master plan refs (expected one or more X.Y.Z).');
    }
    final refCandidates = masterRefs
        .split(RegExp(r'[;,]\s*|\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final ref in refCandidates) {
      if (!masterRefPattern.hasMatch(ref)) {
        _fail(
            'Milestone $id has invalid master plan ref: $ref (expected X.Y.Z).');
      }
    }

    final spot = row['architecture_spot']!.trim();
    if (spot.isEmpty || spot.toLowerCase() == 'none') {
      _fail('Milestone $id missing architecture_spot.');
    }

    final urkRuntimeType = row['urk_runtime_type']!.trim();
    if (!allowedUrkRuntimeTypes.contains(urkRuntimeType)) {
      _fail(
        'Milestone $id has invalid urk_runtime_type "$urkRuntimeType". '
        'Expected one of: ${allowedUrkRuntimeTypes.join(', ')}.',
      );
    }
    final urkProng = row['urk_prong']!.trim();
    if (!allowedUrkProngs.contains(urkProng)) {
      _fail(
        'Milestone $id has invalid urk_prong "$urkProng". '
        'Expected one of: ${allowedUrkProngs.join(', ')}.',
      );
    }
    final privacyModeImpact = row['privacy_mode_impact']!.trim();
    if (!allowedPrivacyModeImpact.contains(privacyModeImpact)) {
      _fail(
        'Milestone $id has invalid privacy_mode_impact "$privacyModeImpact". '
        'Expected one of: ${allowedPrivacyModeImpact.join(', ')}.',
      );
    }
    final impactTierMax = row['impact_tier_max']!.trim();
    if (!allowedImpactTiers.contains(impactTierMax)) {
      _fail(
        'Milestone $id has invalid impact_tier_max "$impactTierMax". '
        'Expected one of: ${allowedImpactTiers.join(', ')}.',
      );
    }

    final changeType = row['change_type']!.trim().toLowerCase();
    if (!allowedChangeTypes.contains(changeType)) {
      _fail(
        'Milestone $id has invalid change_type "${row['change_type']}". '
        'Expected one of: baseline, reopen.',
      );
    }
    final reopensMilestone = row['reopens_milestone']!.trim();
    if (changeType == 'baseline') {
      if (reopensMilestone.isNotEmpty &&
          reopensMilestone.toLowerCase() != 'none') {
        _fail(
          'Milestone $id is baseline but reopens_milestone is set to '
          '"$reopensMilestone". Use "none".',
        );
      }
    } else {
      if (!milestoneIdPattern.hasMatch(reopensMilestone)) {
        _fail(
          'Milestone $id has change_type=reopen but reopens_milestone is invalid: '
          '$reopensMilestone (expected Mx-Py-z).',
        );
      }
      if (reopensMilestone == id) {
        _fail('Milestone $id cannot reopen itself.');
      }
      final reopened = milestoneRowsById[reopensMilestone];
      if (reopened == null) {
        _fail(
          'Milestone $id reopens unknown milestone: $reopensMilestone.',
        );
      }
      if (reopened['status']!.trim() != 'Done') {
        _fail(
          'Milestone $id reopens $reopensMilestone, but that milestone is not Done.',
        );
      }
      if (row['notes']!.trim().isEmpty) {
        _fail('Milestone $id change_type=reopen requires rationale in notes.');
      }
      reopenMilestones.add(row);
    }

    final deps = row['dependencies']!.trim();
    if (deps.isNotEmpty && deps.toLowerCase() != 'none') {
      final candidates = deps
          .split(RegExp(r'[;,]\s*|\s+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final dep in candidates) {
        if (!milestoneIdPattern.hasMatch(dep)) {
          _fail(
            'Milestone $id has invalid dependency "$dep". '
            'Dependencies must be milestone IDs (Mx-Py-z) or "none".',
          );
        }
        if (dep == id) {
          _fail('Milestone $id cannot depend on itself.');
        }
        if (!milestoneRowsById.containsKey(dep)) {
          _fail('Milestone $id has unknown milestone dependency: $dep');
        }
      }
    }
  }

  for (final phase in phaseNums) {
    if (phaseStatusByNum[phase] != 'Ready') {
      continue;
    }
    final phaseMilestones =
        milestoneRowsByPhase[phase] ?? const <Map<String, String>>[];
    final hasActiveMilestone = phaseMilestones.any(
      (row) => activeMilestoneStatus.contains(row['status']!.trim()),
    );
    if (!hasActiveMilestone) {
      _fail(
        'Phase P$phase is marked Ready but has no active milestone '
        '(Ready/In Progress/Done).',
      );
    }
  }

  final masterPhaseRegex = RegExp(r'^## Phase (\d+):', multiLine: true);
  final masterPhases = masterPhaseRegex
      .allMatches(masterPlanText)
      .map((m) => int.parse(m.group(1)!))
      .toSet();

  for (final p in masterPhases) {
    if (!phaseNums.contains(p)) {
      _fail(
        'Execution board missing phase row for MASTER_PLAN phase $p. Add it to CSV.',
      );
    }
  }

  for (final row in reopenMilestones) {
    final id = row['id']!.trim();
    final reopened = row['reopens_milestone']!.trim();
    if (!statusWeeklyText.contains(id) ||
        !statusWeeklyText.contains(reopened)) {
      _fail(
        'Reopen milestone $id must be recorded in docs/STATUS_WEEKLY.md '
        'alongside reopened milestone $reopened.',
      );
    }
  }
}

String _buildPhaseTable(List<Map<String, String>> rows) {
  final sorted = [...rows]
    ..sort((a, b) => int.parse(a['phase']!).compareTo(int.parse(b['phase']!)));

  final lines = <String>[
    '| Phase | Name | Governance Tier | R (Owner) | A (Accountable) | Risk | Priority | Status | Gate |',
    '|------|------|------------------|-----------|------------------|------|----------|--------|------|',
  ];
  for (final r in sorted) {
    final phase = r['phase']!;
    final name = r['name_or_scope']!;
    final tier = r['wave']!.isEmpty
        ? _guessTierFromPriority(r['priority']!)
        : r['wave']!;
    final owner = _fmt(r['owner_r']!);
    final acc = _fmt(r['accountable_a']!);
    final risk = r['risk_score']!;
    final priority = r['priority']!;
    final status = r['status']!;
    final gate = r['exit_criteria']!;
    lines.add(
      '| $phase | $name | $tier | $owner | $acc | $risk | $priority | $status | $gate |',
    );
  }
  return lines.join('\n');
}

String _buildMilestoneTable(List<Map<String, String>> rows) {
  final sorted = [...rows]..sort((a, b) => a['id']!.compareTo(b['id']!));
  final lines = <String>[
    '| Milestone | Phase | Wave | Scope | Change Type | Reopens | URK Runtime | URK Prong | Mode Impact | Impact Tier | PRD IDs | Master Plan Refs | Architecture Spot | R | A | Dependencies | Risk | Priority | Target Window | Status | Evidence |',
    '|----------|-------|------|-------|------------|---------|-------------|-----------|-------------|-------------|---------|------------------|-------------------|---|---|--------------|------|----------|---------------|--------|----------|',
  ];
  for (final r in sorted) {
    lines.add(
      '| ${r['id']} | ${r['phase']} | ${r['wave']} | ${r['name_or_scope']} | ${_fmtOr(r['change_type']!, '-')} | ${_fmtOr(r['reopens_milestone']!, 'none')} | ${_fmtOr(r['urk_runtime_type']!, '-')} | ${_fmtOr(r['urk_prong']!, '-')} | ${_fmtOr(r['privacy_mode_impact']!, '-')} | ${_fmtOr(r['impact_tier_max']!, '-')} | ${_fmtOr(r['prd_ids']!, '-')} | ${_fmtOr(r['master_plan_refs']!, '-')} | ${_fmtOr(r['architecture_spot']!, '-')} | ${_fmt(r['owner_r']!)} | ${_fmt(r['accountable_a']!)} | ${_fmtOr(r['dependencies']!, 'none')} | ${r['risk_score']} | ${r['priority']} | ${r['target_window']} | ${r['status']} | ${_fmtOr(r['evidence']!, '-')} |',
    );
  }
  return lines.join('\n');
}

String _buildUrkLanesSection(List<Map<String, String>> rows) {
  String makeTable({
    required String title,
    required List<String> keys,
    required String Function(String key) labeler,
    required String Function(Map<String, String> row) selector,
  }) {
    final counts = <String, int>{for (final k in keys) k: 0};
    final statusCounts = <String, Map<String, int>>{
      for (final k in keys)
        k: <String, int>{
          'Backlog': 0,
          'Ready': 0,
          'In Progress': 0,
          'Blocked': 0,
          'Done': 0,
        },
    };

    for (final row in rows) {
      final key = selector(row);
      if (!counts.containsKey(key)) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      final status = row['status']!.trim();
      final bucket = statusCounts[key]!;
      if (bucket.containsKey(status)) {
        bucket[status] = (bucket[status] ?? 0) + 1;
      }
    }

    final out = <String>[
      '### $title',
      '',
      '| Lane | Total | Backlog | Ready | In Progress | Blocked | Done |',
      '|------|------:|--------:|------:|------------:|--------:|-----:|',
    ];
    for (final key in keys) {
      final bucket = statusCounts[key]!;
      out.add(
        '| ${labeler(key)} | ${counts[key]} | ${bucket['Backlog']} | ${bucket['Ready']} | ${bucket['In Progress']} | ${bucket['Blocked']} | ${bucket['Done']} |',
      );
    }
    return out.join('\n');
  }

  final runtimeTypes = <String>[
    'user_runtime',
    'event_ops_runtime',
    'business_ops_runtime',
    'expert_services_runtime',
    'shared',
  ];
  final prongs = <String>[
    'model_core',
    'runtime_core',
    'governance_core',
    'cross_prong',
  ];
  final modes = <String>[
    'local_sovereign',
    'private_mesh',
    'federated_cloud',
    'multi_mode',
  ];
  final impactTiers = <String>['L1', 'L2', 'L3', 'L4'];

  return [
    makeTable(
      title: 'URK Runtime Type Lanes',
      keys: runtimeTypes,
      labeler: (k) => '`$k`',
      selector: (row) => row['urk_runtime_type']!.trim(),
    ),
    '',
    makeTable(
      title: 'URK Prong Lanes',
      keys: prongs,
      labeler: (k) => '`$k`',
      selector: (row) => row['urk_prong']!.trim(),
    ),
    '',
    makeTable(
      title: 'Privacy Mode Impact Lanes',
      keys: modes,
      labeler: (k) => '`$k`',
      selector: (row) => row['privacy_mode_impact']!.trim(),
    ),
    '',
    makeTable(
      title: 'Impact Tier Lanes',
      keys: impactTiers,
      labeler: (k) => '`$k`',
      selector: (row) => row['impact_tier_max']!.trim(),
    ),
  ].join('\n');
}

String _buildKanbanSection(List<Map<String, String>> rows) {
  String listFor(String status) {
    final ids = rows
        .where((r) => r['status'] == status)
        .map((r) => r['id']!)
        .toList()
      ..sort();
    if (ids.isEmpty) return 'None';
    return ids.map((e) => '`$e`').join(', ');
  }

  return [
    '### Backlog',
    '',
    listFor('Backlog'),
    '',
    '### Ready',
    '',
    listFor('Ready'),
    '',
    '### In Progress',
    '',
    listFor('In Progress'),
    '',
    '### Blocked',
    '',
    listFor('Blocked'),
    '',
    '### Done',
    '',
    listFor('Done'),
  ].join('\n');
}

String _guessTierFromPriority(String priority) {
  switch (priority) {
    case 'Critical':
      return 'Full';
    case 'High':
      return 'Hybrid';
    default:
      return 'Hybrid';
  }
}

String _fmt(String v) => v.replaceAll(';', ', ');

String _fmtOr(String v, String fallback) =>
    v.trim().isEmpty ? fallback : _fmt(v);

String _replaceSection(
  String source, {
  required String startMarker,
  required String endMarker,
  required String replacement,
}) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);
  if (start == -1 || end == -1 || end < start) {
    _fail('Missing or invalid markers: $startMarker ... $endMarker');
  }
  final before = source.substring(0, start + startMarker.length);
  final after = source.substring(end);
  return '$before\n$replacement\n$after';
}

String _replaceLine(String source,
    {required String prefix, required String next}) {
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].startsWith(prefix)) {
      lines[i] = next;
      return lines.join('\n');
    }
  }
  return source;
}

String _todayIso() {
  final now = DateTime.now().toUtc();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

List<List<String>> _parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    if (row.isNotEmpty || field.isNotEmpty) {
      endField();
      rows.add(row);
      row = <String>[];
    }
  }

  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else {
      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        endField();
      } else if (c == '\n') {
        endRow();
      } else if (c == '\r') {
        // Skip CR in CRLF.
      } else {
        field.write(c);
      }
    }
  }
  if (inQuotes) {
    _fail('CSV parse error: unclosed quote.');
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}

Never _fail(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}
