import 'dart:convert';
import 'dart:io';

const _csvPath = 'docs/EXECUTION_BOARD.csv';
const _telemetrySummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_WEEKLY.json';
const _rollbackDrillSummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.json';
const _replicationSlaSummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_RESEARCH_REPLICATION_SLA_REPORT.json';
const _trustUxSummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_TRUST_UX_PRIORITY_FLOW_REPORT.json';
const _selfHealingSummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_SELF_HEALING_INCIDENT_ROUTING_REPORT.json';
const _lineageTransparencySummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.json';
const _completionAuditSummaryPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_COMPLETION_AUDIT_PACKAGE.json';
const _scorecardPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_READINESS_SCORECARD.md';
const _weeklyPath =
    'docs/plans/methodology/MASTER_PLAN_3_PRONG_WEEKLY_REVIEW.md';
const _finalPath = 'docs/plans/methodology/MASTER_PLAN_3_PRONG_FINAL_REVIEW.md';
const _shadowBypassRateTarget = 0.02;

const _trackedMilestones = <String>[
  'M4-P3-1',
  'M4-P3-2',
  'M4-P3-3',
  'M5-P3-1',
  'M5-P3-2',
  'M5-P3-3',
  'M5-P3-4',
  'M6-P3-1',
  'M6-P3-2',
  'M6-P3-3',
];

class _Milestone {
  const _Milestone({
    required this.id,
    required this.status,
    required this.owner,
    required this.dependencies,
    required this.targetWindow,
    required this.priority,
    required this.riskScore,
    required this.exitCriteria,
    required this.evidence,
  });

  final String id;
  final String status;
  final String owner;
  final String dependencies;
  final String targetWindow;
  final String priority;
  final String riskScore;
  final String exitCriteria;
  final String evidence;
}

class _BoardSnapshot {
  const _BoardSnapshot({
    required this.trackedMilestones,
    required this.statusByMilestone,
  });

  final List<_Milestone> trackedMilestones;
  final Map<String, String> statusByMilestone;
}

class _TelemetrySummary {
  const _TelemetrySummary({
    required this.hasData,
    required this.totalDecisions,
    required this.shadowBypassDecisions,
    required this.shadowBypassRate,
    required this.enforceDecisions,
    required this.enforceBlockedDecisions,
    required this.enforceBlockRate,
    required this.highImpactEnforceDecisions,
    required this.highImpactEnforceBlockedDecisions,
    required this.highImpactEnforceBlockRate,
    required this.topReasonCodes,
    required this.windowStart,
    required this.windowEnd,
    required this.note,
  });

  final bool hasData;
  final int totalDecisions;
  final int shadowBypassDecisions;
  final double shadowBypassRate;
  final int enforceDecisions;
  final int enforceBlockedDecisions;
  final double enforceBlockRate;
  final int highImpactEnforceDecisions;
  final int highImpactEnforceBlockedDecisions;
  final double highImpactEnforceBlockRate;
  final List<String> topReasonCodes;
  final String? windowStart;
  final String? windowEnd;
  final String? note;
}

class _RollbackDrillSummary {
  const _RollbackDrillSummary({
    required this.hasData,
    required this.verdict,
    required this.rollbackRequiredIncidents,
    required this.totalIncidents,
    required this.failClosed,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final int rollbackRequiredIncidents;
  final int totalIncidents;
  final bool failClosed;
  final String? note;
}

class _TrustUxSummary {
  const _TrustUxSummary({
    required this.hasData,
    required this.verdict,
    required this.totalFlows,
    required this.implementedFlows,
    required this.coverageRatio,
    required this.contractOk,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final int totalFlows;
  final int implementedFlows;
  final double coverageRatio;
  final bool contractOk;
  final String? note;
}

class _ReplicationSlaSummary {
  const _ReplicationSlaSummary({
    required this.hasData,
    required this.verdict,
    required this.totalItems,
    required this.activeItems,
    required this.overdueItems,
    required this.slaCompliant,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final int totalItems;
  final int activeItems;
  final int overdueItems;
  final bool slaCompliant;
  final String? note;
}

class _SelfHealingSummary {
  const _SelfHealingSummary({
    required this.hasData,
    required this.verdict,
    required this.totalIncidents,
    required this.activeIncidents,
    required this.sloBreaches,
    required this.sloCompliant,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final int totalIncidents;
  final int activeIncidents;
  final int sloBreaches;
  final bool sloCompliant;
  final String? note;
}

class _LineageTransparencySummary {
  const _LineageTransparencySummary({
    required this.hasData,
    required this.verdict,
    required this.totalFlows,
    required this.implementedFlows,
    required this.coverageRatio,
    required this.contractOk,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final int totalFlows;
  final int implementedFlows;
  final double coverageRatio;
  final bool contractOk;
  final String? note;
}

class _CompletionAuditSummary {
  const _CompletionAuditSummary({
    required this.hasData,
    required this.verdict,
    required this.gatesReady,
    required this.documentsReady,
    required this.signoffReady,
    required this.missingReports,
    required this.missingDocuments,
    required this.missingSignoffRoles,
    required this.approvedSignoffRoles,
    required this.missingSignoffRoleNames,
    required this.note,
  });

  final bool hasData;
  final String verdict;
  final bool gatesReady;
  final bool documentsReady;
  final bool signoffReady;
  final int missingReports;
  final int missingDocuments;
  final int missingSignoffRoles;
  final List<String> approvedSignoffRoles;
  final List<String> missingSignoffRoleNames;
  final String? note;
}

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final snapshot = _loadBoardSnapshot();
  final telemetry = _loadTelemetrySummary();
  final rollbackDrill = _loadRollbackDrillSummary();
  final replicationSla = _loadReplicationSlaSummary();
  final trustUx = _loadTrustUxSummary();
  final selfHealing = _loadSelfHealingSummary();
  final lineageTransparency = _loadLineageTransparencySummary();
  final completionAudit = _loadCompletionAuditSummary();
  final milestones = snapshot.trackedMilestones;
  final date = DateTime.now().toIso8601String().split('T').first;

  final scorecard = _buildScorecard(
    date,
    milestones,
    telemetry,
    rollbackDrill,
    replicationSla,
    trustUx,
    selfHealing,
    lineageTransparency,
    completionAudit,
  );
  final weekly = _buildWeekly(
    date,
    milestones,
    snapshot.statusByMilestone,
    telemetry,
    rollbackDrill,
    replicationSla,
    trustUx,
    selfHealing,
    lineageTransparency,
    completionAudit,
  );
  final finalReview = _buildFinal(
    date,
    milestones,
    telemetry,
    rollbackDrill,
    replicationSla,
    trustUx,
    selfHealing,
    lineageTransparency,
    completionAudit,
  );

  if (checkOnly) {
    final mismatches = <String>[];
    if (_safeRead(_scorecardPath) != scorecard) mismatches.add(_scorecardPath);
    if (_safeRead(_weeklyPath) != weekly) mismatches.add(_weeklyPath);
    if (_safeRead(_finalPath) != finalReview) mismatches.add(_finalPath);

    if (mismatches.isNotEmpty) {
      stderr.writeln('3-prong review artifacts are out of date:');
      for (final path in mismatches) {
        stderr.writeln('- $path');
      }
      stderr.writeln('Run: dart run tool/update_three_prong_reviews.dart');
      exit(1);
    }
    stdout.writeln('OK: 3-prong review artifacts are in sync.');
    return;
  }

  _write(_scorecardPath, scorecard);
  _write(_weeklyPath, weekly);
  _write(_finalPath, finalReview);

  stdout.writeln('Updated $_scorecardPath, $_weeklyPath, and $_finalPath');
}

void _write(String path, String content) {
  final f = File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  if (!f.existsSync()) {
    stderr.writeln('ERROR: failed to write $path');
    exit(1);
  }
}

_BoardSnapshot _loadBoardSnapshot() {
  final file = File(_csvPath);
  if (!file.existsSync()) {
    return const _BoardSnapshot(
      trackedMilestones: <_Milestone>[],
      statusByMilestone: <String, String>{},
    );
  }

  final lines = const LineSplitter().convert(file.readAsStringSync());
  if (lines.isEmpty) {
    return const _BoardSnapshot(
      trackedMilestones: <_Milestone>[],
      statusByMilestone: <String, String>{},
    );
  }

  final header = _splitCsvLine(lines.first);
  final idx = {for (var i = 0; i < header.length; i++) header[i]: i};

  final tracked = <_Milestone>[];
  final statusByMilestone = <String, String>{};

  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final row = _splitCsvLine(line);
    if (_cell(row, idx, 'type') != 'milestone') continue;

    final id = _cell(row, idx, 'id');
    final status = _cell(row, idx, 'status');
    statusByMilestone[id] = status;

    if (!_trackedMilestones.contains(id)) continue;

    tracked.add(
      _Milestone(
        id: id,
        status: status,
        owner: _cell(row, idx, 'owner_r'),
        dependencies: _cell(row, idx, 'dependencies'),
        targetWindow: _cell(row, idx, 'target_window'),
        priority: _cell(row, idx, 'priority'),
        riskScore: _cell(row, idx, 'risk_score'),
        exitCriteria: _cell(row, idx, 'exit_criteria'),
        evidence: _cell(row, idx, 'evidence'),
      ),
    );
  }

  tracked.sort((a, b) => a.id.compareTo(b.id));

  return _BoardSnapshot(
    trackedMilestones: tracked,
    statusByMilestone: statusByMilestone,
  );
}

_TelemetrySummary _loadTelemetrySummary() {
  final f = File(_telemetrySummaryPath);
  if (!f.existsSync()) {
    return const _TelemetrySummary(
      hasData: false,
      totalDecisions: 0,
      shadowBypassDecisions: 0,
      shadowBypassRate: 0.0,
      enforceDecisions: 0,
      enforceBlockedDecisions: 0,
      enforceBlockRate: 0.0,
      highImpactEnforceDecisions: 0,
      highImpactEnforceBlockedDecisions: 0,
      highImpactEnforceBlockRate: 0.0,
      topReasonCodes: <String>[],
      windowStart: null,
      windowEnd: null,
      note: 'Telemetry summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    final byReason = (m['by_reason'] is Map)
        ? (m['by_reason'] as Map).map((k, v) => MapEntry('$k', v))
        : <String, dynamic>{};
    final sortedReasons = byReason.entries.toList()
      ..sort((a, b) => _asInt(b.value).compareTo(_asInt(a.value)));

    return _TelemetrySummary(
      hasData: m['has_data'] == true,
      totalDecisions: _asInt(m['total_decisions']),
      shadowBypassDecisions: _asInt(m['shadow_bypass_decisions']),
      shadowBypassRate: _asDouble(m['shadow_bypass_rate']),
      enforceDecisions: _asInt(m['enforce_decisions']),
      enforceBlockedDecisions: _asInt(m['enforce_blocked_decisions']),
      enforceBlockRate: _asDouble(m['enforce_block_rate']),
      highImpactEnforceDecisions: _asInt(m['high_impact_enforce_decisions']),
      highImpactEnforceBlockedDecisions:
          _asInt(m['high_impact_enforce_blocked_decisions']),
      highImpactEnforceBlockRate:
          _asDouble(m['high_impact_enforce_block_rate']),
      topReasonCodes: sortedReasons.take(3).map((e) => e.key).toList(),
      windowStart: _asStringOrNull(m['window_start']),
      windowEnd: _asStringOrNull(m['window_end']),
      note: _asStringOrNull(m['reason']),
    );
  } catch (e) {
    return _TelemetrySummary(
      hasData: false,
      totalDecisions: 0,
      shadowBypassDecisions: 0,
      shadowBypassRate: 0.0,
      enforceDecisions: 0,
      enforceBlockedDecisions: 0,
      enforceBlockRate: 0.0,
      highImpactEnforceDecisions: 0,
      highImpactEnforceBlockedDecisions: 0,
      highImpactEnforceBlockRate: 0.0,
      topReasonCodes: const <String>[],
      windowStart: null,
      windowEnd: null,
      note: 'Telemetry summary parse error: $e',
    );
  }
}

_RollbackDrillSummary _loadRollbackDrillSummary() {
  final f = File(_rollbackDrillSummaryPath);
  if (!f.existsSync()) {
    return const _RollbackDrillSummary(
      hasData: false,
      verdict: 'NO_DATA',
      rollbackRequiredIncidents: 0,
      totalIncidents: 0,
      failClosed: false,
      note: 'Rollback drill summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    return _RollbackDrillSummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      rollbackRequiredIncidents: _asInt(m['rollback_required_incidents']),
      totalIncidents: _asInt(m['total_incidents']),
      failClosed: m['rollback_profile_fail_closed'] == true,
      note: null,
    );
  } catch (e) {
    return _RollbackDrillSummary(
      hasData: false,
      verdict: 'NO_DATA',
      rollbackRequiredIncidents: 0,
      totalIncidents: 0,
      failClosed: false,
      note: 'Rollback drill summary parse error: $e',
    );
  }
}

_ReplicationSlaSummary _loadReplicationSlaSummary() {
  final f = File(_replicationSlaSummaryPath);
  if (!f.existsSync()) {
    return const _ReplicationSlaSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalItems: 0,
      activeItems: 0,
      overdueItems: 0,
      slaCompliant: false,
      note: 'Replication SLA summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    return _ReplicationSlaSummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      totalItems: _asInt(m['total_items']),
      activeItems: _asInt(m['active_items']),
      overdueItems: _asInt(m['overdue_items']),
      slaCompliant: m['active_sla_compliant'] == true,
      note: null,
    );
  } catch (e) {
    return _ReplicationSlaSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalItems: 0,
      activeItems: 0,
      overdueItems: 0,
      slaCompliant: false,
      note: 'Replication SLA summary parse error: $e',
    );
  }
}

_TrustUxSummary _loadTrustUxSummary() {
  final f = File(_trustUxSummaryPath);
  if (!f.existsSync()) {
    return const _TrustUxSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalFlows: 0,
      implementedFlows: 0,
      coverageRatio: 0.0,
      contractOk: false,
      note: 'Trust UX summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    return _TrustUxSummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      totalFlows: _asInt(m['total_flows']),
      implementedFlows: _asInt(m['implemented_flows']),
      coverageRatio: _asDouble(m['implemented_coverage_ratio']),
      contractOk: m['contract_ok'] == true,
      note: null,
    );
  } catch (e) {
    return _TrustUxSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalFlows: 0,
      implementedFlows: 0,
      coverageRatio: 0.0,
      contractOk: false,
      note: 'Trust UX summary parse error: $e',
    );
  }
}

_SelfHealingSummary _loadSelfHealingSummary() {
  final f = File(_selfHealingSummaryPath);
  if (!f.existsSync()) {
    return const _SelfHealingSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalIncidents: 0,
      activeIncidents: 0,
      sloBreaches: 0,
      sloCompliant: false,
      note: 'Self-healing summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    return _SelfHealingSummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      totalIncidents: _asInt(m['total_incidents']),
      activeIncidents: _asInt(m['active_incidents']),
      sloBreaches: _asInt(m['slo_breaches']),
      sloCompliant: m['slo_compliant'] == true,
      note: null,
    );
  } catch (e) {
    return _SelfHealingSummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalIncidents: 0,
      activeIncidents: 0,
      sloBreaches: 0,
      sloCompliant: false,
      note: 'Self-healing summary parse error: $e',
    );
  }
}

_LineageTransparencySummary _loadLineageTransparencySummary() {
  final f = File(_lineageTransparencySummaryPath);
  if (!f.existsSync()) {
    return const _LineageTransparencySummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalFlows: 0,
      implementedFlows: 0,
      coverageRatio: 0.0,
      contractOk: false,
      note: 'Lineage transparency summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    return _LineageTransparencySummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      totalFlows: _asInt(m['total_flows']),
      implementedFlows: _asInt(m['implemented_flows']),
      coverageRatio: _asDouble(m['implemented_coverage_ratio']),
      contractOk: m['contract_ok'] == true,
      note: null,
    );
  } catch (e) {
    return _LineageTransparencySummary(
      hasData: false,
      verdict: 'NO_DATA',
      totalFlows: 0,
      implementedFlows: 0,
      coverageRatio: 0.0,
      contractOk: false,
      note: 'Lineage transparency summary parse error: $e',
    );
  }
}

_CompletionAuditSummary _loadCompletionAuditSummary() {
  final f = File(_completionAuditSummaryPath);
  if (!f.existsSync()) {
    return const _CompletionAuditSummary(
      hasData: false,
      verdict: 'NO_DATA',
      gatesReady: false,
      documentsReady: false,
      signoffReady: false,
      missingReports: 0,
      missingDocuments: 0,
      missingSignoffRoles: 0,
      approvedSignoffRoles: <String>[],
      missingSignoffRoleNames: <String>[],
      note: 'Completion audit summary file missing',
    );
  }

  try {
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object');
    }
    final m = decoded.map((k, v) => MapEntry('$k', v));
    final missingReports = (m['missing_reports'] is List)
        ? (m['missing_reports'] as List).length
        : 0;
    final missingDocuments = (m['missing_documents'] is List)
        ? (m['missing_documents'] as List).length
        : 0;
    final missingSignoffRoles = (m['missing_signoff_roles'] is List)
        ? (m['missing_signoff_roles'] as List).length
        : 0;
    final approvedSignoffRoles = (m['approved_signoff_roles'] is List)
        ? (m['approved_signoff_roles'] as List)
            .map((e) => '$e')
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final missingSignoffRoleNames = (m['missing_signoff_roles'] is List)
        ? (m['missing_signoff_roles'] as List)
            .map((e) => '$e')
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    return _CompletionAuditSummary(
      hasData: true,
      verdict: _asStringOrNull(m['verdict']) ?? 'UNKNOWN',
      gatesReady: m['gates_ready'] == true,
      documentsReady: m['documents_ready'] == true,
      signoffReady: m['signoff_ready'] == true,
      missingReports: missingReports,
      missingDocuments: missingDocuments,
      missingSignoffRoles: missingSignoffRoles,
      approvedSignoffRoles: approvedSignoffRoles,
      missingSignoffRoleNames: missingSignoffRoleNames,
      note: null,
    );
  } catch (e) {
    return _CompletionAuditSummary(
      hasData: false,
      verdict: 'NO_DATA',
      gatesReady: false,
      documentsReady: false,
      signoffReady: false,
      missingReports: 0,
      missingDocuments: 0,
      missingSignoffRoles: 0,
      approvedSignoffRoles: const <String>[],
      missingSignoffRoleNames: const <String>[],
      note: 'Completion audit summary parse error: $e',
    );
  }
}

String _buildScorecard(
  String date,
  List<_Milestone> ms,
  _TelemetrySummary telemetry,
  _RollbackDrillSummary rollbackDrill,
  _ReplicationSlaSummary replicationSla,
  _TrustUxSummary trustUx,
  _SelfHealingSummary selfHealing,
  _LineageTransparencySummary lineageTransparency,
  _CompletionAuditSummary completionAudit,
) {
  String statusFor(List<String> ids) {
    final rows = ms.where((m) => ids.contains(m.id)).toList();
    if (rows.length != ids.length) return 'Red';
    if (rows.any((m) => m.status == 'Blocked')) return 'Red';
    if (rows.every((m) => m.status == 'Done')) return 'Green';
    return 'Yellow';
  }

  final gates = <Map<String, String>>[
    {
      'id': 'G1',
      'name': 'Lifecycle coverage (100% governed claims)',
      'owner': 'Platform Eng',
      'status': statusFor(['M4-P3-1']),
      'notes': 'M4-P3-1 lifecycle baseline and code evidence',
    },
    {
      'id': 'G2',
      'name': 'Conviction/policy enforcement on high-impact actions',
      'owner': 'Runtime/OS Eng',
      'status': statusFor(['M5-P3-1']),
      'notes':
          'M5-P3-1 production gate authority; shadow bypass target <= ${(_shadowBypassRateTarget * 100).toStringAsFixed(1)}%',
    },
    {
      'id': 'G3',
      'name': 'Independent replication before operational/canonical',
      'owner': 'ML Research',
      'status': statusFor(['M5-P3-3']),
      'notes': 'M5-P3-3 replication queue and SLA',
    },
    {
      'id': 'G4',
      'name': 'Canary + rollback live-fire drill success',
      'owner': 'Reliability',
      'status': statusFor(['M5-P3-2']),
      'notes': 'M5-P3-2 canary rollback automation',
    },
    {
      'id': 'G5',
      'name': 'Self-healing SLO (detect -> contain -> recover)',
      'owner': 'Reliability',
      'status': statusFor(['M6-P3-1']),
      'notes': 'M6-P3-1 cross-domain incident routing',
    },
    {
      'id': 'G6',
      'name': 'Transparency coverage (confidence/provenance surfaces)',
      'owner': 'Product',
      'status': statusFor(['M5-P3-4', 'M6-P3-2']),
      'notes': 'M5/M6 transparency UX coverage',
    },
    {
      'id': 'G7',
      'name': 'Immutable audit reconstruction completeness',
      'owner': 'Governance/Security',
      'status': statusFor(['M6-P3-3']),
      'notes': 'M6-P3-3 final readiness audit package',
    },
  ];

  final goNoGo =
      gates.any((g) => g['status'] == 'Red') ? 'HOLD' : 'IN PROGRESS';

  final b = StringBuffer();
  b.writeln('# Master Plan 3-Prong Readiness Scorecard (One-Page)\n');
  b.writeln('**Version:** v1.1  ');
  b.writeln('**Date:** $date  ');
  b.writeln(
      '**Scope:** Final readiness review for `AVRAI Product` + `AVRAI OS` + `Reality System`  ');
  b.writeln(
      '**Generated from:** `docs/EXECUTION_BOARD.csv` via `tool/update_three_prong_reviews.dart`\n');
  b.writeln(
      'Use this scorecard for weekly readiness review and final sign-off.\n');
  b.writeln('---\n');
  b.writeln('## A) Gate Status Summary\n');
  b.writeln(
      '| Gate | Status (G/Y/R) | Owner | Evidence Link | Notes/Blockers |');
  b.writeln(
      '|------|-----------------|-------|---------------|----------------|');
  for (final g in gates) {
    b.writeln(
      '| ${g['id']} ${g['name']} | ${g['status']} | ${g['owner']} | - | ${g['notes']} |',
    );
  }

  b.writeln(
      '\n**Go/No-Go Rule:** No `Red` allowed. `Yellow` requires explicit waiver and dated remediation plan.');
  b.writeln('\n---\n');
  b.writeln('## B) KPI Snapshot\n');
  b.writeln('| KPI | Current | Target | Trend | Owner |');
  b.writeln('|-----|---------|--------|-------|-------|');
  b.writeln(
      '| Calibration error (critical domains) | TBD | <= target per domain | TBD | ML Research |');
  b.writeln(
      '| Promotion-to-demotion ratio | TBD | >= target | TBD | Runtime/OS |');
  b.writeln('| Drift detection latency | TBD | <= SLO | TBD | Reliability |');
  b.writeln(
      '| MTTR for autonomous P0/P1 incidents | TBD | <= SLO | TBD | Reliability |');
  b.writeln(
      '| Replication pass rate pre-promotion | TBD | >= threshold | TBD | ML Research |');
  b.writeln(
      '| High-impact confusion/correction rate | TBD | <= threshold | TBD | Product |');
  b.writeln(
      '| Rollback success rate | TBD | 100% in drills | TBD | Reliability |');
  b.writeln(
      '| 7/30/90-day delayed-outcome alignment | TBD | >= threshold | TBD | ML Research |');
  final bypassCurrent = telemetry.hasData
      ? '${(telemetry.shadowBypassRate * 100).toStringAsFixed(2)}% (${telemetry.shadowBypassDecisions}/${telemetry.totalDecisions})'
      : 'No data';
  final bypassTrend = telemetry.hasData ? 'Observed' : 'No data';
  b.writeln(
      '| Shadow bypass rate (high-impact shadow gate) | $bypassCurrent | <= ${(_shadowBypassRateTarget * 100).toStringAsFixed(1)}% | $bypassTrend | Runtime/OS |');
  final enforceCurrent = telemetry.hasData
      ? '${(telemetry.enforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.enforceBlockedDecisions}/${telemetry.enforceDecisions})'
      : 'No data';
  b.writeln(
      '| Enforce-mode block rate (all enforce decisions) | $enforceCurrent | Tracked in canary; no unexplained spikes | ${telemetry.hasData ? 'Observed' : 'No data'} | Runtime/OS |');
  final highImpactEnforceCurrent = telemetry.hasData
      ? '${(telemetry.highImpactEnforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.highImpactEnforceBlockedDecisions}/${telemetry.highImpactEnforceDecisions})'
      : 'No data';
  b.writeln(
      '| Enforce-mode block rate (high-impact only) | $highImpactEnforceCurrent | Tracked in canary; policy-consistent blocks only | ${telemetry.hasData ? 'Observed' : 'No data'} | Runtime/OS |');
  b.writeln(
      '| Top shadow reason codes | ${telemetry.topReasonCodes.isEmpty ? 'No data' : telemetry.topReasonCodes.join(", ")} | No persistent unresolved policy reasons | ${telemetry.hasData ? 'Observed' : 'No data'} | Runtime/OS |');
  b.writeln(
      '| Canary rollback drill verdict | ${rollbackDrill.verdict} (${rollbackDrill.rollbackRequiredIncidents}/${rollbackDrill.totalIncidents} incidents required rollback) | PASS with fail-closed profile | ${rollbackDrill.hasData ? 'Observed' : 'No data'} | Reliability |');
  b.writeln(
      '| Replication SLA verdict | ${replicationSla.verdict} (overdue=${replicationSla.overdueItems}, active=${replicationSla.activeItems}) | PASS with overdue active items = 0 | ${replicationSla.hasData ? 'Observed' : 'No data'} | ML Research |');
  b.writeln(
      '| Trust UX priority-flow verdict | ${trustUx.verdict} (implemented=${trustUx.implementedFlows}/${trustUx.totalFlows}, coverage=${(trustUx.coverageRatio * 100).toStringAsFixed(0)}%) | PASS with contract-complete priority flows | ${trustUx.hasData ? 'Observed' : 'No data'} | Product |');
  b.writeln(
      '| Self-healing incident routing verdict | ${selfHealing.verdict} (slo_breaches=${selfHealing.sloBreaches}, active=${selfHealing.activeIncidents}, total=${selfHealing.totalIncidents}) | PASS with detect/contain/recover SLO compliance | ${selfHealing.hasData ? 'Observed' : 'No data'} | Reliability |');
  b.writeln(
      '| Lineage transparency priority-flow verdict | ${lineageTransparency.verdict} (implemented=${lineageTransparency.implementedFlows}/${lineageTransparency.totalFlows}, coverage=${(lineageTransparency.coverageRatio * 100).toStringAsFixed(0)}%) | PASS with what-changed lineage fields on priority flows | ${lineageTransparency.hasData ? 'Observed' : 'No data'} | Product |');
  b.writeln(
      '| Completion audit package verdict | ${completionAudit.verdict} (missing_reports=${completionAudit.missingReports}, missing_documents=${completionAudit.missingDocuments}, missing_signoffs=${completionAudit.missingSignoffRoles}) | PASS with gates+documents+sign-offs ready | ${completionAudit.hasData ? 'Observed' : 'No data'} | Governance |');
  b.writeln('\n---\n');
  b.writeln('## C) 3-Prong Operational Readiness\n');
  b.writeln('| Prong | Status (G/Y/R) | Must-Pass Conditions |');
  b.writeln('|------|-----------------|----------------------|');
  b.writeln('| AVRAI Product | ${statusFor([
        'M5-P3-4',
        'M6-P3-2'
      ])} | High-impact surfaces show confidence/provenance/last-validated; user correction loop live |');
  b.writeln('| AVRAI OS | ${statusFor([
        'M4-P3-2',
        'M5-P3-1',
        'M5-P3-2',
        'M6-P3-3'
      ])} | Conviction gate enforced; canary+rollback active; policy/audit logs immutable |');
  b.writeln('| Reality System | ${statusFor([
        'M4-P3-1',
        'M4-P3-3',
        'M5-P3-3',
        'M6-P3-1'
      ])} | Promotion ladder enforced; contradiction auto-demotion active; novelty quarantine in place |');
  b.writeln('\n---\n');
  b.writeln('## D) Open Risks and Mitigations\n');
  b.writeln('| Risk | Severity | Mitigation | Owner | Due Date |');
  b.writeln('|------|----------|------------|-------|----------|');
  b.writeln(
      '| 3-prong critical milestones still in backlog (`M4-P3-*`, `M5-P3-*`, `M6-P3-*`) | High | Move Day 0-30 milestones to `Ready`/`In Progress` and attach evidence to board rows | AP / REL / MLE | Next weekly review |');
  b.writeln(
      '| Conviction runtime gates not yet production-enforced | High | Complete `M5-P3-1` and validate policy-gate telemetry | REL | Day 31-60 target |');
  b.writeln(
      '| Final readiness audit not started | High | Complete `M6-P3-3` with drill evidence and immutable reconstruction proof | GOV | Day 61-90 target |');
  b.writeln('\n---\n');
  b.writeln('## E) Sign-Off\n');
  b.writeln('| Function | Name | Decision (Approve/Hold) | Date |');
  b.writeln('|----------|------|--------------------------|------|');
  b.writeln('| Product |  |  |  |');
  b.writeln('| Engineering (Platform/OS) |  |  |  |');
  b.writeln('| ML Research |  |  |  |');
  b.writeln('| Reliability/SRE |  |  |  |');
  b.writeln('| Security/Compliance |  |  |  |');
  b.writeln('| Governance/Executive |  |  |  |');
  b.writeln('\n**Final Decision:** `$goNoGo`  ');
  b.writeln('**If HOLD:** Required actions and target re-review date:');

  return b.toString();
}

String _buildWeekly(
  String date,
  List<_Milestone> ms,
  Map<String, String> statusByMilestone,
  _TelemetrySummary telemetry,
  _RollbackDrillSummary rollbackDrill,
  _ReplicationSlaSummary replicationSla,
  _TrustUxSummary trustUx,
  _SelfHealingSummary selfHealing,
  _LineageTransparencySummary lineageTransparency,
  _CompletionAuditSummary completionAudit,
) {
  final counts = <String, int>{
    'Backlog': 0,
    'Ready': 0,
    'In Progress': 0,
    'Blocked': 0,
    'Done': 0,
  };
  for (final m in ms) {
    counts[m.status] = (counts[m.status] ?? 0) + 1;
  }

  String ids(String status) {
    final list =
        ms.where((m) => m.status == status).map((m) => '`${m.id}`').toList();
    return list.isEmpty ? 'None' : list.join(', ');
  }

  final focus = ms
      .where((m) =>
          m.status == 'In Progress' ||
          m.status == 'Ready' ||
          m.status == 'Backlog')
      .take(3)
      .toList();

  final b = StringBuffer();
  b.writeln('# Master Plan 3-Prong Weekly Review (Auto)\n');
  b.writeln('**Week of:** $date  ');
  b.writeln(
      '**Generated from:** `docs/EXECUTION_BOARD.csv` via `tool/update_three_prong_reviews.dart`\n');
  b.writeln('---\n');
  b.writeln('## 1) Status Snapshot\n');
  b.writeln('- Total 3-prong milestones: ${ms.length}');
  b.writeln('- `Backlog`: ${counts['Backlog']}');
  b.writeln('- `Ready`: ${counts['Ready']}');
  b.writeln('- `In Progress`: ${counts['In Progress']}');
  b.writeln('- `Blocked`: ${counts['Blocked']}');
  b.writeln('- `Done`: ${counts['Done']}\n');
  b.writeln('### Milestone IDs by Status\n');
  b.writeln('- `Backlog`: ${ids('Backlog')}');
  b.writeln('- `Ready`: ${ids('Ready')}');
  b.writeln('- `In Progress`: ${ids('In Progress')}');
  b.writeln('- `Blocked`: ${ids('Blocked')}');
  b.writeln('- `Done`: ${ids('Done')}\n');
  b.writeln('### Shadow Gate Telemetry Snapshot\n');
  final bypassPct = (telemetry.shadowBypassRate * 100).toStringAsFixed(2);
  final telemetryGatePass = telemetry.hasData &&
      telemetry.shadowBypassRate <= _shadowBypassRateTarget;
  b.writeln('- Source: `$_telemetrySummaryPath`');
  b.writeln(
      '- Bypass rate: ${telemetry.hasData ? '$bypassPct% (${telemetry.shadowBypassDecisions}/${telemetry.totalDecisions})' : 'No data'}');
  b.writeln(
      '- Enforce block rate (all enforce decisions): ${telemetry.hasData ? '${(telemetry.enforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.enforceBlockedDecisions}/${telemetry.enforceDecisions})' : 'No data'}');
  b.writeln(
      '- Enforce block rate (high-impact only): ${telemetry.hasData ? '${(telemetry.highImpactEnforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.highImpactEnforceBlockedDecisions}/${telemetry.highImpactEnforceDecisions})' : 'No data'}');
  b.writeln(
      '- Threshold: <= ${(_shadowBypassRateTarget * 100).toStringAsFixed(1)}%');
  b.writeln(
      '- Gate status: ${telemetry.hasData ? (telemetryGatePass ? 'PASS' : 'FAIL') : 'NO_DATA'}');
  if (telemetry.topReasonCodes.isNotEmpty) {
    b.writeln('- Top reason codes: ${telemetry.topReasonCodes.join(', ')}');
  }
  if (telemetry.windowStart != null || telemetry.windowEnd != null) {
    b.writeln(
        '- Window: ${telemetry.windowStart ?? '-'} -> ${telemetry.windowEnd ?? '-'}');
  }
  if (!telemetry.hasData &&
      telemetry.note != null &&
      telemetry.note!.isNotEmpty) {
    b.writeln('- Note: ${telemetry.note}');
  }
  b.writeln('- Canary rollback drill source: `$_rollbackDrillSummaryPath`');
  b.writeln(
      '- Canary rollback drill verdict: ${rollbackDrill.verdict} (${rollbackDrill.rollbackRequiredIncidents}/${rollbackDrill.totalIncidents} incidents required rollback)');
  b.writeln(
      '- Fail-closed rollback profile: ${rollbackDrill.hasData ? (rollbackDrill.failClosed ? 'PASS' : 'FAIL') : 'NO_DATA'}');
  b.writeln(
      '- Canary Rollout Go/No-Go: ${rollbackDrill.hasData && rollbackDrill.verdict == 'PASS' && rollbackDrill.failClosed ? 'GO' : 'HOLD'}');
  b.writeln('- Replication SLA source: `$_replicationSlaSummaryPath`');
  b.writeln(
      '- Replication SLA verdict: ${replicationSla.verdict} (overdue=${replicationSla.overdueItems}, active=${replicationSla.activeItems})');
  b.writeln(
      '- Replication SLA Gate: ${replicationSla.hasData && replicationSla.slaCompliant ? 'PASS' : 'FAIL'}');
  b.writeln('- Trust UX source: `$_trustUxSummaryPath`');
  b.writeln(
      '- Trust UX verdict: ${trustUx.verdict} (implemented=${trustUx.implementedFlows}/${trustUx.totalFlows}, coverage=${(trustUx.coverageRatio * 100).toStringAsFixed(0)}%)');
  b.writeln(
      '- Trust UX Gate: ${trustUx.hasData && trustUx.contractOk ? 'PASS' : 'FAIL'}');
  b.writeln('- Self-healing source: `$_selfHealingSummaryPath`');
  b.writeln(
      '- Self-healing verdict: ${selfHealing.verdict} (slo_breaches=${selfHealing.sloBreaches}, active=${selfHealing.activeIncidents}, total=${selfHealing.totalIncidents})');
  b.writeln(
      '- Self-healing Gate: ${selfHealing.hasData && selfHealing.sloCompliant ? 'PASS' : 'FAIL'}');
  b.writeln(
      '- Lineage transparency source: `$_lineageTransparencySummaryPath`');
  b.writeln(
      '- Lineage transparency verdict: ${lineageTransparency.verdict} (implemented=${lineageTransparency.implementedFlows}/${lineageTransparency.totalFlows}, coverage=${(lineageTransparency.coverageRatio * 100).toStringAsFixed(0)}%)');
  b.writeln(
      '- Lineage transparency Gate: ${lineageTransparency.hasData && lineageTransparency.contractOk ? 'PASS' : 'FAIL'}');
  b.writeln('- Completion audit source: `$_completionAuditSummaryPath`');
  b.writeln(
      '- Completion audit verdict: ${completionAudit.verdict} (missing_reports=${completionAudit.missingReports}, missing_documents=${completionAudit.missingDocuments}, missing_signoffs=${completionAudit.missingSignoffRoles})');
  b.writeln(
      '- Completion audit Gate: ${completionAudit.hasData && completionAudit.gatesReady && completionAudit.documentsReady && completionAudit.signoffReady && completionAudit.verdict == 'PASS' ? 'PASS' : 'FAIL'}');
  if (!rollbackDrill.hasData &&
      rollbackDrill.note != null &&
      rollbackDrill.note!.isNotEmpty) {
    b.writeln('- Rollback drill note: ${rollbackDrill.note}');
  }
  if (!selfHealing.hasData &&
      selfHealing.note != null &&
      selfHealing.note!.isNotEmpty) {
    b.writeln('- Self-healing note: ${selfHealing.note}');
  }
  if (!lineageTransparency.hasData &&
      lineageTransparency.note != null &&
      lineageTransparency.note!.isNotEmpty) {
    b.writeln('- Lineage transparency note: ${lineageTransparency.note}');
  }
  if (!completionAudit.hasData &&
      completionAudit.note != null &&
      completionAudit.note!.isNotEmpty) {
    b.writeln('- Completion audit note: ${completionAudit.note}');
  }
  b.writeln();
  b.writeln('---\n');
  b.writeln('## 2) Recommended Next Focus\n');
  b.writeln('| Milestone | Owner | Target Window | Risk | Exit Gate |');
  b.writeln('|---|---|---|---|---|');
  for (final m in focus) {
    b.writeln(
      '| ${m.id} | ${m.owner.replaceAll(';', ', ')} | ${m.targetWindow} | ${m.priority} (${m.riskScore}) | ${m.exitCriteria} |',
    );
  }

  b.writeln('\n---\n');
  b.writeln('## 3) Owner Handoff (Auto)\n');
  b.writeln(
      '| Milestone | Owner | Status | Unresolved Dependencies | Next Action |');
  b.writeln('|---|---|---|---|---|');

  for (final m in ms.where((e) => e.status != 'Done')) {
    final unresolved =
        _unresolvedDependencies(m.dependencies, statusByMilestone);
    final unresolvedText = unresolved.isEmpty ? 'None' : unresolved.join(', ');
    final nextAction = unresolved.isEmpty
        ? (m.exitCriteria.isEmpty
            ? 'Start execution and attach evidence'
            : m.exitCriteria)
        : 'Unblock dependencies before execution';

    b.writeln(
      '| ${m.id} | ${m.owner.replaceAll(';', ', ')} | ${m.status} | $unresolvedText | $nextAction |',
    );
  }

  b.writeln('\n---\n');
  b.writeln('## 4) Automation Notes\n');
  b.writeln('1. Generated from execution board milestone states.');
  b.writeln(
      '2. Use `docs/STATUS_WEEKLY.md` for manual narrative/evidence additions.');
  b.writeln('3. Go/no-go remains controlled by final review gates.');

  return b.toString();
}

String _buildFinal(
  String date,
  List<_Milestone> ms,
  _TelemetrySummary telemetry,
  _RollbackDrillSummary rollbackDrill,
  _ReplicationSlaSummary replicationSla,
  _TrustUxSummary trustUx,
  _SelfHealingSummary selfHealing,
  _LineageTransparencySummary lineageTransparency,
  _CompletionAuditSummary completionAudit,
) {
  final blockers = ms.where((m) => m.status != 'Done').toList();
  final telemetryGatePass = telemetry.hasData &&
      telemetry.shadowBypassRate <= _shadowBypassRateTarget;
  final rollbackGatePass = rollbackDrill.hasData &&
      rollbackDrill.verdict == 'PASS' &&
      rollbackDrill.failClosed;
  final replicationGatePass =
      replicationSla.hasData && replicationSla.slaCompliant;
  final trustUxGatePass = trustUx.hasData && trustUx.contractOk;
  final selfHealingGatePass = selfHealing.hasData && selfHealing.sloCompliant;
  final lineageTransparencyGatePass =
      lineageTransparency.hasData && lineageTransparency.contractOk;
  final completionAuditGatePass = completionAudit.hasData &&
      completionAudit.gatesReady &&
      completionAudit.documentsReady &&
      completionAudit.verdict == 'PASS';
  final verdict = blockers.isEmpty &&
          telemetryGatePass &&
          rollbackGatePass &&
          replicationGatePass &&
          trustUxGatePass &&
          selfHealingGatePass &&
          lineageTransparencyGatePass &&
          completionAuditGatePass
      ? 'GO'
      : 'HOLD';

  final b = StringBuffer();
  b.writeln('# Master Plan 3-Prong Final Review (Auto)\n');
  b.writeln('**Date:** $date  ');
  b.writeln(
      '**Generated from:** `docs/EXECUTION_BOARD.csv` via `tool/update_three_prong_reviews.dart`\n');
  b.writeln('## Verdict\n');
  b.writeln('**$verdict**\n');

  if (blockers.isNotEmpty) {
    b.writeln(
        'Go-live gates are not yet complete; one or more tracked milestones are not `Done`.\n');
    b.writeln('## Outstanding Blockers\n');
    for (final m in blockers) {
      b.writeln('- ${m.id}: status=${m.status}');
    }
    b.writeln();
  }

  b.writeln('## Shadow Telemetry Gate\n');
  b.writeln('- Source: `$_telemetrySummaryPath`');
  b.writeln(
      '- Bypass rate threshold: <= ${(_shadowBypassRateTarget * 100).toStringAsFixed(1)}%');
  if (telemetry.hasData) {
    b.writeln(
        '- Current bypass rate: ${(telemetry.shadowBypassRate * 100).toStringAsFixed(2)}% (${telemetry.shadowBypassDecisions}/${telemetry.totalDecisions})');
    b.writeln('- Result: ${telemetryGatePass ? 'PASS' : 'FAIL'}');
    b.writeln(
        '- Enforce block rate (all): ${(telemetry.enforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.enforceBlockedDecisions}/${telemetry.enforceDecisions})');
    b.writeln(
        '- Enforce block rate (high-impact): ${(telemetry.highImpactEnforceBlockRate * 100).toStringAsFixed(2)}% (${telemetry.highImpactEnforceBlockedDecisions}/${telemetry.highImpactEnforceDecisions})');
    if (telemetry.topReasonCodes.isNotEmpty) {
      b.writeln('- Top reason codes: ${telemetry.topReasonCodes.join(', ')}');
    }
  } else {
    b.writeln('- Current bypass rate: No data');
    b.writeln('- Result: FAIL (no telemetry data)');
    if (telemetry.note != null && telemetry.note!.isNotEmpty) {
      b.writeln('- Note: ${telemetry.note}');
    }
  }
  b.writeln();
  b.writeln('## Canary Rollback Drill Gate\n');
  b.writeln('- Source: `$_rollbackDrillSummaryPath`');
  if (rollbackDrill.hasData) {
    b.writeln(
        '- Drill verdict: ${rollbackDrill.verdict} (${rollbackDrill.rollbackRequiredIncidents}/${rollbackDrill.totalIncidents} incidents required rollback)');
    b.writeln(
        '- Fail-closed rollback profile: ${rollbackDrill.failClosed ? 'PASS' : 'FAIL'}');
    b.writeln('- Result: ${rollbackGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- Drill verdict: NO_DATA');
    b.writeln('- Result: FAIL (no rollback drill data)');
    if (rollbackDrill.note != null && rollbackDrill.note!.isNotEmpty) {
      b.writeln('- Note: ${rollbackDrill.note}');
    }
  }
  b.writeln();
  b.writeln('## Replication SLA Gate\n');
  b.writeln('- Source: `$_replicationSlaSummaryPath`');
  if (replicationSla.hasData) {
    b.writeln(
        '- SLA verdict: ${replicationSla.verdict} (overdue=${replicationSla.overdueItems}, active=${replicationSla.activeItems}, total=${replicationSla.totalItems})');
    b.writeln('- Result: ${replicationGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- SLA verdict: NO_DATA');
    b.writeln('- Result: FAIL (no replication SLA data)');
    if (replicationSla.note != null && replicationSla.note!.isNotEmpty) {
      b.writeln('- Note: ${replicationSla.note}');
    }
  }
  b.writeln();
  b.writeln('## Trust UX Gate\n');
  b.writeln('- Source: `$_trustUxSummaryPath`');
  if (trustUx.hasData) {
    b.writeln(
        '- Trust UX verdict: ${trustUx.verdict} (implemented=${trustUx.implementedFlows}/${trustUx.totalFlows}, coverage=${(trustUx.coverageRatio * 100).toStringAsFixed(0)}%)');
    b.writeln('- Result: ${trustUxGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- Trust UX verdict: NO_DATA');
    b.writeln('- Result: FAIL (no trust UX data)');
    if (trustUx.note != null && trustUx.note!.isNotEmpty) {
      b.writeln('- Note: ${trustUx.note}');
    }
  }
  b.writeln();
  b.writeln('## Self-Healing Incident Routing Gate\n');
  b.writeln('- Source: `$_selfHealingSummaryPath`');
  if (selfHealing.hasData) {
    b.writeln(
        '- Self-healing verdict: ${selfHealing.verdict} (slo_breaches=${selfHealing.sloBreaches}, active=${selfHealing.activeIncidents}, total=${selfHealing.totalIncidents})');
    b.writeln('- Result: ${selfHealingGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- Self-healing verdict: NO_DATA');
    b.writeln('- Result: FAIL (no self-healing data)');
    if (selfHealing.note != null && selfHealing.note!.isNotEmpty) {
      b.writeln('- Note: ${selfHealing.note}');
    }
  }
  b.writeln();
  b.writeln('## Lineage Transparency Gate\n');
  b.writeln('- Source: `$_lineageTransparencySummaryPath`');
  if (lineageTransparency.hasData) {
    b.writeln(
        '- Lineage transparency verdict: ${lineageTransparency.verdict} (implemented=${lineageTransparency.implementedFlows}/${lineageTransparency.totalFlows}, coverage=${(lineageTransparency.coverageRatio * 100).toStringAsFixed(0)}%)');
    b.writeln('- Result: ${lineageTransparencyGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- Lineage transparency verdict: NO_DATA');
    b.writeln('- Result: FAIL (no lineage transparency data)');
    if (lineageTransparency.note != null &&
        lineageTransparency.note!.isNotEmpty) {
      b.writeln('- Note: ${lineageTransparency.note}');
    }
  }
  b.writeln();
  b.writeln('## Completion Audit Package Gate\n');
  b.writeln('- Source: `$_completionAuditSummaryPath`');
  if (completionAudit.hasData) {
    b.writeln(
        '- Completion audit verdict: ${completionAudit.verdict} (missing_reports=${completionAudit.missingReports}, missing_documents=${completionAudit.missingDocuments}, missing_signoffs=${completionAudit.missingSignoffRoles})');
    b.writeln('- Result: ${completionAuditGatePass ? 'PASS' : 'FAIL'}');
  } else {
    b.writeln('- Completion audit verdict: NO_DATA');
    b.writeln('- Result: FAIL (no completion audit package data)');
    if (completionAudit.note != null && completionAudit.note!.isNotEmpty) {
      b.writeln('- Note: ${completionAudit.note}');
    }
  }
  b.writeln();

  b.writeln('## Sign-Off Status\n');
  final requiredRoles = <String>[
    'Product',
    'Platform/OS Engineering',
    'ML Research',
    'Reliability/SRE',
    'Security/Compliance',
    'Governance/Executive',
  ];
  final approved = completionAudit.approvedSignoffRoles.toSet();
  final missing = completionAudit.missingSignoffRoleNames.toSet();
  b.writeln('| Role | Status |');
  b.writeln('|------|--------|');
  for (final role in requiredRoles) {
    final status = approved.contains(role)
        ? 'Approved'
        : (missing.contains(role) ? 'Pending' : 'Unknown');
    b.writeln('| $role | $status |');
  }

  return b.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse('$value') ?? 0.0;
}

String? _asStringOrNull(dynamic value) {
  if (value == null) return null;
  final s = '$value'.trim();
  return s.isEmpty ? null : s;
}

List<String> _unresolvedDependencies(
  String dependencies,
  Map<String, String> statusByMilestone,
) {
  final raw = dependencies.trim();
  if (raw.isEmpty || raw.toLowerCase() == 'none') return const <String>[];

  final deps = raw
      .split(RegExp(r'[;,]\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  return deps
      .where((dep) => (statusByMilestone[dep] ?? 'Unknown') != 'Done')
      .toList(growable: false);
}

String _safeRead(String path) {
  final f = File(path);
  if (!f.existsSync()) return '';
  return f.readAsStringSync();
}

String _cell(List<String> row, Map<String, int> idx, String key) {
  final i = idx[key];
  if (i == null || i < 0 || i >= row.length) return '';
  return row[i];
}

List<String> _splitCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (ch == ',' && !inQuotes) {
      out.add(buf.toString());
      buf.clear();
      continue;
    }

    buf.write(ch);
  }

  out.add(buf.toString());
  return out;
}
