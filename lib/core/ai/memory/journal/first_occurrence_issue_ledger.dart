enum IssueSeverity {
  low,
  medium,
  high,
  critical,
}

enum IssueImpactRadius {
  singleUser,
  cohort,
  subsystem,
  global,
}

enum IssueNextAction {
  fix,
  experiment,
  escalate,
}

class FirstOccurrenceIssueEntry {
  final String issueSignature;
  final IssueSeverity severity;
  final IssueImpactRadius impactRadius;
  final IssueNextAction nextAction;
  final DateTime firstSeenAt;
  final String subsystem;
  final Map<String, Object?> metadata;

  const FirstOccurrenceIssueEntry({
    required this.issueSignature,
    required this.severity,
    required this.impactRadius,
    required this.nextAction,
    required this.firstSeenAt,
    required this.subsystem,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'issue_signature': issueSignature,
      'severity': severity.name,
      'impact_radius': impactRadius.name,
      'next_action': nextAction.name,
      'first_seen_at': firstSeenAt.toUtc().toIso8601String(),
      'subsystem': subsystem,
      'metadata': metadata,
    };
  }

  factory FirstOccurrenceIssueEntry.fromJson(Map<String, dynamic> json) {
    T parse<T extends Enum>(List<T> values, Object? raw, String field) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('Unknown $field "$name".'),
      );
    }

    return FirstOccurrenceIssueEntry(
      issueSignature: json['issue_signature'] as String? ?? '',
      severity: parse(IssueSeverity.values, json['severity'], 'severity'),
      impactRadius: parse(
        IssueImpactRadius.values,
        json['impact_radius'],
        'impact_radius',
      ),
      nextAction: parse(
        IssueNextAction.values,
        json['next_action'],
        'next_action',
      ),
      firstSeenAt: DateTime.tryParse(json['first_seen_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      subsystem: json['subsystem'] as String? ?? '',
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}

class FirstOccurrenceIssueLedger {
  final Map<String, FirstOccurrenceIssueEntry> _entriesBySignature;

  FirstOccurrenceIssueLedger({
    Map<String, FirstOccurrenceIssueEntry>? seedEntries,
  }) : _entriesBySignature = {...?seedEntries};

  bool hasSeen(String issueSignature) {
    return _entriesBySignature.containsKey(issueSignature);
  }

  FirstOccurrenceIssueEntry? lookup(String issueSignature) {
    return _entriesBySignature[issueSignature];
  }

  List<FirstOccurrenceIssueEntry> snapshot() {
    final entries = _entriesBySignature.values.toList(growable: false);
    entries.sort((a, b) => a.firstSeenAt.compareTo(b.firstSeenAt));
    return entries;
  }

  FirstOccurrenceIssueEntry recordFirstSeen({
    required String issueSignature,
    required IssueSeverity severity,
    required IssueImpactRadius impactRadius,
    required DateTime detectedAt,
    required String subsystem,
    Map<String, Object?> metadata = const {},
  }) {
    final signature = issueSignature.trim();
    if (signature.isEmpty) {
      throw ArgumentError.value(
        issueSignature,
        'issueSignature',
        'Issue signature cannot be empty.',
      );
    }

    final existing = _entriesBySignature[signature];
    if (existing != null) {
      return existing;
    }

    final entry = FirstOccurrenceIssueEntry(
      issueSignature: signature,
      severity: severity,
      impactRadius: impactRadius,
      nextAction: determineNextAction(
        severity: severity,
        impactRadius: impactRadius,
      ),
      firstSeenAt: detectedAt.toUtc(),
      subsystem: subsystem,
      metadata: metadata,
    );
    _entriesBySignature[signature] = entry;
    return entry;
  }

  static IssueNextAction determineNextAction({
    required IssueSeverity severity,
    required IssueImpactRadius impactRadius,
  }) {
    if (severity == IssueSeverity.critical ||
        impactRadius == IssueImpactRadius.global) {
      return IssueNextAction.escalate;
    }
    if (severity == IssueSeverity.high ||
        impactRadius == IssueImpactRadius.subsystem ||
        impactRadius == IssueImpactRadius.cohort) {
      return IssueNextAction.experiment;
    }
    return IssueNextAction.fix;
  }
}
